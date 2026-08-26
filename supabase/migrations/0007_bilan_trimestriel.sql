-- 0007 — Le bilan trimestriel, « prêt à l'emploi pour les réunions
-- parents-professeurs » (§3.2).
--
-- C'est la contrepartie promise au parent en échange de son travail de
-- supervision : arriver à la réunion sans avoir rien reconstruit. Le document en
-- fait un livrable PDF, donc le schéma conserve à la fois les chiffres qui
-- permettent de le régénérer et le fichier tel qu'il a été présenté à l'école.

create type statut_bilan_trimestriel as enum ('brouillon', 'valide');

create table bilans_trimestriels (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  trimestre smallint not null check (trimestre between 1 and 3),
  annee_scolaire text not null default annee_scolaire_courante(),

  statut statut_bilan_trimestriel not null default 'brouillon',

  synthese_ia text not null default '',
  -- Ce que le parent ou le référent ajoute, corrige ou nuance. Ce texte prime
  -- sur la synthèse générée dans le PDF final.
  synthese_humaine text not null default '',

  modele_ia text,
  genere_le timestamptz not null default now(),

  valide_par uuid references profils on delete set null,
  valide_le timestamptz,
  -- Chemin du PDF figé dans le bucket `bilans` (voir 0010). Un bilan validé ne
  -- se régénère pas : c'est la pièce montrée à l'établissement.
  pdf_chemin text,

  modifie_le timestamptz not null default now(),
  unique (enfant_id, annee_scolaire, trimestre),

  constraint bilan_trimestriel_valide_a_un_validateur
    check (statut = 'brouillon' or (valide_par is not null and valide_le is not null))
);

create trigger bilans_trimestriels_touch
  before update on bilans_trimestriels
  for each row execute function touch_modifie_le();

create index bilans_trimestriels_enfant_idx
  on bilans_trimestriels (enfant_id, annee_scolaire, trimestre);

create table bilans_trimestriels_matieres (
  id uuid primary key default gen_random_uuid(),
  bilan_id uuid not null references bilans_trimestriels on delete cascade,
  matiere_code text not null references matieres on delete restrict,

  appuis text[] not null default '{}',
  fragilites text[] not null default '{}',
  commentaire text not null default '',

  -- Chiffres arrêtés à la génération. On les fige plutôt que de les recalculer
  -- à l'affichage : un bilan de novembre doit continuer à dire ce qu'il disait
  -- en novembre, même relu en juin.
  objectifs_atteints smallint not null default 0,
  objectifs_total smallint not null default 0,
  missions_reussies smallint not null default 0,
  reperes_progresses smallint not null default 0,

  unique (bilan_id, matiere_code)
);
