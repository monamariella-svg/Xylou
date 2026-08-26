-- 0022 — Personne ne valide sa propre proposition.
--
-- `peut_valider()` réunit les parents et le référent, et c'est juste partout où
-- il sert : les données de santé, les décisions sur l'IA, l'intime. Mais appliqué
-- à la validation d'un objectif, il laissait passer une boucle — le référent
-- proposait un objectif et le validait dans la foulée. La supervision devenait
-- une formalité qu'on s'accorde à soi-même.
--
-- Trois règles, et la troisième est celle que le schéma ne savait pas dire :
--
--   1. Qui valide signe. `valide_par` est celui qui écrit, pas un nom qu'on
--      choisit dans une liste.
--   2. Un objectif transversal — social, communication, comportement — est validé
--      par un titulaire de l'autorité parentale. Le référent le pilote et il en
--      répond, mais ce qui engage l'enfant sur ce terrain-là relève des parents.
--
-- Ce fichier portait une troisième règle — « un professionnel ne valide pas ce
-- qu'il a proposé » — retirée depuis. 0023 fait de la validation un quorum de
-- tous les titulaires de l'autorité parentale, ce qui interdit bien plus
-- sûrement de valider seul sa propre proposition : personne ne valide seul.
-- La règle n'était pas seulement redondante, elle bloquait un quorum rempli
-- lorsque le proposant se trouvait signer en dernier.
--
-- La partie sur les demandes de modification, elle, reste : une demande se
-- tranche par une seule personne, et cette personne ne doit pas être celle qui
-- l'a formulée.

create or replace function verifier_la_validation_de_l_objectif()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  -- Rien à vérifier tant que l'objectif n'est pas validé, ni s'il l'était déjà.
  if new.statut <> 'valide' then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.statut = 'valide' then
    return new;
  end if;

  if new.valide_par is distinct from auth.uid() then
    raise exception 'Qui valide un objectif le signe : valide_par doit être le compte qui écrit.';
  end if;

  if new.domaine_code is not null
     and not est_intervenant(new.enfant_id, array['parent']::role_intervenant[]) then
    raise exception 'Un objectif transversal est validé par un titulaire de l''autorité parentale. Le référent le pilote, il ne l''arbitre pas.';
  end if;

  -- Il y avait ici une règle interdisant à un professionnel de valider sa propre
  -- proposition. 0023 la rend inutile et, pire, nuisible : la validation y
  -- devient un quorum de tous les titulaires de l'autorité parentale, et
  -- `valide_par` n'enregistre plus que celui qui a signé en dernier. Un référent
  -- qui propose un objectif et le contresigne après les deux parents n'esquive
  -- rien — refuser sa signature au motif qu'il est à l'origine de l'objectif
  -- bloquerait un quorum parfaitement rempli.
  --
  -- Ce que la règle protégeait est désormais porté par le quorum lui-même :
  -- personne ne peut valider seul ce qu'il a proposé, puisque personne ne valide
  -- seul.

  return new;
end;
$$;

create trigger objectifs_verifient_leur_validation
  before insert or update on objectifs
  for each row execute function verifier_la_validation_de_l_objectif();

-- Le même raisonnement vaut pour la demande de modification de 0016 : un
-- référent qui demande un changement et le traite lui-même a simplement modifié
-- l'objectif en deux écritures au lieu d'une.
create or replace function verifier_le_traitement_de_la_demande()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_role role_intervenant;
  v_enfant uuid;
begin
  if new.statut = 'ouverte' or (tg_op = 'UPDATE' and old.statut <> 'ouverte') then
    return new;
  end if;

  -- Retirer sa propre demande reste possible : on renonce, on ne tranche pas.
  if new.statut = 'retiree' then
    return new;
  end if;

  if new.traite_par = new.demande_par then
    select o.enfant_id into v_enfant from objectifs o where o.id = new.objectif_id;

    select i.role into v_role
    from intervenants_enfant i
    where i.enfant_id = v_enfant
      and i.profil_id = new.demande_par
      and i.retire_le is null
    limit 1;

    if v_role is distinct from 'parent' then
      raise exception 'Un professionnel ne tranche pas la demande de modification qu''il a formulée.';
    end if;
  end if;

  return new;
end;
$$;

create trigger objectifs_demandes_verifient_leur_traitement
  before insert or update on objectifs_demandes
  for each row execute function verifier_le_traitement_de_la_demande();
