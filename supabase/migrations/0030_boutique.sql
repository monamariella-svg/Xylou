-- 0030 — La boutique.
--
-- `recompenses` existait depuis 0002 : un libellé, un coût, une image, rattachés
-- au projet moteur. C'était une liste, pas une boutique. Trois manques :
--
--   1. Rien n'empêchait d'acquérir une récompense sans avoir les points. La vue
--      `points_enfant` calculait un solde que personne ne vérifiait — un enfant
--      qui s'en aperçoit cesse de jouer le jeu, et le ressort du dispositif
--      tombe avec.
--   2. Aucune catégorie, donc aucune façon d'organiser un catalogue qui grandit.
--   3. Aucune dépendance : offrir une tenue pour un personnage qu'on ne possède
--      pas n'a pas de sens.
--
-- Tout ici est virtuel et propre à l'univers de l'enfant. Pour Xylan et le jeu
-- vidéo : des personnages à modéliser, des tenues, des accessoires, des
-- véhicules, des décors. Pour un enfant passionné de trains, ce seront des
-- locomotives et des gares — les catégories sont assez larges pour les deux, et
-- c'est le `libelle` qui porte l'univers.
--
-- Ce qui s'achète ne doit jamais être un privilège scolaire : ni un exercice en
-- moins, ni une note. C'est pourquoi les points et les notes vivent dans des
-- tables séparées depuis 0013, et pourquoi la boutique ne touche à rien d'autre
-- qu'à elle-même.

create type categorie_recompense as enum (
  'personnage',
  'tenue',
  'accessoire',
  'vehicule',
  'decor',
  'capacite',
  'autre'
);

alter table recompenses
  add column categorie categorie_recompense not null default 'autre',
  -- Retirer un article du catalogue sans effacer ce que les enfants ont déjà
  -- acquis : `recompenses_obtenues` pointe dessus, et un enfant ne se fait pas
  -- reprendre ce qu'il a gagné.
  add column disponible boolean not null default true,
  -- Une tenue suppose le personnage qui la porte.
  add column requiert_id uuid references recompenses on delete set null,
  -- Un décor s'acquiert une fois ; un consommable, non. Par défaut, une fois.
  add column unique_par_enfant boolean not null default true;

create index recompenses_catalogue_idx
  on recompenses (projet_moteur_id, categorie, ordre)
  where disponible;

-- Un article ne peut pas se requérir lui-même, ni dépendre d'un article d'un
-- autre univers : on n'achète pas une tenue de jeu vidéo pour une locomotive.
create or replace function verifier_le_prerequis_de_recompense()
returns trigger language plpgsql as $$
declare
  v_projet uuid;
begin
  if new.requiert_id is null then
    return new;
  end if;

  if new.requiert_id = new.id then
    raise exception 'Un article ne peut pas dépendre de lui-même.';
  end if;

  select projet_moteur_id into v_projet from recompenses where id = new.requiert_id;

  if v_projet is distinct from new.projet_moteur_id then
    raise exception 'Le prérequis doit appartenir au même projet moteur.';
  end if;

  return new;
end;
$$;

create trigger recompenses_verifient_leur_prerequis
  before insert or update on recompenses
  for each row execute function verifier_le_prerequis_de_recompense();

-- ------------------------------------------------------------- l'acquisition

-- Un adulte peut offrir un article hors solde. Ce n'est pas une entorse au jeu,
-- c'est un geste qu'un parent doit pouvoir faire : un enfant qui vient de passer
-- trois semaines sur un blocage a mérité quelque chose que le compteur ne dit
-- pas. La colonne le distingue d'un achat, et la vue ne le compte pas comme une
-- dépense — sinon offrir appauvrirait l'enfant.
alter table recompenses_obtenues
  add column offerte boolean not null default false,
  add column offerte_par uuid references profils on delete set null,
  add column points_payes integer not null default 0 check (points_payes >= 0);

alter table recompenses_obtenues
  add constraint offre_a_un_auteur
  check ((offerte = false) = (offerte_par is null));

-- Le verrou du solde. En trigger plutôt qu'en fonction d'achat : une fonction
-- ne protège que ceux qui l'appellent, et il resterait une politique d'insertion
-- directe par laquelle tout passerait.
--
-- Le `for update` sur la ligne de l'enfant sérialise les acquisitions. Sans lui,
-- deux achats simultanés liraient le même solde et passeraient tous les deux —
-- c'est le scénario classique, et il est facile à provoquer en double-cliquant.
create or replace function verifier_l_acquisition()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_recompense recompenses%rowtype;
  v_solde integer;
begin
  perform 1 from enfants where id = new.enfant_id for update;

  select * into v_recompense from recompenses where id = new.recompense_id;

  if not v_recompense.disponible and not new.offerte then
    raise exception 'Cet article n''est plus au catalogue.';
  end if;

  if v_recompense.unique_par_enfant and exists (
    select 1 from recompenses_obtenues o
    where o.enfant_id = new.enfant_id
      and o.recompense_id = new.recompense_id
      and o.id is distinct from new.id
  ) then
    raise exception 'Cet article a déjà été acquis.';
  end if;

  if v_recompense.requiert_id is not null and not exists (
    select 1 from recompenses_obtenues o
    where o.enfant_id = new.enfant_id and o.recompense_id = v_recompense.requiert_id
  ) then
    raise exception 'Il faut d''abord posséder l''article dont celui-ci dépend.';
  end if;

  if new.offerte then
    new.points_payes := 0;
    return new;
  end if;

  select solde into v_solde from points_enfant where enfant_id = new.enfant_id;

  if coalesce(v_solde, 0) < v_recompense.cout_points then
    raise exception 'Points insuffisants : % disponible(s), % nécessaire(s).',
      coalesce(v_solde, 0), v_recompense.cout_points;
  end if;

  -- Le prix est figé à l'acquisition. Si le catalogue change demain, ce que
  -- l'enfant a payé hier ne bouge pas — et son solde reste calculable.
  new.points_payes := v_recompense.cout_points;
  return new;
end;
$$;

create trigger recompenses_obtenues_verifient_l_acquisition
  before insert on recompenses_obtenues
  for each row execute function verifier_l_acquisition();

-- ------------------------------------------------------------------ le solde

-- La vue de 0006 recalculait la dépense en rejoignant le catalogue, donc un
-- changement de prix réécrivait l'histoire : baisser le coût d'un article
-- rendait des points à tous ceux qui l'avaient déjà acheté. On lit désormais
-- `points_payes`, figé à l'acquisition, et les cadeaux ne coûtent rien.
create or replace view points_enfant
with (security_invoker = true) as
  select
    e.id as enfant_id,
    coalesce(gagnes.total, 0) as points_gagnes,
    coalesce(depenses.total, 0) as points_depenses,
    coalesce(gagnes.total, 0) - coalesce(depenses.total, 0) as solde
  from enfants e
  left join (
    select m.enfant_id, sum(m.points)::integer as total
    from missions m
    where m.statut = 'reussie'
    group by m.enfant_id
  ) gagnes on gagnes.enfant_id = e.id
  left join (
    select ro.enfant_id, sum(ro.points_payes)::integer as total
    from recompenses_obtenues ro
    where not ro.offerte
    group by ro.enfant_id
  ) depenses on depenses.enfant_id = e.id;

-- ==================================================================== RLS

-- Le catalogue se compose par la famille et le référent — ce sont eux qui
-- connaissent l'univers de l'enfant. Les politiques de 0009 sur `recompenses`
-- le prévoient déjà et n'ont pas à changer.

-- Offrir est réservé au cercle qui valide ; acheter aussi, tant que l'enfant
-- n'a pas de compte à lui et travaille depuis la session d'un parent. Le jour
-- où il en aura un, c'est cette politique qu'il faudra rouvrir — et elle seule.
drop policy recompenses_obtenues_ecriture on recompenses_obtenues;

create policy recompenses_obtenues_acquisition on recompenses_obtenues
  for insert to authenticated
  with check (
    peut_valider(enfant_id)
    and (offerte = false or offerte_par = auth.uid())
  );

-- Aucune politique de mise à jour ni de suppression : ce qu'un enfant a acquis
-- lui reste. Retirer un article gagné pour sanctionner un comportement
-- retournerait le dispositif contre ce qu'il cherche à construire.
