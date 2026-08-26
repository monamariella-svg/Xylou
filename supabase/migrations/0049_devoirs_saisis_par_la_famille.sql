-- 0049 — Le devoir que la famille saisit.
--
-- 0048 vient d'écarter le parent de la composition des exercices, et c'était
-- juste : rédiger un énoncé de mathématiques est un métier. Mais ça laissait
-- dehors le cas le plus fréquent du quotidien.
--
-- Le soir, le parent a le cahier de textes devant lui. L'enseignant, lui,
-- n'utilise pas forcément l'outil — le §3.4 en fait même le risque d'adoption
-- principal. Si la famille ne peut pas saisir les exercices du soir, Xylou ne
-- sert à rien les jours où l'école n'a rien déposé, c'est-à-dire la plupart.
--
-- ---------------------------------------------------------------------------
-- TRANSCRIRE N'EST PAS COMPOSER
--
-- Le parent ne décide pas de ce qui est travaillé : il recopie ce que l'école a
-- donné, pour que l'IA le transpose dans l'univers de l'enfant. C'est un geste
-- de saisie, pas un geste pédagogique — et c'est pour ça qu'il lui revient sans
-- entamer ce que 0048 protège.
--
-- La distinction est portée par `nature` : un travail de nature « devoir » est
-- ouvert à la famille, les autres non. Un parent ne peut pas requalifier en
-- devoir la mission d'un enseignant pour se donner le droit d'y toucher — la
-- nature d'un travail est figée dès qu'elle est posée.
-- ---------------------------------------------------------------------------

alter type nature_travail add value if not exists 'devoir';

-- Toutes les comparaisons passent par `::text`. Une valeur d'énumération
-- fraîchement ajoutée ne peut pas être lue dans la même transaction que son
-- ajout, et une politique RLS résout ses littéraux à la création. Le cast évite
-- le piège et permet de tout tenir dans un seul fichier.
create or replace function mission_est_un_devoir(p_mission uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from missions m
    where m.id = p_mission and m.nature::text = 'devoir'
  );
$$;

-- --------------------------------------------- la composition, revisitée

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

  -- La nature ne se change pas. Sans ce verrou, il suffirait de requalifier en
  -- devoir l'évaluation d'un enseignant pour en réécrire le contenu.
  if new.nature is distinct from old.nature then
    raise exception 'La nature d''un travail est fixée à sa création : un entraînement ne devient pas un devoir, ni l''inverse.';
  end if;

  -- Un devoir saisi par la famille lui reste ouvert. Elle l'a transcrit, elle
  -- peut le corriger — une consigne recopiée de travers se répare le soir même,
  -- et attendre l'enseignant reviendrait à perdre la soirée de travail.
  if old.nature::text = 'devoir' and peut_valider(new.enfant_id) then
    return new;
  end if;

  if new.titre             is distinct from old.titre
  or new.intitule_narratif is distinct from old.intitule_narratif
  or new.difficulte        is distinct from old.difficulte
  or new.points            is distinct from old.points
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

-- ------------------------------------------------- les exercices du devoir

drop policy exercices_ecriture on exercices;

create policy exercices_ecriture on exercices for all to authenticated
  using (
    est_intervenant(enfant_de_la_mission(mission_id), array['referent']::role_intervenant[])
    or mission_ouverte_a_l_enseignant(mission_id)
    or (
      mission_est_un_devoir(mission_id)
      and peut_valider(enfant_de_la_mission(mission_id))
    )
  )
  with check (
    est_intervenant(enfant_de_la_mission(mission_id), array['referent']::role_intervenant[])
    or mission_ouverte_a_l_enseignant(mission_id)
    or (
      mission_est_un_devoir(mission_id)
      and peut_valider(enfant_de_la_mission(mission_id))
    )
  );

-- ------------------------------------------------------------- le cadrage
--
-- Deux règles qui empêchent le devoir de devenir une porte dérobée.

-- Un devoir n'est pas une évaluation : il ne se note pas. La note engage
-- l'appréciation d'un professionnel sur un travail scolaire, et un parent qui
-- noterait la copie de son enfant fausserait la moyenne par matière que 0048
-- vient de rendre lisible à toute l'équipe.
create or replace function refuser_la_note_sur_un_devoir()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if mission_est_un_devoir(new.mission_id)
     and not mission_relevant_de_l_enseignant(new.mission_id)
     and auth.uid() is not null then
    raise exception 'Un devoir saisi par la famille ne se note pas. L''enseignant de la matière peut le faire s''il le souhaite.';
  end if;
  return new;
end;
$$;

create trigger notations_refusent_les_devoirs
  before insert or update on notations
  for each row execute function refuser_la_note_sur_un_devoir();

-- Un devoir compte pour les pièces et pour la progression de l'objectif auquel
-- il se rattache — c'est du vrai travail, et le nier découragerait exactement
-- l'enfant qu'on cherche à accrocher. Il ne compte pas pour un badge : le badge
-- dit que l'enseignant a constaté la progression, et personne d'autre ne peut
-- le dire à sa place.
comment on type nature_travail is
  'entrainement : libre et répétable. evaluation : composée et notée par l''enseignant. devoir : donné par l''école, saisi par la famille, non noté.';
