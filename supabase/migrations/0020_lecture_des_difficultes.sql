-- 0020 — Comprendre où l'enfant bloque.
--
-- 0019 s'arrêtait aux totaux : « deux réussites sur cinq ». C'était un mauvais
-- arbitrage. Ce chiffre ne dit pas quoi faire — il dit seulement qu'il faudrait
-- faire quelque chose. Or tout le dispositif repose sur la capacité du
-- professionnel à ajuster : réviser le nombre d'exercices, changer d'angle,
-- reprendre une notion en amont. Aucun de ces gestes ne se décide sur un ratio.
--
-- Ce fichier ouvre donc le détail — la réponse donnée, l'exercice où ça a
-- coincé, le recours à l'indice — mais pas à tout le monde et pas partout :
--
--   la famille       — tout, sur son enfant. C'est déjà le cas depuis 0009.
--   le pilote        — tout, sur les objectifs qu'il pilote. Il en répond.
--   les autres       — rien de plus qu'avant.
--
-- La minimisation du §3.4 ne consiste pas à cacher les difficultés de l'enfant à
-- ceux qui doivent l'aider ; elle consiste à ne pas les étaler devant ceux qui
-- n'ont rien à en faire. Un professeur d'histoire n'a pas à savoir sur quoi
-- l'enfant trébuche en mathématiques. Celui qui pilote l'objectif de
-- mathématiques, si — sinon il ne pilote rien.

-- ---------------------------------------------- accès aux tentatives brutes

create or replace function exercice_sous_objectif_pilote(p_exercice uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from exercices e
    join missions m on m.id = e.mission_id
    where e.id = p_exercice
      and m.objectif_id is not null
      and pilote_l_objectif(m.objectif_id)
  );
$$;

-- S'ajoute à `tentatives_lecture_enseignant` (0013), qui couvre la filiation —
-- ce qu'il a composé, déposé ou proposé. Celle-ci couvre la responsabilité :
-- ce qu'il pilote aujourd'hui, quelle qu'en soit l'origine. Un objectif proposé
-- par le référent et piloté par le professeur de mathématiques tombe dans la
-- seconde et pas dans la première.
create policy tentatives_lecture_pilote on tentatives for select to authenticated
  using (exercice_sous_objectif_pilote(exercice_id));

-- Les corrections suivent les tentatives qu'elles annotent.
create policy corrections_lecture_pilote on corrections for select to authenticated
  using (
    exists (
      select 1 from tentatives t
      where t.id = tentative_id and exercice_sous_objectif_pilote(t.exercice_id)
    )
  );

-- ------------------------------------------------ le détail d'un objectif

-- Chaque exercice proposé sous l'objectif, avec ce que l'enfant a répondu et
-- comment ça s'est passé. C'est l'écran depuis lequel on décide d'ajouter des
-- exercices ou de reprendre autrement.
--
-- SECURITY DEFINER avec contrôle explicite, pour la raison déjà donnée en 0019 :
-- sous RLS, un pilote sans droit sur `tentatives` verrait des lignes vides
-- plutôt qu'un refus, et conclurait que l'enfant n'a rien fait.
create or replace function detail_objectif(p_objectif uuid)
returns table (
  exercice_id uuid,
  ordre smallint,
  consigne text,
  indice text,
  tentative_id uuid,
  reponse jsonb,
  reussie boolean,
  aide_utilisee boolean,
  duree_secondes integer,
  tentee_le timestamptz,
  points_obtenus numeric,
  commentaire_correction text
)
language sql stable security definer set search_path = public as $$
  select
    e.id, e.ordre, e.consigne, e.indice,
    t.id, t.reponse, t.reussie, t.aide_utilisee, t.duree_secondes, t.cree_le,
    c.points_obtenus, c.commentaire
  from objectifs o
  join missions m on m.objectif_id = o.id
  join exercices e on e.mission_id = m.id
  left join tentatives t on t.exercice_id = e.id and t.enfant_id = o.enfant_id
  left join corrections c on c.tentative_id = t.id
  where o.id = p_objectif
    and (peut_valider(o.enfant_id) or pilote_l_objectif(o.id))
  order by e.ordre, t.cree_le;
$$;

-- ------------------------------------------- où ça bloque, tous objectifs

-- La lecture qui manquait vraiment : non pas « combien », mais « sur quoi ».
-- Chaque repère de compétence que l'enfant a rencontré, ce qu'il y réussit, et
-- surtout à quel point il s'y appuie sur l'indice — un enfant qui réussit
-- toujours avec l'aide et jamais sans n'a pas encore acquis, même si son taux de
-- réussite est excellent. C'est le genre de chose qu'un ratio global masque.
--
-- Trié du plus fragile au plus solide : la première ligne est celle sur laquelle
-- il faut travailler.
--
-- La matière cloisonne ici comme partout ailleurs. `matiere_ouverte_a_l_ecriture`
-- rend vrai pour les parents et le référent, qui n'ont pas de matière, et
-- cantonne l'enseignant à la sienne — un professeur d'histoire ne verra jamais
-- cette liste pour les mathématiques.
create or replace function difficultes_de_l_enfant(p_enfant uuid)
returns table (
  repere_id uuid,
  matiere_code text,
  domaine text,
  libelle text,
  tentatives_total bigint,
  reussites bigint,
  echecs bigint,
  reussites_avec_aide bigint,
  taux_reussite numeric
)
language sql stable security definer set search_path = public as $$
  select
    r.id,
    r.matiere_code,
    r.domaine,
    r.libelle,
    count(t.id),
    count(t.id) filter (where t.reussie),
    count(t.id) filter (where not t.reussie),
    count(t.id) filter (where t.reussie and t.aide_utilisee),
    round(100.0 * count(t.id) filter (where t.reussie) / nullif(count(t.id), 0), 0)
  from tentatives t
  join exercices e on e.id = t.exercice_id
  join missions m on m.id = e.mission_id
  left join objectifs o on o.id = m.objectif_id
  left join modeles_exercice mo on mo.id = e.modele_id
  join reperes_competences r on r.id = coalesce(o.repere_id, mo.repere_id)
  where t.enfant_id = p_enfant
    and est_intervenant(p_enfant)
    and matiere_ouverte_a_l_ecriture(p_enfant, r.matiere_code)
  group by r.id, r.matiere_code, r.domaine, r.libelle
  order by
    round(100.0 * count(t.id) filter (where t.reussie) / nullif(count(t.id), 0), 0)
      asc nulls last,
    count(t.id) desc;
$$;
