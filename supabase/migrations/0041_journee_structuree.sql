-- 0041 — La journée a une structure, pas seulement un récit.
--
-- 0039 posait la journée comme une page : une humeur, un texte, des médias, des
-- entrées d'adultes. C'est la moitié du besoin. Le planning de Malte montre
-- l'autre moitié, et elle est antérieure : **avant de raconter sa journée,
-- l'enfant a besoin de savoir de quoi elle sera faite**.
--
-- Quatre objets manquaient, tous présents dans ce document et tous absents ici :
--
--   les étapes      — la journée découpée en moments horodatés, cochables. Une
--                     journée en bloc est illisible ; une journée en cinq lignes
--                     se traverse.
--   les repères     — « ça va être bruyant », « temps calme », « plan B si le
--                     bateau ne sort pas ». C'est ce qui permet d'anticiper au
--                     lieu de subir, et pour un enfant autiste c'est la
--                     différence entre une journée difficile et une crise.
--   les préparatifs — ce qu'il faut emporter, coché la veille. Une charge
--                     mentale qu'on retire aux parents et une autonomie qu'on
--                     donne à l'enfant.
--   les périodes    — un séjour, une semaine, une hospitalisation. Une frise a
--                     besoin de bornes et d'un titre, sinon elle défile sans fin.
--
-- La leçon générale du document : ce n'est pas un journal, c'est un **repère**.
-- Le journal vient après, et il n'est utile que parce que le repère existait
-- avant.

-- ------------------------------------------------------------- les périodes

create type nature_periode as enum (
  'ordinaire',     -- une semaine de classe, sans particularité
  'sejour',        -- vacances, voyage, séjour chez l'autre parent
  'evenement',     -- déménagement, hospitalisation, examen
  'vacances',
  'transition'     -- changement d'établissement, arrivée d'un intervenant
);

create table periodes (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,

  titre text not null,
  sous_titre text not null default '',
  nature nature_periode not null default 'ordinaire',

  debut date not null,
  fin date not null,

  -- Ce qu'on veut que l'enfant retienne en tête de frise : trois phrases, pas
  -- un règlement. Dans le document de Malte, c'est « Trois choses à savoir ».
  a_savoir text not null default '',

  cree_par uuid not null references profils on delete restrict,
  cree_le timestamptz not null default now(),

  constraint periode_bornee check (fin >= debut)
);

create index periodes_enfant_idx on periodes (enfant_id, debut desc);

alter table journees
  add column periode_id uuid references periodes on delete set null,
  -- Le titre du jour et son résumé court : « 🚤 Le bateau dans les grottes
  -- bleues ». C'est ce que porte une tuile de frise, et ce que l'enfant lit en
  -- premier.
  add column titre text not null default '',
  add column resume text not null default '',
  add column emoji text not null default '';

create index journees_periode_idx on journees (periode_id, jour);

-- ------------------------------------------------------------- les étapes

create table journee_etapes (
  id uuid primary key default gen_random_uuid(),
  journee_id uuid not null references journees on delete cascade,

  ordre smallint not null default 0,
  -- Texte libre et non `time` : « Matin », « Soir », « 8h00 » disent tous
  -- quelque chose d'utile, et exiger une heure exacte obligerait à en inventer.
  heure text not null default '',
  intitule text not null,
  detail text not null default '',

  -- L'enfant coche à mesure. C'est lui qui coche, et personne d'autre : voir
  -- la journée avancer sous sa main est le point de la chose.
  faite_le timestamptz,

  cree_le timestamptz not null default now()
);

create index journee_etapes_idx on journee_etapes (journee_id, ordre);

-- ------------------------------------------------------------- les repères

-- Les quatre encadrés du planning de Malte, tels quels. Ils ne décrivent pas ce
-- qu'on fait mais comment ça va se passer — et c'est cette information-là qui
-- manque partout ailleurs.
create type type_repere_jour as enum (
  'bruit',        -- 🔊 ça va être bruyant, prends ton casque
  'calme',        -- 😌 rien de prévu, c'est voulu
  'plan_b',       -- ⭐ si ça n'a pas lieu, voilà ce qu'on fait à la place
  'attention',    -- foule, chaleur, attente longue
  'repere'        -- une information qui rassure : durée, trajet, qui sera là
);

create table journee_reperes (
  id uuid primary key default gen_random_uuid(),
  journee_id uuid not null references journees on delete cascade,
  etape_id uuid references journee_etapes on delete cascade,

  type type_repere_jour not null,
  texte text not null,
  ordre smallint not null default 0,

  cree_par uuid not null references profils on delete restrict,
  cree_le timestamptz not null default now()
);

create index journee_reperes_idx on journee_reperes (journee_id, ordre);

-- ---------------------------------------------------------- les préparatifs

create table journee_preparatifs (
  id uuid primary key default gen_random_uuid(),
  journee_id uuid not null references journees on delete cascade,

  libelle text not null,
  note text not null default '',
  -- « Ma gourde », « Mon casque anti-bruit » : ce qui, oublié, gâche la journée.
  essentiel boolean not null default false,
  ordre smallint not null default 0,

  coche_le timestamptz,
  coche_par uuid references profils on delete set null
);

create index journee_preparatifs_idx on journee_preparatifs (journee_id, ordre);

-- Ce qu'on emporte tous les jours, et qu'on ne veut pas ressaisir. Recopié dans
-- chaque journée à sa création, plutôt que joint à la lecture : une liste de
-- base qui change en janvier ne doit pas réécrire les journées de décembre.
create table preparatifs_recurrents (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  libelle text not null,
  note text not null default '',
  essentiel boolean not null default false,
  ordre smallint not null default 0,
  actif boolean not null default true
);

create index preparatifs_recurrents_idx
  on preparatifs_recurrents (enfant_id, ordre) where actif;

create or replace function garnir_les_preparatifs()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into journee_preparatifs (journee_id, libelle, note, essentiel, ordre)
  select new.id, r.libelle, r.note, r.essentiel, r.ordre
  from preparatifs_recurrents r
  where r.enfant_id = new.enfant_id and r.actif;
  return new;
end;
$$;

create trigger journees_garnissent_les_preparatifs
  after insert on journees
  for each row execute function garnir_les_preparatifs();

-- ------------------------------------------------------------- les amorces

-- « Aujourd'hui, on a… », « Le meilleur moment, c'était… ». Un enfant devant un
-- champ vide n'écrit rien ; devant un début de phrase, il continue. Elles sont
-- en base et non dans le code parce qu'elles doivent s'adapter : ce qui aide
-- Xylan n'aidera pas l'enfant suivant, et c'est au référent d'en juger.
create table amorces_ecriture (
  id uuid primary key default gen_random_uuid(),
  -- Nul pour les amorces communes, servies à tous par défaut.
  enfant_id uuid references enfants on delete cascade,
  contexte text not null,          -- 'recit', 'aime', 'moins_aime', 'bilan'
  texte text not null,
  ordre smallint not null default 0,
  actif boolean not null default true
);

create index amorces_contexte_idx on amorces_ecriture (contexte, ordre) where actif;

insert into amorces_ecriture (contexte, texte, ordre) values
  ('recit', 'Aujourd''hui, on a ', 1),
  ('recit', 'Ce matin, ', 2),
  ('recit', 'Je suis allé ', 3),
  ('aime', 'Le meilleur moment, c''était ', 1),
  ('aime', 'J''ai bien aimé quand ', 2),
  ('aime', 'Ça m''a surpris de ', 3),
  ('moins_aime', 'Ce qui était difficile, c''était ', 1),
  ('moins_aime', 'Il y avait trop de ', 2),
  ('moins_aime', 'Je n''ai pas aimé ', 3);

-- ==================================================================== RLS

alter table periodes               enable row level security;
alter table journee_etapes         enable row level security;
alter table journee_reperes        enable row level security;
alter table journee_preparatifs    enable row level security;
alter table preparatifs_recurrents enable row level security;
alter table amorces_ecriture       enable row level security;

create policy periodes_lecture on periodes for select to authenticated
  using (est_intervenant(enfant_id) or est_l_enfant(enfant_id));

create policy periodes_ecriture on periodes for all to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));

-- Les étapes, repères et préparatifs se lisent par tout le monde : c'est leur
-- raison d'être. Une AESH qui ignore qu'un « temps calme » est prévu à 14 h ne
-- peut pas le protéger.
create policy journee_etapes_lecture on journee_etapes for select to authenticated
  using (exists (select 1 from journees j where j.id = journee_id
                 and (est_intervenant(j.enfant_id) or est_l_enfant(j.enfant_id))));

create policy journee_etapes_ecriture on journee_etapes for all to authenticated
  using (exists (select 1 from journees j where j.id = journee_id and est_intervenant(j.enfant_id)))
  with check (exists (select 1 from journees j where j.id = journee_id and est_intervenant(j.enfant_id)));

create policy journee_reperes_lecture on journee_reperes for select to authenticated
  using (exists (select 1 from journees j where j.id = journee_id
                 and (est_intervenant(j.enfant_id) or est_l_enfant(j.enfant_id))));

create policy journee_reperes_ecriture on journee_reperes for all to authenticated
  using (exists (select 1 from journees j where j.id = journee_id and est_intervenant(j.enfant_id)))
  with check (exists (select 1 from journees j where j.id = journee_id and est_intervenant(j.enfant_id)));

create policy journee_preparatifs_lecture on journee_preparatifs for select to authenticated
  using (exists (select 1 from journees j where j.id = journee_id
                 and (est_intervenant(j.enfant_id) or est_l_enfant(j.enfant_id))));

-- L'enfant coche ses préparatifs et ses étapes : c'est là qu'est l'autonomie.
create policy journee_preparatifs_maj on journee_preparatifs for update to authenticated
  using (exists (select 1 from journees j where j.id = journee_id
                 and (est_intervenant(j.enfant_id) or est_l_enfant(j.enfant_id))))
  with check (exists (select 1 from journees j where j.id = journee_id
                 and (est_intervenant(j.enfant_id) or est_l_enfant(j.enfant_id))));

create policy journee_preparatifs_ecriture on journee_preparatifs for insert to authenticated
  with check (exists (select 1 from journees j where j.id = journee_id and est_intervenant(j.enfant_id)));

create policy journee_preparatifs_retrait on journee_preparatifs for delete to authenticated
  using (exists (select 1 from journees j where j.id = journee_id and est_intervenant(j.enfant_id)));

create policy preparatifs_recurrents_lecture on preparatifs_recurrents for select to authenticated
  using (est_intervenant(enfant_id) or est_l_enfant(enfant_id));

create policy preparatifs_recurrents_ecriture on preparatifs_recurrents for all to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));

create policy amorces_lecture on amorces_ecriture for select to authenticated
  using (enfant_id is null or est_intervenant(enfant_id) or est_l_enfant(enfant_id));

create policy amorces_ecriture_maj on amorces_ecriture for all to authenticated
  using (enfant_id is not null and peut_valider(enfant_id))
  with check (enfant_id is not null and peut_valider(enfant_id));

-- Cocher une étape appartient à l'enfant. Un adulte qui coche à sa place lui
-- retire précisément ce que la liste lui apportait.
create or replace function proteger_les_cases_de_l_enfant()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_enfant uuid;
begin
  select j.enfant_id into v_enfant from journees j where j.id = new.journee_id;

  if new.faite_le is distinct from old.faite_le
     and not (est_l_enfant(v_enfant) or peut_valider(v_enfant)) then
    raise exception 'Cocher une étape revient à l''enfant, ou à ceux qui l''accompagnent de près.';
  end if;

  return new;
end;
$$;

create trigger journee_etapes_protegent_les_cases
  before update on journee_etapes
  for each row execute function proteger_les_cases_de_l_enfant();

-- ======================================================== la frise enrichie

-- La frise de 0039 renvoyait des compteurs. Celle-ci renvoie ce qu'une tuile
-- affiche réellement : l'emoji, le titre court, et de quoi savoir si la journée
-- est préparée. Le libellé relatif — « hier », « dans 3 jours » — se calcule à
-- l'affichage : il dépend du jour de lecture, pas de la donnée.
-- `create or replace` refuse de changer les colonnes d'une fonction qui renvoie
-- une table : il faut la supprimer d'abord. La frise de 0039 en renvoyait huit,
-- celle-ci en renvoie seize.
drop function if exists frise(uuid, date, date);

create function frise(p_enfant uuid, p_debut date, p_fin date)
returns table (
  jour date,
  journee_id uuid,
  periode_id uuid,
  type_jour type_jour,
  emoji text,
  titre text,
  resume text,
  humeur humeur_jour,
  recit text,
  etapes bigint,
  etapes_faites bigint,
  reperes bigint,
  preparatifs_restants bigint,
  entrees bigint,
  medias bigint,
  encouragements bigint
)
language sql stable security definer set search_path = public as $$
  select
    d.jour::date,
    j.id,
    j.periode_id,
    coalesce(j.type_jour, case
      when extract(isodow from d.jour) >= 6 then 'week_end'::type_jour
      else 'ecole'::type_jour
    end),
    coalesce(j.emoji, ''),
    coalesce(j.titre, ''),
    coalesce(j.resume, ''),
    j.humeur,
    coalesce(j.recit, ''),
    count(distinct et.id),
    count(distinct et.id) filter (where et.faite_le is not null),
    count(distinct rp.id),
    count(distinct pr.id) filter (where pr.coche_le is null),
    count(distinct e.id),
    count(distinct m.id),
    count(distinct e.id) filter (where e.type = 'encouragement')
  from generate_series(p_debut, p_fin, interval '1 day') d(jour)
  left join journees j on j.enfant_id = p_enfant and j.jour = d.jour::date
  left join journee_etapes et on et.journee_id = j.id
  left join journee_reperes rp on rp.journee_id = j.id
  left join journee_preparatifs pr on pr.journee_id = j.id
  left join journal_entrees e on e.journee_id = j.id
  left join journal_medias m on m.journee_id = j.id
  where est_intervenant(p_enfant) or est_l_enfant(p_enfant)
  group by d.jour, j.id, j.periode_id, j.type_jour, j.emoji, j.titre, j.resume, j.humeur, j.recit
  order by d.jour;
$$;
