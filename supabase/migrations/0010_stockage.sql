-- 0010 — Buckets de stockage.
--
-- Convention de chemin, identique pour les trois buckets : {enfant_id}/{fichier}.
-- Le premier segment porte donc le droit d'accès, et les politiques ci-dessous
-- le rejouent contre est_intervenant(). Un fichier rangé ailleurs n'est lisible
-- par personne — c'est voulu : mieux vaut un upload qui échoue qu'un document
-- scolaire accessible à la mauvaise famille.

-- Un chemin mal formé ne doit pas faire tomber la politique en erreur, il doit
-- simplement ne correspondre à aucun enfant.
create or replace function uuid_ou_null(p_texte text)
returns uuid
language plpgsql
immutable
as $$
begin
  return p_texte::uuid;
exception when others then
  return null;
end;
$$;

create or replace function enfant_du_chemin(p_name text)
returns uuid
language sql
immutable
as $$
  select uuid_ou_null((storage.foldername(p_name))[1]);
$$;

-- Aucun bucket public : un support de cours annoté au nom d'un enfant et une
-- photo de récompense se servent tous deux par URL signée.
insert into storage.buckets (id, name, public) values
  ('supports', 'supports', false),
  ('bilans', 'bilans', false),
  ('recompenses', 'recompenses', false)
on conflict (id) do nothing;

-- ------------------------------------------------------------------ supports
-- Ce que déposent les enseignants : cours, sujets de devoir, évaluations.

create policy "supports_lecture" on storage.objects
  for select to authenticated using (
    bucket_id = 'supports'
    and public.est_intervenant(public.enfant_du_chemin(name))
  );

create policy "supports_depot" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'supports'
    and public.est_intervenant(public.enfant_du_chemin(name))
  );

create policy "supports_suppression" on storage.objects
  for delete to authenticated using (
    bucket_id = 'supports'
    and (
      owner = auth.uid()
      or public.peut_valider(public.enfant_du_chemin(name))
    )
  );

-- -------------------------------------------------------------------- bilans
-- Les PDF trimestriels. Lisibles par toute l'équipe — c'est leur raison d'être
-- (§3.2) — mais écrits par le seul cercle qui valide.

create policy "bilans_lecture" on storage.objects
  for select to authenticated using (
    bucket_id = 'bilans'
    and public.est_intervenant(public.enfant_du_chemin(name))
  );

create policy "bilans_ecriture" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'bilans'
    and public.peut_valider(public.enfant_du_chemin(name))
  );

create policy "bilans_suppression" on storage.objects
  for delete to authenticated using (
    bucket_id = 'bilans'
    and public.peut_valider(public.enfant_du_chemin(name))
  );

-- --------------------------------------------------------------- recompenses
-- Les images que l'enfant débloque. Rangées sous son identifiant comme le reste :
-- une récompense parle de son univers à lui, elle ne se mutualise pas.

create policy "recompenses_lecture" on storage.objects
  for select to authenticated using (
    bucket_id = 'recompenses'
    and public.est_intervenant(public.enfant_du_chemin(name))
  );

create policy "recompenses_ecriture" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'recompenses'
    and public.peut_valider(public.enfant_du_chemin(name))
  );

create policy "recompenses_suppression" on storage.objects
  for delete to authenticated using (
    bucket_id = 'recompenses'
    and public.peut_valider(public.enfant_du_chemin(name))
  );
