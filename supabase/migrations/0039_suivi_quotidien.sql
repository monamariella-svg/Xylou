-- 0039 — Le suivi quotidien.
--
-- Tout ce que le schéma savait porter jusqu'ici est structuré et lent : un
-- objectif dure des semaines, un bilan un trimestre. Rien ne portait la journée
-- — or c'est l'unité dans laquelle l'enfant vit, et celle qui explique le reste.
-- Une mission ratée un mardi ne veut rien dire ; une mission ratée après une
-- nuit sans sommeil veut tout dire, et personne ne peut le savoir si la nuit
-- n'est écrite nulle part.
--
-- Trois flux, dans un seul objet, parce qu'ils se lisent ensemble :
--
--   l'enfant raconte sa journée — en texte, en photo, en vidéo, en vocal — et
--   dit son humeur. C'est sa page, et il l'écrit comme il peut : un enfant qui
--   ne rédige pas peut enregistrer trente secondes de voix.
--
--   les parents écrivent vers l'équipe : une nuit agitée, une période
--   difficile, un rendez-vous médical. Ce qui explique la journée du lendemain.
--
--   les professionnels écrivent vers les parents : les attendus d'un devoir, ce
--   qui a été fait en cours, comment la journée s'est passée, et l'encouragement
--   pour le travail fourni — celui-là visible de l'enfant, c'est sa raison
--   d'être.
--
-- La frise se lit sur `journees` : une ligne par jour, qu'il s'y soit passé
-- quelque chose ou non. C'est ce qui permet un repère dans le temps continu
-- plutôt qu'une liste d'événements épars — et pour un enfant qui a besoin de
-- structure, un calendrier troué est plus déroutant qu'un calendrier vide.

create type humeur_jour as enum (
  'tres_bonne', 'bonne', 'moyenne', 'difficile', 'tres_difficile'
);

create type type_jour as enum (
  'ecole', 'maison', 'week_end', 'vacances', 'absence', 'soin'
);

-- Une journée par enfant et par date. Créée par qui écrit le premier, jamais
-- en masse : une frise qui se remplit d'avance donnerait l'illusion d'un suivi.
create table journees (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  jour date not null,

  type_jour type_jour not null default 'ecole',

  -- Renseignés par l'enfant, et par lui seul. Un adulte qui noterait l'humeur
  -- de l'enfant à sa place noterait la sienne.
  humeur humeur_jour,
  humeur_le timestamptz,
  recit text not null default '',

  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),

  unique (enfant_id, jour),

  constraint humeur_horodatee check ((humeur is null) = (humeur_le is null))
);

create trigger journees_touch
  before update on journees
  for each row execute function touch_modifie_le();

create index journees_frise_idx on journees (enfant_id, jour desc);

-- ------------------------------------------------------------- les entrées

create type type_entree as enum (
  'nuit',                 -- parent : sommeil, réveil, fatigue
  'sante',                -- parent : rendez-vous, traitement, douleur
  'periode_difficile',    -- parent : contexte familial, deuil, déménagement
  'attendus_devoir',      -- professionnel : ce qui est attendu du devoir donné
  'contenu_cours',        -- professionnel : ce qui a été fait aujourd'hui
  'comportement',         -- professionnel : comment la journée s'est passée
  'encouragement',        -- professionnel : le bon point pour le travail fourni
  'organisation',         -- matériel, transport, sortie
  'autre'
);

create table journal_entrees (
  id uuid primary key default gen_random_uuid(),
  journee_id uuid not null references journees on delete cascade,
  auteur_id uuid not null references profils on delete restrict,

  type type_entree not null,
  corps text not null default '',

  -- Le professionnel décide au cas par cas de ce que l'enfant lit. Un
  -- encouragement lui est adressé — il le voit par défaut. Une observation de
  -- comportement s'adresse aux parents, et la lui montrer sans médiation peut
  -- faire plus de mal que de bien.
  visible_par_l_enfant boolean not null default false,

  -- Rattachement facultatif : « les attendus du devoir » gagnent à pointer vers
  -- le support ou l'objectif concerné plutôt qu'à les redécrire.
  support_id uuid references supports on delete set null,
  objectif_id uuid references objectifs on delete set null,

  cree_le timestamptz not null default now(),
  modifie_le timestamptz
);

create index journal_entrees_journee_idx on journal_entrees (journee_id, cree_le);
create index journal_entrees_auteur_idx on journal_entrees (auteur_id, cree_le desc);

-- Un encouragement est adressé à l'enfant : le masquer n'aurait aucun sens.
create or replace function encouragement_toujours_visible()
returns trigger language plpgsql as $$
begin
  if new.type = 'encouragement' then
    new.visible_par_l_enfant := true;
  end if;
  return new;
end;
$$;

create trigger journal_entrees_encouragements_visibles
  before insert or update on journal_entrees
  for each row execute function encouragement_toujours_visible();

-- ---------------------------------------------------------------- les médias

create type type_media as enum ('photo', 'video', 'audio');

-- Attachés soit à une journée — le récit de l'enfant en images ou en voix —
-- soit à une entrée d'adulte : la photo du tableau, la consigne dictée.
create table journal_medias (
  id uuid primary key default gen_random_uuid(),
  journee_id uuid not null references journees on delete cascade,
  entree_id uuid references journal_entrees on delete cascade,

  type_media type_media not null,
  chemin text not null unique,
  nom text not null default '',
  duree_secondes integer check (duree_secondes is null or duree_secondes > 0),
  octets bigint,

  depose_par uuid not null references profils on delete restrict,
  cree_le timestamptz not null default now()
);

create index journal_medias_journee_idx on journal_medias (journee_id, cree_le);

-- ==================================================================== RLS

alter table journees        enable row level security;
alter table journal_entrees enable row level security;
alter table journal_medias  enable row level security;

-- La frise se lit par toute l'équipe, l'enfant compris. C'est le principe même
-- d'un cahier de liaison : ce qui s'y écrit est destiné à être lu, et une AESH
-- qui ne verrait pas la nuit signalée par les parents ne pourrait pas adapter sa
-- journée.
create policy journees_lecture on journees for select to authenticated
  using (est_intervenant(enfant_id) or est_l_enfant(enfant_id));

-- N'importe quel intervenant ouvre la journée en écrivant le premier ; l'enfant
-- aussi, puisque c'est d'abord sa page.
create policy journees_creation on journees for insert to authenticated
  with check (est_intervenant(enfant_id) or est_l_enfant(enfant_id));

create policy journees_maj on journees for update to authenticated
  using (est_intervenant(enfant_id) or est_l_enfant(enfant_id))
  with check (est_intervenant(enfant_id) or est_l_enfant(enfant_id));

-- L'humeur et le récit appartiennent à l'enfant. Un adulte règle le type de
-- jour — école, soin, vacances — et rien d'autre.
create or replace function proteger_la_page_de_l_enfant()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if est_l_enfant(new.enfant_id) then
    return new;
  end if;

  if new.humeur is distinct from old.humeur
  or new.recit is distinct from old.recit then
    raise exception 'L''humeur et le récit de la journée appartiennent à l''enfant. Écrivez une entrée pour dire ce que vous en observez.';
  end if;

  return new;
end;
$$;

create trigger journees_protegent_la_page_de_l_enfant
  before update on journees
  for each row execute function proteger_la_page_de_l_enfant();

-- L'horodatage de l'humeur se pose tout seul : savoir qu'un enfant s'est dit en
-- difficulté à 8 h ou à 18 h ne raconte pas la même journée.
create or replace function horodater_l_humeur()
returns trigger language plpgsql as $$
begin
  if tg_op = 'INSERT' then
    if new.humeur is not null then new.humeur_le := now(); end if;
  elsif new.humeur is distinct from old.humeur then
    new.humeur_le := case when new.humeur is null then null else now() end;
  end if;
  return new;
end;
$$;

create trigger journees_horodatent_l_humeur
  before insert or update on journees
  for each row execute function horodater_l_humeur();

-- --------------------------------------------------------------- les entrées

-- L'enfant ne voit que ce qui lui est destiné. Les adultes voient tout : le
-- cahier de liaison n'a de valeur que si chacun lit ce que les autres ont écrit.
create policy journal_entrees_lecture on journal_entrees for select to authenticated
  using (
    exists (
      select 1 from journees j
      where j.id = journee_id
        and (
          est_intervenant(j.enfant_id)
          or (est_l_enfant(j.enfant_id) and visible_par_l_enfant)
        )
    )
  );

create policy journal_entrees_ecriture on journal_entrees for insert to authenticated
  with check (
    auteur_id = auth.uid()
    and exists (
      select 1 from journees j
      where j.id = journee_id and est_intervenant(j.enfant_id)
    )
  );

-- On corrige ce qu'on a écrit, pas ce qu'un autre a écrit. Comme en messagerie :
-- une observation relue par les parents ne se réécrit pas en silence.
create policy journal_entrees_correction on journal_entrees for update to authenticated
  using (auteur_id = auth.uid()) with check (auteur_id = auth.uid());

create policy journal_entrees_retrait on journal_entrees for delete to authenticated
  using (auteur_id = auth.uid());

-- ---------------------------------------------------------------- les médias

create policy journal_medias_lecture on journal_medias for select to authenticated
  using (
    exists (
      select 1 from journees j
      where j.id = journee_id
        and (
          est_intervenant(j.enfant_id)
          or (
            est_l_enfant(j.enfant_id)
            and (
              entree_id is null
              or exists (
                select 1 from journal_entrees e
                where e.id = entree_id and e.visible_par_l_enfant
              )
            )
          )
        )
    )
  );

-- L'enfant dépose ses propres médias — c'est le cœur de sa page. Les adultes
-- déposent les leurs sur leurs entrées.
create policy journal_medias_depot on journal_medias for insert to authenticated
  with check (
    depose_par = auth.uid()
    and exists (
      select 1 from journees j
      where j.id = journee_id
        and (est_intervenant(j.enfant_id) or est_l_enfant(j.enfant_id))
    )
  );

create policy journal_medias_retrait on journal_medias for delete to authenticated
  using (depose_par = auth.uid());

-- ============================================================ le stockage

-- Convention : {enfant_id}/{journee_id}/{fichier}. Le premier segment porte le
-- droit, comme les buckets `supports` et `bilans` de 0010.
create or replace function journee_du_chemin(p_name text)
returns uuid language sql immutable as $$
  select uuid_ou_null((storage.foldername(p_name))[2]);
$$;

insert into storage.buckets (id, name, public) values
  ('journal', 'journal', false)
on conflict (id) do nothing;

create policy "journal_lecture" on storage.objects
  for select to authenticated using (
    bucket_id = 'journal'
    and (
      public.est_intervenant(public.enfant_du_chemin(name))
      or public.est_l_enfant(public.enfant_du_chemin(name))
    )
  );

create policy "journal_depot" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'journal'
    and (
      public.est_intervenant(public.enfant_du_chemin(name))
      or public.est_l_enfant(public.enfant_du_chemin(name))
    )
  );

create policy "journal_retrait" on storage.objects
  for delete to authenticated using (
    bucket_id = 'journal'
    and (
      owner = auth.uid()
      or public.peut_valider(public.enfant_du_chemin(name))
    )
  );

-- ======================================================== lire la frise

-- Une frise continue, jours vides compris. La fonction produit la série de
-- dates plutôt que de renvoyer les seules journées écrites : c'est ce qui
-- permet d'afficher un calendrier sans trous, et de voir d'un coup d'œil les
-- jours où personne n'a rien dit.
create or replace function frise(p_enfant uuid, p_debut date, p_fin date)
returns table (
  jour date,
  journee_id uuid,
  type_jour type_jour,
  humeur humeur_jour,
  recit text,
  entrees bigint,
  medias bigint,
  encouragements bigint
)
language sql stable security definer set search_path = public as $$
  select
    d.jour::date,
    j.id,
    coalesce(j.type_jour, case
      when extract(isodow from d.jour) >= 6 then 'week_end'::type_jour
      else 'ecole'::type_jour
    end),
    j.humeur,
    coalesce(j.recit, ''),
    count(distinct e.id),
    count(distinct m.id),
    count(distinct e.id) filter (where e.type = 'encouragement')
  from generate_series(p_debut, p_fin, interval '1 day') d(jour)
  left join journees j on j.enfant_id = p_enfant and j.jour = d.jour::date
  left join journal_entrees e on e.journee_id = j.id
  left join journal_medias m on m.journee_id = j.id
  where est_intervenant(p_enfant) or est_l_enfant(p_enfant)
  group by d.jour, j.id, j.type_jour, j.humeur, j.recit
  order by d.jour;
$$;
