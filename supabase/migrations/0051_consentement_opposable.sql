-- 0051 — Le consentement devient opposable.
--
-- `consentements` existe depuis 0008, `consentement_actif()` est correcte depuis
-- 0037, et aucune politique ne l'appelle. La table se remplit, la signature se
-- conserve, et rien ne vérifie jamais qu'un consentement a été donné avant de
-- traiter les données de l'enfant.
--
-- C'est le défaut que j'ai reproché à trois reprises à d'autres colonnes de ce
-- schéma. Il traîne ici depuis quarante migrations.
--
-- ---------------------------------------------------------------------------
-- CE QUE ÇA CHANGE, ET IL FAUT LE MESURER
--
-- Après cette migration, un dossier sans consentement signé est inerte :
--
--   les enseignants et les accompagnants ne voient plus rien ;
--   aucun appel à l'IA ne peut être journalisé, donc aucun ne doit avoir lieu ;
--   aucune donnée de santé ne peut être enregistrée.
--
-- Ce n'est pas un durcissement gratuit : c'est l'ordre correct des opérations.
-- Le recueil du consentement devient la première étape de tout accompagnement,
-- avant même d'inviter l'équipe. L'interface doit le prévoir, sinon un référent
-- ouvrira un dossier, invitera trois enseignants, et personne ne comprendra
-- pourquoi ils voient une page vide.
--
-- La famille et le référent, eux, gardent tous leurs accès : ce sont eux qui
-- consentent, les enfermer dehors serait circulaire.
-- ---------------------------------------------------------------------------

-- ==================================================== les textes présentés

-- Sans texte publié, `consentements_a_signer()` ne renvoie rien et personne ne
-- peut signer : brancher la règle sans les écrire fermerait la porte à clé en
-- laissant la clé dedans.
--
-- Ce sont des textes de travail. Ils disent honnêtement ce que fait l'outil,
-- mais ils n'ont pas été relus par un juriste — voir les questions 1.1 à 1.7 du
-- document `docs/questions-juriste.md`. À reprendre avant le pilote, en
-- publiant une version 2 : celle-ci restera attachée aux signatures déjà
-- recueillies, ce qui est tout l'objet du versionnement de 0037.

insert into textes_consentement (type, version, titre, contenu, obligatoire) values
(
  'traitement_donnees_sante', 'v1-travail',
  'Les informations relatives au handicap de votre enfant',
  'Pour adapter l''accompagnement, Xylou enregistre les besoins particuliers de votre enfant, les aménagements dont il bénéficie et les suivis extérieurs dont vous nous informez.

Ces informations relèvent des données de santé. Elles sont conservées séparément du reste du dossier et ne sont accessibles qu''aux titulaires de l''autorité parentale et au référent qui suit votre enfant. Les enseignants, les accompagnants et l''administration n''y ont pas accès — ni maintenant, ni plus tard, ni en cas de litige.

Vous pouvez retirer ce consentement à tout moment. Les informations déjà enregistrées cessent alors d''être exploitées.',
  true
),
(
  'partage_equipe_pedagogique', 'v1-travail',
  'Ce que voit l''équipe qui accompagne votre enfant',
  'Les enseignants et les accompagnants rattachés au dossier voient ce qui leur permet d''accompagner votre enfant : ses objectifs, sa progression, les travaux proposés, et le suivi quotidien.

Un enseignant ne voit que sa propre matière pour ce qu''il écrit, et les copies des seuls travaux dont il est à l''origine. Il ne voit ni les informations de santé, ni vos échanges privés, ni les conversations auxquelles il n''est pas convié.

Sans ce consentement, aucun enseignant ni accompagnant ne peut accéder au dossier. Vous et le référent continuez d''y accéder normalement.',
  false
),
(
  'generation_ia', 'v1-travail',
  'Le recours à l''intelligence artificielle',
  'Xylou utilise un modèle d''intelligence artificielle pour transformer les exercices scolaires en missions adaptées aux centres d''intérêt de votre enfant, et pour proposer des contenus à partir des objectifs fixés par l''équipe.

Aucune proposition de l''IA n''atteint votre enfant sans qu''un adulte l''ait validée.

Le contenu des demandes envoyées au modèle n''est pas conservé : nous enregistrons seulement leur volume et leur coût, afin de suivre le budget et de détecter une baisse de qualité. Le prestataire du modèle est un sous-traitant, lié par contrat.

Sans ce consentement, l''outil fonctionne sans génération automatique : les exercices doivent alors être saisis à la main.',
  false
),
(
  'conservation_historique', 'v1-travail',
  'La durée de conservation du dossier',
  'Le dossier de votre enfant est conservé pendant toute la durée de l''accompagnement.

Vous pouvez le supprimer à tout moment. Il disparaît alors pour tout le monde — pour vous, pour l''équipe, pour l''administration. Les données sont ensuite conservées hors de toute consultation pendant la durée légale applicable, puis effacées définitivement.

Personne ne lit un dossier supprimé. Un accès resterait possible en cas de réquisition judiciaire ou de litige vous concernant : il serait alors motivé, limité dans le temps, et vous en seriez informé — sauf lorsque la loi l''interdit.',
  true
)
on conflict (type, version) do nothing;

-- ============================================ le partage avec l'équipe

-- Le point d'étranglement, une fois de plus : `est_intervenant()` gouverne
-- l'écrasante majorité des lectures, directement ou via `peut_valider()`.
--
-- La clause n'ajoute la condition que pour les rôles qui ne consentent pas. Un
-- parent et le référent passent toujours : sans quoi une famille qui n'a pas
-- encore signé ne pourrait pas atteindre l'écran où l'on signe.
create or replace function est_intervenant(p_enfant uuid, p_roles role_intervenant[] default null)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from intervenants_enfant i
    join enfants e on e.id = i.enfant_id
    where i.enfant_id = p_enfant
      and i.profil_id = auth.uid()
      and i.retire_le is null
      and e.archive_le is null
      and (p_roles is null or i.role = any (p_roles))
      and (
        i.role in ('parent', 'referent')
        or consentement_actif(p_enfant, 'partage_equipe_pedagogique')
      )
  );
$$;

-- Les fonctions d'écriture qui interrogent `intervenants_enfant` sans passer
-- par elle doivent porter la même condition, sinon un enseignant pourrait
-- écrire dans un dossier qu'il ne peut pas lire.
create or replace function matiere_ouverte_a_l_ecriture(p_enfant uuid, p_matiere text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from intervenants_enfant i
    join enfants e on e.id = i.enfant_id
    where i.enfant_id = p_enfant
      and i.profil_id = auth.uid()
      and i.retire_le is null
      and e.archive_le is null
      and (i.role <> 'enseignant' or intervenant_couvre(i.id, p_matiere))
      and (
        i.role in ('parent', 'referent')
        or consentement_actif(p_enfant, 'partage_equipe_pedagogique')
      )
  );
$$;

-- ==================================================== les données de santé

-- L'écriture seulement. Interdire la lecture à une famille qui n'aurait pas
-- signé la couperait de ce qu'elle a elle-même saisi ; interdire l'écriture
-- empêche d'enregistrer une donnée de santé sans base légale, ce qui est
-- exactement l'obligation.
drop policy enfants_sante_ecriture on enfants_sante;

create policy enfants_sante_lecture_famille on enfants_sante for select to authenticated
  using (peut_valider(enfant_id));

create policy enfants_sante_ecriture on enfants_sante for all to authenticated
  using (
    peut_valider(enfant_id)
    and consentement_actif(enfant_id, 'traitement_donnees_sante')
  )
  with check (
    peut_valider(enfant_id)
    and consentement_actif(enfant_id, 'traitement_donnees_sante')
  );

-- ==================================================== la génération par l'IA

-- Tout appel au modèle laisse une ligne dans `journal_ia` — c'est le §3.7 qui
-- l'impose pour le suivi du budget. Cette obligation devient le point de
-- contrôle : pas de journal, pas d'appel.
--
-- C'est plus sûr que de vérifier au moment de créer une mission. Une mission
-- peut naître de dix chemins différents, et il suffirait d'en oublier un. La
-- journalisation, elle, est unique et déjà obligatoire.
drop policy journal_ia_ecriture on journal_ia;

create policy journal_ia_ecriture on journal_ia for insert to authenticated
  with check (
    enfant_id is null
    or (
      est_intervenant(enfant_id)
      and consentement_actif(enfant_id, 'generation_ia')
    )
  );

-- ==================================================== savoir où l'on en est

-- L'écran que le référent regarde avant de s'étonner qu'une équipe ne voie
-- rien. Sans lui, le diagnostic d'un dossier inerte prendrait une heure.
create or replace function etat_des_consentements(p_enfant uuid)
returns table (
  type type_consentement,
  titre text,
  obligatoire boolean,
  titulaires_attendus smallint,
  titulaires_rattaches bigint,
  signatures bigint,
  actif boolean,
  manquants text
)
language sql stable security definer set search_path = public as $$
  select
    t.type,
    t.titre,
    t.obligatoire,
    e.titulaires_autorite_parentale,
    (select count(*) from intervenants_enfant i
      where i.enfant_id = p_enfant and i.role = 'parent' and i.retire_le is null),
    (select count(*) from consentements c
      where c.enfant_id = p_enfant and c.type = t.type
        and c.accorde and c.revoque_le is null),
    consentement_actif(p_enfant, t.type),
    coalesce((
      select string_agg(coalesce(p.prenom, p.email), ', ')
      from intervenants_enfant i
      join profils p on p.id = i.profil_id
      where i.enfant_id = p_enfant and i.role = 'parent' and i.retire_le is null
        and not exists (
          select 1 from consentements c
          where c.enfant_id = p_enfant and c.profil_id = i.profil_id
            and c.type = t.type and c.accorde and c.revoque_le is null
        )
    ), '')
  from textes_consentement t
  cross join enfants e
  where e.id = p_enfant
    and t.retire_le is null
    and est_intervenant(p_enfant, array['parent', 'referent']::role_intervenant[])
  order by t.obligatoire desc, t.type;
$$;
