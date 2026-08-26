-- 0021 — Quand l'enfant échoue toujours au même endroit.
--
-- 0020 permet d'aller voir. Encore faut-il y aller. Un blocage installé se
-- reconnaît à ce qu'il ne se signale pas : l'enfant continue de travailler, les
-- exercices continuent d'arriver, et personne ne s'aperçoit qu'il retombe chaque
-- fois sur la même marche. Trois semaines plus tard, ce n'est plus une notion
-- fragile, c'est un dégoût pour la matière.
--
-- D'où une alerte qui vient à l'adulte plutôt que d'attendre qu'il la cherche.
--
-- Le seuil est de trois, en symétrie avec la règle d'acquisition : trois
-- réussites consacrent un acquis, trois échecs d'affilée signalent un blocage.
-- Un échec isolé est du bruit — l'enfant était fatigué, distrait, pressé. Trois
-- d'affilée sur la même chose, non.
--
-- ---------------------------------------------------------------------------
-- DEUX AXES, PAS UN
--
-- Le repère de compétence est l'unité naturelle du scolaire, mais tous les
-- repères appartiennent à une matière : keyer l'alerte dessus laisserait le
-- transversal — communication, comportement, autonomie — entièrement muet. Or
-- c'est précisément là qu'un blocage répété compte le plus, et là qu'il se
-- remarque le moins, faute de note pour le rendre visible.
--
-- Une alerte porte donc sur un repère OU sur un objectif fin, jamais sur les
-- deux. Le scolaire garde sa granularité de compétence ; le transversal prend
-- l'objectif fin comme unité, qui est son grain le plus fin disponible.
-- ---------------------------------------------------------------------------

create type statut_alerte as enum ('ouverte', 'traitee', 'ecartee');

create table alertes_difficulte (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,

  repere_id uuid references reperes_competences on delete cascade,
  objectif_id uuid references objectifs on delete cascade,

  echecs_consecutifs smallint not null,
  ouverte_le timestamptz not null default now(),
  derniere_le timestamptz not null default now(),

  statut statut_alerte not null default 'ouverte',
  -- Ce qu'on a tenté figure dans `alertes_actions`, en fin de fichier : un
  -- blocage sérieux se traite en plusieurs essais, et savoir qu'on a déjà changé
  -- de support avant d'alléger vaut plus que la dernière décision seule.
  traitee_par uuid references profils on delete set null,
  traitee_le timestamptz,

  constraint alerte_porte_sur_un_seul_axe
    check (num_nonnulls(repere_id, objectif_id) = 1),
  constraint alerte_traitee_a_un_auteur
    check (statut = 'ouverte' or (traitee_par is not null and traitee_le is not null))
);

-- Une seule alerte ouverte par enfant et par axe : le blocage est un état, il ne
-- s'empile pas. Les échecs suivants viennent alimenter celle qui court.
create unique index alertes_une_seule_ouverte_par_repere
  on alertes_difficulte (enfant_id, repere_id)
  where statut = 'ouverte' and repere_id is not null;

create unique index alertes_une_seule_ouverte_par_objectif
  on alertes_difficulte (enfant_id, objectif_id)
  where statut = 'ouverte' and objectif_id is not null;

create index alertes_enfant_idx
  on alertes_difficulte (enfant_id, derniere_le desc);

-- ------------------------------------------------- compter la série en cours

-- Une réussite remet le compteur à zéro — c'est le principe même : ce qu'on
-- cherche n'est pas un mauvais taux global, c'est une série qui ne se casse pas.
-- Un enfant à 50 % de réussite qui alterne va bien ; un enfant à 70 % qui vient
-- d'échouer quatre fois d'affilée est en train de décrocher, et aucune moyenne
-- ne le dira.

create or replace function echecs_consecutifs_repere(p_enfant uuid, p_repere uuid)
returns integer language sql stable security definer set search_path = public as $$
  with serie as (
    select t.reussie, row_number() over (order by t.cree_le desc, t.id) as rang
    from tentatives t
    join exercices e on e.id = t.exercice_id
    join missions m on m.id = e.mission_id
    left join objectifs o on o.id = m.objectif_id
    left join modeles_exercice mo on mo.id = e.modele_id
    where t.enfant_id = p_enfant
      and coalesce(o.repere_id, mo.repere_id) = p_repere
  )
  select coalesce(
    (select min(rang) - 1 from serie where reussie),
    (select count(*) from serie)
  )::integer;
$$;

create or replace function echecs_consecutifs_objectif(p_enfant uuid, p_objectif uuid)
returns integer language sql stable security definer set search_path = public as $$
  with serie as (
    select t.reussie, row_number() over (order by t.cree_le desc, t.id) as rang
    from tentatives t
    join exercices e on e.id = t.exercice_id
    join missions m on m.id = e.mission_id
    where t.enfant_id = p_enfant
      and m.objectif_id = p_objectif
  )
  select coalesce(
    (select min(rang) - 1 from serie where reussie),
    (select count(*) from serie)
  )::integer;
$$;

-- ---------------------------------------------------------------- l'alerte

create or replace function alerter_sur_echec_repete()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_seuil constant smallint := 3;
  v_objectif uuid;
  v_repere uuid;
  v_matiere text;
  v_intitule text;
  v_lien text;
  v_echecs integer;
  v_alerte uuid;
begin
  if new.reussie then
    return new;
  end if;

  select m.objectif_id, coalesce(o.repere_id, mo.repere_id), o.libelle
    into v_objectif, v_repere, v_intitule
  from exercices e
  join missions m on m.id = e.mission_id
  left join objectifs o on o.id = m.objectif_id
  left join modeles_exercice mo on mo.id = e.modele_id
  where e.id = new.exercice_id;

  if v_repere is not null then
    select r.matiere_code, r.libelle into v_matiere, v_intitule
    from reperes_competences r where r.id = v_repere;

    v_echecs := echecs_consecutifs_repere(new.enfant_id, v_repere);
    v_lien := '/enfants/' || new.enfant_id || '/difficultes/repere/' || v_repere;
    v_objectif := null;

  elsif v_objectif is not null then
    -- Axe transversal : pas de repère, l'objectif fin fait l'unité. On ne remonte
    -- pas à l'objectif large — un blocage sur « saluer en arrivant » ne se dilue
    -- pas dans « progresser en communication ».
    if not exists (
      select 1 from objectifs o
      where o.id = v_objectif and o.granularite = 'fin'
    ) then
      return new;
    end if;

    v_echecs := echecs_consecutifs_objectif(new.enfant_id, v_objectif);
    v_lien := '/enfants/' || new.enfant_id || '/difficultes/objectif/' || v_objectif;

  else
    -- Ni repère visé, ni objectif : rien de généralisable à signaler.
    return new;
  end if;

  if v_echecs < v_seuil then
    return new;
  end if;

  select id into v_alerte
  from alertes_difficulte
  where enfant_id = new.enfant_id
    and statut = 'ouverte'
    and repere_id is not distinct from v_repere
    and objectif_id is not distinct from v_objectif;

  if v_alerte is not null then
    -- La série s'allonge : on tient l'alerte à jour sans re-notifier. Prévenir à
    -- chaque échec en ferait un bruit de fond, et on cesserait de la lire
    -- exactement au moment où elle devient sérieuse.
    update alertes_difficulte
      set echecs_consecutifs = v_echecs,
          derniere_le = new.cree_le
      where id = v_alerte;
    return new;
  end if;

  insert into alertes_difficulte
    (enfant_id, repere_id, objectif_id, echecs_consecutifs, derniere_le)
  values
    (new.enfant_id, v_repere, v_objectif, v_echecs, new.cree_le);

  -- La famille, le référent, et le professeur de la matière concernée. Sur un
  -- axe transversal `v_matiere` est nul : aucun enseignant n'est joint, et c'est
  -- le référent qui est le professionnel du champ.
  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select
    i.profil_id,
    new.enfant_id,
    'difficulte_repetee',
    'Blocage répété : ' || coalesce(v_intitule, 'compétence non précisée'),
    v_echecs || ' échecs d''affilée, sans réussite intercalée.',
    v_lien
  from intervenants_enfant i
  where i.enfant_id = new.enfant_id
    and i.retire_le is null
    and (
      i.role in ('parent', 'referent')
      or (v_matiere is not null and i.role = 'enseignant' and i.matiere_code = v_matiere)
    );

  return new;
end;
$$;

create trigger tentatives_alertent_sur_echec_repete
  after insert on tentatives
  for each row execute function alerter_sur_echec_repete();

-- ==================================================================== RLS

-- Le cercle de l'alerte : la famille et le référent toujours, l'enseignant sur
-- sa matière, et sur l'axe transversal le pilote de l'objectif. Exactement ceux
-- que le trigger a prévenus — être alerté de quelque chose qu'on ne peut pas
-- ouvrir serait absurde.
create or replace function acces_a_l_alerte(p_alerte uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from alertes_difficulte a
    where a.id = p_alerte
      and (
        peut_valider(a.enfant_id)
        or (a.repere_id is not null and exists (
              select 1 from reperes_competences r
              where r.id = a.repere_id
                and matiere_ouverte_a_l_ecriture(a.enfant_id, r.matiere_code)))
        or (a.objectif_id is not null and pilote_l_objectif(a.objectif_id))
      )
  );
$$;

alter table alertes_difficulte enable row level security;

create policy alertes_lecture on alertes_difficulte for select to authenticated
  using (acces_a_l_alerte(id));

-- Personne ne crée d'alerte à la main : elles naissent du trigger, et il
-- n'existe aucune politique d'insertion.
create policy alertes_traitement on alertes_difficulte for update to authenticated
  using (acces_a_l_alerte(id))
  with check (statut = 'ouverte' or traitee_par = auth.uid());

-- ========================================== l'historique des actions menées

-- Un blocage sérieux ne se résout pas du premier coup. On reprend la notion en
-- amont ; si ça ne suffit pas on change de support ; puis on allège ; puis on
-- oriente. Ne garder que la dernière décision effacerait le raisonnement — et
-- surtout, ferait recommencer les mêmes tentatives six mois plus tard, ou avec
-- l'intervenant suivant qui n'a pas vu ce qui avait déjà échoué.
--
-- C'est aussi la matière première du bilan trimestriel : « voilà ce qu'on a
-- essayé, voilà ce qui a marché » est autrement plus utile à une réunion
-- parents-professeurs qu'un taux de réussite.

create type type_action_alerte as enum (
  'reprise_en_amont',
  'changement_de_support',
  'allegement',
  'exercices_supplementaires',
  'changement_de_projet_moteur',
  'mise_en_pause',
  'orientation_exterieure',
  'autre'
);

create table alertes_actions (
  id uuid primary key default gen_random_uuid(),
  alerte_id uuid not null references alertes_difficulte on delete cascade,

  type_action type_action_alerte not null,
  description text not null,

  auteur_id uuid not null references profils on delete restrict,
  cree_le timestamptz not null default now(),

  -- Renseigné après coup, quand on sait ce que ça a donné. Une action sans effet
  -- constaté n'est pas une erreur — c'est souvent qu'il est trop tôt.
  effet text not null default '',
  effet_constate_le timestamptz,

  constraint effet_constate_a_une_date
    check ((effet = '') = (effet_constate_le is null))
);

create index alertes_actions_alerte_idx
  on alertes_actions (alerte_id, cree_le);

-- On ne clôt pas une alerte sans dire ce qu'on a fait. Sans cette règle, le
-- statut 'traitee' deviendrait une case à cocher pour faire disparaître la
-- ligne de l'écran, et l'historique serait vide là où il devrait être le plus
-- fourni. Écarter reste possible sans action : c'est dire « ce n'était pas un
-- vrai blocage », et c'est une décision signée par `traitee_par`.
create or replace function exiger_une_action_avant_cloture()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.statut = 'traitee' and (tg_op = 'INSERT' or old.statut <> 'traitee') then
    if not exists (select 1 from alertes_actions a where a.alerte_id = new.id) then
      raise exception 'Une alerte se clôt en consignant ce qui a été tenté. Ajoutez une action, ou écartez l''alerte si le blocage n''en était pas un.';
    end if;
  end if;
  return new;
end;
$$;

create trigger alertes_exigent_une_action
  before insert or update on alertes_difficulte
  for each row execute function exiger_une_action_avant_cloture();

alter table alertes_actions enable row level security;

create policy alertes_actions_lecture on alertes_actions for select to authenticated
  using (acces_a_l_alerte(alerte_id));

create policy alertes_actions_ajout on alertes_actions for insert to authenticated
  with check (acces_a_l_alerte(alerte_id) and auteur_id = auth.uid());

-- On complète son propre compte rendu — l'effet constaté arrive souvent des
-- semaines après l'action. On ne réécrit pas celui d'un autre.
create policy alertes_actions_maj on alertes_actions for update to authenticated
  using (auteur_id = auth.uid()) with check (auteur_id = auth.uid());
