# 3. Herramientas CASE y Gestión de Proyectos
## Sistema de Credencialización Web

---

### 3.1 Herramienta de Gestión Seleccionada
Para la planificación, desglose de requerimientos (épicas, historias de usuario y tareas) y seguimiento en tiempo real del proyecto, se estructuró un tablero **Kanban en Notion / Jira Software** con flujo de trabajo ágil:

```
[ Backlog ] ➔ [ Por Hacer (To Do) ] ➔ [ En Proceso (In Progress) ] ➔ [ En Pruebas / QA ] ➔ [ Completado (Done) ]
```

---

### 3.2 Estructura del Tablero de Actividades

#### Épica 1: Arquitectura y Base de Datos (Supabase)
* `DB-01`: Creación de tablas (`usuarios_admin`, `trabajadores`, `credenciales`, `historial_notificaciones`). [Completado]
* `DB-02`: Creación de índices B-Tree para optimización de consultas por área y folio de tarjeta. [Completado]
* `DB-03`: Implementación de vista calculada `vista_credenciales_completa` con `security_invoker = true`. [Completado]

#### Épica 2: Servicios Backend (FastAPI REST)
* `BE-01`: Configuración de autenticación administrativa, tokens de sesión y protección CSRF. [Completado]
* `BE-02`: Endpoints de CRUD de trabajadores con soporte multipart/form-data para fotografías. [Completado]
* `BE-03`: Endpoint de cambio de estado de credencial (`PATCH /api/credenciales/:id/estado`). [Completado]
* `BE-04`: Endpoint público de verificación para escaneo QR (`GET /api/verificar/:id`). [Completado]
* `BE-05`: Servicio de envío de correo automático y registro en historial de auditoría. [Completado]

#### Épica 3: Interfaz de Usuario y Experiencia (React + Tailwind CSS)
* `FE-01`: Panel de control interactivo con estadísticas de trabajadores vigentes, vencidos e inactivos. [Completado]
* `FE-02`: Formulario de captura y edición de trabajadores con validaciones de CURP y fechas. [Completado]
* `FE-03`: Diseño de credencial institucional horizontal (anverso y reverso con corte para impresión). [Completado]
* `FE-04`: Escáner de códigos QR mediante cámara web y carga de archivo de imagen. [Completado]
* `FE-05`: Pantalla pública de verificación responsive para móviles con badges de estado. [Completado]
* `FE-06`: Módulo de reportes con filtros dinámicos y exportación a PDF, CSV e impresión. [Completado]

---

### 3.3 Matriz de Trazabilidad y Asignaciones

| Código | Tarea / Requerimiento | Prioridad | Estimación | Estado Final |
| :--- | :--- | :---: | :---: | :---: |
| **REQ-A** | Registro y administración de al menos 10 trabajadores | Alta | 4 h | **Hecho** |
| **REQ-B** | Credencial digital horizontal con anverso y reverso | Alta | 5 h | **Hecho** |
| **REQ-C** | Generación y lectura de QR sin exponer CURP/Emergencia | Crítica | 4 h | **Hecho** |
| **REQ-D** | Cálculo dinámico de vigencia (Vigente/Inactiva/Vencida/No vigente) | Crítica | 3 h | **Hecho** |
| **REQ-E** | Validación de no duplicidad de números de tarjeta | Alta | 2 h | **Hecho** |
| **REQ-F** | Interfaz responsiva multiplataforma (móvil y PC) | Alta | 4 h | **Hecho** |
| **REQ-G** | Notificaciones automáticas por correo y auditoría | Media | 3 h | **Hecho** |
| **REQ-H** | Reporte general, por área y estado con exportación PDF/CSV | Alta | 3 h | **Hecho** |
