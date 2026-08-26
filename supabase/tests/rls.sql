-- ===========================================================================
-- Vérification des règles d'accès (RLS)
--
-- À exécuter dans le SQL Editor de Supabase, sur une base où les migrations
-- 0001 à 0044 sont passées. Le script crée ses propres comptes et dossiers,
-- vérifie une cinquantaine de règles, puis efface tout ce qu'il a créé.
--
-- Il est réexécutable : il commence par nettoyer les traces d'un passage
-- précédent, repérables à leur adresse en @test.xylou.
--
-- Il ne s'arrête PAS à la première erreur : il collecte tout et affiche un
-- rapport à la fin. Un test qui s'interrompt ne dit que le premier problème,
-- et on corrige à l'aveugle en ignorant les quatre suivants.
--
-- ---------------------------------------------------------------------------
-- CE QU'IL CHERCHE
--
-- Surtout les règles TROP PERMISSIVES. Une règle trop stricte se découvre en
-- cinq minutes : la page est vide, quelqu'un se plaint. Une règle trop large
-- ne se voit jamais — tout fonctionne, jusqu'au jour où un enseignant tombe
-- sur le dossier d'une autre famille. C'est pourquoi la majorité des
-- assertions ci-dessous attendent zéro.
-- ===========================================================================

-- ------------------------------------------------------------ le décor

create temporary table if not exists resultats (
  rang serial,
  domaine text,
  cas text,
  attendu text,
  obtenu text,
  ok boolean
) on commit drop;

truncate resultats;

-- Le script se fait passer pour des comptes ordinaires puis consigne ce qu'ils
-- voient. La table de resultats appartient a postgres : sans ces droits, chaque
-- assertion echouerait non pas sur la regle testee, mais sur son propre
-- carnet de notes.
grant select, insert on resultats to authenticated;
grant usage, select on sequence resultats_rang_seq to authenticated;

do $bloc$
declare
  -- comptes
  p1 uuid; p2 uuid;          -- les deux parents de l'enfant A
  ref uuid;                  -- le référent
  parentB uuid;              -- le parent du second enfant
  maths uuid; histoire uuid; -- deux enseignants, deux matières
  aesh uuid;                 -- accompagnante
  admin uuid;
  tiers uuid;                -- enseignant d'un autre enfant, sans lien avec A
  compte_enfant uuid;

  -- dossiers
  enfA uuid; enfB uuid;
  obj uuid; miss uuid; exo uuid;
  fil_prive uuid;
  n integer;
  msg text;

  procedure_inexistante boolean;
begin
  -- ================================================== nettoyage d'un passage
  delete from auth.users where email like '%@test.xylou';

  -- ================================================== création des comptes
  insert into auth.users (id, email) values
    (gen_random_uuid(), 'parent1@test.xylou') returning id into p1;
  insert into auth.users (id, email) values
    (gen_random_uuid(), 'parent2@test.xylou') returning id into p2;
  insert into auth.users (id, email) values
    (gen_random_uuid(), 'referent@test.xylou') returning id into ref;
  insert into auth.users (id, email) values
    (gen_random_uuid(), 'maths@test.xylou') returning id into maths;
  insert into auth.users (id, email) values
    (gen_random_uuid(), 'histoire@test.xylou') returning id into histoire;
  insert into auth.users (id, email) values
    (gen_random_uuid(), 'aesh@test.xylou') returning id into aesh;
  insert into auth.users (id, email) values
    (gen_random_uuid(), 'admin@test.xylou') returning id into admin;
  insert into auth.users (id, email) values
    (gen_random_uuid(), 'tiers@test.xylou') returning id into tiers;
  insert into auth.users (id, email) values
    (gen_random_uuid(), 'parentB@test.xylou') returning id into parentB;
  insert into auth.users (id, email) values
    (gen_random_uuid(), 'enfant@test.xylou') returning id into compte_enfant;

  -- Le trigger de 0001 a créé les profils. On pose les qualités de plateforme.
  update profils set role_plateforme = 'admin' where id = admin;
  update profils set role_plateforme = 'referent' where id in (ref, tiers);

  -- ================================================== les dossiers
  insert into enfants (prenom, classe, cree_par, titulaires_autorite_parentale)
    values ('Enfant A', '4e', ref, 2) returning id into enfA;
  insert into enfants (prenom, classe, cree_par, titulaires_autorite_parentale)
    values ('Enfant B', '4e', tiers, 1) returning id into enfB;

  update enfants set compte_id = compte_enfant where id = enfA;

  insert into intervenants_enfant (enfant_id, profil_id, role) values
    (enfA, ref, 'referent'), (enfA, p1, 'parent'), (enfA, p2, 'parent'),
    (enfA, aesh, 'accompagnant'),
    -- Le second dossier doit être valide lui aussi : depuis 0025, un enfant
    -- conserve au moins un titulaire de l'autorité parentale rattaché. Un
    -- dossier de test bancal casse les migrations suivantes, pas le test.
    (enfB, tiers, 'referent'), (enfB, parentB, 'parent');

  insert into intervenants_enfant (enfant_id, profil_id, role, toutes_matieres)
    values (enfA, maths, 'enseignant', false);
  insert into intervenants_matieres (intervenant_id, matiere_code)
    select id, 'maths' from intervenants_enfant
    where enfant_id = enfA and profil_id = maths;

  insert into intervenants_enfant (enfant_id, profil_id, role, toutes_matieres)
    values (enfA, histoire, 'enseignant', false);
  insert into intervenants_matieres (intervenant_id, matiere_code)
    select id, 'histoire_geo' from intervenants_enfant
    where enfant_id = enfA and profil_id = histoire;

  insert into enfants_sante (enfant_id, besoins_particuliers)
    values (enfA, 'Donnee sensible de test');

  -- Un objectif de maths, validé par les deux parents.
  insert into objectifs
    (enfant_id, matiere_code, libelle, propose_par, granularite, statut)
    values (enfA, 'maths', 'Objectif de test', maths, 'large', 'propose')
    returning id into obj;

  insert into objectifs_validations (objectif_id, profil_id) values (obj, p1);
  insert into objectifs_validations (objectif_id, profil_id) values (obj, p2);
  insert into objectifs_validations (objectif_id, profil_id) values (obj, ref);

  insert into projets_moteurs (enfant_id, titre, cree_par)
    values (enfA, 'Univers de test', ref);

  insert into missions
    (enfant_id, projet_moteur_id, objectif_id, matiere_code, titre, statut,
     genere_par_ia, auteur_id, valide_par, valide_le)
    select enfA, pm.id, obj, 'maths', 'Mission de test', 'validee',
           false, maths, maths, now()
    from projets_moteurs pm where pm.enfant_id = enfA
    returning id into miss;

  insert into exercices (mission_id, consigne) values (miss, 'Consigne de test')
    returning id into exo;

  insert into tentatives (exercice_id, enfant_id, reussie)
    values (exo, enfA, false);

  -- Un fil restreint entre les parents et l'enseignant de maths. Sans le
  -- référent : c'est le cas que 0014 devait rendre possible.
  insert into fils (enfant_id, portee, sujet, cree_par)
    values (enfA, 'restreint', 'Conversation privee', p1)
    returning id into fil_prive;
  insert into fils_participants (fil_id, profil_id) values (fil_prive, p2);
  insert into fils_participants (fil_id, profil_id) values (fil_prive, maths);
  insert into messages (fil_id, auteur_id, corps)
    values (fil_prive, p1, 'Message prive de test');

  raise notice 'Decor en place.';
end
$bloc$;

-- ===========================================================================
-- Les assertions
--
-- Chacune se fait passer pour quelqu'un, compte ce qu'il voit, et compare.
-- ===========================================================================

do $bloc$
declare
  r record;
  n bigint;
  enfA uuid; enfB uuid;
  p1 uuid; p2 uuid; ref uuid; maths uuid; histoire uuid;
  aesh uuid; admin uuid; tiers uuid; compte_enfant uuid;
  obj uuid; erreur text;

  -- Se faire passer pour quelqu'un, le temps des requêtes qui suivent.
  procedure_bidon boolean;
begin
  select id into p1 from profils where email = 'parent1@test.xylou';
  select id into p2 from profils where email = 'parent2@test.xylou';
  select id into ref from profils where email = 'referent@test.xylou';
  select id into maths from profils where email = 'maths@test.xylou';
  select id into histoire from profils where email = 'histoire@test.xylou';
  select id into aesh from profils where email = 'aesh@test.xylou';
  select id into admin from profils where email = 'admin@test.xylou';
  select id into tiers from profils where email = 'tiers@test.xylou';
  select id into compte_enfant from profils where email = 'enfant@test.xylou';
  select id into enfA from enfants where prenom = 'Enfant A';
  select id into enfB from enfants where prenom = 'Enfant B';
  select id into obj from objectifs where libelle = 'Objectif de test';

  -- =====================================================================
  -- 0. Avant le consentement
  --
  -- Le decor a ete monte sans qu'aucun parent ait signe. C'est l'etat d'un
  -- dossier qu'on vient d'ouvrir, et 0051 veut qu'il soit inerte pour l'equipe.
  -- =====================================================================
  perform set_config('request.jwt.claims',
    json_build_object('sub', maths, 'email', 'maths@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from objectifs;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Consentement', 'Sans signature, l''enseignant lit les objectifs', '0', n::text, n = 0);

  select count(*) into n from missions;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Consentement', 'Sans signature, l''enseignant lit les missions', '0', n::text, n = 0);

  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', p1, 'email', 'parent1@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from objectifs;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Consentement', 'Sans signature, le parent lit quand meme son dossier', '2', n::text, n = 2);

  -- Les deux titulaires signent. Le referent aussi, pour les objectifs de
  -- matiere ou il fait partie du quorum.
  perform signer_les_consentements(
    enfA,
    array['traitement_donnees_sante','partage_equipe_pedagogique',
          'generation_ia','conservation_historique']::type_consentement[],
    'Parent Un');

  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', p2, 'email', 'parent2@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  perform signer_les_consentements(
    enfA,
    array['traitement_donnees_sante','partage_equipe_pedagogique',
          'generation_ia','conservation_historique']::type_consentement[],
    'Parent Deux');

  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', maths, 'email', 'maths@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from objectifs;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Consentement', 'Apres signature des deux parents, l''enseignant voit', '1', n::text, n = 1);

  -- =====================================================================
  -- 1. Les données de santé
  -- =====================================================================

  select count(*) into n from enfants_sante;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Sante', 'Un enseignant lit le diagnostic', '0', n::text, n = 0);

  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', aesh, 'email', 'aesh@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from enfants_sante;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Sante', 'Une AESH lit le diagnostic', '0', n::text, n = 0);

  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', compte_enfant, 'email', 'enfant@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from enfants_sante;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Sante', 'L''enfant lit son propre diagnostic', '0', n::text, n = 0);

  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', p1, 'email', 'parent1@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from enfants_sante;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Sante', 'Un parent lit le diagnostic', '1', n::text, n = 1);

  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', ref, 'email', 'referent@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from enfants_sante;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Sante', 'Le referent lit le diagnostic', '1', n::text, n = 1);

  -- =====================================================================
  -- 2. Le cloisonnement par matière
  -- =====================================================================
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', histoire, 'email', 'histoire@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from tentatives;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Matiere', 'Le prof d''histoire lit les tentatives de maths', '0', n::text, n = 0);

  select count(*) into n from objectifs;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Matiere', 'Le prof d''histoire lit les objectifs (lecture large voulue)', '1', n::text, n = 1);

  select count(*) into n from missions;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Matiere', 'Le prof d''histoire lit les missions (lecture large voulue)', '1', n::text, n = 1);

  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', maths, 'email', 'maths@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from tentatives;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Matiere', 'Le prof de maths lit les tentatives de sa mission', '1', n::text, n = 1);

  -- Écriture hors de sa matière
  begin
    insert into objectifs (enfant_id, matiere_code, libelle, propose_par, granularite)
      values (enfA, 'histoire_geo', 'Objectif hors matiere', maths, 'large');
    insert into resultats (domaine, cas, attendu, obtenu, ok) values
      ('Matiere', 'Le prof de maths propose un objectif d''histoire', 'refus', 'accepte', false);
  exception when others then
    insert into resultats (domaine, cas, attendu, obtenu, ok) values
      ('Matiere', 'Le prof de maths propose un objectif d''histoire', 'refus', 'refus', true);
  end;

  -- =====================================================================
  -- 3. L'étanchéité entre dossiers
  -- =====================================================================
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', tiers, 'email', 'tiers@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from enfants where prenom = 'Enfant A';
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Etancheite', 'Le referent de B lit la fiche de A', '0', n::text, n = 0);

  select count(*) into n from objectifs;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Etancheite', 'Le referent de B lit les objectifs de A', '0', n::text, n = 0);

  select count(*) into n from tentatives;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Etancheite', 'Le referent de B lit les tentatives de A', '0', n::text, n = 0);

  select count(*) into n from enfants_sante;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Etancheite', 'Le referent de B lit la sante de A', '0', n::text, n = 0);

  -- =====================================================================
  -- 4. Les fils restreints
  -- =====================================================================
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', ref, 'email', 'referent@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from messages;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Echanges', 'Le referent lit un fil restreint dont il est absent', '0', n::text, n = 0);

  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', histoire, 'email', 'histoire@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from messages;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Echanges', 'Un enseignant tiers lit un fil restreint', '0', n::text, n = 0);

  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', maths, 'email', 'maths@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from messages;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Echanges', 'Le participant lit le fil restreint', '1', n::text, n = 1);

  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', compte_enfant, 'email', 'enfant@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from messages;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Echanges', 'L''enfant lit les conversations d''adultes', '0', n::text, n = 0);

  -- =====================================================================
  -- 5. Le compte enfant
  -- =====================================================================
  select count(*) into n from missions;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Enfant', 'L''enfant voit sa mission validee', '1', n::text, n = 1);

  select count(*) into n from alertes_difficulte;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Enfant', 'L''enfant lit les alertes ecrites sur lui', '0', n::text, n = 0);

  select count(*) into n from journal_acces;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Enfant', 'L''enfant lit le journal des acces', '0', n::text, n = 0);

  select count(*) into n from objectifs_demandes;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Enfant', 'L''enfant lit les desaccords entre adultes', '0', n::text, n = 0);

  -- =====================================================================
  -- 6. L'administration
  -- =====================================================================
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', admin, 'email', 'admin@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from enfants;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Admin', 'L''admin voit la liste des dossiers', '2', n::text, n = 2);

  select count(*) into n from objectifs;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Admin', 'L''admin lit le contenu d''un dossier', '0', n::text, n = 0);

  select count(*) into n from enfants_sante;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Admin', 'L''admin lit les donnees de sante', '0', n::text, n = 0);

  select count(*) into n from messages;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Admin', 'L''admin lit les echanges', '0', n::text, n = 0);

  select count(*) into n from tentatives;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Admin', 'L''admin lit les copies', '0', n::text, n = 0);

  -- =====================================================================
  -- 7. Le quorum de validation
  -- =====================================================================
  perform set_config('role', 'postgres', true);

  -- Un objectif signé par un seul parent alors qu'il en faut deux.
  declare
    obj2 uuid;
  begin
    insert into objectifs (enfant_id, matiere_code, libelle, propose_par, granularite)
      values (enfA, 'maths', 'Objectif quorum', maths, 'large')
      returning id into obj2;

    perform set_config('request.jwt.claims',
      json_build_object('sub', p1, 'email', 'parent1@test.xylou')::text, true);
    perform set_config('role', 'authenticated', true);

    insert into objectifs_validations (objectif_id, profil_id) values (obj2, p1);

    perform set_config('role', 'postgres', true);
    select statut::text into erreur from objectifs where id = obj2;

    insert into resultats (domaine, cas, attendu, obtenu, ok) values
      ('Quorum', 'Un parent seul valide en garde alternee', 'propose', erreur, erreur = 'propose');

    -- Forcer le statut doit être refusé
    begin
      update objectifs set statut = 'valide', valide_par = p1, valide_le = now()
        where id = obj2;
      insert into resultats (domaine, cas, attendu, obtenu, ok) values
        ('Quorum', 'Forcer le statut sans le quorum', 'refus', 'accepte', false);
    exception when others then
      insert into resultats (domaine, cas, attendu, obtenu, ok) values
        ('Quorum', 'Forcer le statut sans le quorum', 'refus', 'refus', true);
    end;
  end;

  -- L'objectif complet, lui, est bien passé à validé.
  select statut::text into erreur from objectifs where id = obj;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Quorum', 'Objectif signe par les deux parents et le referent', 'valide', erreur, erreur = 'valide');

  -- =====================================================================
  -- 8. Le lien parental
  -- =====================================================================
  perform set_config('request.jwt.claims',
    json_build_object('sub', p1, 'email', 'parent1@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  begin
    delete from intervenants_enfant where enfant_id = enfA and profil_id = p2;
    insert into resultats (domaine, cas, attendu, obtenu, ok) values
      ('Autorite', 'Un parent retire l''autre', 'refus', 'accepte', false);
  exception when others then
    insert into resultats (domaine, cas, attendu, obtenu, ok) values
      ('Autorite', 'Un parent retire l''autre', 'refus', 'refus', true);
  end;

  begin
    update enfants set titulaires_autorite_parentale = 1 where id = enfA;
    insert into resultats (domaine, cas, attendu, obtenu, ok) values
      ('Autorite', 'Un parent declare la composition parentale', 'refus', 'accepte', false);
  exception when others then
    insert into resultats (domaine, cas, attendu, obtenu, ok) values
      ('Autorite', 'Un parent declare la composition parentale', 'refus', 'refus', true);
  end;

  -- =====================================================================
  -- 9. Le parent lit, il ne redige pas (0047 a 0050)
  -- =====================================================================
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', p1, 'email', 'parent1@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  begin
    update objectifs set libelle = 'Reecrit par un parent' where id = obj;
    insert into resultats (domaine, cas, attendu, obtenu, ok) values
      ('Parent', 'Un parent reecrit un objectif valide', 'refus', 'accepte', false);
  exception when others then
    insert into resultats (domaine, cas, attendu, obtenu, ok) values
      ('Parent', 'Un parent reecrit un objectif valide', 'refus', 'refus', true);
  end;

  begin
    update objectifs set exercices_vises = 42 where id = obj;
    insert into resultats (domaine, cas, attendu, obtenu, ok) values
      ('Parent', 'Un parent regle le nombre d''exercices', 'refus', 'accepte', false);
  exception when others then
    insert into resultats (domaine, cas, attendu, obtenu, ok) values
      ('Parent', 'Un parent regle le nombre d''exercices', 'refus', 'refus', true);
  end;

  begin
    insert into exercices (mission_id, consigne)
      values (miss, 'Exercice compose par un parent');
    insert into resultats (domaine, cas, attendu, obtenu, ok) values
      ('Parent', 'Un parent compose un exercice', 'refus', 'accepte', false);
  exception when others then
    insert into resultats (domaine, cas, attendu, obtenu, ok) values
      ('Parent', 'Un parent compose un exercice', 'refus', 'refus', true);
  end;

  begin
    insert into notations (mission_id, bareme, note, note_par)
      values (miss, 20, 18, p1);
    insert into resultats (domaine, cas, attendu, obtenu, ok) values
      ('Parent', 'Un parent note la copie de son enfant', 'refus', 'accepte', false);
  exception when others then
    insert into resultats (domaine, cas, attendu, obtenu, ok) values
      ('Parent', 'Un parent note la copie de son enfant', 'refus', 'refus', true);
  end;

  -- =====================================================================
  -- 10. Le devoir du soir (0049, 0050)
  -- =====================================================================
  declare
    v_dev uuid;
    v_exo_dev uuid;
  begin
    begin
      insert into missions
        (enfant_id, projet_moteur_id, objectif_id, matiere_code, titre,
         statut, genere_par_ia, nature, tentatives_max, auteur_id, fourni_par)
      select enfA, pm.id, obj, 'maths', 'Devoir du soir',
             'proposee', false, 'devoir', null, p1, maths
      from projets_moteurs pm where pm.enfant_id = enfA
      returning id into v_dev;

      insert into exercices (mission_id, consigne)
        values (v_dev, 'Exercice recopie du cahier de textes')
        returning id into v_exo_dev;

      insert into tentatives (exercice_id, enfant_id, reussie)
        values (v_exo_dev, enfA, true);

      insert into resultats (domaine, cas, attendu, obtenu, ok) values
        ('Devoir', 'Un parent saisit un devoir et ses exercices', 'accepte', 'accepte', true);
    exception when others then
      insert into resultats (domaine, cas, attendu, obtenu, ok) values
        ('Devoir', 'Un parent saisit un devoir et ses exercices', 'accepte',
         'refus : ' || sqlerrm, false);
    end;

    -- Le professeur qui a donne le devoir doit en voir la copie, alors qu'il
    -- n'est ni l'auteur de la saisie ni le proposant de l'objectif.
    if v_exo_dev is not null then
      perform set_config('role', 'postgres', true);
      perform set_config('request.jwt.claims',
        json_build_object('sub', maths, 'email', 'maths@test.xylou')::text, true);
      perform set_config('role', 'authenticated', true);

      select count(*) into n from tentatives where exercice_id = v_exo_dev;
      insert into resultats (domaine, cas, attendu, obtenu, ok) values
        ('Devoir', 'Le professeur voit la copie du devoir qu''il a donne', '1', n::text, n = 1);

      perform set_config('role', 'postgres', true);
      perform set_config('request.jwt.claims',
        json_build_object('sub', histoire, 'email', 'histoire@test.xylou')::text, true);
      perform set_config('role', 'authenticated', true);

      select count(*) into n from tentatives where exercice_id = v_exo_dev;
      insert into resultats (domaine, cas, attendu, obtenu, ok) values
        ('Devoir', 'Le professeur d''histoire voit la copie du devoir de maths', '0', n::text, n = 0);
    end if;
  end;

  -- Les pieces ont-elles ete attribuees pour l'exercice reussi ?
  perform set_config('role', 'postgres', true);
  select count(*) into n from pieces_gagnees where enfant_id = enfA and source = 'exercice';
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Pieces', 'Une reussite attribue des pieces', '1', n::text, n = 1);

  -- =====================================================================
  -- 11. L'archivage
  -- =====================================================================
  perform set_config('role', 'postgres', true);
  perform archiver_le_dossier(enfA, 'Test d''archivage');

  perform set_config('request.jwt.claims',
    json_build_object('sub', maths, 'email', 'maths@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from objectifs;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Archivage', 'Un enseignant lit un dossier archive', '0', n::text, n = 0);

  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', p1, 'email', 'parent1@test.xylou')::text, true);
  perform set_config('role', 'authenticated', true);

  select count(*) into n from enfants where id = enfA;
  insert into resultats (domaine, cas, attendu, obtenu, ok) values
    ('Archivage', 'Un parent lit un dossier archive', '0', n::text, n = 0);

  perform set_config('role', 'postgres', true);
end
$bloc$;

-- ===========================================================================
-- Le rapport
-- ===========================================================================

select
  case when ok then 'OK' else '>>> ECHEC' end as etat,
  domaine, cas, attendu, obtenu
from resultats
order by ok, rang;

select
  count(*) filter (where ok) as reussites,
  count(*) filter (where not ok) as echecs,
  count(*) as total
from resultats;

-- ===========================================================================
-- Nettoyage
--
-- Actif par défaut, et il vaut mieux. Des données de test laissées en base
-- vieillissent mal : elles ont été créées sous les règles d'un jour donné, et
-- la migration du lendemain les trouve invalides — c'est ce qui a fait échouer
-- 0055 sur un dossier de test sans parent.
--
-- Pour inspecter à la main ce qui a échoué, commentez ces trois lignes le temps
-- de votre analyse, puis relancez le script en entier pour nettoyer.
--
-- L'ordre compte, et il est contre-intuitif. Beaucoup de clés étrangères vers
-- `profils` sont en `on delete restrict` — volontairement : on ne perd pas la
-- trace de qui a écrit un message ou déposé un document. Supprimer les comptes
-- en premier échoue donc tant que leurs dossiers existent.
--
-- Et supprimer un enfant échoue tant que ses deux parents y sont rattachés
-- (0024). D'où le détachement préalable : la contrainte « un enfant garde au
-- moins un parent » est différée, elle se vérifie en fin de transaction, quand
-- l'enfant a lui-même disparu.
-- ===========================================================================

delete from intervenants_enfant
  where enfant_id in (select id from enfants where prenom in ('Enfant A', 'Enfant B'));

delete from enfants where prenom in ('Enfant A', 'Enfant B');

delete from auth.users where email like '%@test.xylou';
