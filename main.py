import os
import sys
import webbrowser
import threading
import time
import socket
import uvicorn
from backend.main import app

def get_lan_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

def open_browser(url):
    time.sleep(1.5)
    print(f"\n[INFO] Abriendo navegador en {url} ...")
    webbrowser.open(url)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    is_cloud = "PORT" in os.environ
    lan_ip = get_lan_ip()
    local_url = f"http://localhost:{port}"
    network_url = f"http://{lan_ip}:{port}"

    print("=" * 72)
    print("   CACAO DEL SUR - SISTEMA DE CREDENCIALIZACIÓN Y CONTROL DE PERSONAL")
    print("=" * 72)
    if is_cloud:
        print(f" * Modo Producción en la Nube activo en el puerto: {port}")
    else:
        print(f" * Acceso en esta PC:              {local_url}")
        print(f" * Acceso desde celulares/red:     {network_url}")
        print("   (Los códigos QR generados en las credenciales usan esta dirección)")
    print("-" * 72)
    print(" * Credenciales de Administrador:")
    print("   - Correo: admin@cacaodelsur.com  (o admin@institucion.edu.mx)")
    print("   - Contraseña: admin123")
    print("=" * 72)

    if not is_cloud:
        threading.Thread(target=open_browser, args=(local_url,), daemon=True).start()

    uvicorn.run("backend.main:app", host="0.0.0.0", port=port, reload=False)
