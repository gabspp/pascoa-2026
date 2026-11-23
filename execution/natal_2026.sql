-- ============================================================
-- Santo Favo — Natal 2026 — Migração do banco
-- Rodar UMA vez no SQL Editor do Supabase (projeto da Páscoa).
-- Pode rodar de novo sem quebrar (usa IF NOT EXISTS / ON CONFLICT).
--
-- O que faz:
--   1. Colunas novas: campanha, antecedência, limite, entrega/retirada por data
--   2. Fecha o acesso público aos pedidos (falha de segurança da Páscoa)
--   3. Funções seguras que o site usa para criar e finalizar pedidos
--   4. Cadastro inicial do Natal (categorias, produtos, preços, datas, FAQs)
--
-- ANTES DE RODAR: confirmar que o site de brindes (/brindes-2026) NÃO usa as
-- tabelas pedidos / pedido_itens / clientes deste projeto.
-- ============================================================

BEGIN;

-- ── 1. Colunas novas ───────────────────────────────────────

-- campanha: separa Páscoa, Natal e as próximas datas
ALTER TABLE categorias ADD COLUMN IF NOT EXISTS campanha TEXT;
ALTER TABLE produtos   ADD COLUMN IF NOT EXISTS campanha TEXT;
ALTER TABLE pedidos    ADD COLUMN IF NOT EXISTS campanha TEXT;
ALTER TABLE faqs       ADD COLUMN IF NOT EXISTS campanha TEXT;

UPDATE categorias SET campanha = 'pascoa-2026' WHERE campanha IS NULL;
UPDATE produtos   SET campanha = 'pascoa-2026' WHERE campanha IS NULL;
UPDATE pedidos    SET campanha = 'pascoa-2026' WHERE campanha IS NULL;
UPDATE faqs       SET campanha = 'pascoa-2026' WHERE campanha IS NULL;

-- produtos: antecedência mínima em dias (NULL = regra das 17h do dia anterior)
-- e limite de unidades na campanha inteira (NULL = sem limite)
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS antecedencia_dias INT;
ALTER TABLE produtos ADD COLUMN IF NOT EXISTS limite_unidades   INT;

-- datas: o que é possível em cada dia e horário especial ("até 12h")
ALTER TABLE datas_disponiveis ADD COLUMN IF NOT EXISTS permite_retirada BOOLEAN DEFAULT TRUE;
ALTER TABLE datas_disponiveis ADD COLUMN IF NOT EXISTS permite_entrega  BOOLEAN DEFAULT TRUE;
ALTER TABLE datas_disponiveis ADD COLUMN IF NOT EXISTS horario          TEXT;

-- pedidos: token secreto que só o navegador do cliente conhece
ALTER TABLE pedidos ADD COLUMN IF NOT EXISTS token UUID DEFAULT gen_random_uuid();

-- itens: tamanho escolhido (bolos)
ALTER TABLE pedido_itens ADD COLUMN IF NOT EXISTS variacao TEXT;


-- ── 2. Segurança: tirar o acesso público direto aos pedidos ─
-- O site passa a usar só as funções da seção 3. O admin continua usando as
-- políticas "admin_*" (usuário autenticado).

DROP POLICY IF EXISTS "public_insert_clientes" ON clientes;
DROP POLICY IF EXISTS "public_insert_pedidos"  ON pedidos;
DROP POLICY IF EXISTS "public_update_pedidos"  ON pedidos;
DROP POLICY IF EXISTS "public_select_pedidos"  ON pedidos;
DROP POLICY IF EXISTS "public_insert_itens"    ON pedido_itens;
DROP POLICY IF EXISTS "public_select_itens"    ON pedido_itens;

-- Admin: precisa ver produtos inativos e editar o cadastro
DROP POLICY IF EXISTS "admin_select_produtos" ON produtos;
CREATE POLICY "admin_select_produtos" ON produtos FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "admin_update_produtos" ON produtos;
CREATE POLICY "admin_update_produtos" ON produtos FOR UPDATE TO authenticated USING (true);
DROP POLICY IF EXISTS "admin_update_itens" ON pedido_itens;
CREATE POLICY "admin_update_itens" ON pedido_itens FOR UPDATE TO authenticated USING (true);


-- ── 3. Funções do checkout ─────────────────────────────────
-- SECURITY DEFINER: rodam com permissão do dono, então o site consegue gravar
-- sem ter acesso de leitura às tabelas. Cada pedido só é alterado por quem tem
-- o token dele.

-- Configuração ativa
CREATE OR REPLACE FUNCTION campanha_ativa() RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT valor FROM configuracoes WHERE chave = 'campanha_ativa'
$$;

-- Data de hoje no Rio
CREATE OR REPLACE FUNCTION hoje_rio() RETURNS DATE
LANGUAGE sql STABLE AS $$
  SELECT (now() AT TIME ZONE 'America/Sao_Paulo')::date
$$;

-- Status que contam como venda (não contam carrinhos abandonados nem cancelados)
CREATE OR REPLACE FUNCTION status_conta_venda(s TEXT) RETURNS BOOLEAN
LANGUAGE sql IMMUTABLE AS $$
  SELECT s NOT IN ('checkout_iniciado','endereco_preenchido','data_selecionada',
                   'pagamento_selecionado','cancelado')
$$;

-- Unidades restantes de cada produto com limite (público: só números)
CREATE OR REPLACE FUNCTION estoque_restante()
RETURNS TABLE (produto_id UUID, limite INT, vendidos INT, restante INT)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT p.id,
         p.limite_unidades,
         COALESCE(SUM(i.quantidade) FILTER (WHERE status_conta_venda(pe.status)), 0)::INT,
         GREATEST(p.limite_unidades
                  - COALESCE(SUM(i.quantidade) FILTER (WHERE status_conta_venda(pe.status)), 0), 0)::INT
  FROM produtos p
  LEFT JOIN pedido_itens i ON i.produto_id = p.id
  LEFT JOIN pedidos pe     ON pe.id = i.pedido_id AND pe.campanha = p.campanha
  WHERE p.limite_unidades IS NOT NULL
    AND p.campanha = campanha_ativa()
  GROUP BY p.id, p.limite_unidades
$$;

-- Etapa "Seus dados": cria cliente + pedido e devolve id e token
CREATE OR REPLACE FUNCTION checkout_iniciar(p_nome TEXT, p_whatsapp TEXT, p_subtotal NUMERIC)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_cliente UUID;
  v_pedido  UUID;
  v_token   UUID := gen_random_uuid();
BEGIN
  IF COALESCE(trim(p_nome), '') = '' OR COALESCE(trim(p_whatsapp), '') = '' THEN
    RAISE EXCEPTION 'DADOS_INVALIDOS';
  END IF;

  INSERT INTO clientes (nome, whatsapp, lgpd_consentimento)
  VALUES (left(trim(p_nome), 120), left(trim(p_whatsapp), 30), TRUE)
  RETURNING id INTO v_cliente;

  INSERT INTO pedidos (cliente_id, status, subtotal, campanha, token)
  VALUES (v_cliente, 'checkout_iniciado', p_subtotal, campanha_ativa(), v_token)
  RETURNING id INTO v_pedido;

  RETURN json_build_object('pedido_id', v_pedido, 'token', v_token);
END $$;

-- Etapas intermediárias: grava só os campos permitidos
CREATE OR REPLACE FUNCTION checkout_atualizar(p_id UUID, p_token UUID, p_dados JSONB)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_status TEXT := p_dados->>'status';
BEGIN
  IF v_status IS NOT NULL AND v_status NOT IN
     ('checkout_iniciado','endereco_preenchido','data_selecionada','pagamento_selecionado') THEN
    RAISE EXCEPTION 'STATUS_INVALIDO';
  END IF;

  UPDATE pedidos SET
    status            = COALESCE(v_status, status),
    tipo_entrega      = CASE WHEN p_dados ? 'tipo_entrega'      THEN p_dados->>'tipo_entrega'      ELSE tipo_entrega END,
    cep               = CASE WHEN p_dados ? 'cep'               THEN p_dados->>'cep'               ELSE cep END,
    logradouro        = CASE WHEN p_dados ? 'logradouro'        THEN p_dados->>'logradouro'        ELSE logradouro END,
    numero            = CASE WHEN p_dados ? 'numero'            THEN p_dados->>'numero'            ELSE numero END,
    complemento       = CASE WHEN p_dados ? 'complemento'       THEN p_dados->>'complemento'       ELSE complemento END,
    bairro            = CASE WHEN p_dados ? 'bairro'            THEN p_dados->>'bairro'            ELSE bairro END,
    cidade            = CASE WHEN p_dados ? 'cidade'            THEN p_dados->>'cidade'            ELSE cidade END,
    estado            = CASE WHEN p_dados ? 'estado'            THEN p_dados->>'estado'            ELSE estado END,
    frete             = CASE WHEN p_dados ? 'frete'             THEN (p_dados->>'frete')::NUMERIC  ELSE frete END,
    frete_a_confirmar = CASE WHEN p_dados ? 'frete_a_confirmar' THEN (p_dados->>'frete_a_confirmar')::BOOLEAN ELSE frete_a_confirmar END,
    data_entrega      = CASE WHEN p_dados ? 'data_entrega'      THEN (p_dados->>'data_entrega')::DATE ELSE data_entrega END,
    pagamento         = CASE WHEN p_dados ? 'pagamento'         THEN p_dados->>'pagamento'         ELSE pagamento END,
    observacao        = CASE WHEN p_dados ? 'observacao'        THEN left(p_dados->>'observacao', 1000) ELSE observacao END,
    subtotal          = CASE WHEN p_dados ? 'subtotal'          THEN (p_dados->>'subtotal')::NUMERIC ELSE subtotal END,
    updated_at        = now()
  WHERE id = p_id AND token = p_token AND NOT status_conta_venda(status);

  IF NOT FOUND THEN RAISE EXCEPTION 'PEDIDO_NAO_ENCONTRADO'; END IF;
END $$;

-- Etapa final: confere data, antecedência e limites; grava itens; gera código
-- p_itens: [{tipo, produto_id, nome, variacao, quantidade, preco_unitario, preco_total, config_caixa}]
CREATE OR REPLACE FUNCTION checkout_finalizar(p_id UUID, p_token UUID, p_itens JSONB, p_total NUMERIC)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_pedido   pedidos%ROWTYPE;
  v_data     datas_disponiveis%ROWTYPE;
  v_prefixo  TEXT;
  v_dia      TEXT;
  v_seq      INT;
  v_codigo   TEXT;
  r          RECORD;
BEGIN
  -- Uma finalização por vez (evita vender a mesma última unidade duas vezes)
  PERFORM pg_advisory_xact_lock(hashtext('checkout_finalizar'));

  SELECT * INTO v_pedido FROM pedidos WHERE id = p_id AND token = p_token FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'PEDIDO_NAO_ENCONTRADO'; END IF;
  IF status_conta_venda(v_pedido.status) THEN
    RETURN json_build_object('codigo', v_pedido.codigo);   -- clique duplo: devolve o mesmo código
  END IF;
  IF jsonb_typeof(p_itens) <> 'array' OR jsonb_array_length(p_itens) = 0 THEN
    RAISE EXCEPTION 'CARRINHO_VAZIO';
  END IF;

  IF v_pedido.tipo_entrega IS NULL
     OR (v_pedido.tipo_entrega <> 'entrega' AND v_pedido.tipo_entrega NOT LIKE 'retirada%') THEN
    RAISE EXCEPTION 'MODALIDADE_INVALIDA';
  END IF;

  -- Data: precisa estar liberada para a modalidade escolhida
  SELECT * INTO v_data FROM datas_disponiveis WHERE data = v_pedido.data_entrega AND ativo;
  IF NOT FOUND
     OR (v_pedido.tipo_entrega = 'entrega'      AND NOT COALESCE(v_data.permite_entrega,  TRUE))
     OR (v_pedido.tipo_entrega LIKE 'retirada%' AND NOT COALESCE(v_data.permite_retirada, TRUE)) THEN
    RAISE EXCEPTION 'DATA_INDISPONIVEL';
  END IF;

  -- Regra geral: até 17h vale para o dia seguinte; depois, só a partir de 2 dias
  IF (v_pedido.data_entrega < hoje_rio()
       + (CASE WHEN extract(hour FROM now() AT TIME ZONE 'America/Sao_Paulo') < 17 THEN 1 ELSE 2 END)) THEN
    RAISE EXCEPTION 'DATA_INDISPONIVEL';
  END IF;

  -- Antecedência e limite por produto
  FOR r IN
    SELECT p.id, p.nome, p.antecedencia_dias, p.limite_unidades,
           SUM((it->>'quantidade')::INT) AS qtd
    FROM jsonb_array_elements(p_itens) it
    JOIN produtos p ON p.id = NULLIF(it->>'produto_id','')::UUID
    GROUP BY p.id, p.nome, p.antecedencia_dias, p.limite_unidades
  LOOP
    IF r.antecedencia_dias IS NOT NULL
       AND v_pedido.data_entrega < hoje_rio() + r.antecedencia_dias THEN
      RAISE EXCEPTION 'ANTECEDENCIA:%:%', r.nome, r.antecedencia_dias;
    END IF;
    IF r.limite_unidades IS NOT NULL THEN
      IF r.qtd > (SELECT restante FROM estoque_restante() e WHERE e.produto_id = r.id) THEN
        RAISE EXCEPTION 'ESGOTADO:%:%', r.nome,
          (SELECT restante FROM estoque_restante() e WHERE e.produto_id = r.id);
      END IF;
    END IF;
  END LOOP;

  -- Itens
  INSERT INTO pedido_itens (pedido_id, tipo, produto_id, nome, variacao, quantidade,
                            preco_unitario, preco_total, config_caixa)
  SELECT p_id,
         COALESCE(it->>'tipo', 'produto'),
         NULLIF(it->>'produto_id','')::UUID,
         left(it->>'nome', 200),
         it->>'variacao',
         (it->>'quantidade')::INT,
         (it->>'preco_unitario')::NUMERIC,
         (it->>'preco_total')::NUMERIC,
         it->'config_caixa'
  FROM jsonb_array_elements(p_itens) it;

  -- Código: SFN-AAAAMMDD-NNNN
  v_prefixo := COALESCE((SELECT valor FROM configuracoes WHERE chave = 'prefixo_codigo'), 'SF');
  v_dia     := to_char(hoje_rio(), 'YYYYMMDD');
  SELECT COUNT(*) + 1 INTO v_seq FROM pedidos WHERE codigo LIKE v_prefixo || '-' || v_dia || '-%';
  v_codigo  := v_prefixo || '-' || v_dia || '-' || lpad(v_seq::TEXT, 4, '0');

  UPDATE pedidos
  SET status = 'finalizado', codigo = v_codigo, total = p_total, updated_at = now()
  WHERE id = p_id;

  RETURN json_build_object('codigo', v_codigo);
END $$;

REVOKE ALL ON FUNCTION checkout_iniciar(TEXT, TEXT, NUMERIC)        FROM PUBLIC;
REVOKE ALL ON FUNCTION checkout_atualizar(UUID, UUID, JSONB)        FROM PUBLIC;
REVOKE ALL ON FUNCTION checkout_finalizar(UUID, UUID, JSONB, NUMERIC) FROM PUBLIC;
REVOKE ALL ON FUNCTION estoque_restante()                           FROM PUBLIC;
GRANT EXECUTE ON FUNCTION checkout_iniciar(TEXT, TEXT, NUMERIC)        TO anon, authenticated;
GRANT EXECUTE ON FUNCTION checkout_atualizar(UUID, UUID, JSONB)        TO anon, authenticated;
GRANT EXECUTE ON FUNCTION checkout_finalizar(UUID, UUID, JSONB, NUMERIC) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION estoque_restante()                           TO anon, authenticated;
GRANT EXECUTE ON FUNCTION campanha_ativa()                             TO anon, authenticated;


-- ── 4. Cadastro do Natal ───────────────────────────────────

-- Configurações
INSERT INTO configuracoes (chave, valor) VALUES
  ('campanha_ativa',     'natal-2026'),
  ('prefixo_codigo',     'SFN'),
  ('endereco_retirada',  'Rua Arthur Bernardes, 26, loja B — Catete, Rio de Janeiro')
ON CONFLICT (chave) DO UPDATE SET valor = EXCLUDED.valor;

-- Desconto por quantidade (pães de mel avulsos) — mesma tabela dos brindes
DELETE FROM descontos_progressivos;
INSERT INTO descontos_progressivos (qtd_min, qtd_max, preco_unitario) VALUES
  (1,   24,   11.00),
  (25,  49,   10.50),
  (50,  99,   10.00),
  (100, NULL,  9.50);

-- Categorias: "caixas" e "pao-de-mel-avulso" passam para o Natal (os slugs são únicos)
INSERT INTO categorias (nome, slug, ordem, campanha) VALUES
  ('Caixinhas para presente', 'caixas',             1, 'natal-2026'),
  ('Pães de mel avulsos',     'pao-de-mel-avulso',  2, 'natal-2026'),
  ('Bolos',                   'bolos',              3, 'natal-2026'),
  ('Sobremesas de Natal',     'sobremesas-natal',   4, 'natal-2026'),
  ('Do cardápio',             'do-cardapio',        5, 'natal-2026')
ON CONFLICT (slug) DO UPDATE SET nome = EXCLUDED.nome, ordem = EXCLUDED.ordem, campanha = EXCLUDED.campanha;

-- Produtos da Páscoa saem do ar
UPDATE produtos SET ativo = FALSE WHERE campanha = 'pascoa-2026';

-- Produtos do Natal. Os que ainda não têm preço entram INATIVOS (ativo = false):
-- definir o preço e ativar pelo admin.
-- Para evitar duplicar se o script rodar de novo, só insere se o nome não existir no Natal.
INSERT INTO produtos (campanha, categoria_slug, tipo, nome, subtitulo, descricao, preco, preco_min,
                      imagem_url, tag, tag_cor, cor_header, config, antecedencia_dias, limite_unidades,
                      ativo, ordem)
SELECT * FROM (VALUES
  -- Caixinhas (preço = R$ 5 da caixa + R$ 11 por pão de mel)
  ('natal-2026','caixas','caixa','Caixa com 3 pães de mel','Monte do seu jeito',
   'Escolha 3 pães de mel para presentear. Embalagem de Natal inclusa.',
   NULL::NUMERIC, 38.00::NUMERIC, 'img/caixa_3_pdm.jpg', NULL, NULL, 'verde', '{"tamanho":3}'::JSONB, NULL::INT, NULL::INT, TRUE, 1),
  ('natal-2026','caixas','caixa','Caixa com 6 pães de mel','Monte do seu jeito',
   'Escolha 6 pães de mel para um presente inesquecível. Embalagem de Natal inclusa.',
   NULL, 71.00, 'img/caixa_9_pdm.jpg', 'Mais pedida', 'verde', 'verde', '{"tamanho":6}', NULL, NULL, TRUE, 2),
  ('natal-2026','caixas','caixa','Caixa com 9 pães de mel','Monte do seu jeito',
   'Escolha 9 pães de mel. Perfeita para a família toda.',
   NULL, 104.00, 'img/caixa_9_pdm.jpg', NULL, NULL, 'amarelo', '{"tamanho":9}', NULL, NULL, TRUE, 3),
  ('natal-2026','caixas','caixa','Caixa com 15 pães de mel','Monte do seu jeito',
   'A caixa mais completa: 15 pães de mel à sua escolha.',
   NULL, 170.00, 'img/caixa_15_pdm.jpg', NULL, NULL, 'marrom', '{"tamanho":15}', NULL, NULL, TRUE, 4),

  -- Pães de mel avulsos (também são os sabores do montador de caixas)
  ('natal-2026','pao-de-mel-avulso','avulso','Pão de mel doce de leite com nozes','Validade: 12 dias',
   'Pão de mel com cobertura de chocolate, recheio de doce de leite e nozes.',
   11.00, NULL, 'img/ovo_pdm_doce_de_leite_com_nozes.jpg', NULL, NULL, 'amarelo', NULL, NULL, NULL, TRUE, 1),
  ('natal-2026','pao-de-mel-avulso','avulso','Pão de mel caramelo salgado','Validade: 12 dias',
   'Pão de mel com cobertura de chocolate e recheio de caramelo salgado.',
   11.00, NULL, 'img/ovo_pdm_caramelo.jpg', NULL, NULL, 'amarelo', NULL, NULL, NULL, TRUE, 2),
  ('natal-2026','pao-de-mel-avulso','avulso','Pão de mel Cajutella','Validade: 12 dias',
   'Pão de mel com recheio de creme de castanha de caju com chocolate.',
   11.00, NULL, 'img/barra_cajutella.jpg', NULL, NULL, 'amarelo', NULL, NULL, NULL, TRUE, 3),
  ('natal-2026','pao-de-mel-avulso','avulso','Pão de mel damasco','Validade: 12 dias',
   'Pão de mel com cobertura de chocolate e recheio de damasco.',
   11.00, NULL, 'img/ovo_casca-caramelo.jpg', NULL, NULL, 'amarelo', NULL, NULL, NULL, TRUE, 4),
  ('natal-2026','pao-de-mel-avulso','avulso','Pão de mel sem recheio','Validade: 12 dias',
   'O clássico: pão de mel com cobertura de chocolate.',
   11.00, NULL, 'img/ovo_casca-caramelo.jpg', NULL, NULL, 'amarelo', NULL, NULL, NULL, TRUE, 5),
  ('natal-2026','pao-de-mel-avulso','avulso','Pão de mel maracujá','Validade: 7 dias',
   'Pão de mel com cobertura de chocolate e recheio de maracujá.',
   11.00, NULL, 'img/ovo_casca-caramelo.jpg', NULL, NULL, 'amarelo', NULL, NULL, NULL, TRUE, 6),
  ('natal-2026','pao-de-mel-avulso','avulso','Pão de mel laranja','Validade: 7 dias',
   'Pão de mel com cobertura de chocolate e recheio de laranja.',
   11.00, NULL, 'img/ovo_casca-caramelo.jpg', NULL, NULL, 'amarelo', NULL, NULL, NULL, TRUE, 7),

  -- Bolos (P 15 cm / G 25 cm) — PREÇOS A DEFINIR
  ('natal-2026','bolos','simples','Bolo de chocolate','P (15 cm) ou G (25 cm)',
   'Bolo de chocolate Santo Favo.',
   NULL, NULL, 'img/barra.jpg', NULL, NULL, 'marrom',
   '{"variacoes":[{"nome":"P","descricao":"15 cm","preco":0},{"nome":"G","descricao":"25 cm","preco":0}]}', NULL, NULL, FALSE, 1),
  ('natal-2026','bolos','simples','Bolo de pão de mel','P (15 cm) ou G (25 cm)',
   'Bolo de pão de mel Santo Favo.',
   NULL, NULL, 'img/ovo_pdm_caramelo.jpg', NULL, NULL, 'amarelo',
   '{"variacoes":[{"nome":"P","descricao":"15 cm","preco":0},{"nome":"G","descricao":"25 cm","preco":0}]}', NULL, NULL, FALSE, 2),

  -- Sobremesas de Natal: 5 dias de antecedência, 10 unidades de cada no Natal — PREÇOS A DEFINIR
  ('natal-2026','sobremesas-natal','simples','Pão de mel de travessa','Sobremesa de Natal',
   'Pão de mel de travessa para a ceia. Encomende com 5 dias de antecedência.',
   NULL, NULL, 'img/ovo_pdm_doce_de_leite_com_nozes.jpg', 'Edição de Natal', 'rosa', 'rosa', NULL, 5, 10, FALSE, 1),
  ('natal-2026','sobremesas-natal','simples','Pavê rabanada','Sobremesa de Natal',
   'Pavê com sabor de rabanada. Encomende com 5 dias de antecedência.',
   NULL, NULL, 'img/ovo_casca-caramelo.jpg', 'Edição de Natal', 'rosa', 'rosa', NULL, 5, 10, FALSE, 2),
  ('natal-2026','sobremesas-natal','simples','Pavê de cupuaçu com castanha-do-pará','Sobremesa de Natal',
   'Pavê de cupuaçu com castanha-do-pará. Encomende com 5 dias de antecedência.',
   NULL, NULL, 'img/barra_cajutella.jpg', 'Edição de Natal', 'rosa', 'rosa', NULL, 5, 10, FALSE, 3),

  -- Do cardápio — PREÇOS A DEFINIR
  ('natal-2026','do-cardapio','simples','Crocante de pão de mel','Do cardápio',
   'Crocante de pão de mel.', NULL, NULL, 'img/barra.jpg', NULL, NULL, 'amarelo', NULL, NULL, NULL, FALSE, 1),
  ('natal-2026','do-cardapio','simples','Barra de chocolate recheada','Do cardápio',
   'Barra de chocolate recheada.', NULL, NULL, 'img/barra_caramelo.jpg', NULL, NULL, 'marrom', NULL, NULL, NULL, FALSE, 2),
  ('natal-2026','do-cardapio','simples','Barrinhas','Do cardápio',
   'Barrinhas Santo Favo.', NULL, NULL, 'img/barra.jpg', NULL, NULL, 'verde', NULL, NULL, NULL, FALSE, 3)
) AS v(campanha, categoria_slug, tipo, nome, subtitulo, descricao, preco, preco_min, imagem_url, tag,
       tag_cor, cor_header, config, antecedencia_dias, limite_unidades, ativo, ordem)
WHERE NOT EXISTS (SELECT 1 FROM produtos p WHERE p.campanha = v.campanha AND p.nome = v.nome);

-- Datas de dezembro
--   retirada: todos os dias, menos segunda
--   entrega:  terça a sábado
--   24 e 31: até 12h
--   25/12: fechado
INSERT INTO datas_disponiveis (data, ativo, permite_retirada, permite_entrega, horario)
SELECT d::date,
       TRUE,
       TRUE,
       extract(isodow FROM d) BETWEEN 2 AND 6,
       CASE WHEN d::date IN ('2026-12-24','2026-12-31') THEN 'até 12h' END
FROM generate_series('2026-12-01'::date, '2026-12-31'::date, interval '1 day') d
WHERE extract(isodow FROM d) <> 1          -- segunda fechada
  AND d::date <> '2026-12-25'
ON CONFLICT (data) DO UPDATE SET
  ativo = TRUE,
  permite_retirada = EXCLUDED.permite_retirada,
  permite_entrega  = EXCLUDED.permite_entrega,
  horario          = EXCLUDED.horario;

-- FAQs do Natal (as da Páscoa ficam guardadas e saem do ar)
UPDATE faqs SET ativo = FALSE WHERE campanha = 'pascoa-2026';
INSERT INTO faqs (pergunta, resposta, ordem, campanha)
SELECT * FROM (VALUES
  ('Como faço meu pedido?',
   'Escolha seus produtos na loja, monte suas caixinhas, preencha seus dados e envie o pedido pelo WhatsApp. Nossa equipe confirma tudo com você por lá.', 1, 'natal-2026'),
  ('Qual a antecedência para encomendar?',
   'Pães de mel, caixinhas e bolos: até as 17h do dia anterior. Sobremesas de Natal: com 5 dias de antecedência.', 2, 'natal-2026'),
  ('Onde faço a retirada?',
   'Na nossa loja do Catete: Rua Arthur Bernardes, 26, loja B. Retiradas todos os dias, menos às segundas. Nos dias 24 e 31 de dezembro, até as 12h. Dia 25 a loja fica fechada.', 3, 'natal-2026'),
  ('Vocês entregam?',
   'Sim, na cidade do Rio de Janeiro, de terça a sábado (inclusive 24 e 31 de dezembro). O valor do frete depende do bairro e aparece no pedido.', 4, 'natal-2026'),
  ('As sobremesas de Natal são limitadas?',
   'Sim. Fazemos poucas unidades de cada sabor neste Natal. Quando acabar, o produto aparece como esgotado no site.', 5, 'natal-2026'),
  ('Qual a validade dos pães de mel?',
   'Doce de leite com nozes, caramelo salgado, Cajutella, damasco e sem recheio: 12 dias. Maracujá e laranja: 7 dias.', 6, 'natal-2026'),
  ('Como funciona a caixinha para presente?',
   'Você escolhe o tamanho (3, 6, 9 ou 15 pães de mel) e os sabores. O preço é R$ 11 por pão de mel mais R$ 5 da caixa.', 7, 'natal-2026'),
  ('Quais as formas de pagamento?',
   'Pix ou cartão de crédito. O pagamento é combinado com a nossa equipe pelo WhatsApp depois do envio do pedido.', 8, 'natal-2026')
) AS v(pergunta, resposta, ordem, campanha)
WHERE NOT EXISTS (SELECT 1 FROM faqs f WHERE f.campanha = v.campanha AND f.pergunta = v.pergunta);

COMMIT;
