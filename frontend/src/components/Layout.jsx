import { useState } from 'react';
import { ScanLine, ContactRound, LayoutDashboard, UsersRound, ChartNoAxesCombined, Settings2, LogOut, Menu, X } from 'lucide-react';
import { IS_DEMO } from '../services/api';
import { initials } from '../services/domain';
import { Modal } from './UI';

const links = [
  ['/', 'Inicio', LayoutDashboard],
  ['/trabajadores', 'Trabajadores', UsersRound],
  ['/credenciales', 'Credenciales', ContactRound],
  ['/escanear', 'Escanear código', ScanLine],
  ['/reportes', 'Reportes', ChartNoAxesCombined],
  ['/configuracion', 'Configuración', Settings2],
];

export default function Layout({ path, user, onLogout, children }) {
  const [open, setOpen] = useState(false);
  const [showLogoutModal, setShowLogoutModal] = useState(false);
  const active = (url) => url === '/' ? path === '/' : path.startsWith(url);
  const current = links.find(([url]) => active(url));

  return (
    <div className="app-shell">
      <aside className={`sidebar ${open ? 'is-open' : ''}`}>
        <a href="#/" className="brand" onClick={() => setOpen(false)}>
          <img src="/assets/logo_cacao.jpg" alt="Cacao del Sur" className="brand-logo" />
          <span>Cacao del Sur<small>Control Institucional</small></span>
        </a>
        <button className="mobile-close icon-button" onClick={() => setOpen(false)} aria-label="Cerrar menú"><X /></button>
        <p className="nav-label">MENÚ PRINCIPAL</p>
        <nav aria-label="Navegación principal">
          {links.map(([url, label, Icon]) => (
            <a key={url} href={'#' + url} onClick={() => setOpen(false)}
              className={active(url) ? 'active' : ''} aria-current={active(url) ? 'page' : undefined}>
              <Icon size={19} />{label}
            </a>
          ))}
        </nav>
        <div className="sidebar-bottom">
          <div className="sidebar-project">Cacao del Sur S.A. de C.V.<br /><span>Control de Credenciales</span></div>
          <button className="account" onClick={() => setShowLogoutModal(true)} title="Cerrar sesión">
            <span className="account-avatar">{initials(user?.nombre || 'Administrador')}</span>
            <span><strong>{user?.nombre || 'Administrador'}</strong><small>Cerrar sesión</small></span>
            <LogOut size={17} />
          </button>
        </div>
      </aside>
      {open && <div className="sidebar-shade" onClick={() => setOpen(false)} />}
      <div className="main-shell">
        <header className="topbar">
          <div className="breadcrumb">
            <button className="icon-button mobile-menu" onClick={() => setOpen(true)} aria-label="Abrir menú"><Menu /></button>
            <span>Administración</span><span className="breadcrumb-slash">/</span>
            <strong>{current?.[1] || 'Trabajadores'}</strong>
          </div>
          <div className="topbar-right">
            <span className="environment">Sistema conectado</span>
            <span className="topbar-date">{new Intl.DateTimeFormat('es-MX', { day: 'numeric', month: 'long', year: 'numeric' }).format(new Date())}</span>
          </div>
        </header>
        <main>{children}</main>
        <footer className="app-footer"><span>Cacao del Sur S.A. de C.V. · Sistema Institucional</span><span>Versión Corporativa</span></footer>
      </div>

      {showLogoutModal && (
        <Modal title="Confirmar cierre de sesión" onClose={() => setShowLogoutModal(false)}>
          <div style={{display: 'flex', flexDirection: 'column', gap: '14px'}}>
            <p style={{margin: 0, fontSize: '13px', color: '#475569', lineHeight: '1.5'}}>
              ¿Estás seguro de que deseas salir del sistema de credencialización institucional de Cacao del Sur?
            </p>
            <div style={{background: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '8px', padding: '10px 12px', fontSize: '12px', color: '#64748b'}}>
              Sesión activa de: <strong style={{color: '#1e293b'}}>{user?.nombre || 'Administrador'}</strong> ({user?.correo || 'admin@cacaodelsur.com'})
            </div>
            <div style={{display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '6px'}}>
              <button type="button" className="btn btn-secondary" onClick={() => setShowLogoutModal(false)}>
                Cancelar
              </button>
              <button
                type="button"
                className="btn btn-danger"
                onClick={() => {
                  setShowLogoutModal(false);
                  onLogout();
                }}
                style={{background: '#dc2626', color: '#fff', border: 'none', display: 'flex', alignItems: 'center', gap: '6px'}}
              >
                <LogOut size={16} /> Cerrar sesión
              </button>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
}
