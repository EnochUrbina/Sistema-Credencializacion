import base64
from datetime import date, timedelta
from backend.database import get_connection, IS_POSTGRES, create_admin_user, init_db, get_all_workers, create_worker
from backend.auth import hash_password

def generate_svg_avatar(initials: str, bg_color: str) -> str:
    """Generates an inline SVG data URI portrait with warm cocoa tones."""
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="240" height="240" viewBox="0 0 240 240">
      <defs>
        <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="{bg_color}" />
          <stop offset="100%" stop-color="#2D1807" />
        </linearGradient>
      </defs>
      <rect width="240" height="240" rx="24" fill="url(#grad)" />
      <circle cx="120" cy="85" r="45" fill="#FAF6F0" fill-opacity="0.92" />
      <path d="M40 210 C40 150, 80 140, 120 140 C160 140, 200 150, 200 210 Z" fill="#FAF6F0" fill-opacity="0.92" />
      <text x="120" y="98" font-family="'Segoe UI', Arial, sans-serif" font-size="28" font-weight="bold" fill="#3D2012" text-anchor="middle">{initials}</text>
    </svg>"""
    encoded = base64.b64encode(svg.encode("utf-8")).decode("utf-8")
    return f"data:image/svg+xml;base64,{encoded}"

# Catálogo oficial de personal institucional de CACAO DEL SUR S.A. DE C.V.
WORKERS_SEED = [
    {
        "numero_trabajador": "CS-CAL-101",
        "nombre_completo": "Ana Sofía López Morales",
        "edad": 29,
        "sexo": "Femenino",
        "curp": "LOMA970315MCFRLN01",
        "correo": "ana.lopez@cacaodelsur.com",
        "area_adscripcion": "Control de Calidad y Catación",
        "cargo": "Sommelier Principal y Jefa de Catación",
        "fotografia_url": generate_svg_avatar("AL", "#C4823F"),
        "contacto_emergencia_nombre": "Roberto López Morales",
        "contacto_emergencia_telefono": "9611234567",
        "numero_tarjeta": "TAR-CAL-1001",
        "fecha_inicio": "2026-01-01",
        "fecha_vencimiento": "2026-12-31",
        "esta_activa": True
    },
    {
        "numero_trabajador": "CS-PRD-102",
        "nombre_completo": "Juan Carlos Pérez Gómez",
        "edad": 34,
        "sexo": "Masculino",
        "curp": "PEGJ920512HDFRRN02",
        "correo": "juan.perez@cacaodelsur.com",
        "area_adscripcion": "Producción y Chocolatería",
        "cargo": "Maestro Chocolatero de Bombones Finos",
        "fotografia_url": generate_svg_avatar("JP", "#5C3317"),
        "contacto_emergencia_nombre": "Elena Gómez Ruiz",
        "contacto_emergencia_telefono": "9612345678",
        "numero_tarjeta": "TAR-PRD-1002",
        "fecha_inicio": "2026-01-01",
        "fecha_vencimiento": "2026-12-31",
        "esta_activa": False # Inactiva por licencia
    },
    {
        "numero_trabajador": "CS-ADM-103",
        "nombre_completo": "María Elena Ruiz Hernández",
        "edad": 42,
        "sexo": "Femenino",
        "curp": "RUHM840820MDFNZR03",
        "correo": "maria.ruiz@cacaodelsur.com",
        "area_adscripcion": "Administración y Finanzas",
        "cargo": "Directora de Finanzas y Costos Agrícolas",
        "fotografia_url": generate_svg_avatar("MR", "#9E5D24"),
        "contacto_emergencia_nombre": "Carlos Ruiz Hernández",
        "contacto_emergencia_telefono": "9613456789",
        "numero_tarjeta": "TAR-ADM-1003",
        "fecha_inicio": "2025-01-01",
        "fecha_vencimiento": "2026-10-30", # Vencida en 2026
        "esta_activa": True
    },
    {
        "numero_trabajador": "CS-AGR-104",
        "nombre_completo": "Pedro Antonio Díaz Vargas",
        "edad": 38,
        "sexo": "Masculino",
        "curp": "DIVP881105HDFRRD04",
        "correo": "pedro.diaz@cacaodelsur.com",
        "area_adscripcion": "Investigación Agronómica y Campo",
        "cargo": "Ingeniero Agrónomo de Cacao Criollo",
        "fotografia_url": generate_svg_avatar("PD", "#2D6A4F"),
        "contacto_emergencia_nombre": "Laura Vargas Flores",
        "contacto_emergencia_telefono": "9614567890",
        "numero_tarjeta": "TAR-AGR-1004",
        "fecha_inicio": "2026-01-01",
        "fecha_vencimiento": "2026-12-31",
        "esta_activa": True
    },
    {
        "numero_trabajador": "CS-PRD-105",
        "nombre_completo": "Laura Patricia Mendoza Flores",
        "edad": 31,
        "sexo": "Femenino",
        "curp": "MEFL950414MDFNNL05",
        "correo": "laura.mendoza@cacaodelsur.com",
        "area_adscripcion": "Producción y Chocolatería",
        "cargo": "Supervisora de Tostado y Molienda Fina",
        "fotografia_url": generate_svg_avatar("LM", "#7A431D"),
        "contacto_emergencia_nombre": "Patricia Flores Cruz",
        "contacto_emergencia_telefono": "9615678901",
        "numero_tarjeta": "TAR-PRD-1005",
        "fecha_inicio": "2026-02-01",
        "fecha_vencimiento": "2027-02-01",
        "esta_activa": True
    },
    {
        "numero_trabajador": "CS-LOG-106",
        "nombre_completo": "Carlos Eduardo Torres Morales",
        "edad": 45,
        "sexo": "Masculino",
        "curp": "TOMC810228HDFRRS06",
        "correo": "carlos.torres@cacaodelsur.com",
        "area_adscripcion": "Logística y Cadena de Suministro",
        "cargo": "Coordinador de Exportación y Cadena en Frío",
        "fotografia_url": generate_svg_avatar("CT", "#4A2818"),
        "contacto_emergencia_nombre": "Gabriela Silva Méndez",
        "contacto_emergencia_telefono": "9616789012",
        "numero_tarjeta": "TAR-LOG-1006",
        "fecha_inicio": "2026-01-15",
        "fecha_vencimiento": "2027-01-15",
        "esta_activa": True
    },
    {
        "numero_trabajador": "CS-CAL-107",
        "nombre_completo": "Sofía Isabel Castro Peña",
        "edad": 27,
        "sexo": "Femenino",
        "curp": "CAPS990719MDFTSF07",
        "correo": "sofia.castro@cacaodelsur.com",
        "area_adscripcion": "Control de Calidad y Catación",
        "cargo": "Inspectora de Fermentación y Certificación Orgánica",
        "fotografia_url": generate_svg_avatar("SC", "#A0522D"),
        "contacto_emergencia_nombre": "Javier Castro Peña",
        "contacto_emergencia_telefono": "9617890123",
        "numero_tarjeta": "TAR-CAL-1007",
        "fecha_inicio": "2026-03-01",
        "fecha_vencimiento": "2027-03-01",
        "esta_activa": True
    },
    {
        "numero_trabajador": "CS-INN-108",
        "nombre_completo": "Miguel Ángel Ortiz Ramos",
        "edad": 36,
        "sexo": "Masculino",
        "curp": "OIRM900903HDFRGM08",
        "correo": "miguel.ortiz@cacaodelsur.com",
        "area_adscripcion": "Innovación y Maquinaria Agroindustrial",
        "cargo": "Técnico Especialista en Concheado Industrial",
        "fotografia_url": generate_svg_avatar("MO", "#522E1A"),
        "contacto_emergencia_nombre": "Susana Ramos Cruz",
        "contacto_emergencia_telefono": "9618901234",
        "numero_tarjeta": "TAR-INN-1008",
        "fecha_inicio": "2026-12-01",
        "fecha_vencimiento": "2027-12-01", # No vigente (futura)
        "esta_activa": True
    },
    {
        "numero_trabajador": "CS-VTA-109",
        "nombre_completo": "Diana Laura Navarro Silva",
        "edad": 33,
        "sexo": "Femenino",
        "curp": "NASD931211MDFVRN09",
        "correo": "diana.navarro@cacaodelsur.com",
        "area_adscripcion": "Ventas y Exportación Internacional",
        "cargo": "Gerente de Cuentas y Comercio Justo",
        "fotografia_url": generate_svg_avatar("DN", "#8B4513"),
        "contacto_emergencia_nombre": "Raúl Navarro Silva",
        "contacto_emergencia_telefono": "9619012345",
        "numero_tarjeta": "TAR-VTA-1009",
        "fecha_inicio": "2026-01-01",
        "fecha_vencimiento": "2026-12-31",
        "esta_activa": True
    },
    {
        "numero_trabajador": "CS-AGR-110",
        "nombre_completo": "Roberto Carlos Vega Méndez",
        "edad": 50,
        "sexo": "Masculino",
        "curp": "VEMR760606HDFGDC10",
        "correo": "roberto.vega@cacaodelsur.com",
        "area_adscripcion": "Investigación Agronómica y Campo",
        "cargo": "Coordinador de Viveros e Injertos de Cacao",
        "fotografia_url": generate_svg_avatar("RV", "#1B4332"),
        "contacto_emergencia_nombre": "Silvia Méndez Gómez",
        "contacto_emergencia_telefono": "9610123456",
        "numero_tarjeta": "TAR-AGR-1010",
        "fecha_inicio": "2026-01-01",
        "fecha_vencimiento": "2027-06-30",
        "esta_activa": True
    },
    {
        "numero_trabajador": "CS-PRD-111",
        "nombre_completo": "Valeria Alejandra Silva Ríos",
        "edad": 26,
        "sexo": "Femenino",
        "curp": "SIRV000325MDFLRL11",
        "correo": "valeria.silva@cacaodelsur.com",
        "area_adscripcion": "Producción y Chocolatería",
        "cargo": "Artesana de Coberturas y Chocolates de Origen",
        "fotografia_url": generate_svg_avatar("VS", "#B45309"),
        "contacto_emergencia_nombre": "Esteban Silva Ríos",
        "contacto_emergencia_telefono": "9611122334",
        "numero_tarjeta": "TAR-PRD-1011",
        "fecha_inicio": "2026-02-15",
        "fecha_vencimiento": "2027-02-15",
        "esta_activa": True
    },
    {
        "numero_trabajador": "CS-ADM-112",
        "nombre_completo": "Fernando Javier Morales Cruz",
        "edad": 39,
        "sexo": "Masculino",
        "curp": "MOCF870110HDFRRR12",
        "correo": "fernando.morales@cacaodelsur.com",
        "area_adscripcion": "Administración y Finanzas",
        "cargo": "Jefe de Gestión Humana y Cultura Laboral",
        "fotografia_url": generate_svg_avatar("FM", "#3D2012"),
        "contacto_emergencia_nombre": "Lorena Cruz Morales",
        "contacto_emergencia_telefono": "9612233445",
        "numero_tarjeta": "TAR-ADM-1012",
        "fecha_inicio": "2026-01-01",
        "fecha_vencimiento": "2027-01-01",
        "esta_activa": True
    },
    {
        "numero_trabajador": "CS-LOG-113",
        "nombre_completo": "Gabriela Morales Salazar",
        "edad": 30,
        "sexo": "Femenino",
        "curp": "MOSG960418MDFRLB13",
        "correo": "gabriela.morales@cacaodelsur.com",
        "area_adscripcion": "Logística y Cadena de Suministro",
        "cargo": "Supervisora de Almacén de Granos Seleccionados",
        "fotografia_url": generate_svg_avatar("GM", "#6B3A19"),
        "contacto_emergencia_nombre": "Manuel Salazar Trejo",
        "contacto_emergencia_telefono": "9613344556",
        "numero_tarjeta": "TAR-LOG-1013",
        "fecha_inicio": "2026-03-01",
        "fecha_vencimiento": "2027-03-01",
        "esta_activa": True
    }
]

def seed_database(force_refresh: bool = False):
    """Initializes tables, creates admin accounts and loads Cacao del Sur catalog."""
    init_db()

    # 1. Admin users (Cacao del Sur corporate + backward compatible)
    admin_pass = hash_password("admin123")
    create_admin_user("Administrador Cacao del Sur", "admin@cacaodelsur.com", admin_pass)
    create_admin_user("Administrador General", "admin@institucion.edu.mx", admin_pass)

    # 2. Check workers
    existing = get_all_workers()
    if force_refresh or len(existing) < 10 or not any("CS-" in (w.get("numero_trabajador") or "") for w in existing):
        print(f"[SEED] Actualizando catalogo oficial de Cacao del Sur (actual: {len(existing)})...")
        conn = get_connection()
        cur = conn.cursor()
        
        # Clear existing workers and reseed cleanly if needed
        if force_refresh or not any("CS-" in (w.get("numero_trabajador") or "") for w in existing):
            try:
                if IS_POSTGRES:
                    cur.execute("TRUNCATE TABLE historial_notificaciones, credenciales, trabajadores, areas, cargos RESTART IDENTITY CASCADE;")
                else:
                    cur.execute("DELETE FROM historial_notificaciones;")
                    cur.execute("DELETE FROM credenciales;")
                    cur.execute("DELETE FROM trabajadores;")
                    cur.execute("DELETE FROM areas;")
                    cur.execute("DELETE FROM cargos;")
                    cur.execute("DELETE FROM sqlite_sequence WHERE name IN ('trabajadores', 'credenciales', 'areas', 'cargos', 'historial_notificaciones');")
                    conn.commit()
            except Exception as e:
                print(f"[SEED WARN] Limpieza previa: {e}")

        # Re-create admin after truncate
        create_admin_user("Administrador Cacao del Sur", "admin@cacaodelsur.com", admin_pass)
        create_admin_user("Administrador General", "admin@institucion.edu.mx", admin_pass)

        for w_data in WORKERS_SEED:
            create_worker(w_data)
        print(f"[SEED] 13 Trabajadores de Cacao del Sur registrados exitosamente.")
    else:
        print(f"[SEED] Base de datos ya cuenta con catalogo de Cacao del Sur ({len(existing)} trabajadores).")

if __name__ == "__main__":
    seed_database(force_refresh=True)
