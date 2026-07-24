# KTT Irecê — v1

App completo do circuito: ranking, jogadores, etapas, grupos, chaveamento, mesas,
central de chamadas, placar ao vivo do árbitro e página pública com atualização em tempo real.

Um arquivo só (`index.html`) + Supabase. Sem build, sem npm.

---

## 1. Criar o banco (5 min)

1. Crie um projeto em https://supabase.com (região: São Paulo).
2. **SQL Editor → New query** → cole o conteúdo de `schema.sql` → **Run**.
3. Opcional, só pra ver o app cheio: rode `seed.sql` do mesmo jeito.

## 2. Conectar o app

Em **Project Settings → API**, copie os dois valores e cole no topo do `index.html`:

```js
const SUPABASE_URL  = 'https://xxxxx.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOi...';
```

A chave `anon` é pública de propósito — quem protege a escrita é o RLS do `schema.sql`.

## 3. Criar seu login de organização

1. **Authentication → Users → Add user** → e-mail e senha (marque *Auto Confirm*).
2. Copie o **UID** do usuário criado.
3. SQL Editor:

```sql
insert into admins (user_id, nome, papel)
values ('COLE-O-UID-AQUI', 'Wendell', 'admin');
```

Repita para cada árbitro (use `papel = 'arbitro'`).

## 4. Publicar na Vercel

**Sem instalar nada:** vercel.com → *Add New → Project → Deploy from folder* → arraste esta pasta.

**Pelo terminal:**
```bash
npx vercel --prod
```

Sai no ar em `ktt-irece.vercel.app`. Domínio próprio depois é só apontar em Settings → Domains.

---

## Como usar no dia da etapa

| Passo | Onde |
|---|---|
| Criar a etapa e as mesas | Etapas → **+ Nova etapa** |
| Marcar como etapa do dia | Etapas → **Tornar etapa do dia** |
| Sortear os grupos | Grupos → **Gerar grupos · Cat. X** |
| Montar a eliminatória | Chaveamento → **Gerar chave · Cat. X** (repita a cada fase concluída) |
| Chamar jogadores | Central de chamadas → **Chamar** |
| Marcar o jogo | Árbitro → escolhe a partida → **Iniciar** → **+1 ponto** |
| Fechar a etapa | Etapas → **Encerrar e pontuar** (gera pódio e atualiza o ranking) |

**Atalhos do árbitro no teclado:** `A` ponto do jogador da esquerda · `L` ponto da direita · `Backspace` desfaz.

A página **Ao vivo** (`/#/publico`) é aberta a qualquer pessoa e atualiza sozinha — é o link que você divulga no grupo do WhatsApp.

## O que ficou de fora desta v1

- Patrocinadores (tabela já existe no banco, falta a tela)
- Rankings personalizados por recorte
- Inscrições online pelo próprio atleta
- Upload de foto direto pelo app (hoje é URL da imagem)
