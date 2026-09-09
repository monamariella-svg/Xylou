-- 0069 — Ce qu'il faut savoir de l'enfant avant de mesurer son niveau.
--
-- Le bilan de positionnement (0004) mesure des savoirs scolaires. Posé sans
-- précaution à un enfant autiste, il mesure autre chose : une consigne
-- ambiguë, un énoncé qui demande de deviner une intention, un format qui exige
-- de rédiger quand l'enfant sait mais n'écrit pas. La réponse est fausse, et
-- l'enfant en conclut qu'il est nul — c'est le risque nommé au §3.4, et il ne
-- se corrige pas après coup.
--
-- Il manquait donc ce qui vient avant : un questionnaire d'observation, adossé
-- au GEVA-Sco et au PPS, qui ne dit pas ce que l'enfant sait mais **comment lui
-- poser les questions**.
--
-- ---------------------------------------------------------------------------
-- DEUX BILANS QUI NE SE CONFONDENT PAS
--
--   bilans_positionnement (0004)  — le niveau scolaire, matière par matière.
--   observations_capacites (ici)  — comment l'enfant fonctionne, et donc
--                                   comment l'interroger.
--
-- Le second sert à régler le premier. Il ne le remplace jamais, et surtout il
-- ne s'ajoute jamais à ses résultats.
--
-- ---------------------------------------------------------------------------
-- POURQUOI `direction` EST LA COLONNE LA PLUS IMPORTANTE DU FICHIER
--
-- Chaque item du formulaire porte une direction :
--
--   capacity     une compétence — une valeur haute est un appui ;
--   difficulty   une difficulté fonctionnelle — valeur haute, score inversé ;
--   need         un besoin d'aménagement — n'entre dans aucun score, alimente
--                les adaptations ;
--   descriptive  une particularité neutre — profil sensoriel, intérêt
--                spécifique, aménagement existant. **Jamais scorée**, ni en
--                bien ni en mal.
--
-- Sans cette distinction, « réagit fortement aux bruits » deviendrait un point
-- négatif : on aurait enregistré une particularité comme un déficit. La
-- convention du projet l'interdit — on mesure un niveau, on ne note pas un
-- écart à une norme.
--
-- Conséquence à tenir dans l'interface : deux domaines n'ont aucun item scoré
-- (`sensoriel`, `environnement_amenagements`). Ils n'ont pas de score, et
-- afficher 0 s'y lirait comme un jugement. Ils se présentent en contexte.

create type direction_item as enum ('capacity', 'difficulty', 'need', 'descriptive');

-- --------------------------------------------------- le formulaire, versionné

-- Même logique que `textes_consentement` : une version publiée ne se modifie
-- jamais. Les réponses déjà recueillies restent lisibles avec le formulaire qui
-- a servi à les recueillir — sinon un item reformulé changerait rétroactivement
-- le sens de ce qu'une famille a répondu il y a six mois.
create table questionnaires_capacites (
  id uuid primary key default gen_random_uuid(),
  code text not null default 'xylou_bilan_capacites',
  version text not null,

  -- Le formulaire entier : domaines, items, directions, poids, échelle.
  -- En jsonb et non en tables : les items changeront plus souvent que le
  -- schéma, et une correction de libellé ne doit pas demander une migration.
  contenu jsonb not null,

  publie_le timestamptz,
  courant boolean not null default false,
  cree_par uuid references profils on delete set null,
  cree_le timestamptz not null default now(),

  unique (code, version)
);

-- Un seul formulaire courant à la fois : deux versions courantes produiraient
-- deux questionnaires selon l'écran par lequel on est passé.
create unique index questionnaires_un_seul_courant
  on questionnaires_capacites (code) where courant;

-- ------------------------------------------------------------ une observation

-- Un remplissage, à une date, par une personne. Répétable : c'est ce qui
-- permet de suivre l'évolution, là où un diagnostic est une photo figée.
create table observations_capacites (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  questionnaire_id uuid not null references questionnaires_capacites on delete restrict,

  rempli_par uuid references profils on delete set null,
  -- Le rôle au moment du remplissage, recopié : quelqu'un peut changer de rôle
  -- ou quitter l'équipe, et « qui a dit ça » doit rester lisible ensuite.
  role_au_moment role_intervenant,

  statut text not null default 'brouillon'
    check (statut in ('brouillon', 'complete')),

  -- Réponses aux `synthesis_fields` — texte libre, dont le récit d'une
  -- évaluation qui s'est mal passée. C'est la réponse la plus utile du
  -- questionnaire, et aucune case à cocher ne la remplace.
  synthese jsonb not null default '{}'::jsonb,

  rempli_le timestamptz not null default now(),
  modifie_le timestamptz not null default now()
);

create trigger observations_capacites_touch
  before update on observations_capacites
  for each row execute function touch_modifie_le();

create index observations_capacites_enfant_idx
  on observations_capacites (enfant_id, rempli_le desc);

create table observations_reponses (
  id uuid primary key default gen_random_uuid(),
  observation_id uuid not null references observations_capacites on delete cascade,
  item_code text not null,

  -- 0 à 3 sur l'échelle de fréquence. NULL = « pas encore observé », et ce
  -- n'est pas un trou à combler : une famille qui vient d'arriver n'a pas tout
  -- vu, et forcer une réponse fabriquerait la donnée sur laquelle le bilan
  -- serait ensuite calibré.
  valeur smallint check (valeur between 0 and 3),
  note text not null default '',

  unique (observation_id, item_code)
);

-- ------------------------------------------------------- le diagnostic déposé

-- La seconde source, quand elle existe : bilan neuropsychologique, CRA,
-- pluridisciplinaire. Plus riche que l'observation, mais figée à sa date.
create table documents_diagnostic (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,

  nature text not null default 'autre'
    check (nature in ('diagnostic_autisme', 'bilan_pluridisciplinaire', 'autre')),
  chemin text not null,
  nom_fichier text not null default '',

  depose_par uuid references profils on delete set null,
  depose_le timestamptz not null default now(),

  -- Sortie structurée de la lecture par le modèle, sur les mêmes domaines que
  -- le questionnaire, pour que les deux sources soient comparables.
  profil_extrait jsonb,
  extraction_statut text not null default 'en_attente'
    check (extraction_statut in ('en_attente', 'faite', 'echec')),

  -- Rien n'alimente le profil de l'enfant tant qu'un humain n'a pas relu.
  -- Règle du projet : aucune sortie de modèle n'est appliquée sans validation.
  validee_par uuid references profils on delete set null,
  validee_le timestamptz,

  -- Donnée de santé : la conservation se revoit, elle ne s'oublie pas.
  revue_conservation_le date,

  constraint extraction_validee_a_un_validateur
    check ((validee_le is null) = (validee_par is null))
);

create index documents_diagnostic_enfant_idx
  on documents_diagnostic (enfant_id, depose_le desc);

-- ==================================================================== RLS

alter table questionnaires_capacites enable row level security;
alter table observations_capacites   enable row level security;
alter table observations_reponses    enable row level security;
alter table documents_diagnostic     enable row level security;

-- Le formulaire est le même pour tout le monde : il ne porte aucune donnée
-- d'enfant. Seule l'administration le fait évoluer.
create policy questionnaires_lecture on questionnaires_capacites
  for select to authenticated using (true);

create policy questionnaires_administration on questionnaires_capacites
  for all to authenticated using (est_admin()) with check (est_admin());

-- L'observation se lit et s'écrit par l'équipe : un enseignant qui voit
-- l'enfant en classe observe ce qu'un parent ne voit pas, et l'inverse.
create policy observations_lecture on observations_capacites
  for select to authenticated using (est_intervenant(enfant_id));

create policy observations_creation on observations_capacites
  for insert to authenticated
  with check (est_intervenant(enfant_id) and rempli_par = auth.uid());

-- On corrige ce qu'on a rempli, pas ce qu'un autre a observé. Deux réponses
-- divergentes sont une information — un parent et un enseignant peuvent
-- constater des choses différentes de bonne foi — et les écraser la perdrait.
create policy observations_correction on observations_capacites
  for update to authenticated
  using (rempli_par = auth.uid()) with check (rempli_par = auth.uid());

create policy reponses_lecture on observations_reponses
  for select to authenticated using (
    exists (
      select 1 from observations_capacites o
      where o.id = observation_id and est_intervenant(o.enfant_id)
    )
  );

create policy reponses_ecriture on observations_reponses
  for all to authenticated using (
    exists (
      select 1 from observations_capacites o
      where o.id = observation_id and o.rempli_par = auth.uid()
    )
  ) with check (
    exists (
      select 1 from observations_capacites o
      where o.id = observation_id and o.rempli_par = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- LE DIAGNOSTIC EST PLUS FERMÉ QUE LE RESTE DU DOSSIER
--
-- Partout ailleurs, l'équipe entière voit ce qui concerne l'enfant. Pas ici :
-- un bilan neuropsychologique est une donnée de santé au sens de l'article 9,
-- et il dit sur un enfant bien plus que ce qu'un enseignant a besoin de savoir
-- pour adapter un exercice. Ce dont l'équipe a besoin, c'est du profil qui en
-- est extrait — pas de la pièce.
--
-- Les titulaires de l'autorité parentale et le référent, donc, et personne
-- d'autre. Pas même l'administration de la plateforme.
create policy diagnostic_lecture on documents_diagnostic
  for select to authenticated
  using (est_intervenant(enfant_id, array['parent', 'referent']::role_intervenant[]));

create policy diagnostic_depot on documents_diagnostic
  for insert to authenticated
  with check (
    est_intervenant(enfant_id, array['parent', 'referent']::role_intervenant[])
    and depose_par = auth.uid()
  );

create policy diagnostic_maj on documents_diagnostic
  for update to authenticated
  using (est_intervenant(enfant_id, array['parent', 'referent']::role_intervenant[]))
  with check (est_intervenant(enfant_id, array['parent', 'referent']::role_intervenant[]));

create policy diagnostic_retrait on documents_diagnostic
  for delete to authenticated
  using (est_intervenant(enfant_id, array['parent', 'referent']::role_intervenant[]));

-- ==================================================== ce qui reste à faire
--
-- Le bucket de stockage du diagnostic n'est pas créé ici : il suit les
-- conventions de 0010 et se déclare avec ses propres politiques, dans une
-- migration dédiée, une fois tranché s'il rejoint un bucket existant ou non.
--
-- La fusion des deux sources (diagnostic prioritaire là où il couvre, complété
-- puis relayé par l'observation) n'est pas non plus ici : elle ne se décide
-- qu'une fois qu'on a vu passer de vraies divergences. La règle posée d'avance,
-- en revanche : une divergence se signale, elle ne se lisse pas.
