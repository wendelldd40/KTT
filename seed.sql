-- ============================================================
-- KTT IRECÊ — Dados iniciais (opcional, para ver o app cheio)
-- Rode DEPOIS do schema.sql. Pode apagar tudo depois com o bloco final.
-- ============================================================

insert into jogadores (nome,cidade,estado,clube,categoria,vitorias,derrotas,estilo,empunhadura,mao,idade,altura_cm,peso_kg,madeira,borracha_fh,borracha_bh,desde,camisa,instagram,bio,avatar_grad,radar) values
('Wendel Souza','Irecê','BA','ACTI Irecê','A',64,18,'Ofensivo','Clássica','Destro',27,178,74,'Butterfly Viscaria','Tenergy 05','Dignics 09c',2018,9,'@wendeltm','Bicampeão do circuito, referência do ataque de forehand na região de Irecê.','linear-gradient(135deg,#FF7A1A,#B34A10)','[92,58,85,74,80]'),
('Diego Ramos','Xique-Xique','BA','TM Xique-Xique','A',58,21,'Allround','Clássica','Canhoto',31,172,70,'Stiga Carbonado 145','Rakza 7','Rakza 7 Soft',2016,11,'@diegoramos_tm','Jogador de mais experiência do circuito, especialista em variação de efeitos no saque.','linear-gradient(135deg,#3E68FF,#22407A)','[74,80,78,82,88]'),
('Carlos Menezes','Jacobina','BA','AABB Jacobina','A',49,26,'Defensivo','Clássica','Destro',35,180,82,'Donic Defplay Senso','Tackiness Chop','Feint Long III',2015,4,'@carlostm_def','Defensor clássico, dono dos ralis mais longos do circuito.','linear-gradient(135deg,#22C3A6,#116A5A)','[52,95,66,88,90]'),
('Rafael Teixeira','Irecê','BA','ACTI Irecê','A',44,24,'Contra-ataque','Caneta Chinesa','Destro',23,170,66,'DHS Hurricane Long 5','Hurricane 3 Neo','Tenergy 64',2020,7,'@rafa_teixeira','Revelação do circuito com a caneta chinesa e bloqueios agressivos.','linear-gradient(135deg,#E5484D,#7A1E22)','[86,62,80,70,68]'),
('Marcos Lima','Barra do Mendes','BA','TM Barra','B',39,28,'Ofensivo','Caneta Japonesa','Destro',29,175,78,'Butterfly Cypress','Sriver G3',null,2017,10,'@marcoslima_tm','Forte no primeiro ataque, um dos poucos canetistas japoneses da região.','linear-gradient(135deg,#B07CFF,#5B2FA8)','[84,50,76,60,64]'),
('João Pedro Alves','Irecê','BA','ACTI Irecê','B',35,25,'Allround','Clássica','Destro',19,182,71,'Yasaka Ma Lin Extra Offensive','Mark V','Mark V',2022,21,'@jp_alves','Juvenil em ascensão, subiu da categoria C em 2025.','linear-gradient(135deg,#FFB224,#9A6208)','[70,66,72,68,74]'),
('André Bastos','Xique-Xique','BA','TM Xique-Xique','B',33,29,'Defensivo','Clássica','Canhoto',41,176,85,'Stiga Defensive Classic','Mendo','Curl P1-R',2015,3,'@andrebastos','Veterano do circuito, presente desde a primeira etapa em 2015.','linear-gradient(135deg,#4CC38A,#1B5E3F)','[48,90,60,84,86]'),
('Felipe Rocha','Central','BA','TM Central','C',26,22,'Ofensivo','Clássica','Destro',25,169,68,'Palio Energy 03','AK47 Red','AK47 Blue',2021,17,'@feliperocha_tm','Melhor saque da categoria C, buscando o acesso à B em 2026.','linear-gradient(135deg,#00A2C7,#075E73)','[78,54,84,58,60]');

insert into etapas (numero,temporada,nome,data,local,cidade,status,qtd_mesas) values
(1,2026,'1ª Etapa','2026-03-15','Ginásio Municipal','Irecê, BA','encerrada',6),
(2,2026,'2ª Etapa','2026-04-26','Quadra TM','Xique-Xique, BA','encerrada',6),
(3,2026,'3ª Etapa','2026-06-14','AABB','Jacobina, BA','encerrada',6),
(4,2026,'4ª Etapa','2026-07-23','Ginásio Municipal','Irecê, BA','em_andamento',6);

-- mesas de cada etapa
insert into mesas (etapa_id, numero)
select e.id, g.n from etapas e cross join generate_series(1,e.qtd_mesas) as g(n);

-- resultados das etapas encerradas
do $do$
declare
  pts int[] := array[100,80,65,55,50,45,40,36];
  ordens jsonb := '{"1":["Wendel Souza","Diego Ramos","João Pedro Alves","Rafael Teixeira","Carlos Menezes","Marcos Lima","André Bastos","Felipe Rocha"],
                    "2":["Diego Ramos","Wendel Souza","Rafael Teixeira","Carlos Menezes","João Pedro Alves","Marcos Lima","Felipe Rocha","André Bastos"],
                    "3":["Carlos Menezes","Wendel Souza","Diego Ramos","Rafael Teixeira","Marcos Lima","André Bastos","João Pedro Alves","Felipe Rocha"]}'::jsonb;
  et record; nomes jsonb; i int;
begin
  for et in select id, numero from etapas where status='encerrada' order by numero loop
    nomes := ordens -> et.numero::text;
    for i in 0..jsonb_array_length(nomes)-1 loop
      insert into resultados_etapa (etapa_id, jogador_id, categoria, posicao, pontos)
      select et.id, j.id, j.categoria, i+1, pts[i+1]
      from jogadores j where j.nome = (nomes ->> i)
      on conflict do nothing;
    end loop;
  end loop;
end
$do$;

select recalcular_pontos();

-- partidas da etapa em andamento
do $do$
declare e uuid; m1 uuid; m2 uuid; m3 uuid; m4 uuid;
begin
  select id into e from etapas where status='em_andamento' limit 1;
  select id into m1 from mesas where etapa_id=e and numero=1;
  select id into m2 from mesas where etapa_id=e and numero=2;
  select id into m3 from mesas where etapa_id=e and numero=3;
  select id into m4 from mesas where etapa_id=e and numero=4;

  insert into partidas (etapa_id,categoria,fase,jogador_a,jogador_b,mesa_id,status,sets_a,sets_b,ordem)
  select e,'A','semifinal',a.id,b.id,m1,'finalizada',3,1,1
  from jogadores a, jogadores b where a.nome='Wendel Souza' and b.nome='Diego Ramos';

  insert into partidas (etapa_id,categoria,fase,jogador_a,jogador_b,mesa_id,status,ordem)
  select e,'A','semifinal',a.id,b.id,m2,'andamento',2
  from jogadores a, jogadores b where a.nome='Rafael Teixeira' and b.nome='Carlos Menezes';

  insert into partidas (etapa_id,categoria,fase,jogador_a,jogador_b,mesa_id,status,ordem)
  select e,'B','final',a.id,b.id,m3,'proxima',3
  from jogadores a, jogadores b where a.nome='João Pedro Alves' and b.nome='Marcos Lima';

  insert into partidas (etapa_id,categoria,fase,jogador_a,jogador_b,mesa_id,status,ordem)
  select e,'A','disputa3',a.id,b.id,m4,'aguardando',4
  from jogadores a, jogadores b where a.nome='André Bastos' and b.nome='Felipe Rocha';

  update mesas set status='finalizada' where id=m1;
  update mesas set status='partida' where id=m2;
  update mesas set status='aguardando' where id in (m3,m4);
  update partidas set vencedor_id = jogador_a where status='finalizada' and etapa_id=e;
end
$do$;

-- LIMPAR TUDO (descomente se quiser zerar os dados de exemplo)
-- truncate resultados_etapa, sets, partidas, grupo_jogadores, grupos, inscricoes, mesas, etapas, jogadores cascade;
