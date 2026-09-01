-- 0063 — Quel établissement, exactement.
--
-- 0060 demandait le nom de l'établissement et le directeur qui atteste. Le nom
-- seul ne désigne rien : il existe une trentaine de « collège Jean Moulin » en
-- France, et l'administration qui veut vérifier ne sait pas lequel appeler.
--
-- L'adresse ferme cette ambiguïté, et elle fait plus que cela : elle permet de
-- recouper. Un référent qui déclare exercer dans un établissement situé à trois
-- cents kilomètres des enfants qu'il suivra est une question à poser — pas
-- forcément un refus, les services de suivi couvrent parfois de vastes
-- territoires, mais quelque chose que l'instruction doit voir.

alter table demandes_habilitation
  add column etablissement_adresse text not null default '';

comment on column demandes_habilitation.etablissement_adresse is
  'Adresse de l''établissement. Le nom seul ne l''identifie pas — et c''est l''adresse qui permet à l''administration de retrouver la direction pour vérifier.';

create or replace function demander_l_habilitation(
  p_fonction text,
  p_organisation text default '',
  p_numero text default '',
  p_motivation text default '',
  p_directeur_nom text default '',
  p_directeur_contact text default '',
  p_etablissement_adresse text default ''
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

  if length(btrim(p_etablissement_adresse)) < 5 then
    raise exception 'Indiquez l''adresse de l''établissement : son nom seul ne l''identifie pas, et l''administration doit pouvoir le retrouver.';
  end if;

  if length(btrim(p_directeur_nom)) < 2 then
    raise exception 'Indiquez le nom du directeur de l''établissement : c''est lui qui atteste de votre fonction.';
  end if;

  if length(btrim(p_directeur_contact)) < 5 then
    raise exception 'Indiquez comment joindre la direction — adresse électronique ou téléphone. Une attestation qu''on ne peut pas vérifier ne vaut que la confiance qu''on accorde à celui qui la présente.';
  end if;

  insert into demandes_habilitation
    (profil_id, fonction, organisation, etablissement_adresse, numero_professionnel,
     motivation, directeur_nom, directeur_contact)
  values
    (auth.uid(), btrim(p_fonction), btrim(p_organisation), btrim(p_etablissement_adresse),
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

drop function if exists habilitations_a_instruire();

create function habilitations_a_instruire()
returns table (
  demande_id uuid,
  prenom text,
  nom text,
  email text,
  fonction text,
  organisation text,
  etablissement_adresse text,
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
    d.etablissement_adresse, d.numero_professionnel, d.motivation,
    d.directeur_nom, d.directeur_contact,
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
           d.etablissement_adresse, d.numero_professionnel, d.motivation,
           d.directeur_nom, d.directeur_contact, d.cree_le
  order by d.cree_le;
$$;
