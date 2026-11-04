# Frontend de credencialización

React + Vite + Tailwind CSS. Este paquete contiene únicamente frontend.

## Abrir en Visual Studio Code

1. Instala Node.js 22.12 o superior.
2. Abre esta carpeta en VS Code.
3. En la terminal ejecuta:

```bash
npm install
npm run dev
```

## Conexión con la API de tu equipo

Copia `.env.example` como `.env` y configura `VITE_API_URL` con la URL HTTPS de tu backend, incluyendo `/api`. Si se publica junto al backend en el mismo dominio, conserva `/api`.

El frontend no incluye backend ni base de datos. Sin una API disponible no funcionan el inicio de sesión, el registro ni la consulta de trabajadores. No carga trabajadores de ejemplo.

El QR usa el dominio desde donde se abre el frontend. El escáner solicita la cámara al entrar; requiere permiso del navegador y HTTPS para su uso desde la nube.

## Carpetas

- src/pages: pantallas.
- src/components: componentes compartidos y credencial.
- src/services: entrada, estilos y conexión API.

`npm run build` genera la carpeta dist para hosting estático.
