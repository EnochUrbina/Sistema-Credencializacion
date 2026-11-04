// Traduce las filas de vista_credenciales_completa al modelo de las pantallas.
// El identificador del trabajador (SERIAL) y el de su credencial (UUID) son distintos.
import { publicWorker, STATES } from './domain.js';

const FIELD_NAMES = {
  area: 'area_adscripcion',
  fotografia: 'fotografia_url',
  emergencia_nombre: 'contacto_emergencia_nombre',
  emergencia_telefono: 'contacto_emergencia_telefono',
  activa: 'esta_activa',
};
const INPUT_FIELDS = [
  'numero_trabajador', 'nombre_completo', 'edad', 'sexo', 'curp', 'correo',
  'area', 'cargo', 'emergencia_nombre', 'emergencia_telefono',
  'numero_tarjeta', 'fecha_inicio', 'fecha_vencimiento', 'activa',
];

export function parseActive(value) {
  if ([true, 'true', 1, '1'].includes(value)) return true;
  if ([false, 'false', 0, '0'].includes(value)) return false;
  throw new Error('La API debe devolver esta_activa como booleano.');
}

export function fromDatabase(row, { publicView = false } = {}) {
  if (!row || row.trabajador_id == null || !row.credencial_id) {
    throw new Error('La API debe devolver trabajador_id y credencial_id por separado.');
  }
  if (!STATES.includes(row.estado_calculado)) {
    throw new Error('La API debe devolver un estado_calculado válido desde la vista de PostgreSQL.');
  }
  const worker = {
    id: String(row.trabajador_id),
    credencial_id: String(row.credencial_id),
    numero_trabajador: row.numero_trabajador,
    nombre_completo: row.nombre_completo,
    edad: row.edad,
    sexo: row.sexo,
    curp: row.curp,
    correo: row.correo,
    area: row.area_adscripcion,
    cargo: row.cargo,
    fotografia: row.fotografia_url,
    emergencia_nombre: row.contacto_emergencia_nombre,
    emergencia_telefono: row.contacto_emergencia_telefono,
    numero_tarjeta: row.numero_tarjeta,
    fecha_inicio: row.fecha_inicio,
    fecha_vencimiento: row.fecha_vencimiento,
    activa: parseActive(row.esta_activa),
    estado: row.estado_calculado,
  };
  return publicView ? publicWorker(worker) : worker;
}

export function toDatabaseFields(worker) {
  return Object.fromEntries(INPUT_FIELDS.map((key) => [FIELD_NAMES[key] || key, worker[key]]));
}

export function toFormErrors(errors = {}) {
  const reverse = Object.fromEntries(Object.entries(FIELD_NAMES).map(([ui, db]) => [db, ui]));
  reverse.fotografia = 'fotografia';
  return Object.fromEntries(Object.entries(errors).map(([key, value]) => [reverse[key] || key, value]));
}

export function validateWorker(worker, demo = false) {
  const errors = {};
  const limits = { numero_trabajador: 20, nombre_completo: 150, sexo: 20, curp: 18,
    correo: 120, area: 100, cargo: 100, emergencia_nombre: 150,
    emergencia_telefono: 20, numero_tarjeta: 50 };
  for (const [field, max] of Object.entries(limits)) {
    const value = String(worker[field] ?? '').trim();
    if (!value && !(demo && field === 'curp')) errors[field] = ['Este campo es obligatorio.'];
    else if (value.length > max) errors[field] = [`Máximo ${max} caracteres.`];
  }
  const age = Number(worker.edad);
  if (worker.edad === '' || worker.edad == null || !Number.isInteger(age) || age < 18) {
    errors.edad = ['La edad debe ser un número entero de 18 años o más.'];
  }
  if (!demo && !/^[A-Z]{4}\d{6}[HM][A-Z]{5}[A-Z0-9]\d$/.test(worker.curp || '')) {
    errors.curp = ['Revisa la estructura de la CURP de 18 caracteres.'];
  }
  if (!worker.fecha_inicio || !worker.fecha_vencimiento || worker.fecha_inicio > worker.fecha_vencimiento) {
    errors.fecha_vencimiento = ['La vigencia debe tener fechas válidas y vencimiento igual o posterior al inicio.'];
  }
  if (Object.keys(errors).length) {
    const error = new Error('Revisa los campos marcados en el formulario.');
    error.fields = errors;
    throw error;
  }
}
