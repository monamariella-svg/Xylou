-- 0060 — Prévenir le transport, et savoir qu'il a lu.
--
-- Un enfant en transport adapté a un chauffeur qui vient le chercher à une
-- heure fixe. Quand le premier cours saute ou que le dernier est annulé, il faut
-- le prévenir — et aujourd'hui c'est le référent ou un parent qui appelle.
--
-- Il y a des loupés. Le problème n'est pas que personne ne prévient : c'est que
-- **personne ne sait si le message est arrivé**. On appelle, ça sonne dans le
-- vide, on se dit qu'on rappellera, et l'enfant attend devant le collège.
--
-- ---------------------------------------------------------------------------
-- CE QUI CHANGE : L'ACCUSÉ, PAS LA NOTIFICATION
--
-- Envoyer un message de plus ne réglerait rien — il s'ajouterait aux appels et
-- aux SMS déjà envoyés. Ce qui manque est la boucle : tant que le transporteur
-- n'a pas confirmé, le changement reste « annoncé, non confirmé », et quelqu'un
-- doit le voir.
--
-- D'où un lien d'accusé qui tient en un clic, sans compte à créer. Un chauffeur
-- n'a aucune raison de s'inscrire sur une plateforme d'accompagnement scolaire
-- pour dire « c'est noté ».
--
-- ---------------------------------------------------------------------------
-- CE QUE LE TRANSPORTEUR VOIT, ET RIEN D'AUTRE
--
-- Le prénom de l'enfant, la date, les heures. Pas le motif médical, pas les
-- objectifs, pas les échanges — rien du dossier. Il n'est pas un intervenant au
-- sens du schéma et n'a pas de rôle dans `intervenants_enfant` : lui en donner
-- un lui ouvrirait, via `est_intervenant()`, une trentaine de tables dont il n'a
-- que faire.
--
-- C'est le même raisonnement qu'en 0032 pour le compte enfant : un accès étroit
-- se déclare explicitement, il ne se dérive pas d'un rôle existant.
-- ---------------------------------------------------------------------------

alter type type_notification add value if not exists 'transport_modifie';

create table transporteurs (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,

  organisme text not null default '',
  contact text not null,
  email text not null default '',
  telephone text not null default '',

  actif boolean not null default true,
  cree_par uuid not null references profils on delete restrict,
  cree_le timestamptz not null default now(),

  constraint transporteur_joignable
    check (length(btrim(email)) > 0 or length(btrim(telephone)) > 0)
);

create index transporteurs_enfant_idx on transporteurs (enfant_id) where actif;

-- Les heures habituelles, par jour de semaine. Elles servent de référence : un
-- changement se dit par rapport à elles, et l'écart est ce qui compte pour le
-- chauffeur — « une heure plus tard » se comprend mieux qu'une heure absolue.
create table horaires_transport (
  enfant_id uuid not null references enfants on delete cascade,
  -- 1 = lundi, conforme à `isodow`.
  jour_semaine smallint not null check (jour_semaine between 1 and 7),
  prise_en_charge time,
  retour time,
  primary key (enfant_id, jour_semaine)
);

-- ------------------------------------------------------------ le changement

create table changements_transport (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,

  jour date not null,
  -- Nuls quand l'horaire correspondant ne change pas. Les deux nuls avec
  -- `annule` faux n'aurait aucun sens : la contrainte l'interdit.
  nouvelle_prise_en_charge time,
  nouveau_retour time,
  annule boolean not null default false,

  motif text not null default '',

  declare_par uuid not null references profils on delete restrict,
  cree_le timestamptz not null default now(),

  -- Le jeton du lien d'accusé. Court-circuite toute inscription : le chauffeur
  -- reçoit un lien, il clique, c'est confirmé.
  jeton text not null unique default encode(gen_random_bytes(18), 'hex'),

  annonce_le timestamptz,
  accuse_le timestamptz,
  accuse_par text not null default '',

  constraint changement_dit_quelque_chose
    check (annule or nouvelle_prise_en_charge is not null or nouveau_retour is not null)
);

create index changements_transport_jour_idx
  on changements_transport (enfant_id, jour desc);

-- Ce qui n'a pas été confirmé, et dont le jour approche. C'est la liste qui
-- remplace le « je crois que je l'ai eu au téléphone ».
create index changements_sans_accuse_idx
  on changements_transport (jour) where accuse_le is null;

-- ------------------------------------------------------------- annoncer

create or replace function annoncer_le_changement_de_transport(
  p_enfant uuid,
  p_jour date,
  p_prise_en_charge time default null,
  p_retour time default null,
  p_annule boolean default false,
  p_motif text default ''
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_changement uuid;
  v_prenom text;
  v_transporteur record;
  v_texte text;
  v_lien text;
begin
  -- Toute l'équipe peut annoncer : c'est souvent l'enseignant qui sait le
  -- premier qu'un cours saute, et l'obliger à passer par le référent est
  -- exactement le détour qui produit les loupés.
  if not est_intervenant(p_enfant) then
    raise exception 'Seules les personnes rattachées au dossier annoncent un changement de transport.';
  end if;

  select prenom into v_prenom from enfants where id = p_enfant;

  insert into changements_transport
    (enfant_id, jour, nouvelle_prise_en_charge, nouveau_retour, annule, motif, declare_par, annonce_le)
  values
    (p_enfant, p_jour, p_prise_en_charge, p_retour, p_annule, btrim(p_motif), auth.uid(), now())
  returning id into v_changement;

  v_texte :=
    coalesce(v_prenom, 'L''enfant') || ' — ' || to_char(p_jour, 'DD/MM/YYYY') || ' : ' ||
    case
      when p_annule then 'transport annulé'
      else
        coalesce('prise en charge à ' || to_char(p_prise_en_charge, 'HH24hMI'), '') ||
        case when p_prise_en_charge is not null and p_retour is not null then ', ' else '' end ||
        coalesce('retour à ' || to_char(p_retour, 'HH24hMI'), '')
    end ||
    case when btrim(p_motif) <> '' then '. ' || btrim(p_motif) else '' end;

  select id into v_lien from changements_transport where id = v_changement;

  -- Le transporteur reçoit directement dans la file : il n'a pas de compte, donc
  -- pas de ligne dans `notifications`. Le lien d'accusé est dans le corps.
  for v_transporteur in
    select t.contact, t.organisme, t.email
    from transporteurs t
    where t.enfant_id = p_enfant and t.actif and btrim(t.email) <> ''
  loop
    insert into envois
      (destinataire_id, destinataire_libelle, canal, adresse, sujet, corps, lien)
    values
      (null,
       v_transporteur.contact ||
         case when v_transporteur.organisme <> '' then ' (' || v_transporteur.organisme || ')' else '' end,
       'courriel', v_transporteur.email,
       'Changement de transport — ' || to_char(p_jour, 'DD/MM'),
       v_texte || E'\n\nMerci de confirmer en suivant le lien : sans confirmation, la famille sera relancée.',
       '/transport/' || (select jeton from changements_transport where id = v_changement));
  end loop;

  -- La famille et le référent sont prévenus aussi : ils doivent savoir que
  -- l'information est partie, et être relancés si elle n'est pas confirmée.
  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select i.profil_id, p_enfant, 'transport_modifie',
         'Transport modifié le ' || to_char(p_jour, 'DD/MM'),
         v_texte,
         '/enfants/' || p_enfant || '/transport'
  from intervenants_enfant i
  where i.enfant_id = p_enfant and i.retire_le is null
    and i.role in ('parent', 'referent')
    and i.profil_id <> auth.uid();

  return v_changement;
end;
$$;

-- --------------------------------------------------------------- accuser

-- Appelable sans être connecté : le jeton fait foi. C'est délibéré — exiger un
-- compte pour dire « c'est noté » garantirait que personne ne le dise.
create or replace function accuser_le_changement(p_jeton text, p_nom text default '')
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_id uuid;
begin
  select id into v_id from changements_transport
  where jeton = p_jeton and accuse_le is null and jour >= current_date - 1;

  if v_id is null then
    return false;
  end if;

  update changements_transport
    set accuse_le = now(), accuse_par = btrim(p_nom)
    where id = v_id;

  -- La famille apprend que c'est confirmé. C'est la moitié du dispositif : sans
  -- ce retour, on aurait déplacé l'incertitude sans la lever.
  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select i.profil_id, c.enfant_id, 'transport_modifie',
         'Transport confirmé pour le ' || to_char(c.jour, 'DD/MM'),
         case when btrim(p_nom) <> '' then 'Confirmé par ' || btrim(p_nom) || '.' else 'Confirmé par le transporteur.' end,
         '/enfants/' || c.enfant_id || '/transport'
  from changements_transport c
  join intervenants_enfant i on i.enfant_id = c.enfant_id
  where c.id = v_id and i.retire_le is null and i.role in ('parent', 'referent');

  return true;
end;
$$;

-- ------------------------------------------------- ce qui n'est pas confirmé

-- La relance. Un changement annoncé la veille et non confirmé le matin même est
-- exactement le cas où l'enfant attend devant le collège : il faut que quelqu'un
-- le voie avant, pas après.
create or replace function transports_sans_accuse(p_enfant uuid default null)
returns table (
  changement_id uuid,
  enfant_id uuid,
  prenom text,
  jour date,
  jours_restants integer,
  resume text,
  annonce_le timestamptz,
  transporteur text
)
language sql stable security definer set search_path = public as $$
  select
    c.id, c.enfant_id, e.prenom, c.jour,
    (c.jour - current_date)::integer,
    case
      when c.annule then 'Transport annulé'
      else
        coalesce('Prise en charge ' || to_char(c.nouvelle_prise_en_charge, 'HH24hMI'), '') ||
        case when c.nouvelle_prise_en_charge is not null and c.nouveau_retour is not null then ' · ' else '' end ||
        coalesce('Retour ' || to_char(c.nouveau_retour, 'HH24hMI'), '')
    end,
    c.annonce_le,
    coalesce((select string_agg(t.contact, ', ') from transporteurs t
              where t.enfant_id = c.enfant_id and t.actif), 'Aucun transporteur enregistré')
  from changements_transport c
  join enfants e on e.id = c.enfant_id
  where c.accuse_le is null
    and c.jour >= current_date
    and (p_enfant is null or c.enfant_id = p_enfant)
    and est_intervenant(c.enfant_id)
  order by c.jour, c.annonce_le;
$$;

-- ==================================================================== RLS

alter table transporteurs enable row level security;
alter table horaires_transport enable row level security;
alter table changements_transport enable row level security;

-- Le transporteur est une donnée d'organisation, pas de santé : toute l'équipe
-- la lit. L'AESH qui accompagne l'enfant jusqu'au véhicule a besoin de savoir
-- qui vient le chercher.
create policy transporteurs_lecture on transporteurs for select to authenticated
  using (est_intervenant(enfant_id));

create policy transporteurs_gestion on transporteurs for all to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));

create policy horaires_lecture on horaires_transport for select to authenticated
  using (est_intervenant(enfant_id) or est_l_enfant(enfant_id));

create policy horaires_gestion on horaires_transport for all to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));

create policy changements_lecture on changements_transport for select to authenticated
  using (est_intervenant(enfant_id) or est_l_enfant(enfant_id));

-- Les changements passent par `annoncer_le_changement_de_transport()`, qui
-- vérifie les droits et déclenche les envois. Une insertion directe créerait un
-- changement que personne ne recevrait.
create policy changements_correction on changements_transport for update to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));
