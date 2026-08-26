-- 0009 — Row Level Security sur l'intégralité du schéma.
--
-- Principe : l'accès se décide ici, jamais dans le code React. Une page qui
-- oublie un filtre doit renvoyer une liste vide, pas la fiche d'un autre enfant.
--
-- Trois cercles d'accès, du plus large au plus étroit :
--
--   est_intervenant()  — parents, référent et enseignants. Ce qui sert à
--                        accompagner l'enfant à l'école.
--   peut_valider()     — parents et référent seulement. Ce qui touche à
--                        l'intime, au consentement, et à la décision sur l'IA.
--   parent             — le titulaire de l'autorité parentale. Ce qui engage.
--
-- Un enseignant lit le niveau et les objectifs. Il ne lit ni le diagnostic, ni
-- les réponses brutes de l'enfant, ni ses tentatives ratées. Ce n'est pas de la
-- défiance : c'est la minimisation qu'impose le §3.4.
--
-- La matière cloisonne l'écriture, jamais la lecture. Un professeur de
-- mathématiques voit tout le scolaire de l'enfant — c'est la « photographie
-- claire » du §3.1, et elle perdrait son sens amputée des autres matières — mais
-- il n'écrit qu'en mathématiques.
--
-- Dans sa matière, le partage des rôles n'est pas le même selon l'objet :
--
--   objectif   — il propose, les parents ou le référent tranchent. C'est ce qui
--                engage la trajectoire de l'enfant, donc la famille décide.
--   exercice   — dès lors qu'ils s'inscrivent dans un objectif validé, ils sont
--   examen       à lui. C'est son métier, et personne n'est mieux placé pour
--                calibrer un contrôle de mathématiques.
--
-- La supervision du §3.2 n'est pas levée : elle est portée par l'objectif. La
-- famille décide de ce qui sera travaillé ; le professeur décide comment. Une
-- validation demandée trente fois par semaine deviendrait un réflexe, et une
-- validation qu'on ne lit plus ne protège plus personne — la placer là où elle
-- est rare est ce qui la garde effective.
--
-- Le corollaire est strict : hors d'un objectif validé, ou dans une matière que
-- personne n'enseigne, l'enseignant n'a aucun droit d'écriture et tout retombe
-- sur les parents et le référent. `genere_par_ia` ne commande donc plus aucun
-- accès ; la colonne reste, informative, pour dire d'où vient un travail.

-- ------------------------------------------- résolution de l'enfant porteur
--
-- SECURITY DEFINER pour remonter une chaîne de clés étrangères sans déclencher
-- la RLS des tables traversées — sinon chaque politique en évaluerait d'autres
-- en cascade, pour un résultat identique et un plan d'exécution catastrophique.

create or replace function enfant_du_projet_moteur(p_projet uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select enfant_id from projets_moteurs where id = p_projet;
$$;

create or replace function enfant_du_bilan(p_bilan uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select enfant_id from bilans_positionnement where id = p_bilan;
$$;

create or replace function enfant_de_la_question(p_question uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select b.enfant_id
  from bilan_questions q join bilans_positionnement b on b.id = q.bilan_id
  where q.id = p_question;
$$;

create or replace function enfant_du_support(p_support uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select enfant_id from supports where id = p_support;
$$;

create or replace function enfant_de_l_adaptation(p_adaptation uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select s.enfant_id
  from adaptations a join supports s on s.id = a.support_id
  where a.id = p_adaptation;
$$;

create or replace function enfant_de_la_mission(p_mission uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select enfant_id from missions where id = p_mission;
$$;

create or replace function enfant_de_l_exercice(p_exercice uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select m.enfant_id
  from exercices e join missions m on m.id = e.mission_id
  where e.id = p_exercice;
$$;

create or replace function enfant_du_bilan_trimestriel(p_bilan uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select enfant_id from bilans_trimestriels where id = p_bilan;
$$;

-- Deux personnes se « connaissent » si elles accompagnent le même enfant. Sert
-- à afficher « validé par Camille » sans ouvrir l'annuaire des comptes.
create or replace function partage_un_enfant(p_profil uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from intervenants_enfant a
    join intervenants_enfant b on b.enfant_id = a.enfant_id
    where a.profil_id = auth.uid() and a.retire_le is null
      and b.profil_id = p_profil and b.retire_le is null
  );
$$;

-- L'email du compte connecté, pour qu'une personne invitée retrouve son
-- invitation avant d'être rattachée à quoi que ce soit.
create or replace function email_courant()
returns text language sql stable as $$
  select lower(coalesce(auth.jwt() ->> 'email', ''));
$$;

-- Un enseignant écrit dans sa matière et nulle part ailleurs (§3.1 : son geste
-- est de valider un objectif et de déposer un support, pas de piloter tout le
-- scolaire). La lecture, elle, reste entière : comprendre où en est l'enfant
-- suppose de voir les autres matières.
--
-- Les parents et le référent passent : la contrainte de matière ne concerne
-- qu'un rôle, celui d'enseignant. Un enseignant sans matière renseignée n'écrit
-- rien du tout — c'est un profil incomplet, pas un profil aux droits étendus.
-- La contrainte de 0011 empêche déjà de créer un tel rattachement ; cette
-- clause-ci est la seconde serrure, pour le cas où la première serait retirée.
--
-- Le test porte sur la ligne d'intervenant et non sur matiere_de_l_intervenant(),
-- qui renvoie null aussi bien pour un parent que pour un enseignant sans
-- matière : deux situations que la base doit traiter à l'opposé l'une de l'autre.
create or replace function matiere_ouverte_a_l_ecriture(p_enfant uuid, p_matiere text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from intervenants_enfant i
    where i.enfant_id = p_enfant
      and i.profil_id = auth.uid()
      and i.retire_le is null
      and (i.role <> 'enseignant' or i.matiere_code = p_matiere)
  );
$$;

-- L'objectif est le point de contrôle, et le seul.
--
-- La famille valide un objectif : c'est là qu'elle décide de la trajectoire, et
-- c'est le geste qui engage. Ce qui s'inscrit ensuite dans cet objectif —
-- exercices, examens, missions — appartient au professeur de la matière. Lui
-- demander l'aval d'un parent pour composer un contrôle de mathématiques
-- n'aurait pas de sens, et le lui demander trente fois par semaine
-- transformerait la supervision en réflexe : une validation qu'on ne lit plus ne
-- protège plus personne.
--
-- La supervision du §3.2 n'est donc pas levée, elle est déplacée là où elle est
-- lue. Un travail proposé par l'IA hors de tout objectif validé, ou dans une
-- matière que personne n'enseigne, retombe sur les parents et le référent : la
-- jointure sur `objectifs` est stricte, et une mission sans objectif n'ouvre
-- aucun droit à l'enseignant.
create or replace function objectif_valide(p_objectif uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from objectifs o
    where o.id = p_objectif and o.statut in ('valide', 'atteint')
  );
$$;

create or replace function mission_ouverte_a_l_enseignant(p_mission uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from missions m
    join intervenants_enfant i on i.enfant_id = m.enfant_id
    join objectifs o on o.id = m.objectif_id
    where m.id = p_mission
      and i.profil_id = auth.uid()
      and i.retire_le is null
      and i.role = 'enseignant'
      and i.matiere_code = m.matiere_code
      and o.statut in ('valide', 'atteint')
  );
$$;

create or replace function exercice_ouvert_a_l_enseignant(p_exercice uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from exercices e
    where e.id = p_exercice and mission_ouverte_a_l_enseignant(e.mission_id)
  );
$$;

-- =========================================================== activation RLS

alter table profils                    enable row level security;
alter table enfants                    enable row level security;
alter table enfants_sante              enable row level security;
alter table intervenants_enfant        enable row level security;
alter table invitations                enable row level security;
alter table centres_interet            enable row level security;
alter table projets_moteurs            enable row level security;
alter table recompenses                enable row level security;
alter table matieres                   enable row level security;
alter table reperes_competences        enable row level security;
alter table bilans_positionnement      enable row level security;
alter table bilan_questions            enable row level security;
alter table bilan_reponses             enable row level security;
alter table bilan_maitrises            enable row level security;
alter table bilan_niveaux_matiere      enable row level security;
alter table objectifs                  enable row level security;
alter table supports                   enable row level security;
alter table adaptations                enable row level security;
alter table missions                   enable row level security;
alter table exercices                  enable row level security;
alter table tentatives                 enable row level security;
alter table recompenses_obtenues       enable row level security;
alter table bilans_trimestriels        enable row level security;
alter table bilans_trimestriels_matieres enable row level security;
alter table journal_ia                 enable row level security;
alter table consentements              enable row level security;
alter table journal_acces              enable row level security;

-- ================================================================= profils

create policy profils_lecture on profils for select to authenticated
  using (id = auth.uid() or partage_un_enfant(id));

create policy profils_maj on profils for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- ================================================================= enfants

-- `cree_par` figure dans la clause de lecture parce qu'à l'instant exact où le
-- parent insère la fiche, sa ligne d'intervenant n'existe pas encore.
create policy enfants_lecture on enfants for select to authenticated
  using (est_intervenant(id) or cree_par = auth.uid());

create policy enfants_creation on enfants for insert to authenticated
  with check (cree_par = auth.uid());

create policy enfants_maj on enfants for update to authenticated
  using (peut_valider(id) or cree_par = auth.uid())
  with check (peut_valider(id) or cree_par = auth.uid());

create policy enfants_suppression on enfants for delete to authenticated
  using (est_intervenant(id, array['parent']::role_intervenant[]));

-- Diagnostic, aménagements, suivis extérieurs : parents et référent, personne
-- d'autre. C'est la table qui justifie l'AIPD du §3.8.
create policy enfants_sante_lecture on enfants_sante for select to authenticated
  using (peut_valider(enfant_id));

create policy enfants_sante_ecriture on enfants_sante for all to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));

-- ==================================================== intervenants et invitations

create policy intervenants_lecture on intervenants_enfant for select to authenticated
  using (profil_id = auth.uid() or est_intervenant(enfant_id));

create policy intervenants_ajout on intervenants_enfant for insert to authenticated
  with check (
    est_intervenant(enfant_id, array['parent']::role_intervenant[])
    or exists (select 1 from enfants e where e.id = enfant_id and e.cree_par = auth.uid())
  );

create policy intervenants_maj on intervenants_enfant for update to authenticated
  using (est_intervenant(enfant_id, array['parent']::role_intervenant[]))
  with check (est_intervenant(enfant_id, array['parent']::role_intervenant[]));

create policy intervenants_retrait on intervenants_enfant for delete to authenticated
  using (est_intervenant(enfant_id, array['parent']::role_intervenant[]));

create policy invitations_lecture on invitations for select to authenticated
  using (peut_valider(enfant_id) or lower(email) = email_courant());

create policy invitations_creation on invitations for insert to authenticated
  with check (peut_valider(enfant_id) and invite_par = auth.uid());

create policy invitations_maj on invitations for update to authenticated
  using (peut_valider(enfant_id) or lower(email) = email_courant());

-- ================================== centres d'intérêt, projet moteur, récompenses
--
-- En lecture large : le projet moteur est précisément ce qu'un enseignant doit
-- connaître pour comprendre la mission qu'il valide.

create policy centres_interet_lecture on centres_interet for select to authenticated
  using (est_intervenant(enfant_id));

create policy centres_interet_ecriture on centres_interet for all to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));

create policy projets_moteurs_lecture on projets_moteurs for select to authenticated
  using (est_intervenant(enfant_id));

create policy projets_moteurs_ecriture on projets_moteurs for all to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));

create policy recompenses_lecture on recompenses for select to authenticated
  using (est_intervenant(enfant_du_projet_moteur(projet_moteur_id)));

create policy recompenses_ecriture on recompenses for all to authenticated
  using (peut_valider(enfant_du_projet_moteur(projet_moteur_id)))
  with check (peut_valider(enfant_du_projet_moteur(projet_moteur_id)));

-- ========================================================== référentiel

-- Le référentiel scolaire n'appartient à personne : lisible par tout compte
-- connecté, modifiable par la seule clé de service.
create policy matieres_lecture on matieres for select to authenticated using (true);
create policy reperes_lecture on reperes_competences for select to authenticated using (true);

-- ================================================= bilan de positionnement

create policy bilans_lecture on bilans_positionnement for select to authenticated
  using (est_intervenant(enfant_id));

create policy bilans_ecriture on bilans_positionnement for all to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));

-- Les questions posées et les réponses données restent entre l'enfant, ses
-- parents et son référent. Un enseignant lit la synthèse, pas la copie.
create policy bilan_questions_acces on bilan_questions for all to authenticated
  using (peut_valider(enfant_du_bilan(bilan_id)))
  with check (peut_valider(enfant_du_bilan(bilan_id)));

create policy bilan_reponses_acces on bilan_reponses for all to authenticated
  using (peut_valider(enfant_de_la_question(question_id)))
  with check (peut_valider(enfant_de_la_question(question_id)));

create policy bilan_maitrises_lecture on bilan_maitrises for select to authenticated
  using (est_intervenant(enfant_du_bilan(bilan_id)));

create policy bilan_maitrises_ecriture on bilan_maitrises for all to authenticated
  using (peut_valider(enfant_du_bilan(bilan_id)))
  with check (peut_valider(enfant_du_bilan(bilan_id)));

-- La « photographie claire du niveau réel » promise à l'équipe pédagogique
-- (§3.1) : c'est cette table-là, et elle seule, qui la porte.
create policy bilan_niveaux_lecture on bilan_niveaux_matiere for select to authenticated
  using (est_intervenant(enfant_id));

create policy bilan_niveaux_ecriture on bilan_niveaux_matiere for all to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));

-- ================================================= objectifs et supports

create policy objectifs_lecture on objectifs for select to authenticated
  using (est_intervenant(enfant_id));

-- Un enseignant propose ; il ne valide pas. La contrainte de table impose déjà
-- qu'un objectif non « propose » porte un validateur ; la politique impose que
-- ce validateur soit un parent ou le référent.
create policy objectifs_proposition on objectifs for insert to authenticated
  with check (
    est_intervenant(enfant_id)
    and propose_par = auth.uid()
    and (statut = 'propose' or peut_valider(enfant_id))
    and matiere_ouverte_a_l_ecriture(enfant_id, matiere_code)
  );

-- La clause de matière figure aussi ici, et pas seulement à l'insertion : sans
-- elle, un enseignant déplacerait son propre objectif vers une autre matière
-- d'un simple update.
create policy objectifs_maj on objectifs for update to authenticated
  using (peut_valider(enfant_id) or (propose_par = auth.uid() and statut = 'propose'))
  with check (
    (case when peut_valider(enfant_id) then true else statut = 'propose' end)
    and matiere_ouverte_a_l_ecriture(enfant_id, matiere_code)
  );

create policy objectifs_suppression on objectifs for delete to authenticated
  using (peut_valider(enfant_id) or (propose_par = auth.uid() and statut = 'propose'));

create policy supports_lecture on supports for select to authenticated
  using (est_intervenant(enfant_id));

create policy supports_depot on supports for insert to authenticated
  with check (
    est_intervenant(enfant_id)
    and depose_par = auth.uid()
    and matiere_ouverte_a_l_ecriture(enfant_id, matiere_code)
  );

create policy supports_maj on supports for update to authenticated
  using (peut_valider(enfant_id) or depose_par = auth.uid())
  with check (
    (peut_valider(enfant_id) or depose_par = auth.uid())
    and matiere_ouverte_a_l_ecriture(enfant_id, matiere_code)
  );

create policy supports_suppression on supports for delete to authenticated
  using (peut_valider(enfant_id) or depose_par = auth.uid());

create policy adaptations_lecture on adaptations for select to authenticated
  using (est_intervenant(enfant_de_l_adaptation(id)));

create policy adaptations_ecriture on adaptations for all to authenticated
  using (peut_valider(enfant_de_l_adaptation(id)))
  with check (peut_valider(enfant_du_support(support_id)));

-- =================================================== missions et exercices

create policy missions_lecture on missions for select to authenticated
  using (est_intervenant(enfant_id));

-- Le professeur écrit dans sa matière, à l'intérieur d'un objectif que la
-- famille a validé. `objectif_id is not null` n'est pas redondant avec
-- `objectif_valide()` : sans lui, une mission détachée de tout objectif
-- passerait la clause avec un null silencieux.
create policy missions_ecriture on missions for all to authenticated
  using (
    peut_valider(enfant_id)
    or (
      matiere_ouverte_a_l_ecriture(enfant_id, matiere_code)
      and objectif_id is not null
      and objectif_valide(objectif_id)
    )
  )
  with check (
    peut_valider(enfant_id)
    or (
      matiere_ouverte_a_l_ecriture(enfant_id, matiere_code)
      and objectif_id is not null
      and objectif_valide(objectif_id)
    )
  );

create policy exercices_lecture on exercices for select to authenticated
  using (est_intervenant(enfant_de_la_mission(mission_id)));

create policy exercices_ecriture on exercices for all to authenticated
  using (
    peut_valider(enfant_de_la_mission(mission_id))
    or mission_ouverte_a_l_enseignant(mission_id)
  )
  with check (
    peut_valider(enfant_de_la_mission(mission_id))
    or mission_ouverte_a_l_enseignant(mission_id)
  );

-- Les essais et les erreurs de l'enfant : cercle restreint. Dans le MVP, l'enfant
-- travaille depuis la session d'un parent — d'où l'écriture réservée à ce cercle.
create policy tentatives_acces on tentatives for all to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));

-- La lecture des copies par le professeur est ouverte en 0013 et pas ici : elle
-- dépend de `missions.auteur_id`, colonne que 0013 crée. La règle n'est pas non
-- plus celle de l'écriture — un travail transposé par l'IA depuis le PDF d'un
-- professeur reste son travail, même s'il ne peut pas le valider lui-même.

create policy recompenses_obtenues_lecture on recompenses_obtenues for select to authenticated
  using (est_intervenant(enfant_id));

create policy recompenses_obtenues_ecriture on recompenses_obtenues for all to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));

-- ================================================== bilan trimestriel

create policy bilans_trim_lecture on bilans_trimestriels for select to authenticated
  using (est_intervenant(enfant_id));

create policy bilans_trim_ecriture on bilans_trimestriels for all to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));

create policy bilans_trim_matieres_lecture on bilans_trimestriels_matieres for select to authenticated
  using (est_intervenant(enfant_du_bilan_trimestriel(bilan_id)));

create policy bilans_trim_matieres_ecriture on bilans_trimestriels_matieres for all to authenticated
  using (peut_valider(enfant_du_bilan_trimestriel(bilan_id)))
  with check (peut_valider(enfant_du_bilan_trimestriel(bilan_id)));

-- ==================================================== supervision et RGPD

-- Ce que l'IA coûte regarde la famille qui paie (§3.6), pas l'établissement.
create policy journal_ia_lecture on journal_ia for select to authenticated
  using (enfant_id is not null and peut_valider(enfant_id));

create policy journal_ia_ecriture on journal_ia for insert to authenticated
  with check (enfant_id is null or est_intervenant(enfant_id));

-- Un consentement se lit par ceux qu'il engage, se donne par un parent pour
-- lui-même, et se révoque par la personne qui l'a donné — jamais par un tiers.
create policy consentements_lecture on consentements for select to authenticated
  using (profil_id = auth.uid() or est_intervenant(enfant_id, array['parent']::role_intervenant[]));

create policy consentements_creation on consentements for insert to authenticated
  with check (
    profil_id = auth.uid()
    and est_intervenant(enfant_id, array['parent']::role_intervenant[])
  );

create policy consentements_revocation on consentements for update to authenticated
  using (profil_id = auth.uid()) with check (profil_id = auth.uid());

create policy journal_acces_lecture on journal_acces for select to authenticated
  using (peut_valider(enfant_id));

create policy journal_acces_ecriture on journal_acces for insert to authenticated
  with check (est_intervenant(enfant_id) and profil_id = auth.uid());
