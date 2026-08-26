-- 0002 — Le projet moteur : l'univers dans lequel l'enfant apprend.
--
-- C'est la pièce qui distingue Xylou d'un cahier d'exercices en ligne. Pour
-- Xylan c'est le jeu vidéo ; pour un autre enfant ce sera les trains, un dessin
-- animé, un livre. Tout ce que l'enfant voit à l'écran est reformulé dans ce
-- vocabulaire-là, d'où la colonne `lexique`.

create table centres_interet (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  libelle text not null,
  -- 1 = ça lui plaît, 5 = c'est son sujet. Sert à choisir sur quoi accrocher un
  -- exercice quand l'enfant décroche, pas à classer l'enfant.
  intensite smallint not null default 3 check (intensite between 1 and 5),
  note text not null default '',
  cree_le timestamptz not null default now()
);

create index centres_interet_enfant_idx on centres_interet (enfant_id);

create type univers_moteur as enum (
  'jeu_video', 'dessin_anime', 'livre', 'animaux', 'transports',
  'espace', 'sport', 'musique', 'autre'
);

create table projets_moteurs (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  titre text not null,
  univers univers_moteur not null default 'autre',
  description text not null default '',

  -- Comment nommer les choses dans cet univers. Un enfant qui joue à un
  -- jeu de construction ne fait pas des « exercices », il relève des « défis » ;
  -- un enfant passionné de trains ne gagne pas des « points », il ouvre des
  -- « lignes ». Les clés sont fixes, les valeurs appartiennent à l'enfant.
  -- Clés attendues : mission, missions, recompense, recompenses, point, points,
  -- niveau, indice, reussite.
  lexique jsonb not null default '{}'::jsonb,

  actif boolean not null default true,
  cree_par uuid not null references profils on delete restrict,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now()
);

create trigger projets_moteurs_touch
  before update on projets_moteurs
  for each row execute function touch_modifie_le();

-- Un seul univers actif à la fois : deux fils rouges simultanés, c'est deux fils
-- rouges qu'on ne suit pas.
create unique index projets_moteurs_un_seul_actif
  on projets_moteurs (enfant_id) where actif;

create table recompenses (
  id uuid primary key default gen_random_uuid(),
  projet_moteur_id uuid not null references projets_moteurs on delete cascade,
  libelle text not null,
  description text not null default '',
  cout_points integer not null default 10 check (cout_points >= 0),
  image_chemin text,
  ordre smallint not null default 0,
  cree_le timestamptz not null default now()
);

create index recompenses_projet_idx on recompenses (projet_moteur_id);
