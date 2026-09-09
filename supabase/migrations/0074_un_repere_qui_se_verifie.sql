-- 0074 — De quoi un repère a besoin pour qu'on puisse en faire une question.
--
-- 0003 donne à un repère un libellé — « accorder le verbe avec son sujet ».
-- C'est assez pour ranger, pas pour générer : un modèle à qui l'on demande une
-- question là-dessus peut aussi bien produire un exercice de conjugaison, une
-- dictée ou une question de cours. Trois exercices qui ne mesurent pas la même
-- chose, et rien dans la base ne dit lequel était attendu.
--
-- ---------------------------------------------------------------------------
-- CE DÉCOUPAGE EXISTE DÉJÀ, ET IL EST OFFICIEL
--
-- On avait supposé qu'il faudrait le faire écrire par un enseignant. C'était
-- faux. Les « Guides pour le professeur » (CP à CM2) et les « Documents à
-- destination des équipes pédagogiques » (6e à 4e) qui accompagnent les
-- évaluations nationales décomposent déjà chaque exercice en :
--
--   la compétence précise visée, avec son code au programme ;
--   la consigne exacte donnée à l'élève ;
--   les critères de réussite, item par item ;
--   l'analyse des erreurs les plus fréquentes.
--
-- Produit par la DEPP et l'IGÉSR avec des conseillers pédagogiques et des
-- professeurs. Librement téléchargeable. C'est la matière première.
--
-- ---------------------------------------------------------------------------
-- POURQUOI ÉTENDRE `reperes_competences` PLUTÔT QUE CRÉER UNE TABLE
--
-- La tentation serait une table `reperes_verifiables` à côté. Elle produirait
-- deux référentiels scolaires là où il en faut un : un bilan citerait l'un, un
-- objectif l'autre, et personne ne saurait lequel fait foi.
--
-- 0072 a séparé les *domaines* des *repères* parce que ce sont deux natures
-- différentes — un regroupement officiel et un attendu vérifiable. Ici, il
-- s'agit du même objet, mieux renseigné. On ajoute des colonnes.
-- ---------------------------------------------------------------------------

alter table reperes_competences
  -- Le code de la compétence au programme ou au socle, tel que le guide le
  -- porte. `code` existe déjà en 0003 mais sans provenance : celui-ci se cite.
  add column code_programme text,

  -- La consigne telle qu'elle est donnée à l'élève dans l'évaluation
  -- nationale. Elle ne sera pas reprise mot pour mot — le pré-bilan décide de
  -- la formulation — mais elle dit ce que la question doit demander.
  add column consigne_reference text not null default '',

  -- À quoi l'on reconnaît que c'est réussi. C'est la colonne qui manquait :
  -- sans elle, une réponse ne peut être corrigée que par ressemblance, et l'on
  -- ne sait pas ce qu'on a mesuré.
  add column critere_de_reussite text not null default '',

  -- Les erreurs que font le plus souvent les élèves sur ce repère.
  -- Deux usages, et le second n'est pas évident : elles servent à écrire des
  -- propositions fausses plausibles. Un QCM dont les mauvaises réponses sont
  -- absurdes ne mesure rien — l'enfant élimine sans savoir.
  add column erreurs_types text[] not null default '{}';

comment on column reperes_competences.critere_de_reussite is
  'Ce qui distingue une réussite d''un échec. Sans lui, une réponse ne se corrige que par ressemblance.';

-- ---------------------------------------------------------------------------
-- UN PIÈGE À NE PAS TOMBER DEDANS : LES SEUILS
--
-- Ces guides publient aussi des seuils de maîtrise — combien d'items réussis
-- placent l'élève dans tel groupe. Ils ne sont **pas** repris ici, et c'est
-- délibéré.
--
-- Ces seuils sont calibrés sur l'évaluation nationale telle qu'elle est passée :
-- même consigne, même durée, même format, en classe. Un bilan Xylou change
-- précisément tout cela — le format s'adapte à l'enfant, la durée se découpe,
-- la question se reformule. Appliquer leurs seuils à nos passations reviendrait
-- à comparer deux mesures qui n'ont de commun que le nom.
--
-- La traduction en groupes de maîtrise reste donc celle de 0073 : dérivée de
-- notre propre échelle, honnête sur ce qu'elle est.
-- ---------------------------------------------------------------------------

-- Un repère utilisable pour générer une question est un repère qui dit ce
-- qu'il attend. Cette vue nomme l'écart plutôt que de le laisser se découvrir
-- au moment où une génération produit n'importe quoi.
create or replace view reperes_generables
with (security_invoker = true) as
  select
    r.id,
    r.matiere_code,
    r.cycle,
    r.domaine,
    r.libelle,
    r.source,
    r.critere_de_reussite <> '' as a_un_critere,
    cardinality(r.erreurs_types) > 0 as a_des_erreurs_types,
    r.domaine_evaluation_id is not null as rattache_a_un_domaine
  from reperes_competences r
  where r.actif;
