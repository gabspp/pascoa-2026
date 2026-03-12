/**
 * check_data.js — Mostra quantos registros existem em cada tabela.
 * Uso: node execution/check_data.js
 */
const { createClient } = require('@supabase/supabase-js');
const { config }       = require('dotenv');
const path             = require('path');

config({ path: path.resolve(__dirname, '../.env') });

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY
);

const TABLES = [
  'categorias','produtos','descontos_progressivos','frete_bairros',
  'datas_disponiveis','configuracoes','faqs',
];

async function checkData() {
  console.log('\n📊 Conteúdo das tabelas:\n');
  for (const table of TABLES) {
    const { data, error } = await supabase.from(table).select('*');
    if (error) {
      console.log(`  ❌ ${table}: ${error.message}`);
    } else {
      const count = data.length;
      const status = count === 0 ? '⚠️  VAZIO' : `✅ ${count} registro(s)`;
      console.log(`  ${status} — ${table}`);
      if (count > 0 && count <= 5) {
        data.forEach(row => {
          const preview = Object.entries(row).slice(0,3).map(([k,v]) => `${k}: ${JSON.stringify(v)}`).join(' | ');
          console.log(`       → ${preview}`);
        });
      }
    }
  }
  console.log('');
}

checkData();
