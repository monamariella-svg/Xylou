-- 0067 — Dire quels types de notification quittent l'application.
--
-- 0059 a posé `preferences_notification` et le défaut qui va avec : l'absence
-- de préférence vaut accord, sinon personne ne recevrait rien tant qu'il n'a
-- pas visité un écran de réglages qu'il n'a aucune raison d'ouvrir. Le pied de
-- page de chaque courriel annonce depuis lors que « vous pouvez choisir ce qui
-- vous est notifié depuis votre compte ». L'écran n'existait pas.
--
-- Il n'a de sens que pour les types qui sortent réellement — proposer de couper
-- le courriel d'un mouvement de récompense, qui n'en envoie aucun, ferait
-- croire à un réglage qui n'agit sur rien. `type_notifie_hors_application()`
-- détient cette liste depuis 0059, mais type par type : on peut l'interroger
-- sur un type, pas lui demander lesquels.
--
-- La recopier dans l'interface serait la condamner à diverger. Le jour où un
-- type s'ajoutera à la fonction, l'écran continuerait d'afficher l'ancienne
-- liste : un courriel partirait sans que rien ne permette de l'arrêter, et
-- c'est exactement la panne qu'un écran de préférences ne peut pas avoir.

create or replace function types_notifies_hors_application()
returns setof type_notification
language sql
stable
as $$
  -- `enum_range` énumère le type Postgres lui-même : la liste suit les
  -- `alter type … add value` à venir sans qu'on ait à y repenser.
  select t
  from unnest(enum_range(null::type_notification)) as t
  where type_notifie_hors_application(t)
  order by t;
$$;
