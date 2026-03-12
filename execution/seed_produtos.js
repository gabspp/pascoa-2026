/**
 * seed_produtos.js — Substitui todos os produtos pelos dados reais.
 * Uso: node execution/seed_produtos.js
 */
const { createClient } = require('@supabase/supabase-js');
const { config }       = require('dotenv');
const path             = require('path');

config({ path: path.resolve(__dirname, '../.env') });

const sb = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const PRODUTOS = [
  // ── Ovos de Páscoa ──────────────────────────────────────
  {
    categoria_slug: 'ovos-pascoa', tipo: 'simples', ordem: 1,
    nome: 'Ovo Pão de Mel - Doce de Leite com Nozes',
    descricao: 'Chocolate 40% de produção própria, casca recheada de pão de mel e doce de leite com nozes. Validade: 10 dias. Peso aproximado: 450g. MANTER EM LOCAL FRESCO, SECO E AREJADO.',
    preco: 150.00, tag: 'Clássico', tag_cor: 'verde', cor_header: 'marrom',
    imagem_url: 'img/ovo_pdm_doce_de_leite_com_nozes.jpg',
  },
  {
    categoria_slug: 'ovos-pascoa', tipo: 'simples', ordem: 2,
    nome: 'Ovo Pão de Mel - Caramelo Salgado',
    descricao: 'Chocolate 40% de produção própria, casca recheada de pão de mel e caramelo salgado. Validade: 10 dias. Peso aproximado: 450g. MANTER EM LOCAL FRESCO, SECO E AREJADO.',
    preco: 150.00, tag: 'Mais Vendido', tag_cor: 'rosa', cor_header: 'marrom',
    imagem_url: 'img/ovo_pdm_caramelo.jpg',
  },
  {
    categoria_slug: 'ovos-pascoa', tipo: 'simples', ordem: 3,
    nome: 'Ovo Casca Recheada - Caramelo Salgado',
    descricao: 'Chocolate 40% de produção própria, casca recheada de caramelo salgado. Validade: 10 dias. Peso aproximado: 420g. MANTER EM LOCAL FRESCO, SECO E AREJADO.',
    preco: 150.00, tag: null, tag_cor: 'verde', cor_header: 'marrom',
    imagem_url: 'img/ovo_casca-caramelo.jpg',
  },
  {
    categoria_slug: 'ovos-pascoa', tipo: 'simples', ordem: 4,
    nome: 'Ovo Amendoim, Chocolate e Caramelo',
    descricao: 'Chocolate 40% de produção própria, casca recheada de creme de manteiga de amendoim com chocolate, caramelo salgado e amendoim. Validade: 10 dias. Peso aproximado: 450g. MANTER EM LOCAL FRESCO, SECO E AREJADO.',
    preco: 170.00, tag: null, tag_cor: 'verde', cor_header: 'marrom',
    imagem_url: 'img/ovo_amendoim.jpg',
  },
  {
    categoria_slug: 'ovos-pascoa', tipo: 'simples', ordem: 5,
    nome: 'Ovo Fudge e Framboesa',
    descricao: 'Chocolate 40% de produção própria, casca recheada de fudge de chocolate meio amargo, fudge de chocolate branco e geleia de framboesa. Validade: 10 dias. Peso aproximado: 450g. MANTER EM LOCAL FRESCO, SECO E AREJADO.',
    preco: 170.00, tag: 'Novidade', tag_cor: 'roxo', cor_header: 'marrom',
    imagem_url: 'img/ovo_fudge.jpg',
  },

  // ── Barras Recheadas ────────────────────────────────────
  {
    categoria_slug: 'barras', tipo: 'simples', ordem: 1,
    nome: 'Barra de Chocolate - Caramelo Salgado',
    descricao: 'Chocolate 40% de produção própria, recheado de caramelo salgado. Validade: 20 dias. Peso aproximado: 200g. MANTER EM LOCAL FRESCO, SECO E AREJADO.',
    preco: 55.00, tag: 'Novo', tag_cor: 'verde', cor_header: 'amarelo',
    imagem_url: 'img/barra_caramelo.jpg',
  },
  {
    categoria_slug: 'barras', tipo: 'simples', ordem: 2,
    nome: 'Barra de Chocolate - Cajutella',
    descricao: 'Chocolate 40% de produção própria, recheado de cajutella (creme de castanha de caju com chocolate) e castanha de caju. Validade: 20 dias. Peso aproximado: 200g. MANTER EM LOCAL FRESCO, SECO E AREJADO.',
    preco: 55.00, tag: 'Novo', tag_cor: 'verde', cor_header: 'amarelo',
    imagem_url: 'img/barra_cajutella.jpg',
  },

  // ── Caixas para Presentear ──────────────────────────────
  {
    categoria_slug: 'caixas', tipo: 'caixa', ordem: 1,
    nome: 'Caixa com 3 Pães De Mel',
    descricao: 'Escolha os sabores de recheio e monte como quiser!',
    preco_min: 35.00, tag: null, tag_cor: 'verde', cor_header: 'verde',
    config: { tamanho: 3 },
    imagem_url: 'img/caixa_3_pdm.jpg',
  },
  {
    categoria_slug: 'caixas', tipo: 'caixa', ordem: 2,
    nome: 'Caixa com 6 Pães De Mel',
    descricao: 'Escolha os sabores de recheio e monte como quiser!',
    preco_min: 65.00, tag: null, tag_cor: 'verde', cor_header: 'verde',
    config: { tamanho: 6 },
    imagem_url: 'img/caixa_9_pdm.jpg',
  },
  {
    categoria_slug: 'caixas', tipo: 'caixa', ordem: 3,
    nome: 'Caixa com 9 Pães De Mel',
    descricao: 'Escolha os sabores de recheio e monte como quiser!',
    preco_min: 95.00, tag: 'Favorito', tag_cor: 'amarelo', cor_header: 'verde',
    config: { tamanho: 9 },
    imagem_url: 'img/caixa_9_pdm.jpg',
  },
  {
    categoria_slug: 'caixas', tipo: 'caixa', ordem: 4,
    nome: 'Caixa com 15 Pães De Mel',
    descricao: 'Escolha os sabores de recheio e monte como quiser!',
    preco_min: 155.00, tag: 'Presentão!', tag_cor: 'rosa', cor_header: 'verde',
    config: { tamanho: 15 },
    imagem_url: 'img/caixa_15_pdm.jpg',
  },

  // ── Pães de Mel Avulso ──────────────────────────────────
  {
    categoria_slug: 'pao-de-mel-avulso', tipo: 'avulso', ordem: 1,
    nome: 'Pão De Mel - Chocolate',
    descricao: 'Páscoa tem que ter CHOCOLATE! O melhor pão de mel do mundo com um recheio chocolatudo de ganache. Coberto com o nosso chocolate da casa, claro! Validade: 12 dias.',
    preco: 12.00, tag: 'Especial do Mês', tag_cor: 'rosa', cor_header: 'rosa',
    is_especial_mes: true,
    imagem_url: 'img/ovo_pdm_caramelo.jpg',
  },
  {
    categoria_slug: 'pao-de-mel-avulso', tipo: 'avulso', ordem: 2,
    nome: 'Pão de Mel - Doce de Leite com Nozes',
    descricao: 'O começo de tudo! Nosso primeiro pão de mel, coberto de chocolate e recheado com doce de leite com nozes. Validade: 12 dias.',
    preco: 10.00, tag: null, tag_cor: 'verde', cor_header: 'amarelo',
    imagem_url: 'img/ovo_pdm_doce_de_leite_com_nozes.jpg',
  },
  {
    categoria_slug: 'pao-de-mel-avulso', tipo: 'avulso', ordem: 3,
    nome: 'Pão de Mel - Caramelo Salgado',
    descricao: 'Nosso campeão de vendas e provavelmente o seu favorito. O melhor pão de mel do Rio, coberto de chocolate e recheado com o nosso irresistível caramelo salgado. Validade: 12 dias.',
    preco: 10.00, tag: 'Mais Vendido', tag_cor: 'rosa', cor_header: 'amarelo',
    imagem_url: 'img/ovo_pdm_caramelo.jpg',
  },
  {
    categoria_slug: 'pao-de-mel-avulso', tipo: 'avulso', ordem: 4,
    nome: 'Pão De Mel - Cajutella',
    descricao: 'Um recheio rico, cremoso, crocante e chocolatudo. Pão de mel coberto de chocolate e recheado com creme de castanha de caju com chocolate. Validade: 12 dias.',
    preco: 10.00, tag: 'Exclusivo', tag_cor: 'roxo', cor_header: 'amarelo',
    imagem_url: 'img/barra_cajutella.jpg',
  },
  {
    categoria_slug: 'pao-de-mel-avulso', tipo: 'avulso', ordem: 5,
    nome: 'Pão De Mel - Laranja',
    descricao: 'Nosso recheio aproveita cada pedacinho da fruta e demora 3 dias para ficar pronto. O resultado é um doce de laranja surreal! Validade: 7 dias.',
    preco: 10.00, tag: null, tag_cor: 'verde', cor_header: 'amarelo',
    imagem_url: 'img/ovo_pdm_doce_de_leite_com_nozes.jpg',
  },
  {
    categoria_slug: 'pao-de-mel-avulso', tipo: 'avulso', ordem: 6,
    nome: 'Pão De Mel - Maracujá',
    descricao: 'Refresque o seu paladar com a acidez vibrante do curd de maracujá, que contrasta perfeitamente com o doce do pão de mel e a cobertura de chocolate. Validade: 12 dias.',
    preco: 10.00, tag: null, tag_cor: 'verde', cor_header: 'amarelo',
    imagem_url: 'img/ovo_pdm_caramelo.jpg',
  },
  {
    categoria_slug: 'pao-de-mel-avulso', tipo: 'avulso', ordem: 7,
    nome: 'Pão De Mel - Sem Recheio',
    descricao: 'O simples e perfeito. Para os fãs da pureza do pão de mel tradicional, com sua massa macia, saborosa e molhadinha, e a clássica cobertura de chocolate. Validade: 12 dias.',
    preco: 10.00, tag: 'Clássico', tag_cor: 'verde', cor_header: 'amarelo',
    imagem_url: 'img/ovo_pdm_doce_de_leite_com_nozes.jpg',
  },
];

async function main() {
  console.log('\n🗑️  Removendo produtos existentes...');
  const { error: delErr } = await sb.from('produtos').delete().neq('id', '00000000-0000-0000-0000-000000000000');
  if (delErr) { console.error('❌ Erro ao deletar:', delErr.message); process.exit(1); }

  console.log(`📦 Inserindo ${PRODUTOS.length} produtos reais...\n`);
  const { data, error } = await sb.from('produtos').insert(PRODUTOS).select('nome, tipo, preco, preco_min, tag');
  if (error) { console.error('❌ Erro ao inserir:', error.message); process.exit(1); }

  data.forEach(p => {
    const preco = p.preco != null ? `R$ ${p.preco}` : `a partir de R$ ${p.preco_min}`;
    const tag = p.tag ? ` [${p.tag}]` : '';
    console.log(`  ✅ [${p.tipo}] ${p.nome} — ${preco}${tag}`);
  });
  console.log(`\n✅ ${data.length} produtos inseridos.\n`);
}

main();
