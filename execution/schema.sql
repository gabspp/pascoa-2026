-- ============================================================
-- Santo Favo Páscoa 2026 — Schema Supabase
-- Rodar no SQL Editor do Supabase Dashboard
-- ============================================================

-- ── Extensões ──────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Categorias ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS categorias (
  id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome  TEXT NOT NULL,
  slug  TEXT UNIQUE NOT NULL,
  ordem INT  DEFAULT 0
);

-- ── Produtos ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS produtos (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  categoria_slug TEXT REFERENCES categorias(slug) ON DELETE SET NULL,
  tipo           TEXT NOT NULL DEFAULT 'simples', -- simples | avulso | caixa
  nome           TEXT NOT NULL,
  subtitulo      TEXT,
  descricao      TEXT,
  preco          DECIMAL(10,2),     -- preço fixo (simples/avulso base)
  preco_min      DECIMAL(10,2),     -- para caixas: "A partir de"
  imagem_url     TEXT,
  tag            TEXT,              -- ex: "Clássico", "Novidade"
  tag_cor        TEXT DEFAULT 'verde', -- verde | rosa | roxo | amarelo
  cor_header     TEXT DEFAULT 'amarelo', -- cor da faixa do card
  is_especial_mes BOOLEAN DEFAULT FALSE,
  config         JSONB,             -- para caixas: {"tamanho": 6}
  ativo          BOOLEAN DEFAULT TRUE,
  ordem          INT DEFAULT 0
);

-- ── Sabores de pão de mel (para box configurator) ──────────
-- São produtos do tipo 'avulso' na tabela produtos
-- Nenhuma tabela extra necessária

-- ── Descontos Progressivos ─────────────────────────────────
CREATE TABLE IF NOT EXISTS descontos_progressivos (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  qtd_min        INT            NOT NULL,
  qtd_max        INT,                    -- NULL = sem limite superior
  preco_unitario DECIMAL(10,2)  NOT NULL
);

-- ── Frete por Bairro ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS frete_bairros (
  id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bairro TEXT           NOT NULL UNIQUE, -- lowercase, sem acentos
  valor  DECIMAL(10,2)  NOT NULL
);

-- ── Datas Disponíveis ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS datas_disponiveis (
  id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data  DATE NOT NULL UNIQUE,
  ativo BOOLEAN DEFAULT TRUE
);

-- ── Clientes ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS clientes (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome                TEXT NOT NULL,
  whatsapp            TEXT NOT NULL,
  lgpd_consentimento  BOOLEAN DEFAULT FALSE,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- ── Pedidos ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS pedidos (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  codigo            TEXT UNIQUE,
  cliente_id        UUID REFERENCES clientes(id) ON DELETE SET NULL,
  status            TEXT DEFAULT 'checkout_iniciado',
  -- checkout_iniciado | endereco_preenchido | data_selecionada
  -- pagamento_selecionado | finalizado | cancelado
  tipo_entrega      TEXT,    -- retirada | entrega
  cep               TEXT,
  logradouro        TEXT,
  numero            TEXT,
  complemento       TEXT,
  bairro            TEXT,
  cidade            TEXT,
  estado            TEXT,
  frete             DECIMAL(10,2),
  frete_a_confirmar BOOLEAN DEFAULT FALSE,
  data_entrega      DATE,
  pagamento         TEXT,    -- pix | credito
  observacao        TEXT,
  subtotal          DECIMAL(10,2),
  total             DECIMAL(10,2),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

-- ── Itens do Pedido ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS pedido_itens (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id     UUID REFERENCES pedidos(id) ON DELETE CASCADE,
  tipo          TEXT DEFAULT 'produto',  -- produto | avulso | caixa
  produto_id    UUID REFERENCES produtos(id) ON DELETE SET NULL,
  nome          TEXT NOT NULL,
  quantidade    INT  DEFAULT 1,
  preco_unitario DECIMAL(10,2),
  preco_total   DECIMAL(10,2),
  config_caixa  JSONB  -- para caixas: {tamanho, itens:[{nome,qtd}]}
);

-- ── FAQs ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS faqs (
  id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pergunta TEXT NOT NULL,
  resposta TEXT NOT NULL,
  ordem    INT  DEFAULT 0,
  ativo    BOOLEAN DEFAULT TRUE
);

-- ── Configurações ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS configuracoes (
  chave TEXT PRIMARY KEY,
  valor TEXT NOT NULL
);

-- ============================================================
-- RLS Policies
-- ============================================================

ALTER TABLE categorias           ENABLE ROW LEVEL SECURITY;
ALTER TABLE produtos              ENABLE ROW LEVEL SECURITY;
ALTER TABLE descontos_progressivos ENABLE ROW LEVEL SECURITY;
ALTER TABLE frete_bairros         ENABLE ROW LEVEL SECURITY;
ALTER TABLE datas_disponiveis     ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes              ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedidos               ENABLE ROW LEVEL SECURITY;
ALTER TABLE pedido_itens          ENABLE ROW LEVEL SECURITY;
ALTER TABLE faqs                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE configuracoes         ENABLE ROW LEVEL SECURITY;

-- SELECT público para dados de leitura
CREATE POLICY "public_read_categorias"            ON categorias            FOR SELECT USING (true);
CREATE POLICY "public_read_produtos"              ON produtos              FOR SELECT USING (ativo = true);
CREATE POLICY "public_read_descontos"             ON descontos_progressivos FOR SELECT USING (true);
CREATE POLICY "public_read_frete"                 ON frete_bairros         FOR SELECT USING (true);
CREATE POLICY "public_read_datas"                 ON datas_disponiveis     FOR SELECT USING (ativo = true);
CREATE POLICY "public_read_faqs"                  ON faqs                  FOR SELECT USING (ativo = true);
CREATE POLICY "public_read_configuracoes"         ON configuracoes         FOR SELECT USING (true);

-- Clientes: INSERT público
CREATE POLICY "public_insert_clientes" ON clientes FOR INSERT WITH CHECK (true);

-- Pedidos: INSERT + UPDATE públicos (por id, sem auth)
CREATE POLICY "public_insert_pedidos"  ON pedidos  FOR INSERT WITH CHECK (true);
CREATE POLICY "public_update_pedidos"  ON pedidos  FOR UPDATE USING (true);
CREATE POLICY "public_select_pedidos"  ON pedidos  FOR SELECT USING (true);

-- Itens: INSERT público
CREATE POLICY "public_insert_itens"    ON pedido_itens FOR INSERT WITH CHECK (true);
CREATE POLICY "public_select_itens"    ON pedido_itens FOR SELECT USING (true);

-- ============================================================
-- Seed: Descontos Progressivos
-- ============================================================
INSERT INTO descontos_progressivos (qtd_min, qtd_max, preco_unitario) VALUES
  (1,   24,  10.00),
  (25,  49,   9.50),
  (50,  99,   9.00),
  (100, NULL,  8.50)
ON CONFLICT DO NOTHING;

-- ============================================================
-- Seed: Categorias
-- ============================================================
INSERT INTO categorias (nome, slug, ordem) VALUES
  ('Ovos de Páscoa',      'ovos-pascoa',       1),
  ('Pão de Mel Avulso',   'pao-de-mel-avulso', 2),
  ('Barras',              'barras',            3),
  ('Caixas de Presente',  'caixas',            4)
ON CONFLICT (slug) DO NOTHING;

-- ============================================================
-- Seed: Produtos
-- ============================================================

-- Ovos de Páscoa
INSERT INTO produtos (categoria_slug, tipo, nome, subtitulo, descricao, preco, imagem_url, tag, tag_cor, cor_header, ordem) VALUES
  ('ovos-pascoa', 'simples', 'Ovo Pão de Mel', 'Recheio de Amendoim',
   'Casca de chocolate ao leite com pão de mel e recheio cremoso de amendoim. Irresistível e cheio de afeto.',
   65.00, 'img/ovo_amendoim.jpg', 'Clássico', 'verde', 'amarelo', 1),

  ('ovos-pascoa', 'simples', 'Ovo Casca Caramelo', 'Caramelo Salgado',
   'Casca de chocolate com caramelo salgado e pão de mel. Equilíbrio perfeito entre doce e sofisticado.',
   75.00, 'img/ovo_casca-caramelo.jpg', 'Campeão de Vendas', 'rosa', 'amarelo', 2),

  ('ovos-pascoa', 'simples', 'Ovo Fudge', 'Chocolate Intenso',
   'Recheio de fudge de chocolate intenso com pão de mel. Para os amantes de chocolate puro.',
   70.00, 'img/ovo_fudge.jpg', 'Novidade', 'amarelo', 'roxo', 3),

  ('ovos-pascoa', 'simples', 'Ovo Doce de Leite com Nozes', 'Doce de Leite Cremoso',
   'Pão de mel com doce de leite artesanal e nozes. Uma combinação que aquece a alma.',
   80.00, 'img/ovo_pdm_doce_de_leite_com_nozes.jpg', NULL, NULL, 'amarelo', 4),

  ('ovos-pascoa', 'simples', 'Ovo Caramelo PDM', 'Caramelo com Pão de Mel',
   'Pão de mel artesanal com caramelo cremoso. Textura perfeita e sabor inesquecível.',
   65.00, 'img/ovo_pdm_caramelo.jpg', NULL, NULL, 'rosa', 5)
ON CONFLICT DO NOTHING;

-- Pão de Mel Avulso (sabores)
INSERT INTO produtos (categoria_slug, tipo, nome, subtitulo, descricao, preco, imagem_url, tag, tag_cor, cor_header, is_especial_mes, ordem) VALUES
  ('pao-de-mel-avulso', 'avulso', 'Pão de Mel Doce de Leite', 'Sabor Doce de Leite',
   'Pão de mel com cobertura de chocolate e recheio cremoso de doce de leite.',
   10.00, 'img/ovo_pdm_doce_de_leite_com_nozes.jpg', NULL, NULL, 'amarelo', FALSE, 1),

  ('pao-de-mel-avulso', 'avulso', 'Pão de Mel Amendoim', 'Sabor Amendoim',
   'Pão de mel com cobertura de chocolate e recheio cremoso de amendoim.',
   10.00, 'img/ovo_amendoim.jpg', NULL, NULL, 'amarelo', FALSE, 2),

  ('pao-de-mel-avulso', 'avulso', 'Pão de Mel Caramelo', 'Sabor Caramelo Salgado',
   'Pão de mel com cobertura de chocolate e recheio de caramelo salgado.',
   10.00, 'img/ovo_pdm_caramelo.jpg', NULL, NULL, 'amarelo', FALSE, 3),

  ('pao-de-mel-avulso', 'avulso', 'Pão de Mel Fudge', 'Sabor Fudge',
   'Pão de mel com cobertura de chocolate intenso e recheio de fudge.',
   10.00, 'img/ovo_fudge.jpg', NULL, NULL, 'roxo', FALSE, 4),

  ('pao-de-mel-avulso', 'avulso', 'Pão de Mel Sem Recheio', 'Clássico',
   'Pão de mel com cobertura de chocolate. O clássico de sempre.',
   10.00, 'img/ovo_casca-caramelo.jpg', NULL, NULL, 'verde', FALSE, 5),

  ('pao-de-mel-avulso', 'avulso', 'Pão de Mel da Estação', 'Especial do Mês',
   'Sabor especial do mês feito com ingredientes sazonais. Disponível por tempo limitado!',
   12.00, 'img/ovo_casca-caramelo.jpg', 'Especial', 'rosa', 'rosa', TRUE, 6)
ON CONFLICT DO NOTHING;

-- Barras
INSERT INTO produtos (categoria_slug, tipo, nome, subtitulo, descricao, preco, imagem_url, tag, tag_cor, cor_header, ordem) VALUES
  ('barras', 'simples', 'Barra Cajutella', 'Chocolate com Pasta de Caju',
   'Chocolate artesanal com cajutella cremosa. Uma combinação que conquistou o público e não sai da memória afetiva.',
   55.00, 'img/barra_cajutella.jpg', 'Novidade', 'amarelo', 'rosa', 1),

  ('barras', 'simples', 'Barra Caramelo Salgado', 'Caramelo com Flor de Sal',
   'Chocolate artesanal com caramelo salgado e um toque de flor de sal. Equilíbrio sofisticado.',
   55.00, 'img/barra_caramelo.jpg', NULL, NULL, 'amarelo', 2),

  ('barras', 'simples', 'Barra de Chocolate', 'Chocolate Puro',
   'Chocolate artesanal feito com mel de abelha. Sabor limpo, intenso e com origem rastreável.',
   45.00, 'img/barra.jpg', NULL, NULL, 'marrom', 3)
ON CONFLICT DO NOTHING;

-- Caixas de Presente
INSERT INTO produtos (categoria_slug, tipo, nome, subtitulo, descricao, preco_min, imagem_url, tag, tag_cor, cor_header, config, ordem) VALUES
  ('caixas', 'caixa', 'Caixa com 3 Pães de Mel', 'Monte do seu jeito',
   'Escolha 3 sabores de pão de mel para presentear com carinho. Embalagem especial inclusa.',
   35.00, 'img/caixa_3_pdm.jpg', NULL, NULL, 'verde', '{"tamanho": 3}', 1),

  ('caixas', 'caixa', 'Caixa com 6 Pães de Mel', 'Monte do seu jeito',
   'Escolha 6 sabores de pão de mel para um presente inesquecível. Embalagem especial inclusa.',
   65.00, 'img/caixa_9_pdm.jpg', 'Popular', 'verde', 'verde', '{"tamanho": 6}', 2),

  ('caixas', 'caixa', 'Caixa com 9 Pães de Mel', 'Monte do seu jeito',
   'Escolha 9 sabores de pão de mel. Perfeita para presentear a família toda.',
   95.00, 'img/caixa_9_pdm.jpg', NULL, NULL, 'amarelo', '{"tamanho": 9}', 3),

  ('caixas', 'caixa', 'Caixa com 15 Pães de Mel', 'Monte do seu jeito',
   'A caixa mais completa! 15 pães de mel à sua escolha. Para os momentos mais especiais.',
   155.00, 'img/caixa_15_pdm.jpg', 'Campeão de Vendas', 'rosa', 'marrom', '{"tamanho": 15}', 4)
ON CONFLICT DO NOTHING;

-- ============================================================
-- Seed: Datas Disponíveis (Abril 2026)
-- ============================================================
INSERT INTO datas_disponiveis (data, ativo) VALUES
  ('2026-04-01', true),
  ('2026-04-02', true),
  ('2026-04-03', true),
  ('2026-04-04', true),
  ('2026-04-05', true),
  ('2026-04-08', true),
  ('2026-04-09', true),
  ('2026-04-10', true),
  ('2026-04-11', true),
  ('2026-04-12', true),
  ('2026-04-15', true),
  ('2026-04-16', true),
  ('2026-04-17', true),
  ('2026-04-18', true),
  ('2026-04-19', true)
ON CONFLICT (data) DO NOTHING;

-- ============================================================
-- Seed: Configurações
-- ============================================================
INSERT INTO configuracoes (chave, valor) VALUES
  ('endereco_retirada', 'Rua das Flores, 123 — Botafogo, Rio de Janeiro — RJ'),
  ('whatsapp_numero', '5521967643537'),
  ('prazo_minimo_horas', '24')
ON CONFLICT (chave) DO UPDATE SET valor = EXCLUDED.valor;

-- ============================================================
-- Seed: FAQs
-- ============================================================
INSERT INTO faqs (pergunta, resposta, ordem) VALUES
  ('Como faço meu pedido?',
   'Acesse nossa loja, escolha seus produtos, monte sua cesta e finalize pelo WhatsApp. É simples e rápido!',
   1),
  ('Qual o prazo mínimo para fazer um pedido?',
   'Os pedidos devem ser feitos com pelo menos 24 horas de antecedência.',
   2),
  ('Vocês entregam em qual região?',
   'Entregamos em toda a cidade do Rio de Janeiro — Capital. Para outras regiões, entre em contato.',
   3),
  ('Como funciona a caixa personalizada?',
   'Você escolhe o tamanho da caixa (3, 6, 9 ou 15 pães) e seleciona os sabores que quiser. O preço é a soma dos pães mais R$ 5,00 da embalagem.',
   4),
  ('Qual a forma de pagamento?',
   'Aceitamos PIX e Cartão de Crédito. O pagamento é combinado diretamente com a nossa equipe após o envio do pedido pelo WhatsApp.',
   5),
  ('Os produtos contêm glúten?',
   'Nossos pães de mel contêm glúten. Se você tiver restrições alimentares, entre em contato antes de fazer seu pedido.',
   6)
ON CONFLICT DO NOTHING;
