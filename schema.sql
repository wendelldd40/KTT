-- ============================================================
-- KTT IRECÊ — Schema Supabase v1
-- Rode inteiro no SQL Editor do Supabase.
-- ============================================================

create extension if not exists "pgcrypto";

-- ---------- ADMINS ----------
create table if not exists admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  nome text,
  papel text not null default 'arbitro' check (papel in ('admin','arbitro')),
  criado_em timestamptz default now()
);

create or replace function is_admin() returns boolean
language sql stable security definer set search_path = public as $fn$
  select exists (select 1 from admins where user_id = auth.uid());
$fn$;

-- ---------- JOGADORES ----------
create table if not exists jogadores (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  apelido text,
  cidade text,
  estado text default 'BA',
  clube text,
  categoria text not null default 'C' check (categoria in ('A','B','C','D')),
  pontos int not null default 0,
  vitorias int not null default 0,
  derrotas int not null default 0,
  estilo text,
  empunhadura text,
  mao text,
  idade int,
  altura_cm int,
  peso_kg int,
  madeira text,
  borracha_fh text,
  borracha_bh text,
  desde int,
  camisa int,
  instagram text,
  bio text,
  foto_url text,
  avatar_grad text default 'linear-gradient(135deg,#FF7A1A,#B34A10)',
  radar jsonb default '[70,70,70,70,70]'::jsonb,
  ativo boolean not null default true,
  criado_em timestamptz default now()
);
create index if not exists jogadores_pontos_idx on jogadores (pontos desc);
create index if not exists jogadores_cat_idx on jogadores (categoria);

-- ---------- ETAPAS ----------
create table if not exists etapas (
  id uuid primary key default gen_random_uuid(),
  numero int not null,
  temporada int not null default extract(year from now()),
  nome text,
  data date,
  local text,
  cidade text,
  formato text not null default 'grupos_eliminatoria'
    check (formato in ('grupos_eliminatoria','eliminatoria_simples','todos_contra_todos')),
  status text not null default 'planejada'
    check (status in ('planejada','em_andamento','encerrada')),
  qtd_mesas int not null default 6,
  pontuacao jsonb not null default '[100,80,65,55,50,45,40,36,32,28,24,20,16,12,8,4]'::jsonb,
  criado_em timestamptz default now(),
  unique (temporada, numero)
);

-- ---------- INSCRIÇÕES ----------
create table if not exists inscricoes (
  id uuid primary key default gen_random_uuid(),
  etapa_id uuid not null references etapas(id) on delete cascade,
  jogador_id uuid not null references jogadores(id) on delete cascade,
  categoria text not null default 'C',
  presente boolean not null default false,
  unique (etapa_id, jogador_id)
);

-- ---------- GRUPOS ----------
create table if not exists grupos (
  id uuid primary key default gen_random_uuid(),
  etapa_id uuid not null references etapas(id) on delete cascade,
  categoria text not null,
  nome text not null,
  ordem int not null default 0
);

create table if not exists grupo_jogadores (
  grupo_id uuid not null references grupos(id) on delete cascade,
  jogador_id uuid not null references jogadores(id) on delete cascade,
  primary key (grupo_id, jogador_id)
);

-- ---------- MESAS ----------
create table if not exists mesas (
  id uuid primary key default gen_random_uuid(),
  etapa_id uuid not null references etapas(id) on delete cascade,
  numero int not null,
  status text not null default 'livre'
    check (status in ('livre','aguardando','partida','finalizada')),
  unique (etapa_id, numero)
);

-- ---------- PARTIDAS ----------
create table if not exists partidas (
  id uuid primary key default gen_random_uuid(),
  etapa_id uuid not null references etapas(id) on delete cascade,
  grupo_id uuid references grupos(id) on delete set null,
  categoria text not null default 'A',
  fase text not null default 'grupo'
    check (fase in ('grupo','oitavas','quartas','semifinal','final','disputa3')),
  chave_pos int,
  jogador_a uuid references jogadores(id) on delete set null,
  jogador_b uuid references jogadores(id) on delete set null,
  mesa_id uuid references mesas(id) on delete set null,
  melhor_de int not null default 5,
  sets_a int not null default 0,
  sets_b int not null default 0,
  pontos_a int not null default 0,
  pontos_b int not null default 0,
  vencedor_id uuid references jogadores(id) on delete set null,
  status text not null default 'proxima'
    check (status in ('proxima','aguardando','chamando','andamento','finalizada')),
  ordem int not null default 0,
  chamada_em timestamptz,
  iniciada_em timestamptz,
  finalizada_em timestamptz,
  criado_em timestamptz default now()
);
create index if not exists partidas_etapa_idx on partidas (etapa_id, status);

-- ---------- SETS ----------
create table if not exists sets (
  id uuid primary key default gen_random_uuid(),
  partida_id uuid not null references partidas(id) on delete cascade,
  numero int not null,
  pontos_a int not null default 0,
  pontos_b int not null default 0,
  unique (partida_id, numero)
);

-- ---------- RESULTADOS DA ETAPA ----------
create table if not exists resultados_etapa (
  id uuid primary key default gen_random_uuid(),
  etapa_id uuid not null references etapas(id) on delete cascade,
  jogador_id uuid not null references jogadores(id) on delete cascade,
  categoria text not null default 'A',
  posicao int not null,
  pontos int not null default 0,
  vitorias int not null default 0,
  derrotas int not null default 0,
  unique (etapa_id, jogador_id)
);

-- ---------- PATROCINADORES ----------
create table if not exists patrocinadores (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  logo_url text,
  site text,
  nivel text default 'apoio' check (nivel in ('master','ouro','prata','apoio')),
  ativo boolean not null default true,
  ordem int not null default 0
);

-- ---------- VIEW: RANKING ABSOLUTO ----------
create or replace view ranking as
select
  j.id, j.nome, j.clube, j.cidade, j.categoria, j.foto_url, j.avatar_grad,
  j.vitorias, j.derrotas,
  coalesce(sum(r.pontos), 0)::int as pontos,
  count(distinct r.etapa_id)::int as etapas_disputadas,
  rank() over (order by coalesce(sum(r.pontos),0) desc, j.vitorias desc)::int as posicao
from jogadores j
left join resultados_etapa r on r.jogador_id = j.id
where j.ativo
group by j.id;

-- ---------- RECÁLCULO DE PONTOS ----------
create or replace function recalcular_pontos() returns void
language sql security definer set search_path = public as $fn$
  update jogadores j set pontos = coalesce((
    select sum(r.pontos) from resultados_etapa r where r.jogador_id = j.id
  ), 0);
$fn$;

-- ---------- RLS ----------
alter table jogadores        enable row level security;
alter table etapas           enable row level security;
alter table inscricoes       enable row level security;
alter table grupos           enable row level security;
alter table grupo_jogadores  enable row level security;
alter table mesas            enable row level security;
alter table partidas         enable row level security;
alter table sets             enable row level security;
alter table resultados_etapa enable row level security;
alter table patrocinadores   enable row level security;
alter table admins           enable row level security;

do $do$
declare t text;
begin
  foreach t in array array['jogadores','etapas','inscricoes','grupos','grupo_jogadores',
                           'mesas','partidas','sets','resultados_etapa','patrocinadores']
  loop
    execute format('drop policy if exists leitura_publica on %I', t);
    execute format('create policy leitura_publica on %I for select using (true)', t);
    execute format('drop policy if exists escrita_admin on %I', t);
    execute format('create policy escrita_admin on %I for all using (is_admin()) with check (is_admin())', t);
  end loop;
end
$do$;

drop policy if exists admin_ve_se_mesmo on admins;
create policy admin_ve_se_mesmo on admins for select using (auth.uid() = user_id);

-- ---------- REALTIME ----------
do $do$
begin
  begin execute 'alter publication supabase_realtime add table partidas'; exception when others then null; end;
  begin execute 'alter publication supabase_realtime add table sets'; exception when others then null; end;
  begin execute 'alter publication supabase_realtime add table mesas'; exception when others then null; end;
  begin execute 'alter publication supabase_realtime add table etapas'; exception when others then null; end;
end
$do$;

alter table partidas replica identity full;
alter table sets replica identity full;
alter table mesas replica identity full;
