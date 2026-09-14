import test from 'node:test';
import assert from 'node:assert/strict';
import { guardarPerfilEnTransaccion } from '../src/modules/productos/productos.acordes.service.js';

test('invalid accords do not write product profile', async () => {
  let wrote = false;
  const tx = {
    acorde: { count: async () => 0 },
    productoAcorde: { deleteMany: async () => { wrote = true; } },
  };
  await assert.rejects(guardarPerfilEnTransaccion(tx, 1, [{ acordeId: 8, intensidad: 60 }]));
  assert.equal(wrote, false);
});

test('profile uses the supplied transaction and sorts intensity', async () => {
  let saved;
  const tx = {
    acorde: { count: async () => 2 },
    productoAcorde: {
      deleteMany: async ({where}) => assert.equal(where.productoId, 3),
      createMany: async ({data}) => { saved = data; },
    },
  };
  await guardarPerfilEnTransaccion(tx, 3, [{acordeId: 1, intensidad: 50}, {acordeId: 2, intensidad: 90}]);
  assert.deepEqual(saved.map(a => a.acordeId), [2, 1]);
  assert.ok(saved.every(a => a.productoId === 3 && !a.copiadoDeReferencia));
});
