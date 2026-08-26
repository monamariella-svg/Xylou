-- 0017 — Ce que les professionnels pensent de ce que l'IA propose.
--
-- Deux notations coexistent désormais, et il faut les tenir bien séparées :
--
--   notations (0013) — ce que l'enfant a réussi. Elle parle de lui.
--   avis_ia   (ici)  — ce que la proposition valait. Elle parle de l'outil.
--
-- Les confondre serait grave dans les deux sens : une mission mal fichue ferait
-- baisser la note de l'enfant, et un enfant en difficulté ferait passer l'IA
-- pour mauvaise. Deux tables, aucun lien entre elles.
--
-- Le §3.4 fait du calibrage le principal risque produit, et le §3.7 rappelle
-- qu'on ne pilote pas ce qu'on ne mesure pas. `journal_ia` enregistre déjà ce
-- que l'IA a coûté ; il ne dit rien de ce qu'elle valait. C'est le seul retour
-- qui vienne de quelqu'un qui connaît à la fois la matière et l'enfant.

create type verdict_ia as enum ('pertinente', 'a_ajuster', 'inadaptee');

create table avis_ia (
  id uuid primary key default gen_random_uuid(),

  -- Ce sur quoi porte l'avis. Exactement l'un des deux : une mission proposée,
  -- ou une adaptation de support. Ce sont les deux sorties de l'IA qu'un
  -- professionnel voit et peut juger sur pièce.
  mission_id uuid references missions on delete cascade,
  adaptation_id uuid references adaptations on delete cascade,

  verdict verdict_ia not null,
  -- Le champ qui porte toute la valeur du dispositif. « Inadaptée » sans motif
  -- n'apprend rien ; « le vocabulaire du jeu écrase l'énoncé mathématique »
  -- se corrige.
  motif text not null default '',

  auteur_id uuid not null references profils on delete restrict,
  cree_le timestamptz not null default now(),

  constraint avis_porte_sur_une_seule_sortie
    check (num_nonnulls(mission_id, adaptation_id) = 1),

  -- Un avis par personne et par objet : on révise le sien, on n'en empile pas.
  unique (mission_id, auteur_id),
  unique (adaptation_id, auteur_id)
);

create index avis_ia_mission_idx on avis_ia (mission_id);
create index avis_ia_adaptation_idx on avis_ia (adaptation_id);
-- Les avis négatifs, du plus récent au plus ancien : c'est la liste qu'on relit
-- avant de retoucher un prompt.
create index avis_ia_negatifs_idx on avis_ia (cree_le desc)
  where verdict <> 'pertinente';

alter table avis_ia enable row level security;

-- Toute l'équipe lit les avis. Savoir qu'un collègue a jugé une transposition
-- inadaptée évite de la valider sans y regarder, et évite surtout de signaler
-- deux fois le même défaut.
create policy avis_ia_lecture on avis_ia for select to authenticated
  using (
    case
      when mission_id is not null then est_intervenant(enfant_de_la_mission(mission_id))
      else est_intervenant(enfant_de_l_adaptation(adaptation_id))
    end
  );

-- On donne son avis, on ne corrige pas celui d'un autre. La matière s'applique
-- ici comme partout ailleurs en écriture : `matiere_ouverte_a_l_ecriture()`
-- laisse passer les parents et le référent, qui n'ont pas de matière, et cantonne
-- l'enseignant à la sienne.
create policy avis_ia_ecriture on avis_ia for all to authenticated
  using (auteur_id = auth.uid())
  with check (
    auteur_id = auth.uid()
    and case
      when mission_id is not null then exists (
        select 1 from missions m
        where m.id = mission_id
          and matiere_ouverte_a_l_ecriture(m.enfant_id, m.matiere_code)
      )
      else exists (
        select 1 from adaptations a
        join supports s on s.id = a.support_id
        where a.id = adaptation_id
          and matiere_ouverte_a_l_ecriture(s.enfant_id, s.matiere_code)
      )
    end
  );

-- Ce qu'on relit pour calibrer : chaque sortie jugée, par qui, et pourquoi.
-- Restreinte aux enfants que le lecteur accompagne — la vue est en
-- security_invoker, donc les politiques ci-dessus s'appliquent d'elles-mêmes.
create view qualite_ia
with (security_invoker = true) as
  select
    v.verdict,
    v.motif,
    v.cree_le,
    v.auteur_id,
    coalesce(m.matiere_code, s.matiere_code) as matiere_code,
    coalesce(m.modele_ia, a.modele_ia) as modele_ia,
    case when v.mission_id is not null then 'mission' else 'adaptation' end as sortie
  from avis_ia v
  left join missions m on m.id = v.mission_id
  left join adaptations a on a.id = v.adaptation_id
  left join supports s on s.id = a.support_id;
