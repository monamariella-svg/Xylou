-- 0064 — L'identifiant qui rend l'établissement vérifiable.
--
-- 0063 a rendu l'adresse obligatoire, parce qu'un nom d'établissement n'en
-- désigne aucun en particulier. L'adresse lève l'ambiguïté mais reste
-- déclarative : rien ne dit qu'elle est exacte, et l'administration doit encore
-- la recouper à la main.
--
-- Le code UAI — ex-RNE, huit caractères du type 0123456A — identifie un
-- établissement scolaire sans ambiguïté et se vérifie dans l'annuaire public de
-- l'Éducation nationale. Renseigné, il permet de retrouver le nom exact,
-- l'adresse et le téléphone : ces champs cessent d'être déclarés pour devenir
-- vérifiés.
--
-- ---------------------------------------------------------------------------
-- FACULTATIF, ET IL DOIT LE RESTER
--
-- Seuls les établissements scolaires ont un UAI. Un IME, un SESSAD, un service
-- médico-social relèvent du répertoire FINESS, d'un autre format et d'un autre
-- annuaire — et une éducatrice spécialisée qui suit un enfant depuis un SESSAD
-- est exactement le profil de référent qu'on cherche.
--
-- Le rendre obligatoire écarterait donc une partie de ceux à qui l'outil est
-- destiné, pour gagner une commodité de vérification. L'adresse reste
-- l'exigence ; l'UAI est le raccourci quand il existe.
-- ---------------------------------------------------------------------------

alter table demandes_habilitation
  add column uai text not null default '';

comment on column demandes_habilitation.uai is
  'Code UAI de l''établissement scolaire, quand il en a un. Facultatif : les structures médico-sociales relèvent du répertoire FINESS.';

-- Format contrôlé mais souple : sept chiffres et une lettre, ou vide. On
-- normalise en majuscules à la saisie plutôt que de refuser « 0123456a », qui
-- est le même établissement écrit autrement.
alter table demandes_habilitation
  add constraint uai_bien_forme
  check (uai = '' or uai ~ '^[0-9]{7}[A-Z]$');

create or replace function demander_l_habilitation(
  p_fonction text,
  p_organisation text default '',
  p_numero text default '',
  p_motivation text default '',
  p_directeur_nom text default '',
  p_directeur_contact text default '',
  p_etablissement_adresse text default '',
  p_uai text default ''
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_demande uuid;
  v_role role_plateforme;
  v_uai text := upper(btrim(coalesce(p_uai, '')));
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

  if v_uai <> '' and v_uai !~ '^[0-9]{7}[A-Z]$' then
    raise exception 'Le code UAI se compose de sept chiffres suivis d''une lettre, par exemple 0123456A. Laissez-le vide si votre structure n''en a pas.';
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
    (profil_id, fonction, organisation, uai, etablissement_adresse,
     numero_professionnel, motivation, directeur_nom, directeur_contact)
  values
    (auth.uid(), btrim(p_fonction), btrim(p_organisation), v_uai,
     btrim(p_etablissement_adresse), btrim(p_numero), btrim(p_motivation),
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
  uai text,
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
    d.id, p.prenom, p.nom, p.email, d.fonction, d.organisation, d.uai,
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
  group by d.id, p.prenom, p.nom, p.email, d.fonction, d.organisation, d.uai,
           d.etablissement_adresse, d.numero_professionnel, d.motivation,
           d.directeur_nom, d.directeur_contact, d.cree_le
  order by d.cree_le;
$$;
