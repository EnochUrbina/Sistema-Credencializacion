export function today() { return new Intl.DateTimeFormat('en-CA', { timeZone: 'America/Mexico_City', year:'numeric', month:'2-digit', day:'2-digit' }).format(new Date()); }
export function statusOf(worker, date = today()) {
 if (!worker.activa) return 'Inactiva';
 if (date < worker.fecha_inicio) return 'No vigente';
 if (date > worker.fecha_vencimiento) return 'Vencida';
 return 'Vigente';
}
export function dateLabel(value) { if (!value) return '—'; const [y,m,d] = value.split('-'); return `${d}/${m}/${y}`; }
export function initials(name='') { return name.trim().split(/\s+/).slice(0,2).map(s=>s[0]).join('').toUpperCase(); }
export function publicWorker(w) { if (!w) return null; const keys=['id','nombre_completo','numero_trabajador','numero_tarjeta','area','cargo','fotografia','fecha_inicio','fecha_vencimiento','activa','credencial_id','estado']; return Object.fromEntries(keys.map(k=>[k,w[k]])); }
export function csvCell(value) { const text=String(value??''); return '"'+(/^[=+@\-\t\r]/.test(text)?"'"+text:text).replaceAll('"','""')+'"'; }
export const STATES=['Vigente','Inactiva','Vencida','No vigente'];
