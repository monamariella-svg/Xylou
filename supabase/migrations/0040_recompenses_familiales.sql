-- 0040 — Les récompenses que la famille promet.
--
-- La boutique de 0030 vend du virtuel : un personnage, un décor, une tenue,
-- payés en points dépensés. C'est une économie fermée, immédiate, et elle joue
-- son rôle au quotidien.
--
-- Ce que les parents apportent est d'une autre nature. Une sortie en famille en
-- novembre, un après-midi avec son père, une visite quelque part : c'est réel,
-- c'est daté, et pour beaucoup d'enfants c'est infiniment plus motivant qu'un
-- objet à l'écran. Trois différences structurantes avec la boutique :
--
--   - la récompense est **réelle**. Personne ne la « débloque » dans le jeu :
--     un adulte la tient, ou ne la tient pas.
--   - elle a une **date**. C'est ce qui permet à l'IA d'en parler correctement :
--     une récompense dans trois jours se mentionne dans la mission du jour, une
--     récompense dans deux mois demande une jauge de progression.
--   - les points ne sont **pas dépensés**. On atteint un palier, on ne paie pas
--     un prix. Un enfant qui viderait son solde en achetant un décor perdrait
--     sa sortie de novembre — ce serait absurde, et il l'apprendrait trop tard.
--
-- Elle ne dépend pas non plus du projet moteur : un changement d'univers (0035)
-- ne fait pas disparaître une sortie promise.
--
-- ---------------------------------------------------------------------------
-- UNE PROMESSE NON TENUE EST PIRE QUE PAS DE PROMESSE
--
-- Pour un enfant qui a besoin de repères stables, une récompense annoncée puis
-- annulée ne coûte pas zéro : elle coûte la confiance dans tout ce qui sera
-- annoncé ensuite. D'où deux choix qui peuvent sembler rigides — l'annulation
-- exige un motif, et le report se distingue de l'annulation. L'outil ne peut pas
-- empêcher un adulte de ne pas tenir parole ; il peut au moins l'obliger à
-- s'en apercevoir.
-- ---------------------------------------------------------------------------

create type horizon_recompense as enum ('imminent', 'court_terme', 'moyen_terme', 'long_terme');
create type statut_recompense_familiale as enum ('promise', 'atteinte', 'reportee', 'annulee');

create table recompenses_familiales (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,

  libelle text not null,
  description text not null default '',
  -- Rangée dans le bucket `recompenses` de 0010, sous {enfant_id}/. La photo
  -- fait beaucoup du travail : « une sortie » motive moins que la photo du lieu.
  photo_chemin text,

  -- Facultative, et c'est souvent le plus simple. Une récompense datée impose un
  -- calendrier : il faut la tenir le jour dit, la reporter en s'expliquant, gérer
  -- l'écart entre la date promise et le palier atteint. Un seuil de points seul
  -- se suffit — « à 200 points, tu l'as » — et l'enfant contrôle le moment.
  --
  -- La date garde son intérêt quand la récompense est elle-même datée : une
  -- sortie prévue le 15, un anniversaire, un spectacle. Dans ce cas seulement.
  prevue_le date,

  -- Ce qu'il faut atteindre. Tout est facultatif et tout se cumule : ce qui est
  -- renseigné doit être atteint.
  --
  -- Le palier de points et le compte de missions ne disent pas la même chose. Les
  -- points récompensent la difficulté — une mission dure en rapporte plus. Le
  -- compte de missions récompense la régularité, et c'est parfois ce qu'on
  -- cherche : dix missions faciles enchaînées valent mieux, pour un enfant qui
  -- décroche, qu'une seule très bien réussie.
  points_requis integer check (points_requis is null or points_requis > 0),
  missions_requises integer check (missions_requises is null or missions_requises > 0),
  objectif_id uuid references objectifs on delete set null,
  condition text not null default '',

  statut statut_recompense_familiale not null default 'promise',
  atteinte_le date,
  motif text not null default '',

  proposee_par uuid not null references profils on delete restrict,
  cree_le timestamptz not null default now(),
  modifie_le timestamptz not null default now(),

  -- Une annulation ou un report se motive : c'est ce que l'enfant demandera,
  -- et ce que le parent devra pouvoir lui dire.
  constraint changement_motive
    check (statut not in ('reportee', 'annulee') or length(btrim(motif)) >= 5),
  constraint atteinte_datee
    check ((statut = 'atteinte') = (atteinte_le is not null)),

  -- Une récompense sans aucune condition ni date ne dit rien à l'enfant : ni
  -- quand, ni pourquoi, ni comment l'obtenir. C'est une intention, pas une
  -- promesse, et elle ne motive personne.
  constraint recompense_a_une_condition
    check (
      prevue_le is not null
      or points_requis is not null
      or missions_requises is not null
      or objectif_id is not null
      or length(btrim(condition)) > 0
    )
);

create trigger recompenses_familiales_touch
  before update on recompenses_familiales
  for each row execute function touch_modifie_le();

create index recompenses_familiales_a_venir_idx
  on recompenses_familiales (enfant_id, prevue_le)
  where statut = 'promise';

-- ------------------------------------------------------------- l'horizon

-- Calculé et jamais stocké : une récompense « à moyen terme » devient
-- « imminente » sans que personne ne la touche, simplement parce que les jours
-- passent. Une colonne aurait vieilli en silence.
-- `strict` : sans date, il n'y a pas d'horizon. Sans ce mot, un `null` tomberait
-- dans le `else` et une récompense sans échéance serait annoncée « à long
-- terme » — une information fausse, et fabriquée de toutes pièces.
create or replace function horizon_de(p_date date)
returns horizon_recompense
language sql immutable strict as $$
  select case
    when p_date - current_date <= 3  then 'imminent'
    when p_date - current_date <= 14 then 'court_terme'
    when p_date - current_date <= 60 then 'moyen_terme'
    else 'long_terme'
  end::horizon_recompense;
$$;

-- Le compte de missions réussies, pour la condition de régularité.
create or replace function missions_reussies(p_enfant uuid)
returns integer
language sql stable security definer set search_path = public as $$
  select count(*)::integer from missions
  where enfant_id = p_enfant and statut = 'reussie';
$$;

-- La progression vers une récompense : la moins avancée de ses conditions
-- chiffrées, puisqu'il faut les remplir toutes. Nul si aucune n'est chiffrée —
-- une condition en clair s'apprécie, elle ne se calcule pas.
create or replace function progression_vers(p_enfant uuid, p_points integer, p_missions integer)
returns numeric
language sql stable security definer set search_path = public as $$
  select min(part) from (
    select case when p_points is null then null else
      least(100, round(100.0 * coalesce((select points_gagnes from points_enfant where enfant_id = p_enfant), 0) / p_points, 0))
    end as part
    union all
    select case when p_missions is null then null else
      least(100, round(100.0 * missions_reussies(p_enfant) / p_missions, 0))
    end
  ) parts;
$$;

-- Ce que l'IA reçoit pour composer ses missions : la récompense en vue, dans
-- combien de jours, et où en est l'enfant. C'est ce qui permet d'écrire « encore
-- deux missions et le musée du week-end est gagné » plutôt qu'un encouragement
-- générique — et c'est la différence entre un motivateur et un slogan.
create or replace function recompenses_a_venir(p_enfant uuid)
returns table (
  recompense_id uuid,
  libelle text,
  description text,
  photo_chemin text,
  prevue_le date,
  jours_restants integer,
  horizon horizon_recompense,
  points_requis integer,
  points_actuels integer,
  progression numeric,
  condition text
)
language sql stable security definer set search_path = public as $$
  select
    r.id,
    r.libelle,
    r.description,
    r.photo_chemin,
    r.prevue_le,
    (r.prevue_le - current_date)::integer,
    horizon_de(r.prevue_le),
    r.points_requis,
    coalesce(p.points_gagnes, 0),
    case
      when r.points_requis is null then null
      else least(100, round(100.0 * coalesce(p.points_gagnes, 0) / r.points_requis, 0))
    end,
    r.condition
  from recompenses_familiales r
  left join points_enfant p on p.enfant_id = r.enfant_id
  where r.enfant_id = p_enfant
    and r.statut = 'promise'
    and (est_intervenant(p_enfant) or est_l_enfant(p_enfant))
  order by r.prevue_le;
$$;

-- `points_gagnes` et non `solde` : le palier se franchit, il ne se paie pas.
-- Un enfant qui dépense ses points en boutique ne recule pas vers sa sortie.

-- ------------------------------------------------------- atteindre le palier

-- Prévenir quand le palier est franchi. La notification part vers la famille —
-- c'est elle qui tient la promesse — et vers l'enfant, à qui elle est destinée.
create or replace function signaler_le_palier_atteint()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_compte uuid;
begin
  if new.statut <> 'atteinte' or old.statut = 'atteinte' then
    return new;
  end if;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select i.profil_id, new.enfant_id, 'recompense_atteinte',
         'Récompense atteinte : ' || new.libelle,
         'Prévue le ' || to_char(new.prevue_le, 'DD/MM/YYYY') || '.',
         '/enfants/' || new.enfant_id || '/recompenses/' || new.id
  from intervenants_enfant i
  where i.enfant_id = new.enfant_id
    and i.retire_le is null
    and i.role in ('parent', 'referent');

  select compte_id into v_compte from enfants where id = new.enfant_id;

  if v_compte is not null then
    insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
    values (v_compte, new.enfant_id, 'recompense_atteinte',
            'Tu as gagné : ' || new.libelle, '',
            '/mes-recompenses/' || new.id);
  end if;

  return new;
end;
$$;

create trigger recompenses_familiales_signalent_le_palier
  after update on recompenses_familiales
  for each row execute function signaler_le_palier_atteint();

-- ==================================================================== RLS

alter table recompenses_familiales enable row level security;

-- L'enfant la voit, évidemment : une récompense qu'il ignore ne motive rien.
-- L'équipe aussi — un enseignant qui sait qu'une sortie se joue cette semaine
-- comprend pourquoi l'enfant s'accroche, et peut s'appuyer dessus.
create policy recompenses_familiales_lecture on recompenses_familiales
  for select to authenticated
  using (est_intervenant(enfant_id) or est_l_enfant(enfant_id));

-- Promettre engage : cela revient aux parents et au référent, jamais à
-- l'établissement. Un enseignant qui promettrait une sortie en famille
-- engagerait quelqu'un d'autre que lui.
create policy recompenses_familiales_creation on recompenses_familiales
  for insert to authenticated
  with check (peut_valider(enfant_id) and proposee_par = auth.uid());

create policy recompenses_familiales_maj on recompenses_familiales
  for update to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));

-- Pas de suppression : une promesse ne s'efface pas, elle s'annule — avec un
-- motif, et en restant lisible. Un enfant qui cherche une récompense disparue
-- sans trace n'a personne à qui demander pourquoi.

-- ------------------------------------------------------------- la photo

-- Le bucket `recompenses` existe depuis 0010, mais ses politiques datent d'avant
-- le compte enfant (0032) : elles ne connaissent que `est_intervenant()`. La
-- photo de la sortie promise serait donc invisible à celui qu'elle motive.
create policy "recompenses_lecture_enfant" on storage.objects
  for select to authenticated using (
    bucket_id = 'recompenses'
    and public.est_l_enfant(public.enfant_du_chemin(name))
  );

-- Même oubli sur les images de la boutique virtuelle : `recompenses.image_chemin`
-- pointe dans ce bucket, et un catalogue sans images n'est pas un catalogue.
-- La politique ci-dessus les couvre toutes deux, puisqu'elles partagent le
-- bucket et la convention de chemin.
