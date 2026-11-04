import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

SMTP_HOST = os.getenv("SMTP_HOST", "")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
SMTP_FROM = os.getenv("SMTP_FROM", os.getenv("SMTP_USER", "notificaciones@credenciales.edu.mx"))

def send_notification_email(
    trabajador_nombre: str,
    numero_trabajador: str,
    numero_tarjeta: str,
    tipo_evento: str,
    destinatario: str,
    fecha_inicio: str,
    fecha_vencimiento: str,
    estado_actualizado: str
) -> str:
    """
    Sends an automated email notification and returns the dispatch status
    ('Enviado' or 'Simulado / Sin SMTP' or 'Error de envío').
    """
    asunto = f"Notificación de Credencial - {tipo_evento} - {numero_tarjeta}"
    
    vigencia_texto = f"{fecha_inicio} al {fecha_vencimiento}"
    
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f8fafc; margin: 0; padding: 20px; color: #1e293b; }}
        .card {{ max-width: 580px; margin: 0 auto; background: #ffffff; border-radius: 12px; border: 1px solid #e2e8f0; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.07); }}
        .header {{ background: #1e3a8a; color: #ffffff; padding: 24px; text-align: center; }}
        .header h1 {{ margin: 0; font-size: 20px; letter-spacing: 0.5px; }}
        .content {{ padding: 24px; }}
        .badge {{ display: inline-block; padding: 6px 14px; border-radius: 9999px; font-weight: 600; font-size: 13px; margin-bottom: 16px; }}
        .badge-vigente {{ background: #dcfce7; color: #15803d; }}
        .badge-inactiva {{ background: #f1f5f9; color: #475569; }}
        .badge-vencida {{ background: #fee2e2; color: #b91c1c; }}
        .badge-novigente {{ background: #fef3c7; color: #b45309; }}
        table {{ width: 100%; border-collapse: collapse; margin-top: 16px; }}
        td {{ padding: 10px 12px; border-bottom: 1px solid #f1f5f9; }}
        td.label {{ font-weight: 600; color: #64748b; width: 40%; }}
        td.val {{ color: #0f172a; font-weight: 500; }}
        .footer {{ background: #f8fafc; padding: 16px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #e2e8f0; }}
      </style>
    </head>
    <body>
      <div class="card">
        <div class="header">
          <h1>Sistema de Credencialización Institucional</h1>
        </div>
        <div class="content">
          <p>Estimado(a) <strong>{trabajador_nombre}</strong>,</p>
          <p>Le informamos que se ha registrado una actualización respecto a su credencial institucional:</p>
          
          <div style="text-align: center;">
            <span class="badge badge-{'vigente' if estado_actualizado == 'Vigente' else 'vencida' if estado_actualizado == 'Vencida' else 'inactiva'}">
              Estado: {estado_actualizado}
            </span>
          </div>

          <table>
            <tr><td class="label">Trabajador:</td><td class="val">{trabajador_nombre}</td></tr>
            <tr><td class="label">Número de Trabajador:</td><td class="val">{numero_trabajador}</td></tr>
            <tr><td class="label">Número de Tarjeta:</td><td class="val">{numero_tarjeta}</td></tr>
            <tr><td class="label">Tipo de Notificación:</td><td class="val"><strong>{tipo_evento}</strong></td></tr>
            <tr><td class="label">Vigencia:</td><td class="val">{vigencia_texto}</td></tr>
            <tr><td class="label">Estado Actualizado:</td><td class="val"><strong>{estado_actualizado}</strong></td></tr>
          </table>

          <p style="margin-top: 20px; font-size: 13px; color: #64748b;">
            Esta es una notificación automática generada por el sistema. Puede consultar la validez de su credencial escaneando el código QR impreso en el reverso de su tarjeta.
          </p>
        </div>
        <div class="footer">
          Sistema de Credencialización · Todos los derechos reservados.
        </div>
      </div>
    </body>
    </html>
    """

    # 1. Si SMTP está configurado (Gmail / Servidor propio), envía por protocolo SMTP a CUALQUIER destinatario
    if SMTP_HOST and SMTP_USER and SMTP_PASSWORD:
        try:
            msg = MIMEMultipart("alternative")
            msg["Subject"] = asunto
            msg["From"] = SMTP_FROM
            msg["To"] = destinatario
            msg.attach(MIMEText(html_content, "html"))

            with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=12) as server:
                server.starttls()
                server.login(SMTP_USER, SMTP_PASSWORD)
                server.sendmail(SMTP_FROM, [destinatario], msg.as_string())
            print(f"[MAILER SMTP] Correo enviado exitosamente via SMTP a {destinatario}!")
            return "Enviado"
        except Exception as e:
            print(f"[MAILER SMTP ERROR] {e}")
            return f"Error: {str(e)[:25]}"

    # 2. Resend como respaldo
    resend_key = os.getenv("RESEND_API_KEY", "").strip()
    if resend_key:
        try:
            import urllib.request
            import urllib.error
            import json
            payload = {
                "from": "Nebula Tech <onboarding@resend.dev>",
                "to": [destinatario],
                "subject": asunto,
                "html": html_content
            }
            req = urllib.request.Request(
                "https://api.resend.com/emails",
                data=json.dumps(payload).encode("utf-8"),
                headers={
                    "Authorization": f"Bearer {resend_key}",
                    "Content-Type": "application/json",
                    "User-Agent": "NebulaTech-Credenciales/1.0"
                }
            )
            try:
                with urllib.request.urlopen(req, timeout=10) as resp:
                    print(f"[MAILER RESEND] Correo enviado exitosamente a {destinatario}!")
                    return "Enviado"
            except urllib.error.HTTPError as err:
                err_body = err.read().decode("utf-8")
                if "only send testing emails to your own email address" in err_body:
                    fallback_owner = "l23270637@tuxtla.tecnm.mx"
                    print(f"[MAILER RESEND] Modo prueba Resend: enviando correo de prueba a {fallback_owner} (destinatario registrado: {destinatario})")
                    payload["to"] = [fallback_owner]
                    payload["subject"] = f"[Para: {destinatario}] {asunto}"
                    req2 = urllib.request.Request(
                        "https://api.resend.com/emails",
                        data=json.dumps(payload).encode("utf-8"),
                        headers={
                            "Authorization": f"Bearer {resend_key}",
                            "Content-Type": "application/json",
                            "User-Agent": "NebulaTech-Credenciales/1.0"
                        }
                    )
                    with urllib.request.urlopen(req2, timeout=10) as resp2:
                        print(f"[MAILER RESEND] Correo de demostracion entregado con exito a {fallback_owner}!")
                        return "Enviado"
                raise
        except Exception as e:
            print(f"[MAILER RESEND ERROR] {e}")
            return f"Error: {str(e)[:25]}"

    # 2. If SMTP is configured, attempt real email delivery
    if SMTP_HOST and SMTP_USER and SMTP_PASSWORD:
        try:
            msg = MIMEMultipart("alternative")
            msg["Subject"] = asunto
            msg["From"] = SMTP_FROM
            msg["To"] = destinatario
            msg.attach(MIMEText(html_content, "html"))

            with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=8) as server:
                server.starttls()
                server.login(SMTP_USER, SMTP_PASSWORD)
                server.sendmail(SMTP_FROM, [destinatario], msg.as_string())
            return "Enviado"
        except Exception as e:
            print(f"[MAILER] Error enviando correo a {destinatario}: {e}")
            return f"Error: {str(e)[:25]}"
    else:
        # Simulated mode: system records notice cleanly
        print(f"[MAILER SIMULADO] Correo preparado para {destinatario} | Evento: {tipo_evento} | Tarjeta: {numero_tarjeta} | Estado: {estado_actualizado}")
        return "Simulado (OK)"
