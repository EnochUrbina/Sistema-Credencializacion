import { test } from 'node:test';
import assert from 'node:assert/strict';
import { fromDatabase, toDatabaseFields, toFormErrors, parseActive, validateWorker } from '../src/services/postgresAdapter.js';
const row = {
  trabajador_id: 15, credencial_id: '329cf26e-e2cd-4446-b76c-954124bd2bce',
  numero_trabajador: 'TR015', nombre_completo: 'Persona de prueba', edad: 25,
  sexo: 'Femenino', curp: 'PRUEBA', correo: 'prueba@example.test',
  area_adscripcion: 'Sistemas', cargo: 'Analista', fotografia_url: 'https://example.test/foto.jpg',
  contacto_emergencia_nombre: 'Contacto', contacto_emergencia_telefono: '0000000000',
  numero_tarjeta: 'TAR1015', fecha_inicio: '2026-01-01', fecha_vencimiento: '2027-12-31',
  esta_activa: true, estado_calculado: 'Vigente',
};
test('distingue ID numérico de trabajador y UUID de credencial', () => {
  const w = fromDatabase(row);
  assert.equal(w.id, '15'); assert.equal(w.credencial_id, row.credencial_id);
  assert.equal(w.area, 'Sistemas'); assert.equal(w.fotografia, row.fotografia_url);
  assert.equal(w.emergencia_telefono, row.contacto_emergencia_telefono);
});
test('la autoridad del estado en modo API es la vista del servidor', () => {
  assert.equal(fromDatabase({ ...row, estado_calculado: 'Vencida' }).estado, 'Vencida');
  assert.throws(() => fromDatabase({ ...row, estado_calculado: undefined }), /estado_calculado/);
});
test('false no se interpreta como true al recibir booleanos serializados', () => {
  for (const value of [false, 'false', 0, '0']) assert.equal(parseActive(value), false);
  for (const value of [true, 'true', 1, '1']) assert.equal(parseActive(value), true);
  assert.throws(() => parseActive(undefined));
});
test('la respuesta pública excluye datos privados aunque la entrada los tenga', () => {
  const w = fromDatabase(row, { publicView: true });
  for (const k of ['edad', 'sexo', 'curp', 'correo', 'emergencia_nombre', 'emergencia_telefono', 'contacto_emergencia_telefono']) assert.equal(k in w, false);
  assert.equal(w.credencial_id, row.credencial_id);
});
test('envía nombres de PostgreSQL y excluye claves calculadas o de identidad', () => {
  const fields = toDatabaseFields(fromDatabase(row));
  assert.equal(fields.area_adscripcion, row.area_adscripcion);
  assert.equal(fields.contacto_emergencia_nombre, 'Contacto');
  assert.equal(fields.esta_activa, true);
  for (const k of ['id', 'credencial_id', 'estado', 'estado_calculado', 'fotografia_url', 'password_hash']) assert.equal(k in fields, false);
});
test('traduce los errores de la API a los campos del formulario', () => {
  const errors = toFormErrors({ area_adscripcion: ['Requerida'], contacto_emergencia_telefono: ['Inválido'], curp: ['Duplicada'] });
  assert.deepEqual(errors.area, ['Requerida']); assert.deepEqual(errors.emergencia_telefono, ['Inválido']); assert.deepEqual(errors.curp, ['Duplicada']);
});
test('rechaza menores y respeta límites 20 y 50 de la base', () => {
  const w = fromDatabase(row);
  assert.throws(() => validateWorker({ ...w, edad: 17 }, true), (e) => !!e.fields.edad);
  assert.throws(() => validateWorker({ ...w, numero_trabajador: 'T'.repeat(21) }, true), (e) => !!e.fields.numero_trabajador);
  assert.throws(() => validateWorker({ ...w, numero_tarjeta: 'T'.repeat(51) }, true), (e) => !!e.fields.numero_tarjeta);
  assert.doesNotThrow(() => validateWorker({ ...w, edad: 18, numero_trabajador: 'T'.repeat(20), numero_tarjeta: 'T'.repeat(50) }, true));
});
test('exige ambas identidades y rechaza fechas invertidas', () => {
  assert.throws(() => fromDatabase({ ...row, trabajador_id: null }), /por separado/);
  assert.throws(() => fromDatabase({ ...row, credencial_id: undefined }), /por separado/);
  assert.throws(() => validateWorker({ ...fromDatabase(row), fecha_inicio: '2030-01-01' }, true), (e) => !!e.fields.fecha_vencimiento);
});
