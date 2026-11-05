import os
import re
import uuid
import shutil
from typing import Optional
from fastapi import FastAPI, Request, Response, HTTPException, Depends, UploadFile, File, Form, status
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

load_dotenv()

from backend.database import (
    init_db, get_all_workers, get_worker_view_by_id, get_worker_view_by_credencial_id,
    get_qr_public_view_by_credencial_id, check_worker_duplicates,
    create_worker, update_worker, toggle_credencial_status,
    add_notification_history, get_notification_history,
    get_admin_user, create_admin_user
)
from backend.auth import (
    hash_password, verify_password, create_session, get_session_user,
    delete_session, generate_csrf_token, validate_csrf_token
)
from backend.notifications import send_notification_email
from backend.seed import seed_database

# Initialize database and tables on startup
init_db()
seed_database()

app = FastAPI(title="Sistema de Credencialización Web")

@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    import traceback
    traceback.print_exc()
    err_msg = str(exc) or exc.__class__.__name__
    return JSONResponse(
        status_code=500,
        content={"message": f"Error del servidor: {err_msg}"}
    )

# CORS middleware for dev and production
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "..", "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

DIST_DIR = os.path.join(os.path.dirname(__file__), "..", "frontend", "dist")

# Dependency: require logged-in admin
def get_current_admin(request: Request):
    session_id = request.cookies.get("credencial_session")
    if not session_id:
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            session_id = auth_header[7:]
    user = get_session_user(session_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesión expirada o no iniciada."
        )
    return user

def get_lan_ip():
    import socket
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

@app.get("/api/network-info")
def network_info():
    ip = get_lan_ip()
    return {
        "lan_ip": ip,
        "base_url": f"http://{ip}:8000"
    }

# ==============================================================================
# AUTH & CSRF ENDPOINTS
# ==============================================================================

@app.get("/api/csrf")
def get_csrf():
    """Generates a CSRF token for secure state-changing requests."""
    return {"csrf_token": generate_csrf_token()}

@app.post("/api/login")
async def login(request: Request, response: Response):
    """Logs in an administrator and sets the session cookie."""
    data = await request.json()
    correo = (data.get("correo") or "").strip().lower()
    password = data.get("password") or ""

    user = get_admin_user(correo)
    if not user or not verify_password(password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Correo electrónico o contraseña incorrectos."
        )

    session_id = create_session(user)
    response.set_cookie(
        key="credencial_session",
        value=session_id,
        httponly=True,
        samesite="lax",
        max_age=86400 * 7
    )
    return {
        "id": user["id"],
        "nombre": user["nombre"],
        "correo": user["correo"]
    }

@app.get("/api/me")
def me(user: dict = Depends(get_current_admin)):
    """Returns the authenticated admin info."""
    return user

@app.post("/api/logout")
def logout(request: Request, response: Response):
    """Logs out the administrator."""
    session_id = request.cookies.get("credencial_session")
    delete_session(session_id)
    response.delete_cookie(key="credencial_session")
    return {"ok": True}

# ==============================================================================
# WORKERS & CREDENTIALS ENDPOINTS
# ==============================================================================

@app.get("/api/trabajadores")
def list_workers(user: dict = Depends(get_current_admin)):
    """Returns all workers and their credentials from the view."""
    return get_all_workers()

def _validate_worker_fields(data: dict, is_update: bool = False, worker_id: Optional[int] = None):
    """Rigorous validation of all input fields according to reto specifications and security best practices."""
    errors = {}
    
    # 1. Nombre completo: Solo letras, espacios, acentos y guiones (sin números ni símbolos raros)
    nombre = str(data.get("nombre_completo") or "").strip()
    if not nombre:
        errors["nombre_completo"] = ["El nombre completo es obligatorio."]
    elif len(nombre) < 3:
        errors["nombre_completo"] = ["El nombre debe tener al menos 3 caracteres."]
    elif len(nombre) > 150:
        errors["nombre_completo"] = ["Máximo 150 caracteres."]
    elif not re.match(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s\.\-]+$", nombre):
        errors["nombre_completo"] = ["El nombre solo debe contener letras, espacios, acentos y guiones (sin números ni caracteres especiales)."]

    # 2. Edad: Número entero entre 18 y 99 años
    try:
        edad = int(data.get("edad", 0))
        if edad < 18:
            errors["edad"] = ["La edad debe ser de 18 años o más (requisito del reto)."]
        elif edad > 99:
            errors["edad"] = ["Ingresa una edad válida (menor a 100 años)."]
    except (ValueError, TypeError):
        errors["edad"] = ["La edad debe ser un número entero válido."]

    # 3. Sexo: Selección de catálogo válido
    sexo = str(data.get("sexo") or "").strip()
    if not sexo:
        errors["sexo"] = ["El sexo es obligatorio."]
    elif sexo not in ["Femenino", "Masculino", "Otro", "Prefiere no indicar"]:
        errors["sexo"] = ["Selecciona una opción válida de la lista."]

    # 4. CURP: Exactamente 18 caracteres en mayúsculas, formato oficial RENAPO
    curp = str(data.get("curp") or "").strip().upper()
    curp_pattern = r"^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\d$"
    if not curp:
        errors["curp"] = ["La CURP es obligatoria."]
    elif len(curp) != 18:
        errors["curp"] = [f"La CURP debe tener exactamente 18 caracteres (actualmente tiene {len(curp)})."]
    elif not re.match(curp_pattern, curp):
        errors["curp"] = ["Estructura de CURP inválida. Formato oficial: 4 letras, 6 dígitos (AAMMDD), sexo (H/M), 5 letras de entidad y consonantes, homoclave."]

    # 5. Correo electrónico: Formato estándar RFC
    correo = str(data.get("correo") or "").strip().lower()
    email_pattern = r"^[\w\.\+\-]+@[a-zA-Z0-9\-]+(\.[a-zA-Z0-9\-]+)+$"
    if not correo:
        errors["correo"] = ["El correo electrónico es obligatorio."]
    elif len(correo) > 120:
        errors["correo"] = ["Máximo 120 caracteres."]
    elif not re.match(email_pattern, correo):
        errors["correo"] = ["Ingresa una dirección de correo válida (ejemplo: usuario@institucion.edu.mx)."]

    # 6. Número de trabajador: Formato institucional Cacao del Sur (ej. CS-PRD-101 o CS-101)
    num_trab = str(data.get("numero_trabajador") or "").strip().upper()
    if not num_trab:
        errors["numero_trabajador"] = ["El número de trabajador es obligatorio."]
    elif len(num_trab) < 4:
        errors["numero_trabajador"] = ["Mínimo 4 caracteres (formato CS-ÁREA-XXX)."]
    elif len(num_trab) > 20:
        errors["numero_trabajador"] = ["Máximo 20 caracteres."]
    elif not re.match(r"^[A-Za-z0-9\-_.]+$", num_trab):
        errors["numero_trabajador"] = ["Solo se permiten letras, números y guiones."]
    elif not ("-" in num_trab):
        errors["numero_trabajador"] = ["Debe incluir guion separador según formato corporativo (ej. CS-PRD-101)."]

    # 7. Número de tarjeta: Folio único institucional (ej. TAR-PRD-1001 o TAR-1001)
    num_tarj = str(data.get("numero_tarjeta") or "").strip().upper()
    if not num_tarj:
        errors["numero_tarjeta"] = ["El número de tarjeta es obligatorio."]
    elif len(num_tarj) < 5:
        errors["numero_tarjeta"] = ["Mínimo 5 caracteres (ej. TAR-PRD-1001 o TAR-1001)."]
    elif len(num_tarj) > 50:
        errors["numero_tarjeta"] = ["Máximo 50 caracteres."]
    elif not re.match(r"^[A-Za-z0-9\-_.]+$", num_tarj):
        errors["numero_tarjeta"] = ["Solo se permiten letras, números y guiones."]
    elif not num_tarj.startswith("TAR-"):
        errors["numero_tarjeta"] = ["El folio de tarjeta debe iniciar con el prefijo oficial 'TAR-' (ej. TAR-PRD-1001)."]

    # 8. Área de adscripción: Longitud 2-100, caracteres alfanuméricos y acentos
    area = str(data.get("area_adscripcion") or data.get("area") or "").strip()
    if not area:
        errors["area_adscripcion"] = ["El área de adscripción es obligatoria."]
    elif len(area) < 2:
        errors["area_adscripcion"] = ["Mínimo 2 caracteres."]
    elif len(area) > 100:
        errors["area_adscripcion"] = ["Máximo 100 caracteres."]
    elif not re.match(r"^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ\s\.\-/,]+$", area):
        errors["area_adscripcion"] = ["El área contiene caracteres no permitidos."]

    # 9. Cargo / Puesto: Longitud 2-100
    cargo = str(data.get("cargo") or "").strip()
    if not cargo:
        errors["cargo"] = ["El cargo o puesto es obligatorio."]
    elif len(cargo) < 2:
        errors["cargo"] = ["Mínimo 2 caracteres."]
    elif len(cargo) > 100:
        errors["cargo"] = ["Máximo 100 caracteres."]
    elif not re.match(r"^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ\s\.\-/,]+$", cargo):
        errors["cargo"] = ["El cargo contiene caracteres no permitidos."]

    # 10. Contacto de emergencia (nombre)
    em_nombre = str(data.get("contacto_emergencia_nombre") or "").strip()
    if not em_nombre:
        errors["contacto_emergencia_nombre"] = ["El nombre del contacto de emergencia es obligatorio."]
    elif len(em_nombre) < 3:
        errors["contacto_emergencia_nombre"] = ["Mínimo 3 caracteres."]
    elif len(em_nombre) > 150:
        errors["contacto_emergencia_nombre"] = ["Máximo 150 caracteres."]
    elif not re.match(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s\.\-]+$", em_nombre):
        errors["contacto_emergencia_nombre"] = ["Solo debe contener letras y espacios."]

    # 11. Teléfono de emergencia: Mínimo 10 dígitos numéricos
    em_tel = str(data.get("contacto_emergencia_telefono") or "").strip()
    digits = re.sub(r"\D", "", em_tel)
    if not em_tel:
        errors["contacto_emergencia_telefono"] = ["El teléfono de emergencia es obligatorio."]
    elif len(digits) != 10:
        errors["contacto_emergencia_telefono"] = [f"Debe tener exactamente 10 dígitos numéricos (actualmente tiene {len(digits)})."]
    elif len(em_tel) > 20:
        errors["contacto_emergencia_telefono"] = ["Máximo 20 caracteres en total."]
    elif not re.match(r"^[+0-9\s\-()]+$", em_tel):
        errors["contacto_emergencia_telefono"] = ["Solo se permiten números, espacios, guiones, paréntesis y prefijo +."]

    # 12. Rango de vigencia (fecha_inicio y fecha_vencimiento)
    inicio = str(data.get("fecha_inicio") or "").strip()
    venc = str(data.get("fecha_vencimiento") or "").strip()
    if not inicio:
        errors["fecha_inicio"] = ["La fecha de inicio de vigencia es obligatoria."]
    if not venc:
        errors["fecha_vencimiento"] = ["La fecha de vencimiento es obligatoria."]
    elif inicio and venc:
        if inicio > venc:
            errors["fecha_vencimiento"] = ["La fecha de vencimiento debe ser igual o posterior a la fecha de inicio."]
        try:
            y_ini = int(inicio.split("-")[0])
            y_venc = int(venc.split("-")[0])
            if y_ini < 2000 or y_ini > 2050 or y_venc < 2000 or y_venc > 2050:
                errors["fecha_vencimiento"] = ["El año de vigencia debe estar entre el 2000 y el 2050."]
        except Exception:
            errors["fecha_vencimiento"] = ["Formato de fecha inválido. Utiliza el selector de fecha."]

    # 13. Chequeo de duplicados en base de datos (número trabajador, tarjeta, CURP, correo)
    dup_errors = check_worker_duplicates(data, exclude_trabajador_id=worker_id)
    for k, v in dup_errors.items():
        errors[k] = v

    if errors:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"message": "Revisa los campos marcados en el formulario.", "errors": errors}
        )

@app.post("/api/trabajadores")
async def create_new_worker(
    request: Request,
    user: dict = Depends(get_current_admin)
):
    """Creates a new worker, emits credential and triggers notification."""
    content_type = request.headers.get("content-type", "")
    data = {}
    photo_url = ""

    if "multipart/form-data" in content_type:
        form = await request.form()
        for k, v in form.items():
            if k == "fotografia" and hasattr(v, "filename") and v.filename:
                # Save uploaded file
                ext = os.path.splitext(v.filename)[1] or ".jpg"
                filename = f"foto_{uuid.uuid4().hex[:12]}{ext}"
                filepath = os.path.join(UPLOAD_DIR, filename)
                with open(filepath, "wb") as buffer:
                    shutil.copyfileobj(v.file, buffer)
                photo_url = f"/uploads/{filename}"
            elif k == "fotografia" and isinstance(v, str) and v.startswith("data:"):
                photo_url = v
            else:
                data[k] = v
    else:
        data = await request.json()
        photo_url = data.get("fotografia_url") or data.get("fotografia") or ""

    if photo_url:
        data["fotografia_url"] = photo_url
    elif not data.get("fotografia_url"):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"message": "Agrega una fotografía individual para continuar.", "errors": {"fotografia": ["La fotografía es obligatoria."]}}
        )

    # Normalize esta_activa
    activa_raw = data.get("esta_activa", True)
    data["esta_activa"] = str(activa_raw).lower() in ("true", "1", "yes")

    # Clean strings
    for k in ["numero_trabajador", "nombre_completo", "sexo", "curp", "correo",
              "area_adscripcion", "cargo", "contacto_emergencia_nombre",
              "contacto_emergencia_telefono", "numero_tarjeta"]:
        if k in data and isinstance(data[k], str):
            data[k] = data[k].strip()

    data["curp"] = data.get("curp", "").upper()

    _validate_worker_fields(data)

    try:
        new_row = create_worker(data)
    except Exception as e:
        err_msg = str(e)
        if "unique" in err_msg.lower() or "duplicad" in err_msg.lower() or "ya existe" in err_msg.lower():
            if "numero_trabajador" in err_msg.lower():
                raise HTTPException(status_code=422, detail={"message": "El número de trabajador ya existe.", "errors": {"numero_trabajador": ["Ya está registrado."]}})
            if "numero_tarjeta" in err_msg.lower():
                raise HTTPException(status_code=422, detail={"message": "El número de tarjeta ya existe.", "errors": {"numero_tarjeta": ["Ya está registrado."]}})
            if "curp" in err_msg.lower():
                raise HTTPException(status_code=422, detail={"message": "La CURP ya existe.", "errors": {"curp": ["Ya está registrada."]}})
        raise HTTPException(status_code=400, detail={"message": f"Error al registrar: {err_msg}"})

    # Trigger Automated Notification: 'Nueva credencial'
    try:
        dispatch_status = send_notification_email(
            trabajador_nombre=new_row["nombre_completo"],
            numero_trabajador=new_row["numero_trabajador"],
            numero_tarjeta=new_row["numero_tarjeta"],
            tipo_evento="Nueva credencial",
            destinatario=new_row["correo"],
            fecha_inicio=new_row["fecha_inicio"],
            fecha_vencimiento=new_row["fecha_vencimiento"],
            estado_actualizado=new_row["estado_calculado"]
        )
        add_notification_history(
            trabajador_id=new_row["trabajador_id"],
            numero_tarjeta=new_row["numero_tarjeta"],
            tipo_evento="Nueva credencial",
            correo=new_row["correo"],
            estado=dispatch_status
        )
    except Exception as mail_err:
        print(f"[MAILER WARN] Error al enviar notificación de alta: {mail_err}")

    return new_row

@app.post("/api/trabajadores/{worker_id}")
@app.put("/api/trabajadores/{worker_id}")
async def update_existing_worker(
    worker_id: int,
    request: Request,
    user: dict = Depends(get_current_admin)
):
    """Updates an existing worker and detects vigencia changes to send email."""
    existing = get_worker_view_by_id(worker_id)
    if not existing:
        raise HTTPException(status_code=404, detail={"message": "Trabajador no encontrado."})

    content_type = request.headers.get("content-type", "")
    data = {}
    photo_url = existing.get("fotografia_url", "")

    if "multipart/form-data" in content_type:
        form = await request.form()
        for k, v in form.items():
            if k == "fotografia" and hasattr(v, "filename") and v.filename:
                ext = os.path.splitext(v.filename)[1] or ".jpg"
                filename = f"foto_{uuid.uuid4().hex[:12]}{ext}"
                filepath = os.path.join(UPLOAD_DIR, filename)
                with open(filepath, "wb") as buffer:
                    shutil.copyfileobj(v.file, buffer)
                photo_url = f"/uploads/{filename}"
            elif k == "fotografia" and isinstance(v, str) and v.startswith("data:"):
                photo_url = v
            else:
                data[k] = v
    else:
        data = await request.json()
        if "fotografia" in data or "fotografia_url" in data:
            photo_url = data.get("fotografia_url") or data.get("fotografia")

    data["fotografia_url"] = photo_url
    activa_raw = data.get("esta_activa", existing["esta_activa"])
    data["esta_activa"] = str(activa_raw).lower() in ("true", "1", "yes")

    for k in ["numero_trabajador", "nombre_completo", "sexo", "curp", "correo",
              "area_adscripcion", "cargo", "contacto_emergencia_nombre",
              "contacto_emergencia_telefono", "numero_tarjeta"]:
        if k in data and isinstance(data[k], str):
            data[k] = data[k].strip()

    # Criterio estricto de inmutabilidad institucional Cacao del Sur:
    # La matrícula y el folio de tarjeta son inmutables una vez asignados al expediente físico y digital.
    # Únicamente la CURP puede ser rectificada ante correcciones o resoluciones de RENAPO.
    data["numero_trabajador"] = existing["numero_trabajador"]
    data["numero_tarjeta"] = existing["numero_tarjeta"]
    if not data.get("curp"):
        data["curp"] = existing["curp"]

    _validate_worker_fields(data, is_update=True, worker_id=worker_id)

    old_vencimiento = str(existing.get("fecha_vencimiento", ""))
    new_vencimiento = str(data.get("fecha_vencimiento", ""))
    vencimiento_changed = old_vencimiento != new_vencimiento

    updated_row = update_worker(worker_id, data)

    # Automated Notification: 'Modificación vigencia' if expiration changed
    if vencimiento_changed:
        try:
            dispatch_status = send_notification_email(
                trabajador_nombre=updated_row["nombre_completo"],
                numero_trabajador=updated_row["numero_trabajador"],
                numero_tarjeta=updated_row["numero_tarjeta"],
                tipo_evento="Modificación vigencia",
                destinatario=updated_row["correo"],
                fecha_inicio=updated_row["fecha_inicio"],
                fecha_vencimiento=updated_row["fecha_vencimiento"],
                estado_actualizado=updated_row["estado_calculado"]
            )
            add_notification_history(
                trabajador_id=updated_row["trabajador_id"],
                numero_tarjeta=updated_row["numero_tarjeta"],
                tipo_evento="Modificación vigencia",
                correo=updated_row["correo"],
                estado=dispatch_status
            )
        except Exception as mail_err:
            print(f"[MAILER WARN] Error al enviar notificación de vigencia: {mail_err}")

    return updated_row

@app.patch("/api/credenciales/{credencial_id}/estado")
async def toggle_credencial(
    credencial_id: str,
    request: Request,
    user: dict = Depends(get_current_admin)
):
    """Enables or disables a credencial and records deactivation event."""
    try:
        data = await request.json()
        esta_activa = bool(data.get("esta_activa", True))

        updated_row = toggle_credencial_status(credencial_id, esta_activa)
        if not updated_row:
            raise HTTPException(status_code=404, detail={"message": "Credencial no encontrada."})

        # Automated Notification: 'Desactivación' when admin disables card
        if not esta_activa:
            try:
                dispatch_status = send_notification_email(
                    trabajador_nombre=updated_row["nombre_completo"],
                    numero_trabajador=updated_row["numero_trabajador"],
                    numero_tarjeta=updated_row["numero_tarjeta"],
                    tipo_evento="Desactivación",
                    destinatario=updated_row["correo"],
                    fecha_inicio=updated_row["fecha_inicio"],
                    fecha_vencimiento=updated_row["fecha_vencimiento"],
                    estado_actualizado=updated_row["estado_calculado"]
                )
                add_notification_history(
                    trabajador_id=updated_row["trabajador_id"],
                    numero_tarjeta=updated_row["numero_tarjeta"],
                    tipo_evento="Desactivación",
                    correo=updated_row["correo"],
                    estado=dispatch_status
                )
            except Exception as mail_err:
                print(f"[MAILER WARN] Error al enviar notificación de desactivación: {mail_err}")

        return updated_row
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail={"message": f"Error al cambiar estado de la credencial: {str(e)}"})

# ==============================================================================
# PUBLIC VERIFICATION ENDPOINT (QR CODE DESTINATION)
# ==============================================================================

@app.get("/api/verificar/{credencial_id}")
def public_verify(credencial_id: str):
    """
    Public verification view accessed by scanning the QR code.
    Returns trabajador_id and credencial_id as required by the frontend adapter,
    while omitting sensitive data (CURP and emergency contacts).
    """
    row = get_worker_view_by_credencial_id(credencial_id)
    if not row:
        raise HTTPException(
            status_code=404,
            detail={"message": "Credencial no encontrada. El código QR no corresponde a una credencial registrada."}
        )
    return {
        "trabajador_id": row["trabajador_id"],
        "credencial_id": row["credencial_id"],
        "numero_trabajador": row["numero_trabajador"],
        "nombre_completo": row["nombre_completo"],
        "area_adscripcion": row["area_adscripcion"],
        "cargo": row["cargo"],
        "fotografia_url": row["fotografia_url"],
        "numero_tarjeta": row["numero_tarjeta"],
        "fecha_inicio": row["fecha_inicio"],
        "fecha_vencimiento": row["fecha_vencimiento"],
        "esta_activa": row["esta_activa"],
        "estado_calculado": row["estado_calculado"]
    }

# ==============================================================================
# AUDIT & SEED ENDPOINTS
# ==============================================================================

@app.get("/api/notificaciones")
def list_notifications(user: dict = Depends(get_current_admin)):
    """Returns the email notifications audit trail."""
    return get_notification_history()

@app.post("/api/seed")
def reseed(user: dict = Depends(get_current_admin)):
    """Reseeds the database with 10 sample workers."""
    seed_database()
    return {"message": "Base de datos actualizada con trabajadores de prueba."}

# ==============================================================================
# STATIC SPA FRONTEND SERVING
# ==============================================================================

if os.path.exists(DIST_DIR):
    app.mount("/assets", StaticFiles(directory=os.path.join(DIST_DIR, "assets")), name="assets")

    @app.get("/{full_path:path}")
    async def serve_spa(full_path: str):
        # Do not intercept API or uploads
        if full_path.startswith("api/") or full_path.startswith("uploads/"):
            raise HTTPException(status_code=404, detail="Not Found")
        file_path = os.path.join(DIST_DIR, full_path)
        if os.path.isfile(file_path):
            return FileResponse(file_path)
        return FileResponse(os.path.join(DIST_DIR, "index.html"))
