-- 0056 — Le piège du NULL dans une comparaison.
--
-- 0036 exige qu'un enseignant couvre au moins une matière, et le vérifie par un
-- trigger différé sur `intervenants_matieres`. La fonction commence par écarter
-- les autres rôles :
--
--   select i.role into v_role from intervenants_enfant i where i.id = ...;
--   if v_role <> 'enseignant' then return null; end if;
--
-- Le raisonnement suppose que la ligne d'intervenant existe. Elle n'existe plus
-- quand on supprime l'intervenant lui-même : les matières partent en cascade, le
-- trigger différé se réveille, et `v_role` est nul.
--
-- Or `null <> 'enseignant'` ne vaut pas vrai — il vaut null. La sortie anticipée
-- ne se déclenche donc pas, et la fonction va exiger une matière pour quelqu'un
-- qui vient d'être effacé.
--
-- ---------------------------------------------------------------------------
-- CE QUE ÇA CASSAIT VRAIMENT
--
-- Bien plus que le nettoyage d'un jeu d'essai : **supprimer un enseignant
-- devenait impossible**. La politique `intervenants_retrait` l'autorise depuis
-- 0026, l'application l'aurait proposé, et l'erreur serait tombée devant
-- l'utilisateur — avec un message parlant d'une matière manquante, c'est-à-dire
-- envoyant chercher exactement au mauvais endroit.
--
-- `is distinct from` traite le null comme une valeur, ce qui est le
-- comportement voulu partout dans ce schéma. C'est l'opérateur à employer par
-- défaut dès qu'une comparaison peut rencontrer un null.
-- ---------------------------------------------------------------------------

create or replace function exiger_une_matiere_a_l_enseignant()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_role role_intervenant;
begin
  select i.role into v_role
  from intervenants_enfant i
  where i.id = coalesce(new.intervenant_id, old.intervenant_id);

  -- L'intervenant a disparu : il n'y a plus personne à qui exiger une matière.
  if v_role is distinct from 'enseignant' then
    return null;
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    where i.id = coalesce(new.intervenant_id, old.intervenant_id)
      and (
        i.toutes_matieres
        or exists (select 1 from intervenants_matieres m where m.intervenant_id = i.id)
      )
  ) then
    raise exception 'Un enseignant couvre au moins une matière, ou toutes.';
  end if;

  return null;
end;
$$;

-- Le même piège guettait la vérification au rattachement. Elle lit `new`, qui
-- existe toujours en INSERT et UPDATE — donc pas de null possible ici. Mais un
-- intervenant retiré n'a plus à couvrir quoi que ce soit, et la condition le
-- disait déjà. Reprise pour cohérence de lecture, sans changement de fond.
create or replace function exiger_une_matiere_au_rattachement()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.role is distinct from 'enseignant' or new.retire_le is not null then
    return null;
  end if;

  if new.toutes_matieres then
    return null;
  end if;

  if not exists (
    select 1 from intervenants_matieres m where m.intervenant_id = new.id
  ) then
    raise exception 'Un enseignant couvre au moins une matière, ou toutes. Renseignez son périmètre.';
  end if;

  return null;
end;
$$;
