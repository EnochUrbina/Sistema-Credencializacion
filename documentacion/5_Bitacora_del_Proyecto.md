# 5. Bitácora Técnica del Proyecto
## Sistema de Credencialización Web (Reto 3)

---

### 5.1 Registro de Actividades Realizadas
1. **Modelado y Normalización de Datos:** Separación de los expedientes personales (`trabajadores`) de la información transaccional de credenciales (`credenciales`), permitiendo renovaciones y desactivaciones sin alterar la historia del empleado.
2. **Implementación de la Vista de Negocio:** Creación de `vista_credenciales_completa` que computa dinámicamente si una credencial es `Vigente`, `Inactiva`, `Vencida` o `No vigente` de forma centralizada en el motor SQL.
3. **Desarrollo del Backend FastAPI:**
   - Servicios de autenticación con hash de contraseñas mediante PBKDF2 y cookies HTTP-only.
   - Endpoints REST para CRUD de trabajadores con soporte multipart/form-data para carga de fotografías.
   - Endpoint público de verificación para el escáner QR.
   - Sistema de notificaciones automáticas con registro de auditoría en `historial_notificaciones`.
4. **Desarrollo del Frontend React + Tailwind:**
   - Vista de credencial institucional horizontal con doble cara (anverso y reverso).
   - Componente de escaneo en vivo con la cámara del dispositivo móvil/laptop.
   - Módulo de reportes interactivos con generación de archivos PDF (vía `jspdf` y `jspdf-autotable`) y hojas de cálculo CSV.
5. **Configuración de Resiliencia (Dual Engine):** Soporte simultáneo para PostgreSQL en la nube (Supabase) y SQLite local para garantizar funcionamiento inmediato ante cualquier fallo de conexión a Internet durante la presentación.

---

### 5.2 Dificultades Encontradas y Soluciones Implementadas

| Dificultad Encontrada | Causa Raíz | Solución Implementada |
| :--- | :--- | :--- |
| **1. Entorno local sin Node.js instalado** | La laptop del desarrollador no contaba con Node.js en las variables de entorno, impidiendo ejecutar el frontend React inicialmente. | Se integró una versión portátil de Node.js v22 en el entorno local, se instalaron las dependencias y se compiló el frontend en un paquete estático optimizado (`dist/`) que es servido directamente por FastAPI. |
| **2. Advertencia crítica de seguridad RLS en la vista SQL** | PostgreSQL / Supabase emitía advertencias sobre vistas que omitían el contexto del invocador en políticas de RLS. | Se incorporó la cláusula `WITH (security_invoker = true)` en la declaración de la vista, mitigando riesgos de elevación de privilegios. |
| **3. Privacidad de datos en la consulta pública del QR** | El requerimiento prohíbe taxativamente mostrar la CURP y datos de contacto de emergencia a personas externas que escaneen el QR. | Se creó una proyección estricta en el endpoint `/api/verificar/:id` y en el adaptador `postgresAdapter.js` que excluye de raíz los campos sensibles antes de renderizar la tarjeta en pantalla. |
| **4. Diferencias horarias en el cálculo de vigencia** | La diferencia horaria entre el servidor y el cliente podía provocar que una credencial venciera unas horas antes o después del día marcado. | Se normalizó el cálculo temporal utilizando la zona horaria oficial `America/Mexico_City` tanto en las consultas de base de datos como en los formateadores de fecha en frontend. |
| **5. Carga de fotografías en conexiones lentas** | Fotografías pesadas de celulares demoraban la sincronización o agotaban límites de almacenamiento. | Se implementó preprocesamiento con `FileReader` / `Blob` y un seeder con avatares vectoriales SVG integrados en base64 para garantizar independencia sin saturar la red. |

---

### 5.3 Cambios Efectuados Respecto al Plan Original
* **Lanzador Automatizado:** Se añadió el script ejecutable `INICIAR_SISTEMA.bat` para que cualquier miembro del equipo o evaluador pueda levantar el sistema completo (backend, base de datos y frontend) con un solo clic.
* **Seeder Automático:** Se precargaron 10 trabajadores institucionales con datos realistas (nombres, CURPs, cargos, áreas de Sistemas, Recursos Humanos, Administración, Biblioteca, Mantenimiento, Dirección) y variedad de estados para agilizar la evaluación de los jueces.

---

### 5.4 Resultados Obtenidos
* **100% de Pruebas Unitarias Aprobadas:** 16 pruebas automatizadas pasadas exitosamente.
* **Cumplimiento Completo del Reto:** Los 15 requerimientos funcionales y de entrega se encuentran cubiertos en su totalidad.
* **Rendimiento:** Tiempos de respuesta de la API inferiores a 30 ms en consultas locales y renderizado instantáneo en móviles.
