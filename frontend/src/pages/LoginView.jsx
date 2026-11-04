import { useState } from 'react';
import { ContactRound, LogIn } from 'lucide-react';
import { api, IS_DEMO } from '../services/api';
import { ErrorBox } from '../components/UI';

export default function Login({ onLogin }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  async function submit(e) {
    e.preventDefault();
    setBusy(true);
    setError('');
    try { onLogin(await api.login(email, password)); }
    catch (e) { setError(e.message); }
    finally { setBusy(false); }
  }

  return (
    <div className="login-page">
      <form onSubmit={submit} className="login-form">
        <div className="login-title"><ContactRound size={32} /><h1>Sistema de credencialización</h1></div>
        <p className="muted">Acceso de administrador</p>
        {error && <ErrorBox message={error} />}
        <label>Correo electrónico
          <input type="email" autoComplete="username" placeholder="Correo electrónico" value={email} onChange={(e) => setEmail(e.target.value)} required={!IS_DEMO} />
        </label>
        <label>Contraseña
          <input type="password" autoComplete="current-password" placeholder="Contraseña" value={password} onChange={(e) => setPassword(e.target.value)} required={!IS_DEMO} />
        </label>
        <button className="btn btn-primary w-full" disabled={busy}>
          <LogIn size={17} />{busy ? 'Ingresando…' : IS_DEMO ? 'Entrar a la demostración' : 'Iniciar sesión'}
        </button>
        {IS_DEMO && <div className="demo-note"><strong>Versión de prueba</strong><p>Puedes entrar sin correo ni contraseña. Los datos son ficticios y los cambios se guardan solo en este navegador; este acceso no autentica usuarios reales.</p></div>}
        <p className="login-help">Proyecto académico · Hackatón 2026</p>
      </form>
    </div>
  );
}
