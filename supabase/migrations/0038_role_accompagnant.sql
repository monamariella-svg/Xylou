-- 0038 — La place de l'AESH.
--
-- 0001 posait trois rôles et s'en expliquait : « on ne multiplie pas les rôles
-- pour décrire des métiers, on multiplie les droits pour décrire des accès ». Le
-- raisonnement tenait pour un coordinateur ULIS, dont les droits sont bien ceux
-- d'un référent. Il ne tient pas pour une AESH.
--
-- Une AESH est auprès de l'enfant tous les jours. Elle a plus à dire sur sa
-- journée que quiconque, et elle doit pouvoir l'écrire. Mais elle n'arbitre pas
-- la trajectoire scolaire et n'a pas à lire un diagnostic : la ranger parmi les
-- référents lui donnerait `peut_valider()`, c'est-à-dire la validation des
-- objectifs, la décision sur les propositions de l'IA, et l'accès à
-- `enfants_sante`. Trois choses qui ne relèvent pas d'elle.
--
-- La ranger parmi les enseignants serait tout aussi faux : elle n'a pas de
-- matière, et 0036 exige qu'un enseignant en couvre au moins une.
--
-- D'où un quatrième rôle. Aucune politique existante ne le nomme, et c'est
-- exactement l'effet recherché : il hérite de ce que `est_intervenant()` accorde
-- — voir les objectifs, les missions, le projet moteur, ce qui permet
-- d'accompagner — et de rien de ce que `peut_valider()` réserve.
--
-- Ce que cela lui donne, sans qu'aucune ligne n'ait à le prévoir :
--
--   ✓ la fiche de l'enfant, son projet moteur, ses centres d'intérêt
--   ✓ les objectifs et leur avancement, les missions, les supports
--   ✓ le suivi quotidien (0039), où elle a le plus à apporter
--   ✗ le diagnostic et les aménagements  (peut_valider)
--   ✗ la validation des objectifs         (quorum, 0023)
--   ✗ les copies et les tentatives        (filiation enseignante, 0033)
--   ✗ les fils restreints                 (participation explicite, 0014)
--
-- Le fichier ne fait que déclarer la valeur. Elle ne peut pas être utilisée dans
-- la même transaction que son ajout — d'où une migration à elle seule, et le
-- suivi quotidien dans la suivante.

alter type role_intervenant add value if not exists 'accompagnant';

comment on type role_intervenant is
  'parent, referent, enseignant, accompagnant. Le rôle décrit un périmètre d''accès, pas un métier : la fonction exacte (AESH, AVS, éducateur, coordinatrice ULIS) se renseigne en clair dans intervenants_enfant.fonction.';
