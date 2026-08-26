-- 0062 — Le référent répond de l'équipe qu'il compose.
--
-- 0025 laissait `peut_valider()` inviter, c'est-à-dire les parents autant que le
-- référent. Un parent pouvait donc rattacher un enseignant, une AESH, un second
-- référent — et personne ne répondait de ce rattachement.
--
-- Or c'est un acte lourd. Rattacher quelqu'un lui ouvre les objectifs, les
-- missions, le suivi quotidien, la progression de l'enfant. Le faire sur la foi
-- d'une adresse électronique tapée un soir, sans que personne ait vérifié que
-- cette personne est bien celle qu'elle prétend être, est exactement le genre de
-- porte qu'on regrette.
--
-- ---------------------------------------------------------------------------
-- POURQUOI LE RÉFÉRENT, ET PAS LA FAMILLE
--
-- Ce n'est pas une défiance envers les parents. C'est que le référent est le
-- seul à pouvoir vérifier : il connaît l'établissement, il sait qui y enseigne,
-- il a l'attestation de direction qui l'a lui-même fait habiliter. Un parent
-- connaît le nom du professeur de mathématiques ; il n'a aucun moyen de
-- s'assurer que l'adresse qu'on lui a donnée est bien la sienne.
--
-- La chaîne devient cohérente de bout en bout : l'administration répond du
-- référent, le référent répond de l'équipe. Chaque maillon vérifie le suivant,
-- et personne ne vérifie personne à sa place.
--
-- Ce que la famille garde : tout ce qui la concerne. Elle valide les objectifs,
-- signe les consentements, décide de la suppression, ouvre des conversations
-- privées. Elle ne compose pas l'équipe professionnelle, et n'a pas à le faire.
-- ---------------------------------------------------------------------------

drop policy invitations_creation on invitations;

create policy invitations_creation on invitations for insert to authenticated
  with check (
    invite_par = auth.uid()
    -- `definit_l_autorite_parentale()` vaut pour le référent du dossier et pour
    -- l'administration. C'est déjà la fonction qui gouverne l'établissement de
    -- l'autorité parentale : inviter revient au même cercle, et une seule
    -- notion vaut mieux que deux qui se ressembleraient.
    and definit_l_autorite_parentale(enfant_id)
  );

-- Le retrait suit la même logique. Sans cela, un parent ne pourrait pas inviter
-- un enseignant mais pourrait le retirer — ce qui reviendrait à lui laisser
-- composer l'équipe par soustraction.
--
-- Le retrait de soi-même reste ouvert à tous : personne n'est retenu dans un
-- dossier contre son gré.
create or replace function retirer_l_intervenant(
  p_enfant uuid,
  p_profil uuid,
  p_motif text default ''
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_role role_intervenant;
begin
  select role into v_role
  from intervenants_enfant
  where enfant_id = p_enfant and profil_id = p_profil and retire_le is null;

  if v_role is null then
    raise exception 'Cette personne n''est pas rattachée à ce dossier.';
  end if;

  -- Le lien parental relève de 0024 et 0025 : il ne se défait pas par ici.
  if v_role = 'parent' then
    raise exception 'Le rattachement d''un titulaire de l''autorité parentale ne se retire pas de cette façon.';
  end if;

  if not (definit_l_autorite_parentale(p_enfant) or p_profil = auth.uid()) then
    raise exception 'Retirer un intervenant revient au référent du dossier, ou à l''intéressé lui-même.';
  end if;

  update intervenants_enfant
    set retire_le = now(), motif_retrait = p_motif
    where enfant_id = p_enfant and profil_id = p_profil and retire_le is null;
end;
$$;

-- Qui, sur ce dossier, peut composer l'équipe. Sert à l'interface : proposer un
-- formulaire d'invitation à quelqu'un qui se fera refuser à l'envoi est une
-- promesse qu'on ne tient pas.
create or replace function peut_composer_l_equipe(p_enfant uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select definit_l_autorite_parentale(p_enfant);
$$;
