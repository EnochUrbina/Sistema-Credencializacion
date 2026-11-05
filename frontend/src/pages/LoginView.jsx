import { useState } from 'react';
import { LogIn } from 'lucide-react';
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
        <div className="login-brand-header">
          <img src="/assets/logo_cacao.jpg" alt="Cacao del Sur" className="login-logo-img" />
          <h1>Cacao del Sur</h1>
          <p>Portal de Credencialización y Control de Personal</p>
        </div>
        <p className="muted" style={{ textAlign: 'center', marginBottom: '16px' }}>Acceso de personal autorizado</p>
        {error && <ErrorBox message={error} />}
        <label>Correo electrónico institucional
          <input type="email" autoComplete="username" placeholder="admin@cacaodelsur.com" value={email} onChange={(e) => setEmail(e.target.value)} required={!IS_DEMO} />
        </label>
        <label>Contraseña
          <input type="password" autoComplete="current-password" placeholder="••••••••" value={password} onChange={(e) => setPassword(e.target.value)} required={!IS_DEMO} />
        </label>
        <button className="btn btn-primary w-full" disabled={busy}>
          <LogIn size={17} />{busy ? 'Ingresando…' : 'Iniciar sesión'}
        </button>
        <p className="login-help">© 2026 Cacao del Sur S.A. de C.V. · Acceso Restringido</p>
      </form>
    </div>
  );
}
