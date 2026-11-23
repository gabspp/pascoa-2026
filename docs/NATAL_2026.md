# Santo Favo | Site de Natal 2026 — Especificação

Documento de referência para o Claude Code. O site de Natal é construído **dentro do repositório `pascoa-2026`**: reaproveita a loja, o montador de caixas, o carrinho, o checkout em etapas, o envio pelo WhatsApp e o admin. Este arquivo descreve só o que é novo ou diferente.

Status: rascunho de 23/11/2026. Preços e textos finais das sobremesas, fotos e artes ainda serão enviados. Até lá, usar dados de exemplo (seed) e imagens provisórias.

---

## 0. Como o site da Páscoa é feito (base real)

- **HTML estático**, sem framework: `index.html`, `loja.html` (loja, carrinho, montador e checkout), `informacoes.html`, `privacidade.html` e `admin.html`.
- Tailwind por CDN, fontes Pipo e Fig Grotesk em `fonts/`, logos em `brand_assets/`, fotos em `img/`.
- `supabase-js` direto no navegador, com a chave pública. Scripts de manutenção em `execution/` (rodam com a chave de serviço do `.env`, que não está no repositório).
- Deploy na Vercel. **Este projeto é o dono do domínio santofavo.com.br.** Hoje o `vercel.json` redireciona `/`, `/loja`, `/informacoes` e `/admin` para `/brindes-2026`, faz rewrite de `/brindes-2026` (e `/_next/*`) para o projeto `brindes-cooporativos` e serve a página de vale-presente `/beatrizcypriano`.
- Regras que já existem e continuam: desconto por quantidade só nos avulsos (`getPrecoAvulso`), especial do mês fora do desconto, carrinho no `localStorage`, pedido salvo a cada etapa, pedido até 17h vale para o dia seguinte (depois das 17h, só a partir de 2 dias), código `SF-AAAAMMDD-NNNN`.

**Decisão:** construir o Natal neste mesmo repositório e no mesmo projeto da Vercel, sem trocar de stack. Antes de mexer, marcar a versão da Páscoa com a tag `pascoa-2026-final` para ela continuar recuperável.

## 1. Endereço e prazo

- O Natal fica na **página principal de santofavo.com.br**. No lançamento, tirar do `vercel.json` os redirecionamentos de `/`, `/loja`, `/informacoes` e `/admin`.
- Manter os rewrites de `/brindes-2026` e `/_next/*` e a página `/beatrizcypriano`.
- Meta: **site no ar até 01/12**.
- WhatsApp: +55 21 96764-3537.

## 2. Estrutura de páginas

| Rota | Conteúdo |
|---|---|
| `/` | Hero de Natal, atalhos por categoria, banner das Sobremesas de Natal, "Como comprar", link discreto "Para empresas" → `/brindes-2026` |
| `/loja` | Grid com filtro por categoria (igual à Páscoa) |
| `/sobremesas-de-natal` | Página dedicada às 3 travessas: foto grande, descrição, porções, prazo de 5 dias, aviso de quantidade limitada, botão de adicionar. **Mesmo carrinho e mesmo checkout do resto do site.** |
| `/informacoes` | FAQ (tabela `faqs`) |
| `/privacidade` | Igual à Páscoa |
| `/admin` | Igual à Páscoa + ajustes da seção 6 |

### Categorias

1. **Caixinhas para presente**: caixas de 3, 6, 9 e 15 pães de mel (montador da Páscoa)
2. **Pães de mel avulsos**
3. **Bolos**
4. **Sobremesas de Natal**
5. **Do cardápio**: barrinhas, crocante de pão de mel, barra de chocolate recheada (a confirmar quais entram)

## 3. Produtos e preços

### Pão de mel (mesma tabela da página de brindes)

Desconto por quantidade aplicado **só aos pães avulsos** (os das caixas não contam):

| Pães avulsos no carrinho | Preço por unidade |
|---|---|
| 1 a 24 | R$ 11,00 |
| 25 a 49 | R$ 10,50 |
| 50 a 99 | R$ 10,00 |
| 100 ou mais | R$ 9,50 |

**Caixas:** R$ 5,00 de embalagem + R$ 11,00 por pão de mel (caixa 3 = R$ 38; 6 = R$ 71; 9 = R$ 104; 15 = R$ 170).

**Sabores** (validade diferente, exibir aviso no montador e no checkout):
- 12 dias: doce de leite com nozes, caramelo salgado, Cajutella, damasco, sem recheio
- 7 dias: maracujá, laranja

### Bolos

Dois sabores, dois tamanhos cada:

| Bolo | P (15 cm) | G (25 cm) |
|---|---|---|
| Chocolate | a definir | a definir |
| Pão de mel | a definir | a definir |

### Sobremesas de Natal (doces de travessa)

- Pão de mel de travessa
- Pavê rabanada
- Pavê de cupuaçu com castanha-do-pará

Regras:
- **Um tamanho só** (preço, porções e peso a definir).
- **Antecedência mínima de 5 dias**.
- **Limite de 10 unidades de cada sabor** (ver pergunta em aberto 2).
- Podem ser **retiradas ou entregues**.
- Produto refrigerado: mostrar aviso de conservação na página e no checkout.

## 4. Datas, retirada e entrega

- **Retirada:** todos os dias, **exceto segunda-feira**, na **Rua Arthur Bernardes, 26, loja B**.
- **24/12 e 31/12:** retiradas **até 12h**. Mostrar o horário no calendário e na mensagem do WhatsApp.
- **25/12 (sexta) e 01/01 (sexta):** deixar **bloqueados** por padrão (ajustável no admin).
- **Entrega:** só na cidade do Rio de Janeiro, com frete por bairro como na Páscoa.
- Calendário do checkout: mostra só as datas liberadas no admin, já descontando a antecedência (ver seção 5).

## 5. Novas regras de lógica (o que muda em relação à Páscoa)

### 5.1 Variações de produto

Bolos têm tamanho P e G. Sem tabela nova: usar o campo `config` (JSONB) que já existe em `produtos`, por exemplo `{"variacoes": [{"nome": "P", "descricao": "15 cm", "preco": 0}, {"nome": "G", "descricao": "25 cm", "preco": 0}]}`. No card e na janela do produto, o cliente escolhe o tamanho antes de adicionar. O item do carrinho e o `pedido_itens.nome` levam o tamanho ("Bolo de Chocolate G (25 cm)").

### 5.2 Antecedência por produto

Adicionar `antecedencia_dias` em `produtos` (null = regra atual das 17h; sobremesas = 5).
- A data mínima do pedido é **a maior entre a regra das 17h e hoje + o maior `antecedencia_dias` dos itens do carrinho**.
- Se o cliente já escolheu uma data e depois adiciona uma sobremesa que não cabe nela, avisar e pedir outra data.
- No card das sobremesas: "Encomende com 5 dias de antecedência".

### 5.3 Limite de unidades

Adicionar `limite_unidades` em `produtos` (null = sem limite).
- Antes de mostrar o produto, calcular quantas unidades já foram pedidas (pedidos com status `finalizado` em diante e não `cancelado`).
- Mostrar "Últimas X unidades" quando restarem 3 ou menos, e "Esgotado" quando zerar.
- Conferir de novo no servidor na hora de finalizar o pedido (dois clientes ao mesmo tempo).

### 5.4 Coluna `campanha`

O Supabase não aceita projetos novos. Em vez de tabelas novas para o Natal, adicionar `campanha` (texto: `pascoa-2026`, `natal-2026`) em `categorias`, `produtos`, `pedidos` e `faqs`, e uma linha `campanha_ativa` em `configuracoes`. O site e o admin leem só a campanha ativa. Os registros da Páscoa recebem `pascoa-2026`. Assim a próxima data comemorativa é só cadastro.

### 5.6 Horário especial por data

Adicionar `horario` (texto, opcional) em `datas_disponiveis`, por exemplo "retirada até 12h" em 24 e 31/12. O calendário do checkout e a mensagem do WhatsApp mostram esse texto.

### 5.7 Segurança dos pedidos (corrigir antes do lançamento)

No `schema.sql` da Páscoa, os pedidos ficaram abertos para o público: `public_select_pedidos` e `public_update_pedidos` usam `USING (true)`. Com a chave pública, que fica visível no site, qualquer pessoa consegue listar os endereços e observações de todos os pedidos e alterá-los.

Correção:
- Remover as políticas públicas de SELECT e UPDATE de `pedidos` e a de SELECT de `pedido_itens`. O admin continua funcionando, porque usa as políticas `authenticated`.
- Criar funções no Supabase (`security definer`) para o site: `criar_pedido` (devolve o id e um token aleatório), `atualizar_pedido(id, token, …)` e `finalizar_pedido(id, token, itens)`. Esta última gera o código SFN, confere o limite de unidades e grava os itens.
- Antes de remover as políticas, conferir se o site de brindes usa as mesmas tabelas.

### 5.5 Código e mensagem do pedido

- Código: `SFN-AAAAMMDD-NNNN` (N de Natal), para não misturar com os pedidos da Páscoa.
- Mensagem do WhatsApp com tema de Natal (🎄), incluindo variação dos bolos, horário de retirada quando for 24 ou 31/12 e o endereço da loja.

## 6. Ajustes no admin

- Campo de variações no cadastro de produto.
- Campos de antecedência e limite de unidades.
- Coluna "vendidos / limite" na lista de produtos.
- Filtro de campanha na lista de pedidos.
- Calendário com horário especial por data (24 e 31/12 até 12h).

## 7. Visual

- Identidade do design system Santo Favo (Pipo, Fig Grotesk, seis cores oficiais, favos, sem sombra nos elementos de conteúdo), com toques de Natal.
- Artes e fotos ainda não chegaram: usar imagens provisórias com proporção fixa, para a troca ser só substituir arquivos.

## 8. Opcional: integração com o sistema de encomendas interno

O sistema `encomendas-santofavo` grava os pedidos num banco do Notion com uma coluna por produto (já existem `Bolo Choco P/G`, `Bolo PDM P/G`, `Caixa 3/6/9/15` e sabores de PDM). Depois que o atendente confirmar no WhatsApp, um botão no admin poderia enviar o pedido para o Notion, evitando redigitação. Faltariam as colunas das três sobremesas. Fica para depois, se der tempo.

## 9. Ordem de desenvolvimento

1. Tag `pascoa-2026-final` e branch `natal-2026` neste repositório
2. Banco (`execution/natal_2026.sql`): `campanha`, `antecedencia_dias`, `limite_unidades`, `horario`, as funções seguras da seção 5.7 e o seed de Natal (categorias, produtos, descontos de R$ 11 a R$ 9,50, datas)
3. Lógica em `loja.html`: variações, antecedência no calendário, limite de unidades, código SFN
4. Página `sobremesas-de-natal.html` e categorias novas
5. Calendário: segundas fechadas, 24 e 31/12 até 12h, 25/12 e 01/01 bloqueados
6. Mensagem do WhatsApp com tema de Natal e endereço da loja
7. Admin: campos novos e filtro de campanha
8. Tema de Natal em `index.html`, `loja.html` e `informacoes.html`, com imagens provisórias
9. Preview na Vercel, depois lançamento: tirar os redirecionamentos do `vercel.json`
10. Trocar fotos, artes e preços finais

## 10. Decisões fechadas (23/11)

- Limite das sobremesas: **10 de cada sabor no Natal inteiro** (não por dia).
- Entregas: **terça a sábado**, inclusive 24 e 31/12.
- **25/12 e 01/01 fechados.**
- Bolos: mesma regra dos pães de mel (**até 17h do dia anterior**).

## 11. Status (branch `natal-2026`)

Feito:
- `execution/natal_2026.sql`: migração testada num Postgres local (segurança, limites, antecedência, datas, cadastro do Natal).
- `loja.html`: tamanhos, estoque, antecedência, datas por modalidade, checkout seguro, mensagem do WhatsApp com código SFN.
- `admin.html`: campanha ativa, entrega/retirada e horário por data, preços P/G, vendidos/limite, bloqueio de ativar produto sem preço.

Falta:
1. Rodar `execution/natal_2026.sql` no Supabase (depois de confirmar que o site de brindes não usa as tabelas `pedidos`, `pedido_itens` e `clientes`).
2. Preços de bolos, sobremesas e itens do cardápio; definir pelo admin e ativar.
3. Visual de Natal: `index.html` (ainda é a home da Páscoa), página `sobremesas-de-natal.html`, fotos e artes.
4. Ícone do carrinho (ainda usa os ovinhos de Páscoa).
5. Lançamento: juntar o branch no `main` e tirar os redirecionamentos de `/`, `/loja`, `/informacoes` e `/admin` do `vercel.json`.
