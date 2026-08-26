-- 0061 — Ce qu'on exigera, et qu'on n'exige pas encore.
--
-- 0054 laisse accorder une habilitation sans aucune pièce, à condition de dire
-- sur quoi l'on se fonde. C'est le bon réglage pour le pilote : la première
-- équipe se compose de gens qu'on connaît, et leur imposer une procédure
-- administrative avant même d'avoir montré l'outil serait le meilleur moyen de
-- ne jamais le leur montrer. Le §3.4 identifie l'adoption comme le risque
-- principal, et ce risque-là se paie au premier contact.
--
-- Mais ce réglage ne peut pas survivre au pilote. Un référent ouvre des dossiers
-- d'enfants handicapés, établit qui détient l'autorité parentale, lit des
-- données de santé. En production, cela ne s'accorde pas sur une connaissance
-- personnelle.
--
-- ---------------------------------------------------------------------------
-- LA BASCULE TIENT EN UNE LIGNE
--
-- Le jour venu, on modifie `pieces_exigees()` et rien d'autre. Toutes les
-- demandes en cours et à venir suivent immédiatement.
--
-- C'est le même dispositif que `duree_conservation()` en 0058, et pour la même
-- raison : une règle qui doit changer un jour se met à un seul endroit, sinon
-- elle se change à moitié.
--
-- Pour passer en production :
--
--   select array['attestation_direction']::type_piece_habilitation[];
--
-- Et si l'on veut davantage :
--
--   select array['attestation_direction', 'piece_identite']::type_piece_habilitation[];
-- ---------------------------------------------------------------------------

create or replace function pieces_exigees()
returns type_piece_habilitation[]
language sql immutable as $$
  -- PHASE PILOTE : aucune pièce exigée. Voir l'en-tête avant de modifier.
  select array[]::type_piece_habilitation[];
$$;

comment on function pieces_exigees() is
  'Types de pièces sans lesquels une habilitation ne peut pas être accordée. Vide pendant le pilote — à renseigner avant la mise en production. Modifier ici et nulle part ailleurs.';

-- Ce qui manque à une demande donnée. Sert à l'écran d'instruction, pour que
-- l'administration voie l'exigence avant de buter dessus.
create or replace function pieces_manquantes(p_demande uuid)
returns type_piece_habilitation[]
language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(t), array[]::type_piece_habilitation[])
  from unnest(pieces_exigees()) t
  where not exists (
    select 1 from habilitation_pieces p
    where p.demande_id = p_demande
      and p.type_piece = t
      -- Une pièce périmée ne compte pas : une attestation de 2019 ne prouve
      -- rien de 2026, et l'accepter viderait l'exigence de son sens.
      and (p.valable_jusqu_au is null or p.valable_jusqu_au >= current_date)
  );
$$;

create or replace function accepter_l_habilitation(
  p_demande uuid,
  p_valable_jusqu_au date default null,
  p_motif text default ''
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_profil uuid;
  v_pieces integer;
  v_manquantes type_piece_habilitation[];
begin
  if not est_admin() then
    raise exception 'L''instruction des demandes revient à l''administration.';
  end if;

  select profil_id into v_profil
  from demandes_habilitation
  where id = p_demande and statut = 'en_attente';

  if v_profil is null then
    raise exception 'Demande introuvable ou déjà instruite.';
  end if;

  -- Le verrou de production. Vide pendant le pilote, donc sans effet — mais
  -- présent, et donc impossible à oublier le jour où on le remplit.
  v_manquantes := pieces_manquantes(p_demande);

  if array_length(v_manquantes, 1) > 0 then
    raise exception 'Cette demande ne peut pas être accordée : il manque % (ou la pièce fournie est périmée).',
      array_to_string(v_manquantes, ', ');
  end if;

  -- Sans exigence formelle, accorder sans rien lire reste possible — mais se
  -- dit. Le jour où quelqu'un demandera sur quoi cette habilitation reposait,
  -- « je la connais, elle coordonne l'ULIS du collège X » est une réponse
  -- recevable, à condition d'avoir été écrite ce jour-là.
  select count(*) into v_pieces from habilitation_pieces where demande_id = p_demande;

  if v_pieces = 0 and length(btrim(p_motif)) < 10 then
    raise exception 'Aucune pièce justificative n''a été versée. Vous pouvez accorder l''habilitation malgré tout, mais dites sur quoi vous vous fondez.';
  end if;

  update demandes_habilitation
    set statut = 'acceptee', traitee_par = auth.uid(), traitee_le = now(),
        motif = btrim(p_motif), valable_jusqu_au = p_valable_jusqu_au
    where id = p_demande;

  update profils set role_plateforme = 'referent' where id = v_profil;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  values (v_profil, null, 'habilitation_traitee',
          'Votre habilitation de référent est accordée',
          'Vous pouvez désormais ouvrir des dossiers.',
          '/tableau-de-bord');
end;
$$;

-- L'écran d'instruction affiche ce qui manque. Colonne ajoutée en fin de table
-- pour que l'ordre des précédentes ne bouge pas.
drop function if exists habilitations_a_instruire();

create function habilitations_a_instruire()
returns table (
  demande_id uuid,
  prenom text,
  nom text,
  email text,
  fonction text,
  organisation text,
  numero_professionnel text,
  motivation text,
  directeur_nom text,
  directeur_contact text,
  pieces bigint,
  types_fournis text,
  pieces_perimees bigint,
  depuis_jours integer,
  manquantes text
)
language sql stable security definer set search_path = public as $$
  select
    d.id, p.prenom, p.nom, p.email, d.fonction, d.organisation,
    d.numero_professionnel, d.motivation, d.directeur_nom, d.directeur_contact,
    count(pi.id),
    coalesce(string_agg(distinct pi.type_piece::text, ', '), ''),
    count(pi.id) filter (where pi.valable_jusqu_au is not null
                           and pi.valable_jusqu_au < current_date),
    (current_date - d.cree_le::date)::integer,
    array_to_string(pieces_manquantes(d.id), ', ')
  from demandes_habilitation d
  join profils p on p.id = d.profil_id
  left join habilitation_pieces pi on pi.demande_id = d.id
  where d.statut = 'en_attente' and est_admin()
  group by d.id, p.prenom, p.nom, p.email, d.fonction, d.organisation,
           d.numero_professionnel, d.motivation, d.directeur_nom,
           d.directeur_contact, d.cree_le
  order by d.cree_le;
$$;
