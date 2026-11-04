# 🪪 Sistema de Credencialización Web (Reto 3 - Hackatón 2026)

Sistema web integral, seguro y responsivo para la administración de personal institucional y la emisión automática de credenciales digitales con código QR único, validación de vigencias en tiempo real y notificaciones automáticas.

---

## 🚀 Inicio Rápido (En 1 Clic)

Simplemente ejecuta el archivo por lotes en Windows:

```cmd
INICIAR_SISTEMA.bat
```

O desde la terminal:

```cmd
python main.py
```

El sistema iniciará el servidor backend **FastAPI**, servirá la aplicación **React** compilada y abrirá automáticamente tu navegador en:
👉 **[http://localhost:8000](http://localhost:8000)**

---

## 🔑 Credenciales de Acceso Administrativo

* **Correo:** `admin@institucion.edu.mx`
* **Contraseña:** `admin123`

---

## 📊 Características y Requerimientos Cumplidos

1. **Administración Completa de Trabajadores:**
   - Alta, consulta, modificación y baja lógica (desactivación).
   - Validaciones estrictas: edad $\ge 18$, CURP mexicana de 18 caracteres, números únicos de trabajador y tarjeta.
   - 10 trabajadores institucionales precargados con fotografías y diferentes estados (`Vigente`, `Inactiva`, `Vencida`, `No vigente`).
2. **Credenciales Digitales con Anverso y Reverso:**
   - Diseño institucional horizontal listo para imprimir.
   - **Anverso:** Logotipo/nombre institucional, fotografía del trabajador, nombre completo, número de trabajador, área y cargo.
   - **Reverso:** Código QR único, número de tarjeta, vigencia e instrucciones institucionales.
   - Botón directo de impresión optimizado para corte y enmicado.
3. **Escáner y Consulta Pública por Código QR:**
   - Lector QR integrado usando la cámara de tu laptop o celular (`/escanear`).
   - También permite cargar una imagen del QR o ingresar el enlace manualmente.
   - **Página pública de verificación (`/verificar/:id`):** Muestra si la credencial es válida o inválida en tiempo real.
   - **Protección de Datos:** Por seguridad, la CURP y datos de contacto de emergencia jamás se exponen en la vista pública.
4. **Administración Dinámica de Vigencias:**
   - Estado calculado automáticamente según fechas y acciones del administrador (`Vigente`, `Inactiva`, `Vencida`, `No vigente`).
   - Al desactivar una credencial, el QR refleja inmediatamente el estado **Inactiva** sin eliminar el expediente.
5. **Notificaciones Automáticas por Correo:**
   - Se despacha notificación cuando:
     - Se genera una nueva credencial.
     - El administrador desactiva una credencial.
     - Se modifica la fecha de vencimiento.
   - Registro de auditoría persistente en la tabla `historial_notificaciones`.
6. **Módulo de Reportes:**
   - Reporte general, reporte filtrado por área de adscripción y reporte por estado de vigencia.
   - Exportación directa a **CSV**, descarga de **PDF** formateado e impresión física.

---

## 🗄️ Conexión con Supabase (Opcional)

Por defecto, el sistema viene listo y operativo con su base de datos local `credenciales.db`.
Si deseas sincronizarlo con tu proyecto en la nube de **Supabase**:

1. Abre el archivo `.env` en la raíz del proyecto.
2. Agrega tu cadena de conexión en `DATABASE_URL`:
   ```ini
   DATABASE_URL=postgresql://postgres:[TU_PASSWORD]@db.[TU_PROYECTO].supabase.co:5432/postgres
   ```
3. Guarda el archivo y reinicia el servidor. El sistema detectará automáticamente PostgreSQL y utilizará la base de datos de Supabase.

---

## 📁 Documentación de Gestión del Proyecto

En la carpeta [`documentacion/`](./documentacion/) encontrarás los 5 documentos solicitados para la entrega del Reto:

* [`1_Planeacion_del_Proyecto.md`](./documentacion/1_Planeacion_del_Proyecto.md): Objetivos, alcance, actividades, responsables, recursos y tiempos.
* [`2_Contrato_del_Proyecto.md`](./documentacion/2_Contrato_del_Proyecto.md): Compromisos del equipo, entregables y condiciones.
* [`3_Herramientas_y_Gestion.md`](./documentacion/3_Herramientas_y_Gestion.md): Organización del tablero Kanban en Notion/Jira.
* [`4_Evidencias_de_Seguimiento.md`](./documentacion/4_Evidencias_de_Seguimiento.md): Estado de avance en los 4 momentos del proyecto.
* [`5_Bitacora_del_Proyecto.md`](./documentacion/5_Bitacora_del_Proyecto.md): Actividades, dificultades encontradas, soluciones y resultados.

---

## 💻 Desarrollo del Frontend (Modo Vite con Hot-Reload)

Si deseas modificar el código fuente de React en modo de desarrollo en vivo:

```cmd
DEV_FRONTEND.bat
```
*(Utiliza la versión de Node.js v22 portátil incluida en la carpeta `tools/`).*
