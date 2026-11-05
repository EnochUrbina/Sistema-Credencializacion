-- ==============================================================================
-- CACAO DEL SUR S.A. DE C.V. - ESQUEMA Y DATOS OFICIALES PARA POSTGRESQL / SUPABASE
-- Sistema de Credencialización y Control de Personal Institucional
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Limpieza opcional de tablas previas (en orden de dependencias)
DROP VIEW IF EXISTS vista_trabajadores_completa CASCADE;
DROP TABLE IF EXISTS historial_notificaciones CASCADE;
DROP TABLE IF EXISTS credenciales CASCADE;
DROP TABLE IF EXISTS trabajadores CASCADE;
DROP TABLE IF EXISTS cargos CASCADE;
DROP TABLE IF EXISTS areas CASCADE;
DROP TABLE IF EXISTS usuarios_admin CASCADE;

-- Función de actualización de timestamps
CREATE OR REPLACE FUNCTION trigger_actualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1. Usuarios Administradores
CREATE TABLE usuarios_admin (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(120) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Catálogo de Áreas
CREATE TABLE areas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

-- 3. Catálogo de Cargos
CREATE TABLE cargos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

-- 4. Expedientes de Trabajadores
CREATE TABLE trabajadores (
    id SERIAL PRIMARY KEY,
    numero_trabajador VARCHAR(20) UNIQUE NOT NULL,
    nombre_completo VARCHAR(150) NOT NULL,
    edad INTEGER NOT NULL CHECK (edad >= 18 AND edad <= 99),
    sexo VARCHAR(20) NOT NULL,
    curp VARCHAR(18) UNIQUE NOT NULL,
    correo VARCHAR(120) UNIQUE NOT NULL,
    area_id INTEGER NOT NULL REFERENCES areas(id) ON DELETE RESTRICT,
    cargo_id INTEGER NOT NULL REFERENCES cargos(id) ON DELETE RESTRICT,
    fotografia_url TEXT NOT NULL,
    contacto_emergencia_nombre VARCHAR(100) NOT NULL,
    contacto_emergencia_telefono VARCHAR(15) NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Credenciales Físicas / Digitales
CREATE TABLE credenciales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trabajador_id INTEGER UNIQUE NOT NULL REFERENCES trabajadores(id) ON DELETE CASCADE,
    numero_tarjeta VARCHAR(50) UNIQUE NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    esta_activa BOOLEAN DEFAULT TRUE NOT NULL,
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_fechas_vigencia CHECK (fecha_vencimiento >= fecha_inicio)
);

-- 6. Historial de Notificaciones
CREATE TABLE historial_notificaciones (
    id SERIAL PRIMARY KEY,
    trabajador_id INTEGER NOT NULL REFERENCES trabajadores(id) ON DELETE CASCADE,
    tipo VARCHAR(50) NOT NULL,
    destinatario VARCHAR(120) NOT NULL,
    mensaje TEXT NOT NULL,
    enviado_en TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Triggers de actualización
DROP TRIGGER IF EXISTS trg_actualizar_credenciales ON credenciales;
CREATE TRIGGER trg_actualizar_credenciales
BEFORE UPDATE ON credenciales
FOR EACH ROW EXECUTE FUNCTION trigger_actualizar_timestamp();

-- Vista completa normalizada
CREATE OR REPLACE VIEW vista_trabajadores_completa AS
SELECT 
    t.id,
    t.numero_trabajador,
    t.nombre_completo,
    t.edad,
    t.sexo,
    t.curp,
    t.correo,
    a.nombre AS area_adscripcion,
    c.nombre AS cargo,
    t.fotografia_url,
    t.contacto_emergencia_nombre,
    t.contacto_emergencia_telefono,
    t.creado_en,
    cr.id AS credencial_uuid,
    cr.numero_tarjeta,
    cr.fecha_inicio,
    cr.fecha_vencimiento,
    cr.esta_activa,
    CASE 
        WHEN cr.esta_activa = FALSE THEN 'Inactiva'
        WHEN CURRENT_DATE < cr.fecha_inicio THEN 'Por iniciar'
        WHEN CURRENT_DATE > cr.fecha_vencimiento THEN 'Vencida'
        ELSE 'Vigente'
    END AS estado
FROM trabajadores t
LEFT JOIN areas a ON t.area_id = a.id
LEFT JOIN cargos c ON t.cargo_id = c.id
LEFT JOIN credenciales cr ON t.id = cr.trabajador_id;

-- Inserción de Cuentas Administradoras
INSERT INTO usuarios_admin (nombre, correo, password_hash)
VALUES 
    ('Administrador Cacao del Sur', 'admin@cacaodelsur.com', 'pbkdf2:sha256:100000$30f07a374e88c70a129924da667407b7$ac3bd30c62205b2e0a6be50595750e3c75b569382566147ee0ff9a5133116d7c'),
    ('Administrador General', 'admin@institucion.edu.mx', 'pbkdf2:sha256:100000$30f07a374e88c70a129924da667407b7$ac3bd30c62205b2e0a6be50595750e3c75b569382566147ee0ff9a5133116d7c');

-- Inserción de Áreas Oficiales
INSERT INTO areas (nombre) VALUES
    ('Control de Calidad y Catación'),
    ('Producción y Chocolatería'),
    ('Administración y Finanzas'),
    ('Investigación Agronómica y Campo'),
    ('Logística y Cadena de Suministro'),
    ('Innovación y Maquinaria Agroindustrial'),
    ('Ventas y Exportación Internacional');

-- Inserción de Cargos Especializados
INSERT INTO cargos (nombre) VALUES
    ('Sommelier Principal y Jefa de Catación'),
    ('Maestro Chocolatero de Bombones Finos'),
    ('Directora de Finanzas y Costos Agrícolas'),
    ('Ingeniero Agrónomo de Cacao Criollo'),
    ('Supervisora de Tostado y Molienda Fina'),
    ('Coordinador de Exportación y Cadena en Frío'),
    ('Inspectora de Fermentación y Certificación Orgánica'),
    ('Técnico Especialista en Concheado Industrial'),
    ('Gerente de Cuentas y Comercio Justo'),
    ('Coordinador de Viveros e Injertos de Cacao'),
    ('Artesana de Coberturas y Chocolates de Origen'),
    ('Jefe de Gestión Humana y Cultura Laboral'),
    ('Supervisora de Almacén de Granos Seleccionados');

-- Inserción de 13 Trabajadores de Cacao del Sur y sus Credenciales
DO $$
DECLARE
    t_id_1 INTEGER;
    t_id_2 INTEGER;
    t_id_3 INTEGER;
    t_id_4 INTEGER;
    t_id_5 INTEGER;
    t_id_6 INTEGER;
    t_id_7 INTEGER;
    t_id_8 INTEGER;
    t_id_9 INTEGER;
    t_id_10 INTEGER;
    t_id_11 INTEGER;
    t_id_12 INTEGER;
    t_id_13 INTEGER;
BEGIN

    -- Trabajador 1: Ana Sofía López Morales (CS-CAL-101)
    INSERT INTO trabajadores (
        numero_trabajador, nombre_completo, edad, sexo, curp, correo, 
        area_id, cargo_id, fotografia_url, contacto_emergencia_nombre, contacto_emergencia_telefono
    ) VALUES (
        'CS-CAL-101', 'Ana Sofía López Morales', 29, 'Femenino', 'LOMA970315MCFRLN01', 'ana.lopez@cacaodelsur.com',
        (SELECT id FROM areas WHERE nombre = 'Control de Calidad y Catación'),
        (SELECT id FROM cargos WHERE nombre = 'Sommelier Principal y Jefa de Catación'),
        'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjQzQ4MjNGIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+QUw8L3RleHQ+CiAgICA8L3N2Zz4=', 'Roberto López Morales', '9611234567'
    ) RETURNING id INTO t_id_1;

    INSERT INTO credenciales (
        trabajador_id, numero_tarjeta, fecha_inicio, fecha_vencimiento, esta_activa
    ) VALUES (
        t_id_1, 'TAR-CAL-1001', '2026-01-01', '2026-12-31', TRUE
    );

    -- Trabajador 2: Juan Carlos Pérez Gómez (CS-PRD-102)
    INSERT INTO trabajadores (
        numero_trabajador, nombre_completo, edad, sexo, curp, correo, 
        area_id, cargo_id, fotografia_url, contacto_emergencia_nombre, contacto_emergencia_telefono
    ) VALUES (
        'CS-PRD-102', 'Juan Carlos Pérez Gómez', 34, 'Masculino', 'PEGJ920512HDFRRN02', 'juan.perez@cacaodelsur.com',
        (SELECT id FROM areas WHERE nombre = 'Producción y Chocolatería'),
        (SELECT id FROM cargos WHERE nombre = 'Maestro Chocolatero de Bombones Finos'),
        'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjNUMzMzE3IiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+SlA8L3RleHQ+CiAgICA8L3N2Zz4=', 'Elena Gómez Ruiz', '9612345678'
    ) RETURNING id INTO t_id_2;

    INSERT INTO credenciales (
        trabajador_id, numero_tarjeta, fecha_inicio, fecha_vencimiento, esta_activa
    ) VALUES (
        t_id_2, 'TAR-PRD-1002', '2026-01-01', '2026-12-31', FALSE
    );

    -- Trabajador 3: María Elena Ruiz Hernández (CS-ADM-103)
    INSERT INTO trabajadores (
        numero_trabajador, nombre_completo, edad, sexo, curp, correo, 
        area_id, cargo_id, fotografia_url, contacto_emergencia_nombre, contacto_emergencia_telefono
    ) VALUES (
        'CS-ADM-103', 'María Elena Ruiz Hernández', 42, 'Femenino', 'RUHM840820MDFNZR03', 'maria.ruiz@cacaodelsur.com',
        (SELECT id FROM areas WHERE nombre = 'Administración y Finanzas'),
        (SELECT id FROM cargos WHERE nombre = 'Directora de Finanzas y Costos Agrícolas'),
        'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjOUU1RDI0IiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+TVI8L3RleHQ+CiAgICA8L3N2Zz4=', 'Carlos Ruiz Hernández', '9613456789'
    ) RETURNING id INTO t_id_3;

    INSERT INTO credenciales (
        trabajador_id, numero_tarjeta, fecha_inicio, fecha_vencimiento, esta_activa
    ) VALUES (
        t_id_3, 'TAR-ADM-1003', '2025-01-01', '2026-10-30', TRUE
    );

    -- Trabajador 4: Pedro Antonio Díaz Vargas (CS-AGR-104)
    INSERT INTO trabajadores (
        numero_trabajador, nombre_completo, edad, sexo, curp, correo, 
        area_id, cargo_id, fotografia_url, contacto_emergencia_nombre, contacto_emergencia_telefono
    ) VALUES (
        'CS-AGR-104', 'Pedro Antonio Díaz Vargas', 38, 'Masculino', 'DIVP881105HDFRRD04', 'pedro.diaz@cacaodelsur.com',
        (SELECT id FROM areas WHERE nombre = 'Investigación Agronómica y Campo'),
        (SELECT id FROM cargos WHERE nombre = 'Ingeniero Agrónomo de Cacao Criollo'),
        'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjMkQ2QTRGIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+UEQ8L3RleHQ+CiAgICA8L3N2Zz4=', 'Laura Vargas Flores', '9614567890'
    ) RETURNING id INTO t_id_4;

    INSERT INTO credenciales (
        trabajador_id, numero_tarjeta, fecha_inicio, fecha_vencimiento, esta_activa
    ) VALUES (
        t_id_4, 'TAR-AGR-1004', '2026-01-01', '2026-12-31', TRUE
    );

    -- Trabajador 5: Laura Patricia Mendoza Flores (CS-PRD-105)
    INSERT INTO trabajadores (
        numero_trabajador, nombre_completo, edad, sexo, curp, correo, 
        area_id, cargo_id, fotografia_url, contacto_emergencia_nombre, contacto_emergencia_telefono
    ) VALUES (
        'CS-PRD-105', 'Laura Patricia Mendoza Flores', 31, 'Femenino', 'MEFL950414MDFNNL05', 'laura.mendoza@cacaodelsur.com',
        (SELECT id FROM areas WHERE nombre = 'Producción y Chocolatería'),
        (SELECT id FROM cargos WHERE nombre = 'Supervisora de Tostado y Molienda Fina'),
        'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjN0E0MzFEIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+TE08L3RleHQ+CiAgICA8L3N2Zz4=', 'Patricia Flores Cruz', '9615678901'
    ) RETURNING id INTO t_id_5;

    INSERT INTO credenciales (
        trabajador_id, numero_tarjeta, fecha_inicio, fecha_vencimiento, esta_activa
    ) VALUES (
        t_id_5, 'TAR-PRD-1005', '2026-02-01', '2027-02-01', TRUE
    );

    -- Trabajador 6: Carlos Eduardo Torres Morales (CS-LOG-106)
    INSERT INTO trabajadores (
        numero_trabajador, nombre_completo, edad, sexo, curp, correo, 
        area_id, cargo_id, fotografia_url, contacto_emergencia_nombre, contacto_emergencia_telefono
    ) VALUES (
        'CS-LOG-106', 'Carlos Eduardo Torres Morales', 45, 'Masculino', 'TOMC810228HDFRRS06', 'carlos.torres@cacaodelsur.com',
        (SELECT id FROM areas WHERE nombre = 'Logística y Cadena de Suministro'),
        (SELECT id FROM cargos WHERE nombre = 'Coordinador de Exportación y Cadena en Frío'),
        'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjNEEyODE4IiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+Q1Q8L3RleHQ+CiAgICA8L3N2Zz4=', 'Gabriela Silva Méndez', '9616789012'
    ) RETURNING id INTO t_id_6;

    INSERT INTO credenciales (
        trabajador_id, numero_tarjeta, fecha_inicio, fecha_vencimiento, esta_activa
    ) VALUES (
        t_id_6, 'TAR-LOG-1006', '2026-01-15', '2027-01-15', TRUE
    );

    -- Trabajador 7: Sofía Isabel Castro Peña (CS-CAL-107)
    INSERT INTO trabajadores (
        numero_trabajador, nombre_completo, edad, sexo, curp, correo, 
        area_id, cargo_id, fotografia_url, contacto_emergencia_nombre, contacto_emergencia_telefono
    ) VALUES (
        'CS-CAL-107', 'Sofía Isabel Castro Peña', 27, 'Femenino', 'CAPS990719MDFTSF07', 'sofia.castro@cacaodelsur.com',
        (SELECT id FROM areas WHERE nombre = 'Control de Calidad y Catación'),
        (SELECT id FROM cargos WHERE nombre = 'Inspectora de Fermentación y Certificación Orgánica'),
        'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjQTA1MjJEIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+U0M8L3RleHQ+CiAgICA8L3N2Zz4=', 'Javier Castro Peña', '9617890123'
    ) RETURNING id INTO t_id_7;

    INSERT INTO credenciales (
        trabajador_id, numero_tarjeta, fecha_inicio, fecha_vencimiento, esta_activa
    ) VALUES (
        t_id_7, 'TAR-CAL-1007', '2026-03-01', '2027-03-01', TRUE
    );

    -- Trabajador 8: Miguel Ángel Ortiz Ramos (CS-INN-108)
    INSERT INTO trabajadores (
        numero_trabajador, nombre_completo, edad, sexo, curp, correo, 
        area_id, cargo_id, fotografia_url, contacto_emergencia_nombre, contacto_emergencia_telefono
    ) VALUES (
        'CS-INN-108', 'Miguel Ángel Ortiz Ramos', 36, 'Masculino', 'OIRM900903HDFRGM08', 'miguel.ortiz@cacaodelsur.com',
        (SELECT id FROM areas WHERE nombre = 'Innovación y Maquinaria Agroindustrial'),
        (SELECT id FROM cargos WHERE nombre = 'Técnico Especialista en Concheado Industrial'),
        'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjNTIyRTFBIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+TU88L3RleHQ+CiAgICA8L3N2Zz4=', 'Susana Ramos Cruz', '9618901234'
    ) RETURNING id INTO t_id_8;

    INSERT INTO credenciales (
        trabajador_id, numero_tarjeta, fecha_inicio, fecha_vencimiento, esta_activa
    ) VALUES (
        t_id_8, 'TAR-INN-1008', '2026-12-01', '2027-12-01', TRUE
    );

    -- Trabajador 9: Diana Laura Navarro Silva (CS-VTA-109)
    INSERT INTO trabajadores (
        numero_trabajador, nombre_completo, edad, sexo, curp, correo, 
        area_id, cargo_id, fotografia_url, contacto_emergencia_nombre, contacto_emergencia_telefono
    ) VALUES (
        'CS-VTA-109', 'Diana Laura Navarro Silva', 33, 'Femenino', 'NASD931211MDFVRN09', 'diana.navarro@cacaodelsur.com',
        (SELECT id FROM areas WHERE nombre = 'Ventas y Exportación Internacional'),
        (SELECT id FROM cargos WHERE nombre = 'Gerente de Cuentas y Comercio Justo'),
        'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjOEI0NTEzIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+RE48L3RleHQ+CiAgICA8L3N2Zz4=', 'Raúl Navarro Silva', '9619012345'
    ) RETURNING id INTO t_id_9;

    INSERT INTO credenciales (
        trabajador_id, numero_tarjeta, fecha_inicio, fecha_vencimiento, esta_activa
    ) VALUES (
        t_id_9, 'TAR-VTA-1009', '2026-01-01', '2026-12-31', TRUE
    );

    -- Trabajador 10: Roberto Carlos Vega Méndez (CS-AGR-110)
    INSERT INTO trabajadores (
        numero_trabajador, nombre_completo, edad, sexo, curp, correo, 
        area_id, cargo_id, fotografia_url, contacto_emergencia_nombre, contacto_emergencia_telefono
    ) VALUES (
        'CS-AGR-110', 'Roberto Carlos Vega Méndez', 50, 'Masculino', 'VEMR760606HDFGDC10', 'roberto.vega@cacaodelsur.com',
        (SELECT id FROM areas WHERE nombre = 'Investigación Agronómica y Campo'),
        (SELECT id FROM cargos WHERE nombre = 'Coordinador de Viveros e Injertos de Cacao'),
        'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjMUI0MzMyIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+UlY8L3RleHQ+CiAgICA8L3N2Zz4=', 'Silvia Méndez Gómez', '9610123456'
    ) RETURNING id INTO t_id_10;

    INSERT INTO credenciales (
        trabajador_id, numero_tarjeta, fecha_inicio, fecha_vencimiento, esta_activa
    ) VALUES (
        t_id_10, 'TAR-AGR-1010', '2026-01-01', '2027-06-30', TRUE
    );

    -- Trabajador 11: Valeria Alejandra Silva Ríos (CS-PRD-111)
    INSERT INTO trabajadores (
        numero_trabajador, nombre_completo, edad, sexo, curp, correo, 
        area_id, cargo_id, fotografia_url, contacto_emergencia_nombre, contacto_emergencia_telefono
    ) VALUES (
        'CS-PRD-111', 'Valeria Alejandra Silva Ríos', 26, 'Femenino', 'SIRV000325MDFLRL11', 'valeria.silva@cacaodelsur.com',
        (SELECT id FROM areas WHERE nombre = 'Producción y Chocolatería'),
        (SELECT id FROM cargos WHERE nombre = 'Artesana de Coberturas y Chocolates de Origen'),
        'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjQjQ1MzA5IiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+VlM8L3RleHQ+CiAgICA8L3N2Zz4=', 'Esteban Silva Ríos', '9611122334'
    ) RETURNING id INTO t_id_11;

    INSERT INTO credenciales (
        trabajador_id, numero_tarjeta, fecha_inicio, fecha_vencimiento, esta_activa
    ) VALUES (
        t_id_11, 'TAR-PRD-1011', '2026-02-15', '2027-02-15', TRUE
    );

    -- Trabajador 12: Fernando Javier Morales Cruz (CS-ADM-112)
    INSERT INTO trabajadores (
        numero_trabajador, nombre_completo, edad, sexo, curp, correo, 
        area_id, cargo_id, fotografia_url, contacto_emergencia_nombre, contacto_emergencia_telefono
    ) VALUES (
        'CS-ADM-112', 'Fernando Javier Morales Cruz', 39, 'Masculino', 'MOCF870110HDFRRR12', 'fernando.morales@cacaodelsur.com',
        (SELECT id FROM areas WHERE nombre = 'Administración y Finanzas'),
        (SELECT id FROM cargos WHERE nombre = 'Jefe de Gestión Humana y Cultura Laboral'),
        'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjM0QyMDEyIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+Rk08L3RleHQ+CiAgICA8L3N2Zz4=', 'Lorena Cruz Morales', '9612233445'
    ) RETURNING id INTO t_id_12;

    INSERT INTO credenciales (
        trabajador_id, numero_tarjeta, fecha_inicio, fecha_vencimiento, esta_activa
    ) VALUES (
        t_id_12, 'TAR-ADM-1012', '2026-01-01', '2027-01-01', TRUE
    );

    -- Trabajador 13: Gabriela Morales Salazar (CS-LOG-113)
    INSERT INTO trabajadores (
        numero_trabajador, nombre_completo, edad, sexo, curp, correo, 
        area_id, cargo_id, fotografia_url, contacto_emergencia_nombre, contacto_emergencia_telefono
    ) VALUES (
        'CS-LOG-113', 'Gabriela Morales Salazar', 30, 'Femenino', 'MOSG960418MDFRLB13', 'gabriela.morales@cacaodelsur.com',
        (SELECT id FROM areas WHERE nombre = 'Logística y Cadena de Suministro'),
        (SELECT id FROM cargos WHERE nombre = 'Supervisora de Almacén de Granos Seleccionados'),
        'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjNkIzQTE5IiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+R008L3RleHQ+CiAgICA8L3N2Zz4=', 'Manuel Salazar Trejo', '9613344556'
    ) RETURNING id INTO t_id_13;

    INSERT INTO credenciales (
        trabajador_id, numero_tarjeta, fecha_inicio, fecha_vencimiento, esta_activa
    ) VALUES (
        t_id_13, 'TAR-LOG-1013', '2026-03-01', '2027-03-01', TRUE
    );
END $$;
