-- 0029 — Le bucket des pièces justificatives d'accès.
--
-- Convention de chemin : {acces_id}/{fichier}. Le premier segment porte
-- l'identifiant de l'accès d'exception, et non celui de l'enfant — contrairement
-- à tous les autres buckets du projet.
--
-- Ce n'est pas une inconséquence. Ailleurs, le chemin dit « ce fichier concerne
-- cet enfant », et la politique rejoue `est_intervenant()` : c'est ce qui ouvre
-- le document à la famille et à l'équipe. Ici, c'est exactement ce qu'il ne faut
-- pas. Une réquisition ne se montre pas à la famille visée par l'enquête, et un
-- chemin construit sur `enfant_id` aurait rendu ce partage tentant à écrire.

create or replace function acces_du_chemin(p_name text)
returns uuid
language sql
immutable
as $$
  select uuid_ou_null((storage.foldername(p_name))[1]);
$$;

insert into storage.buckets (id, name, public) values
  ('requisitions', 'requisitions', false)
on conflict (id) do nothing;

-- Lisible par l'administration, et par elle seule — y compris les pièces
-- déposées par un autre administrateur. Une justification que son auteur serait
-- le seul à pouvoir relire ne justifierait rien devant quiconque.
--
-- La famille n'y a pas accès, même après la levée du secret. Elle apprend qu'un
-- accès a eu lieu et sur quel motif ; le dossier d'enquête lui-même ne lui
-- appartient pas, et il peut porter sur des tiers.
create policy "requisitions_lecture" on storage.objects
  for select to authenticated using (
    bucket_id = 'requisitions' and public.est_admin()
  );

-- On ne verse une pièce que dans un accès qu'on a soi-même ouvert et qui court
-- encore. Déposer dans l'accès d'un autre, ou dans un accès déjà refermé,
-- reviendrait à reconstituer après coup une justification.
create policy "requisitions_depot" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'requisitions'
    and public.est_admin()
    and exists (
      select 1 from public.acces_exceptionnels a
      where a.id = public.acces_du_chemin(name)
        and a.ouvert_par = auth.uid()
        and a.clos_le is null
    )
  );

-- Aucune politique de suppression, volontairement. Une pièce justificative qui
-- s'efface laisse un accès sans fondement dans le journal, et personne pour dire
-- ce qui l'avait autorisé. Le jour où une suppression est réellement nécessaire
-- — une durée de conservation échue, une pièce versée par erreur dans le mauvais
-- dossier — elle se fait par la clé de service, en connaissance de cause.
