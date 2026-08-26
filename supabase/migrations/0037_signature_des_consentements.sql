-- 0037 — Le consentement se signe, et la signature se conserve.
--
-- 0008 posait une table `consentements` avec un booléen et une chaîne
-- `version_texte`. C'était insuffisant sur les deux plans qui comptent le jour
-- où quelqu'un conteste :
--
--   - « v2 » ne prouve rien. Il faut le texte lui-même, tel qu'il était affiché,
--     et il faut qu'il soit impossible de le réécrire après coup. Un
--     consentement recueilli sur un texte modifié depuis ne vaut rien.
--   - « accorde = true » ne dit pas qui a cliqué. Il faut un geste attribuable :
--     un nom saisi, un horodatage, l'adresse d'où il vient.
--
-- Le moment du recueil est celui où le parent renseigne sa fiche, c'est-à-dire
-- quand il rejoint le dossier. C'est le seul instant où il est disponible et où
-- la question a du sens — la lui poser plus tard supposerait de le laisser
-- entrer d'abord, donc de traiter avant d'avoir demandé.

-- ------------------------------------------------------------- les textes

create table textes_consentement (
  id uuid primary key default gen_random_uuid(),
  type type_consentement not null,
  version text not null,

  titre text not null,
  contenu text not null,

  -- Certains consentements conditionnent l'usage même de l'outil ; d'autres se
  -- refusent sans en sortir. Un parent doit pouvoir dire non à la génération par
  -- l'IA sans renoncer au suivi.
  obligatoire boolean not null default false,

  publie_le timestamptz not null default now(),
  retire_le timestamptz,

  unique (type, version)
);

create index textes_en_vigueur_idx
  on textes_consentement (type, publie_le desc) where retire_le is null;

-- Un texte publié ne se réécrit pas : les consentements déjà recueillis
-- pointent dessus, et modifier le contenu réécrirait rétroactivement ce que des
-- gens ont accepté. On en publie une nouvelle version, et l'ancienne se retire.
create or replace function figer_le_texte_publie()
returns trigger language plpgsql as $$
begin
  if new.contenu is distinct from old.contenu
  or new.titre is distinct from old.titre
  or new.type is distinct from old.type
  or new.version is distinct from old.version
  or new.obligatoire is distinct from old.obligatoire then
    raise exception 'Un texte de consentement ne se modifie pas : publiez une nouvelle version et retirez celle-ci.';
  end if;
  return new;
end;
$$;

create trigger textes_consentement_figes
  before update on textes_consentement
  for each row execute function figer_le_texte_publie();

alter table textes_consentement enable row level security;

create policy textes_lecture on textes_consentement
  for select to authenticated using (true);

create policy textes_publication on textes_consentement
  for insert to authenticated with check (est_admin());

create policy textes_retrait on textes_consentement
  for update to authenticated using (est_admin());

-- ------------------------------------------------------- la signature

alter table consentements
  add column texte_id uuid references textes_consentement on delete restrict,
  -- Le nom saisi par la personne au moment du geste. C'est la signature au sens
  -- courant : un acte volontaire, attribuable, distinct d'une case cochée.
  add column signature_nom text not null default '',
  -- Une signature manuscrite tracée à l'écran, quand l'interface la propose.
  -- Facultative : elle rassure plus qu'elle ne prouve, mais elle ne coûte rien.
  add column signature_chemin text,
  add column adresse_ip inet,
  add column agent text not null default '';

-- Un consentement accordé porte une signature et le texte sur lequel elle a été
-- donnée. Un refus n'en a pas besoin : on ne signe pas un non.
alter table consentements
  add constraint consentement_accorde_est_signe
  check (
    accorde = false
    or (texte_id is not null and length(btrim(signature_nom)) >= 2)
  );

-- Une signature ne se retouche pas. Seule la révocation s'écrit après coup —
-- c'est un droit, et elle laisse la ligne d'origine intacte.
create or replace function figer_le_consentement()
returns trigger language plpgsql as $$
begin
  if new.enfant_id      is distinct from old.enfant_id
  or new.profil_id      is distinct from old.profil_id
  or new.type           is distinct from old.type
  or new.accorde        is distinct from old.accorde
  or new.texte_id       is distinct from old.texte_id
  or new.version_texte  is distinct from old.version_texte
  or new.signature_nom  is distinct from old.signature_nom
  or new.signature_chemin is distinct from old.signature_chemin
  or new.accorde_le     is distinct from old.accorde_le
  or new.adresse_ip     is distinct from old.adresse_ip then
    raise exception 'Un consentement signé ne se modifie pas. Révoquez-le, ou signez la version en vigueur.';
  end if;

  if old.revoque_le is not null and new.revoque_le is distinct from old.revoque_le then
    raise exception 'Un consentement déjà révoqué ne se réactive pas : signez de nouveau.';
  end if;

  return new;
end;
$$;

create trigger consentements_figes
  before update on consentements
  for each row execute function figer_le_consentement();

-- ---------------------------------------------------- signer, au bon moment

-- Le geste que l'interface appelle quand le parent valide sa fiche. Il signe
-- tout ce qu'il accepte d'un coup, sur les textes en vigueur au moment du clic.
create or replace function signer_les_consentements(
  p_enfant uuid,
  p_types type_consentement[],
  p_signature text,
  p_refuses type_consentement[] default '{}',
  p_ip inet default null,
  p_agent text default ''
)
returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_type type_consentement;
  v_texte textes_consentement%rowtype;
  v_compte integer := 0;
begin
  if not est_intervenant(p_enfant, array['parent', 'referent']::role_intervenant[]) then
    raise exception 'Seuls les titulaires de l''autorité parentale et le référent signent les consentements.';
  end if;

  if length(btrim(p_signature)) < 2 then
    raise exception 'La signature ne peut pas être vide.';
  end if;

  foreach v_type in array p_types loop
    select * into v_texte from textes_consentement
    where type = v_type and retire_le is null
    order by publie_le desc limit 1;

    if not found then
      raise exception 'Aucun texte en vigueur pour ce consentement : %', v_type;
    end if;

    insert into consentements
      (enfant_id, profil_id, type, accorde, version_texte, texte_id,
       signature_nom, adresse_ip, agent)
    values
      (p_enfant, auth.uid(), v_type, true, v_texte.version, v_texte.id,
       btrim(p_signature), p_ip, p_agent);

    v_compte := v_compte + 1;
  end loop;

  -- Les refus sont enregistrés aussi. Ne garder que les acceptations rendrait
  -- indiscernable « il a refusé » de « on ne lui a jamais demandé ».
  foreach v_type in array p_refuses loop
    select * into v_texte from textes_consentement
    where type = v_type and retire_le is null
    order by publie_le desc limit 1;

    if found and v_texte.obligatoire then
      raise exception 'Ce consentement conditionne l''usage de l''outil et ne peut pas être refusé : %', v_type;
    end if;

    insert into consentements
      (enfant_id, profil_id, type, accorde, version_texte, texte_id, adresse_ip, agent)
    values
      (p_enfant, auth.uid(), v_type, false, coalesce(v_texte.version, ''), v_texte.id, p_ip, p_agent);
  end loop;

  return v_compte;
end;
$$;

-- ------------------------------------------- ce qu'il reste à signer

-- La liste que l'interface présente au parent qui renseigne sa fiche : tous les
-- textes en vigueur qu'il n'a pas encore signés dans leur version courante. Un
-- texte republié y réapparaît, ce qui est le comportement voulu — un
-- consentement porte sur un texte, pas sur un sujet.
create or replace function consentements_a_signer(p_enfant uuid)
returns table (
  texte_id uuid,
  type type_consentement,
  version text,
  titre text,
  contenu text,
  obligatoire boolean
)
language sql stable security definer set search_path = public as $$
  select t.id, t.type, t.version, t.titre, t.contenu, t.obligatoire
  from textes_consentement t
  where t.retire_le is null
    and est_intervenant(p_enfant, array['parent', 'referent']::role_intervenant[])
    and not exists (
      select 1 from consentements c
      where c.enfant_id = p_enfant
        and c.profil_id = auth.uid()
        and c.texte_id = t.id
        and c.revoque_le is null
    )
  order by t.obligatoire desc, t.type;
$$;

-- ------------------------------------- le consentement, aligné sur le quorum

-- `consentement_actif()` (0008) renvoyait vrai dès qu'une personne avait
-- consenti. En garde alternée, cela revenait à traiter les données de santé d'un
-- enfant sur l'accord d'un seul de ses parents.
--
-- La règle suit désormais celle de la validation : tous les titulaires déclarés,
-- et il faut qu'ils soient tous rattachés. Un consentement incomplet vaut absence
-- de consentement — c'est l'hypothèse stricte, et la question 2.2 du document
-- juriste dira si elle peut se relâcher.
create or replace function consentement_actif(p_enfant uuid, p_type type_consentement)
returns boolean
language sql stable security definer set search_path = public as $$
  select composition_parentale_complete(p_enfant)
     and not exists (
       select 1
       from intervenants_enfant i
       where i.enfant_id = p_enfant
         and i.role = 'parent'
         and i.retire_le is null
         and not exists (
           select 1 from consentements c
           where c.enfant_id = p_enfant
             and c.profil_id = i.profil_id
             and c.type = p_type
             and c.accorde
             and c.revoque_le is null
         )
     );
$$;

-- ==================================================== stockage des signatures

-- Convention : {consentement_id}/{fichier}. Une signature manuscrite est une
-- donnée biométrique au sens large et n'a pas à circuler : seul son auteur la
-- relit, et aucun autre chemin n'y mène.
create or replace function consentement_du_chemin(p_name text)
returns uuid language sql immutable as $$
  select uuid_ou_null((storage.foldername(p_name))[1]);
$$;

insert into storage.buckets (id, name, public) values
  ('signatures', 'signatures', false)
on conflict (id) do nothing;

create policy "signatures_lecture" on storage.objects
  for select to authenticated using (
    bucket_id = 'signatures'
    and exists (
      select 1 from public.consentements c
      where c.id = public.consentement_du_chemin(name)
        and c.profil_id = auth.uid()
    )
  );

create policy "signatures_depot" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'signatures'
    and exists (
      select 1 from public.consentements c
      where c.id = public.consentement_du_chemin(name)
        and c.profil_id = auth.uid()
    )
  );

-- Aucune suppression : effacer une signature reviendrait à effacer la preuve du
-- consentement qu'elle porte, en laissant la ligne qui l'invoque.
