-- 0045 — Ce qui s'exécute sans utilisateur connecté.
--
-- Six triggers de protection posent la même question de la mauvaise façon. Ils
-- demandent « cette personne a-t-elle le droit ? » sans envisager qu'il puisse
-- n'y avoir personne — et refusent alors par défaut.
--
-- Or trois contextes légitimes n'ont aucun utilisateur connecté :
--
--   le SQL Editor de Supabase, où l'on amorce et où l'on répare ;
--   la clé de service, qu'utilisent les traitements de fond ;
--   les migrations et les jeux d'essai.
--
-- Dans ces trois cas, `auth.uid()` est nul. Ce n'est pas un utilisateur sans
-- droits : c'est un accès direct à la base, par définition privilégié — celui
-- qui l'a peut de toute façon désactiver n'importe quel trigger.
--
-- ---------------------------------------------------------------------------
-- LE BUG QUE ÇA CACHAIT
--
-- 0026 indiquait comment créer le premier administrateur :
--
--   update profils set role_plateforme = 'admin' where email = '…';
--
-- Cette requête est refusée par le trigger de 0026 lui-même, qui exige
-- `est_admin()` — alors qu'aucun administrateur n'existe encore. La porte se
-- ferme de l'intérieur, et l'application est inutilisable dès le premier jour :
-- sans admin, pas de référent ; sans référent, pas de dossier.
--
-- Le défaut était invisible à la lecture. Il est apparu à la première seconde
-- du script de vérification, avant même la première assertion.
-- ---------------------------------------------------------------------------
--
-- La règle appliquée ici distingue deux natures de garde-fou :
--
--   les gardes d'AUTORISATION — « qui a le droit de faire ça » — cèdent devant
--   un contexte de confiance, puisque la question n'a pas de sens sans
--   personne à qui la poser. Ce sont les six ci-dessous.
--
--   les gardes d'INTÉGRITÉ — « est-ce cohérent » — ne cèdent pas. Le quorum de
--   validation, le figement d'une pièce justificative, l'interdiction de
--   recacher une récompense dévoilée restent opposables à tout le monde, clé de
--   service comprise. Une règle de cohérence qu'on peut contourner n'en est pas
--   une.

-- ------------------------------------------------------ la qualité d'un compte

create or replace function proteger_le_role_plateforme()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.role_plateforme is distinct from old.role_plateforme
     and auth.uid() is not null
     and not est_admin() then
    raise exception 'La qualité d''un compte est établie par l''administration.';
  end if;
  return new;
end;
$$;

-- ------------------------------------------------- la composition parentale

create or replace function proteger_la_composition_parentale()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.titulaires_autorite_parentale is distinct from old.titulaires_autorite_parentale
     and auth.uid() is not null
     and not definit_l_autorite_parentale(new.id) then
    raise exception 'Seul le référent établit le nombre de titulaires de l''autorité parentale.';
  end if;
  return new;
end;
$$;

-- ------------------------------------------------------------ le lien parental

create or replace function proteger_le_lien_parental()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_profil uuid := coalesce(old.profil_id, new.profil_id);
  v_enfant uuid := coalesce(old.enfant_id, new.enfant_id);
  v_touche_un_parent boolean :=
    coalesce(old.role, new.role) = 'parent'
    or (tg_op = 'UPDATE' and new.role = 'parent');
begin
  if auth.uid() is null then
    if tg_op = 'DELETE' then return old; end if;
    return new;
  end if;

  if v_profil = auth.uid() then
    if tg_op = 'UPDATE'
       and new.role = 'parent'
       and old.role is distinct from 'parent' then
      raise exception 'On ne se déclare pas soi-même titulaire de l''autorité parentale.';
    end if;

  elsif v_touche_un_parent and not definit_l_autorite_parentale(v_enfant) then
    raise exception 'Seul le référent établit qui détient l''autorité parentale.';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

-- --------------------------------------------------------- le compte enfant

create or replace function proteger_le_compte_enfant()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.compte_id is distinct from old.compte_id
     and auth.uid() is not null
     and not (peut_valider(new.id) or est_admin()) then
    raise exception 'Le compte d''un enfant est rattaché par ses parents ou son référent.';
  end if;
  return new;
end;
$$;

-- ----------------------------------------------------- le pilotage d'objectif

create or replace function restreindre_le_pilotage()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or peut_valider(new.enfant_id) then
    return new;
  end if;

  if new.libelle            is distinct from old.libelle
  or new.description        is distinct from old.description
  or new.statut             is distinct from old.statut
  or new.valide_par         is distinct from old.valide_par
  or new.valide_le          is distinct from old.valide_le
  or new.granularite        is distinct from old.granularite
  or new.objectif_parent_id is distinct from old.objectif_parent_id
  or new.matiere_code       is distinct from old.matiere_code
  or new.domaine_code       is distinct from old.domaine_code
  or new.enfant_id          is distinct from old.enfant_id then
    raise exception 'Seuls la famille et le référent modifient un objectif validé. Le pilote ajuste la période, le nombre d''exercices et le critère de fin — pour le reste, passez par une demande de modification.';
  end if;

  return new;
end;
$$;

-- ------------------------------------------------ la signature de validation

-- `exiger_le_quorum` n'est PAS assoupli : le quorum est une règle de cohérence,
-- pas une question de droits. Un objectif ne doit pas pouvoir passer à « validé »
-- sans ses signatures, quel que soit le chemin emprunté — et le script de
-- vérification compte là-dessus pour prouver que la règle tient.
create or replace function verifier_la_validation_de_l_objectif()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.statut <> 'valide' then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.statut = 'valide' then
    return new;
  end if;

  -- Sans utilisateur connecté, il n'y a personne pour signer : la vérification
  -- de signature n'a pas d'objet. Le quorum, lui, s'applique toujours.
  if auth.uid() is null then
    return new;
  end if;

  if new.valide_par is distinct from auth.uid() then
    raise exception 'Qui valide un objectif le signe : valide_par doit être le compte qui écrit.';
  end if;

  if new.domaine_code is not null
     and not est_intervenant(new.enfant_id, array['parent']::role_intervenant[]) then
    raise exception 'Un objectif transversal est validé par un titulaire de l''autorité parentale. Le référent le pilote, il ne l''arbitre pas.';
  end if;

  return new;
end;
$$;

-- ------------------------------------------------------------ l'amorçage

-- L'instruction de 0026, désormais exécutable. À lancer une fois, en
-- remplaçant l'adresse — après quoi cet administrateur crée les suivants
-- depuis l'application.
--
--   update profils set role_plateforme = 'admin' where email = 'vous@exemple.fr';
