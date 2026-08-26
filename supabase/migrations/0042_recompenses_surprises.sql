-- 0042 — Ce que l'enfant sait d'une récompense à venir.
--
-- 0040 rendait toute récompense entièrement visible. C'est bien pour une sortie
-- annoncée — savoir qu'on ira au musée le 15 novembre fait tout le travail — et
-- c'est manqué pour une surprise.
--
-- ---------------------------------------------------------------------------
-- POURQUOI QUATRE LEVIERS ET NON UN
--
-- La première version de ce fichier posait une règle : une surprise cache sa
-- nature, mais garde sa date et sa jauge visibles, « parce que c'est ce qui fait
-- travailler l'enfant ». C'était décider à la place des familles.
--
-- Pour beaucoup d'enfants, l'anticipation est le carburant : la jauge qui monte
-- vers une date connue soutient l'effort pendant des semaines. Pour d'autres,
-- exactement la même information devient une boucle — la sortie occupe toute la
-- place, revient dans chaque conversation, et le travail passe au second plan.
-- Chez un enfant autiste, cet écart n'est pas une nuance de tempérament, c'est
-- la différence entre un dispositif qui aide et un dispositif qui épuise.
--
-- Personne ne peut le savoir depuis une table. Celui qui promet la récompense,
-- lui, le sait. Quatre interrupteurs indépendants, tous ouverts par défaut :
--
--   montrer_existence   — qu'il y a quelque chose
--   montrer_nature      — ce que c'est
--   montrer_date        — pour quand
--   montrer_progression — à quelle distance il en est
--
-- Tout fermer donne la surprise complète : rien n'apparaît avant le
-- dévoilement. Tout ouvrir donne la récompense annoncée de 0040. Entre les
-- deux, chaque combinaison a un sens et un usage.
-- ---------------------------------------------------------------------------
--
-- Sur le nom de la table : `recompenses_familiales` couvre aussi bien celles du
-- référent. La politique de 0040 exige `peut_valider()`, qui l'inclut — il en
-- crée dans les mêmes termes que les parents, et `proposee_par` dit lequel des
-- deux a promis.

comment on table recompenses_familiales is
  'Récompenses réelles promises par les parents ou par le référent. Le nom dit leur nature — réelles, tenues par un adulte — et non leur origine.';

alter table recompenses_familiales
  add column montrer_existence boolean not null default true,
  add column montrer_nature boolean not null default true,
  add column montrer_date boolean not null default true,
  add column montrer_progression boolean not null default true,
  add column devoilee_le timestamptz,
  add column devoilee_par uuid references profils on delete set null;

alter table recompenses_familiales
  add constraint devoilement_signe
  check ((devoilee_le is null) = (devoilee_par is null));

-- Cacher l'existence et montrer le reste n'a pas de sens : on ne peut pas
-- afficher la date de quelque chose dont on tait l'existence.
alter table recompenses_familiales
  add constraint visibilite_coherente
  check (
    montrer_existence
    or (not montrer_nature and not montrer_date and not montrer_progression)
  );

create index recompenses_a_devoiler_idx
  on recompenses_familiales (enfant_id, prevue_le)
  where statut = 'promise' and devoilee_le is null and not montrer_nature;

-- L'objet que l'enfant voit à la place. Il appartient à l'univers : un coffre
-- dans un jeu vidéo, une carte à gratter, un colis, une caisse de marchandises
-- sur un réseau ferroviaire. Le choisir revient à ceux qui composent l'univers,
-- pas à une correspondance figée dans le code — un enfant dont l'univers est le
-- désert n'a que faire d'un coffre de donjon.
alter table projets_moteurs
  add column surprise_libelle text not null default 'Une surprise',
  add column surprise_image_chemin text;

-- ------------------------------------------------------------- dévoiler

-- Le dévoilement ouvre tout d'un coup, quels que soient les quatre
-- interrupteurs. C'est le geste du référent — ou du parent — quand les objectifs
-- sont atteints.
--
-- Séparé de `statut = 'atteinte'` à dessein : on dévoile le jour où c'est
-- acquis, la sortie a lieu le week-end suivant.
create or replace function devoiler_la_recompense(p_recompense uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_rec recompenses_familiales%rowtype;
  v_compte uuid;
begin
  select * into v_rec from recompenses_familiales where id = p_recompense;

  if not found then
    raise exception 'Récompense introuvable.';
  end if;

  if not peut_valider(v_rec.enfant_id) then
    raise exception 'Dévoiler une récompense revient aux titulaires de l''autorité parentale ou au référent.';
  end if;

  if v_rec.devoilee_le is not null then
    raise exception 'Cette récompense est déjà dévoilée.';
  end if;

  update recompenses_familiales
    set devoilee_le = now(), devoilee_par = auth.uid()
    where id = p_recompense;

  select compte_id into v_compte from enfants where id = v_rec.enfant_id;

  if v_compte is not null then
    insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
    values (v_compte, v_rec.enfant_id, 'recompense_atteinte',
            'Ta surprise se dévoile : ' || v_rec.libelle, '',
            '/mes-recompenses/' || v_rec.id);
  end if;
end;
$$;

-- Ce qui a été montré ne se reprend pas. Un interrupteur va de fermé à ouvert,
-- jamais l'inverse : refermer reviendrait à retirer à l'enfant une information
-- qu'il a déjà lue, et à lui donner le sentiment qu'on lui cache quelque chose
-- — ce qui est précisément le contraire du but.
create or replace function figer_la_visibilite()
returns trigger language plpgsql as $$
begin
  if old.devoilee_le is not null and new.devoilee_le is null then
    raise exception 'Une récompense dévoilée ne se recache pas.';
  end if;

  if (old.montrer_existence   and not new.montrer_existence)
  or (old.montrer_nature      and not new.montrer_nature)
  or (old.montrer_date        and not new.montrer_date)
  or (old.montrer_progression and not new.montrer_progression) then
    raise exception 'On peut en montrer davantage, jamais moins : l''enfant a déjà lu ce qui était visible.';
  end if;

  return new;
end;
$$;

create trigger recompenses_figent_la_visibilite
  before update on recompenses_familiales
  for each row execute function figer_la_visibilite();

-- ------------------------------------------------- modifier une récompense
--
-- Tant qu'une récompense reste cachée, elle se retouche librement : changer
-- d'idée sur une surprise que personne n'a lue ne coûte rien à personne, et
-- l'interdire obligerait à annuler puis recréer pour corriger une faute de
-- frappe.
--
-- Ce qui se fige, c'est ce que l'enfant a déjà vu — et chaque levier de
-- visibilité fige exactement ce qu'il montrait :
--
--   nature visible      → le libellé, la description et la photo ne bougent plus
--   date visible        → elle peut être reportée, mais le report est consigné
--   progression visible → le palier peut descendre, jamais monter
--
-- La règle tient en une phrase : on ne réécrit pas une promesse que l'enfant a
-- lue. On peut l'améliorer, la reporter en s'en expliquant, mais pas la
-- remplacer par une autre en espérant qu'il n'ait pas fait attention.

create table recompenses_reports (
  id uuid primary key default gen_random_uuid(),
  recompense_id uuid not null references recompenses_familiales on delete cascade,
  ancienne_date date not null,
  nouvelle_date date not null,
  motif text not null,
  reporte_par uuid not null references profils on delete restrict,
  reporte_le timestamptz not null default now()
);

create index recompenses_reports_idx on recompenses_reports (recompense_id, reporte_le desc);

alter table recompenses_reports enable row level security;

-- L'enfant y a droit : c'est l'explication du décalage, et la lui refuser
-- laisserait un changement de date sans raison. Les reports d'une récompense
-- qu'il ne voit pas ne le concernent pas.
create policy recompenses_reports_lecture on recompenses_reports
  for select to authenticated
  using (
    exists (
      select 1 from recompenses_familiales r
      where r.id = recompense_id
        and (
          est_intervenant(r.enfant_id)
          or (
            est_l_enfant(r.enfant_id)
            and (r.devoilee_le is not null or r.montrer_date)
          )
        )
    )
  );

create or replace function figer_ce_que_l_enfant_a_vu()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_nature_vue boolean := old.devoilee_le is not null or old.montrer_nature;
  v_date_vue boolean := old.devoilee_le is not null or old.montrer_date;
  v_jauge_vue boolean := old.devoilee_le is not null or old.montrer_progression;
begin
  if v_nature_vue and (
       new.libelle      is distinct from old.libelle
    or new.description  is distinct from old.description
    or new.photo_chemin is distinct from old.photo_chemin
  ) then
    raise exception 'L''enfant a déjà lu cette récompense : son intitulé et sa photo ne se réécrivent plus. Annulez-la en vous expliquant, ou promettez-en une autre.';
  end if;

  if v_jauge_vue and (
       coalesce(new.points_requis, 0)     > coalesce(old.points_requis, 0)
    or coalesce(new.missions_requises, 0) > coalesce(old.missions_requises, 0)
  ) then
    raise exception 'Relever une exigence que l''enfant voit revient à éloigner l''arrivée pendant qu''il court. On peut l''abaisser, pas la remonter.';
  end if;

  -- Poser une date là où il n'y en avait pas n'est pas un report : c'est une
  -- précision qu'on ajoute, et elle ne rompt aucune promesse. Seul le décalage
  -- d'une date déjà connue se motive.
  if v_date_vue
     and old.prevue_le is not null
     and new.prevue_le is distinct from old.prevue_le then

    if new.prevue_le is null then
      raise exception 'Retirer une date que l''enfant connaît la laisse sans repère. Reportez-la, ou annulez la récompense.';
    end if;

    if length(btrim(coalesce(new.motif, ''))) < 5 then
      raise exception 'Décaler une date que l''enfant connaît se motive : renseignez le motif, il lui sera montré.';
    end if;

    insert into recompenses_reports
      (recompense_id, ancienne_date, nouvelle_date, motif, reporte_par)
    values
      (old.id, old.prevue_le, new.prevue_le, btrim(new.motif), auth.uid());
  end if;

  return new;
end;
$$;

create trigger recompenses_figent_ce_qui_a_ete_vu
  before update on recompenses_familiales
  for each row execute function figer_ce_que_l_enfant_a_vu();

-- ------------------------------------------- prévenir quand le palier tombe

-- Les adultes sont prévenus dès que le palier est franchi, pour qu'ils pensent à
-- dévoiler. Sans ce signal, une surprise resterait fermée des semaines après
-- avoir été méritée — ce qui, du point de vue de l'enfant, revient à une
-- promesse non tenue. Et il est d'autant plus nécessaire que l'enfant, lui, ne
-- voit peut-être ni la jauge ni la date pour le rappeler.
create or replace function signaler_le_palier_franchi()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_rec record;
  v_points integer;
begin
  if not new.reussie then
    return new;
  end if;

  select points_gagnes into v_points from points_enfant where enfant_id = new.enfant_id;

  for v_rec in
    select r.id, r.libelle, r.montrer_nature, r.devoilee_le
    from recompenses_familiales r
    where r.enfant_id = new.enfant_id
      and r.statut = 'promise'
      -- Toutes les conditions chiffrées renseignées doivent être remplies.
      and (r.points_requis is not null or r.missions_requises is not null)
      and (r.points_requis is null or r.points_requis <= coalesce(v_points, 0))
      and (r.missions_requises is null
           or r.missions_requises <= missions_reussies(new.enfant_id))
      and not exists (
        select 1 from notifications n
        where n.enfant_id = new.enfant_id
          and n.type = 'recompense_approche'
          and n.corps = r.id::text
      )
  loop
    insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
    select i.profil_id, new.enfant_id, 'recompense_approche',
           case when v_rec.montrer_nature or v_rec.devoilee_le is not null
                then 'Palier atteint : ' || v_rec.libelle
                else 'Palier atteint — une surprise attend d''être dévoilée' end,
           v_rec.id::text,
           '/enfants/' || new.enfant_id || '/recompenses/' || v_rec.id
    from intervenants_enfant i
    where i.enfant_id = new.enfant_id
      and i.retire_le is null
      and i.role in ('parent', 'referent');
  end loop;

  return new;
end;
$$;

create trigger tentatives_signalent_le_palier
  after insert on tentatives
  for each row execute function signaler_le_palier_franchi();

-- ================================================ ce que l'enfant voit

-- L'enfant perd son accès direct à la table. RLS filtre des lignes, jamais des
-- colonnes : lui laisser lire la ligne lui livrerait `libelle`, `photo_chemin`
-- et `prevue_le` — c'est-à-dire tout, quels que soient les interrupteurs. Il
-- passe désormais par une fonction, seule capable de masquer champ par champ.
drop policy recompenses_familiales_lecture on recompenses_familiales;

create policy recompenses_familiales_lecture on recompenses_familiales
  for select to authenticated
  using (est_intervenant(enfant_id));

drop function if exists mes_recompenses(uuid);

create function mes_recompenses(p_enfant uuid)
returns table (
  recompense_id uuid,
  devoilee boolean,
  libelle text,
  description text,
  photo_chemin text,
  surprise_libelle text,
  surprise_image_chemin text,
  prevue_le date,
  jours_restants integer,
  horizon horizon_recompense,
  points_requis integer,
  points_actuels integer,
  missions_requises integer,
  missions_actuelles integer,
  progression numeric,
  de_la_part_de text
)
language sql stable security definer set search_path = public as $$
  select
    r.id,
    (r.devoilee_le is not null),
    case when r.devoilee_le is not null or r.montrer_nature then r.libelle else '' end,
    case when r.devoilee_le is not null or r.montrer_nature then r.description else '' end,
    case when r.devoilee_le is not null or r.montrer_nature then r.photo_chemin else null end,
    coalesce(pm.surprise_libelle, 'Une surprise'),
    pm.surprise_image_chemin,
    case when r.devoilee_le is not null or r.montrer_date then r.prevue_le else null end,
    case when r.devoilee_le is not null or r.montrer_date
         then (r.prevue_le - current_date)::integer else null end,
    case when r.devoilee_le is not null or r.montrer_date
         then horizon_de(r.prevue_le) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.points_requis else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then coalesce(p.points_gagnes, 0) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.missions_requises else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then missions_reussies(p_enfant) else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then progression_vers(p_enfant, r.points_requis, r.missions_requises) else null end,
    coalesce(pr.prenom, '')
  from recompenses_familiales r
  left join points_enfant p on p.enfant_id = r.enfant_id
  left join profils pr on pr.id = r.proposee_par
  left join projets_moteurs pm on pm.enfant_id = r.enfant_id and pm.actif
  where r.enfant_id = p_enfant
    and r.statut = 'promise'
    -- Une récompense dont on tait jusqu'à l'existence ne figure pas dans la
    -- liste. C'est le mode qui convient à l'enfant que l'attente met en boucle :
    -- il n'y a rien à attendre, jusqu'au jour où il y a quelque chose.
    and (r.montrer_existence or r.devoilee_le is not null)
    and (est_l_enfant(p_enfant) or est_intervenant(p_enfant))
  order by r.prevue_le nulls last;
$$;

-- La fonction qui alimente l'IA applique exactement le même masquage. Le modèle
-- rédige des textes que l'enfant lit : lui donner la récompense en clair
-- reviendrait à la divulguer par la première mission venue, et le soin pris à la
-- cacher n'aurait servi à rien.
drop function if exists recompenses_a_venir(uuid);

create function recompenses_a_venir(p_enfant uuid)
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
  missions_requises integer,
  missions_actuelles integer,
  progression numeric,
  condition text
)
language sql stable security definer set search_path = public as $$
  select
    r.id,
    case when r.devoilee_le is not null or r.montrer_nature
         then r.libelle
         else coalesce(pm.surprise_libelle, 'Une surprise') end,
    case when r.devoilee_le is not null or r.montrer_nature then r.description else '' end,
    case when r.devoilee_le is not null or r.montrer_nature then r.photo_chemin else null end,
    case when r.devoilee_le is not null or r.montrer_date then r.prevue_le else null end,
    case when r.devoilee_le is not null or r.montrer_date
         then (r.prevue_le - current_date)::integer else null end,
    case when r.devoilee_le is not null or r.montrer_date
         then horizon_de(r.prevue_le) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.points_requis else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then coalesce(p.points_gagnes, 0) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.missions_requises else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then missions_reussies(p_enfant) else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then progression_vers(p_enfant, r.points_requis, r.missions_requises) else null end,
    r.condition
  from recompenses_familiales r
  left join points_enfant p on p.enfant_id = r.enfant_id
  left join projets_moteurs pm on pm.enfant_id = r.enfant_id and pm.actif
  where r.enfant_id = p_enfant
    and r.statut = 'promise'
    and (r.montrer_existence or r.devoilee_le is not null)
    and (est_intervenant(p_enfant) or est_l_enfant(p_enfant))
  order by r.prevue_le nulls last;
$$;

-- L'image de substitution vit dans le bucket `recompenses`, sous {enfant_id}/,
-- et la politique de 0040 la rend déjà lisible à l'enfant. C'est voulu : elle
-- est faite pour être vue — c'est parfois tout ce qu'il verra.
