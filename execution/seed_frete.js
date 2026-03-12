/**
 * seed_frete.js — Popula a tabela frete_bairros com as taxas de entrega.
 * Uso: node execution/seed_frete.js
 */
const { createClient } = require('@supabase/supabase-js');
const { config }       = require('dotenv');
const path             = require('path');

config({ path: path.resolve(__dirname, '../.env') });

const sb = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY
);

const FRETE = [
  // Zona Norte
  { bairro: 'andarai',               valor: 22 },
  { bairro: 'cachambi',              valor: 27 },
  { bairro: 'engenho de dentro',     valor: 26 },
  { bairro: 'grajau',                valor: 25 },
  { bairro: 'jardim sulacap',        valor: 50 },
  { bairro: 'lins de vasconcelos',   valor: 30 },
  { bairro: 'maracana',              valor: 19 },
  { bairro: 'meier',                 valor: 28 },
  { bairro: 'penha',                 valor: 33 },
  { bairro: 'penha circular',        valor: 30 },
  { bairro: 'praca da bandeira',     valor: 19 },
  { bairro: 'sao cristovao',         valor: 23 },
  { bairro: 'tijuca',                valor: 22 },
  { bairro: 'todos os santos',       valor: 25 },
  { bairro: 'vila isabel',           valor: 20 },
  // Zona Sul
  { bairro: 'botafogo',              valor: 14 },
  { bairro: 'catete',                valor: 10 },
  { bairro: 'cosme velho',           valor: 15 },
  { bairro: 'copacabana',            valor: 16 },
  { bairro: 'flamengo',              valor: 10 },
  { bairro: 'gavea',                 valor: 18 },
  { bairro: 'humaita',               valor: 17 },
  { bairro: 'ipanema',               valor: 18 },
  { bairro: 'lagoa',                 valor: 17 },
  { bairro: 'laranjeiras',           valor: 11 },
  { bairro: 'leblon',                valor: 20 },
  { bairro: 'leme',                  valor: 15 },
  { bairro: 'urca',                  valor: 15 },
  // Centro
  { bairro: 'centro',                valor: 16 },
  { bairro: 'cidade nova',           valor: 16 },
  { bairro: 'estacio',               valor: 19 },
  { bairro: 'gamboa',                valor: 15 },
  { bairro: 'gloria',                valor: 12 },
  { bairro: 'santa teresa',          valor: 16 },
  { bairro: 'santo cristo',          valor: 15 },
  { bairro: 'saude',                 valor: 15 },
  // Zona Oeste
  { bairro: 'anil',                  valor: 45 },
  { bairro: 'barra da tijuca',       valor: 35 },
  { bairro: 'barra olimpica',        valor: 50 },
  { bairro: 'campo grande',          valor: 55 },
  { bairro: 'jacarepagua',           valor: 30 },
  { bairro: 'recreio dos bandeirantes', valor: 60 },
  { bairro: 'sao conrado',           valor: 27 },
  // Ilha do Governador
  { bairro: 'portuguesa',            valor: 50 },
  // Niterói
  { bairro: 'icarai',                valor: 40 },
];

async function main() {
  console.log(`\n🚚 Inserindo ${FRETE.length} bairros em frete_bairros...\n`);

  const { data, error } = await sb
    .from('frete_bairros')
    .upsert(FRETE, { onConflict: 'bairro' })
    .select('bairro, valor');

  if (error) {
    console.error('❌ Erro:', error.message);
    process.exit(1);
  }

  console.log(`✅ ${data.length} registros inseridos/atualizados:\n`);
  data.forEach(r => console.log(`  ${r.bairro}: R$ ${r.valor}`));
  console.log('');
}

main();
