import test from 'node:test';
import assert from 'node:assert/strict';
import {credentialToken} from '../src/services/qr.js';
const id='72a6dc78-b9b9-45ab-a831-a1a204d32de4';
test('Lee UUID y enlaces del QR sin navegar a destinos externos',()=>{assert.equal(credentialToken(id),id);assert.equal(credentialToken('https://servidor/#/verificar/'+id),id);assert.equal(credentialToken('https://servidor/api/verificar/'+id),id);});
test('Rechaza QR ajeno, código ejecutable e identificador incorrecto',()=>{for(const raw of ['javascript:alert(1)','https://ejemplo.com','../../etc/passwd','123', 'https://x/#/verificar/'+id+'extra'])assert.throws(()=>credentialToken(raw));});
