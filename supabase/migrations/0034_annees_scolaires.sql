-- 0034 — Le dossier se classe par année.
--
-- `enfants.classe` est une valeur unique, et `objectifs.annee_scolaire` une
-- chaîne libre posée par défaut. Au bout de deux ans, plus rien ne dit ce qui
-- appartient à quelle année : les objectifs de 4e se mêlent à ceux de 3e, les
-- bilans trimestriels s'empilent sans repère, et le changement d'établissement
-- ne laisse aucune trace.
--
-- Une année scolaire devient donc un objet : une classe, un établissement, une
-- date d'ouverture, une date de clôture, et le lien vers celle qui la précède.
--
-- Le point qui compte : **on ne recommence pas à zéro chaque rentrée**. Le bilan
-- de fin d'année est repris comme point de départ de l'année suivante. Refaire
-- un bilan de positionnement complet en septembre serait coûteux, redondant, et
-- pénible pour l'enfant — à qui on redemanderait de prouver ce qu'il venait
-- d'acquérir.

create table annees_enfant (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,

  annee_scolaire text not null,
  classe niveau_classe not null,
  etablissement text not null default '',

  debute_le date not null default current_date,
  close_le date,

  -- D'où l'on part. La première année, c'est le bilan de positionnement ; les
  -- suivantes, le bilan de fin de l'année précédente. Jamais les deux.
  bilan_positionnement_id uuid references bilans_positionnement on delete set null,
  bilan_anterieur_id uuid references bilans_trimestriels on delete set null,

  annee_precedente_id uuid references annees_enfant on delete set null,

  unique (enfant_id, annee_scolaire),

  constraint annee_part_d_un_seul_bilan
    check (num_nonnulls(bilan_positionnement_id, bilan_anterieur_id) <= 1),
  constraint annee_close_apres_son_debut
    check (close_le is null or close_le >= debute_le)
);

create index annees_enfant_idx on annees_enfant (enfant_id, debute_le desc);

-- Une seule année ouverte à la fois : deux années courantes produiraient deux
-- classes de référence, et plus personne ne saurait laquelle fait foi.
create unique index annees_une_seule_ouverte
  on annees_enfant (enfant_id) where close_le is null;

-- Ce qui se range par année. `annee_scolaire` en texte reste pour compatibilité,
-- mais c'est `annee_id` qui fait foi désormais.
alter table objectifs
  add column annee_id uuid references annees_enfant on delete set null;

alter table bilans_trimestriels
  add column annee_id uuid references annees_enfant on delete set null;

create index objectifs_annee_idx on objectifs (annee_id);
create index bilans_trimestriels_annee_idx on bilans_trimestriels (annee_id);

-- ------------------------------------------------------- le passage de classe

-- Un geste unique, plutôt qu'une suite de mises à jour que l'application
-- pourrait faire à moitié. Clore l'année sans en ouvrir une autre laisserait
-- l'enfant sans classe de référence, et donc sans repères de cycle pour ses
-- prochains exercices.
create or replace function passer_en_classe_superieure(
  p_enfant uuid,
  p_classe niveau_classe,
  p_annee_scolaire text,
  p_etablissement text default null
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_ancienne annees_enfant%rowtype;
  v_bilan uuid;
  v_nouvelle uuid;
begin
  if not peut_valider(p_enfant) then
    raise exception 'Le passage de classe est acté par la famille ou le référent.';
  end if;

  select * into v_ancienne
  from annees_enfant
  where enfant_id = p_enfant and close_le is null;

  if found then
    -- Le dernier bilan trimestriel validé de l'année qui se termine devient le
    -- point de départ de la suivante.
    select b.id into v_bilan
    from bilans_trimestriels b
    where b.enfant_id = p_enfant
      and b.annee_id = v_ancienne.id
      and b.statut = 'valide'
    order by b.trimestre desc
    limit 1;

    update annees_enfant set close_le = current_date where id = v_ancienne.id;
  end if;

  insert into annees_enfant (
    enfant_id, annee_scolaire, classe, etablissement,
    bilan_anterieur_id, annee_precedente_id
  )
  values (
    p_enfant, p_annee_scolaire, p_classe,
    coalesce(p_etablissement, v_ancienne.etablissement, ''),
    v_bilan, v_ancienne.id
  )
  returning id into v_nouvelle;

  update enfants set classe = p_classe where id = p_enfant;

  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  values (p_enfant, auth.uid(), 'passage_de_classe', 'annees_enfant', v_nouvelle,
          jsonb_build_object('classe', p_classe, 'annee', p_annee_scolaire));

  return v_nouvelle;
end;
$$;

-- Ce qu'on n'a pas fini. La liste que l'équipe relit à la rentrée pour décider
-- ce qu'elle reprend — et rien n'est repris automatiquement : un objectif non
-- atteint en juin ne l'est pas forcément encore pertinent en septembre, et c'est
-- une décision de réunion, pas de trigger.
create or replace function objectifs_non_atteints(p_annee uuid)
returns table (
  objectif_id uuid,
  libelle text,
  matiere_code text,
  domaine_code text,
  granularite granularite_objectif,
  statut statut_objectif
)
language sql stable security definer set search_path = public as $$
  select o.id, o.libelle, o.matiere_code, o.domaine_code, o.granularite, o.statut
  from objectifs o
  join annees_enfant a on a.id = o.annee_id
  where o.annee_id = p_annee
    and o.statut in ('propose', 'valide')
    and est_intervenant(a.enfant_id)
  order by o.granularite, o.libelle;
$$;

-- ==================================================================== RLS

alter table annees_enfant enable row level security;

create policy annees_lecture on annees_enfant for select to authenticated
  using (est_intervenant(enfant_id) or est_l_enfant(enfant_id));

-- Les années se créent par `passer_en_classe_superieure()`, qui vérifie les
-- droits et journalise. La politique couvre la toute première, celle qu'on ouvre
-- à l'inscription et qui n'a pas de précédente.
create policy annees_ouverture on annees_enfant for insert to authenticated
  with check (peut_valider(enfant_id));

create policy annees_maj on annees_enfant for update to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));
