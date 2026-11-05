# 4. Evidencias de Seguimiento del Proyecto
## Sistema de Credencialización Web (Reto 3)

Este documento registra formalmente el estado de avance en los cuatro momentos clave del desarrollo:

---

### Momento 1: Inicio del Primer Día
* **Fecha y Hora:** Día 1 - 09:00 hrs.
* **Objetivos Establecidos:** 
  - Análisis detallado de los requerimientos y reglas de negocio del Reto 3.
  - Diseño conceptual y entidad-relación de la base de datos relacional.
  - Selección de la arquitectura técnica (Supabase PostgreSQL + FastAPI + React SPA).
* **Estado de Avance (15%):**
  - Esquema SQL redactado con tablas para trabajadores, credenciales, usuarios administradores e historial de notificaciones.
  - Habilitación de la extensión `uuid-ossp` para tokens únicos no predecibles en los códigos QR.
  - Creación de la vista `vista_credenciales_completa` con la lógica de clasificación de vigencia según `CURRENT_DATE`.

---

### Momento 2: Cierre del Primer Día
* **Fecha y Hora:** Día 1 - 19:30 hrs.
* **Objetivos Alcanzados:**
  - Despliegue del esquema en la nube de Supabase.
  - Maquetación y desarrollo inicial de componentes de frontend en React y Tailwind CSS.
  - Definición del contrato API REST y adaptadores de datos (`api.js`, `postgresAdapter.js`).
* **Estado de Avance (55%):**
  - Implementación de la tarjeta credencial horizontal con anverso institucional y reverso con código QR.
  - Formularios de captura de datos con validaciones iniciales de edad ($\ge 18$) y formato de CURP.
  - Módulo de lectura de QR mediante acceso a la API del navegador `getUserMedia`.

---

### Momento 3: Inicio del Segundo Día
* **Fecha y Hora:** Día 2 - 08:30 hrs.
* **Objetivos Establecidos:**
  - Construcción de los servicios backend en FastAPI con persistencia en PostgreSQL / Supabase y fallback local.
  - Implementación de la autenticación administrativa basada en cookies de sesión y protección CSRF.
  - Implementación del sistema de notificaciones automáticas por correo electrónico ante nueva credencial, desactivación o modificación de vigencia.
* **Estado de Avance (75%):**
  - Integración completa entre el frontend React y la API REST en Python.
  - Endpoint público de verificación `/api/verificar/:id` completado con política estricta de protección de datos personales (sin CURP ni datos de emergencia).

---

### Momento 4: Cierre del Proyecto
* **Fecha y Hora:** Día 2 - 14:00 hrs.
* **Resultados Finales Alcanzados (100%):**
  - Suite de 16 pruebas unitarias y de integración ejecutadas con 100% de éxito.
  - Base de datos precargada con 10 trabajadores representativos de diversas áreas y estados de credencial (`Vigente`, `Inactiva`, `Vencida`, `No vigente`).
  - Módulo de reportes general, por área y por estado de vigencia, con descarga instantánea en CSV, PDF e impresión directa.
  - Compilación de producción generada y empaquetado en lanzador automatizado de un solo clic (`INICIAR_SISTEMA.bat`).
  - Sistema 100% listo para demostración en vivo ante el jurado evaluador.
