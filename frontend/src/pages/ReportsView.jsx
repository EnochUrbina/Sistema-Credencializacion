import {jsPDF} from 'jspdf';
import autoTable from 'jspdf-autotable';
import {useState, useEffect, useMemo} from 'react';
import {
  Printer, Download, FileChartColumn, Filter, Search, TrendingUp, Activity,
  CheckCircle2, XCircle, AlertTriangle, Clock, Building2, Users, ArrowUpRight,
  ShieldCheck, Mail, RefreshCw
} from 'lucide-react';
import {PageHeading, Empty} from '../components/UI';
import WorkerTable from './WorkerTable';
import {csvCell, STATES, dateLabel} from '../services/domain';
import {api} from '../services/api';

export default function Reports({workers = []}){
  const [area, setArea] = useState('');
  const [state, setState] = useState('');
  const [search, setSearch] = useState('');
  const [notifications, setNotifications] = useState([]);
  const [loadingEvents, setLoadingEvents] = useState(true);

  // Cargar historial de eventos de auditoría y notificaciones
  const loadNotifications = () => {
    setLoadingEvents(true);
    api.notifications()
      .then(data => setNotifications(Array.isArray(data) ? data : []))
      .catch(() => setNotifications([]))
      .finally(() => setLoadingEvents(false));
  };

  useEffect(() => {
    loadNotifications();
  }, []);

  // Áreas únicas para filtros
  const areas = useMemo(() => [...new Set(workers.map(w => w.area))].filter(Boolean).sort(), [workers]);

  // Filtrado reactivo de trabajadores
  const filteredRows = useMemo(() => {
    const q = search.trim().toLowerCase();
    return workers.filter(w => {
      const matchArea = !area || w.area === area;
      const matchState = !state || w.estado === state;
      const matchQuery = !q || (
        (w.nombre_completo || '').toLowerCase().includes(q) ||
        (w.numero_trabajador || '').toLowerCase().includes(q) ||
        (w.numero_tarjeta || '').toLowerCase().includes(q) ||
        (w.cargo || '').toLowerCase().includes(q)
      );
      return matchArea && matchState && matchQuery;
    });
  }, [workers, area, state, search]);

  // Métricas generales
  const total = workers.length;
  const vigentes = workers.filter(w => w.estado === 'Vigente').length;
  const inactivas = workers.filter(w => w.estado === 'Inactiva').length;
  const vencidas = workers.filter(w => w.estado === 'Vencida').length;
  const noVigentes = workers.filter(w => w.estado === 'No vigente').length;

  const pctVigentes = total ? Math.round((vigentes / total) * 100) : 0;
  const pctInactivas = total ? Math.round((inactivas / total) * 100) : 0;
  const pctVencidas = total ? Math.round((vencidas / total) * 100) : 0;
  const pctNoVigentes = total ? Math.round((noVigentes / total) * 100) : 0;

  // Métricas por Área de adscripción
  const areaStats = useMemo(() => {
    const map = {};
    workers.forEach(w => {
      const a = w.area || 'Sin área asignada';
      if (!map[a]) map[a] = { total: 0, vigentes: 0 };
      map[a].total += 1;
      if (w.estado === 'Vigente') map[a].vigentes += 1;
    });
    return Object.entries(map).map(([name, data]) => ({
      name,
      total: data.total,
      vigentes: data.vigentes,
      pct: total ? Math.round((data.total / total) * 100) : 0
    })).sort((a, b) => b.total - a.total);
  }, [workers, total]);

  // Métricas de flujo de eventos recientes (notificaciones / auditoría)
  const eventStats = useMemo(() => {
    const countNuevas = notifications.filter(n => (n.tipo_evento || '').toLowerCase().includes('nueva')).length;
    const countBajas = notifications.filter(n => (n.tipo_evento || '').toLowerCase().includes('desactiv')).length;
    const countModifs = notifications.filter(n => (n.tipo_evento || '').toLowerCase().includes('vigencia') || (n.tipo_evento || '').toLowerCase().includes('modific')).length;
    return {
      nuevas: countNuevas,
      bajas: countBajas,
      modificaciones: countModifs,
      total: notifications.length
    };
  }, [notifications]);

  // Exportar a PDF
  function pdf(){
    const doc = new jsPDF({orientation: 'landscape'});
    doc.setFontSize(16);
    doc.text('Reporte Institucional de Credencialización', 14, 16);
    doc.setFontSize(10);
    doc.setTextColor(100);
    doc.text(
      `Generado el: ${new Intl.DateTimeFormat('es-MX', {dateStyle: 'long', timeStyle: 'short', timeZone: 'America/Mexico_City'}).format(new Date())} | Filtros: Área [${area || 'Todas'}], Estado [${state || 'Todos'}] | Registros: ${filteredRows.length}`,
      14,
      23
    );

    autoTable(doc, {
      startY: 28,
      head: [['Nombre Completo', 'Núm. Trabajador', 'Núm. Tarjeta', 'Área', 'Cargo', 'Inicio', 'Vencimiento', 'Estado']],
      body: filteredRows.map(w => [
        w.nombre_completo,
        w.numero_trabajador,
        w.numero_tarjeta,
        w.area,
        w.cargo,
        w.fecha_inicio,
        w.fecha_vencimiento,
        w.estado
      ]),
      styles: {fontSize: 8, cellPadding: 3},
      headStyles: {fillColor: [49, 92, 135]}
    });

    doc.save('reporte-credencializacion.pdf');
  }

  // Exportar a CSV
  function download(){
    const columns = ['Nombre Completo', 'Número de Trabajador', 'Número de Tarjeta', 'Área', 'Cargo', 'Fecha Inicio', 'Fecha Vencimiento', 'Estado'];
    const data = [
      columns,
      ...filteredRows.map(w => [
        w.nombre_completo,
        w.numero_trabajador,
        w.numero_tarjeta,
        w.area,
        w.cargo,
        w.fecha_inicio,
        w.fecha_vencimiento,
        w.estado
      ])
    ].map(row => row.map(csvCell).join(',')).join('\r\n');

    const url = URL.createObjectURL(new Blob(['\uFEFF' + data], {type: 'text/csv;charset=utf-8;'}));
    const a = document.createElement('a');
    a.href = url;
    a.download = 'reporte-credenciales.csv';
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <div className="reports-page">
      {/* Encabezado y acciones de descarga */}
      <PageHeading
        title="Reportes y Analítica Institucional"
        description="Métricas de credencialización en tiempo real, desglose de vigencias y flujo reciente de auditoría."
      >
        <button className="btn btn-secondary" onClick={download} disabled={!filteredRows.length}>
          <Download size={16}/> Exportar CSV
        </button>
        <button className="btn btn-secondary" onClick={pdf} disabled={!filteredRows.length}>
          <Download size={16}/> Descargar PDF
        </button>
        <button className="btn btn-primary" onClick={() => window.print()}>
          <Printer size={16}/> Imprimir reporte
        </button>
      </PageHeading>

      {/* Tarjetas de Indicadores Clave (KPIs) */}
      <div className="stat-grid" style={{marginBottom: '24px'}}>
        <div className="stat-card">
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
            <div>
              <span style={{fontSize: '11px', color: '#64748b', fontWeight: '500'}}>Total Expedientes</span>
              <strong style={{fontSize: '24px', display: 'block', color: '#1e293b', marginTop: '4px'}}>{total}</strong>
            </div>
            <span style={{background: '#f1f5f9', color: '#315c87', padding: '10px', borderRadius: '8px'}}>
              <Users size={22}/>
            </span>
          </div>
          <span style={{fontSize: '11px', color: '#64748b', marginTop: '8px', display: 'block'}}>
            Personal activo registrado
          </span>
        </div>

        <div className="stat-card">
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
            <div>
              <span style={{fontSize: '11px', color: '#16a34a', fontWeight: '500'}}>Credenciales Vigentes</span>
              <strong style={{fontSize: '24px', display: 'block', color: '#16a34a', marginTop: '4px'}}>
                {vigentes} <small style={{fontSize: '13px', fontWeight: 'normal', color: '#64748b'}}>({pctVigentes}%)</small>
              </strong>
            </div>
            <span style={{background: '#ecfdf5', color: '#16a34a', padding: '10px', borderRadius: '8px'}}>
              <ShieldCheck size={22}/>
            </span>
          </div>
          <span style={{fontSize: '11px', color: '#16a34a', marginTop: '8px', display: 'block'}}>
            Habilitadas para acceso
          </span>
        </div>

        <div className="stat-card">
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
            <div>
              <span style={{fontSize: '11px', color: '#dc2626', fontWeight: '500'}}>Vencidas / Expiradas</span>
              <strong style={{fontSize: '24px', display: 'block', color: '#dc2626', marginTop: '4px'}}>
                {vencidas} <small style={{fontSize: '13px', fontWeight: 'normal', color: '#64748b'}}>({pctVencidas}%)</small>
              </strong>
            </div>
            <span style={{background: '#fef2f2', color: '#dc2626', padding: '10px', borderRadius: '8px'}}>
              <Clock size={22}/>
            </span>
          </div>
          <span style={{fontSize: '11px', color: '#dc2626', marginTop: '8px', display: 'block'}}>
            Requieren renovación
          </span>
        </div>

        <div className="stat-card">
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
            <div>
              <span style={{fontSize: '11px', color: '#475569', fontWeight: '500'}}>Inactivas / Bajas</span>
              <strong style={{fontSize: '24px', display: 'block', color: '#475569', marginTop: '4px'}}>
                {inactivas} <small style={{fontSize: '13px', fontWeight: 'normal', color: '#64748b'}}>({pctInactivas}%)</small>
              </strong>
            </div>
            <span style={{background: '#f1f5f9', color: '#475569', padding: '10px', borderRadius: '8px'}}>
              <XCircle size={22}/>
            </span>
          </div>
          <span style={{fontSize: '11px', color: '#64748b', marginTop: '8px', display: 'block'}}>
            Suspendidas administrativamente
          </span>
        </div>
      </div>

      {/* Sección Gráfica: Flujo Reciente y Distribución */}
      <div style={{display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '20px', marginBottom: '24px'}}>
        
        {/* Panel 1: Gráfica de Flujo Reciente de Movimientos */}
        <section className="panel" style={{padding: '20px', display: 'flex', flexDirection: 'column'}}>
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px'}}>
            <div style={{display: 'flex', alignItems: 'center', gap: '8px'}}>
              <span style={{background: '#eff6ff', color: '#315c87', padding: '6px', borderRadius: '6px', display: 'inline-flex'}}>
                <Activity size={18}/>
              </span>
              <div>
                <h3 style={{fontSize: '14px', margin: 0, color: '#1e293b'}}>Flujo Reciente de Credenciales</h3>
                <p style={{fontSize: '11px', color: '#64748b', margin: 0}}>Historial de auditoría y notificaciones SMTP</p>
              </div>
            </div>
            <button
              className="icon-button"
              onClick={loadNotifications}
              title="Actualizar flujo"
              style={{padding: '4px'}}
            >
              <RefreshCw size={14} className={loadingEvents ? 'spin' : ''}/>
            </button>
          </div>

          {/* Barras de proporción de eventos */}
          <div style={{display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '10px', marginBottom: '16px'}}>
            <div style={{background: '#f8fafc', padding: '10px', borderRadius: '6px', border: '1px solid #e2e8f0', textAlign: 'center'}}>
              <span style={{fontSize: '10px', color: '#16a34a', fontWeight: '600', display: 'block'}}>Nuevas</span>
              <strong style={{fontSize: '18px', color: '#16a34a'}}>{eventStats.nuevas}</strong>
            </div>
            <div style={{background: '#f8fafc', padding: '10px', borderRadius: '6px', border: '1px solid #e2e8f0', textAlign: 'center'}}>
              <span style={{fontSize: '10px', color: '#dc2626', fontWeight: '600', display: 'block'}}>Bajas</span>
              <strong style={{fontSize: '18px', color: '#dc2626'}}>{eventStats.bajas}</strong>
            </div>
            <div style={{background: '#f8fafc', padding: '10px', borderRadius: '6px', border: '1px solid #e2e8f0', textAlign: 'center'}}>
              <span style={{fontSize: '10px', color: '#2563eb', fontWeight: '600', display: 'block'}}>Vigencias</span>
              <strong style={{fontSize: '18px', color: '#2563eb'}}>{eventStats.modificaciones}</strong>
            </div>
          </div>

          {/* Gráfica de barras horizontales de volumen de eventos */}
          <div style={{marginBottom: '16px'}}>
            <div style={{display: 'flex', justifyContent: 'space-between', fontSize: '11px', color: '#64748b', marginBottom: '4px'}}>
              <span>Balance de eventos en el sistema:</span>
              <span>{eventStats.total} movimientos registrados</span>
            </div>
            <div style={{display: 'flex', height: '10px', borderRadius: '5px', overflow: 'hidden', background: '#e2e8f0'}}>
              <div
                style={{
                  width: `${eventStats.total ? (eventStats.nuevas / eventStats.total) * 100 : 0}%`,
                  background: '#16a34a',
                  transition: 'width 0.4s'
                }}
                title={`Nuevas credenciales: ${eventStats.nuevas}`}
              />
              <div
                style={{
                  width: `${eventStats.total ? (eventStats.bajas / eventStats.total) * 100 : 0}%`,
                  background: '#dc2626',
                  transition: 'width 0.4s'
                }}
                title={`Desactivaciones: ${eventStats.bajas}`}
              />
              <div
                style={{
                  width: `${eventStats.total ? (eventStats.modificaciones / eventStats.total) * 100 : 0}%`,
                  background: '#2563eb',
                  transition: 'width 0.4s'
                }}
                title={`Modificaciones de vigencia: ${eventStats.modificaciones}`}
              />
            </div>
          </div>

          {/* Lista de últimos eventos en vivo */}
          <div style={{flex: 1, overflowY: 'auto', maxHeight: '180px', display: 'flex', flexDirection: 'column', gap: '8px'}}>
            {notifications.length === 0 ? (
              <div style={{textAlign: 'center', padding: '25px', color: '#94a3b8', fontSize: '12px'}}>
                No hay movimientos registrados en el flujo aún.
              </div>
            ) : (
              notifications.slice(0, 5).map((evt, idx) => {
                const isNew = (evt.tipo_evento || '').toLowerCase().includes('nueva');
                const isDown = (evt.tipo_evento || '').toLowerCase().includes('desactiv');
                const badgeBg = isNew ? '#ecfdf5' : isDown ? '#fef2f2' : '#eff6ff';
                const badgeColor = isNew ? '#16a34a' : isDown ? '#dc2626' : '#2563eb';

                return (
                  <div
                    key={evt.id || idx}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      padding: '8px 10px',
                      background: '#f8fafc',
                      borderRadius: '6px',
                      fontSize: '11px',
                      borderLeft: `3px solid ${badgeColor}`
                    }}
                  >
                    <div style={{display: 'flex', flexDirection: 'column'}}>
                      <span style={{fontWeight: '600', color: '#1e293b'}}>
                        {evt.tipo_evento} · <span style={{fontFamily: 'monospace', color: '#475569'}}>{evt.numero_tarjeta}</span>
                      </span>
                      <small style={{color: '#64748b'}}>
                        {evt.correo_destinatario || 'Sin correo registrado'}
                      </small>
                    </div>
                    <div style={{textAlign: 'right'}}>
                      <span style={{
                        fontSize: '10px',
                        fontWeight: '600',
                        color: badgeColor,
                        background: badgeBg,
                        padding: '2px 6px',
                        borderRadius: '4px',
                        display: 'inline-block',
                        marginBottom: '2px'
                      }}>
                        {evt.estado_notificacion || 'Enviado'}
                      </span>
                      <span style={{display: 'block', fontSize: '9px', color: '#94a3b8'}}>
                        {evt.enviado_en ? evt.enviado_en.split(' ')[0] : 'Hoy'}
                      </span>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </section>

        {/* Panel 2: Distribución por Estados y Departamentos */}
        <section className="panel" style={{padding: '20px', display: 'flex', flexDirection: 'column'}}>
          <div style={{display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '14px'}}>
            <span style={{background: '#f0fdf4', color: '#16a34a', padding: '6px', borderRadius: '6px', display: 'inline-flex'}}>
              <FileChartColumn size={18}/>
            </span>
            <div>
              <h3 style={{fontSize: '14px', margin: 0, color: '#1e293b'}}>Distribución de Vigencias</h3>
              <p style={{fontSize: '11px', color: '#64748b', margin: 0}}>Composición porcentual de estados actuales</p>
            </div>
          </div>

          {/* Barra proporcional visual de estados */}
          <div style={{marginBottom: '14px'}}>
            <div style={{display: 'flex', height: '18px', borderRadius: '6px', overflow: 'hidden', background: '#e2e8f0', boxShadow: 'inset 0 1px 2px rgba(0,0,0,0.06)'}}>
              {pctVigentes > 0 && (
                <div style={{width: `${pctVigentes}%`, background: '#16a34a'}} title={`Vigente: ${vigentes} (${pctVigentes}%)`}/>
              )}
              {pctInactivas > 0 && (
                <div style={{width: `${pctInactivas}%`, background: '#64748b'}} title={`Inactiva: ${inactivas} (${pctInactivas}%)`}/>
              )}
              {pctVencidas > 0 && (
                <div style={{width: `${pctVencidas}%`, background: '#dc2626'}} title={`Vencida: ${vencidas} (${pctVencidas}%)`}/>
              )}
              {pctNoVigentes > 0 && (
                <div style={{width: `${pctNoVigentes}%`, background: '#d97706'}} title={`No vigente: ${noVigentes} (${pctNoVigentes}%)`}/>
              )}
            </div>

            {/* Leyenda interactiva de estados */}
            <div style={{display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '8px', marginTop: '12px'}}>
              <button
                type="button"
                onClick={() => setState(state === 'Vigente' ? '' : 'Vigente')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '6px 10px',
                  borderRadius: '6px',
                  border: state === 'Vigente' ? '2px solid #16a34a' : '1px solid #e2e8f0',
                  background: state === 'Vigente' ? '#f0fdf4' : '#fff',
                  cursor: 'pointer',
                  fontSize: '11px'
                }}
              >
                <span style={{display: 'flex', alignItems: 'center', gap: '6px', color: '#16a34a', fontWeight: '500'}}>
                  <span style={{width: '8px', height: '8px', borderRadius: '50%', background: '#16a34a'}}/> Vigente
                </span>
                <strong>{vigentes} ({pctVigentes}%)</strong>
              </button>

              <button
                type="button"
                onClick={() => setState(state === 'Inactiva' ? '' : 'Inactiva')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '6px 10px',
                  borderRadius: '6px',
                  border: state === 'Inactiva' ? '2px solid #64748b' : '1px solid #e2e8f0',
                  background: state === 'Inactiva' ? '#f8fafc' : '#fff',
                  cursor: 'pointer',
                  fontSize: '11px'
                }}
              >
                <span style={{display: 'flex', alignItems: 'center', gap: '6px', color: '#64748b', fontWeight: '500'}}>
                  <span style={{width: '8px', height: '8px', borderRadius: '50%', background: '#64748b'}}/> Inactiva
                </span>
                <strong>{inactivas} ({pctInactivas}%)</strong>
              </button>

              <button
                type="button"
                onClick={() => setState(state === 'Vencida' ? '' : 'Vencida')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '6px 10px',
                  borderRadius: '6px',
                  border: state === 'Vencida' ? '2px solid #dc2626' : '1px solid #e2e8f0',
                  background: state === 'Vencida' ? '#fef2f2' : '#fff',
                  cursor: 'pointer',
                  fontSize: '11px'
                }}
              >
                <span style={{display: 'flex', alignItems: 'center', gap: '6px', color: '#dc2626', fontWeight: '500'}}>
                  <span style={{width: '8px', height: '8px', borderRadius: '50%', background: '#dc2626'}}/> Vencida
                </span>
                <strong>{vencidas} ({pctVencidas}%)</strong>
              </button>

              <button
                type="button"
                onClick={() => setState(state === 'No vigente' ? '' : 'No vigente')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '6px 10px',
                  borderRadius: '6px',
                  border: state === 'No vigente' ? '2px solid #d97706' : '1px solid #e2e8f0',
                  background: state === 'No vigente' ? '#fffbeb' : '#fff',
                  cursor: 'pointer',
                  fontSize: '11px'
                }}
              >
                <span style={{display: 'flex', alignItems: 'center', gap: '6px', color: '#d97706', fontWeight: '500'}}>
                  <span style={{width: '8px', height: '8px', borderRadius: '50%', background: '#d97706'}}/> No vigente
                </span>
                <strong>{noVigentes} ({pctNoVigentes}%)</strong>
              </button>
            </div>
          </div>

          {/* Gráfica de Áreas de Adscripción */}
          <div style={{marginTop: 'auto', paddingTop: '10px', borderTop: '1px solid #f1f5f9'}}>
            <div style={{display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '8px'}}>
              <Building2 size={15} style={{color: '#64748b'}}/>
              <span style={{fontSize: '12px', fontWeight: '600', color: '#334155'}}>Personal por Área:</span>
            </div>
            <div style={{display: 'flex', flexDirection: 'column', gap: '6px'}}>
              {areaStats.slice(0, 4).map(a => (
                <div
                  key={a.name}
                  onClick={() => setArea(area === a.name ? '' : a.name)}
                  style={{cursor: 'pointer'}}
                  title={`Clic para filtrar por ${a.name}`}
                >
                  <div style={{display: 'flex', justifyContent: 'space-between', fontSize: '11px', marginBottom: '2px'}}>
                    <span style={{color: area === a.name ? '#315c87' : '#475569', fontWeight: area === a.name ? 'bold' : 'normal'}}>
                      {a.name}
                    </span>
                    <span style={{color: '#64748b'}}>{a.total} emp. ({a.pct}%)</span>
                  </div>
                  <div style={{height: '6px', borderRadius: '3px', background: '#f1f5f9', overflow: 'hidden'}}>
                    <div style={{height: '100%', width: `${a.pct}%`, background: area === a.name ? '#315c87' : '#94a3b8'}}/>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

      </div>

      {/* Panel Principal: Tabla de Registros y Filtros Dinámicos */}
      <section className="panel" style={{padding: '20px'}}>
        <div className="filter-bar no-print" style={{display: 'flex', flexWrap: 'wrap', gap: '12px', alignItems: 'center', marginBottom: '16px'}}>
          <span className="filter-label" style={{display: 'flex', alignItems: 'center', gap: '6px', fontWeight: '600', fontSize: '13px'}}>
            <Filter size={16}/> Filtrar registros:
          </span>

          {/* Búsqueda en vivo */}
          <div style={{position: 'relative', flex: '1', minWidth: '200px'}}>
            <Search size={14} style={{position: 'absolute', left: '10px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8'}}/>
            <input
              type="text"
              placeholder="Buscar por nombre, trabajador o tarjeta..."
              value={search}
              onChange={e => setSearch(e.target.value)}
              style={{paddingLeft: '32px', width: '100%'}}
            />
          </div>

          {/* Filtro por Área */}
          <select aria-label="Área del reporte" value={area} onChange={e => setArea(e.target.value)}>
            <option value="">Todas las áreas</option>
            {areas.map(a => <option key={a} value={a}>{a}</option>)}
          </select>

          {/* Filtro por Estado */}
          <select aria-label="Estado del reporte" value={state} onChange={e => setState(e.target.value)}>
            <option value="">Todos los estados</option>
            {STATES.map(s => <option key={s} value={s}>{s}</option>)}
          </select>

          {(area || state || search) && (
            <button className="text-button" onClick={() => { setArea(''); setState(''); setSearch(''); }}>
              Limpiar filtros
            </button>
          )}
        </div>

        {/* Resumen de filtros activos */}
        <div className="report-filters" style={{display: 'flex', alignItems: 'center', gap: '10px', fontSize: '12px', color: '#64748b', marginBottom: '14px'}}>
          <span>Área: <strong style={{color: '#1e293b'}}>{area || 'Todas'}</strong></span>
          <span>·</span>
          <span>Estado: <strong style={{color: '#1e293b'}}>{state || 'Todos'}</strong></span>
          {search && (
            <>
              <span>·</span>
              <span>Búsqueda: <strong style={{color: '#315c87'}}>"{search}"</strong></span>
            </>
          )}
          <span style={{marginLeft: 'auto', fontWeight: '600', color: '#315c87'}}>
            {filteredRows.length} {filteredRows.length === 1 ? 'registro encontrado' : 'registros encontrados'}
          </span>
        </div>

        {/* Tabla institucional */}
        <WorkerTable workers={filteredRows}/>

        {/* Resumen al pie */}
        <div className="report-summary" style={{display: 'flex', flexWrap: 'wrap', gap: '16px', marginTop: '16px', paddingTop: '14px', borderTop: '1px solid #e2e8f0', fontSize: '12px'}}>
          {STATES.map(s => (
            <span key={s}>
              {s}: <strong>{filteredRows.filter(w => w.estado === s).length}</strong>
            </span>
          ))}
          <span style={{marginLeft: 'auto'}}>
            Total mostrado: <strong>{filteredRows.length}</strong> de {total}
          </span>
        </div>
      </section>

      <p className="footnote no-print" style={{marginTop: '16px', color: '#94a3b8', fontSize: '11px'}}>
        El reporte refleja el cálculo dinámico de vigencias al momento de la consulta. La exportación en PDF y CSV incluye todos los registros que cumplan con los filtros activos.
      </p>
    </div>
  );
}
