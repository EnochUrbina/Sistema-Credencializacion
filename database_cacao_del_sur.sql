-- ==========================================================
-- BASE DE DATOS OFICIAL: CACAO DEL SUR S.A. DE C.V.
-- Sistema de Credencializacion y Control de Personal
-- Exportacion completa con esquema, catalogos y trabajadores
-- ==========================================================

BEGIN TRANSACTION;
CREATE TABLE areas (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre TEXT UNIQUE NOT NULL
            );
INSERT INTO "areas" VALUES(1,'Control de Calidad y Catación');
INSERT INTO "areas" VALUES(2,'Producción y Chocolatería');
INSERT INTO "areas" VALUES(3,'Administración y Finanzas');
INSERT INTO "areas" VALUES(4,'Investigación Agronómica y Campo');
INSERT INTO "areas" VALUES(5,'Logística y Cadena de Suministro');
INSERT INTO "areas" VALUES(6,'Innovación y Maquinaria Agroindustrial');
INSERT INTO "areas" VALUES(7,'Ventas y Exportación Internacional');
CREATE TABLE cargos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre TEXT UNIQUE NOT NULL
            );
INSERT INTO "cargos" VALUES(1,'Sommelier Principal y Jefa de Catación');
INSERT INTO "cargos" VALUES(2,'Maestro Chocolatero de Bombones Finos');
INSERT INTO "cargos" VALUES(3,'Directora de Finanzas y Costos Agrícolas');
INSERT INTO "cargos" VALUES(4,'Ingeniero Agrónomo de Cacao Criollo');
INSERT INTO "cargos" VALUES(5,'Supervisora de Tostado y Molienda Fina');
INSERT INTO "cargos" VALUES(6,'Coordinador de Exportación y Cadena en Frío');
INSERT INTO "cargos" VALUES(7,'Inspectora de Fermentación y Certificación Orgánica');
INSERT INTO "cargos" VALUES(8,'Técnico Especialista en Concheado Industrial');
INSERT INTO "cargos" VALUES(9,'Gerente de Cuentas y Comercio Justo');
INSERT INTO "cargos" VALUES(10,'Coordinador de Viveros e Injertos de Cacao');
INSERT INTO "cargos" VALUES(11,'Artesana de Coberturas y Chocolates de Origen');
INSERT INTO "cargos" VALUES(12,'Jefe de Gestión Humana y Cultura Laboral');
INSERT INTO "cargos" VALUES(13,'Supervisora de Almacén de Granos Seleccionados');
CREATE TABLE credenciales (
                id TEXT PRIMARY KEY,
                trabajador_id INTEGER UNIQUE NOT NULL REFERENCES trabajadores(id) ON DELETE CASCADE,
                numero_tarjeta TEXT UNIQUE NOT NULL,
                fecha_inicio TEXT NOT NULL,
                fecha_vencimiento TEXT NOT NULL,
                esta_activa INTEGER DEFAULT 1 NOT NULL,
                actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                CHECK (fecha_vencimiento >= fecha_inicio)
            );
INSERT INTO "credenciales" VALUES('2d8a46e8-c752-4fb6-92ee-3e747d657611',1,'TAR-CAL-1001','2026-01-01','2026-12-31',1,'2026-11-04 22:43:44');
INSERT INTO "credenciales" VALUES('ecc10126-e6c7-4775-8b91-445e62084501',2,'TAR-PRD-1002','2026-01-01','2026-12-31',0,'2026-11-04 22:43:44');
INSERT INTO "credenciales" VALUES('d73e4a62-df2c-4c5a-9219-753506a3b213',3,'TAR-ADM-1003','2025-01-01','2026-10-30',1,'2026-11-04 22:43:44');
INSERT INTO "credenciales" VALUES('1d3ec37d-fd62-4409-a03b-bcbbb59395e9',4,'TAR-AGR-1004','2026-01-01','2026-12-31',1,'2026-11-04 22:43:44');
INSERT INTO "credenciales" VALUES('d51b767b-0586-44f5-9b7b-3910137509f2',5,'TAR-PRD-1005','2026-02-01','2027-02-01',1,'2026-11-04 22:43:44');
INSERT INTO "credenciales" VALUES('27fe1169-d26f-4c75-b159-bb290035a603',6,'TAR-LOG-1006','2026-01-15','2027-01-15',1,'2026-11-04 22:43:44');
INSERT INTO "credenciales" VALUES('9de42567-38d3-4c4a-8863-5f098fc62a96',7,'TAR-CAL-1007','2026-03-01','2027-03-01',1,'2026-11-04 22:43:44');
INSERT INTO "credenciales" VALUES('c9dd73fa-2ecd-46c7-b3f8-e10dcb4d9d37',8,'TAR-INN-1008','2026-12-01','2027-12-01',1,'2026-11-04 22:43:44');
INSERT INTO "credenciales" VALUES('05e54a1f-d5a1-40c7-82ab-07d8e5415c45',9,'TAR-VTA-1009','2026-01-01','2026-12-31',1,'2026-11-04 22:43:44');
INSERT INTO "credenciales" VALUES('4443367c-5046-4aac-b12b-6a65ae37649f',10,'TAR-AGR-1010','2026-01-01','2027-06-30',1,'2026-11-04 22:43:44');
INSERT INTO "credenciales" VALUES('7f831c49-73f1-42f9-b1a8-3945ff838fff',11,'TAR-PRD-1011','2026-02-15','2027-02-15',1,'2026-11-04 22:43:44');
INSERT INTO "credenciales" VALUES('0b820e1e-318e-4276-aac3-2a8530886c45',12,'TAR-ADM-1012','2026-01-01','2027-01-01',1,'2026-11-04 22:43:44');
INSERT INTO "credenciales" VALUES('54e3124d-048c-4893-b2e7-b05a23a9ec2d',13,'TAR-LOG-1013','2026-03-01','2027-03-01',1,'2026-11-04 22:43:44');
CREATE TABLE historial_notificaciones (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                trabajador_id INTEGER NOT NULL REFERENCES trabajadores(id) ON DELETE CASCADE,
                numero_tarjeta TEXT NOT NULL,
                tipo_evento TEXT NOT NULL,
                correo_destinatario TEXT NOT NULL,
                estado_notificacion TEXT NOT NULL,
                enviado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
CREATE TABLE trabajadores (
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
INSERT INTO "trabajadores" VALUES(1,'CS-CAL-101','Ana Sofía López Morales',29,'Femenino','LOMA970315MCFRLN01','ana.lopez@cacaodelsur.com',1,1,'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjQzQ4MjNGIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+QUw8L3RleHQ+CiAgICA8L3N2Zz4=','Roberto López Morales','9611234567','2026-11-04 22:43:44');
INSERT INTO "trabajadores" VALUES(2,'CS-PRD-102','Juan Carlos Pérez Gómez',34,'Masculino','PEGJ920512HDFRRN02','juan.perez@cacaodelsur.com',2,2,'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjNUMzMzE3IiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+SlA8L3RleHQ+CiAgICA8L3N2Zz4=','Elena Gómez Ruiz','9612345678','2026-11-04 22:43:44');
INSERT INTO "trabajadores" VALUES(3,'CS-ADM-103','María Elena Ruiz Hernández',42,'Femenino','RUHM840820MDFNZR03','maria.ruiz@cacaodelsur.com',3,3,'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjOUU1RDI0IiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+TVI8L3RleHQ+CiAgICA8L3N2Zz4=','Carlos Ruiz Hernández','9613456789','2026-11-04 22:43:44');
INSERT INTO "trabajadores" VALUES(4,'CS-AGR-104','Pedro Antonio Díaz Vargas',38,'Masculino','DIVP881105HDFRRD04','pedro.diaz@cacaodelsur.com',4,4,'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjMkQ2QTRGIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+UEQ8L3RleHQ+CiAgICA8L3N2Zz4=','Laura Vargas Flores','9614567890','2026-11-04 22:43:44');
INSERT INTO "trabajadores" VALUES(5,'CS-PRD-105','Laura Patricia Mendoza Flores',31,'Femenino','MEFL950414MDFNNL05','laura.mendoza@cacaodelsur.com',2,5,'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjN0E0MzFEIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+TE08L3RleHQ+CiAgICA8L3N2Zz4=','Patricia Flores Cruz','9615678901','2026-11-04 22:43:44');
INSERT INTO "trabajadores" VALUES(6,'CS-LOG-106','Carlos Eduardo Torres Morales',45,'Masculino','TOMC810228HDFRRS06','carlos.torres@cacaodelsur.com',5,6,'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjNEEyODE4IiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+Q1Q8L3RleHQ+CiAgICA8L3N2Zz4=','Gabriela Silva Méndez','9616789012','2026-11-04 22:43:44');
INSERT INTO "trabajadores" VALUES(7,'CS-CAL-107','Sofía Isabel Castro Peña',27,'Femenino','CAPS990719MDFTSF07','sofia.castro@cacaodelsur.com',1,7,'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjQTA1MjJEIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+U0M8L3RleHQ+CiAgICA8L3N2Zz4=','Javier Castro Peña','9617890123','2026-11-04 22:43:44');
INSERT INTO "trabajadores" VALUES(8,'CS-INN-108','Miguel Ángel Ortiz Ramos',36,'Masculino','OIRM900903HDFRGM08','miguel.ortiz@cacaodelsur.com',6,8,'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjNTIyRTFBIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+TU88L3RleHQ+CiAgICA8L3N2Zz4=','Susana Ramos Cruz','9618901234','2026-11-04 22:43:44');
INSERT INTO "trabajadores" VALUES(9,'CS-VTA-109','Diana Laura Navarro Silva',33,'Femenino','NASD931211MDFVRN09','diana.navarro@cacaodelsur.com',7,9,'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjOEI0NTEzIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+RE48L3RleHQ+CiAgICA8L3N2Zz4=','Raúl Navarro Silva','9619012345','2026-11-04 22:43:44');
INSERT INTO "trabajadores" VALUES(10,'CS-AGR-110','Roberto Carlos Vega Méndez',50,'Masculino','VEMR760606HDFGDC10','roberto.vega@cacaodelsur.com',4,10,'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjMUI0MzMyIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+UlY8L3RleHQ+CiAgICA8L3N2Zz4=','Silvia Méndez Gómez','9610123456','2026-11-04 22:43:44');
INSERT INTO "trabajadores" VALUES(11,'CS-PRD-111','Valeria Alejandra Silva Ríos',26,'Femenino','SIRV000325MDFLRL11','valeria.silva@cacaodelsur.com',2,11,'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjQjQ1MzA5IiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+VlM8L3RleHQ+CiAgICA8L3N2Zz4=','Esteban Silva Ríos','9611122334','2026-11-04 22:43:44');
INSERT INTO "trabajadores" VALUES(12,'CS-ADM-112','Fernando Javier Morales Cruz',39,'Masculino','MOCF870110HDFRRR12','fernando.morales@cacaodelsur.com',3,12,'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjM0QyMDEyIiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+Rk08L3RleHQ+CiAgICA8L3N2Zz4=','Lorena Cruz Morales','9612233445','2026-11-04 22:43:44');
INSERT INTO "trabajadores" VALUES(13,'CS-LOG-113','Gabriela Morales Salazar',30,'Femenino','MOSG960418MDFRLB13','gabriela.morales@cacaodelsur.com',5,13,'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNDAiIGhlaWdodD0iMjQwIiB2aWV3Qm94PSIwIDAgMjQwIDI0MCI+CiAgICAgIDxkZWZzPgogICAgICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JhZCIgeDE9IjAlIiB5MT0iMCUiIHgyPSIxMDAlIiB5Mj0iMTAwJSI+CiAgICAgICAgICA8c3RvcCBvZmZzZXQ9IjAlIiBzdG9wLWNvbG9yPSIjNkIzQTE5IiAvPgogICAgICAgICAgPHN0b3Agb2Zmc2V0PSIxMDAlIiBzdG9wLWNvbG9yPSIjMkQxODA3IiAvPgogICAgICAgIDwvbGluZWFyR3JhZGllbnQ+CiAgICAgIDwvZGVmcz4KICAgICAgPHJlY3Qgd2lkdGg9IjI0MCIgaGVpZ2h0PSIyNDAiIHJ4PSIyNCIgZmlsbD0idXJsKCNncmFkKSIgLz4KICAgICAgPGNpcmNsZSBjeD0iMTIwIiBjeT0iODUiIHI9IjQ1IiBmaWxsPSIjRkFGNkYwIiBmaWxsLW9wYWNpdHk9IjAuOTIiIC8+CiAgICAgIDxwYXRoIGQ9Ik00MCAyMTAgQzQwIDE1MCwgODAgMTQwLCAxMjAgMTQwIEMxNjAgMTQwLCAyMDAgMTUwLCAyMDAgMjEwIFoiIGZpbGw9IiNGQUY2RjAiIGZpbGwtb3BhY2l0eT0iMC45MiIgLz4KICAgICAgPHRleHQgeD0iMTIwIiB5PSI5OCIgZm9udC1mYW1pbHk9IidTZWdvZSBVSScsIEFyaWFsLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjI4IiBmb250LXdlaWdodD0iYm9sZCIgZmlsbD0iIzNEMjAxMiIgdGV4dC1hbmNob3I9Im1pZGRsZSI+R008L3RleHQ+CiAgICA8L3N2Zz4=','Manuel Salazar Trejo','9613344556','2026-11-04 22:43:44');
CREATE TABLE usuarios_admin (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                nombre TEXT NOT NULL,
                correo TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
INSERT INTO "usuarios_admin" VALUES(1,'Administrador General','admin@institucion.edu.mx','pbkdf2:sha256:100000$1b4fad9e68edc15ee0ff9fe38a4516c2$d4a7853999083c4229f9af882764ebacd34658f9093f63039b00330314451517','2026-11-04 20:56:00');
INSERT INTO "usuarios_admin" VALUES(23,'Administrador Cacao del Sur','admin@cacaodelsur.com','pbkdf2:sha256:100000$93f3cb09f4c48400ff9a485379f6c67d$cc6e0c6d9c2d853f8956d298cfad830b1c74ce2e902b117ac9f0d458b576cabe','2026-11-04 22:42:40');
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
DELETE FROM "sqlite_sequence";
INSERT INTO "sqlite_sequence" VALUES('usuarios_admin',30);
INSERT INTO "sqlite_sequence" VALUES('areas',7);
INSERT INTO "sqlite_sequence" VALUES('cargos',13);
INSERT INTO "sqlite_sequence" VALUES('trabajadores',13);
COMMIT;
