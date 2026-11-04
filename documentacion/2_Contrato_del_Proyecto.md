# 2. Contrato del Proyecto
## Sistema de Credencialización Web

---

### 2.1 Compromisos del Equipo
Los integrantes del equipo de desarrollo asumen el compromiso formal de entregar un software funcional, seguro y eficiente que cumpla rigurosamente con los 15 puntos estipulados en los requerimientos funcionales del desafío:
1. **Calidad de Código:** Adherencia a estándares de arquitectura limpia, separación de responsabilidades (Frontend SPA desacoplado de la API REST) y manejo defensivo de errores.
2. **Seguridad y Privacidad:** Garantía irrestricta de que datos personales sensibles (CURP completa y teléfonos/nombres de emergencia) permanezcan bajo acceso exclusivo de administradores autenticados y nunca sean expuestos en la vista pública del código QR.
3. **Disponibilidad:** El sistema debe operar tanto en entornos locales sin conexión externa (mediante fallback local) como en la nube conectado a Supabase.

---

### 2.2 Entregables Comprometidos
1. **Base de Datos:** Script SQL completo y verificado (`usuarios_admin`, `trabajadores`, `credenciales`, `historial_notificaciones`, índices y vista dinámica `vista_credenciales_completa`).
2. **Módulo de Administración de Personal:** Alta con fotografía individual, edición, baja lógica (desactivación conservando el historial) y consulta detallada.
3. **Credencial Institucional Imprimible:** Diseño con dimensiones estándar de tarjeta de identificación horizontal, anverso (foto, nombre, cargo, adscripción) y reverso (QR dinámico, folio de tarjeta, vigencia, leyenda institucional).
4. **Módulo de Consulta y Escaneo QR:** Página pública de verificación adaptada a dispositivos móviles con retroalimentación cromática del estado (`Vigente`, `Inactiva`, `Vencida`, `No vigente`).
5. **Sistema de Auditoría y Notificaciones:** Registro de eventos de modificación de vigencia, alta y desactivación.
6. **Módulo de Reportes:** Filtros interactivos por área y estado, con descarga en formato CSV y PDF e impresión directa.
7. **Documentación Oficial:** Planeación, contrato, gestión en herramientas CASE, evidencias en cuatro momentos y bitácora técnica de desarrollo.

---

### 2.3 Roles y Responsabilidades

| Rol | Responsable Asignado | Responsabilidades Clave |
| :--- | :--- | :--- |
| **Líder de Proyecto & Backend** | Integrante 1 | Arquitectura FastAPI, seguridad, endpoints REST, sistema de notificaciones y sesiones. |
| **Desarrollador Frontend & UI/UX** | Integrante 2 | Diseño de credenciales (anverso/reverso), escáner de cámara QR, componentes Tailwind CSS. |
| **Administrador de Datos & QA** | Integrante 3 | Base de datos Supabase, vistas SQL, pruebas unitarias automatizadas y redacción de bitácora. |

---

### 2.4 Condiciones de Aceptación
* El sistema deberá ser presentado en ejecución real sin fallas críticas.
* Se validará la existencia de un mínimo de 10 trabajadores registrados con distintos estados de vigencia.
* Se comprobará el escaneo de credenciales desde un dispositivo con cámara verificando la actualización inmediata tras la desactivación por parte del administrador.
