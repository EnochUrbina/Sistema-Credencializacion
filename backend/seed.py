import base64
from datetime import date, timedelta
from backend.database import get_connection, IS_POSTGRES, create_admin_user, init_db, get_all_workers, create_worker
from backend.auth import hash_password

def generate_svg_avatar(initials: str, bg_color: str) -> str:
    """Generates an inline SVG data URI portrait for offline independence."""
    svg = f"""<svg xmlns="http://www.w3.org/2000/svg" width="240" height="240" viewBox="0 0 240 240">
      <defs>
        <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="{bg_color}" />
          <stop offset="100%" stop-color="#0f172a" />
        </linearGradient>
      </defs>
      <rect width="240" height="240" rx="24" fill="url(#grad)" />
      <circle cx="120" cy="85" r="45" fill="#f8fafc" fill-opacity="0.9" />
      <path d="M40 210 C40 150, 80 140, 120 140 C160 140, 200 150, 200 210 Z" fill="#f8fafc" fill-opacity="0.9" />
      <text x="120" y="98" font-family="Arial, sans-serif" font-size="28" font-weight="bold" fill="#1e293b" text-anchor="middle">{initials}</text>
    </svg>"""
    encoded = base64.b64encode(svg.encode("utf-8")).decode("utf-8")
    return f"data:image/svg+xml;base64,{encoded}"

WORKERS_SEED = [
    {
        "numero_trabajador": "TR001",
        "nombre_completo": "Ana Sofía López Morales",
        "edad": 29,
        "sexo": "Femenino",
        "curp": "LOMA970315MCFRLN01",
        "correo": "ana.lopez@institucion.edu.mx",
        "area_adscripcion": "Sistemas",
        "cargo": "Líder de Desarrollo Web",
        "fotografia_url": generate_svg_avatar("AL", "#2563eb"),
        "contacto_emergencia_nombre": "Roberto López",
        "contacto_emergencia_telefono": "5512345678",
        "numero_tarjeta": "TAR1001",
        "fecha_inicio": "2026-01-01",
        "fecha_vencimiento": "2026-12-31",
        "esta_activa": True # Vigente
    },
    {
        "numero_trabajador": "TR002",
        "nombre_completo": "Juan Carlos Pérez Gómez",
        "edad": 34,
        "sexo": "Masculino",
        "curp": "PEGJ920512HDFRRN02",
        "correo": "juan.perez@institucion.edu.mx",
        "area_adscripcion": "Recursos Humanos",
        "cargo": "Especialista en Capacitación",
        "fotografia_url": generate_svg_avatar("JP", "#0d9488"),
        "contacto_emergencia_nombre": "Elena Gómez",
        "contacto_emergencia_telefono": "5523456789",
        "numero_tarjeta": "TAR1002",
        "fecha_inicio": "2026-01-01",
        "fecha_vencimiento": "2026-12-31",
        "esta_activa": False # Inactiva (desactivada por admin)
    },
    {
        "numero_trabajador": "TR003",
        "nombre_completo": "María Elena Ruiz Hernández",
        "edad": 42,
        "sexo": "Femenino",
        "curp": "RUHM840820MDFNZR03",
        "correo": "maria.ruiz@institucion.edu.mx",
        "area_adscripcion": "Administración",
        "cargo": "Coordinadora de Finanzas",
        "fotografia_url": generate_svg_avatar("MR", "#e11d48"),
        "contacto_emergencia_nombre": "Carlos Ruiz",
        "contacto_emergencia_telefono": "5534567890",
        "numero_tarjeta": "TAR1003",
        "fecha_inicio": "2025-01-01",
        "fecha_vencimiento": "2026-10-30", # Vencida (fecha pasada en 2026)
        "esta_activa": True
    },
    {
        "numero_trabajador": "TR004",
        "nombre_completo": "Pedro Antonio Díaz Vargas",
        "edad": 38,
        "sexo": "Masculino",
        "curp": "DIVP881105HDFRRD04",
        "correo": "pedro.diaz@institucion.edu.mx",
        "area_adscripcion": "Biblioteca",
        "cargo": "Jefe de Acervo Documental",
        "fotografia_url": generate_svg_avatar("PD", "#7c3aed"),
        "contacto_emergencia_nombre": "Laura Vargas",
        "contacto_emergencia_telefono": "5545678901",
        "numero_tarjeta": "TAR1004",
        "fecha_inicio": "2026-01-01",
        "fecha_vencimiento": "2026-12-31",
        "esta_activa": True # Vigente
    },
    {
        "numero_trabajador": "TR005",
        "nombre_completo": "Laura Patricia Mendoza Flores",
        "edad": 31,
        "sexo": "Femenino",
        "curp": "MEFL950414MDFNNL05",
        "correo": "laura.mendoza@institucion.edu.mx",
        "area_adscripcion": "Sistemas",
        "cargo": "Administradora de Servidores",
        "fotografia_url": generate_svg_avatar("LM", "#0284c7"),
        "contacto_emergencia_nombre": "Patricia Flores",
        "contacto_emergencia_telefono": "5556789012",
        "numero_tarjeta": "TAR1005",
        "fecha_inicio": "2026-02-01",
        "fecha_vencimiento": "2027-02-01",
        "esta_activa": True # Vigente
    },
    {
        "numero_trabajador": "TR006",
        "nombre_completo": "Carlos Eduardo Ramírez Silva",
        "edad": 45,
        "sexo": "Masculino",
        "curp": "RASC810930HDFRML06",
        "correo": "carlos.ramirez@institucion.edu.mx",
        "area_adscripcion": "Mantenimiento",
        "cargo": "Supervisor de Infraestructura",
        "fotografia_url": generate_svg_avatar("CR", "#d97706"),
        "contacto_emergencia_nombre": "Gabriela Silva",
        "contacto_emergencia_telefono": "5567890123",
        "numero_tarjeta": "TAR1006",
        "fecha_inicio": "2026-01-15",
        "fecha_vencimiento": "2027-01-15",
        "esta_activa": True # Vigente
    },
    {
        "numero_trabajador": "TR007",
        "nombre_completo": "Valeria Ivonne Castro Ortiz",
        "edad": 27,
        "sexo": "Femenino",
        "curp": "CAOV990618MDFSTV07",
        "correo": "valeria.castro@institucion.edu.mx",
        "area_adscripcion": "Recursos Humanos",
        "cargo": "Analista de Nóminas",
        "fotografia_url": generate_svg_avatar("VC", "#ec4899"),
        "contacto_emergencia_nombre": "Javier Castro",
        "contacto_emergencia_telefono": "5578901234",
        "numero_tarjeta": "TAR1007",
        "fecha_inicio": "2026-03-01",
        "fecha_vencimiento": "2027-03-01",
        "esta_activa": True # Vigente
    },
    {
        "numero_trabajador": "TR008",
        "nombre_completo": "Fernando Miguel Torres Aguilar",
        "edad": 36,
        "sexo": "Masculino",
        "curp": "TOAF900228HDFRNF08",
        "correo": "fernando.torres@institucion.edu.mx",
        "area_adscripcion": "Administración",
        "cargo": "Auditor Interno",
        "fotografia_url": generate_svg_avatar("FT", "#4f46e5"),
        "contacto_emergencia_nombre": "Susana Aguilar",
        "contacto_emergencia_telefono": "5589012345",
        "numero_tarjeta": "TAR1008",
        "fecha_inicio": "2026-12-01",
        "fecha_vencimiento": "2027-12-01", # No vigente (inicio futuro)
        "esta_activa": True
    },
    {
        "numero_trabajador": "TR009",
        "nombre_completo": "Gabriela Elizabeth Morales Vega",
        "edad": 33,
        "sexo": "Femenino",
        "curp": "MOVG931210MDFRBG09",
        "correo": "gabriela.morales@institucion.edu.mx",
        "area_adscripcion": "Biblioteca",
        "cargo": "Encargada de Préstamos y Archivo",
        "fotografia_url": generate_svg_avatar("GM", "#059669"),
        "contacto_emergencia_nombre": "Raúl Morales",
        "contacto_emergencia_telefono": "5590123456",
        "numero_tarjeta": "TAR1009",
        "fecha_inicio": "2026-01-01",
        "fecha_vencimiento": "2026-12-31",
        "esta_activa": True # Vigente
    },
    {
        "numero_trabajador": "TR010",
        "nombre_completo": "Jorge Luis Herrera Nava",
        "edad": 50,
        "sexo": "Masculino",
        "curp": "HENJ760722HDFRLJ10",
        "correo": "jorge.herrera@institucion.edu.mx",
        "area_adscripcion": "Dirección General",
        "cargo": "Subdirector Operativo",
        "fotografia_url": generate_svg_avatar("JH", "#1e3a8a"),
        "contacto_emergencia_nombre": "Silvia Nava",
        "contacto_emergencia_telefono": "5501234567",
        "numero_tarjeta": "TAR1010",
        "fecha_inicio": "2026-01-01",
        "fecha_vencimiento": "2027-06-30",
        "esta_activa": True # Vigente
    }
]

def seed_database():
    """Initializes tables, creates the admin user, and preloads 10 sample workers."""
    init_db()

    # 1. Admin user
    admin_pass = hash_password("admin123")
    create_admin_user("Administrador General", "admin@institucion.edu.mx", admin_pass)

    # 2. Check if workers already exist
    existing = get_all_workers()
    if len(existing) < 10:
        print(f"[SEED] Insertando trabajadores de prueba (actual: {len(existing)})...")
        existing_numbers = {w["numero_trabajador"] for w in existing}
        for w_data in WORKERS_SEED:
            if w_data["numero_trabajador"] not in existing_numbers:
                create_worker(w_data)
        print(f"[SEED] 10 Trabajadores listos para el desafío.")
    else:
        print(f"[SEED] Base de datos ya cuenta con {len(existing)} trabajadores.")

if __name__ == "__main__":
    seed_database()
