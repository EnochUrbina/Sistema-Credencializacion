# 1. Planeación del Proyecto
## Reto 3: Sistema de Credencialización Web

---

### 1.1 Objetivo General
Desarrollar e implementar un sistema web integral, responsivo y seguro para la administración de personal y la emisión automatizada de credenciales digitales institucionales con código QR único, que permita la verificación pública e instantánea de la vigencia del trabajador desde cualquier dispositivo móvil o de escritorio, protegiendo los datos personales sensibles y registrando eventos de auditoría y notificación.

### 1.2 Objetivos Específicos
1. **Administración de Expedientes:** Proveer un módulo seguro para registrar, consultar, editar y activar/desactivar credenciales de trabajadores con validaciones estrictas (edad $\ge 18$, unicidad de número de trabajador, CURP y tarjeta).
2. **Generación de Credenciales con Anverso y Reverso:** Diseñar credenciales institucionales horizontales que incorporen fotografía, datos laborales, vigencia, lineamientos institucionales y código QR único con formato listo para impresión física en alta calidad.
3. **Consulta Pública Segura por Código QR:** Implementar un lector de cámara web/móvil y un endpoint público de verificación en tiempo real que muestre el estado de validez (Vigente, Inactiva, Vencida, No vigente) omitiendo datos sensibles (CURP y contactos de emergencia).
4. **Notificaciones Automáticas y Auditoría:** Notificar por correo electrónico ante la emisión de una nueva credencial, desactivación o cambio de vigencia, registrando la bitácora en la base de datos (`historial_notificaciones`).
5. **Módulo de Reportes:** Generar reportes generales, por departamento y por estatus de vigencia, con capacidades de exportación a CSV, PDF e impresión directa.

---

### 1.3 Alcance del Proyecto
* **Incluido:**
  - Base de datos relacional (PostgreSQL / Supabase con vistas dinámicas, índices y RLS; fallback automático en SQLite).
  - Backend API RESTful desarrollado en FastAPI (Python 3.13) con autenticación administrativa, protección CSRF y manejo de sesiones.
  - Frontend responsivo tipo Single Page Application (SPA) desarrollado con React 19, Tailwind CSS, Lucide Icons, jsPDF y lector de QR nativo con cámara.
  - Precarga de al menos 10 trabajadores institucionales representativos.
  - Generación de anverso y reverso para corte e impresión.
  - Notificaciones por correo electrónico (SMTP y simulación con bitácora).
* **Excluido:**
  - Pasarelas de cobro por emisión de reposición.
  - Integración con torniquetes biométricos físicos.

---

### 1.4 Actividades y Cronograma Estimado

| Fase | Actividad | Tiempo Estimado | Responsable |
| :--- | :--- | :---: | :--- |
| **Fase 1** | Modelado de base de datos SQL, índices, vistas de cálculo de vigencia y seguridad RLS | 3 horas | Administrador de Base de Datos |
| **Fase 2** | Creación de API REST (FastAPI): autenticación, CRUD de trabajadores, endpoints de vigencia y QR | 5 horas | Desarrollador Backend |
| **Fase 3** | Desarrollo de componentes Frontend (React + Tailwind CSS): gafete anverso/reverso, vista de verificación pública | 5 horas | Desarrollador Frontend |
| **Fase 4** | Integración del escáner de cámara QR, reportes dinámicos y exportación PDF/CSV | 4 horas | Desarrollador Full-Stack |
| **Fase 5** | Sistema de notificaciones automáticas y bitácora de auditoría | 3 horas | Desarrollador Backend |
| **Fase 6** | Pruebas integrales, verificación de seguridad, redacción de bitácora y documentación | 4 horas | Equipo Completo / QA |

---

### 1.5 Recursos Asignados
* **Hardware:** Laptops de desarrollo con cámaras web para pruebas de escaneo QR y dispositivos móviles smartphone (iOS/Android).
* **Software y Herramientas:**
  - Lenguajes: Python 3.13, JavaScript (Node.js v22).
  - Frameworks: FastAPI, React 19, Tailwind CSS, Vite.
  - Base de datos: PostgreSQL (Supabase) / SQLite.
  - Librerías clave: `qrcode.react`, `jsqr`, `jspdf`, `jspdf-autotable`, `uvicorn`, `psycopg2`.
