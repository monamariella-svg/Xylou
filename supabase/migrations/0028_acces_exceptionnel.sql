-- 0028 — L'accès d'exception, en cas de litige.
--
-- 0026 et 0027 ont fermé le dossier à l'administration : elle corrige des
-- rattachements, elle ne lit pas ce qui s'y passe. La règle est bonne au
-- quotidien et intenable le jour où quelque chose se conteste — deux parents en
-- désaccord sur une validation, une famille qui affirme n'avoir jamais reçu un
-- message, un professeur mis en cause. Refuser tout accès dans ces cas-là ne
-- protège personne : cela laisse le litige sans arbitre, et finit par se régler
-- par une extraction en base, hors de tout cadre.
--
-- L'accès existe donc, mais il se paie :
--
--   - il s'ouvre explicitement, avec un motif écrit ;
--   - il est borné dans le temps, et se referme tout seul ;
--   - la famille et le référent en sont prévenus à l'instant où il s'ouvre ;
--   - il ne donne jamais que la lecture.
--
-- ---------------------------------------------------------------------------
-- CE QUE LA TRACE COUVRE, ET CE QU'ELLE NE COUVRE PAS
--
-- Postgres ne déclenche pas de trigger sur un SELECT : il est impossible de
-- consigner chaque ligne effectivement lue. Ce qui est tracé, c'est l'ouverture
-- — qui, quand, pourquoi, jusqu'à quand — et rien de plus fin.
--
-- Autant le dire ici plutôt que de laisser croire à une traçabilité qu'on n'a
-- pas : la garantie ne repose pas sur l'exhaustivité du journal, elle repose sur
-- le fait que la famille est prévenue et peut demander des comptes.
-- ---------------------------------------------------------------------------

-- Deux natures d'accès, parce qu'une seule règle d'information ne peut pas
-- couvrir les deux.
--
--   litige      — un désaccord interne à l'accompagnement. La famille est
--                 prévenue à l'instant où le dossier s'ouvre. C'est même tout
--                 l'intérêt : elle est partie au litige.
--
--   requisition — une réquisition judiciaire. Elle s'impose, et le secret de
--                 l'enquête peut interdire d'en informer la famille. Souvent
--                 temporairement, rarement pour toujours.
--
-- Ce fichier ne décide pas du droit applicable : il permet les deux
-- comportements et oblige à dire lequel on applique et sur quel fondement.
-- L'article invoqué se lit ensuite dans `base_legale`, ce qui est la seule chose
-- utile le jour où quelqu'un demande pourquoi la famille n'a rien su.
--   demande_famille  — la famille demande elle-même l'ouverture, pour obtenir
--                      une extraction ou faire constater quelque chose. Elle est
--                      à l'origine, mais son accord doit être écrit : une
--                      demande orale rapportée par un tiers n'engage personne.
--
--   demande_equipe   — l'établissement ou un intervenant demande l'accès. Là,
--                      l'autorisation de la famille est indispensable, et elle
--                      doit émaner de chaque titulaire de l'autorité parentale.
create type nature_acces as enum (
  'litige',
  'requisition',
  'demande_famille',
  'demande_equipe'
);

create table acces_exceptionnels (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,
  ouvert_par uuid not null references profils on delete restrict,

  nature nature_acces not null default 'litige',

  -- Écrit, et pas choisi dans une liste : un motif à cocher se coche sans
  -- réfléchir, et ne vaut rien devant qui conteste.
  motif text not null check (length(btrim(motif)) >= 20),
  reference_litige text not null default '',

  -- L'autorité requérante et le fondement invoqué. Sans eux, une réquisition ne
  -- se distingue pas d'un accès qu'on a simplement choisi de taire.
  autorite_requerante text not null default '',
  base_legale text not null default '',

  -- Nul pour un litige, où l'information est immédiate. Pour une réquisition :
  -- la date à laquelle la famille a effectivement été informée, renseignée quand
  -- le secret est levé. Tant qu'elle est nulle, l'information reste due.
  information_faite_le timestamptz,

  ouvert_le timestamptz not null default now(),
  expire_le timestamptz not null default now() + interval '72 hours',
  clos_le timestamptz,

  constraint acces_borne_dans_le_temps check (expire_le > ouvert_le),

  -- Taire l'ouverture à la famille suppose de dire qui l'exige et à quel titre.
  constraint requisition_documente_son_fondement
    check (
      nature <> 'requisition'
      or (
        length(btrim(autorite_requerante)) > 0
        and length(btrim(base_legale)) > 0
        and length(btrim(reference_litige)) > 0
      )
    )
);

-- Les réquisitions dont l'information reste due : la liste qu'on relit quand une
-- enquête se clôt. Sans elle, « on préviendra plus tard » devient « on n'a
-- jamais prévenu », faute de savoir qui restait à prévenir.
create index acces_information_due_idx
  on acces_exceptionnels (ouvert_le)
  where nature = 'requisition' and information_faite_le is null;

create index acces_exceptionnels_enfant_idx
  on acces_exceptionnels (enfant_id, ouvert_le desc);

-- Un seul accès ouvert à la fois par administrateur et par enfant : sans cela,
-- en rouvrir un chaque fois qu'il expire reviendrait à un accès permanent
-- déguisé en série d'exceptions.
create unique index acces_exceptionnels_un_seul_actif
  on acces_exceptionnels (enfant_id, ouvert_par)
  where clos_le is null;

-- ------------------------------------------------- les pièces justificatives

-- Une table et non des colonnes : un accès demandé par l'équipe pédagogique
-- suppose l'accord de chaque titulaire de l'autorité parentale, donc jusqu'à
-- deux courriers distincts, chacun émanant d'une personne identifiée. Une
-- colonne `document_chemin` aurait obligé à choisir lequel des deux conserver.
create type type_piece_acces as enum (
  'requisition',
  'courrier_autorite_parentale',
  'autre'
);

create table acces_pieces (
  id uuid primary key default gen_random_uuid(),
  acces_id uuid not null references acces_exceptionnels on delete cascade,
  type_piece type_piece_acces not null,

  -- De quel titulaire émane le courrier. C'est ce qui permet de compter les
  -- accords : deux courriers du même parent ne font pas deux autorisations.
  emane_de uuid references profils on delete restrict,

  nom text not null,
  chemin text not null unique,

  depose_par uuid not null references profils on delete restrict,
  depose_le timestamptz not null default now(),

  -- Une pièce versée par erreur — mauvais dossier, mauvais parent, scan
  -- illisible — s'écarte, elle ne s'efface pas. Le cumul est la seule forme de
  -- correction qui laisse voir qu'il y a eu correction.
  ecartee_le timestamptz,
  ecartee_par uuid references profils on delete set null,
  motif_ecartement text not null default '',

  constraint courrier_designe_son_auteur
    check ((type_piece = 'courrier_autorite_parentale') = (emane_de is not null)),

  -- Écarter est un geste signé et motivé, sinon c'est une suppression déguisée.
  constraint ecartement_signe_et_motive
    check (
      (ecartee_le is null and ecartee_par is null and btrim(motif_ecartement) = '')
      or (ecartee_le is not null and ecartee_par is not null
          and length(btrim(motif_ecartement)) >= 10)
    )
);

create index acces_pieces_acces_idx on acces_pieces (acces_id);

-- Ce que chaque nature exige avant de donner accès à quoi que ce soit.
--
--   litige           — rien. C'est l'administration qui agit de son propre chef,
--                      sous le motif écrit et sous le regard de la famille,
--                      prévenue à l'ouverture.
--   requisition      — la pièce qui l'ordonne.
--   demande_famille  — l'accord écrit de chaque titulaire. Y compris quand c'est
--   demande_equipe     la famille qui demande : en garde alternée, la demande
--                      d'un parent n'emporte pas celle de l'autre, et le dossier
--                      est aussi celui du second.
create or replace function pieces_suffisantes(p_acces uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select case a.nature
    when 'litige' then true
    when 'requisition' then exists (
      select 1 from acces_pieces p
      where p.acces_id = a.id
        and p.type_piece = 'requisition'
        and p.ecartee_le is null
    )
    else (
      select count(distinct p.emane_de)
      from acces_pieces p
      join intervenants_enfant i
        on i.profil_id = p.emane_de
       and i.enfant_id = a.enfant_id
       and i.role = 'parent'
       and i.retire_le is null
      where p.acces_id = a.id
        and p.type_piece = 'courrier_autorite_parentale'
        and p.ecartee_le is null
    ) >= e.titulaires_autorite_parentale
  end
  from acces_exceptionnels a
  join enfants e on e.id = a.enfant_id
  where a.id = p_acces;
$$;

-- Les pièces conditionnent l'activation, pas l'insertion. C'est une nécessité
-- pratique — le chemin du fichier contient l'identifiant de l'accès, qui n'existe
-- pas avant que la ligne soit écrite — et c'est aussi le bon endroit : ce qu'on
-- veut empêcher n'est pas d'ouvrir un dossier, c'est de lire quoi que ce soit
-- avant d'avoir versé ce qui l'autorise.
create or replace function acces_exceptionnel_actif(p_enfant uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from acces_exceptionnels a
    where a.enfant_id = p_enfant
      and a.ouvert_par = auth.uid()
      and a.clos_le is null
      and a.expire_le > now()
      and pieces_suffisantes(a.id)
  );
$$;

alter table acces_pieces enable row level security;

-- Le versement est réservé à l'administrateur qui a ouvert l'accès, et tant
-- qu'il court. Déposer dans l'accès d'un autre, ou dans un accès refermé,
-- reviendrait à reconstituer une justification après coup.
create policy acces_pieces_depot on acces_pieces for insert to authenticated
  with check (
    depose_par = auth.uid()
    and exists (
      select 1 from acces_exceptionnels a
      where a.id = acces_id and a.ouvert_par = auth.uid() and a.clos_le is null
    )
  );

create policy acces_pieces_lecture on acces_pieces for select to authenticated
  using (est_admin());

-- Le seul changement autorisé sur une pièce est son écartement. Rien d'autre :
-- une pièce dont on pourrait réécrire l'auteur ou le chemin ne justifierait
-- rien, puisqu'il suffirait de lire d'abord et d'ajuster ensuite.
--
-- Écarter est sans danger, et c'est ce qui permet de l'ouvrir largement : le
-- décompte ignore les pièces écartées, donc l'opération ne peut que retirer de
-- la justification, jamais en ajouter. Un administrateur qui écarterait tout
-- fermerait son propre accès.
create policy acces_pieces_ecartement on acces_pieces for update to authenticated
  using (est_admin())
  with check (est_admin() and ecartee_par = auth.uid());

create or replace function restreindre_l_ecartement_de_piece()
returns trigger language plpgsql as $$
begin
  if new.acces_id   is distinct from old.acces_id
  or new.type_piece is distinct from old.type_piece
  or new.emane_de   is distinct from old.emane_de
  or new.chemin     is distinct from old.chemin
  or new.nom        is distinct from old.nom
  or new.depose_par is distinct from old.depose_par
  or new.depose_le  is distinct from old.depose_le then
    raise exception 'Une pièce ne se corrige pas : écartez-la en motivant, puis versez-en une autre. Les deux resteront visibles.';
  end if;

  if old.ecartee_le is not null then
    raise exception 'Cette pièce a déjà été écartée.';
  end if;

  return new;
end;
$$;

create trigger acces_pieces_restreignent_l_ecartement
  before update on acces_pieces
  for each row execute function restreindre_l_ecartement_de_piece();

-- Toujours aucune politique de suppression : la pièce écartée reste, et c'est
-- elle qui rend l'erreur lisible. Un dossier où ne figurerait que la bonne pièce
-- ne dirait pas qu'il y en a eu une mauvaise — or c'est précisément ce qu'un
-- contrôle a besoin de voir.

-- --------------------------------------------------- prévenir, et consigner

-- Prévenir la famille et le référent — jamais les enseignants : ni un litige ni
-- une enquête ne se diffusent à l'équipe pédagogique.
create or replace function informer_de_l_acces(p_acces uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_acces acces_exceptionnels%rowtype;
begin
  select * into v_acces from acces_exceptionnels where id = p_acces;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select
    i.profil_id, v_acces.enfant_id, 'acces_exceptionnel',
    'Accès administratif au dossier',
    'Motif : ' || v_acces.motif,
    '/enfants/' || v_acces.enfant_id || '/acces/' || v_acces.id
  from intervenants_enfant i
  where i.enfant_id = v_acces.enfant_id
    and i.retire_le is null
    and i.role in ('parent', 'referent');
end;
$$;

create or replace function annoncer_l_acces_exceptionnel()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  -- Le journal reçoit toujours l'ouverture, y compris pour une réquisition.
  -- Ce qui peut être différé, c'est l'information de la famille — pas la trace.
  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  values (
    new.enfant_id, new.ouvert_par, 'acces_exceptionnel_ouvert',
    'acces_exceptionnels', new.id,
    jsonb_build_object(
      'nature', new.nature,
      'motif', new.motif,
      'expire_le', new.expire_le,
      'reference', new.reference_litige,
      'autorite', new.autorite_requerante,
      'base_legale', new.base_legale
    )
  );

  -- Prévenir à l'ouverture, et non après coup, est ce qui distingue un accès
  -- d'exception d'une porte dérobée. La réquisition y échappe parce que le
  -- secret de l'enquête peut l'exiger — et l'information reste due, elle est
  -- seulement remise à plus tard.
  -- Seule la réquisition échappe à l'information immédiate. Une demande de la
  -- famille ou de l'équipe s'appuie précisément sur un accord parental écrit :
  -- la taire n'aurait aucun sens, et le second titulaire, en garde alternée,
  -- doit voir que son accord a été utilisé.
  if new.nature <> 'requisition' then
    perform informer_de_l_acces(new.id);
    update acces_exceptionnels set information_faite_le = now() where id = new.id;
  end if;

  return new;
end;
$$;

create trigger acces_exceptionnels_annoncent
  after insert on acces_exceptionnels
  for each row execute function annoncer_l_acces_exceptionnel();

-- Lever le secret : la famille est informée, et la date est consignée. C'est le
-- geste qu'on oublie, d'où l'index partiel plus haut qui liste ce qui reste dû.
create or replace function lever_le_secret(p_acces uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not est_admin() then
    raise exception 'Réservé à l''administration.';
  end if;

  if not exists (
    select 1 from acces_exceptionnels
    where id = p_acces and information_faite_le is null
  ) then
    raise exception 'Cet accès a déjà été porté à la connaissance de la famille.';
  end if;

  perform informer_de_l_acces(p_acces);

  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  select a.enfant_id, auth.uid(), 'acces_exceptionnel_revele',
         'acces_exceptionnels', a.id,
         jsonb_build_object('ouvert_le', a.ouvert_le)
  from acces_exceptionnels a where a.id = p_acces;

  update acces_exceptionnels set information_faite_le = now() where id = p_acces;
end;
$$;

-- ==================================================================== RLS

alter table acces_exceptionnels enable row level security;

-- La famille et le référent lisent l'historique des accès à leur dossier. C'est
-- la contrepartie : un droit de regard sur qui a regardé.
--
-- `information_faite_le is not null` est la condition qui rend le secret réel.
-- Sans elle, une réquisition apparaîtrait dans cette liste à la seconde où elle
-- s'ouvre, et toute la mécanique de différé ne servirait à rien.
create policy acces_exceptionnels_lecture on acces_exceptionnels
  for select to authenticated
  using (
    (peut_valider(enfant_id) and information_faite_le is not null)
    or (est_admin() and ouvert_par = auth.uid())
  );

create policy acces_exceptionnels_ouverture on acces_exceptionnels
  for insert to authenticated
  with check (est_admin() and ouvert_par = auth.uid());

-- On referme le sien, on ne prolonge pas : `expire_le` n'est pas modifiable,
-- faute de quoi la borne temporelle ne vaudrait rien.
create policy acces_exceptionnels_cloture on acces_exceptionnels
  for update to authenticated
  using (est_admin() and ouvert_par = auth.uid());

create or replace function figer_la_borne_de_l_acces()
returns trigger language plpgsql as $$
begin
  if new.expire_le is distinct from old.expire_le
  or new.motif is distinct from old.motif
  or new.enfant_id is distinct from old.enfant_id
  or new.ouvert_par is distinct from old.ouvert_par then
    raise exception 'Un accès d''exception ne se prolonge ni ne se réécrit : refermez-le et rouvrez-en un, motif à l''appui.';
  end if;
  return new;
end;
$$;

create trigger acces_exceptionnels_figent_leur_borne
  before update on acces_exceptionnels
  for each row execute function figer_la_borne_de_l_acces();

-- ============================================ ce que l'accès ouvre en lecture

-- Uniquement du SELECT, sur ce qui peut faire l'objet d'un litige : ce qui a été
-- décidé, ce qui a été dit, ce qui a été fait et ce que l'enfant a produit.
--
-- `enfants_sante` en est délibérément absente. Un diagnostic n'éclaire aucun des
-- litiges que cet accès sert à trancher, et le §3.4 en fait la donnée la plus
-- protégée du schéma. Si un jour un litige porte réellement sur elle, il faudra
-- l'ouvrir explicitement — et ce sera une décision à prendre à ce moment-là,
-- pas un droit acquis d'avance.

create policy objectifs_lecture_litige on objectifs
  for select to authenticated using (acces_exceptionnel_actif(enfant_id));

create policy objectifs_validations_lecture_litige on objectifs_validations
  for select to authenticated
  using (acces_exceptionnel_actif(enfant_de_l_objectif(objectif_id)));

create policy objectifs_demandes_lecture_litige on objectifs_demandes
  for select to authenticated
  using (acces_exceptionnel_actif(enfant_de_l_objectif(objectif_id)));

create policy missions_lecture_litige on missions
  for select to authenticated using (acces_exceptionnel_actif(enfant_id));

create policy exercices_lecture_litige on exercices
  for select to authenticated
  using (acces_exceptionnel_actif(enfant_de_la_mission(mission_id)));

create policy tentatives_lecture_litige on tentatives
  for select to authenticated using (acces_exceptionnel_actif(enfant_id));

create policy corrections_lecture_litige on corrections
  for select to authenticated
  using (acces_exceptionnel_actif(enfant_de_la_tentative(tentative_id)));

create policy notations_lecture_litige on notations
  for select to authenticated
  using (acces_exceptionnel_actif(enfant_de_la_mission(mission_id)));

create policy fils_lecture_litige on fils
  for select to authenticated using (acces_exceptionnel_actif(enfant_id));

create policy messages_lecture_litige on messages
  for select to authenticated
  using (exists (
    select 1 from fils f
    where f.id = fil_id and acces_exceptionnel_actif(f.enfant_id)
  ));

create policy pieces_jointes_lecture_litige on pieces_jointes
  for select to authenticated
  using (exists (
    select 1 from messages m
    join fils f on f.id = m.fil_id
    where m.id = message_id and acces_exceptionnel_actif(f.enfant_id)
  ));

create policy alertes_lecture_litige on alertes_difficulte
  for select to authenticated using (acces_exceptionnel_actif(enfant_id));

create policy alertes_actions_lecture_litige on alertes_actions
  for select to authenticated
  using (exists (
    select 1 from alertes_difficulte a
    where a.id = alerte_id and acces_exceptionnel_actif(a.enfant_id)
  ));

create policy journal_acces_lecture_litige on journal_acces
  for select to authenticated using (acces_exceptionnel_actif(enfant_id));

-- Et la fuite symétrique : `journal_acces_lecture` (0009) ouvre le journal à la
-- famille, or le trigger ci-dessus y consigne l'ouverture de toute réquisition,
-- base légale comprise. Le secret aurait tenu dans `acces_exceptionnels` et
-- serait tombé dans le journal, à la ligne suivante.
drop policy journal_acces_lecture on journal_acces;

create policy journal_acces_lecture on journal_acces for select to authenticated
  using (
    peut_valider(enfant_id)
    and not (
      action in ('acces_exceptionnel_ouvert', 'acces_exceptionnel_revele')
      and exists (
        select 1 from acces_exceptionnels a
        where a.id = ligne_id and a.information_faite_le is null
      )
    )
  );

-- L'administration relit ses propres accès d'exception, comme elle relit ses
-- corrections (0027).
drop policy journal_acces_lecture_admin on journal_acces;

create policy journal_acces_lecture_admin on journal_acces for select to authenticated
  using (
    est_admin()
    and action in (
      'correction_administrative',
      'acces_exceptionnel_ouvert',
      'acces_exceptionnel_revele'
    )
  );

create policy journal_ia_lecture_litige on journal_ia
  for select to authenticated
  using (enfant_id is not null and acces_exceptionnel_actif(enfant_id));
