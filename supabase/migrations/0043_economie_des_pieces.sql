-- 0043 — Les pièces se gagnent à l'exercice, et selon l'effort.
--
-- 0006 posait `missions.points`, un entier fixe attribué à la mission entière.
-- Deux défauts que l'usage quotidien rend criants :
--
--   - un exercice difficile rapporte autant qu'un facile, ce qui apprend à
--     l'enfant à chercher le moins coûteux plutôt que le plus utile ;
--   - rien n'est gagné avant que la mission entière soit réussie. Un enfant qui
--     en fait quatre sur cinq repart avec zéro, et ce zéro-là décourage
--     exactement ceux qu'on voulait accrocher.
--
-- La pièce se gagne donc **à l'exercice**, une fois, à la première réussite, et
-- proportionnellement à sa difficulté. La note du professeur s'ajoute en bonus —
-- jamais en condition : elle accélère, elle ne bloque rien. C'est la réserve
-- posée à propos des quêtes, et elle vaut ici aussi.
--
-- ---------------------------------------------------------------------------
-- UN REGISTRE, PAS UN COMPTEUR
--
-- 0006 disait déjà pourquoi : « un compteur dénormalisé finit toujours par
-- diverger de l'historique qui le justifie ». Avec trois sources de gain —
-- l'exercice, le bonus de note, le cadeau d'un adulte — un solde stocké
-- deviendrait invérifiable au premier écart.
--
-- Chaque gain est donc une ligne. Le solde est une somme, et l'enfant peut
-- toujours savoir d'où vient chaque pièce.
-- ---------------------------------------------------------------------------

create type source_pieces as enum (
  'exercice',      -- réussite d'un exercice, selon sa difficulté
  'bonus_note',    -- la note obtenue à une évaluation
  'mission',       -- la mission achevée dans son entier
  'cadeau'         -- un adulte donne, hors barème
);

create table pieces_gagnees (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  source source_pieces not null,

  exercice_id uuid references exercices on delete set null,
  mission_id uuid references missions on delete set null,
  notation_id uuid references notations on delete set null,

  pieces integer not null check (pieces > 0),
  -- Ce que l'enfant lit dans son historique. « Exercice difficile réussi »,
  -- « Très bonne note en mathématiques », « Pour ton courage cette semaine ».
  motif text not null default '',

  attribue_par uuid references profils on delete set null,
  cree_le timestamptz not null default now()
);

create index pieces_gagnees_enfant_idx on pieces_gagnees (enfant_id, cree_le desc);

-- Une pièce par exercice réussi, et une seule. Sans cet index, un enfant qui
-- refait un exercice déjà réussi encaisserait à chaque passage — et il s'en
-- apercevrait vite.
create unique index pieces_une_fois_par_exercice
  on pieces_gagnees (enfant_id, exercice_id)
  where source = 'exercice';

create unique index pieces_une_fois_par_notation
  on pieces_gagnees (notation_id) where source = 'bonus_note';

create unique index pieces_une_fois_par_mission
  on pieces_gagnees (enfant_id, mission_id) where source = 'mission';

-- ------------------------------------------------------------- le barème

alter table exercices
  -- Nulle : l'exercice hérite alors de la difficulté de sa mission. Renseignée
  -- quand un exercice détonne dans une mission par ailleurs homogène.
  add column difficulte smallint check (difficulte is null or difficulte between 1 and 5),
  -- Forcée à la main quand le barème ne convient pas. Rare, mais un professeur
  -- doit pouvoir dire « celui-là vaut plus que ce que sa difficulté annonce ».
  add column pieces integer check (pieces is null or pieces >= 0);

-- Progression volontairement non linéaire vers le haut : un exercice de
-- difficulté 5 rapporte six fois un exercice de difficulté 1, pas cinq. L'écart
-- doit se voir, sinon rien ne pousse à tenter plus dur.
create or replace function pieces_pour(p_difficulte smallint)
returns integer language sql immutable as $$
  select case coalesce(p_difficulte, 3)
    when 1 then 2
    when 2 then 4
    when 3 then 6
    when 4 then 9
    else 12
  end;
$$;

-- ------------------------------------------- attribution à la réussite

create or replace function attribuer_les_pieces_de_l_exercice()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_diff smallint;
  v_pieces integer;
  v_forcees integer;
begin
  if not new.reussie then
    return new;
  end if;

  select coalesce(e.difficulte, m.difficulte), e.pieces
    into v_diff, v_forcees
  from exercices e
  join missions m on m.id = e.mission_id
  where e.id = new.exercice_id;

  v_pieces := coalesce(v_forcees, pieces_pour(v_diff));

  if v_pieces = 0 then
    return new;
  end if;

  -- `on conflict do nothing` plutôt qu'un test préalable : deux tentatives
  -- réussies enregistrées au même instant passeraient toutes deux le test, et
  -- l'index unique est le seul arbitre fiable.
  insert into pieces_gagnees (enfant_id, source, exercice_id, pieces, motif)
  values (
    new.enfant_id, 'exercice', new.exercice_id, v_pieces,
    case
      when v_diff >= 4 then 'Exercice difficile réussi'
      when v_diff <= 2 then 'Exercice réussi'
      else 'Exercice réussi'
    end
  )
  on conflict do nothing;

  return new;
end;
$$;

create trigger tentatives_attribuent_les_pieces
  after insert on tentatives
  for each row execute function attribuer_les_pieces_de_l_exercice();

-- --------------------------------------------------------- le bonus de note

-- La note s'ajoute, elle ne conditionne rien. Une mauvaise note ne retire aucune
-- pièce : elle n'en donne simplement pas. La différence n'est pas rhétorique —
-- un enfant qui peut *perdre* ce qu'il a gagné cesse de prendre des risques.
--
-- Rien en dessous de la moitié du barème, puis une progression jusqu'à dix
-- pièces pour une note parfaite. Le seuil évite qu'un bonus dérisoire vienne
-- souligner un mauvais résultat, ce qui vaudrait mieux que rien.
create or replace function attribuer_le_bonus_de_note()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_enfant uuid;
  v_ratio numeric;
  v_bonus integer;
begin
  if new.note is null or new.bareme is null or new.bareme = 0 then
    return new;
  end if;

  v_ratio := new.note / new.bareme;

  if v_ratio < 0.5 then
    return new;
  end if;

  v_bonus := ceil(10 * v_ratio)::integer;

  select enfant_id into v_enfant from missions where id = new.mission_id;

  insert into pieces_gagnees
    (enfant_id, source, mission_id, notation_id, pieces, motif, attribue_par)
  values (
    v_enfant, 'bonus_note', new.mission_id, new.id, v_bonus,
    'Bonus pour la note obtenue', new.note_par
  )
  on conflict do nothing;

  return new;
end;
$$;

create trigger notations_attribuent_le_bonus
  after insert or update on notations
  for each row execute function attribuer_le_bonus_de_note();

-- ----------------------------------------------------- la mission achevée

-- `missions.points` garde son sens : la prime d'achèvement, versée quand la
-- mission entière est réussie. Elle vient s'ajouter aux pièces des exercices,
-- elle ne les remplace pas — finir ce qu'on a commencé vaut quelque chose en
-- soi, et c'est justement ce qui manque à un enfant qui abandonne en route.
create or replace function attribuer_les_pieces_de_la_mission()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.statut <> 'reussie' or old.statut = 'reussie' or new.points = 0 then
    return new;
  end if;

  insert into pieces_gagnees (enfant_id, source, mission_id, pieces, motif)
  values (new.enfant_id, 'mission', new.id, new.points, 'Mission terminée')
  on conflict do nothing;

  return new;
end;
$$;

create trigger missions_attribuent_leurs_pieces
  after update on missions
  for each row execute function attribuer_les_pieces_de_la_mission();

-- ------------------------------------------------------------- le solde

-- La vue de 0006 sommait `missions.points`. Elle lit désormais le registre, qui
-- porte les trois sources. Les colonnes ne changent pas : tout ce qui s'appuie
-- dessus — la boutique de 0030, les paliers de 0040 — continue de fonctionner.
create or replace view points_enfant
with (security_invoker = true) as
  select
    e.id as enfant_id,
    coalesce(gagnes.total, 0) as points_gagnes,
    coalesce(depenses.total, 0) as points_depenses,
    coalesce(gagnes.total, 0) - coalesce(depenses.total, 0) as solde
  from enfants e
  left join (
    select g.enfant_id, sum(g.pieces)::integer as total
    from pieces_gagnees g
    group by g.enfant_id
  ) gagnes on gagnes.enfant_id = e.id
  left join (
    select ro.enfant_id, sum(ro.points_payes)::integer as total
    from recompenses_obtenues ro
    where not ro.offerte
    group by ro.enfant_id
  ) depenses on depenses.enfant_id = e.id;

-- ==================================================================== RLS

alter table pieces_gagnees enable row level security;

-- L'enfant lit son propre registre : savoir d'où vient chaque pièce fait partie
-- du jeu, et c'est ce qui rend le barème lisible plutôt qu'arbitraire.
create policy pieces_lecture on pieces_gagnees for select to authenticated
  using (est_intervenant(enfant_id) or est_l_enfant(enfant_id));

-- Les gains automatiques passent par les triggers, en SECURITY DEFINER. La seule
-- écriture ouverte est le cadeau : un adulte qui donne des pièces hors barème.
create policy pieces_cadeau on pieces_gagnees for insert to authenticated
  with check (
    source = 'cadeau'
    and attribue_par = auth.uid()
    and est_intervenant(enfant_id)
    and length(btrim(motif)) > 0
  );

-- Aucune suppression, aucune modification. Retirer des pièces gagnées est la
-- seule chose que ce dispositif ne doit jamais permettre : une monnaie qu'on
-- peut confisquer cesse d'être une récompense pour devenir un moyen de pression.
