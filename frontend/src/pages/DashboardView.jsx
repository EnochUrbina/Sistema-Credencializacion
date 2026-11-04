import { UserPlus, ArrowRight } from 'lucide-react';
import WorkerTable from './WorkerTable';
import { PageHeading } from '../components/UI';

export default function Dashboard({ workers }) {
  const count = (state) => workers.filter((w) => w.estado === state).length;
  const summary = [
    ['Trabajadores', workers.length],
    ['Vigentes', count('Vigente')],
    ['Inactivas', count('Inactiva')],
    ['Vencidas', count('Vencida')],
  ];

  return (
    <>
      <PageHeading title="Inicio" description="Administración de trabajadores y credenciales.">
        <a className="btn btn-primary" href="#/trabajadores/nuevo">
          <UserPlus size={17} /> Registrar trabajador
        </a>
      </PageHeading>

      <section className="stat-grid" aria-label="Resumen de registros">
        {summary.map(([label, value]) => (
          <article className="stat-card" key={label}>
            <span>{label}</span>
            <strong>{value}</strong>
          </article>
        ))}
      </section>

      <section className="panel">
        <div className="panel-heading">
          <h2>Trabajadores registrados</h2>
          <a href="#/trabajadores" className="text-button">Ver todos <ArrowRight size={16} /></a>
        </div>
        <WorkerTable workers={workers.slice(0, 5)} />
        <div className="panel-bottom">
          <span>Mostrando {Math.min(workers.length, 5)} de {workers.length} trabajadores</span>
          <a href="#/reportes">Consultar reportes <ArrowRight size={15} /></a>
        </div>
      </section>

      <section className="panel home-notice">
        <h2>Revisión de vigencias</h2>
        <p>
          Hay {count('Vencida')} credenciales vencidas y {count('No vigente')} con fecha de inicio pendiente.
          Revisa los registros antes de renovar o activar una tarjeta.
        </p>
        <a className="text-button" href="#/credenciales">Ver credenciales <ArrowRight size={15} /></a>
      </section>
    </>
  );
}
