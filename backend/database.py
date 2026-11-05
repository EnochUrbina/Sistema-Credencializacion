import os
import uuid
import sqlite3
from datetime import datetime, date
from typing import List, Dict, Any, Optional

DATABASE_URL = os.getenv("DATABASE_URL", "")

IS_POSTGRES = bool(DATABASE_URL and DATABASE_URL.startswith("postgres"))

if IS_POSTGRES:
    import psycopg2
    from psycopg2.extras import RealDictCursor

def get_connection():
    """Returns a database connection (PostgreSQL or fallback SQLite)."""
    global IS_POSTGRES
    if IS_POSTGRES:
        try:
            conn = psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor, connect_timeout=10)
            conn.autocommit = True
            return conn
        except Exception as e:
            print(f"[ALERTA DATABASE] Error al conectar a PostgreSQL ({e}). Cambiando a SQLite de respaldo.")
            IS_POSTGRES = False

    db_path = os.path.join(os.path.dirname(__file__), "..", "credenciales.db")
    conn = sqlite3.connect(db_path, timeout=30.0, check_same_thread=False)
    try:
        conn.execute("PRAGMA journal_mode = WAL;")
        conn.execute("PRAGMA busy_timeout = 30000;")
        conn.execute("PRAGMA foreign_keys = ON;")
    except Exception:
        pass
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    """Initializes tables, catalogs, views and triggers."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        if IS_POSTGRES:
            # Execute the new normalized PostgreSQL schema if not exists
            cur.execute("""
            CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
            CREATE EXTENSION IF NOT EXISTS "pgcrypto";

            CREATE OR REPLACE FUNCTION trigger_actualizar_timestamp()
            RETURNS TRIGGER AS $$
            BEGIN
                NEW.actualizado_en = CURRENT_TIMESTAMP;
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;

            CREATE TABLE IF NOT EXISTS usuarios_admin (
                id SERIAL PRIMARY KEY,
                nombre VARCHAR(100) NOT NULL,
                correo VARCHAR(120) UNIQUE NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS areas (
                id SERIAL PRIMARY KEY,
                nombre VARCHAR(100) UNIQUE NOT NULL
            );

            CREATE TABLE IF NOT EXISTS cargos (
                id SERIAL PRIMARY KEY,
                nombre VARCHAR(100) UNIQUE NOT NULL
            );

            CREATE TABLE IF NOT EXISTS trabajadores (
                id SERIAL PRIMARY KEY,
                numero_trabajador VARCHAR(20) UNIQUE NOT NULL,
                nombre_completo VARCHAR(150) NOT NULL,
                edad INTEGER NOT NULL CHECK (edad >= 18),
                sexo VARCHAR(20) NOT NULL,
                curp VARCHAR(18) UNIQUE NOT NULL,
                correo VARCHAR(120) UNIQUE NOT NULL,
                area_id INTEGER NOT NULL REFERENCES areas(id) ON DELETE RESTRICT,
                cargo_id INTEGER NOT NULL REFERENCES cargos(id) ON DELETE RESTRICT,
                fotografia_url TEXT DEFAULT 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
                contacto_emergencia_nombre VARCHAR(150) NOT NULL,
                contacto_emergencia_telefono VARCHAR(20) NOT NULL,
                creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS credenciales (
                id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                trabajador_id INTEGER UNIQUE NOT NULL REFERENCES trabajadores(id) ON DELETE CASCADE,
                numero_tarjeta VARCHAR(50) UNIQUE NOT NULL,
                fecha_inicio DATE NOT NULL,
                fecha_vencimiento DATE NOT NULL,
                esta_activa BOOLEAN DEFAULT TRUE NOT NULL,
                actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT chk_fechas_vigencia CHECK (fecha_vencimiento >= fecha_inicio)
            );

            CREATE TABLE IF NOT EXISTS historial_notificaciones (
                id SERIAL PRIMARY KEY,
                trabajador_id INTEGER NOT NULL REFERENCES trabajadores(id) ON DELETE CASCADE,
                numero_tarjeta VARCHAR(50) NOT NULL,
                tipo_evento VARCHAR(50) NOT NULL,
                correo_destinatario VARCHAR(120) NOT NULL,
                estado_notificacion VARCHAR(30) NOT NULL,
                enviado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );

            CREATE OR REPLACE VIEW vista_credenciales_completa 
            WITH (security_invoker = true) AS
            SELECT 
                c.id AS credencial_id,
                c.numero_tarjeta,
                c.fecha_inicio,
                c.fecha_vencimiento,
                c.esta_activa,
                c.actualizado_en,
                t.id AS trabajador_id,
                t.numero_trabajador,
                t.nombre_completo,
                t.edad,
                t.sexo,
                t.curp,
                t.correo,
                a.id AS area_id,
                a.nombre AS area_adscripcion,
                cg.id AS cargo_id,
                cg.nombre AS cargo,
                t.fotografia_url,
                t.contacto_emergencia_nombre,
                t.contacto_emergencia_telefono,
                CASE 
                    WHEN c.esta_activa = FALSE THEN 'Inactiva'
                    WHEN CURRENT_DATE > c.fecha_vencimiento THEN 'Vencida'
                    WHEN CURRENT_DATE < c.fecha_inicio THEN 'No vigente'
                    ELSE 'Vigente'
                END AS estado_calculado
            FROM credenciales c
            INNER JOIN trabajadores t ON c.trabajador_id = t.id
            INNER JOIN areas a ON t.area_id = a.id
            INNER JOIN cargos cg ON t.cargo_id = cg.id;

            CREATE OR REPLACE VIEW vista_qr_publico AS
            SELECT 
                t.id AS trabajador_id,
                c.id AS credencial_id,
                c.numero_tarjeta,
                c.fecha_inicio,
                c.fecha_vencimiento,
                c.esta_activa,
                t.numero_trabajador,
                t.nombre_completo,
                a.nombre AS area_adscripcion,
                cg.nombre AS cargo,
                t.fotografia_url,
                CASE 
                    WHEN c.esta_activa = FALSE THEN 'Inactiva'
                    WHEN CURRENT_DATE > c.fecha_vencimiento THEN 'Vencida'
                    WHEN CURRENT_DATE < c.fecha_inicio THEN 'No vigente'
                    ELSE 'Vigente'
                END AS estado_calculado
            FROM credenciales c
            INNER JOIN trabajadores t ON c.trabajador_id = t.id
            INNER JOIN areas a ON t.area_id = a.id
            INNER JOIN cargos cg ON t.cargo_id = cg.id;
            """)
        else:
            # SQLite matching schema
            cur.executescript("""
            CREATE TABLE IF NOT EXISTS usuarios_admin (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre TEXT NOT NULL,
                correo TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS areas (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre TEXT UNIQUE NOT NULL
            );

            CREATE TABLE IF NOT EXISTS cargos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre TEXT UNIQUE NOT NULL
            );

            CREATE TABLE IF NOT EXISTS trabajadores (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                numero_trabajador TEXT UNIQUE NOT NULL,
                nombre_completo TEXT NOT NULL,
                edad INTEGER NOT NULL CHECK (edad >= 18),
                sexo TEXT NOT NULL,
                curp TEXT UNIQUE NOT NULL,
                correo TEXT UNIQUE NOT NULL,
                area_id INTEGER NOT NULL REFERENCES areas(id),
                cargo_id INTEGER NOT NULL REFERENCES cargos(id),
                fotografia_url TEXT NOT NULL,
                contacto_emergencia_nombre TEXT NOT NULL,
                contacto_emergencia_telefono TEXT NOT NULL,
                creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS credenciales (
                id TEXT PRIMARY KEY,
                trabajador_id INTEGER UNIQUE NOT NULL REFERENCES trabajadores(id) ON DELETE CASCADE,
                numero_tarjeta TEXT UNIQUE NOT NULL,
                fecha_inicio TEXT NOT NULL,
                fecha_vencimiento TEXT NOT NULL,
                esta_activa INTEGER DEFAULT 1 NOT NULL,
                actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                CHECK (fecha_vencimiento >= fecha_inicio)
            );

            CREATE TABLE IF NOT EXISTS historial_notificaciones (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                trabajador_id INTEGER NOT NULL REFERENCES trabajadores(id) ON DELETE CASCADE,
                numero_tarjeta TEXT NOT NULL,
                tipo_evento TEXT NOT NULL,
                correo_destinatario TEXT NOT NULL,
                estado_notificacion TEXT NOT NULL,
                enviado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            DROP VIEW IF EXISTS vista_credenciales_completa;
            CREATE VIEW vista_credenciales_completa AS
            SELECT 
                c.id AS credencial_id,
                c.numero_tarjeta,
                c.fecha_inicio,
                c.fecha_vencimiento,
                CASE WHEN c.esta_activa = 1 THEN 1 ELSE 0 END AS esta_activa,
                c.actualizado_en,
                t.id AS trabajador_id,
                t.numero_trabajador,
                t.nombre_completo,
                t.edad,
                t.sexo,
                t.curp,
                t.correo,
                a.id AS area_id,
                a.nombre AS area_adscripcion,
                cg.id AS cargo_id,
                cg.nombre AS cargo,
                t.fotografia_url,
                t.contacto_emergencia_nombre,
                t.contacto_emergencia_telefono,
                CASE 
                    WHEN c.esta_activa = 0 THEN 'Inactiva'
                    WHEN date('now', 'localtime') > c.fecha_vencimiento THEN 'Vencida'
                    WHEN date('now', 'localtime') < c.fecha_inicio THEN 'No vigente'
                    ELSE 'Vigente'
                END AS estado_calculado
            FROM credenciales c
            INNER JOIN trabajadores t ON c.trabajador_id = t.id
            INNER JOIN areas a ON t.area_id = a.id
            INNER JOIN cargos cg ON t.cargo_id = cg.id;

            DROP VIEW IF EXISTS vista_qr_publico;
            CREATE VIEW vista_qr_publico AS
            SELECT 
                t.id AS trabajador_id,
                c.id AS credencial_id,
                c.numero_tarjeta,
                c.fecha_inicio,
                c.fecha_vencimiento,
                CASE WHEN c.esta_activa = 1 THEN 1 ELSE 0 END AS esta_activa,
                t.numero_trabajador,
                t.nombre_completo,
                a.nombre AS area_adscripcion,
                cg.nombre AS cargo,
                t.fotografia_url,
                CASE 
                    WHEN c.esta_activa = 0 THEN 'Inactiva'
                    WHEN date('now', 'localtime') > c.fecha_vencimiento THEN 'Vencida'
                    WHEN date('now', 'localtime') < c.fecha_inicio THEN 'No vigente'
                    ELSE 'Vigente'
                END AS estado_calculado
            FROM credenciales c
            INNER JOIN trabajadores t ON c.trabajador_id = t.id
            INNER JOIN areas a ON t.area_id = a.id
            INNER JOIN cargos cg ON t.cargo_id = cg.id;
            """)
            conn.commit()
    finally:
        conn.close()

def _row_to_dict(row) -> Dict[str, Any]:
    """Converts a database row into a standard Python dict with typed fields."""
    if row is None:
        return None
    d = dict(row)
    if "esta_activa" in d:
        d["esta_activa"] = bool(d["esta_activa"])
    if "fecha_inicio" in d and isinstance(d["fecha_inicio"], (date, datetime)):
        d["fecha_inicio"] = d["fecha_inicio"].strftime("%Y-%m-%d")
    if "fecha_vencimiento" in d and isinstance(d["fecha_vencimiento"], (date, datetime)):
        d["fecha_vencimiento"] = d["fecha_vencimiento"].strftime("%Y-%m-%d")
    if "credencial_id" in d and d["credencial_id"] is not None:
        d["credencial_id"] = str(d["credencial_id"])
    return d

def get_or_create_area(nombre: str, cur=None) -> int:
    """Finds area ID by name or inserts a new one into the areas catalog."""
    nombre = (nombre or "General").strip()
    owns_conn = False
    if cur is None:
        conn = get_connection()
        cur = conn.cursor()
        owns_conn = True
    else:
        conn = getattr(cur, "connection", None)

    try:
        if IS_POSTGRES:
            cur.execute("SELECT id FROM areas WHERE LOWER(nombre) = LOWER(%s)", (nombre,))
            row = cur.fetchone()
            if row:
                return row["id"]
            cur.execute("INSERT INTO areas (nombre) VALUES (%s) RETURNING id", (nombre,))
            res = cur.fetchone()["id"]
            if conn:
                conn.commit()
            return res
        else:
            cur.execute("SELECT id FROM areas WHERE LOWER(nombre) = LOWER(?)", (nombre,))
            row = cur.fetchone()
            if row:
                return row["id"]
            cur.execute("INSERT INTO areas (nombre) VALUES (?)", (nombre,))
            if conn:
                conn.commit()
            return cur.lastrowid
    finally:
        if owns_conn and conn:
            conn.close()

def get_or_create_cargo(nombre: str, cur=None) -> int:
    """Finds cargo ID by name or inserts a new one into the cargos catalog."""
    nombre = (nombre or "Personal").strip()
    owns_conn = False
    if cur is None:
        conn = get_connection()
        cur = conn.cursor()
        owns_conn = True
    else:
        conn = getattr(cur, "connection", None)

    try:
        if IS_POSTGRES:
            cur.execute("SELECT id FROM cargos WHERE LOWER(nombre) = LOWER(%s)", (nombre,))
            row = cur.fetchone()
            if row:
                return row["id"]
            cur.execute("INSERT INTO cargos (nombre) VALUES (%s) RETURNING id", (nombre,))
            res = cur.fetchone()["id"]
            if conn:
                conn.commit()
            return res
        else:
            cur.execute("SELECT id FROM cargos WHERE LOWER(nombre) = LOWER(?)", (nombre,))
            row = cur.fetchone()
            if row:
                return row["id"]
            cur.execute("INSERT INTO cargos (nombre) VALUES (?)", (nombre,))
            if conn:
                conn.commit()
            return cur.lastrowid
    finally:
        if owns_conn and conn:
            conn.close()

def get_all_workers() -> List[Dict[str, Any]]:
    """Returns all workers from vista_credenciales_completa."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM vista_credenciales_completa ORDER BY trabajador_id ASC")
        rows = cur.fetchall()
        return [_row_to_dict(r) for r in rows]
    finally:
        conn.close()

def check_worker_duplicates(data: dict, exclude_trabajador_id: Optional[int] = None) -> Dict[str, List[str]]:
    """Checks for duplicate numero_trabajador, numero_tarjeta, curp, and correo."""
    errors = {}
    conn = get_connection()
    try:
        cur = conn.cursor()
        num_trab = str(data.get("numero_trabajador") or "").strip().upper()
        num_tarj = str(data.get("numero_tarjeta") or "").strip().upper()
        curp_val = str(data.get("curp") or "").strip().upper()
        correo_val = str(data.get("correo") or "").strip().lower()

        cur.execute("SELECT trabajador_id, numero_trabajador, numero_tarjeta, curp, correo FROM vista_credenciales_completa")
        rows = cur.fetchall()
        for r in rows:
            tid = r["trabajador_id"]
            if exclude_trabajador_id and int(tid) == int(exclude_trabajador_id):
                continue
            if num_trab and str(r["numero_trabajador"] or "").strip().upper() == num_trab:
                errors["numero_trabajador"] = ["Este número de trabajador ya está registrado por otro empleado."]
            if num_tarj and str(r["numero_tarjeta"] or "").strip().upper() == num_tarj:
                errors["numero_tarjeta"] = ["Este número de tarjeta ya está asignado a otra credencial."]
            if curp_val and str(r["curp"] or "").strip().upper() == curp_val:
                errors["curp"] = ["Esta CURP ya se encuentra registrada en el sistema."]
            if correo_val and str(r["correo"] or "").strip().lower() == correo_val:
                errors["correo"] = ["Este correo electrónico ya está registrado por otro trabajador."]
        return errors
    finally:
        conn.close()

def get_worker_view_by_id(trabajador_id: int) -> Optional[Dict[str, Any]]:
    """Gets a worker from the view by trabajador_id."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        if IS_POSTGRES:
            cur.execute("SELECT * FROM vista_credenciales_completa WHERE trabajador_id = %s", (trabajador_id,))
        else:
            cur.execute("SELECT * FROM vista_credenciales_completa WHERE trabajador_id = ?", (trabajador_id,))
        row = cur.fetchone()
        return _row_to_dict(row)
    finally:
        conn.close()

def get_worker_view_by_credencial_id(credencial_id: str) -> Optional[Dict[str, Any]]:
    """Gets a worker from the view by credencial_id (UUID or token)."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        if IS_POSTGRES:
            cur.execute("SELECT * FROM vista_credenciales_completa WHERE credencial_id::text = %s", (str(credencial_id),))
        else:
            cur.execute("SELECT * FROM vista_credenciales_completa WHERE credencial_id = ?", (str(credencial_id),))
        row = cur.fetchone()
        return _row_to_dict(row)
    finally:
        conn.close()

def get_qr_public_view_by_credencial_id(credencial_id: str) -> Optional[Dict[str, Any]]:
    """Gets public projection from vista_qr_publico."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        if IS_POSTGRES:
            cur.execute("SELECT * FROM vista_qr_publico WHERE credencial_id::text = %s", (str(credencial_id),))
        else:
            cur.execute("SELECT * FROM vista_qr_publico WHERE credencial_id = ?", (str(credencial_id),))
        row = cur.fetchone()
        return _row_to_dict(row)
    finally:
        conn.close()

def create_worker(data: dict) -> Dict[str, Any]:
    """
    Inserts into areas/cargos catalogs, then trabajadores and credenciales,
    and returns the row from vista_credenciales_completa.
    """
    conn = get_connection()
    try:
        cur = conn.cursor()
        area_nombre = data.get("area_adscripcion") or data.get("area") or "General"
        cargo_nombre = data.get("cargo") or "Personal"
        area_id = data.get("area_id") or get_or_create_area(area_nombre, cur=cur)
        cargo_id = data.get("cargo_id") or get_or_create_cargo(cargo_nombre, cur=cur)

        cred_uuid = str(uuid.uuid4())
        activa_val = 1 if data.get("esta_activa", True) else 0

        if IS_POSTGRES:
            activa_val = bool(data.get("esta_activa", True))
            cur.execute("""
                INSERT INTO trabajadores (
                    numero_trabajador, nombre_completo, edad, sexo, curp, correo,
                    area_id, cargo_id, fotografia_url, contacto_emergencia_nombre,
                    contacto_emergencia_telefono
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
            """, (
                data["numero_trabajador"], data["nombre_completo"], int(data["edad"]),
                data["sexo"], data["curp"], data["correo"], area_id,
                cargo_id, data["fotografia_url"], data["contacto_emergencia_nombre"],
                data["contacto_emergencia_telefono"]
            ))
            trabajador_id = cur.fetchone()["id"]

            cur.execute("""
                INSERT INTO credenciales (
                    id, trabajador_id, numero_tarjeta, fecha_inicio, fecha_vencimiento, esta_activa
                ) VALUES (%s, %s, %s, %s, %s, %s)
            """, (
                cred_uuid, trabajador_id, data["numero_tarjeta"],
                data["fecha_inicio"], data["fecha_vencimiento"], activa_val
            ))
            conn.commit()
        else:
            cur.execute("""
                INSERT INTO trabajadores (
                    numero_trabajador, nombre_completo, edad, sexo, curp, correo,
                    area_id, cargo_id, fotografia_url, contacto_emergencia_nombre,
                    contacto_emergencia_telefono
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                data["numero_trabajador"], data["nombre_completo"], int(data["edad"]),
                data["sexo"], data["curp"], data["correo"], area_id,
                cargo_id, data["fotografia_url"], data["contacto_emergencia_nombre"],
                data["contacto_emergencia_telefono"]
            ))
            trabajador_id = cur.lastrowid

            cur.execute("""
                INSERT INTO credenciales (
                    id, trabajador_id, numero_tarjeta, fecha_inicio, fecha_vencimiento, esta_activa
                ) VALUES (?, ?, ?, ?, ?, ?)
            """, (
                cred_uuid, trabajador_id, data["numero_tarjeta"],
                data["fecha_inicio"], data["fecha_vencimiento"], activa_val
            ))
            conn.commit()
    finally:
        conn.close()

    return get_worker_view_by_id(trabajador_id)

def update_worker(trabajador_id: int, data: dict) -> Dict[str, Any]:
    """Updates an existing worker and their credencial."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        area_nombre = data.get("area_adscripcion") or data.get("area") or "General"
        cargo_nombre = data.get("cargo") or "Personal"
        area_id = data.get("area_id") or get_or_create_area(area_nombre, cur=cur)
        cargo_id = data.get("cargo_id") or get_or_create_cargo(cargo_nombre, cur=cur)

        activa_val = 1 if data.get("esta_activa", True) else 0

        if IS_POSTGRES:
            activa_val = bool(data.get("esta_activa", True))
            cur.execute("""
                UPDATE trabajadores SET
                    numero_trabajador = %s,
                    nombre_completo = %s,
                    edad = %s,
                    sexo = %s,
                    curp = %s,
                    correo = %s,
                    area_id = %s,
                    cargo_id = %s,
                    fotografia_url = COALESCE(NULLIF(%s, ''), fotografia_url),
                    contacto_emergencia_nombre = %s,
                    contacto_emergencia_telefono = %s
                WHERE id = %s
            """, (
                data["numero_trabajador"], data["nombre_completo"], int(data["edad"]),
                data["sexo"], data["curp"], data["correo"], area_id,
                cargo_id, data.get("fotografia_url", ""),
                data["contacto_emergencia_nombre"], data["contacto_emergencia_telefono"],
                trabajador_id
            ))

            cur.execute("""
                UPDATE credenciales SET
                    numero_tarjeta = %s,
                    fecha_inicio = %s,
                    fecha_vencimiento = %s,
                    esta_activa = %s,
                    actualizado_en = CURRENT_TIMESTAMP
                WHERE trabajador_id = %s
            """, (
                data["numero_tarjeta"], data["fecha_inicio"], data["fecha_vencimiento"],
                activa_val, trabajador_id
            ))
            conn.commit()
        else:
            foto_val = data.get("fotografia_url") or ""
            cur.execute("""
                UPDATE trabajadores SET
                    numero_trabajador = ?,
                    nombre_completo = ?,
                    edad = ?,
                    sexo = ?,
                    curp = ?,
                    correo = ?,
                    area_id = ?,
                    cargo_id = ?,
                    fotografia_url = CASE WHEN ? != '' AND ? IS NOT NULL THEN ? ELSE fotografia_url END,
                    contacto_emergencia_nombre = ?,
                    contacto_emergencia_telefono = ?
                WHERE id = ?
            """, (
                data["numero_trabajador"], data["nombre_completo"], int(data["edad"]),
                data["sexo"], data["curp"], data["correo"], area_id,
                cargo_id, foto_val, foto_val, foto_val,
                data["contacto_emergencia_nombre"], data["contacto_emergencia_telefono"],
                trabajador_id
            ))

            cur.execute("""
                UPDATE credenciales SET
                    numero_tarjeta = ?,
                    fecha_inicio = ?,
                    fecha_vencimiento = ?,
                    esta_activa = ?,
                    actualizado_en = CURRENT_TIMESTAMP
                WHERE trabajador_id = ?
            """, (
                data["numero_tarjeta"], data["fecha_inicio"], data["fecha_vencimiento"],
                activa_val, trabajador_id
            ))
            conn.commit()
    finally:
        conn.close()

    return get_worker_view_by_id(trabajador_id)

def toggle_credencial_status(credencial_id: str, esta_activa: bool) -> Optional[Dict[str, Any]]:
    """Activates or deactivates a credencial."""
    conn = get_connection()
    cid_str = str(credencial_id).strip()
    try:
        cur = conn.cursor()
        activa_val = 1 if esta_activa else 0
        if IS_POSTGRES:
            activa_val = bool(esta_activa)
            cur.execute("""
                UPDATE credenciales
                SET esta_activa = %s, actualizado_en = CURRENT_TIMESTAMP
                WHERE id::text = %s
            """, (activa_val, cid_str))
            conn.commit()
        else:
            cur.execute("""
                UPDATE credenciales
                SET esta_activa = ?, actualizado_en = CURRENT_TIMESTAMP
                WHERE id = ?
            """, (activa_val, cid_str))
            conn.commit()
    finally:
        conn.close()

    return get_worker_view_by_credencial_id(cid_str)

def add_notification_history(trabajador_id: int, numero_tarjeta: str, tipo_evento: str, correo: str, estado: str):
    """Inserts an audit record in historial_notificaciones."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        if IS_POSTGRES:
            cur.execute("""
                INSERT INTO historial_notificaciones (
                    trabajador_id, numero_tarjeta, tipo_evento, correo_destinatario, estado_notificacion
                ) VALUES (%s, %s, %s, %s, %s)
            """, (trabajador_id, numero_tarjeta, tipo_evento, correo, estado))
            conn.commit()
        else:
            cur.execute("""
                INSERT INTO historial_notificaciones (
                    trabajador_id, numero_tarjeta, tipo_evento, correo_destinatario, estado_notificacion
                ) VALUES (?, ?, ?, ?, ?)
            """, (trabajador_id, numero_tarjeta, tipo_evento, correo, estado))
            conn.commit()
    finally:
        conn.close()

def get_notification_history() -> List[Dict[str, Any]]:
    """Returns the list of sent notifications."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM historial_notificaciones ORDER BY id DESC")
        rows = cur.fetchall()
        return [_row_to_dict(r) for r in rows]
    finally:
        conn.close()

def get_admin_user(correo: str) -> Optional[Dict[str, Any]]:
    """Finds an admin user by email."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        if IS_POSTGRES:
            cur.execute("SELECT * FROM usuarios_admin WHERE correo = %s", (correo,))
        else:
            cur.execute("SELECT * FROM usuarios_admin WHERE correo = ?", (correo,))
        row = cur.fetchone()
        return _row_to_dict(row)
    finally:
        conn.close()

def create_admin_user(nombre: str, correo: str, password_hash: str):
    """Creates a new admin user."""
    conn = get_connection()
    try:
        cur = conn.cursor()
        if IS_POSTGRES:
            cur.execute("""
                INSERT INTO usuarios_admin (nombre, correo, password_hash)
                VALUES (%s, %s, %s)
                ON CONFLICT (correo) DO NOTHING
            """, (nombre, correo, password_hash))
        else:
            cur.execute("""
                INSERT OR IGNORE INTO usuarios_admin (nombre, correo, password_hash)
                VALUES (?, ?, ?)
            """, (nombre, correo, password_hash))
            conn.commit()
    finally:
        conn.close()
