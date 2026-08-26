-- 0013 — Distinguer un entraînement d'une évaluation.
--
-- 0006 ne connaissait qu'un seul objet : la mission, que l'enfant répète autant
-- qu'il veut, où l'indice est gratuit et l'erreur sans conséquence. Une
-- évaluation obéit à d'autres règles — un nombre d'essais arrêté, des indices
-- que le professeur autorise ou non, une note et une appréciation.
--
-- Un professeur en donne autant qu'il veut : rien ici ne limite le nombre de
-- devoirs, seulement le nombre d'essais sur chacun.
--
-- Rien ne justifie une seconde table pour l'évaluation elle-même — c'est une
-- suite d'exercices, exactement comme une mission. Ce qui change est le régime,
-- pas la structure. En revanche la correction et la note vivent à part, et pour
-- une raison qui n'a rien de théorique : elles doivent être écrites par le
-- professeur sur des lignes que le §3.2 lui interdit de toucher.

create type nature_travail as enum ('entrainement', 'evaluation');

alter table missions
  add column nature nature_travail not null default 'entrainement';

-- Qui l'a composé. Pour une mission générée, la colonne reste nulle et
-- `genere_par_ia` dit déjà l'essentiel ; pour un examen, elle porte le nom du
-- professeur qui devra en lire les résultats.
alter table missions
  add column auteur_id uuid references profils on delete set null;

-- Le nombre d'essais est une décision du professeur, pas une propriété du type
-- de travail. Un devoir sur table se passe une fois ; un devoir maison peut
-- s'autoriser un second envoi ; une évaluation de rattrapage n'aurait aucun sens
-- autrement. On exige seulement qu'une évaluation le dise explicitement — un
-- entraînement laissé à null reste illimité, ce qui est son régime normal.
alter table missions
  add column tentatives_max smallint
  check (tentatives_max is null or tentatives_max >= 1);

alter table missions
  add constraint evaluation_annonce_ses_essais
  check (nature <> 'evaluation' or tentatives_max is not null);

-- L'indice est le cœur du dispositif d'entraînement (§3.2 : « un indice
-- disponible à la demande vaut mieux qu'un échec sec »). Dans une évaluation il
-- fausserait la mesure, sans pour autant qu'on veuille l'interdire : c'est au
-- professeur de décider, contrôle par contrôle.
alter table missions
  add column indices_autorises boolean not null default true;

create index missions_nature_idx
  on missions (enfant_id, nature, cree_le desc);

-- Tous les travaux composés par un professeur donné.
create index missions_auteur_idx
  on missions (auteur_id, cree_le desc)
  where nature = 'evaluation';

-- ------------------------------------------------------- correction détaillée
--
-- La correction vit dans sa propre table, et non dans des colonnes ajoutées à
-- `tentatives`. La raison tient en une phrase : le professeur doit pouvoir
-- annoter la copie sans pouvoir la réécrire. RLS filtre des lignes, pas des
-- colonnes — lui ouvrir `tentatives` en écriture lui donnerait aussi `reponse`.
-- Deux tables, et la question ne se pose plus.
create table corrections (
  id uuid primary key default gen_random_uuid(),
  tentative_id uuid not null references tentatives on delete cascade unique,
  points_obtenus numeric(5, 2),
  commentaire text not null default '',
  corrigee_par uuid not null references profils on delete restrict,
  corrigee_le timestamptz not null default now()
);

create index corrections_correcteur_idx on corrections (corrigee_par, corrigee_le desc);

-- ------------------------------------------- ce qui relève d'un professeur
--
-- Écrire et lire les résultats ne suivent pas la même règle, et les confondre
-- était une erreur de 0009.
--
-- L'écriture exclut ce que l'IA a produit : un professeur ne valide pas une
-- suggestion, c'est le verrou du §3.2 et il ne bouge pas.
--
-- La lecture des copies suit la provenance du travail, pas celle de sa mise en
-- forme. Un professeur qui dépose son sujet en PDF et le fait transposer en
-- mission par l'IA a composé cet examen : le refuser à sa lecture reviendrait à
-- lui demander de corriger à l'aveugle, ou à le dissuader d'utiliser l'outil —
-- soit exactement le contraire de ce que le §3.2 cherche à lui offrir.
--
-- Trois filiations, et aucune n'est plus légitime que les autres. L'IA ne
-- produit jamais un travail à partir de rien : elle part d'un document déposé ou
-- d'un objectif proposé, et dans les deux cas quelqu'un l'a écrit. Suivre ces
-- liens jusqu'à leur auteur, c'est retrouver le professionnel dont ce travail
-- est la continuation.
--
--   auteur_id       — il a composé la mission lui-même.
--   support         — elle a été transposée depuis son document.
--   objectif        — elle a été engendrée par l'objectif qu'il a proposé.
--
-- La matière reste vérifiée dans les trois cas : ce n'est pas parce qu'un
-- document est passé entre ses mains qu'un professeur lit les copies des autres.
create or replace function mission_relevant_de_l_enseignant(p_mission uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from missions m
    join intervenants_enfant i on i.enfant_id = m.enfant_id
    left join adaptations a on a.id = m.adaptation_id
    left join supports s on s.id = a.support_id
    left join objectifs o on o.id = m.objectif_id
    where m.id = p_mission
      and i.profil_id = auth.uid()
      and i.retire_le is null
      and i.role = 'enseignant'
      and i.matiere_code = m.matiere_code
      and (
        m.auteur_id = auth.uid()
        or s.depose_par = auth.uid()
        or o.propose_par = auth.uid()
      )
  );
$$;

create or replace function exercice_relevant_de_l_enseignant(p_exercice uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from exercices e
    where e.id = p_exercice and mission_relevant_de_l_enseignant(e.mission_id)
  );
$$;

create or replace function tentative_ouverte_a_l_enseignant(p_tentative uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from tentatives t
    where t.id = p_tentative and exercice_relevant_de_l_enseignant(t.exercice_id)
  );
$$;

-- Un examen dont on ne lit pas les copies n'est pas un examen. Le professeur lit
-- les résultats de ses propres travaux — ceux qu'il a composés comme ceux nés de
-- ses documents — et rien d'autre : ni les tentatives des autres matières, ni
-- celles des missions d'entraînement qu'il n'a pas suscitées. La minimisation du
-- §3.4 ne cède que là où elle empêcherait le professeur de faire son métier.
create policy tentatives_lecture_enseignant on tentatives for select to authenticated
  using (exercice_relevant_de_l_enseignant(exercice_id));

create or replace function enfant_de_la_tentative(p_tentative uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select enfant_id from tentatives where id = p_tentative;
$$;

alter table corrections enable row level security;

-- L'enfant et sa famille lisent la correction, évidemment. Le professeur lit
-- les siennes. Les autres enseignants n'ont rien à faire dans la copie d'une
-- matière qui n'est pas la leur.
create policy corrections_lecture on corrections for select to authenticated
  using (
    peut_valider(enfant_de_la_tentative(tentative_id))
    or tentative_ouverte_a_l_enseignant(tentative_id)
  );

create policy corrections_ecriture on corrections for all to authenticated
  using (
    peut_valider(enfant_de_la_tentative(tentative_id))
    or tentative_ouverte_a_l_enseignant(tentative_id)
  )
  with check (
    corrigee_par = auth.uid()
    and (
      peut_valider(enfant_de_la_tentative(tentative_id))
      or tentative_ouverte_a_l_enseignant(tentative_id)
    )
  );

-- ------------------------------------------------------------- la notation
--
-- Table à part, et pour la même raison que `corrections` : le professeur doit
-- pouvoir noter un travail sans pouvoir écrire sur la ligne `missions`. Sur une
-- mission transposée par l'IA depuis son PDF, lui ouvrir la ligne lui donnerait
-- `statut` et `valide_par` — c'est-à-dire le pouvoir de valider lui-même une
-- suggestion de l'IA, ce que le §3.2 lui refuse. La note sort donc de la table.
--
-- `points` reste à sa place et ne se confond pas avec la note : c'est la monnaie
-- du projet moteur, celle qui ouvre les récompenses. Un enfant peut gagner ses
-- points sur un devoir noté 8, et c'est voulu — l'effort est récompensé même
-- quand le résultat ne l'est pas encore.
create table notations (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references missions on delete cascade unique,

  bareme numeric(5, 2) not null check (bareme > 0),
  note numeric(5, 2),
  appreciation text not null default '',

  note_par uuid not null references profils on delete restrict,
  note_le timestamptz not null default now(),

  constraint note_dans_le_bareme
    check (note is null or (note >= 0 and note <= bareme))
);

create index notations_mission_idx on notations (mission_id);

-- Les copies qu'aucun professeur n'a encore relues.
create index missions_a_corriger_idx
  on missions (auteur_id, cree_le)
  where nature = 'evaluation';

alter table notations enable row level security;

-- La note se lit par toute l'équipe : c'est une information de synthèse, du même
-- ordre que le niveau par matière du §3.1, et non le détail d'une copie.
create policy notations_lecture on notations for select to authenticated
  using (est_intervenant(enfant_de_la_mission(mission_id)));

create policy notations_ecriture on notations for all to authenticated
  using (
    peut_valider(enfant_de_la_mission(mission_id))
    or mission_relevant_de_l_enseignant(mission_id)
  )
  with check (
    note_par = auth.uid()
    and (
      peut_valider(enfant_de_la_mission(mission_id))
      or mission_relevant_de_l_enseignant(mission_id)
    )
  );

-- ------------------------------------------------- reprise de la politique
--
-- 0009 autorisait l'enseignant à écrire dans sa matière sans pouvoir contraindre
-- `auteur_id` : la colonne n'existait pas encore. Sans elle, un professeur
-- composerait un examen au nom d'un collègue — et c'est ce collègue qui le
-- retrouverait dans sa liste de copies à corriger.
--
-- On n'exige pas qu'il *soit* l'auteur, seulement qu'il ne désigne personne
-- d'autre : une mission produite par l'IA sous un objectif validé n'a pas
-- d'auteur humain, et le professeur qui l'ouvre à l'enfant ne l'a pas écrite.

drop policy missions_ecriture on missions;

create policy missions_ecriture on missions for all to authenticated
  using (
    peut_valider(enfant_id)
    or (
      matiere_ouverte_a_l_ecriture(enfant_id, matiere_code)
      and objectif_id is not null
      and objectif_valide(objectif_id)
    )
  )
  with check (
    peut_valider(enfant_id)
    or (
      matiere_ouverte_a_l_ecriture(enfant_id, matiere_code)
      and objectif_id is not null
      and objectif_valide(objectif_id)
      and (auteur_id is null or auteur_id = auth.uid())
    )
  );
