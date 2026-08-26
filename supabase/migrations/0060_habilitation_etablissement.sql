-- 0060 — De qui le référent tient son attestation.
--
-- 0054 demandait une « organisation », en texte libre et facultative. C'était
-- trop peu. Une demande d'habilitation dit « je suis coordinatrice ULIS au
-- collège X » — et l'administration, devant cette phrase, ne peut rien faire
-- d'autre que croire.
--
-- Ce qui manque n'est pas une pièce de plus : c'est **quelqu'un à qui
-- téléphoner**. Une attestation de direction se vérifie en appelant la
-- direction, et cela suppose de savoir qui elle est et comment la joindre.
--
-- ---------------------------------------------------------------------------
-- POURQUOI CE N'EST PAS DE LA PAPERASSE
--
-- Le référent ouvre des dossiers d'enfants handicapés, établit qui détient
-- l'autorité parentale, accède aux données de santé. C'est la qualité la plus
-- lourde du système, et la seule qu'on accorde à quelqu'un qu'on ne connaît pas
-- forcément.
--
-- Exiger un établissement et un directeur joignables ne protège pas
-- l'administration : ça protège les familles dont les dossiers seront ouverts.
-- ---------------------------------------------------------------------------

alter table demandes_habilitation
  add column directeur_nom text not null default '',
  add column directeur_contact text not null default '';

comment on column demandes_habilitation.directeur_contact is
  'Adresse ou téléphone du directeur d''établissement. Sert à vérifier l''attestation — c''est sa seule raison d''être, et il ne doit servir à rien d''autre.';

-- Les trois deviennent nécessaires. Le défaut vide laisse passer les demandes
-- déjà déposées, s'il y en a : les invalider rétroactivement obligerait à
-- recommencer une démarche déjà faite.
create or replace function demander_l_habilitation(
  p_fonction text,
  p_organisation text default '',
  p_numero text default '',
  p_motivation text default '',
  p_directeur_nom text default '',
  p_directeur_contact text default ''
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_demande uuid;
  v_role role_plateforme;
begin
  select role_plateforme into v_role from profils where id = auth.uid();

  if v_role in ('referent', 'admin') then
    raise exception 'Votre compte a déjà cette habilitation.';
  end if;

  if length(btrim(p_fonction)) < 3 then
    raise exception 'Indiquez votre fonction : c''est ce que l''administration lira en premier.';
  end if;

  if length(btrim(p_organisation)) < 2 then
    raise exception 'Indiquez l''établissement ou la structure où vous exercez.';
  end if;

  if length(btrim(p_directeur_nom)) < 2 then
    raise exception 'Indiquez le nom du directeur de l''établissement : c''est lui qui atteste de votre fonction.';
  end if;

  if length(btrim(p_directeur_contact)) < 5 then
    raise exception 'Indiquez comment joindre la direction — adresse électronique ou téléphone. Une attestation qu''on ne peut pas vérifier ne vaut que la confiance qu''on accorde à celui qui la présente.';
  end if;

  insert into demandes_habilitation
    (profil_id, fonction, organisation, numero_professionnel, motivation,
     directeur_nom, directeur_contact)
  values
    (auth.uid(), btrim(p_fonction), btrim(p_organisation),
     btrim(p_numero), btrim(p_motivation),
     btrim(p_directeur_nom), btrim(p_directeur_contact))
  returning id into v_demande;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select p.id, null, 'habilitation_demandee',
         'Demande de référent : ' || btrim(p_organisation),
         btrim(p_fonction) || ' — atteste : ' || btrim(p_directeur_nom),
         '/administration'
  from profils p where p.role_plateforme = 'admin';

  return v_demande;
end;
$$;

-- La file d'instruction montre de qui vient l'attestation, et comment le
-- joindre. Sans ces deux colonnes à l'écran, l'administration devrait ouvrir la
-- demande pour savoir si elle est vérifiable — donc ne le ferait pas.
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
  depuis_jours integer
)
language sql stable security definer set search_path = public as $$
  select
    d.id, p.prenom, p.nom, p.email, d.fonction, d.organisation,
    d.numero_professionnel, d.motivation, d.directeur_nom, d.directeur_contact,
    count(pi.id),
    coalesce(string_agg(distinct pi.type_piece::text, ', '), ''),
    count(pi.id) filter (where pi.valable_jusqu_au is not null
                           and pi.valable_jusqu_au < current_date),
    (current_date - d.cree_le::date)::integer
  from demandes_habilitation d
  join profils p on p.id = d.profil_id
  left join habilitation_pieces pi on pi.demande_id = d.id
  where d.statut = 'en_attente' and est_admin()
  group by d.id, p.prenom, p.nom, p.email, d.fonction, d.organisation,
           d.numero_professionnel, d.motivation, d.directeur_nom,
           d.directeur_contact, d.cree_le
  order by d.cree_le;
$$;
