import { useState, useEffect } from 'react';
import { ShieldCheck, ShieldX, RotateCw, LockKeyhole } from 'lucide-react';
import { api } from '../services/api';
import { Avatar, Badge, Loading, ErrorBox } from '../components/UI';
import { dateLabel } from '../services/domain';
import { INSTITUTION } from '../components/CredentialCard';

export default function Verify({ token }) {
  const [w, setW] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [at, setAt] = useState('');

  async function load() {
    setLoading(true);
    setError('');
    try {
      setW(await api.verify(token));
      setAt(
        new Intl.DateTimeFormat('es-MX', {
          dateStyle: 'medium',
          timeStyle: 'short',
          timeZone: 'America/Mexico_City',
        }).format(new Date())
      );
    } catch (e) {
      if (e.status === 404) setW(null);
      else setError(e.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, [token]);

  const valid = w?.estado === 'Vigente';
  const Icon = valid ? ShieldCheck : ShieldX;

  return (
    <div className="verification-page">
      <header className="verify-header">
        <a className="brand" href="#/">
          <img src="/assets/logo_cacao.jpg" alt="Cacao del Sur" className="brand-logo" />
          <span>Cacao del Sur</span>
        </a>
        <span>VERIFICACIÓN INSTITUCIONAL DE IDENTIDAD</span>
      </header>

      <main className="verification-main">
        {loading ? (
          <Loading />
        ) : error ? (
          <ErrorBox message={error} retry={load} />
        ) : !w ? (
          <section className="panel not-found">
            <ShieldX size={48} />
            <h1>Credencial no encontrada</h1>
            <p>No existe un registro oficial asociado con este código. Revisa el enlace o consulta a Cacao del Sur.</p>
            <button className="btn btn-secondary" onClick={load}>
              <RotateCw size={16} /> Volver a consultar
            </button>
          </section>
        ) : (
          <>
            <div className={`verification-status ${valid ? 'is-valid' : 'is-invalid'}`}>
              <Icon size={24} />
              <div>
                <strong>{valid ? 'Credencial oficial vigente' : 'Credencial sin validez actual'}</strong>
                <span>
                  {valid
                    ? 'Identificación activa y verificada en el padrón institucional.'
                    : w.estado === 'Inactiva'
                    ? 'La institución ha desactivado temporalmente esta credencial.'
                    : w.estado === 'Vencida'
                    ? 'El periodo de vigencia asignado ha concluido.'
                    : 'El periodo de vigencia no ha iniciado.'}
                </span>
              </div>
            </div>

            <section className="panel verification-card">
              <p className="eyebrow">{INSTITUTION}</p>
              <Avatar worker={w} large />
              <h1>{w.nombre_completo}</h1>
              <p className="muted">{w.cargo}</p>
              <Badge state={w.estado} />
              <dl className="verify-fields">
                {[
                  ['Número de trabajador', w.numero_trabajador],
                  ['Área de adscripción', w.area],
                  ['Número de tarjeta', w.numero_tarjeta],
                  ['Inicio de vigencia', dateLabel(w.fecha_inicio)],
                  ['Fecha de vencimiento', dateLabel(w.fecha_vencimiento)],
                ].map(([k, v]) => (
                  <div key={k}>
                    <dt>{k}</dt>
                    <dd>{v}</dd>
                  </div>
                ))}
              </dl>
              <button className="btn btn-secondary w-full" onClick={load}>
                <RotateCw size={16} /> Actualizar consulta
              </button>
              <p className="footnote">Última validación: {at}</p>
            </section>

            <p className="verification-hint">
              <LockKeyhole size={16} /> Validación en tiempo real conectada a la base de datos oficial.
            </p>
            <p className="footnote text-center">Compara la fotografía con la persona que presenta la credencial.</p>
          </>
        )}
      </main>

      <footer className="verify-footer">© 2026 Cacao del Sur S.A. de C.V. · Validación Oficial de Credenciales</footer>
    </div>
  );
}
