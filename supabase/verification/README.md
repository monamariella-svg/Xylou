# Vérifier les migrations avant de les appliquer

Un PostgreSQL jetable, les 77 migrations dans l'ordre, et l'on sait si elles
passent — avant de toucher à la base de production.

    ./supabase/verification/executer.sh

Le script rend 0 si tout passe, autre chose sinon, et nomme la migration qui a
échoué. Rien n'est laissé derrière : le cluster est supprimé à la fin.

## `bouchons-supabase.sql`

Supabase fournit des schémas que PostgreSQL n'a pas : `auth`, `storage`,
`vault`, `net`, `cron`. Les migrations s'y réfèrent — `auth.uid()` dans chaque
politique RLS, `net.http_post` dans les sonnettes des files.

Ce fichier en pose des versions minimales, juste assez pour que le SQL
s'exécute. **Elles ne reproduisent pas le comportement de Supabase** : `auth.uid()`
rend toujours nul, `net.http_post` ne poste rien. On vérifie qu'une migration
s'applique, pas qu'une politique RLS protège — cela demanderait de vrais
utilisateurs et de vrais jetons.

## Ce que cette vérification a déjà attrapé

Un `revoke ... from public` qui retirait à `service_role` le droit d'appeler sa
propre fonction — la file d'envoi se serait vue refuser l'accès, en production
seulement. Et une jointure sur un libellé qui ne rapprochait rien : la migration
passait au vert avec un tiers du référentiel manquant.
