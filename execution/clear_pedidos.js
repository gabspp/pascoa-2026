const { createClient } = require('@supabase/supabase-js');
require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });

const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

async function clear() {
  const { data: pedidos } = await sb.from('pedidos').select('id');
  const count = pedidos ? pedidos.length : 0;
  console.log('Pedidos encontrados:', count);
  if (count === 0) { console.log('Nada para apagar.'); return; }

  const ids = pedidos.map(function(p) { return p.id; });
  const r1 = await sb.from('pedido_itens').delete().in('pedido_id', ids);
  const r2 = await sb.from('pedidos').delete().in('id', ids);
  if (r2.error) { console.error('Erro:', r2.error.message); return; }
  console.log('Apagados:', count, 'pedidos e seus itens.');
}

clear();
