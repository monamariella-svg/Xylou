-- 0035 — Changer d'univers sans effacer ce qui a été vécu.
--
-- 0002 prévoyait qu'un enfant se lasse, et posait un seul projet moteur actif à
-- la fois. Il ne disait rien du passage de l'un à l'autre — or les missions
-- portent leur `intitule_narratif` écrit dans le lexique de l'univers en cours.
-- Sans traitement, le dossier devient un mélange de deux mondes.
--
-- La règle, et elle se lit dans les deux sens :
--
--   les missions terminées restent telles quelles. Réussies ou abandonnées,
--   elles racontent ce que l'enfant a réellement fait, dans les mots qui étaient
--   les siens à ce moment-là. Les réécrire dans le nouvel univers falsifierait
--   son histoire — et lui retirerait le souvenir d'avoir été bon à quelque chose
--   qui comptait pour lui.
--
--   les missions ouvertes sont recréées. Elles n'ont pas encore été vécues :
--   rien ne s'y attache. Les transposer coûte un appel au modèle et évite de
--   présenter à l'enfant, le lendemain d'un changement d'univers, un défi
--   formulé dans celui qu'il vient de quitter.
--
-- Ce qui ne bouge pas : les points déjà gagnés et les récompenses déjà acquises.
-- Le solde se calcule sur `missions.points` et `recompenses_obtenues`, l'un et
-- l'autre inchangés. Un enfant qui change d'univers ne repart pas de zéro — ce
-- serait le punir de s'être lassé.

-- Le lien entre l'ancienne mission et celle qui la reprend. `remplacee_par`
-- distingue un abandon réel — l'enfant a renoncé, ou l'adulte a retiré la
-- mission — d'une transposition, où rien n'a été abandonné du tout.
alter table missions
  add column remplacee_par uuid references missions on delete set null,
  -- Vrai tant que le lexique du nouvel univers n'a pas été appliqué. La mission
  -- reste en `proposee`, donc invisible à l'enfant (0032), jusqu'à ce que
  -- quelqu'un ait relu ce que le modèle a écrit.
  add column a_retransposer boolean not null default false;

create index missions_a_retransposer_idx
  on missions (enfant_id) where a_retransposer;

-- ------------------------------------------------------- le changement

create or replace function changer_de_projet_moteur(
  p_enfant uuid,
  p_titre text,
  p_univers univers_moteur default 'autre',
  p_description text default '',
  p_lexique jsonb default '{}'::jsonb
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_nouveau uuid;
  v_ancienne missions%rowtype;
  v_copie uuid;
begin
  if not peut_valider(p_enfant) then
    raise exception 'Le projet moteur est décidé par la famille ou le référent.';
  end if;

  -- L'index unique de 0002 n'admet qu'un projet actif : il faut refermer avant
  -- d'ouvrir, et dans la même transaction pour ne jamais laisser l'enfant sans
  -- univers.
  update projets_moteurs set actif = false
    where enfant_id = p_enfant and actif;

  insert into projets_moteurs (enfant_id, titre, univers, description, lexique, cree_par)
  values (p_enfant, p_titre, p_univers, p_description, p_lexique, auth.uid())
  returning id into v_nouveau;

  -- Les missions encore ouvertes, une par une. Le contenu pédagogique est
  -- recopié tel quel : c'est le même exercice, seule son enveloppe change.
  for v_ancienne in
    select * from missions
    where enfant_id = p_enfant
      and statut in ('proposee', 'validee', 'en_cours')
      and remplacee_par is null
  loop
    insert into missions (
      enfant_id, projet_moteur_id, objectif_id, adaptation_id,
      matiere_code, domaine_code, titre, intitule_narratif,
      difficulte, points, statut, genere_par_ia, modele_ia,
      nature, auteur_id, tentatives_max, indices_autorises,
      ordre, a_retransposer
    )
    values (
      v_ancienne.enfant_id, v_nouveau, v_ancienne.objectif_id, v_ancienne.adaptation_id,
      v_ancienne.matiere_code, v_ancienne.domaine_code, v_ancienne.titre,
      -- L'ancienne formulation narrative ne suit pas : elle appartient à
      -- l'univers qu'on quitte. Le modèle la réécrira, et un adulte la relira.
      '',
      v_ancienne.difficulte, v_ancienne.points, 'proposee',
      v_ancienne.genere_par_ia, v_ancienne.modele_ia,
      v_ancienne.nature, v_ancienne.auteur_id, v_ancienne.tentatives_max,
      v_ancienne.indices_autorises, v_ancienne.ordre, true
    )
    returning id into v_copie;

    -- Les exercices suivent avec leur substance — contenu, correction, indice.
    -- La consigne est reprise telle quelle et sera réécrite en même temps que
    -- l'intitulé : la garder évite de perdre l'énoncé si la transposition
    -- échoue, et `a_retransposer` empêche qu'elle atteigne l'enfant entre-temps.
    insert into exercices (mission_id, ordre, consigne, type_reponse, contenu, correction, indice, modele_id)
    select v_copie, e.ordre, e.consigne, e.type_reponse, e.contenu, e.correction, e.indice, e.modele_id
    from exercices e
    where e.mission_id = v_ancienne.id
    order by e.ordre;

    -- L'ancienne est close, mais `remplacee_par` dit qu'elle n'a pas été
    -- abandonnée : l'écran peut afficher « transposée » plutôt que « abandonnée »,
    -- et l'enfant n'a pas à lire qu'il a renoncé à quelque chose.
    --
    -- Le `case` n'est pas une précaution de style : la contrainte de 0006 exige
    -- un validateur dès qu'une mission quitte `proposee`. Une mission jamais
    -- validée n'en a pas, et la faire passer en `abandonnee` échouerait. Elle
    -- garde donc son statut — elle n'avait de toute façon atteint personne — et
    -- c'est `remplacee_par` qui la retire des listes.
    update missions
      set statut = case when valide_par is not null then 'abandonnee' else statut end,
          remplacee_par = v_copie
      where id = v_ancienne.id;
  end loop;

  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  values (p_enfant, auth.uid(), 'changement_projet_moteur', 'projets_moteurs', v_nouveau,
          jsonb_build_object('titre', p_titre, 'univers', p_univers));

  return v_nouveau;
end;
$$;

-- Ce qui attend d'être réécrit. La file que l'application donne au modèle, et
-- que quelqu'un relit avant de rouvrir les missions à l'enfant.
create or replace function missions_a_retransposer(p_enfant uuid)
returns table (
  mission_id uuid,
  titre text,
  matiere_code text,
  domaine_code text,
  exercices bigint
)
language sql stable security definer set search_path = public as $$
  select m.id, m.titre, m.matiere_code, m.domaine_code, count(e.id)
  from missions m
  left join exercices e on e.mission_id = m.id
  where m.enfant_id = p_enfant
    and m.a_retransposer
    and est_intervenant(p_enfant)
  group by m.id, m.titre, m.matiere_code, m.domaine_code
  order by m.ordre;
$$;

-- Une mission transposée ne s'ouvre pas tant que le lexique n'a pas été appliqué.
-- Sans ce garde-fou, il suffirait de valider sans regarder pour envoyer à
-- l'enfant un défi rédigé dans l'univers qu'il vient d'abandonner — exactement
-- ce que le changement cherchait à éviter.
create or replace function exiger_la_retransposition()
returns trigger language plpgsql as $$
begin
  if new.statut <> 'proposee' and new.a_retransposer then
    raise exception 'Cette mission attend d''être réécrite dans le nouvel univers avant d''être ouverte.';
  end if;
  return new;
end;
$$;

create trigger missions_exigent_la_retransposition
  before insert or update on missions
  for each row execute function exiger_la_retransposition();
