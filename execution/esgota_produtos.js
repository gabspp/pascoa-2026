/**
 * esgota_produtos.js — Marca todos os produtos como inativo (esgotado).
 * Uso: node execution/esgota_produtos.js
 */
const { createClient } = require('@supabase/supabase-js');
const { config }       = require('dotenv');
const path             = require('path');

config({ path: path.resolve(__dirname, '../.env') });

const sb = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function main() {
  console.log('\n⏳ Esgotando todos os produtos...');
  const { data, error } = await sb
    .from('produtos')
    .update({ ativo: false })
    .neq('id', '00000000-0000-0000-0000-000000000000')
    .select('nome');

  if (error) { console.error('❌ Erro:', error.message); process.exit(1); }

  data.forEach(p => console.log(`  🚫 ${p.nome}`));
  console.log(`\n✅ ${data.length} produto(s) marcado(s) como esgotado.\n`);
}

main();
