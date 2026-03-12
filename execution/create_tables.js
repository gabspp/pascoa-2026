/**
 * create_tables.js — Verifica se as tabelas Supabase existem.
 * Uso: node execution/create_tables.js
 */
const { createClient } = require('@supabase/supabase-js');
const { config }       = require('dotenv');
const { readFileSync } = require('fs');
const path             = require('path');

config({ path: path.resolve(__dirname, '../.env') });

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

const TABLES = [
  'categorias','produtos','descontos_progressivos','frete_bairros',
  'datas_disponiveis','clientes','pedidos','pedido_itens','faqs','configuracoes',
];

async function checkTables() {
  console.log('\n🔍 Verificando tabelas no Supabase...\n');
  const missing = [];
  for (const table of TABLES) {
    const { error } = await supabase.from(table).select('*').limit(1);
    const ok = !error || error.code !== '42P01';
    missing.push(!ok);
    console.log(`  ${ok ? '✅' : '❌'} ${table}${!ok ? ` — ${error.message}` : ''}`);
  }
  const nMissing = missing.filter(Boolean).length;
  if (nMissing === 0) {
    console.log('\n✅ Todas as tabelas estão prontas!\n');
  } else {
    console.log(`\n⚠️  ${nMissing} tabela(s) não encontrada(s).`);
    console.log('   Rode execution/schema.sql no Supabase SQL Editor:');
    console.log('   https://supabase.com/dashboard/project/lbdlvkaplyxcjdogtoec/sql\n');
  }
  process.exit(nMissing === 0 ? 0 : 1);
}

checkTables();
