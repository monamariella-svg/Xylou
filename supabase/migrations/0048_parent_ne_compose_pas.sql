-- 0048 — Le parent lit les résultats, il ne compose pas les exercices.
--
-- Même défaut qu'en 0047, un cran plus loin. `peut_valider()` ouvrait en
-- écriture les exercices, les notations et les corrections : un parent pouvait
-- rédiger un énoncé de mathématiques, corriger la copie de son enfant et lui
-- mettre une note.
--
-- Personne n'aurait fait ça. Mais une règle qui repose sur le fait que personne
-- n'en abusera n'est pas une règle, et un parent bien intentionné qui « aide »
-- en retouchant un barème fausse la mesure sans s'en apercevoir.
--
-- ---------------------------------------------------------------------------
-- LA COUPE EXACTE
--
-- Ce que le parent perd : composer, corriger, noter. Trois gestes de métier.
--
-- Ce qu'il garde, et qui n'est pas négociable :
--
--   valider qu'une mission atteigne son enfant. C'est le verrou du §3.2, et ce
--   n'est pas « modifier un exercice » — c'est décider si ce que l'IA propose
--   convient à son enfant, aujourd'hui. Aucun professionnel ne peut le savoir
--   à sa place.
--
--   tout lire. Les résultats, les copies, les corrections, les notes, les
--   jauges, matière par matière. C'est la contrepartie de sa supervision, et
--   c'est ce que le §3.2 lui promet en échange de son travail.
--
-- Le référent conserve l'écriture : il pilote les domaines transversaux, et il
-- est le professionnel de recours quand une matière n'a pas d'enseignant.
-- ---------------------------------------------------------------------------

-- --------------------------------------------------------------- exercices

drop policy exercices_ecriture on exercices;

create policy exercices_ecriture on exercices for all to authenticated
  using (
    est_intervenant(enfant_de_la_mission(mission_id), array['referent']::role_intervenant[])
    or mission_ouverte_a_l_enseignant(mission_id)
  )
  with check (
    est_intervenant(enfant_de_la_mission(mission_id), array['referent']::role_intervenant[])
    or mission_ouverte_a_l_enseignant(mission_id)
  );

-- --------------------------------------------------------------- notations

drop policy notations_ecriture on notations;

create policy notations_ecriture on notations for all to authenticated
  using (
    est_intervenant(enfant_de_la_mission(mission_id), array['referent']::role_intervenant[])
    or mission_relevant_de_l_enseignant(mission_id)
  )
  with check (
    note_par = auth.uid()
    and (
      est_intervenant(enfant_de_la_mission(mission_id), array['referent']::role_intervenant[])
      or mission_relevant_de_l_enseignant(mission_id)
    )
  );

-- ------------------------------------------------------------- corrections

drop policy corrections_ecriture on corrections;

create policy corrections_ecriture on corrections for all to authenticated
  using (
    est_intervenant(enfant_de_la_tentative(tentative_id), array['referent']::role_intervenant[])
    or tentative_ouverte_a_l_enseignant(tentative_id)
  )
  with check (
    corrigee_par = auth.uid()
    and (
      est_intervenant(enfant_de_la_tentative(tentative_id), array['referent']::role_intervenant[])
      or tentative_ouverte_a_l_enseignant(tentative_id)
    )
  );

-- ---------------------------------------------------------------- missions
--
-- Ici la politique ne suffit pas : le parent doit garder l'écriture pour
-- valider, et la perdre pour le contenu. RLS filtre des lignes, jamais des
-- colonnes — c'est donc un trigger qui tient la frontière, comme en 0047.

create or replace function restreindre_la_composition_de_mission()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_professionnel boolean;
begin
  if auth.uid() is null then
    return new;
  end if;

  v_professionnel :=
    est_intervenant(new.enfant_id, array['referent']::role_intervenant[])
    or mission_ouverte_a_l_enseignant(new.id)
    or mission_relevant_de_l_enseignant(new.id);

  if v_professionnel then
    return new;
  end if;

  -- Le contenu pédagogique et le barème du jeu : réservés aux professionnels.
  -- `points` en fait partie — un parent qui gonfle la valeur d'une mission
  -- déséquilibre l'économie de 0043 et vide les paliers de leur sens.
  if new.titre             is distinct from old.titre
  or new.intitule_narratif is distinct from old.intitule_narratif
  or new.difficulte        is distinct from old.difficulte
  or new.points            is distinct from old.points
  or new.nature            is distinct from old.nature
  or new.tentatives_max    is distinct from old.tentatives_max
  or new.indices_autorises is distinct from old.indices_autorises
  or new.matiere_code      is distinct from old.matiere_code
  or new.domaine_code      is distinct from old.domaine_code
  or new.objectif_id       is distinct from old.objectif_id
  or new.auteur_id         is distinct from old.auteur_id then
    raise exception 'Le contenu d''une mission est composé par l''enseignant de la matière, ou par le référent. Vous pouvez la valider, la refuser, ou demander qu''elle soit revue.';
  end if;

  return new;
end;
$$;

create trigger missions_restreignent_leur_composition
  before update on missions
  for each row execute function restreindre_la_composition_de_mission();

-- ================================================ ce que le parent consulte

-- Les résultats matière par matière, en une requête. L'information existait,
-- éparpillée dans six tables : la reconstituer côté application aurait donné
-- six requêtes par écran et autant d'occasions d'oublier un filtre.
--
-- Rien ici n'ouvre un accès nouveau : la fonction est `security definer` mais
-- elle vérifie `est_intervenant()`, et la clause de matière écarte l'enseignant
-- des matières qui ne sont pas les siennes — un professeur d'histoire n'y verra
-- que l'histoire, un parent verra tout.
create or replace function resultats_par_matiere(p_enfant uuid)
returns table (
  matiere_code text,
  libelle text,
  emoji text,
  badge_niveau smallint,
  objectifs_en_cours bigint,
  objectifs_atteints bigint,
  missions_reussies bigint,
  exercices_reussis bigint,
  exercices_tentes bigint,
  taux_reussite numeric,
  note_moyenne numeric,
  alertes_ouvertes bigint,
  pieces_gagnees bigint
)
language sql stable security definer set search_path = public as $$
  select
    m.code,
    m.libelle,
    m.emoji,
    coalesce((
      select max(b.niveau) from badges_obtenus b
      where b.enfant_id = p_enfant and b.matiere_code = m.code
    ), 0::smallint),
    (select count(*) from objectifs o
      where o.enfant_id = p_enfant and o.matiere_code = m.code
        and o.statut = 'valide'),
    (select count(*) from objectifs o
      where o.enfant_id = p_enfant and o.matiere_code = m.code
        and o.statut = 'atteint'),
    (select count(*) from missions mi
      where mi.enfant_id = p_enfant and mi.matiere_code = m.code
        and mi.statut = 'reussie'),
    (select count(distinct t.exercice_id) from tentatives t
      join exercices e on e.id = t.exercice_id
      join missions mi on mi.id = e.mission_id
      where t.enfant_id = p_enfant and mi.matiere_code = m.code and t.reussie),
    (select count(distinct t.exercice_id) from tentatives t
      join exercices e on e.id = t.exercice_id
      join missions mi on mi.id = e.mission_id
      where t.enfant_id = p_enfant and mi.matiere_code = m.code),
    (select case when count(distinct t.exercice_id) = 0 then null
                 else round(100.0 * count(distinct t.exercice_id) filter (where t.reussie)
                            / count(distinct t.exercice_id), 0) end
      from tentatives t
      join exercices e on e.id = t.exercice_id
      join missions mi on mi.id = e.mission_id
      where t.enfant_id = p_enfant and mi.matiere_code = m.code),
    -- Ramenée sur 20, pour être comparable d'un barème à l'autre.
    (select round(avg(20.0 * n.note / n.bareme), 1)
      from notations n
      join missions mi on mi.id = n.mission_id
      where mi.enfant_id = p_enfant and mi.matiere_code = m.code and n.note is not null),
    (select count(*) from alertes_difficulte a
      join reperes_competences r on r.id = a.repere_id
      where a.enfant_id = p_enfant and r.matiere_code = m.code and a.statut = 'ouverte'),
    (select coalesce(sum(g.pieces), 0) from pieces_gagnees g
      left join exercices e on e.id = g.exercice_id
      left join missions mi on mi.id = coalesce(e.mission_id, g.mission_id)
      where g.enfant_id = p_enfant and mi.matiere_code = m.code)
  from matieres m
  where est_intervenant(p_enfant)
    and matiere_ouverte_a_l_ecriture(p_enfant, m.code)
    -- Seulement les matières où il se passe quelque chose. Afficher les dix
    -- matières du référentiel pour un enfant qui en travaille trois
    -- transformerait un tableau de progrès en tableau de manques.
    and exists (
      select 1 from objectifs o
      where o.enfant_id = p_enfant and o.matiere_code = m.code
    )
  order by m.ordre;
$$;
