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
SMTP_FROM = os.getenv("SMTP_FROM", "") or (f"Cacao del Sur <{SMTP_USER}>" if SMTP_USER else "Cacao del Sur <notificaciones@cacaodelsur.com>")

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
    asunto = f"Cacao del Sur - Notificación de Credencial [{tipo_evento}] - {numero_tarjeta}"
    vigencia_texto = f"{fecha_inicio} al {fecha_vencimiento}"
    
    badge_bg = "#E8F5E9" if estado_actualizado == "Vigente" else "#FFEBEE" if estado_actualizado == "Vencida" else "#EFEBE9"
    badge_color = "#1B5E20" if estado_actualizado == "Vigente" else "#B71C1C" if estado_actualizado == "Vencida" else "#4E342E"

    html_content = f"""
    <!DOCTYPE html>
    <html lang="es">
    <head>
      <meta charset="utf-8">
      <style>
        body {{ font-family: 'Segoe UI', Arial, sans-serif; background-color: #FAF6F0; margin: 0; padding: 24px; color: #2C1E18; }}
        .card {{ max-width: 580px; margin: 0 auto; background: #FFFFFF; border-radius: 12px; border: 1px solid #E8DCCF; overflow: hidden; box-shadow: 0 8px 24px rgba(46, 24, 14, 0.08); }}
        .header {{ background: linear-gradient(135deg, #2E180E 0%, #3D2012 100%); color: #FAF6F0; padding: 28px 24px; text-align: center; border-bottom: 3px solid #C4823F; }}
        .header h1 {{ margin: 0; font-size: 22px; letter-spacing: 0.5px; font-weight: 700; color: #FAF6F0; }}
        .header p {{ margin: 6px 0 0; font-size: 13px; color: #D49B55; font-weight: 500; }}
        .content {{ padding: 28px 24px; }}
        .badge {{ display: inline-block; padding: 8px 18px; border-radius: 20px; font-weight: 600; font-size: 13px; margin-bottom: 18px; background: {badge_bg}; color: {badge_color}; border: 1px solid {badge_color}33; }}
        table {{ width: 100%; border-collapse: collapse; margin-top: 18px; }}
        td {{ padding: 11px 14px; border-bottom: 1px solid #F5EFEB; font-size: 13px; }}
        td.label {{ font-weight: 600; color: #7E6B5D; width: 42%; }}
        td.val {{ color: #2C1E18; font-weight: 500; }}
        .notice {{ margin-top: 22px; padding: 14px 16px; background: #FFFDF9; border-left: 4px solid #C4823F; border-radius: 4px; font-size: 12px; color: #7E6B5D; line-height: 1.6; }}
        .footer {{ background: #F5EBE1; padding: 18px 24px; text-align: center; font-size: 11px; color: #7E6B5D; border-top: 1px solid #E8DCCF; }}
      </style>
    </head>
    <body>
      <div class="card">
        <div class="header">
          <h1>CACAO DEL SUR S.A. DE C.V.</h1>
          <p>Control Institucional de Credencialización y Personal</p>
        </div>
        <div class="content">
          <p>Estimado(a) <strong>{trabajador_nombre}</strong>,</p>
          <p>Le informamos que se ha registrado una actualización oficial respecto a su expediente y credencial:</p>
          
          <div style="text-align: center;">
            <span class="badge">
              Estado de Credencial: <strong>{estado_actualizado}</strong>
            </span>
          </div>

          <table>
            <tr><td class="label">Colaborador:</td><td class="val">{trabajador_nombre}</td></tr>
            <tr><td class="label">Matrícula Institucional:</td><td class="val"><code>{numero_trabajador}</code></td></tr>
            <tr><td class="label">Folio de Tarjeta:</td><td class="val"><code>{numero_tarjeta}</code></td></tr>
            <tr><td class="label">Tipo de Movimiento:</td><td class="val"><strong>{tipo_evento}</strong></td></tr>
            <tr><td class="label">Periodo de Vigencia:</td><td class="val">{vigencia_texto}</td></tr>
            <tr><td class="label">Estatus Actual:</td><td class="val"><strong>{estado_actualizado}</strong></td></tr>
          </table>

          <div class="notice">
            Esta es una notificación automática del sistema institucional. Puede verificar la vigencia y autenticidad física de su credencial escaneando el código QR impreso en el reverso de su tarjeta.
          </div>
        </div>
        <div class="footer">
          © 2026 Cacao del Sur S.A. de C.V. · Finca & Planta Procesadora · Todos los derechos reservados.
        </div>
      </div>
    </body>
    </html>
    """

    # 1. Envío mediante SMTP (Gmail, Outlook, Hostinger, Mailgun, etc.)
    if SMTP_HOST and SMTP_USER and SMTP_PASSWORD:
        try:
            msg = MIMEMultipart("alternative")
            msg["Subject"] = asunto
            msg["From"] = SMTP_FROM
            msg["To"] = destinatario
            msg.attach(MIMEText(html_content, "html", "utf-8"))

            if SMTP_PORT == 465:
                # SSL directo
                with smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT, timeout=12) as server:
                    server.login(SMTP_USER, SMTP_PASSWORD)
                    server.sendmail(SMTP_FROM, [destinatario], msg.as_string())
            else:
                # STARTTLS (puerto 587 o 25)
                with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=12) as server:
                    server.starttls()
                    server.login(SMTP_USER, SMTP_PASSWORD)
                    server.sendmail(SMTP_FROM, [destinatario], msg.as_string())

            print(f"[MAILER SMTP] Correo enviado exitosamente via {SMTP_HOST} a {destinatario}!")
            return "Enviado"
        except Exception as e:
            print(f"[MAILER SMTP ERROR] {e}")
            return f"Error SMTP: {str(e)[:30]}"

    # 2. Resend API como alternativa HTTP
    resend_key = os.getenv("RESEND_API_KEY", "").strip()
    if resend_key:
        try:
            import urllib.request
            import urllib.error
            import json
            payload = {
                "from": "Cacao del Sur <onboarding@resend.dev>",
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
                    "User-Agent": "CacaoDelSur-Credenciales/1.0"
                }
            )
            try:
                with urllib.request.urlopen(req, timeout=10) as resp:
                    print(f"[MAILER RESEND] Correo enviado exitosamente a {destinatario}!")
                    return "Enviado"
            except urllib.error.HTTPError as err:
                err_body = err.read().decode("utf-8")
                # Si está en modo prueba de Resend (solo permite enviar al correo de la cuenta)
                if "only send testing emails to your own email address" in err_body:
                    fallback_owner = os.getenv("ADMIN_EMAIL", "admin@cacaodelsur.com")
                    payload["to"] = [fallback_owner]
                    payload["subject"] = f"[Prueba para: {destinatario}] {asunto}"
                    req2 = urllib.request.Request(
                        "https://api.resend.com/emails",
                        data=json.dumps(payload).encode("utf-8"),
                        headers={
                            "Authorization": f"Bearer {resend_key}",
                            "Content-Type": "application/json",
                            "User-Agent": "CacaoDelSur-Credenciales/1.0"
                        }
                    )
                    with urllib.request.urlopen(req2, timeout=10) as resp2:
                        print(f"[MAILER RESEND] Correo de prueba entregado a {fallback_owner}!")
                        return "Enviado (Modo Prueba Resend)"
                raise
        except Exception as e:
            print(f"[MAILER RESEND ERROR] {e}")
            return f"Error Resend: {str(e)[:30]}"

    # 3. Modo Simulado / Sin SMTP configurado
    print(f"[MAILER SIMULADO] Correo preparado para {destinatario} | Evento: {tipo_evento} | Tarjeta: {numero_tarjeta} | Estado: {estado_actualizado}")
    return "Simulado (Sin SMTP)"
