const { createClient } = require('@supabase/supabase-js');
const { config }       = require('dotenv');
const path             = require('path');

config({ path: path.resolve(__dirname, '../.env') });
const sb = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY);

async function main() {
  // Produtos
  const { data: prods } = await sb.from('produtos').select('nome, tipo, preco, preco_min, ativo').order('categoria_slug').order('ordem');
  console.log('\n🍫 PRODUTOS:');
  prods.forEach(p => {
    const preco = p.preco != null ? `R$ ${p.preco}` : `a partir de R$ ${p.preco_min}`;
    console.log(`  [${p.tipo}] ${p.nome} — ${preco} ${p.ativo ? '' : '(inativo)'}`);
  });

  // Datas
  const { data: datas } = await sb.from('datas_disponiveis').select('data, ativo').order('data');
  console.log('\n📅 DATAS DISPONÍVEIS:');
  datas.forEach(d => console.log(`  ${d.data} ${d.ativo ? '✅' : '❌'}`));

  // Configurações
  const { data: cfgs } = await sb.from('configuracoes').select('chave, valor');
  console.log('\n⚙️  CONFIGURAÇÕES:');
  cfgs.forEach(c => console.log(`  ${c.chave}: ${c.valor}`));
}

main();
