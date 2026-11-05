const seedWorkers = () => [];
import { publicWorker, statusOf } from './domain';
import { fromDatabase, toDatabaseFields, toFormErrors, validateWorker } from './postgresAdapter';

export const IS_DEMO = false;
const BASE = (import.meta.env.VITE_API_URL || '/api').replace(/\/$/, '');
const KEY = 'credencial-workers-postgres-v2';
let csrfToken = null;

async function ensureCsrf() {
  if (csrfToken) return csrfToken;
  const res = await fetch(BASE + '/csrf', { credentials: 'include', headers: { Accept: 'application/json' } });
  if (!res.ok) throw Error('No se pudo preparar una sesión segura. Revisa el endpoint /csrf.');
  const data = await res.json();
  if (!data.csrf_token) throw Error('El servidor no devolvió csrf_token.');
  csrfToken = data.csrf_token;
  return csrfToken;
}

function readDemo() {
  const saved = localStorage.getItem(KEY);
  if (!saved) return seedWorkers();
  try {
    const rows = JSON.parse(saved);
    if (!Array.isArray(rows)) throw Error();
    return rows;
  } catch { throw new Error('Los datos de prueba no se pueden leer. Restablécelos desde Configuración.'); }
}
function persist(rows) {
  try { localStorage.setItem(KEY, JSON.stringify(rows)); }
  catch { throw new Error('No se pudo guardar. El almacenamiento está lleno; utiliza fotografías más pequeñas.'); }
}
async function request(path, options = {}) {
  const headers = { Accept: 'application/json', ...options.headers };
  const token = localStorage.getItem('cacao_session_token');
  if (token && !headers['Authorization']) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  if (options.method && !['GET', 'HEAD'].includes(options.method)) headers['X-CSRF-Token'] = await ensureCsrf();
  if (options.body && !(options.body instanceof FormData)) headers['Content-Type'] = 'application/json';
  const res = await fetch(BASE + path, { credentials: 'include', ...options, headers });
  const data = res.status === 204 ? null : await res.json().catch(() => null);
  if (!res.ok) {
    if (res.status === 401) {
      localStorage.removeItem('cacao_session_token');
      localStorage.removeItem('cacao_user');
    }
    const error = new Error(data?.message || `Error ${res.status}. No se completó la operación.`);
    error.fields = toFormErrors(data?.errors);
    error.status = res.status;
    throw error;
  }
  return data;
}
const withState = (w) => ({ ...w, estado: statusOf(w) });
function duplicate(rows, worker, id) {
  for (const [field, label] of [['numero_trabajador', 'El número de trabajador'], ['numero_tarjeta', 'El número de tarjeta'], ['curp', 'La CURP']]) {
    const value = String(worker[field] || '').trim().toUpperCase();
    if (value && rows.some((r) => String(r.id) !== String(id) && String(r[field] || '').trim().toUpperCase() === value)) {
      const error = new Error(`${label} ya existe.`);
      error.fields = { [field]: [`${label} ya está registrado.`] };
      throw error;
    }
  }
}

export const api = {
  async login(correo, password) {
    if (IS_DEMO) {
      sessionStorage.setItem('credencial-demo-session', '1');
      return { nombre: 'Administrador', correo: correo || 'demo@example.test' };
    }
    const user = await request('/login', { method: 'POST', body: JSON.stringify({ correo, password }) });
    if (user && user.token) {
      localStorage.setItem('cacao_session_token', user.token);
    }
    if (user) {
      localStorage.setItem('cacao_user', JSON.stringify(user));
    }
    csrfToken = null;
    return user;
  },
  async me() {
    if (IS_DEMO) return sessionStorage.getItem('credencial-demo-session') ? { nombre: 'Administrador' } : null;
    try {
      const u = await request('/me');
      if (u) {
        localStorage.setItem('cacao_user', JSON.stringify(u));
      }
      return u;
    } catch (e) {
      localStorage.removeItem('cacao_session_token');
      localStorage.removeItem('cacao_user');
      throw e;
    }
  },
  async logout() {
    localStorage.removeItem('cacao_session_token');
    localStorage.removeItem('cacao_user');
    if (IS_DEMO) { sessionStorage.removeItem('credencial-demo-session'); return; }
    const result = await request('/logout', { method: 'POST' });
    csrfToken = null;
    return result;
  },
  async workers() {
    if (IS_DEMO) return readDemo().map(withState);
    const rows = await request('/trabajadores');
    if (!Array.isArray(rows)) throw Error('GET /trabajadores debe devolver un array de filas de la vista.');
    return rows.map((row) => fromDatabase(row));
  },
  async save(worker, id) {
    const cleaned = { ...worker };
    for (const [key, value] of Object.entries(cleaned)) if (typeof value === 'string' && key !== 'fotografia') cleaned[key] = value.trim();
    cleaned.curp = (cleaned.curp || '').toUpperCase();
    validateWorker(cleaned, IS_DEMO);
    if (IS_DEMO) {
      const rows = readDemo();
      duplicate(rows, cleaned, id);
      const saved = { ...cleaned, id: id ? String(id) : String(Math.max(0, ...rows.map((r) => Number(r.id))) + 1), credencial_id: worker.credencial_id || crypto.randomUUID() };
      persist(id ? rows.map((r) => r.id === String(id) ? saved : r) : [saved, ...rows]);
      return withState(saved);
    }
    const form = new FormData();
    Object.entries(toDatabaseFields(cleaned)).forEach(([key, value]) => form.append(key, typeof value === 'boolean' ? String(value) : value ?? ''));
    // Contrato actual: POST multipart y _method=PUT para editar.
    if (id) form.append('_method', 'PUT');
    if (worker.fotografia?.startsWith('data:')) {
      const blob = await (await fetch(worker.fotografia)).blob();
      if (!['image/jpeg', 'image/png'].includes(blob.type)) throw Error('Carga una fotografía JPEG o PNG antes de guardar en el servidor.');
      form.append('fotografia', blob, 'fotografia.' + (blob.type === 'image/png' ? 'png' : 'jpg'));
    }
    const row = await request(id ? `/trabajadores/${encodeURIComponent(id)}` : '/trabajadores', { method: 'POST', body: form });
    return fromDatabase(row);
  },
  async toggle(credencialId, activa) {
    if (IS_DEMO) {
      const rows = readDemo();
      const worker = rows.find((r) => r.credencial_id === credencialId);
      if (!worker) throw Error('Credencial no encontrada.');
      worker.activa = activa;
      persist(rows);
      return withState(worker);
    }
    const row = await request(`/credenciales/${encodeURIComponent(credencialId)}/estado`, { method: 'PATCH', body: JSON.stringify({ esta_activa: activa }) });
    return fromDatabase(row);
  },
  async verify(credencialId) {
    if (IS_DEMO) return publicWorker(readDemo().map(withState).find((w) => w.credencial_id === credencialId));
    const row = await request(`/verificar/${encodeURIComponent(credencialId)}`);
    return fromDatabase(row, { publicView: true });
  },
  async notifications() {
    if (IS_DEMO) return [];
    return request('/notificaciones');
  },
  reset() {
    if (!IS_DEMO) throw Error('Esta acción solo está disponible en demostración.');
    persist(seedWorkers());
  },
};

let cachedLanBase = '';
try {
  fetch(((import.meta.env.VITE_API_URL || '/api').replace(/\/$/, '')) + '/network-info')
    .then((r) => r.json())
    .then((d) => { if (d?.base_url) cachedLanBase = d.base_url; })
    .catch(() => {});
} catch (_) {}

export function verificationURL(worker) {
  let origin = (import.meta.env.VITE_PUBLIC_ORIGIN || window.location.origin).replace(/\/$/, '');
  if ((origin.includes('localhost') || origin.includes('127.0.0.1')) && cachedLanBase) {
    origin = cachedLanBase;
  }
  return `${origin}/#/verificar/${encodeURIComponent(worker.credencial_id)}`;
}
