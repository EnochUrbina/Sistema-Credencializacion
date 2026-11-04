-- =============================================================================
-- SISTEMA DE CREDENCIALIZACIÓN WEB - ESQUEMA ESTRUCTURAL (NORMALIZADO)
-- =============================================================================

-- 0. REINICIO LIMPIO (ELIMINACIÓN DE OBJETOS PREVIOS EN CASCADA)
DROP VIEW IF EXISTS vista_qr_publico CASCADE;
DROP VIEW IF EXISTS vista_credenciales_completa CASCADE;
DROP FUNCTION IF EXISTS trigger_actualizar_timestamp CASCADE;
DROP TABLE IF EXISTS historial_notificaciones CASCADE;
DROP TABLE IF EXISTS credenciales CASCADE;
DROP TABLE IF EXISTS trabajadores CASCADE;
DROP TABLE IF EXISTS cargos CASCADE;
DROP TABLE IF EXISTS areas CASCADE;
DROP TABLE IF EXISTS usuarios_admin CASCADE;

-- Extensiones requeridas para UUIDs y funciones de encriptación (bcrypt)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. FUNCIÓN Y DISPARADOR (TRIGGER) PARA ACTUALIZACIÓN DE TIMESTAMPS
-- =============================================================================

CREATE OR REPLACE FUNCTION trigger_actualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- 2. TABLAS DE CATÁLOGOS Y AUTENTICACIÓN
-- =============================================================================

-- Control de acceso administrativo (LoginView.jsx)
CREATE TABLE usuarios_admin (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(120) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Catálogo normalizado de Áreas de adscripción
CREATE TABLE areas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

-- Catálogo normalizado de Cargos / Puestos laborales
CREATE TABLE cargos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

-- =============================================================================
-- 3. TABLAS OPERATIVAS PRINCIPALES
-- =============================================================================

-- Expediente completo del trabajador
CREATE TABLE trabajadores (
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

-- Emisión de tarjetas y token seguro para el QR
CREATE TABLE credenciales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trabajador_id INTEGER UNIQUE NOT NULL REFERENCES trabajadores(id) ON DELETE CASCADE,
    numero_tarjeta VARCHAR(50) UNIQUE NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    esta_activa BOOLEAN DEFAULT TRUE NOT NULL,
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_fechas_vigencia CHECK (fecha_vencimiento >= fecha_inicio)
);

-- Auditoría de avisos enviados por correo electrónico
CREATE TABLE historial_notificaciones (
    id SERIAL PRIMARY KEY,
    trabajador_id INTEGER NOT NULL REFERENCES trabajadores(id) ON DELETE CASCADE,
    numero_tarjeta VARCHAR(50) NOT NULL,
    tipo_evento VARCHAR(50) NOT NULL, -- 'Nueva credencial', 'Desactivación', 'Modificación vigencia'
    correo_destinatario VARCHAR(120) NOT NULL,
    estado_notificacion VARCHAR(30) NOT NULL,
    enviado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Disparador para actualizar 'actualizado_en' en credenciales
CREATE TRIGGER trg_actualizar_credenciales
BEFORE UPDATE ON credenciales
FOR EACH ROW
EXECUTE FUNCTION trigger_actualizar_timestamp();

-- =============================================================================
-- 4. ÍNDICES DE RENDIMIENTO (OPTIMIZADOS PARA JOINS Y CONSULTAS)
-- =============================================================================

CREATE INDEX idx_trabajadores_area_id ON trabajadores(area_id);
CREATE INDEX idx_trabajadores_cargo_id ON trabajadores(cargo_id);
CREATE INDEX idx_credenciales_trabajador_id ON credenciales(trabajador_id);
CREATE INDEX idx_notificaciones_trabajador_id ON historial_notificaciones(trabajador_id);

-- =============================================================================
-- 5. SEGURIDAD A NIVEL DE FILA (RLS) Y POLÍTICAS OPERATIVAS
-- =============================================================================

ALTER TABLE usuarios_admin ENABLE ROW LEVEL SECURITY;
ALTER TABLE areas ENABLE ROW LEVEL SECURITY;
ALTER TABLE cargos ENABLE ROW LEVEL SECURITY;
ALTER TABLE trabajadores ENABLE ROW LEVEL SECURITY;
ALTER TABLE credenciales ENABLE ROW LEVEL SECURITY;
ALTER TABLE historial_notificaciones ENABLE ROW LEVEL SECURITY;

-- Catálogos: lectura pública (para selects de formularios) y control total al admin
CREATE POLICY "Lectura publica areas" ON areas 
    FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Gestion total areas" ON areas 
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Lectura publica cargos" ON cargos 
    FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "Gestion total cargos" ON cargos 
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Gestión operativa exclusiva para administradores autenticados
CREATE POLICY "Admin gestion total trabajadores" ON trabajadores 
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Admin gestion total credenciales" ON credenciales 
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Admin gestion total notificaciones" ON historial_notificaciones 
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Admin gestion total usuarios" ON usuarios_admin 
    FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- =============================================================================
-- 6. VISTAS SQL (CÁLCULO DINÁMICO DE ESTADOS)
-- =============================================================================

-- 6.1 Vista interna completa para el panel administrativo, auditoría y reportes
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

-- 6.2 Vista pública blindada para lectura de código QR
-- (Excluye expresamente CURP y contactos de emergencia por seguridad)
CREATE OR REPLACE VIEW vista_qr_publico 
WITH (security_invoker = false) AS
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

-- Permisos de consulta sobre vistas
GRANT SELECT ON vista_credenciales_completa TO authenticated;
GRANT SELECT ON vista_qr_publico TO anon, authenticated;
