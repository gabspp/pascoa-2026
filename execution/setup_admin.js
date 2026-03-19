/**
 * setup_admin.js — Cria o usuário admin no Supabase Auth e imprime as
 * políticas RLS para você colar no SQL Editor do Supabase.
 *
 * Uso: node execution/setup_admin.js EMAIL SENHA
 * Ex:  node execution/setup_admin.js admin@santofavo.com MinhaSenh@123
 */
const { createClient } = require('@supabase/supabase-js');
const { config }       = require('dotenv');
const path             = require('path');

config({ path: path.resolve(__dirname, '../.env') });

const email = process.argv[2];
const senha  = process.argv[3];

if (!email || !senha) {
  console.error('\nUso: node execution/setup_admin.js EMAIL SENHA\n');
  process.exit(1);
}

const sb = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } }
);

const SQL = `
-- Políticas RLS para o painel admin (usuários autenticados)
CREATE POLICY "admin_select_pedidos"  ON pedidos           FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin_update_pedidos"  ON pedidos           FOR UPDATE TO authenticated USING (true);
CREATE POLICY "admin_select_clientes" ON clientes          FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin_select_itens"    ON pedido_itens      FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin_update_produtos" ON produtos          FOR UPDATE TO authenticated USING (true);
CREATE POLICY "admin_select_datas"    ON datas_disponiveis FOR SELECT TO authenticated USING (true);
CREATE POLICY "admin_update_datas"    ON datas_disponiveis FOR UPDATE TO authenticated USING (true);
CREATE POLICY "admin_insert_datas"    ON datas_disponiveis FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "admin_delete_datas"    ON datas_disponiveis FOR DELETE TO authenticated USING (true);
`.trim();

async function main() {
  console.log('\n🔐 Criando usuário admin...\n');

  const { data, error } = await sb.auth.admin.createUser({
    email,
    password: senha,
    email_confirm: true,
  });

  if (error) {
    if (error.message.toLowerCase().includes('already')) {
      console.log(`ℹ️  Usuário ${email} já existe.\n`);
    } else {
      console.error('❌ Erro:', error.message);
      process.exit(1);
    }
  } else {
    console.log(`✅ Usuário criado com sucesso!`);
    console.log(`   ID: ${data.user.id}`);
    console.log(`   Email: ${email}\n`);
  }

  console.log('─'.repeat(60));
  console.log('📋 PRÓXIMO PASSO — cole este SQL no Supabase SQL Editor:');
  console.log('   (Dashboard → SQL Editor → New query → Run)\n');
  console.log(SQL);
  console.log('\n' + '─'.repeat(60));
  console.log('\n✅ Depois disso, acesse /admin.html e faça login!\n');
}

main();
