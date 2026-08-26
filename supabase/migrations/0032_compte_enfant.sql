-- 0032 — L'enfant a son compte.
--
-- 0009 posait qu'il travaillait depuis la session d'un parent. Pour un
-- adolescent de 4e, c'était intenable : demander l'ordinateur de sa mère pour
-- faire ses exercices est le meilleur moyen de ne pas les faire.
--
-- ---------------------------------------------------------------------------
-- POURQUOI PAS UN RÔLE DANS `intervenants_enfant`
--
-- La tentation était d'ajouter 'enfant' à `role_intervenant`. Elle est piégeuse :
-- `est_intervenant(p_enfant)` sans filtre de rôle gouverne la lecture d'une
-- trentaine de tables, et l'enfant y aurait tout gagné d'un coup — le diagnostic,
-- les alertes de blocage écrites sur lui, les conversations entre adultes, le
-- journal des accès. Une seule ligne dans un enum aurait ouvert tout le dossier.
--
-- L'enfant n'est donc pas un intervenant de plus. C'est un accès distinct, dont
-- chaque droit est écrit ici, un par un. La liste est courte et c'est voulu :
-- ce qui n'y figure pas lui reste fermé, y compris ce qu'on ajoutera demain.
-- ---------------------------------------------------------------------------

alter table enfants
  add column compte_id uuid unique references profils on delete set null;

comment on column enfants.compte_id is
  'Compte personnel de l''enfant, quand il en a un. Nul sinon : il travaille alors depuis la session d''un parent.';

create or replace function est_l_enfant(p_enfant uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from enfants e
    where e.id = p_enfant
      and e.compte_id = auth.uid()
      and e.archive_le is null
  );
$$;

-- Rattacher un compte à un enfant appartient à la famille et au référent. Le
-- détacher aussi — un adolescent en difficulté peut avoir besoin qu'on referme
-- l'accès un temps, et ce n'est pas une décision qu'il prend seul.
create or replace function proteger_le_compte_enfant()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.compte_id is distinct from old.compte_id
     and not (peut_valider(new.id) or est_admin()) then
    raise exception 'Le compte d''un enfant est rattaché par ses parents ou son référent.';
  end if;
  return new;
end;
$$;

create trigger enfants_protegent_le_compte
  before update on enfants
  for each row execute function proteger_le_compte_enfant();

-- ============================================== ce que l'enfant voit de lui

-- Sa fiche. Ni `enfants_sante`, qui reste au cercle qui valide : un enfant
-- découvrant son diagnostic dans une interface, sans personne à côté de lui,
-- n'est pas ce que le §3.4 protège.
create policy enfants_lecture_enfant on enfants for select to authenticated
  using (compte_id = auth.uid() and archive_le is null);

-- Son univers, et de quoi comprendre ce qu'il gagne.
create policy projets_moteurs_lecture_enfant on projets_moteurs
  for select to authenticated using (est_l_enfant(enfant_id));

create policy centres_interet_lecture_enfant on centres_interet
  for select to authenticated using (est_l_enfant(enfant_id));

create policy recompenses_lecture_enfant on recompenses
  for select to authenticated
  using (est_l_enfant(enfant_du_projet_moteur(projet_moteur_id)));

create policy recompenses_obtenues_lecture_enfant on recompenses_obtenues
  for select to authenticated using (est_l_enfant(enfant_id));

-- Il achète lui-même. C'est tout l'intérêt de la boutique : un solde qu'un
-- adulte dépense à sa place ne récompense rien. Les vérifications de 0030 —
-- solde, prérequis, unicité — s'appliquent de la même façon.
create policy recompenses_obtenues_achat_enfant on recompenses_obtenues
  for insert to authenticated
  with check (est_l_enfant(enfant_id) and offerte = false);

-- Ce qu'il a à faire, et rien d'autre : une mission encore en attente de
-- validation ne doit pas lui apparaître, sans quoi le verrou de supervision se
-- contournerait par la simple curiosité.
create policy missions_lecture_enfant on missions for select to authenticated
  using (
    est_l_enfant(enfant_id)
    and statut in ('validee', 'en_cours', 'reussie')
  );

create policy exercices_lecture_enfant on exercices for select to authenticated
  using (
    exists (
      select 1 from missions m
      where m.id = mission_id
        and est_l_enfant(m.enfant_id)
        and m.statut in ('validee', 'en_cours', 'reussie')
    )
  );

-- Ses propres essais : il les écrit, il les relit. Un enfant qui ne peut pas
-- revoir ce qu'il a répondu ne peut pas apprendre de son erreur.
create policy tentatives_lecture_enfant on tentatives for select to authenticated
  using (est_l_enfant(enfant_id));

create policy tentatives_ecriture_enfant on tentatives for insert to authenticated
  with check (est_l_enfant(enfant_id));

-- La correction et la note lui sont adressées : elles lui reviennent de droit.
create policy corrections_lecture_enfant on corrections for select to authenticated
  using (est_l_enfant(enfant_de_la_tentative(tentative_id)));

create policy notations_lecture_enfant on notations for select to authenticated
  using (est_l_enfant(enfant_de_la_mission(mission_id)));

-- Les objectifs validés, pour qu'il sache vers quoi il travaille. Pas ceux en
-- discussion : un objectif que les adultes n'ont pas encore arrêté n'a pas à lui
-- être annoncé, et encore moins un objectif refusé.
create policy objectifs_lecture_enfant on objectifs for select to authenticated
  using (est_l_enfant(enfant_id) and statut in ('valide', 'atteint'));

-- ---------------------------------------------------------------------------
-- CE QUI LUI RESTE FERMÉ, ET POURQUOI
--
--   enfants_sante          le diagnostic, sans accompagnement humain.
--   alertes_difficulte     ce que les adultes écrivent de ses blocages. Lire
--   alertes_actions        « trois échecs d'affilée, blocage installé » sur soi
--                          n'aide personne à treize ans.
--   fils, messages         les conversations entre adultes le concernant.
--   avis_ia                le jugement des professionnels sur l'outil.
--   bilans, niveaux        la photographie de son niveau par matière. Le §3.3
--                          interdit la comparaison à une norme ; la restitution
--                          à l'enfant lui-même demande une médiation qui ne se
--                          règle pas par une politique RLS.
--   journal_acces          qui a consulté son dossier.
--   objectifs_demandes     les désaccords entre adultes sur sa trajectoire.
--
-- Chacune de ces fermetures est discutable et plusieurs méritent d'être
-- rouvertes une fois l'interface pensée pour lui parler. Aucune ne l'est par
-- défaut : ouvrir demande une décision, garder fermé n'en demande pas.
-- ---------------------------------------------------------------------------
