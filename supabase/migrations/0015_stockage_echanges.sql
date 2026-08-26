-- 0015 — Le bucket des documents partagés en messagerie.
--
-- Convention de chemin : {enfant_id}/{fil_id}/{fichier}. Deux segments portants
-- au lieu d'un seul, parce que le droit d'accès ne se décide pas au niveau de
-- l'enfant ici : un compte rendu déposé dans un fil de binôme ne doit pas
-- devenir lisible par toute l'équipe au motif qu'elle accompagne le même enfant.
-- C'est le fil qui décide, donc c'est le fil qui figure dans le chemin.

create or replace function fil_du_chemin(p_name text)
returns uuid
language sql
immutable
as $$
  select uuid_ou_null((storage.foldername(p_name))[2]);
$$;

insert into storage.buckets (id, name, public) values
  ('echanges', 'echanges', false)
on conflict (id) do nothing;

-- `acces_au_fil(null)` renvoie faux : un chemin mal formé ne correspond à aucun
-- fil, donc à aucun droit. Un dépôt hors convention échoue au lieu de créer un
-- document que personne ne peut plus lire ni supprimer.
create policy "echanges_lecture" on storage.objects
  for select to authenticated using (
    bucket_id = 'echanges'
    and public.acces_au_fil(public.fil_du_chemin(name))
  );

create policy "echanges_depot" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'echanges'
    and public.acces_au_fil(public.fil_du_chemin(name))
  );

-- On retire le document qu'on a soi-même déposé. Les parents et le référent
-- peuvent retirer n'importe lequel : c'est leur enfant, et c'est à eux que
-- revient la décision de ne plus laisser circuler une pièce.
create policy "echanges_suppression" on storage.objects
  for delete to authenticated using (
    bucket_id = 'echanges'
    and (
      owner = auth.uid()
      or public.peut_valider(public.enfant_du_chemin(name))
    )
  );
