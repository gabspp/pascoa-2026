# Prompt de Desenvolvimento — Santo Favo | Campanha de Páscoa 2026

## Visão Geral do Projeto

Construa um site responsivo (mobile-first) para a campanha de Páscoa 2026 da confeitaria **Santo Favo**. O site funciona como catálogo e ponto de venda, com checkout que finaliza via mensagem no WhatsApp (sem processamento de pagamento online). O pedido é sempre concluído por um atendente humano.

**Dados da empresa:**
- Nome: Santo Favo
- WhatsApp: +55 21 96764-3537
- Email: santofavo@gmail.com
- Instagram: @santofavo (incluir link no site)

**Páscoa 2026:** 5 de abril

---

## Stack Técnica

| Camada         | Tecnologia                                                      |
| -------------- | --------------------------------------------------------------- |
| Framework      | Next.js (App Router)                                            |
| Estilização    | Tailwind CSS                                                    |
| Backend / Auth | Supabase (PostgreSQL, Row Level Security)                       |
| Hospedagem     | Vercel                                                          |
| API de CEP     | ViaCEP (https://viacep.com.br) — gratuita, sem chave            |
| WhatsApp       | Redirecionamento via URL `https://wa.me/5521967643537?text=...` |
| Imagens        | Otimização com next/image (WebP, lazy loading, srcset)          |

---

## Design e Identidade Visual

- Siga as referências visuais da pasta `@design-refs`
- Use as fontes da pasta `@fonts`
- Use as imagens e logos da pasta `@imgs`
- **Tom visual:** Moderno, alegre, colorido com elegância. Não escandaloso. Paleta vibrante mas equilibrada
- **Elementos obrigatórios:** Logo da Santo Favo, cores da marca, ícones temáticos de Páscoa
- **Tipografia:** Usar as fontes fornecidas como primárias; fallback para system fonts
- **Responsividade:** Mobile-first. Testar em viewports 375px, 768px e 1440px

---

## Estrutura de Páginas

### Página 1 — HOME (`/`)

**Header (presente em todas as páginas):**
- Logo da Santo Favo
- Menu hambúrguer (mobile) / navegação horizontal (desktop)
- Botão CTA destacado: "Faça seu Pedido" → leva para `/loja`

**Seção Hero / Carrossel:**
- Carrossel de imagens chamativas dos produtos (autoplay suave + swipe mobile + controles)
- Cada slide pode ter texto sobreposto com título e CTA

**Seção Catálogo Resumido:**
- Título da seção (ex: "Nossos Produtos de Páscoa")
- Barra horizontal com botões coloridos de categorias (scroll horizontal no mobile)
- Ao clicar na categoria, os cards filtram com transição suave
- Cards de produto com: foto, título, descrição curta, preço, tags opcionais ("Clássico", "Novidade", "Campeão de Vendas", "Especial do Mês", etc.)
- Botão "Ver todos" → leva para `/loja`

**Seção "Como Comprar":**
- 3 cards com ícones ilustrativos:
  1. "Escolha seus produtos"
  2. "Finalize seu pedido"
  3. "Receba ou retire suas delícias"
- Botão "Saiba mais" → leva para `/informacoes`

**Footer (presente em todas as páginas):**
- Logo
- Links de navegação
- Link para Instagram
- WhatsApp de contato
- Aviso LGPD / link para política de privacidade
- Créditos: "Feito com ♥ pela Santo Favo"

---

### Página 2 — LOJA (`/loja`) ⭐ Página Principal

**Layout estilo e-commerce:**
- Barra de categorias (fixa no topo ao scrollar, com scroll horizontal no mobile)
- Grid de produtos filtráveis por categoria
- Cada card de produto exibe: foto, título, preço (ou faixa de preço para caixas), tag (se houver), botão "Adicionar"

**Card expandido (Modal ou Drawer):**
- Ao clicar no card, abre um modal/drawer com:
  - Foto(s) ampliada(s) do produto
  - Título, descrição completa, preço
  - Para produtos simples: seletor de quantidade + botão "Adicionar à Cesta"
  - Para Caixas de Pão de Mel: interface de montagem (ver seção Lógica de Caixas)

**Carrinho / Cesta:**
- Ícone flutuante no canto inferior (ou superior) com badge de quantidade
- Ao clicar, abre painel lateral ou modal com:
  - Lista de itens com foto miniatura, nome, quantidade (editável), preço unitário, subtotal
  - Para caixas: mostrar configuração dos sabores escolhidos
  - Botão remover item
  - Subtotal
  - Botão "Continuar comprando" e "Finalizar Pedido"
- **Persistência:** Salvar carrinho em `localStorage` para manter entre sessões

**Fluxo de Checkout (etapas dentro de um modal/página):**

O checkout deve ser um fluxo em etapas (stepper visual) com as seguintes telas:

**Etapa 1 — Revisão do Pedido:**
- Lista completa dos itens (editável: alterar quantidade, remover)
- Subtotal dos produtos
- Botão "Continuar"

**Etapa 2 — Seus Dados (Cadastro Rápido):**
- Nome completo (obrigatório)
- Número de WhatsApp (obrigatório, com máscara de telefone BR)
- Checkbox de consentimento LGPD: "Autorizo o uso dos meus dados para contato referente a este pedido"
- **Neste momento, salvar os dados no Supabase** com status `checkout_iniciado` (para rastreamento de abandono)
- Botão "Continuar"

**Etapa 3 — Entrega ou Retirada:**
- Opção 1: **Retirar no local** (exibir endereço da confeitaria)
- Opção 2: **Entrega** (somente Rio de Janeiro — Capital)
  - Se entrega: campo de CEP com consulta automática via ViaCEP
  - Preencher endereço automaticamente
  - Cruzar bairro retornado pela ViaCEP com a tabela de frete do Supabase
  - Se bairro encontrado: exibir valor do frete
  - Se bairro NÃO encontrado: exibir mensagem "O valor do frete para sua região será informado pelo nosso atendente" e permitir continuar normalmente
  - Campos: CEP, Endereço, Número, Complemento, Bairro
  - Aviso sutil: "Entregas disponíveis apenas para Rio de Janeiro — Capital"
- Atualizar status no Supabase: `endereco_preenchido`
- Botão "Continuar"

**Etapa 4 — Data de Entrega/Retirada:**
- Calendário ou seletor de datas mostrando **apenas dias disponíveis** (configurados pelo admin)
- **Regra: pedido deve ser feito com no mínimo 24h de antecedência.** Ou seja, o dia de hoje nunca está disponível, mesmo que esteja marcado como disponível no admin
- Se não houver datas disponíveis, exibir mensagem amigável
- Atualizar status no Supabase: `data_selecionada`
- Botão "Continuar"

**Etapa 5 — Observações e Pagamento:**
- Campo de observação (textarea, opcional)
- Forma de pagamento: PIX ou Cartão de Crédito (apenas seleção, sem integração de pagamento)
- Atualizar status no Supabase: `pagamento_selecionado`
- Botão "Finalizar Pedido"

**Etapa 6 — Confirmação e Envio ao WhatsApp:**
- Resumo visual completo do pedido
- Ao clicar em "Enviar Pedido pelo WhatsApp":
  1. Salvar pedido completo no Supabase com status `finalizado` e gerar um código de pedido (ex: `SF-20260401-0042`)
  2. Redirecionar para WhatsApp com mensagem pré-formatada:

```
🐰 *Pedido de Páscoa — Santo Favo*
📋 Código: SF-XXXXXXXX-XXXX

👤 *Nome:* [nome]
📱 *WhatsApp:* [telefone]

📦 *Modalidade:* Retirada / Entrega
📍 *Endereço:* [endereço completo] (se entrega)
📅 *Data:* [data escolhida]

🛒 *Pedido:*
• 2x Ovo de Colher Brigadeiro — R$ XX,XX
• 1x Caixa com 6 Pães de Mel (Doce de leite, Caramelo...) — R$ XX,XX
[...]

📝 *Obs:* [observação]

💰 *Subtotal:* R$ XX,XX
🚚 *Frete:* R$ XX,XX (ou "A confirmar")
💳 *Pagamento:* PIX / Crédito

*Total: R$ XXX,XX*
```

- **IMPORTANTE:** Se a URL do `wa.me` ficar muito longa (>4096 caracteres), truncar o pedido e adicionar: "📎 Pedido completo disponível no sistema — Código: SF-XXXX". O atendente consulta o painel admin.

---

### Página 3 — INFORMAÇÕES (`/informacoes`)

- Imagem de topo com título: "Tudo o que você precisa saber"
- Cards expansíveis (accordion) com perguntas e respostas (conteúdo será fornecido depois — deixar estrutura pronta puxando de uma tabela `faqs` no Supabase)
- Botão CTA no final: "Monte seu Pedido" → leva para `/loja`

---

## Lógica de Negócio

### 1. Pães de Mel Avulsos — Desconto Progressivo

Aplica-se ao total de pães de mel avulsos (fora das caixas). O "Especial do Mês" **não** conta para o desconto.

| Quantidade total de pães avulsos | Preço unitário |
|----------------------------------|---------------|
| 1 a 24 | R$ 10,00 |
| 25 a 49 | R$ 9,50 |
| 50 a 99 | R$ 9,00 |
| 100+ | R$ 8,50 |

- O desconto deve ser recalculado em tempo real conforme o cliente adiciona/remove pães
- Exibir badge ou tooltip explicando o desconto quando aplicável (ex: "Você ganhou desconto por quantidade! 🎉")
- O "Especial do Mês" é identificado por uma flag `is_especial_mes` no banco e tem preço fixo (R$ 12,00), sem participar do desconto progressivo

### 2. Caixas para Presentear (Configurador de Produto)

As caixas são embalagens para pães de mel. Tamanhos: 3, 6, 9 e 15 unidades.

**Preço da caixa:** R$ 5,00 (embalagem) + soma dos pães de mel selecionados

**Fluxo UX para montagem de caixa:**
1. Cliente escolhe o tamanho da caixa (3, 6, 9 ou 15)
2. Abre interface de seleção de sabores:
   - Lista de sabores disponíveis de pão de mel (com foto e preço: R$ 10 ou R$ 12)
   - Para cada sabor, seletor de quantidade (+/-)
   - Contador visual: "X de Y pães selecionados" com barra de progresso
   - Não permitir adicionar mais pães do que a caixa comporta
   - Não permitir finalizar a caixa com menos pães do que o tamanho exige
3. Ao completar, botão "Adicionar Caixa à Cesta"
4. No carrinho, a caixa aparece como item único com a composição detalhada:
   - "Caixa com 6 Pães de Mel — R$ 71,00"
   - Subtitulo: "2x Doce de Leite, 2x Caramelo, 2x Sem Recheio"

**Regras:**
- Pães dentro das caixas **NÃO** contam para o desconto progressivo dos avulsos
- O cliente pode ter múltiplas caixas com configurações diferentes
- Pode aumentar a quantidade de uma caixa já montada (duplica a mesma configuração)
- Pode editar a configuração de uma caixa no carrinho

### 3. Frete

- Tabela de frete por bairro armazenada no Supabase (tabela `frete_bairros`)
- Estrutura: `bairro` (texto normalizado, lowercase, sem acentos) | `valor` (decimal)
- A tabela será importada via CSV posteriormente (~20 bairros)
- Fluxo:
  1. Cliente digita CEP
  2. Consulta ViaCEP → retorna bairro
  3. Normalizar bairro (lowercase, sem acentos) e buscar na tabela `frete_bairros`
  4. Se encontrado → exibir valor
  5. Se NÃO encontrado → "O frete para sua região será informado pelo atendente" (não impede a compra)
- No resumo do pedido: exibir "Frete: R$ X,XX" ou "Frete: A confirmar"
- Na mensagem do WhatsApp: incluir "Frete: A confirmar" quando não calculado

---

## Esquema de Banco de Dados (Supabase)

### Tabela `categorias`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid (PK) | |
| nome | text | Nome da categoria |
| slug | text (unique) | URL-friendly |
| ordem | integer | Ordem de exibição |
| ativo | boolean | Visível no site |
| created_at | timestamptz | |

### Tabela `produtos`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid (PK) | |
| categoria_id | uuid (FK → categorias) | |
| nome | text | |
| slug | text (unique) | |
| descricao | text | Descrição curta (card) |
| descricao_completa | text | Descrição longa (modal) |
| preco | decimal | Preço base |
| preco_especial | decimal | Preço alternativo (ex: R$12 para especiais) |
| imagens | text[] | Array de URLs das imagens |
| tags | text[] | Ex: ["Clássico", "Novidade", "Campeão de Vendas"] |
| is_especial_mes | boolean | Se é o Especial do Mês (excluído do desconto progressivo) |
| is_caixa | boolean | Se é uma caixa para presentear |
| tamanho_caixa | integer | Null se não é caixa; 3, 6, 9 ou 15 se é caixa |
| disponivel | boolean | Disponível para compra |
| ordem | integer | Ordem de exibição |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### Tabela `descontos_progressivos`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid (PK) | |
| quantidade_min | integer | Quantidade mínima |
| quantidade_max | integer | Quantidade máxima (null = sem limite) |
| preco_unitario | decimal | Preço por unidade nessa faixa |
| ativo | boolean | |

### Tabela `frete_bairros`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid (PK) | |
| bairro | text | Nome normalizado (lowercase, sem acentos) |
| bairro_display | text | Nome original para exibição |
| valor | decimal | Valor do frete |
| ativo | boolean | |

### Tabela `datas_disponiveis`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid (PK) | |
| data | date (unique) | Data disponível para entrega/retirada |
| tipo | text | "entrega", "retirada" ou "ambos" |
| limite_pedidos | integer | Máximo de pedidos para essa data (null = sem limite) |
| pedidos_count | integer | Contador de pedidos já feitos |
| ativo | boolean | |

### Tabela `clientes`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid (PK) | |
| nome | text | |
| whatsapp | text | Número com DDI |
| consentimento_lgpd | boolean | |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### Tabela `pedidos`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid (PK) | |
| codigo | text (unique) | Ex: "SF-20260401-0042" |
| cliente_id | uuid (FK → clientes) | |
| status | text | Enum: `carrinho`, `checkout_iniciado`, `endereco_preenchido`, `data_selecionada`, `pagamento_selecionado`, `finalizado`, `enviado_whatsapp`, `atendimento`, `concluido`, `cancelado` |
| modalidade | text | "retirada" ou "entrega" |
| endereco | jsonb | {cep, logradouro, numero, complemento, bairro, cidade, estado} |
| data_entrega | date | |
| observacao | text | |
| forma_pagamento | text | "pix" ou "credito" |
| subtotal | decimal | |
| frete | decimal | Null se não calculado |
| frete_a_confirmar | boolean | |
| total | decimal | |
| mensagem_whatsapp | text | Mensagem formatada enviada |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### Tabela `pedido_itens`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid (PK) | |
| pedido_id | uuid (FK → pedidos) | |
| produto_id | uuid (FK → produtos) | |
| quantidade | integer | |
| preco_unitario | decimal | Preço no momento da compra |
| preco_total | decimal | |
| configuracao_caixa | jsonb | Se for caixa: [{sabor_id, sabor_nome, quantidade, preco_unitario}] |
| created_at | timestamptz | |

### Tabela `faqs`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | uuid (PK) | |
| pergunta | text | |
| resposta | text | |
| ordem | integer | |
| ativo | boolean | |

### Tabela `configuracoes`
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| chave | text (PK) | Ex: "preco_caixa", "whatsapp_numero", "limite_pedidos_dia" |
| valor | jsonb | |
| updated_at | timestamptz | |

---

## Painel Administrativo (`/admin`)

Acesso protegido por autenticação Supabase (email + senha, único usuário).

**Dashboard:**
- Pedidos recentes (últimos 30 dias)
- Pedidos por status (cards com contadores)
- Carrinhos abandonados (clientes que pararam no meio do checkout)

**Gestão de Produtos:**
- Listar, editar, ativar/desativar produtos
- Alterar preço, descrição, imagens, tags
- Marcar/desmarcar "Especial do Mês"
- Reordenar produtos e categorias

**Gestão de Datas:**
- Calendário visual para marcar/desmarcar dias disponíveis
- Definir se é entrega, retirada ou ambos
- Opcional: limite de pedidos por data
- Visão rápida de quantos pedidos já existem por data

**Gestão de Frete:**
- Tabela editável de bairros e valores
- Importação via CSV
- Adicionar/remover/editar bairros

**Gestão de FAQs:**
- CRUD simples de perguntas e respostas
- Reordenar

**Pedidos:**
- Lista de todos os pedidos com filtro por status, data, busca por nome/código
- Detalhe do pedido com todas as informações
- Possibilidade de alterar status (para controle interno)

**Clientes:**
- Lista de clientes cadastrados
- Indicação de quem abandonou carrinho (para follow-up via WhatsApp)

---

## Segurança e Conformidade

### LGPD
- Banner de consentimento na primeira visita: "Usamos seus dados apenas para processar pedidos. Ao continuar, você concorda com nossa política de privacidade."
- Checkbox obrigatório no cadastro
- Página `/privacidade` com política de privacidade simples
- Dados dos clientes protegidos com Row Level Security no Supabase

### Supabase RLS
- Tabelas públicas (leitura): `categorias`, `produtos`, `datas_disponiveis`, `faqs`, `configuracoes`, `descontos_progressivos`
- Tabelas protegidas (escrita via API autenticada ou server-side): `clientes`, `pedidos`, `pedido_itens`
- Tabelas admin-only: `frete_bairros` (leitura permitida para consulta de frete, escrita só admin)
- Usar Server Actions do Next.js para operações sensíveis (criar cliente, criar pedido) — nunca expor service_role key no client

### Variáveis de Ambiente
```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
NEXT_PUBLIC_WHATSAPP_NUMBER=5521967643537
```

---

## Performance e SEO

- **Imagens:** Usar `next/image` com formato WebP, lazy loading, placeholder blur
- **SSG/ISR:** Páginas de produto e FAQ com Incremental Static Regeneration
- **Meta tags:** Open Graph, Twitter Cards com imagens dos produtos
- **Schema markup:** LocalBusiness + Product para SEO
- **Lighthouse:** Buscar score > 90 em Performance, Accessibility, SEO
- **Core Web Vitals:** Priorizar LCP < 2.5s, CLS < 0.1

---

## Integrações

### Instagram
- Link para perfil no header e footer
- Opcional: seção na home com feed recente via embed (sem API complexa — usar embed do Instagram ou imagens estáticas linkadas)

### WhatsApp
- Botão flutuante de WhatsApp em todas as páginas (para dúvidas gerais)
- Envio do pedido via URL `wa.me` com mensagem formatada

---

## Dados Pendentes (a fornecer depois)

O site deve funcionar com dados de exemplo (seed) até que os reais sejam fornecidos:

1. **Tabela completa de produtos** (nome, preço, descrição, categoria, imagens)
2. **Tabela de frete por bairro** (~20 bairros, CSV)
3. **Conteúdo das FAQs**
4. **Textos finais** (headline da home, descrições, etc.)
5. **Fotos profissionais dos produtos**

Criar seeds realistas para desenvolvimento, com produtos fictícios mas que reflitam as categorias reais: Ovos de Colher, Barras de Chocolate, Pães de Mel (avulsos), Caixas para Presentear, Especial do Mês, etc.

---

## Ordem de Desenvolvimento Sugerida

1. **Setup:** Next.js + Supabase + Tailwind + deploy na Vercel
2. **Banco de dados:** Criar tabelas, RLS, seeds
3. **Layout base:** Header, Footer, navegação, responsividade
4. **Home:** Carrossel, catálogo resumido, seção como comprar
5. **Loja:** Grid de produtos, filtro por categoria, card expandido
6. **Carrinho:** Adicionar/remover itens, persistência localStorage
7. **Configurador de Caixas:** Interface de montagem de caixas
8. **Desconto progressivo:** Lógica de cálculo em tempo real
9. **Checkout completo:** Todas as etapas, integração CEP, salvamento no Supabase
10. **Envio WhatsApp:** Montagem da mensagem, redirecionamento
11. **Informações:** Página de FAQ com accordion
12. **Admin:** Autenticação, dashboard, CRUD de produtos/datas/frete/FAQs
13. **LGPD:** Banner, checkbox, página de privacidade
14. **SEO e Performance:** Meta tags, schema, otimização de imagens
15. **Testes e refinamento:** Fluxo completo mobile, edge cases, polish visual
