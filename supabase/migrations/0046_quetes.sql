-- 0046 — La quête du trimestre.
--
-- Tout existait séparément et rien ne se tenait : des missions en liste plate,
-- des badges par matière, une récompense familiale, des pièces au quotidien.
-- L'enfant voyait quatre compteurs sans savoir lequel racontait son trimestre.
--
-- La quête est le récit qui les relie. Un titre dans son univers, un ensemble
-- de missions, les badges visés, et la récompense au bout.
--
-- ---------------------------------------------------------------------------
-- CE QUI DÉCIDE DE LA RÉUSSITE
--
-- Les badges, et rien d'autre. C'est un choix, et il découle de la réserve
-- posée sur les notes : une quête se gagne sur l'effort, pas sur le résultat.
--
--   les badges  disent que les objectifs de l'enseignant ont été atteints.
--               C'est la seule mesure qui vienne de ce que l'école attendait.
--   les pièces  récompensent le quotidien et alimentent la boutique. Elles ne
--               conditionnent pas la quête : un enfant qui enchaîne les
--               exercices faciles ne doit pas gagner son trimestre pour autant.
--   les notes   ajoutent des pièces en bonus (0043) et n'entrent nulle part
--               ailleurs. Une mauvaise note ne coûte jamais une quête.
--
-- La quête se clôt quand les badges visés sont obtenus, à la date où ça arrive.
-- Pas à la fin du trimestre : un enfant qui remplit sa quête en semaine 8
-- n'attend pas quatre semaines pour l'apprendre. Le trimestre borne la quête,
-- il ne la retient pas.
-- ---------------------------------------------------------------------------

alter type type_notification add value if not exists 'quete_reussie';

create type statut_quete as enum ('en_cours', 'reussie', 'close');

create table quetes (
  id uuid primary key default gen_random_uuid(),
  enfant_id uuid not null references enfants on delete cascade,

  annee_id uuid references annees_enfant on delete set null,
  trimestre smallint not null check (trimestre between 1 and 3),

  -- Le titre que l'enfant lit, écrit dans le lexique de son projet moteur.
  titre text not null,
  -- Ce que les adultes lisent dans le bilan trimestriel. Séparés pour la même
  -- raison qu'en 0006 : changer d'univers ne doit pas effacer ce qui a été fait.
  intitule_scolaire text not null default '',
  description text not null default '',

  projet_moteur_id uuid references projets_moteurs on delete set null,
  recompense_id uuid references recompenses_familiales on delete set null,

  statut statut_quete not null default 'en_cours',
  ouverte_le date not null default current_date,
  reussie_le date,
  close_le date,

  -- Nul quand les badges visés sont tous tombés : la quête s'est conclue
  -- d'elle-même. Renseigné quand un adulte l'a conclue sur appréciation.
  --
  -- Les deux sont des réussites pleines pour l'enfant. La distinction ne sert
  -- pas à hiérarchiser, elle sert à relire : un trimestre où trois quêtes ont
  -- été conclues sur appréciation dit que les objectifs étaient mal calibrés,
  -- et c'est une information sur les adultes, pas sur l'enfant.
  reussie_par uuid references profils on delete set null,
  motif_reussite text not null default '',

  cree_par uuid not null references profils on delete restrict,

  unique (enfant_id, annee_id, trimestre),
  constraint quete_reussie_est_datee
    check ((statut = 'reussie') = (reussie_le is not null)),
  constraint reussite_sur_appreciation_motivee
    check (reussie_par is null or length(btrim(motif_reussite)) >= 5)
);

create index quetes_enfant_idx on quetes (enfant_id, trimestre);

-- Une seule quête en cours par enfant : deux récits parallèles, c'est deux
-- récits qu'on ne suit pas. C'est la même règle que le projet moteur de 0002.
create unique index quetes_une_seule_en_cours
  on quetes (enfant_id) where statut = 'en_cours';

-- Les badges que ce trimestre vise. Déclarés à l'ouverture par l'équipe : c'est
-- l'endroit où « ce trimestre, on travaille les maths et la communication » se
-- dit une fois, au lieu d'être déduit après coup de ce qui a été fait.
create table quetes_badges_vises (
  quete_id uuid not null references quetes on delete cascade,
  matiere_code text references matieres on delete restrict,
  domaine_code text references domaines_transversaux on delete restrict,
  constraint badge_vise_a_un_champ check (num_nonnulls(matiere_code, domaine_code) = 1)
);

create unique index quetes_badges_vises_unique
  on quetes_badges_vises (quete_id, coalesce(matiere_code, domaine_code));

-- Les missions du trimestre se rattachent à la quête. Facultatif : une mission
-- peut exister hors quête, et c'est le cas de tout ce qui précède la première.
alter table missions
  add column quete_id uuid references quetes on delete set null;

create index missions_quete_idx on missions (quete_id);

-- ------------------------------------------------------------ la progression

-- Où en est la quête : les badges visés, ceux obtenus depuis son ouverture, et
-- les missions qui s'y rattachent. C'est l'écran principal de l'enfant.
create or replace function progression_quete(p_quete uuid)
returns table (
  quete_id uuid,
  titre text,
  trimestre smallint,
  statut statut_quete,
  badges_vises bigint,
  badges_obtenus bigint,
  missions_total bigint,
  missions_reussies bigint,
  pieces_gagnees bigint,
  progression numeric
)
language sql stable security definer set search_path = public as $$
  select
    q.id,
    q.titre,
    q.trimestre,
    q.statut,
    count(distinct v.coalesce_champ),
    count(distinct v.coalesce_champ) filter (where v.obtenu),
    count(distinct m.id),
    count(distinct m.id) filter (where m.statut = 'reussie'),
    coalesce((
      select sum(g.pieces) from pieces_gagnees g
      join missions mm on mm.id = g.mission_id
      where mm.quete_id = q.id
    ), 0),
    case when count(distinct v.coalesce_champ) = 0 then 0
         else round(100.0 * count(distinct v.coalesce_champ) filter (where v.obtenu)
                    / count(distinct v.coalesce_champ), 0)
    end
  from quetes q
  left join lateral (
    select
      coalesce(bv.matiere_code, bv.domaine_code) as coalesce_champ,
      exists (
        select 1 from badges_obtenus b
        where b.enfant_id = q.enfant_id
          and b.matiere_code is not distinct from bv.matiere_code
          and b.domaine_code is not distinct from bv.domaine_code
          and b.obtenu_le >= q.ouverte_le
      ) as obtenu
    from quetes_badges_vises bv where bv.quete_id = q.id
  ) v on true
  left join missions m on m.quete_id = q.id
  where q.id = p_quete
    and (est_intervenant(q.enfant_id) or est_l_enfant(q.enfant_id))
  group by q.id, q.titre, q.trimestre, q.statut;
$$;

-- ------------------------------------------------------- la clôture

-- Déclenchée par l'attribution d'un badge, et non par une date. Un enfant qui
-- remplit sa quête en semaine 8 l'apprend en semaine 8.
create or replace function conclure_la_quete()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_quete quetes%rowtype;
  v_manquants integer;
  v_compte uuid;
begin
  select * into v_quete from quetes
  where enfant_id = new.enfant_id and statut = 'en_cours';

  if not found then
    return new;
  end if;

  select count(*) into v_manquants
  from quetes_badges_vises bv
  where bv.quete_id = v_quete.id
    and not exists (
      select 1 from badges_obtenus b
      where b.enfant_id = v_quete.enfant_id
        and b.matiere_code is not distinct from bv.matiere_code
        and b.domaine_code is not distinct from bv.domaine_code
        and b.obtenu_le >= v_quete.ouverte_le
    );

  if v_manquants > 0 then
    return new;
  end if;

  update quetes
    set statut = 'reussie', reussie_le = current_date
    where id = v_quete.id;

  -- La famille est prévenue : c'est elle qui tient la récompense, et une quête
  -- gagnée dont personne ne s'aperçoit vaut une promesse non tenue.
  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select i.profil_id, v_quete.enfant_id, 'quete_reussie',
         'Quête réussie : ' || v_quete.titre,
         'Tous les badges visés du trimestre ' || v_quete.trimestre || ' sont obtenus.',
         '/enfants/' || v_quete.enfant_id || '/quetes/' || v_quete.id
  from intervenants_enfant i
  where i.enfant_id = v_quete.enfant_id
    and i.retire_le is null
    and i.role in ('parent', 'referent');

  select compte_id into v_compte from enfants where id = v_quete.enfant_id;

  if v_compte is not null then
    insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
    values (v_compte, v_quete.enfant_id, 'quete_reussie',
            'Tu as terminé : ' || v_quete.titre, '',
            '/mes-quetes/' || v_quete.id);
  end if;

  return new;
end;
$$;

create trigger badges_concluent_la_quete
  after insert on badges_obtenus
  for each row execute function conclure_la_quete();

-- ------------------------------------------------- ce que l'enfant regarde

create or replace function ma_quete(p_enfant uuid)
returns table (
  quete_id uuid,
  titre text,
  description text,
  trimestre smallint,
  statut statut_quete,
  badges_vises bigint,
  badges_obtenus bigint,
  missions_total bigint,
  missions_reussies bigint,
  pieces_gagnees bigint,
  progression numeric
)
language sql stable security definer set search_path = public as $$
  select p.quete_id, p.titre, q.description, p.trimestre, p.statut,
         p.badges_vises, p.badges_obtenus, p.missions_total, p.missions_reussies,
         p.pieces_gagnees, p.progression
  from quetes q
  cross join lateral progression_quete(q.id) p
  where q.enfant_id = p_enfant
    and q.statut = 'en_cours'
    and (est_l_enfant(p_enfant) or est_intervenant(p_enfant));
$$;

-- ==================================================================== RLS

alter table quetes enable row level security;
alter table quetes_badges_vises enable row level security;

-- L'enfant voit sa quête : c'est le récit de son trimestre, et le cacher
-- reviendrait à lui demander de courir sans lui dire vers quoi.
create policy quetes_lecture on quetes for select to authenticated
  using (est_intervenant(enfant_id) or est_l_enfant(enfant_id));

-- Ouvrir une quête revient à décider de ce que sera le trimestre : cela se pose
-- en réunion, donc entre les mains de la famille et du référent.
create policy quetes_ecriture on quetes for all to authenticated
  using (peut_valider(enfant_id)) with check (peut_valider(enfant_id));

create policy quetes_badges_lecture on quetes_badges_vises for select to authenticated
  using (
    exists (select 1 from quetes q where q.id = quete_id
            and (est_intervenant(q.enfant_id) or est_l_enfant(q.enfant_id)))
  );

create policy quetes_badges_ecriture on quetes_badges_vises for all to authenticated
  using (exists (select 1 from quetes q where q.id = quete_id and peut_valider(q.enfant_id)))
  with check (exists (select 1 from quetes q where q.id = quete_id and peut_valider(q.enfant_id)));

-- Le statut se pose de deux façons, et les deux sont légitimes.
--
-- Par les badges : la quête tombe d'elle-même, personne ne signe.
--
-- Sur appréciation : un adulte du cercle qui valide estime que l'enfant a fait
-- le maximum de ce dont il était capable ce trimestre-là. Refuser cette porte
-- serait une faute — un enfant qui a franchi un blocage énorme sans cocher ses
-- cases mérite sa quête autant qu'un autre, et lui refuser sa récompense au
-- motif qu'un compteur n'est pas plein est exactement ce que cet outil ne doit
-- pas faire. C'est le principe déjà posé pour les badges en 0044.
--
-- Ce qui reste verrouillé : le geste est signé et motivé. Pas pour en
-- décourager l'usage — pour qu'on puisse le relire.
create or replace function proteger_le_statut_de_la_quete()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_manquants integer;
begin
  if new.statut is not distinct from old.statut or auth.uid() is null then
    return new;
  end if;

  -- Clore une quête manquée reste possible : un trimestre se termine, réussi ou
  -- non, et laisser une quête ouverte indéfiniment serait pire.
  if new.statut = 'close' then
    return new;
  end if;

  if new.statut = 'reussie' then
    select count(*) into v_manquants
    from quetes_badges_vises bv
    where bv.quete_id = new.id
      and not exists (
        select 1 from badges_obtenus b
        where b.enfant_id = new.enfant_id
          and b.matiere_code is not distinct from bv.matiere_code
          and b.domaine_code is not distinct from bv.domaine_code
          and b.obtenu_le >= new.ouverte_le
      );

    if v_manquants > 0 then
      if not peut_valider(new.enfant_id) then
        raise exception 'Il manque % badge(s). Conclure une quête malgré cela revient aux titulaires de l''autorité parentale ou au référent.', v_manquants;
      end if;

      if new.reussie_par is distinct from auth.uid() then
        raise exception 'Conclure une quête sur appréciation se signe : renseignez reussie_par.';
      end if;

      if length(btrim(coalesce(new.motif_reussite, ''))) < 5 then
        raise exception 'Il manque % badge(s). La quête reste concluable, mais dites en quoi l''enfant a fait ce qu''il pouvait — ce texte lui sera montré.', v_manquants;
      end if;
    end if;
  end if;

  return new;
end;
$$;

create trigger quetes_protegent_leur_statut
  before update on quetes
  for each row execute function proteger_le_statut_de_la_quete();
