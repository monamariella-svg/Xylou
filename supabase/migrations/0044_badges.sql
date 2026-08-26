-- 0044 — Les badges, ou le chaînon manquant.
--
-- Le schéma récompensait deux choses et en oubliait une troisième, qui est la
-- plus importante :
--
--   les pièces (0043)   récompensent l'exercice fait. Immédiat, quotidien.
--   la récompense (0040) récompense le palier franchi. Lointain, familial.
--   rien                 ne récompensait l'**objectif atteint**.
--
-- Or c'est l'objectif que l'enseignant pose, et c'est sur lui qu'il juge. Entre
-- « j'ai fait mes exercices » et « j'ai progressé en mathématiques », il n'y
-- avait aucun pont : l'enfant accumulait des pièces sans jamais voir que son
-- travail répondait à une attente précise.
--
-- Le badge est ce pont. Une jauge par matière — et par domaine transversal, la
-- communication mérite son badge autant que les mathématiques — qui avance à
-- mesure que les objectifs fins de ce champ sont atteints. Au terme du
-- trimestre, si la progression est là, le badge monte d'un niveau.
--
-- La chaîne complète devient lisible, et c'est ce qui manquait :
--
--   l'enseignant pose un objectif fin, avec son nombre de réussites attendu
--        ↓
--   l'enfant fait des exercices, gagne des pièces au passage
--        ↓
--   les réussites remplissent l'objectif, la jauge du badge avance
--        ↓
--   le trimestre se termine, le badge monte de niveau
--        ↓
--   les badges du trimestre débloquent la récompense familiale
--
-- Chaque maillon est visible de l'enfant. C'est la différence entre travailler
-- pour des points et travailler pour quelque chose.

-- L'apparence du badge appartient à la matière, pas à l'enfant : un badge de
-- mathématiques doit se reconnaître d'un dossier à l'autre.
alter table matieres add column emoji text not null default '🎓';
alter table domaines_transversaux add column emoji text not null default '⭐';

update matieres set emoji = case code
  when 'francais' then '📖'
  when 'maths' then '🔢'
  when 'histoire_geo' then '🗺️'
  when 'langues' then '💬'
  when 'svt' then '🌱'
  when 'physique_chimie' then '⚗️'
  when 'technologie' then '⚙️'
  when 'arts' then '🎨'
  when 'emc' then '⚖️'
  when 'eps' then '🏃'
  else '🎓'
end;

update domaines_transversaux set emoji = case code
  when 'communication' then '🗣️'
  when 'social' then '🤝'
  when 'autonomie' then '🧭'
  when 'comportement' then '🌊'
  when 'societal' then '🏛️'
  else '⭐'
end;

-- ------------------------------------------------------------- les badges

create table badges_obtenus (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,

  matiere_code text references matieres on delete restrict,
  domaine_code text references domaines_transversaux on delete restrict,

  niveau smallint not null check (niveau >= 1),

  annee_id uuid references annees_enfant on delete set null,
  trimestre smallint check (trimestre between 1 and 3),

  -- Ce qui a été atteint au moment de l'attribution, figé. Le badge doit rester
  -- explicable des mois plus tard, quand les objectifs auront changé.
  objectifs_atteints smallint not null default 0,
  objectifs_total smallint not null default 0,
  progression numeric,

  -- Nul quand le seuil a été franchi et le badge attribué automatiquement.
  -- Renseigné quand un professionnel l'a accordé malgré un seuil non atteint.
  attribue_par uuid references profils on delete set null,
  commentaire text not null default '',

  obtenu_le timestamptz not null default now(),

  constraint badge_releve_d_un_seul_champ
    check (num_nonnulls(matiere_code, domaine_code) = 1)
);

create unique index badge_un_niveau_par_matiere
  on badges_obtenus (enfant_id, matiere_code, niveau) where matiere_code is not null;
create unique index badge_un_niveau_par_domaine
  on badges_obtenus (enfant_id, domaine_code, niveau) where domaine_code is not null;

create index badges_enfant_idx on badges_obtenus (enfant_id, obtenu_le desc);

-- Le seuil de progression au-delà duquel le badge se gagne. Isolé dans une
-- fonction pour être ajustable après le pilote : c'est typiquement le genre de
-- valeur qu'on croit bien choisir et qu'on corrige au premier trimestre réel.
create or replace function seuil_badge()
returns numeric language sql immutable as $$ select 70::numeric; $$;

-- --------------------------------------------------------------- la jauge

-- Ce que l'enfant voit avancer. Elle compte les objectifs fins du champ pour
-- l'année en cours : atteints sur total. Un objectif large ne compte pas — il ne
-- se termine pas, il se décompose.
create or replace function jauge_badge(
  p_enfant uuid,
  p_matiere text default null,
  p_domaine text default null
)
returns table (
  champ text,
  libelle text,
  emoji text,
  niveau_actuel smallint,
  objectifs_total bigint,
  objectifs_atteints bigint,
  progression numeric,
  seuil numeric
)
language sql stable security definer set search_path = public as $$
  select
    coalesce(p_matiere, p_domaine),
    coalesce(m.libelle, d.libelle, ''),
    coalesce(m.emoji, d.emoji, '🎓'),
    coalesce((
      select max(b.niveau) from badges_obtenus b
      where b.enfant_id = p_enfant
        and b.matiere_code is not distinct from p_matiere
        and b.domaine_code is not distinct from p_domaine
    ), 0::smallint),
    count(o.id),
    count(o.id) filter (where o.statut = 'atteint'),
    case when count(o.id) = 0 then 0
         else round(100.0 * count(o.id) filter (where o.statut = 'atteint') / count(o.id), 0)
    end,
    seuil_badge()
  from (select 1) unite
  left join matieres m on m.code = p_matiere
  left join domaines_transversaux d on d.code = p_domaine
  left join annees_enfant a on a.enfant_id = p_enfant and a.close_le is null
  left join objectifs o
    on o.enfant_id = p_enfant
   and o.granularite = 'fin'
   and o.matiere_code is not distinct from p_matiere
   and o.domaine_code is not distinct from p_domaine
   and (o.annee_id is null or o.annee_id = a.id)
   and o.statut in ('valide', 'atteint')
  where est_intervenant(p_enfant) or est_l_enfant(p_enfant)
  group by m.libelle, d.libelle, m.emoji, d.emoji;
$$;

-- Toutes les jauges de l'enfant, pour l'écran qui les affiche côte à côte. Seuls
-- les champs où il a effectivement des objectifs : afficher dix matières vides
-- transformerait un tableau de progrès en tableau de manques.
create or replace function mes_jauges(p_enfant uuid)
returns table (
  champ text,
  libelle text,
  emoji text,
  niveau_actuel smallint,
  objectifs_total bigint,
  objectifs_atteints bigint,
  progression numeric,
  seuil numeric
)
language sql stable security definer set search_path = public as $$
  select j.*
  from (
    select distinct o.matiere_code, o.domaine_code
    from objectifs o
    left join annees_enfant a on a.id = o.annee_id
    where o.enfant_id = p_enfant
      and o.granularite = 'fin'
      and o.statut in ('valide', 'atteint')
  ) champs
  cross join lateral jauge_badge(p_enfant, champs.matiere_code, champs.domaine_code) j
  where est_intervenant(p_enfant) or est_l_enfant(p_enfant)
  order by j.progression desc;
$$;

-- ------------------------------------------------------- attribuer un badge

create or replace function attribuer_le_badge(
  p_enfant uuid,
  p_matiere text default null,
  p_domaine text default null,
  p_trimestre smallint default null,
  p_commentaire text default ''
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_jauge record;
  v_annee uuid;
  v_badge uuid;
  v_manuel boolean;
  v_compte uuid;
begin
  if num_nonnulls(p_matiere, p_domaine) <> 1 then
    raise exception 'Un badge relève d''une matière ou d''un domaine, pas des deux.';
  end if;

  -- Le pilote du champ, comme partout ailleurs : l'enseignant de la matière, le
  -- référent pour le transversal. Un badge est un jugement sur le travail, il
  -- revient à celui qui l'a suivi.
  if not (
    (p_matiere is not null and matiere_ouverte_a_l_ecriture(p_enfant, p_matiere))
    or (p_domaine is not null and est_intervenant(p_enfant, array['referent']::role_intervenant[]))
  ) then
    raise exception 'Ce badge revient à l''enseignant de la matière, ou au référent pour un domaine transversal.';
  end if;

  select * into v_jauge from jauge_badge(p_enfant, p_matiere, p_domaine);

  if v_jauge.objectifs_total = 0 then
    raise exception 'Aucun objectif dans ce champ : il n''y a rien à récompenser encore.';
  end if;

  -- En dessous du seuil, le badge reste possible mais devient un geste assumé.
  -- « Bien progressé » n'est pas toujours un pourcentage : un enfant qui a
  -- franchi un blocage compte autant qu'un enfant qui a coché ses cases.
  v_manuel := v_jauge.progression < seuil_badge();

  if v_manuel and length(btrim(p_commentaire)) < 5 then
    raise exception 'Progression de % pour cent, seuil à %. Le badge reste attribuable, mais il se motive : dites en quoi l''enfant a progressé.',
      v_jauge.progression, seuil_badge();
  end if;

  select id into v_annee from annees_enfant
  where enfant_id = p_enfant and close_le is null;

  insert into badges_obtenus (
    enfant_id, matiere_code, domaine_code, niveau, annee_id, trimestre,
    objectifs_atteints, objectifs_total, progression,
    attribue_par, commentaire
  )
  values (
    p_enfant, p_matiere, p_domaine, (v_jauge.niveau_actuel + 1)::smallint,
    v_annee, p_trimestre,
    v_jauge.objectifs_atteints, v_jauge.objectifs_total, v_jauge.progression,
    case when v_manuel then auth.uid() else null end,
    btrim(p_commentaire)
  )
  returning id into v_badge;

  -- L'enfant est prévenu directement. C'est le moment que tout le dispositif
  -- vise, et il n'a pas à l'apprendre par un adulte qui y aurait pensé.
  select compte_id into v_compte from enfants where id = p_enfant;

  if v_compte is not null then
    insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
    values (
      v_compte, p_enfant, 'badge_obtenu',
      v_jauge.emoji || ' Badge ' || v_jauge.libelle || ' niveau ' || (v_jauge.niveau_actuel + 1),
      v_jauge.objectifs_atteints || ' objectifs atteints sur ' || v_jauge.objectifs_total || '.',
      '/mes-badges/' || v_badge
    );
  end if;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select i.profil_id, p_enfant, 'badge_obtenu',
         'Badge ' || v_jauge.libelle || ' niveau ' || (v_jauge.niveau_actuel + 1),
         '', '/enfants/' || p_enfant || '/badges/' || v_badge
  from intervenants_enfant i
  where i.enfant_id = p_enfant
    and i.retire_le is null
    and i.role in ('parent', 'referent')
    and i.profil_id <> auth.uid();

  return v_badge;
end;
$$;

-- ------------------------------------- le badge comme condition de récompense

-- Le maillon qui referme la chaîne : la récompense trimestrielle se gagne sur
-- des badges, c'est-à-dire sur des objectifs atteints, c'est-à-dire sur ce que
-- les enseignants attendaient. Les pièces récompensent le chemin, les badges
-- récompensent l'arrivée.
alter table recompenses_familiales
  add column badges_requis integer check (badges_requis is null or badges_requis > 0);

comment on column recompenses_familiales.badges_requis is
  'Nombre de badges à obtenir. Comptés sur l''année scolaire en cours, tous champs confondus.';

create or replace function badges_de_l_annee(p_enfant uuid)
returns integer language sql stable security definer set search_path = public as $$
  select count(*)::integer
  from badges_obtenus b
  join annees_enfant a on a.id = b.annee_id
  where b.enfant_id = p_enfant and a.close_le is null;
$$;

-- La progression de 0040 ne connaissait que les pièces et les missions. Une
-- colonne ajoutée sans être branchée ne sert à rien — c'est le défaut que le
-- consentement de 0008 a traîné pendant vingt migrations, et je ne le refais pas.
-- La version à trois paramètres de 0040 doit disparaître : avec un quatrième
-- paramètre à valeur par défaut, les deux coexisteraient et tout appel à trois
-- arguments deviendrait ambigu — « function is not unique », à l'exécution et
-- non à la création, donc découvert au pire moment.
drop function if exists progression_vers(uuid, integer, integer);

create function progression_vers(
  p_enfant uuid,
  p_points integer,
  p_missions integer,
  p_badges integer default null
)
returns numeric
language sql stable security definer set search_path = public as $$
  select min(part) from (
    select case when p_points is null then null else
      least(100, round(100.0 * coalesce((select points_gagnes from points_enfant where enfant_id = p_enfant), 0) / p_points, 0))
    end as part
    union all
    select case when p_missions is null then null else
      least(100, round(100.0 * missions_reussies(p_enfant) / p_missions, 0))
    end
    union all
    select case when p_badges is null then null else
      least(100, round(100.0 * badges_de_l_annee(p_enfant) / p_badges, 0))
    end
  ) parts;
$$;

-- Et les deux fonctions de lecture, pour que la condition de badge apparaisse
-- réellement à l'enfant et au modèle.
drop function if exists mes_recompenses(uuid);

create function mes_recompenses(p_enfant uuid)
returns table (
  recompense_id uuid,
  devoilee boolean,
  libelle text,
  description text,
  photo_chemin text,
  surprise_libelle text,
  surprise_image_chemin text,
  prevue_le date,
  jours_restants integer,
  horizon horizon_recompense,
  points_requis integer,
  points_actuels integer,
  missions_requises integer,
  missions_actuelles integer,
  badges_requis integer,
  badges_actuels integer,
  progression numeric,
  de_la_part_de text
)
language sql stable security definer set search_path = public as $$
  select
    r.id,
    (r.devoilee_le is not null),
    case when r.devoilee_le is not null or r.montrer_nature then r.libelle else '' end,
    case when r.devoilee_le is not null or r.montrer_nature then r.description else '' end,
    case when r.devoilee_le is not null or r.montrer_nature then r.photo_chemin else null end,
    coalesce(pm.surprise_libelle, 'Une surprise'),
    pm.surprise_image_chemin,
    case when r.devoilee_le is not null or r.montrer_date then r.prevue_le else null end,
    case when r.devoilee_le is not null or r.montrer_date
         then (r.prevue_le - current_date)::integer else null end,
    case when r.devoilee_le is not null or r.montrer_date
         then horizon_de(r.prevue_le) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.points_requis else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then coalesce(p.points_gagnes, 0) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.missions_requises else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then missions_reussies(p_enfant) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.badges_requis else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then badges_de_l_annee(p_enfant) else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then progression_vers(p_enfant, r.points_requis, r.missions_requises, r.badges_requis)
         else null end,
    coalesce(pr.prenom, '')
  from recompenses_familiales r
  left join points_enfant p on p.enfant_id = r.enfant_id
  left join profils pr on pr.id = r.proposee_par
  left join projets_moteurs pm on pm.enfant_id = r.enfant_id and pm.actif
  where r.enfant_id = p_enfant
    and r.statut = 'promise'
    and (r.montrer_existence or r.devoilee_le is not null)
    and (est_l_enfant(p_enfant) or est_intervenant(p_enfant))
  order by r.prevue_le nulls last;
$$;

drop function if exists recompenses_a_venir(uuid);

create function recompenses_a_venir(p_enfant uuid)
returns table (
  recompense_id uuid,
  libelle text,
  description text,
  photo_chemin text,
  prevue_le date,
  jours_restants integer,
  horizon horizon_recompense,
  points_requis integer,
  points_actuels integer,
  missions_requises integer,
  missions_actuelles integer,
  badges_requis integer,
  badges_actuels integer,
  progression numeric,
  condition text
)
language sql stable security definer set search_path = public as $$
  select
    r.id,
    case when r.devoilee_le is not null or r.montrer_nature
         then r.libelle
         else coalesce(pm.surprise_libelle, 'Une surprise') end,
    case when r.devoilee_le is not null or r.montrer_nature then r.description else '' end,
    case when r.devoilee_le is not null or r.montrer_nature then r.photo_chemin else null end,
    case when r.devoilee_le is not null or r.montrer_date then r.prevue_le else null end,
    case when r.devoilee_le is not null or r.montrer_date
         then (r.prevue_le - current_date)::integer else null end,
    case when r.devoilee_le is not null or r.montrer_date
         then horizon_de(r.prevue_le) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.points_requis else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then coalesce(p.points_gagnes, 0) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.missions_requises else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then missions_reussies(p_enfant) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.badges_requis else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then badges_de_l_annee(p_enfant) else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then progression_vers(p_enfant, r.points_requis, r.missions_requises, r.badges_requis)
         else null end,
    r.condition
  from recompenses_familiales r
  left join points_enfant p on p.enfant_id = r.enfant_id
  left join projets_moteurs pm on pm.enfant_id = r.enfant_id and pm.actif
  where r.enfant_id = p_enfant
    and r.statut = 'promise'
    and (r.montrer_existence or r.devoilee_le is not null)
    and (est_intervenant(p_enfant) or est_l_enfant(p_enfant))
  order by r.prevue_le nulls last;
$$;

-- ==================================================================== RLS

alter table badges_obtenus enable row level security;

create policy badges_lecture on badges_obtenus for select to authenticated
  using (est_intervenant(enfant_id) or est_l_enfant(enfant_id));

-- Aucune politique d'écriture : les badges passent par `attribuer_le_badge()`,
-- qui vérifie le champ, le pilote et le seuil. Et aucune suppression — un badge
-- retiré serait la chose la plus décourageante que cet outil puisse faire.
