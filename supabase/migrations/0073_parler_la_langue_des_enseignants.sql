-- 0073 — Rendre un bilan lisible par une équipe, sans le rendre comparatif.
--
-- Les évaluations nationales classent chaque élève en trois groupes de maîtrise
-- par domaine, sans note. C'est le vocabulaire que les enseignants manipulent
-- déjà, et un bilan Xylou qui l'ignore oblige chacun à retraduire dans sa tête —
-- ce que personne ne fait, et qui finit par « je n'ai pas compris leur truc ».
--
-- `maitrise` (0004) en compte cinq, volontairement : « à travailler », « en
-- cours », « acquis », « point fort ». Plus fin, et surtout descriptif — il dit
-- où en est l'enfant, pas où il se situe par rapport aux autres.
--
-- ---------------------------------------------------------------------------
-- POURQUOI TRADUIRE PLUTÔT QUE REMPLACER
--
-- Les libellés officiels des groupes sont de registre comparatif — un élève y
-- est « fragile » ou « à besoins ». La convention du projet l'interdit à
-- l'écran : on mesure un niveau, on ne note pas un écart à une norme.
--
-- D'où deux lectures d'une même mesure, et non deux mesures :
--
--   ce que voient l'enfant et sa famille — les cinq niveaux de `maitrise` ;
--   ce que lit l'équipe pédagogique      — les trois groupes, sur demande.
--
-- La mesure ne change pas. Seul son énoncé s'adapte au lecteur. Et comme la
-- traduction va du fin vers le grossier, elle ne perd rien qui ne soit
-- retrouvable : l'inverse aurait été une perte définitive.
-- ---------------------------------------------------------------------------

-- Numérotés plutôt que nommés. Les libellés officiels n'ont pas pu être
-- vérifiés sur les pages de l'Éducation nationale, et inventer « fragile » ou
-- « satisfaisant » les ferait passer pour officiels. Le numéro, lui, est exact :
-- les évaluations nationales rangent bien en trois groupes ordonnés.
create or replace function groupe_de_maitrise(p_maitrise maitrise)
returns smallint
language sql
immutable
as $$
  select case p_maitrise
    when 'a_travailler' then 1
    when 'en_cours'     then 2
    when 'acquise'      then 3
    -- Un point fort reste dans le groupe le plus élevé : les évaluations
    -- nationales n'ont pas de quatrième groupe pour le distinguer. C'est
    -- précisément ce que notre échelle sait dire et pas la leur, et c'est une
    -- raison de garder les deux.
    when 'point_fort'   then 3
    else null
  end::smallint;
$$;

-- Ce qu'on affiche à côté du numéro, sans registre comparatif. Ces formulations
-- sont les nôtres : elles décrivent ce que l'enfant fait, pas son rang.
create or replace function libelle_groupe_de_maitrise(p_groupe smallint)
returns text
language sql
immutable
as $$
  select case p_groupe
    when 1 then 'Groupe 1 — à construire'
    when 2 then 'Groupe 2 — en cours de construction'
    when 3 then 'Groupe 3 — maîtrisé'
    else 'Non évalué'
  end;
$$;

-- La lecture « équipe pédagogique » d'un bilan : un groupe par matière, agrégé
-- depuis les repères validés. On agrège par la médiane et non par la moyenne —
-- un unique repère non évalué ou un point fort isolé ne doit pas déplacer le
-- groupe d'une matière entière.
create or replace function groupes_par_matiere(p_bilan uuid)
returns table (matiere_code text, groupe smallint, repere_count bigint)
language sql
stable
as $$
  select
    r.matiere_code,
    percentile_disc(0.5) within group (
      order by groupe_de_maitrise(bm.maitrise)
    )::smallint as groupe,
    count(*) as repere_count
  from bilan_maitrises bm
  join reperes_competences r on r.id = bm.repere_id
  where bm.bilan_id = p_bilan
    and groupe_de_maitrise(bm.maitrise) is not null
  group by r.matiere_code;
$$;
