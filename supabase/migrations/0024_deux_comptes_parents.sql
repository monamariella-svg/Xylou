-- 0024 — Chaque parent a son propre compte, et personne ne parle pour l'autre.
--
-- 0001 a été écrit avec en tête un modèle où un parent inscrit les autres. Deux
-- politiques en portent la trace, et elles deviennent dangereuses dès lors que
-- 0023 fait reposer la validation sur le nombre de parents rattachés :
--
--   `intervenants_ajout`  laissait un parent insérer une ligne pour n'importe
--                         quel profil. Rattacher quelqu'un à l'enfant devenait
--                         un geste unilatéral, sans que l'intéressé le sache.
--
--   `intervenants_retrait` laissait un parent retirer l'autre. En garde
--                         alternée, retirer le co-parent fait tomber le quorum
--                         à un — et l'objectif se valide seul, dans la foulée.
--                         Le mécanisme censé protéger du passage en force en
--                         devenait l'instrument.
--
-- Ici, les deux parents ont chacun leur compte. Un rattachement se fait donc par
-- invitation acceptée, jamais par insertion d'autorité, et le lien d'un parent à
-- son enfant ne se défait pas depuis le compte d'un tiers.

-- ------------------------------------------------- accepter une invitation

-- `invitations` existait depuis 0001 avec son jeton et sa date d'acceptation,
-- mais rien ne transformait une invitation acceptée en rattachement : la colonne
-- se remplissait et il ne se passait rien. C'est ici que le lien se crée.
--
-- SECURITY DEFINER parce que l'invité n'a, par définition, aucun droit sur
-- l'enfant au moment où il accepte : aucune politique ne peut lui ouvrir
-- `intervenants_enfant` avant que la ligne qui l'y autoriserait existe.
create or replace function accepter_l_invitation(p_jeton text)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_inv invitations%rowtype;
begin
  select * into v_inv
  from invitations
  where jeton = p_jeton
    and acceptee_le is null
    and annulee_le is null
    and expire_le > now();

  if not found then
    raise exception 'Invitation introuvable, déjà acceptée, annulée ou expirée.';
  end if;

  -- Le jeton ne suffit pas : il circule par courriel, et un courriel se
  -- transfère. L'adresse du compte connecté doit être celle de l'invitation.
  if lower(v_inv.email) <> email_courant() then
    raise exception 'Cette invitation a été adressée à une autre adresse que celle de votre compte.';
  end if;

  insert into intervenants_enfant
    (enfant_id, profil_id, role, fonction, matiere_code, invite_par)
  values
    (v_inv.enfant_id, auth.uid(), v_inv.role, v_inv.fonction, v_inv.matiere_code, v_inv.invite_par)
  on conflict (enfant_id, profil_id) do nothing;

  update invitations set acceptee_le = now() where id = v_inv.id;

  return v_inv.enfant_id;
end;
$$;

-- ------------------------------------------------- rattachement d'autorité

drop policy intervenants_ajout on intervenants_enfant;

-- Il ne reste qu'un cas d'insertion directe : celui qui vient de créer la fiche
-- s'y rattache lui-même. Tout le reste passe par `accepter_l_invitation()`,
-- c'est-à-dire par un geste de la personne concernée.
create policy intervenants_ajout on intervenants_enfant for insert to authenticated
  with check (
    profil_id = auth.uid()
    and exists (
      select 1 from enfants e
      where e.id = enfant_id and e.cree_par = auth.uid()
    )
  );

-- ------------------------------------------- le lien parental ne se défait pas

-- `intervenants_maj` et `intervenants_retrait` restent ouvertes aux parents pour
-- les autres rôles — retirer un enseignant qui change d'établissement est un
-- geste ordinaire. Sur une ligne de parent, en revanche, seul l'intéressé agit.
--
-- Cela rend volontairement impossible de retirer un parent depuis
-- l'application. Ce n'est pas un oubli : une autorité parentale se perd par
-- décision de justice, pas par un clic de l'autre parent. Le jour où le cas se
-- présente, il se traite hors de l'outil, avec les pièces qui l'établissent.
create or replace function proteger_le_lien_parental()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_role role_intervenant := coalesce(old.role, new.role);
  v_profil uuid := coalesce(old.profil_id, new.profil_id);
begin
  if v_role = 'parent' and v_profil is distinct from auth.uid() then
    raise exception 'Le rattachement d''un titulaire de l''autorité parentale ne se modifie ni ne se retire depuis un autre compte.';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

create trigger intervenants_protegent_le_lien_parental
  before update or delete on intervenants_enfant
  for each row execute function proteger_le_lien_parental();

-- ---------------------------------------------- supprimer la fiche enfant

-- `enfants_suppression` autorisait n'importe quel parent à supprimer la fiche.
-- Avec deux comptes distincts, c'est le même passage en force que le retrait du
-- co-parent, en plus définitif : la cascade emporte objectifs, tentatives,
-- messages et alertes.
--
-- La suppression reste possible quand un seul parent est rattaché. À plusieurs,
-- l'archivage (`archive_le`, prévu en 0001) rend la fiche inactive sans détruire
-- ce que l'autre parent n'a pas accepté de perdre.
create or replace function proteger_la_suppression_de_l_enfant()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (
    select count(*) from intervenants_enfant i
    where i.enfant_id = old.id and i.role = 'parent' and i.retire_le is null
  ) > 1 then
    raise exception 'Deux titulaires de l''autorité parentale sont rattachés : archivez la fiche plutôt que de la supprimer, ou retirez-vous vous-même.';
  end if;
  return old;
end;
$$;

create trigger enfants_protegent_leur_suppression
  before delete on enfants
  for each row execute function proteger_la_suppression_de_l_enfant();
