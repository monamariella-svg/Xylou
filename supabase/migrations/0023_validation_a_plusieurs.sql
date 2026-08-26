-- 0023 — Quand la validation demande plusieurs signatures.
--
-- `valide_par` est une colonne unique : elle sait dire qui a validé, jamais
-- qu'il manque quelqu'un. Or l'autorité parentale se partage. En garde alternée,
-- un objectif validé par un seul parent n'est pas un objectif validé — c'est un
-- objectif validé par un parent, et l'autre l'apprendra en le découvrant fait.
--
-- Le désaccord entre parents séparés sur ce qui doit être travaillé n'est pas un
-- cas de bord : c'est une situation ordinaire, et l'outil n'a pas à trancher à
-- leur place. Il doit seulement refuser d'avancer tant que les deux n'ont pas
-- signé, et rendre visible qui manque.
--
-- La validation devient donc un quorum :
--
--   tous les titulaires de l'autorité parentale rattachés à l'enfant ;
--   plus le référent, pour un objectif de matière.
--
-- Un parent seul valide seul — le quorum vaut un. Rien à traiter comme
-- exception : la règle est « tous les parents », et tous, parfois, c'est un.
--
-- Le référent est exclu du quorum sur les objectifs transversaux, en cohérence
-- avec 0022 : il les pilote, il ne les arbitre pas.

create table objectifs_validations (
  objectif_id uuid not null references objectifs on delete cascade,
  profil_id uuid not null references profils on delete cascade,
  valide_le timestamptz not null default now(),
  commentaire text not null default '',
  primary key (objectif_id, profil_id)
);

create index objectifs_validations_profil_idx
  on objectifs_validations (profil_id);

-- Qui doit signer pour cet objectif. Recalculé à chaque appel plutôt que figé à
-- la création : un second parent rattaché après coup — reconnaissance, jugement,
-- ou simple oubli réparé — entre dans le quorum des objectifs encore ouverts,
-- ce qui est le comportement souhaitable.
create or replace function valideurs_requis(p_objectif uuid)
returns table (profil_id uuid)
language sql stable security definer set search_path = public as $$
  select i.profil_id
  from objectifs o
  join intervenants_enfant i on i.enfant_id = o.enfant_id
  where o.id = p_objectif
    and i.retire_le is null
    and (
      i.role = 'parent'
      or (i.role = 'referent' and o.matiere_code is not null)
    );
$$;

create or replace function objectif_pleinement_valide(p_objectif uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select not exists (
    select 1 from valideurs_requis(p_objectif) r
    where not exists (
      select 1 from objectifs_validations v
      where v.objectif_id = p_objectif and v.profil_id = r.profil_id
    )
  );
$$;

-- Ce qui manque, pour l'afficher : « en attente de la signature de Camille »
-- plutôt qu'un objectif bloqué sans explication.
create or replace function valideurs_manquants(p_objectif uuid)
returns table (profil_id uuid, prenom text, nom text)
language sql stable security definer set search_path = public as $$
  select p.id, p.prenom, p.nom
  from valideurs_requis(p_objectif) r
  join profils p on p.id = r.profil_id
  where not exists (
    select 1 from objectifs_validations v
    where v.objectif_id = p_objectif and v.profil_id = r.profil_id
  )
    and est_intervenant((select enfant_id from objectifs where id = p_objectif));
$$;

-- ------------------------------------------------- le passage à « validé »

-- Le statut n'est plus posé à la main : il tombe quand la dernière signature
-- arrive. Laisser l'application le faire l'obligerait à recompter le quorum
-- elle-même, et un jour elle se tromperait — ou quelqu'un appellerait l'API
-- directement.
create or replace function conclure_la_validation()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if objectif_pleinement_valide(new.objectif_id) then
    update objectifs
      set statut = 'valide',
          valide_par = new.profil_id,
          valide_le = new.valide_le
      where id = new.objectif_id
        and statut = 'propose';
  end if;
  return new;
end;
$$;

create trigger objectifs_validations_concluent
  after insert on objectifs_validations
  for each row execute function conclure_la_validation();

-- Et l'inverse : tant que le quorum n'est pas atteint, personne ne pose
-- `statut = 'valide'` directement. C'est ce trigger qui rend le quorum opposable
-- plutôt que conventionnel.
create or replace function exiger_le_quorum()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.statut = 'valide'
     and (tg_op = 'INSERT' or old.statut is distinct from 'valide')
     and not objectif_pleinement_valide(new.id) then
    raise exception 'Il manque une signature : cet objectif attend encore la validation d''un titulaire de l''autorité parentale ou du référent.';
  end if;
  return new;
end;
$$;

create trigger objectifs_exigent_le_quorum
  before insert or update on objectifs
  for each row execute function exiger_le_quorum();

-- ==================================================================== RLS

alter table objectifs_validations enable row level security;

-- Toute l'équipe voit qui a signé. Un enseignant qui attend un objectif a le
-- droit de savoir qu'il est en attente d'une signature plutôt que de le relancer
-- à vide.
create policy objectifs_validations_lecture on objectifs_validations
  for select to authenticated
  using (est_intervenant(enfant_de_l_objectif(objectif_id)));

-- On signe pour soi, et seulement si on fait partie du quorum. Un parent ne
-- signe pas au nom de l'autre — c'est tout l'objet de ce fichier.
create policy objectifs_validations_signature on objectifs_validations
  for insert to authenticated
  with check (
    profil_id = auth.uid()
    and exists (
      select 1 from valideurs_requis(objectif_id) r where r.profil_id = auth.uid()
    )
  );

-- On retire sa signature tant que l'objectif n'est pas conclu. Après, il faut
-- passer par une demande de modification (0016) : revenir sur une décision déjà
-- prise se discute, ça ne se défait pas discrètement.
create policy objectifs_validations_retrait on objectifs_validations
  for delete to authenticated
  using (
    profil_id = auth.uid()
    and exists (
      select 1 from objectifs o
      where o.id = objectif_id and o.statut = 'propose'
    )
  );
