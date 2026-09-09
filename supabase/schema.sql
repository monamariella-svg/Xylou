-- 
-- Le schéma de Xylou, tel que les migrations le produisent.
-- 
-- CE FICHIER NE FAIT PAS FOI. Les migrations numérotées le font. Celui-ci en est
-- une photographie, régénérée par :
-- 
--   ./supabase/verification/executer.sh --schema
-- 
-- Ne le modifiez jamais à la main : la prochaine régénération effacerait la
-- correction, et la base réelle ne l'aurait jamais eue.
-- 
-- CE QU'IL NE CONTIENT PAS
-- 
-- Aucune donnée. Ni les 55 attendus officiels de mathématiques, ni les 45
-- questions de l'évaluation nationale, ni le questionnaire du pré-bilan — tout
-- cela vit dans les migrations 0070 et 0075 à 0076.
-- 
-- Recréer une base à partir de ce seul fichier donnerait donc un schéma correct
-- et un référentiel vide.
-- 
--
-- PostgreSQL database dump
--


-- Dumped from database version 16.13 (Ubuntu 16.13-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.13 (Ubuntu 16.13-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: canal_envoi; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.canal_envoi AS ENUM (
    'courriel',
    'push'
);


--
-- Name: categorie_recompense; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.categorie_recompense AS ENUM (
    'personnage',
    'tenue',
    'accessoire',
    'vehicule',
    'decor',
    'capacite',
    'autre'
);


--
-- Name: cycle_scolaire; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.cycle_scolaire AS ENUM (
    'cycle2',
    'cycle3',
    'cycle4',
    'lycee'
);


--
-- Name: direction_item; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.direction_item AS ENUM (
    'capacity',
    'difficulty',
    'need',
    'descriptive'
);


--
-- Name: forme_adaptation; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.forme_adaptation AS ENUM (
    'visuelle',
    'mission'
);


--
-- Name: granularite_objectif; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.granularite_objectif AS ENUM (
    'large',
    'fin'
);


--
-- Name: horizon_recompense; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.horizon_recompense AS ENUM (
    'imminent',
    'court_terme',
    'moyen_terme',
    'long_terme'
);


--
-- Name: humeur_jour; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.humeur_jour AS ENUM (
    'tres_bonne',
    'bonne',
    'moyenne',
    'difficile',
    'tres_difficile'
);


--
-- Name: maitrise; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.maitrise AS ENUM (
    'non_evaluee',
    'a_travailler',
    'en_cours',
    'acquise',
    'point_fort'
);


--
-- Name: nature_acces; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.nature_acces AS ENUM (
    'litige',
    'requisition',
    'demande_famille',
    'demande_equipe'
);


--
-- Name: nature_periode; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.nature_periode AS ENUM (
    'ordinaire',
    'sejour',
    'evenement',
    'vacances',
    'transition'
);


--
-- Name: nature_travail; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.nature_travail AS ENUM (
    'entrainement',
    'evaluation',
    'devoir'
);


--
-- Name: TYPE nature_travail; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TYPE public.nature_travail IS 'entrainement : libre et répétable. evaluation : composée et notée par l''enseignant. devoir : donné par l''école, saisi par l''enseignant ou par la famille. Les trois comptent pour l''objectif auquel ils se rattachent.';


--
-- Name: niveau_classe; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.niveau_classe AS ENUM (
    'cp',
    'ce1',
    'ce2',
    'cm1',
    'cm2',
    '6e',
    '5e',
    '4e',
    '3e',
    '2nde',
    '1ere',
    'terminale'
);


--
-- Name: operation_ia; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.operation_ia AS ENUM (
    'bilan_questions',
    'bilan_evaluation',
    'bilan_synthese',
    'adaptation_visuelle',
    'adaptation_mission',
    'generation_mission',
    'generation_exercices',
    'bilan_trimestriel',
    'interaction_courte'
);


--
-- Name: origine_contenu; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.origine_contenu AS ENUM (
    'enseignant',
    'parent',
    'referent',
    'ia'
);


--
-- Name: plateforme_appareil; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.plateforme_appareil AS ENUM (
    'ios',
    'android',
    'web'
);


--
-- Name: portee_fil; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.portee_fil AS ENUM (
    'restreint',
    'equipe'
);


--
-- Name: profil_communication; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.profil_communication AS ENUM (
    'verbal',
    'non_verbal',
    'mixte'
);


--
-- Name: role_intervenant; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.role_intervenant AS ENUM (
    'parent',
    'referent',
    'enseignant',
    'accompagnant'
);


--
-- Name: TYPE role_intervenant; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TYPE public.role_intervenant IS 'parent, referent, enseignant, accompagnant. Le rôle décrit un périmètre d''accès, pas un métier : la fonction exacte (AESH, AVS, éducateur, coordinatrice ULIS) se renseigne en clair dans intervenants_enfant.fonction.';


--
-- Name: role_plateforme; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.role_plateforme AS ENUM (
    'membre',
    'referent',
    'admin'
);


--
-- Name: source_pieces; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.source_pieces AS ENUM (
    'exercice',
    'bonus_note',
    'mission',
    'cadeau'
);


--
-- Name: source_repere; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.source_repere AS ENUM (
    'eduscol',
    'amorce',
    'local'
);


--
-- Name: statut_adaptation; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statut_adaptation AS ENUM (
    'brouillon',
    'validee',
    'rejetee'
);


--
-- Name: statut_alerte; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statut_alerte AS ENUM (
    'ouverte',
    'traitee',
    'ecartee'
);


--
-- Name: statut_bilan; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statut_bilan AS ENUM (
    'en_cours',
    'complete',
    'valide',
    'abandonne'
);


--
-- Name: statut_bilan_trimestriel; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statut_bilan_trimestriel AS ENUM (
    'brouillon',
    'valide'
);


--
-- Name: statut_demande; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statut_demande AS ENUM (
    'ouverte',
    'acceptee',
    'refusee',
    'retiree'
);


--
-- Name: statut_envoi; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statut_envoi AS ENUM (
    'a_envoyer',
    'envoye',
    'echec',
    'abandonne'
);


--
-- Name: statut_generation; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statut_generation AS ENUM (
    'en_attente',
    'en_cours',
    'terminee',
    'echec',
    'annulee'
);


--
-- Name: statut_habilitation; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statut_habilitation AS ENUM (
    'en_attente',
    'acceptee',
    'refusee',
    'retiree'
);


--
-- Name: statut_mission; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statut_mission AS ENUM (
    'proposee',
    'validee',
    'en_cours',
    'reussie',
    'abandonnee'
);


--
-- Name: statut_modele; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statut_modele AS ENUM (
    'propose',
    'valide',
    'retire'
);


--
-- Name: statut_objectif; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statut_objectif AS ENUM (
    'propose',
    'valide',
    'atteint',
    'abandonne'
);


--
-- Name: statut_quete; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statut_quete AS ENUM (
    'en_cours',
    'reussie',
    'close'
);


--
-- Name: statut_recompense_familiale; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statut_recompense_familiale AS ENUM (
    'promise',
    'atteinte',
    'reportee',
    'annulee'
);


--
-- Name: statut_support; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statut_support AS ENUM (
    'depose',
    'en_traitement',
    'adapte',
    'echec'
);


--
-- Name: statut_suppression; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.statut_suppression AS ENUM (
    'en_attente',
    'accordee',
    'masquee',
    'purgee',
    'annulee'
);


--
-- Name: type_action_alerte; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.type_action_alerte AS ENUM (
    'reprise_en_amont',
    'changement_de_support',
    'allegement',
    'exercices_supplementaires',
    'changement_de_projet_moteur',
    'mise_en_pause',
    'orientation_exterieure',
    'autre'
);


--
-- Name: type_consentement; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.type_consentement AS ENUM (
    'traitement_donnees_sante',
    'generation_ia',
    'partage_equipe_pedagogique',
    'conservation_historique'
);


--
-- Name: type_entree; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.type_entree AS ENUM (
    'nuit',
    'sante',
    'periode_difficile',
    'attendus_devoir',
    'contenu_cours',
    'comportement',
    'encouragement',
    'organisation',
    'autre'
);


--
-- Name: type_jour; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.type_jour AS ENUM (
    'ecole',
    'maison',
    'week_end',
    'vacances',
    'absence',
    'soin'
);


--
-- Name: type_media; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.type_media AS ENUM (
    'photo',
    'video',
    'audio'
);


--
-- Name: type_notification; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.type_notification AS ENUM (
    'message',
    'objectif_propose',
    'objectif_modification_demandee',
    'objectif_valide',
    'mission_a_valider',
    'examen_rendu',
    'difficulte_repetee',
    'bilan_pret',
    'invitation',
    'acces_exceptionnel',
    'recompense_approche',
    'recompense_atteinte',
    'badge_obtenu',
    'quete_reussie',
    'habilitation_demandee',
    'habilitation_traitee'
);


--
-- Name: type_piece_acces; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.type_piece_acces AS ENUM (
    'requisition',
    'courrier_autorite_parentale',
    'autre'
);


--
-- Name: type_piece_habilitation; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.type_piece_habilitation AS ENUM (
    'piece_identite',
    'carte_professionnelle',
    'attestation_employeur',
    'attestation_direction',
    'diplome',
    'agrement',
    'assurance_responsabilite',
    'autre'
);


--
-- Name: type_repere_jour; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.type_repere_jour AS ENUM (
    'bruit',
    'calme',
    'plan_b',
    'attention',
    'repere'
);


--
-- Name: type_reponse; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.type_reponse AS ENUM (
    'qcm',
    'texte',
    'numerique',
    'association',
    'ordre',
    'oui_non'
);


--
-- Name: type_support; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.type_support AS ENUM (
    'cours',
    'devoir',
    'evaluation',
    'autre'
);


--
-- Name: univers_moteur; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.univers_moteur AS ENUM (
    'jeu_video',
    'dessin_anime',
    'livre',
    'animaux',
    'transports',
    'espace',
    'sport',
    'musique',
    'autre'
);


--
-- Name: verdict_ia; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.verdict_ia AS ENUM (
    'pertinente',
    'a_ajuster',
    'inadaptee'
);


--
-- Name: accepter_l_habilitation(uuid, date, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accepter_l_habilitation(p_demande uuid, p_valable_jusqu_au date DEFAULT NULL::date, p_motif text DEFAULT ''::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_profil uuid;
  v_pieces integer;
  v_manquantes type_piece_habilitation[];
begin
  if not est_admin() then
    raise exception 'L''instruction des demandes revient à l''administration.';
  end if;

  select profil_id into v_profil
  from demandes_habilitation
  where id = p_demande and statut = 'en_attente';

  if v_profil is null then
    raise exception 'Demande introuvable ou déjà instruite.';
  end if;

  -- Le verrou de production. Vide pendant le pilote, donc sans effet — mais
  -- présent, et donc impossible à oublier le jour où on le remplit.
  v_manquantes := pieces_manquantes(p_demande);

  if array_length(v_manquantes, 1) > 0 then
    raise exception 'Cette demande ne peut pas être accordée : il manque % (ou la pièce fournie est périmée).',
      array_to_string(v_manquantes, ', ');
  end if;

  -- Sans exigence formelle, accorder sans rien lire reste possible — mais se
  -- dit. Le jour où quelqu'un demandera sur quoi cette habilitation reposait,
  -- « je la connais, elle coordonne l'ULIS du collège X » est une réponse
  -- recevable, à condition d'avoir été écrite ce jour-là.
  select count(*) into v_pieces from habilitation_pieces where demande_id = p_demande;

  if v_pieces = 0 and length(btrim(p_motif)) < 10 then
    raise exception 'Aucune pièce justificative n''a été versée. Vous pouvez accorder l''habilitation malgré tout, mais dites sur quoi vous vous fondez.';
  end if;

  update demandes_habilitation
    set statut = 'acceptee', traitee_par = auth.uid(), traitee_le = now(),
        motif = btrim(p_motif), valable_jusqu_au = p_valable_jusqu_au
    where id = p_demande;

  update profils set role_plateforme = 'referent' where id = v_profil;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  values (v_profil, null, 'habilitation_traitee',
          'Votre habilitation de référent est accordée',
          'Vous pouvez désormais ouvrir des dossiers.',
          '/tableau-de-bord');
end;
$$;


--
-- Name: accepter_l_invitation(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accepter_l_invitation(p_jeton text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_inv invitations%rowtype;
  v_intervenant uuid;
begin
  select * into v_inv
  from invitations
  where jeton = p_jeton
    and acceptee_le is null
    and annulee_le is null
    and expire_le > now();

  if not found then
    raise exception 'Invitation introuvable, déjà acceptée, annulée ou expirée.';
  end if;

  if lower(v_inv.email) <> email_courant() then
    raise exception 'Cette invitation a été adressée à une autre adresse que celle de votre compte.';
  end if;

  insert into intervenants_enfant
    (enfant_id, profil_id, role, fonction, matiere_code, toutes_matieres, invite_par)
  values
    (v_inv.enfant_id, auth.uid(), v_inv.role, v_inv.fonction,
     v_inv.matiere_code, v_inv.toutes_matieres, v_inv.invite_par)
  on conflict (enfant_id, profil_id) do nothing
  returning id into v_intervenant;

  if v_intervenant is not null then
    insert into intervenants_matieres (intervenant_id, matiere_code)
    select v_intervenant, unnest(v_inv.matieres)
    on conflict do nothing;
  end if;

  update invitations set acceptee_le = now() where id = v_inv.id;

  return v_inv.enfant_id;
end;
$$;


--
-- Name: acces_a_l_alerte(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.acces_a_l_alerte(p_alerte uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from alertes_difficulte a
    where a.id = p_alerte
      and (
        peut_valider(a.enfant_id)
        or (a.repere_id is not null and exists (
              select 1 from reperes_competences r
              where r.id = a.repere_id
                and matiere_ouverte_a_l_ecriture(a.enfant_id, r.matiere_code)))
        or (a.objectif_id is not null and pilote_l_objectif(a.objectif_id))
      )
  );
$$;


--
-- Name: acces_au_fil(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.acces_au_fil(p_fil uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1
    from fils f
    join enfants e on e.id = f.enfant_id
    where f.id = p_fil
      and e.archive_le is null
      and (
        (f.portee = 'equipe' and est_intervenant(f.enfant_id))
        or exists (
          select 1 from fils_participants p
          where p.fil_id = f.id and p.profil_id = auth.uid()
        )
      )
  );
$$;


--
-- Name: acces_au_message(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.acces_au_message(p_message uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from messages m where m.id = p_message and acces_au_fil(m.fil_id)
  );
$$;


--
-- Name: acces_du_chemin(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.acces_du_chemin(p_name text) RETURNS uuid
    LANGUAGE sql IMMUTABLE
    AS $$
  select uuid_ou_null((storage.foldername(p_name))[1]);
$$;


--
-- Name: acces_exceptionnel_actif(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.acces_exceptionnel_actif(p_enfant uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from acces_exceptionnels a
    where a.enfant_id = p_enfant
      and a.ouvert_par = auth.uid()
      and a.clos_le is null
      and a.expire_le > now()
      and pieces_suffisantes(a.id)
  );
$$;


--
-- Name: accompagne_un_enfant(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accompagne_un_enfant() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from intervenants_enfant i
    where i.profil_id = auth.uid() and i.retire_le is null
  );
$$;


--
-- Name: accorder_la_suppression(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accorder_la_suppression(p_demande uuid, p_signature text) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_enfant uuid;
  v_manquants integer;
begin
  select enfant_id into v_enfant from demandes_suppression
  where id = p_demande and statut = 'en_attente';

  if v_enfant is null then
    raise exception 'Demande introuvable, déjà accordée ou annulée.';
  end if;

  if not est_intervenant(v_enfant, array['parent']::role_intervenant[]) then
    raise exception 'Seuls les titulaires de l''autorité parentale accordent la suppression.';
  end if;

  insert into suppressions_accords (demande_id, profil_id, signature_nom)
  values (p_demande, auth.uid(), btrim(p_signature))
  on conflict do nothing;

  -- Tous les titulaires rattachés, sans exception. La composition déclarée sert
  -- ici comme pour le quorum de 0023 : si un second titulaire est annoncé mais
  -- n'a jamais rejoint, rien ne s'efface — et c'est voulu.
  select count(*) into v_manquants
  from intervenants_enfant i
  where i.enfant_id = v_enfant and i.role = 'parent' and i.retire_le is null
    and not exists (
      select 1 from suppressions_accords a
      where a.demande_id = p_demande and a.profil_id = i.profil_id
    );

  if v_manquants > 0 or not composition_parentale_complete(v_enfant) then
    return false;
  end if;

  update demandes_suppression set statut = 'accordee' where id = p_demande;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select p.id, v_enfant, 'message',
         'Suppression de dossier accordée',
         'Tous les titulaires ont donné leur accord. Le dossier peut être masqué.',
         '/administration/suppressions/' || p_demande
  from profils p where p.role_plateforme = 'admin';

  return true;
end;
$$;


--
-- Name: alerter_sur_echec_repete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.alerter_sur_echec_repete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_seuil constant smallint := 3;
  v_objectif uuid;
  v_repere uuid;
  v_matiere text;
  v_intitule text;
  v_lien text;
  v_echecs integer;
  v_alerte uuid;
begin
  if new.reussie then
    return new;
  end if;

  select m.objectif_id, coalesce(o.repere_id, mo.repere_id), o.libelle
    into v_objectif, v_repere, v_intitule
  from exercices e
  join missions m on m.id = e.mission_id
  left join objectifs o on o.id = m.objectif_id
  left join modeles_exercice mo on mo.id = e.modele_id
  where e.id = new.exercice_id;

  if v_repere is not null then
    select r.matiere_code, r.libelle into v_matiere, v_intitule
    from reperes_competences r where r.id = v_repere;

    v_echecs := echecs_consecutifs_repere(new.enfant_id, v_repere);
    v_lien := '/enfants/' || new.enfant_id || '/difficultes/repere/' || v_repere;
    v_objectif := null;

  elsif v_objectif is not null then
    if not exists (
      select 1 from objectifs o
      where o.id = v_objectif and o.granularite = 'fin'
    ) then
      return new;
    end if;

    v_echecs := echecs_consecutifs_objectif(new.enfant_id, v_objectif);
    v_lien := '/enfants/' || new.enfant_id || '/difficultes/objectif/' || v_objectif;

  else
    return new;
  end if;

  if v_echecs < v_seuil then
    return new;
  end if;

  select id into v_alerte
  from alertes_difficulte
  where enfant_id = new.enfant_id
    and statut = 'ouverte'
    and repere_id is not distinct from v_repere
    and objectif_id is not distinct from v_objectif;

  if v_alerte is not null then
    update alertes_difficulte
      set echecs_consecutifs = v_echecs, derniere_le = new.cree_le
      where id = v_alerte;
    return new;
  end if;

  insert into alertes_difficulte
    (enfant_id, repere_id, objectif_id, echecs_consecutifs, derniere_le)
  values
    (new.enfant_id, v_repere, v_objectif, v_echecs, new.cree_le);

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select
    i.profil_id, new.enfant_id, 'difficulte_repetee',
    'Blocage répété : ' || coalesce(v_intitule, 'compétence non précisée'),
    v_echecs || ' échecs d''affilée, sans réussite intercalée.',
    v_lien
  from intervenants_enfant i
  where i.enfant_id = new.enfant_id
    and i.retire_le is null
    and (
      i.role in ('parent', 'referent')
      or (v_matiere is not null and i.role = 'enseignant'
          and intervenant_couvre(i.id, v_matiere))
    );

  return new;
end;
$$;


--
-- Name: annee_scolaire_courante(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.annee_scolaire_courante() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select case
    when extract(month from now()) >= 8
      then extract(year from now())::int || '-' || (extract(year from now())::int + 1)
    else (extract(year from now())::int - 1) || '-' || extract(year from now())::int
  end;
$$;


--
-- Name: annonce_de_suppression(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.annonce_de_suppression() RETURNS TABLE(duree_texte text, duree interval, effacement_le date)
    LANGUAGE sql STABLE
    AS $$
  select
    case
      when duree_conservation() = interval '1 year' then 'un an'
      when extract(year from duree_conservation()) >= 1
        then extract(year from duree_conservation())::int || ' ans'
      else extract(month from duree_conservation())::int || ' mois'
    end,
    duree_conservation(),
    (now() + duree_conservation())::date;
$$;


--
-- Name: FUNCTION annonce_de_suppression(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.annonce_de_suppression() IS 'Ce que l''écran de confirmation annonce : la durée d''abord, la date ensuite. La date est indicative et se recalcule ; c''est la durée qui engage.';


--
-- Name: annoncer_l_acces_exceptionnel(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.annoncer_l_acces_exceptionnel() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  -- Le journal reçoit toujours l'ouverture, y compris pour une réquisition.
  -- Ce qui peut être différé, c'est l'information de la famille — pas la trace.
  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  values (
    new.enfant_id, new.ouvert_par, 'acces_exceptionnel_ouvert',
    'acces_exceptionnels', new.id,
    jsonb_build_object(
      'nature', new.nature,
      'motif', new.motif,
      'expire_le', new.expire_le,
      'reference', new.reference_litige,
      'autorite', new.autorite_requerante,
      'base_legale', new.base_legale
    )
  );

  -- Prévenir à l'ouverture, et non après coup, est ce qui distingue un accès
  -- d'exception d'une porte dérobée. La réquisition y échappe parce que le
  -- secret de l'enquête peut l'exiger — et l'information reste due, elle est
  -- seulement remise à plus tard.
  -- Seule la réquisition échappe à l'information immédiate. Une demande de la
  -- famille ou de l'équipe s'appuie précisément sur un accord parental écrit :
  -- la taire n'aurait aucun sens, et le second titulaire, en garde alternée,
  -- doit voir que son accord a été utilisé.
  if new.nature <> 'requisition' then
    perform informer_de_l_acces(new.id);
    update acces_exceptionnels set information_faite_le = now() where id = new.id;
  end if;

  return new;
end;
$$;


--
-- Name: annuler_la_suppression(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.annuler_la_suppression(p_demande uuid, p_motif text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_enfant uuid;
  v_statut statut_suppression;
begin
  select enfant_id, statut into v_enfant, v_statut
  from demandes_suppression where id = p_demande;

  if v_statut not in ('en_attente', 'accordee', 'masquee') then
    raise exception 'Demande introuvable ou déjà purgée.';
  end if;

  -- Un seul titulaire suffit à arrêter. Il faut l'unanimité pour effacer, une
  -- seule voix pour s'y opposer : l'asymétrie est le but.
  --
  -- Tant que la purge n'a pas eu lieu, le retour en arrière reste possible — et
  -- c'est tout l'intérêt des deux temps. Une famille qui se ravise trois mois
  -- plus tard retrouve son dossier intact.
  if not (est_admin() or est_intervenant(v_enfant, array['parent']::role_intervenant[])) then
    raise exception 'Seuls les titulaires de l''autorité parentale et l''administration peuvent arrêter une suppression.';
  end if;

  if v_statut = 'masquee' then
    if not est_admin() then
      raise exception 'Un dossier déjà masqué se rouvre par l''administration.';
    end if;
    perform desarchiver_le_dossier(v_enfant, btrim(p_motif));
    delete from suppressions_effectuees
      where enfant_id = v_enfant and purgee_le is null;
  end if;

  update demandes_suppression
    set statut = 'annulee', motif_annulation = btrim(p_motif)
    where id = p_demande;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select i.profil_id, v_enfant, 'message',
         'Suppression annulée', btrim(p_motif),
         '/enfants/' || v_enfant
  from intervenants_enfant i
  where i.enfant_id = v_enfant and i.retire_le is null
    and i.role in ('parent', 'referent')
    and i.profil_id <> auth.uid();
end;
$$;


--
-- Name: archiver_le_dossier(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.archiver_le_dossier(p_enfant uuid, p_motif text DEFAULT ''::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if not peut_valider(p_enfant) then
    raise exception 'Seuls les titulaires de l''autorité parentale et le référent archivent un dossier.';
  end if;

  if exists (select 1 from enfants where id = p_enfant and archive_le is not null) then
    raise exception 'Ce dossier est déjà archivé.';
  end if;

  perform set_config('xylou.archivage', 'en_cours', true);

  update enfants
    set archive_le = now(),
        archive_par = auth.uid(),
        motif_archivage = p_motif,
        purge_prevue_le = (now() + interval '5 years')::date
    where id = p_enfant;

  perform set_config('xylou.archivage', '', true);

  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  values (p_enfant, auth.uid(), 'dossier_archive', 'enfants', p_enfant,
          jsonb_build_object('motif', p_motif));
end;
$$;


--
-- Name: attribuer_le_badge(uuid, text, text, smallint, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.attribuer_le_badge(p_enfant uuid, p_matiere text DEFAULT NULL::text, p_domaine text DEFAULT NULL::text, p_trimestre smallint DEFAULT NULL::smallint, p_commentaire text DEFAULT ''::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_jauge record;
  v_annee uuid;
  v_badge uuid;
  v_manuel boolean;
  v_compte uuid;
begin
  if num_nonnulls(p_matiere, p_domaine) <> 1 then
    raise exception 'Un badge relève d''une matière ou d''un domaine, pas des deux.';
  end if;

  -- Le pilote du champ, comme partout ailleurs : l'enseignant de la matière, le
  -- référent pour le transversal. Un badge est un jugement sur le travail, il
  -- revient à celui qui l'a suivi.
  if not (
    (p_matiere is not null and matiere_ouverte_a_l_ecriture(p_enfant, p_matiere))
    or (p_domaine is not null and est_intervenant(p_enfant, array['referent']::role_intervenant[]))
  ) then
    raise exception 'Ce badge revient à l''enseignant de la matière, ou au référent pour un domaine transversal.';
  end if;

  select * into v_jauge from jauge_badge(p_enfant, p_matiere, p_domaine);

  if v_jauge.objectifs_total = 0 then
    raise exception 'Aucun objectif dans ce champ : il n''y a rien à récompenser encore.';
  end if;

  -- En dessous du seuil, le badge reste possible mais devient un geste assumé.
  -- « Bien progressé » n'est pas toujours un pourcentage : un enfant qui a
  -- franchi un blocage compte autant qu'un enfant qui a coché ses cases.
  v_manuel := v_jauge.progression < seuil_badge();

  if v_manuel and length(btrim(p_commentaire)) < 5 then
    raise exception 'Progression de % pour cent, seuil à %. Le badge reste attribuable, mais il se motive : dites en quoi l''enfant a progressé.',
      v_jauge.progression, seuil_badge();
  end if;

  select id into v_annee from annees_enfant
  where enfant_id = p_enfant and close_le is null;

  insert into badges_obtenus (
    enfant_id, matiere_code, domaine_code, niveau, annee_id, trimestre,
    objectifs_atteints, objectifs_total, progression,
    attribue_par, commentaire
  )
  values (
    p_enfant, p_matiere, p_domaine, (v_jauge.niveau_actuel + 1)::smallint,
    v_annee, p_trimestre,
    v_jauge.objectifs_atteints, v_jauge.objectifs_total, v_jauge.progression,
    case when v_manuel then auth.uid() else null end,
    btrim(p_commentaire)
  )
  returning id into v_badge;

  -- L'enfant est prévenu directement. C'est le moment que tout le dispositif
  -- vise, et il n'a pas à l'apprendre par un adulte qui y aurait pensé.
  select compte_id into v_compte from enfants where id = p_enfant;

  if v_compte is not null then
    insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
    values (
      v_compte, p_enfant, 'badge_obtenu',
      v_jauge.emoji || ' Badge ' || v_jauge.libelle || ' niveau ' || (v_jauge.niveau_actuel + 1),
      v_jauge.objectifs_atteints || ' objectifs atteints sur ' || v_jauge.objectifs_total || '.',
      '/mes-badges/' || v_badge
    );
  end if;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select i.profil_id, p_enfant, 'badge_obtenu',
         'Badge ' || v_jauge.libelle || ' niveau ' || (v_jauge.niveau_actuel + 1),
         '', '/enfants/' || p_enfant || '/badges/' || v_badge
  from intervenants_enfant i
  where i.enfant_id = p_enfant
    and i.retire_le is null
    and i.role in ('parent', 'referent')
    and i.profil_id <> auth.uid();

  return v_badge;
end;
$$;


--
-- Name: attribuer_le_bonus_de_note(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.attribuer_le_bonus_de_note() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_enfant uuid;
  v_ratio numeric;
  v_bonus integer;
begin
  if new.note is null or new.bareme is null or new.bareme = 0 then
    return new;
  end if;

  v_ratio := new.note / new.bareme;

  if v_ratio < 0.5 then
    return new;
  end if;

  v_bonus := ceil(10 * v_ratio)::integer;

  select enfant_id into v_enfant from missions where id = new.mission_id;

  insert into pieces_gagnees
    (enfant_id, source, mission_id, notation_id, pieces, motif, attribue_par)
  values (
    v_enfant, 'bonus_note', new.mission_id, new.id, v_bonus,
    'Bonus pour la note obtenue', new.note_par
  )
  on conflict do nothing;

  return new;
end;
$$;


--
-- Name: attribuer_les_pieces_de_l_exercice(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.attribuer_les_pieces_de_l_exercice() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_diff smallint;
  v_pieces integer;
  v_forcees integer;
begin
  if not new.reussie then
    return new;
  end if;

  select coalesce(e.difficulte, m.difficulte), e.pieces
    into v_diff, v_forcees
  from exercices e
  join missions m on m.id = e.mission_id
  where e.id = new.exercice_id;

  v_pieces := coalesce(v_forcees, pieces_pour(v_diff));

  if v_pieces = 0 then
    return new;
  end if;

  -- `on conflict do nothing` plutôt qu'un test préalable : deux tentatives
  -- réussies enregistrées au même instant passeraient toutes deux le test, et
  -- l'index unique est le seul arbitre fiable.
  insert into pieces_gagnees (enfant_id, source, exercice_id, pieces, motif)
  values (
    new.enfant_id, 'exercice', new.exercice_id, v_pieces,
    case
      when v_diff >= 4 then 'Exercice difficile réussi'
      when v_diff <= 2 then 'Exercice réussi'
      else 'Exercice réussi'
    end
  )
  on conflict do nothing;

  return new;
end;
$$;


--
-- Name: attribuer_les_pieces_de_la_mission(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.attribuer_les_pieces_de_la_mission() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if new.statut <> 'reussie' or old.statut = 'reussie' or new.points = 0 then
    return new;
  end if;

  insert into pieces_gagnees (enfant_id, source, mission_id, pieces, motif)
  values (new.enfant_id, 'mission', new.id, new.points, 'Mission terminée')
  on conflict do nothing;

  return new;
end;
$$;


--
-- Name: badges_de_l_annee(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.badges_de_l_annee(p_enfant uuid) RETURNS integer
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select count(*)::integer
  from badges_obtenus b
  join annees_enfant a on a.id = b.annee_id
  where b.enfant_id = p_enfant and a.close_le is null;
$$;


--
-- Name: changer_de_projet_moteur(uuid, text, public.univers_moteur, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.changer_de_projet_moteur(p_enfant uuid, p_titre text, p_univers public.univers_moteur DEFAULT 'autre'::public.univers_moteur, p_description text DEFAULT ''::text, p_lexique jsonb DEFAULT '{}'::jsonb) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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


--
-- Name: composition_parentale_complete(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.composition_parentale_complete(p_enfant uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select e.titulaires_autorite_parentale = (
    select count(*) from intervenants_enfant i
    where i.enfant_id = p_enfant
      and i.role = 'parent'
      and i.retire_le is null
  )
  from enfants e where e.id = p_enfant;
$$;


--
-- Name: conclure_la_quete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.conclure_la_quete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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


--
-- Name: conclure_la_validation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.conclure_la_validation() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if objectif_pleinement_valide(new.objectif_id) then
    update objectifs
      set statut = 'valide',
          valide_par = new.profil_id,
          valide_le = new.valide_le
      where id = new.objectif_id
        and statut = 'propose';
  end if;
  return new;
end;
$$;


--
-- Name: consentement_actif(uuid, public.type_consentement); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.consentement_actif(p_enfant uuid, p_type public.type_consentement) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select composition_parentale_complete(p_enfant)
     and not exists (
       select 1
       from intervenants_enfant i
       where i.enfant_id = p_enfant
         and i.role = 'parent'
         and i.retire_le is null
         and not exists (
           select 1 from consentements c
           where c.enfant_id = p_enfant
             and c.profil_id = i.profil_id
             and c.type = p_type
             and c.accorde
             and c.revoque_le is null
         )
     );
$$;


--
-- Name: consentement_du_chemin(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.consentement_du_chemin(p_name text) RETURNS uuid
    LANGUAGE sql IMMUTABLE
    AS $$
  select uuid_ou_null((storage.foldername(p_name))[1]);
$$;


--
-- Name: consentements_a_signer(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.consentements_a_signer(p_enfant uuid) RETURNS TABLE(texte_id uuid, type public.type_consentement, version text, titre text, contenu text, obligatoire boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select t.id, t.type, t.version, t.titre, t.contenu, t.obligatoire
  from textes_consentement t
  where t.retire_le is null
    and est_intervenant(p_enfant, array['parent']::role_intervenant[])
    and not exists (
      select 1 from consentements c
      where c.enfant_id = p_enfant
        and c.profil_id = auth.uid()
        and c.texte_id = t.id
        and c.revoque_le is null
    )
  order by t.obligatoire desc, t.type;
$$;


--
-- Name: creer_profil_a_l_inscription(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.creer_profil_a_l_inscription() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  insert into profils (id, email, prenom, nom)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'prenom', ''),
    coalesce(new.raw_user_meta_data ->> 'nom', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;


--
-- Name: cycle_de_la_classe(public.niveau_classe); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cycle_de_la_classe(p_classe public.niveau_classe) RETURNS public.cycle_scolaire
    LANGUAGE sql IMMUTABLE
    AS $$
  select case
    when p_classe in ('cp', 'ce1', 'ce2') then 'cycle2'
    when p_classe in ('cm1', 'cm2', '6e') then 'cycle3'
    when p_classe in ('5e', '4e', '3e') then 'cycle4'
    else 'lycee'
  end::cycle_scolaire;
$$;


--
-- Name: definit_l_autorite_parentale(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.definit_l_autorite_parentale(p_enfant uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    est_intervenant(p_enfant, array['referent']::role_intervenant[])
    or est_admin();
$$;


--
-- Name: demander_l_habilitation(text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.demander_l_habilitation(p_fonction text, p_organisation text DEFAULT ''::text, p_numero text DEFAULT ''::text, p_motivation text DEFAULT ''::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_demande uuid;
  v_role role_plateforme;
begin
  select role_plateforme into v_role from profils where id = auth.uid();

  if v_role in ('referent', 'admin') then
    raise exception 'Votre compte a déjà cette habilitation.';
  end if;

  if length(btrim(p_fonction)) < 3 then
    raise exception 'Indiquez votre fonction : c''est ce que l''administration lira en premier.';
  end if;

  insert into demandes_habilitation
    (profil_id, fonction, organisation, numero_professionnel, motivation)
  values
    (auth.uid(), btrim(p_fonction), btrim(p_organisation),
     btrim(p_numero), btrim(p_motivation))
  returning id into v_demande;

  -- Sans ce signal, une demande attendrait qu'un administrateur pense à
  -- regarder une file qu'il n'a aucune raison d'ouvrir.
  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select p.id, null, 'habilitation_demandee',
         'Demande de référent : ' || coalesce(nullif(btrim(p_organisation), ''), btrim(p_fonction)),
         btrim(p_fonction),
         '/administration/habilitations/' || v_demande
  from profils p where p.role_plateforme = 'admin';

  return v_demande;
end;
$$;


--
-- Name: demander_l_habilitation(text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.demander_l_habilitation(p_fonction text, p_organisation text DEFAULT ''::text, p_numero text DEFAULT ''::text, p_motivation text DEFAULT ''::text, p_directeur_nom text DEFAULT ''::text, p_directeur_contact text DEFAULT ''::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_demande uuid;
  v_role role_plateforme;
begin
  select role_plateforme into v_role from profils where id = auth.uid();

  if v_role in ('referent', 'admin') then
    raise exception 'Votre compte a déjà cette habilitation.';
  end if;

  if length(btrim(p_fonction)) < 3 then
    raise exception 'Indiquez votre fonction : c''est ce que l''administration lira en premier.';
  end if;

  if length(btrim(p_organisation)) < 2 then
    raise exception 'Indiquez l''établissement ou la structure où vous exercez.';
  end if;

  if length(btrim(p_directeur_nom)) < 2 then
    raise exception 'Indiquez le nom du directeur de l''établissement : c''est lui qui atteste de votre fonction.';
  end if;

  if length(btrim(p_directeur_contact)) < 5 then
    raise exception 'Indiquez comment joindre la direction — adresse électronique ou téléphone. Une attestation qu''on ne peut pas vérifier ne vaut que la confiance qu''on accorde à celui qui la présente.';
  end if;

  insert into demandes_habilitation
    (profil_id, fonction, organisation, numero_professionnel, motivation,
     directeur_nom, directeur_contact)
  values
    (auth.uid(), btrim(p_fonction), btrim(p_organisation),
     btrim(p_numero), btrim(p_motivation),
     btrim(p_directeur_nom), btrim(p_directeur_contact))
  returning id into v_demande;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select p.id, null, 'habilitation_demandee',
         'Demande de référent : ' || btrim(p_organisation),
         btrim(p_fonction) || ' — atteste : ' || btrim(p_directeur_nom),
         '/administration'
  from profils p where p.role_plateforme = 'admin';

  return v_demande;
end;
$$;


--
-- Name: demander_l_habilitation(text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.demander_l_habilitation(p_fonction text, p_organisation text DEFAULT ''::text, p_numero text DEFAULT ''::text, p_motivation text DEFAULT ''::text, p_directeur_nom text DEFAULT ''::text, p_directeur_contact text DEFAULT ''::text, p_etablissement_adresse text DEFAULT ''::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_demande uuid;
  v_role role_plateforme;
begin
  select role_plateforme into v_role from profils where id = auth.uid();

  if v_role in ('referent', 'admin') then
    raise exception 'Votre compte a déjà cette habilitation.';
  end if;

  if length(btrim(p_fonction)) < 3 then
    raise exception 'Indiquez votre fonction : c''est ce que l''administration lira en premier.';
  end if;

  if length(btrim(p_organisation)) < 2 then
    raise exception 'Indiquez l''établissement ou la structure où vous exercez.';
  end if;

  if length(btrim(p_etablissement_adresse)) < 5 then
    raise exception 'Indiquez l''adresse de l''établissement : son nom seul ne l''identifie pas, et l''administration doit pouvoir le retrouver.';
  end if;

  if length(btrim(p_directeur_nom)) < 2 then
    raise exception 'Indiquez le nom du directeur de l''établissement : c''est lui qui atteste de votre fonction.';
  end if;

  if length(btrim(p_directeur_contact)) < 5 then
    raise exception 'Indiquez comment joindre la direction — adresse électronique ou téléphone. Une attestation qu''on ne peut pas vérifier ne vaut que la confiance qu''on accorde à celui qui la présente.';
  end if;

  insert into demandes_habilitation
    (profil_id, fonction, organisation, etablissement_adresse, numero_professionnel,
     motivation, directeur_nom, directeur_contact)
  values
    (auth.uid(), btrim(p_fonction), btrim(p_organisation), btrim(p_etablissement_adresse),
     btrim(p_numero), btrim(p_motivation),
     btrim(p_directeur_nom), btrim(p_directeur_contact))
  returning id into v_demande;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select p.id, null, 'habilitation_demandee',
         'Demande de référent : ' || btrim(p_organisation),
         btrim(p_fonction) || ' — atteste : ' || btrim(p_directeur_nom),
         '/administration'
  from profils p where p.role_plateforme = 'admin';

  return v_demande;
end;
$$;


--
-- Name: demander_l_habilitation(text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.demander_l_habilitation(p_fonction text, p_organisation text DEFAULT ''::text, p_numero text DEFAULT ''::text, p_motivation text DEFAULT ''::text, p_directeur_nom text DEFAULT ''::text, p_directeur_contact text DEFAULT ''::text, p_etablissement_adresse text DEFAULT ''::text, p_uai text DEFAULT ''::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $_$
declare
  v_demande uuid;
  v_role role_plateforme;
  v_uai text := upper(btrim(coalesce(p_uai, '')));
begin
  select role_plateforme into v_role from profils where id = auth.uid();

  if v_role in ('referent', 'admin') then
    raise exception 'Votre compte a déjà cette habilitation.';
  end if;

  if length(btrim(p_fonction)) < 3 then
    raise exception 'Indiquez votre fonction : c''est ce que l''administration lira en premier.';
  end if;

  if length(btrim(p_organisation)) < 2 then
    raise exception 'Indiquez l''établissement ou la structure où vous exercez.';
  end if;

  if v_uai <> '' and v_uai !~ '^[0-9]{7}[A-Z]$' then
    raise exception 'Le code UAI se compose de sept chiffres suivis d''une lettre, par exemple 0123456A. Laissez-le vide si votre structure n''en a pas.';
  end if;

  if length(btrim(p_etablissement_adresse)) < 5 then
    raise exception 'Indiquez l''adresse de l''établissement : son nom seul ne l''identifie pas, et l''administration doit pouvoir le retrouver.';
  end if;

  if length(btrim(p_directeur_nom)) < 2 then
    raise exception 'Indiquez le nom du directeur de l''établissement : c''est lui qui atteste de votre fonction.';
  end if;

  if length(btrim(p_directeur_contact)) < 5 then
    raise exception 'Indiquez comment joindre la direction — adresse électronique ou téléphone. Une attestation qu''on ne peut pas vérifier ne vaut que la confiance qu''on accorde à celui qui la présente.';
  end if;

  insert into demandes_habilitation
    (profil_id, fonction, organisation, uai, etablissement_adresse,
     numero_professionnel, motivation, directeur_nom, directeur_contact)
  values
    (auth.uid(), btrim(p_fonction), btrim(p_organisation), v_uai,
     btrim(p_etablissement_adresse), btrim(p_numero), btrim(p_motivation),
     btrim(p_directeur_nom), btrim(p_directeur_contact))
  returning id into v_demande;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select p.id, null, 'habilitation_demandee',
         'Demande de référent : ' || btrim(p_organisation),
         btrim(p_fonction) || ' — atteste : ' || btrim(p_directeur_nom),
         '/administration'
  from profils p where p.role_plateforme = 'admin';

  return v_demande;
end;
$_$;


--
-- Name: demander_la_suppression(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.demander_la_suppression(p_enfant uuid, p_motif text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_demande uuid;
begin
  if not (est_admin() or est_intervenant(p_enfant, array['parent']::role_intervenant[])) then
    raise exception 'La suppression d''un dossier se demande par un titulaire de l''autorité parentale, ou par l''administration.';
  end if;

  if length(btrim(p_motif)) < 15 then
    raise exception 'Dites pourquoi ce dossier doit être supprimé : c''est ce que les titulaires liront avant de donner leur accord.';
  end if;

  insert into demandes_suppression (enfant_id, demandee_par, motif)
  values (p_enfant, auth.uid(), btrim(p_motif))
  returning id into v_demande;

  -- Tous les titulaires sont prévenus, y compris le demandeur s'il en est un :
  -- il doit signer comme les autres, et le voir dans sa liste évite qu'il
  -- attende un accord qui n'attend que lui.
  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select i.profil_id, p_enfant, 'message',
         'Demande de suppression du dossier',
         btrim(p_motif),
         '/enfants/' || p_enfant || '/suppression/' || v_demande
  from intervenants_enfant i
  where i.enfant_id = p_enfant and i.retire_le is null
    and i.role in ('parent', 'referent');

  return v_demande;
end;
$$;


--
-- Name: desarchiver_le_dossier(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.desarchiver_le_dossier(p_enfant uuid, p_motif text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if not est_admin() then
    raise exception 'Le désarchivage est un geste administratif.';
  end if;

  if length(btrim(p_motif)) < 10 then
    raise exception 'Le désarchivage se motive.';
  end if;

  perform set_config('xylou.archivage', 'en_cours', true);

  update enfants
    set archive_le = null, archive_par = null,
        motif_archivage = '', purge_prevue_le = null
    where id = p_enfant;

  perform set_config('xylou.archivage', '', true);

  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  values (p_enfant, auth.uid(), 'dossier_desarchive', 'enfants', p_enfant,
          jsonb_build_object('motif', p_motif));
end;
$$;


--
-- Name: designer_le_premier_referent(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.designer_le_premier_referent() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if new.role <> 'referent' or new.principal or new.retire_le is not null then
    return new;
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    where i.enfant_id = new.enfant_id
      and i.role = 'referent'
      and i.principal
      and i.retire_le is null
  ) then
    new.principal := true;
    new.designe_le := now();
  end if;

  return new;
end;
$$;


--
-- Name: designer_le_referent_principal(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.designer_le_referent_principal(p_enfant uuid, p_profil uuid, p_motif text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_ancien uuid;
  v_prenom text;
begin
  -- L'administration, ou le principal en exercice qui passe la main. Pas les
  -- parents : le référent est désigné par la structure, et un désaccord avec
  -- lui se règle en le disant à l'administration, pas en le remplaçant.
  if not (
    est_admin()
    or exists (
      select 1 from intervenants_enfant i
      where i.enfant_id = p_enfant and i.profil_id = auth.uid()
        and i.role = 'referent' and i.principal and i.retire_le is null
    )
  ) then
    raise exception 'Désigner le référent principal revient à l''administration, ou au référent en exercice qui passe la main.';
  end if;

  if length(btrim(p_motif)) < 10 then
    raise exception 'Un changement de référent se motive : c''est ce que la famille lira.';
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    join profils p on p.id = i.profil_id
    where i.enfant_id = p_enfant and i.profil_id = p_profil
      and i.role = 'referent' and i.retire_le is null
      and p.role_plateforme in ('referent', 'admin')
  ) then
    raise exception 'Cette personne doit d''abord être rattachée au dossier comme référent, et disposer de l''habilitation.';
  end if;

  select i.profil_id into v_ancien
  from intervenants_enfant i
  where i.enfant_id = p_enfant and i.role = 'referent'
    and i.principal and i.retire_le is null;

  -- Dans cet ordre : l'index unique n'admet qu'un principal à la fois.
  update intervenants_enfant
    set principal = false
    where enfant_id = p_enfant and role = 'referent' and principal and retire_le is null;

  update intervenants_enfant
    set principal = true, designe_le = now()
    where enfant_id = p_enfant and profil_id = p_profil and role = 'referent';

  select prenom into v_prenom from profils where id = p_profil;

  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  values (p_enfant, auth.uid(), 'changement_referent', 'intervenants_enfant', null,
          jsonb_build_object('ancien', v_ancien, 'nouveau', p_profil, 'motif', btrim(p_motif)));

  -- La famille est prévenue. Un changement de référent la concerne au premier
  -- chef : c'est la personne à qui elle confie ce qu'elle ne dit pas à l'école.
  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select i.profil_id, p_enfant, 'message',
         'Changement de référent',
         coalesce(v_prenom, 'Une nouvelle personne') || ' suit désormais le dossier. ' || btrim(p_motif),
         '/enfants/' || p_enfant || '/equipe'
  from intervenants_enfant i
  where i.enfant_id = p_enfant and i.retire_le is null
    and i.role in ('parent', 'referent')
    and i.profil_id <> auth.uid();
end;
$$;


--
-- Name: detail_objectif(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.detail_objectif(p_objectif uuid) RETURNS TABLE(exercice_id uuid, ordre smallint, consigne text, indice text, tentative_id uuid, reponse jsonb, reussie boolean, aide_utilisee boolean, duree_secondes integer, tentee_le timestamp with time zone, points_obtenus numeric, commentaire_correction text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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


--
-- Name: devoiler_la_recompense(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.devoiler_la_recompense(p_recompense uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_rec recompenses_familiales%rowtype;
  v_compte uuid;
begin
  select * into v_rec from recompenses_familiales where id = p_recompense;

  if not found then
    raise exception 'Récompense introuvable.';
  end if;

  if not peut_valider(v_rec.enfant_id) then
    raise exception 'Dévoiler une récompense revient aux titulaires de l''autorité parentale ou au référent.';
  end if;

  if v_rec.devoilee_le is not null then
    raise exception 'Cette récompense est déjà dévoilée.';
  end if;

  update recompenses_familiales
    set devoilee_le = now(), devoilee_par = auth.uid()
    where id = p_recompense;

  select compte_id into v_compte from enfants where id = v_rec.enfant_id;

  if v_compte is not null then
    insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
    values (v_compte, v_rec.enfant_id, 'recompense_atteinte',
            'Ta surprise se dévoile : ' || v_rec.libelle, '',
            '/mes-recompenses/' || v_rec.id);
  end if;
end;
$$;


--
-- Name: devoirs_a_rattacher(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.devoirs_a_rattacher(p_enfant uuid) RETURNS TABLE(mission_id uuid, titre text, matiere_code text, saisi_par text, cree_le timestamp with time zone, exercices bigint)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select m.id, m.titre, m.matiere_code, coalesce(p.prenom, ''), m.cree_le,
         count(e.id)
  from missions m
  left join profils p on p.id = m.auteur_id
  left join exercices e on e.mission_id = m.id
  where m.enfant_id = p_enfant
    and m.nature::text = 'devoir'
    and m.objectif_id is null
    and m.statut <> 'abandonnee'
    and est_intervenant(p_enfant)
  group by m.id, m.titre, m.matiere_code, p.prenom, m.cree_le
  order by m.cree_le desc;
$$;


--
-- Name: difficultes_de_l_enfant(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.difficultes_de_l_enfant(p_enfant uuid) RETURNS TABLE(repere_id uuid, matiere_code text, domaine text, libelle text, tentatives_total bigint, reussites bigint, echecs bigint, reussites_avec_aide bigint, taux_reussite numeric)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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


--
-- Name: dossiers_a_purger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dossiers_a_purger() RETURNS TABLE(enfant_id uuid, enfant text, archive_le timestamp with time zone, purge_due_le date, date_annoncee date, ecart_jours integer, jours_de_retard integer, sur_demande boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    e.id, nom_affiche(e.prenom, e.nom), e.archive_le,
    (e.archive_le + duree_conservation())::date,
    e.purge_prevue_le,
    -- Non nul si la durée légale a changé depuis le masquage. C'est la colonne
    -- qu'on regarde le jour où quelqu'un demande pourquoi son dossier est
    -- toujours là — ou pourquoi il ne l'est plus.
    ((e.archive_le + duree_conservation())::date - e.purge_prevue_le)::integer,
    (current_date - (e.archive_le + duree_conservation())::date)::integer,
    exists (select 1 from demandes_suppression d
            where d.enfant_id = e.id and d.statut = 'masquee')
  from enfants e
  where e.archive_le is not null
    and (e.archive_le + duree_conservation())::date <= current_date
    and est_admin()
  order by (e.archive_le + duree_conservation())::date;
$$;


--
-- Name: dossiers_sans_referent_valide(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dossiers_sans_referent_valide() RETURNS TABLE(enfant_id uuid, prenom text, referent_prenom text, referent_nom text, habilitation_jusqu_au date, suppleants bigint)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    e.id, e.prenom, p.prenom, p.nom, d.valable_jusqu_au,
    (select count(*) from intervenants_enfant s
      where s.enfant_id = e.id and s.role = 'referent'
        and not s.principal and s.retire_le is null)
  from enfants e
  join intervenants_enfant i
    on i.enfant_id = e.id and i.role = 'referent'
   and i.principal and i.retire_le is null
  join profils p on p.id = i.profil_id
  left join lateral (
    select dd.valable_jusqu_au from demandes_habilitation dd
    where dd.profil_id = p.id and dd.statut = 'acceptee'
    order by dd.traitee_le desc limit 1
  ) d on true
  where e.archive_le is null
    and est_admin()
    and (
      p.role_plateforme not in ('referent', 'admin')
      or (d.valable_jusqu_au is not null and d.valable_jusqu_au <= current_date + 60)
    )
  order by d.valable_jusqu_au nulls first;
$$;


--
-- Name: duree_conservation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.duree_conservation() RETURNS interval
    LANGUAGE sql IMMUTABLE
    AS $$
  select interval '5 years';
$$;


--
-- Name: FUNCTION duree_conservation(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.duree_conservation() IS 'Durée légale de conservation après masquage. Placeholder de 5 ans — voir la question 5.5 du document juriste. Modifier ici et nulle part ailleurs.';


--
-- Name: echecs_consecutifs_objectif(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.echecs_consecutifs_objectif(p_enfant uuid, p_objectif uuid) RETURNS integer
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  with serie as (
    select t.reussie, row_number() over (order by t.cree_le desc, t.id) as rang
    from tentatives t
    join exercices e on e.id = t.exercice_id
    join missions m on m.id = e.mission_id
    where t.enfant_id = p_enfant
      and m.objectif_id = p_objectif
  )
  select coalesce(
    (select min(rang) - 1 from serie where reussie),
    (select count(*) from serie)
  )::integer;
$$;


--
-- Name: echecs_consecutifs_repere(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.echecs_consecutifs_repere(p_enfant uuid, p_repere uuid) RETURNS integer
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  with serie as (
    select t.reussie, row_number() over (order by t.cree_le desc, t.id) as rang
    from tentatives t
    join exercices e on e.id = t.exercice_id
    join missions m on m.id = e.mission_id
    left join objectifs o on o.id = m.objectif_id
    left join modeles_exercice mo on mo.id = e.modele_id
    where t.enfant_id = p_enfant
      and coalesce(o.repere_id, mo.repere_id) = p_repere
  )
  select coalesce(
    (select min(rang) - 1 from serie where reussie),
    (select count(*) from serie)
  )::integer;
$$;


--
-- Name: email_courant(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.email_courant() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select lower(coalesce(auth.jwt() ->> 'email', ''));
$$;


--
-- Name: encouragement_toujours_visible(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.encouragement_toujours_visible() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if new.type = 'encouragement' then
    new.visible_par_l_enfant := true;
  end if;
  return new;
end;
$$;


--
-- Name: enfant_de_l_adaptation(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enfant_de_l_adaptation(p_adaptation uuid) RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select s.enfant_id
  from adaptations a join supports s on s.id = a.support_id
  where a.id = p_adaptation;
$$;


--
-- Name: enfant_de_l_exercice(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enfant_de_l_exercice(p_exercice uuid) RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select m.enfant_id
  from exercices e join missions m on m.id = e.mission_id
  where e.id = p_exercice;
$$;


--
-- Name: enfant_de_l_objectif(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enfant_de_l_objectif(p_objectif uuid) RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select enfant_id from objectifs where id = p_objectif;
$$;


--
-- Name: enfant_de_la_mission(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enfant_de_la_mission(p_mission uuid) RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select enfant_id from missions where id = p_mission;
$$;


--
-- Name: enfant_de_la_question(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enfant_de_la_question(p_question uuid) RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select b.enfant_id
  from bilan_questions q join bilans_positionnement b on b.id = q.bilan_id
  where q.id = p_question;
$$;


--
-- Name: enfant_de_la_tentative(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enfant_de_la_tentative(p_tentative uuid) RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select enfant_id from tentatives where id = p_tentative;
$$;


--
-- Name: enfant_du_bilan(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enfant_du_bilan(p_bilan uuid) RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select enfant_id from bilans_positionnement where id = p_bilan;
$$;


--
-- Name: enfant_du_bilan_trimestriel(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enfant_du_bilan_trimestriel(p_bilan uuid) RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select enfant_id from bilans_trimestriels where id = p_bilan;
$$;


--
-- Name: enfant_du_chemin(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enfant_du_chemin(p_name text) RETURNS uuid
    LANGUAGE sql IMMUTABLE
    AS $$
  select uuid_ou_null((storage.foldername(p_name))[1]);
$$;


--
-- Name: enfant_du_projet_moteur(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enfant_du_projet_moteur(p_projet uuid) RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select enfant_id from projets_moteurs where id = p_projet;
$$;


--
-- Name: enfant_du_support(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enfant_du_support(p_support uuid) RETURNS uuid
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select enfant_id from supports where id = p_support;
$$;


--
-- Name: enseignants_de_la_matiere(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enseignants_de_la_matiere(p_enfant uuid, p_matiere text) RETURNS TABLE(profil_id uuid, prenom text, nom text, fonction text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select p.id, p.prenom, p.nom, i.fonction
  from intervenants_enfant i
  join profils p on p.id = i.profil_id
  where i.enfant_id = p_enfant
    and i.retire_le is null
    and i.role = 'enseignant'
    and intervenant_couvre(i.id, p_matiere)
    and est_intervenant(p_enfant)
  order by p.nom, p.prenom;
$$;


--
-- Name: enseigne_la_matiere(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enseigne_la_matiere(p_matiere text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from intervenants_enfant i
    where i.profil_id = auth.uid()
      and i.retire_le is null
      and i.role = 'enseignant'
      and intervenant_couvre(i.id, p_matiere)
  );
$$;


--
-- Name: envois_en_echec(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.envois_en_echec(p_depuis_jours integer DEFAULT 7) RETURNS TABLE(canal public.canal_envoi, statut public.statut_envoi, nombre bigint, derniere_erreur text, dernier_le timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select e.canal, e.statut, count(*), max(e.derniere_erreur), max(e.cree_le)
  from envois e
  where e.statut in ('echec', 'abandonne')
    and e.cree_le >= now() - make_interval(days => p_depuis_jours)
    and est_admin()
  group by e.canal, e.statut
  order by 3 desc;
$$;


--
-- Name: est_admin(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.est_admin() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from profils p where p.id = auth.uid() and p.role_plateforme = 'admin'
  );
$$;


--
-- Name: est_intervenant(uuid, public.role_intervenant[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.est_intervenant(p_enfant uuid, p_roles public.role_intervenant[] DEFAULT NULL::public.role_intervenant[]) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1
    from intervenants_enfant i
    join enfants e on e.id = i.enfant_id
    where i.enfant_id = p_enfant
      and i.profil_id = auth.uid()
      and i.retire_le is null
      and e.archive_le is null
      and (p_roles is null or i.role = any (p_roles))
      and (
        i.role in ('parent', 'referent')
        or consentement_actif(p_enfant, 'partage_equipe_pedagogique')
      )
  );
$$;


--
-- Name: est_intervenant_de(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.est_intervenant_de(p_profil uuid, p_enfant uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from intervenants_enfant i
    where i.enfant_id = p_enfant
      and i.profil_id = p_profil
      and i.retire_le is null
  );
$$;


--
-- Name: est_l_enfant(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.est_l_enfant(p_enfant uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from enfants e
    where e.id = p_enfant
      and e.compte_id = auth.uid()
      and e.archive_le is null
  );
$$;


--
-- Name: etat_des_consentements(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.etat_des_consentements(p_enfant uuid) RETURNS TABLE(type public.type_consentement, titre text, obligatoire boolean, titulaires_attendus smallint, titulaires_rattaches bigint, signatures bigint, actif boolean, manquants text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    t.type,
    t.titre,
    t.obligatoire,
    e.titulaires_autorite_parentale,
    (select count(*) from intervenants_enfant i
      where i.enfant_id = p_enfant and i.role = 'parent' and i.retire_le is null),
    (select count(*) from consentements c
      where c.enfant_id = p_enfant and c.type = t.type
        and c.accorde and c.revoque_le is null),
    consentement_actif(p_enfant, t.type),
    coalesce((
      select string_agg(coalesce(p.prenom, p.email), ', ')
      from intervenants_enfant i
      join profils p on p.id = i.profil_id
      where i.enfant_id = p_enfant and i.role = 'parent' and i.retire_le is null
        and not exists (
          select 1 from consentements c
          where c.enfant_id = p_enfant and c.profil_id = i.profil_id
            and c.type = t.type and c.accorde and c.revoque_le is null
        )
    ), '')
  from textes_consentement t
  cross join enfants e
  where e.id = p_enfant
    and t.retire_le is null
    and est_intervenant(p_enfant, array['parent', 'referent']::role_intervenant[])
  order by t.obligatoire desc, t.type;
$$;


--
-- Name: exercice_ouvert_a_l_enseignant(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.exercice_ouvert_a_l_enseignant(p_exercice uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from exercices e
    where e.id = p_exercice and mission_ouverte_a_l_enseignant(e.mission_id)
  );
$$;


--
-- Name: exercice_relevant_de_l_enseignant(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.exercice_relevant_de_l_enseignant(p_exercice uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from exercices e
    where e.id = p_exercice and mission_relevant_de_l_enseignant(e.mission_id)
  );
$$;


--
-- Name: exercice_sous_objectif_pilote(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.exercice_sous_objectif_pilote(p_exercice uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1
    from exercices e
    join missions m on m.id = e.mission_id
    where e.id = p_exercice
      and m.objectif_id is not null
      and pilote_l_objectif(m.objectif_id)
  );
$$;


--
-- Name: exiger_la_retransposition(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.exiger_la_retransposition() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if new.statut <> 'proposee' and new.a_retransposer then
    raise exception 'Cette mission attend d''être réécrite dans le nouvel univers avant d''être ouverte.';
  end if;
  return new;
end;
$$;


--
-- Name: exiger_le_quorum(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.exiger_le_quorum() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_declares smallint;
  v_rattaches integer;
begin
  if new.statut <> 'valide'
     or (tg_op = 'UPDATE' and old.statut is not distinct from 'valide') then
    return new;
  end if;

  if objectif_pleinement_valide(new.id) then
    return new;
  end if;

  select e.titulaires_autorite_parentale into v_declares
  from enfants e where e.id = new.enfant_id;

  select count(*) into v_rattaches
  from intervenants_enfant i
  where i.enfant_id = new.enfant_id and i.role = 'parent' and i.retire_le is null;

  if v_rattaches < v_declares then
    raise exception 'Autorité parentale : % titulaire(s) attendu(s), % rattaché(s). Invitez le titulaire manquant, ou demandez au référent de ramener le nombre à 1 si la famille est monoparentale.', v_declares, v_rattaches;
  end if;

  raise exception 'Il manque une signature : cet objectif attend encore la validation d''un titulaire de l''autorité parentale ou du référent.';
end;
$$;


--
-- Name: exiger_un_parent_rattache(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.exiger_un_parent_rattache() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_enfant uuid := coalesce(new.enfant_id, old.enfant_id);
begin
  -- La fiche a pu disparaître entre-temps : une suppression d'enfant fait
  -- cascader ses rattachements, et il n'y a alors rien à exiger.
  if not exists (select 1 from enfants e where e.id = v_enfant) then
    return null;
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    where i.enfant_id = v_enfant
      and i.role = 'parent'
      and i.retire_le is null
  ) then
    raise exception 'Un enfant conserve au moins un titulaire de l''autorité parentale rattaché.';
  end if;

  return null;
end;
$$;


--
-- Name: exiger_un_referent_principal(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.exiger_un_referent_principal() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_enfant uuid := coalesce(new.enfant_id, old.enfant_id);
begin
  if not exists (select 1 from enfants e where e.id = v_enfant) then
    return null;
  end if;

  if exists (
    select 1 from enfants e where e.id = v_enfant and e.archive_le is not null
  ) then
    return null;
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    where i.enfant_id = v_enfant
      and i.role = 'referent'
      and i.principal
      and i.retire_le is null
  ) then
    raise exception 'Ce dossier n''a plus de référent principal. Désignez un suppléant, ou demandez à l''administration d''en rattacher un.';
  end if;

  return null;
end;
$$;


--
-- Name: exiger_une_action_avant_cloture(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.exiger_une_action_avant_cloture() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if new.statut = 'traitee' and (tg_op = 'INSERT' or old.statut <> 'traitee') then
    if not exists (select 1 from alertes_actions a where a.alerte_id = new.id) then
      raise exception 'Une alerte se clôt en consignant ce qui a été tenté. Ajoutez une action, ou écartez l''alerte si le blocage n''en était pas un.';
    end if;
  end if;
  return new;
end;
$$;


--
-- Name: exiger_une_matiere_a_l_enseignant(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.exiger_une_matiere_a_l_enseignant() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_role role_intervenant;
begin
  select i.role into v_role
  from intervenants_enfant i
  where i.id = coalesce(new.intervenant_id, old.intervenant_id);

  -- L'intervenant a disparu : il n'y a plus personne à qui exiger une matière.
  if v_role is distinct from 'enseignant' then
    return null;
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    where i.id = coalesce(new.intervenant_id, old.intervenant_id)
      and (
        i.toutes_matieres
        or exists (select 1 from intervenants_matieres m where m.intervenant_id = i.id)
      )
  ) then
    raise exception 'Un enseignant couvre au moins une matière, ou toutes.';
  end if;

  return null;
end;
$$;


--
-- Name: exiger_une_matiere_au_rattachement(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.exiger_une_matiere_au_rattachement() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if new.role is distinct from 'enseignant' or new.retire_le is not null then
    return null;
  end if;

  if new.toutes_matieres then
    return null;
  end if;

  if not exists (
    select 1 from intervenants_matieres m where m.intervenant_id = new.id
  ) then
    raise exception 'Un enseignant couvre au moins une matière, ou toutes. Renseignez son périmètre.';
  end if;

  return null;
end;
$$;


--
-- Name: figer_ce_que_l_enfant_a_vu(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.figer_ce_que_l_enfant_a_vu() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_nature_vue boolean := old.devoilee_le is not null or old.montrer_nature;
  v_date_vue boolean := old.devoilee_le is not null or old.montrer_date;
  v_jauge_vue boolean := old.devoilee_le is not null or old.montrer_progression;
begin
  if v_nature_vue and (
       new.libelle      is distinct from old.libelle
    or new.description  is distinct from old.description
    or new.photo_chemin is distinct from old.photo_chemin
  ) then
    raise exception 'L''enfant a déjà lu cette récompense : son intitulé et sa photo ne se réécrivent plus. Annulez-la en vous expliquant, ou promettez-en une autre.';
  end if;

  if v_jauge_vue and (
       coalesce(new.points_requis, 0)     > coalesce(old.points_requis, 0)
    or coalesce(new.missions_requises, 0) > coalesce(old.missions_requises, 0)
  ) then
    raise exception 'Relever une exigence que l''enfant voit revient à éloigner l''arrivée pendant qu''il court. On peut l''abaisser, pas la remonter.';
  end if;

  -- Poser une date là où il n'y en avait pas n'est pas un report : c'est une
  -- précision qu'on ajoute, et elle ne rompt aucune promesse. Seul le décalage
  -- d'une date déjà connue se motive.
  if v_date_vue
     and old.prevue_le is not null
     and new.prevue_le is distinct from old.prevue_le then

    if new.prevue_le is null then
      raise exception 'Retirer une date que l''enfant connaît la laisse sans repère. Reportez-la, ou annulez la récompense.';
    end if;

    if length(btrim(coalesce(new.motif, ''))) < 5 then
      raise exception 'Décaler une date que l''enfant connaît se motive : renseignez le motif, il lui sera montré.';
    end if;

    insert into recompenses_reports
      (recompense_id, ancienne_date, nouvelle_date, motif, reporte_par)
    values
      (old.id, old.prevue_le, new.prevue_le, btrim(new.motif), auth.uid());
  end if;

  return new;
end;
$$;


--
-- Name: figer_la_borne_de_l_acces(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.figer_la_borne_de_l_acces() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if new.expire_le is distinct from old.expire_le
  or new.motif is distinct from old.motif
  or new.enfant_id is distinct from old.enfant_id
  or new.ouvert_par is distinct from old.ouvert_par then
    raise exception 'Un accès d''exception ne se prolonge ni ne se réécrit : refermez-le et rouvrez-en un, motif à l''appui.';
  end if;
  return new;
end;
$$;


--
-- Name: figer_la_portee(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.figer_la_portee() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if new.portee is distinct from old.portee then
    raise exception 'La portée d''un fil ne se modifie pas : ouvrez un fil d''équipe et reprenez-y ce qui doit être partagé.';
  end if;
  return new;
end;
$$;


--
-- Name: figer_la_visibilite(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.figer_la_visibilite() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if old.devoilee_le is not null and new.devoilee_le is null then
    raise exception 'Une récompense dévoilée ne se recache pas.';
  end if;

  if (old.montrer_existence   and not new.montrer_existence)
  or (old.montrer_nature      and not new.montrer_nature)
  or (old.montrer_date        and not new.montrer_date)
  or (old.montrer_progression and not new.montrer_progression) then
    raise exception 'On peut en montrer davantage, jamais moins : l''enfant a déjà lu ce qui était visible.';
  end if;

  return new;
end;
$$;


--
-- Name: figer_le_consentement(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.figer_le_consentement() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if new.enfant_id      is distinct from old.enfant_id
  or new.profil_id      is distinct from old.profil_id
  or new.type           is distinct from old.type
  or new.accorde        is distinct from old.accorde
  or new.texte_id       is distinct from old.texte_id
  or new.version_texte  is distinct from old.version_texte
  or new.signature_nom  is distinct from old.signature_nom
  or new.signature_chemin is distinct from old.signature_chemin
  or new.accorde_le     is distinct from old.accorde_le
  or new.adresse_ip     is distinct from old.adresse_ip then
    raise exception 'Un consentement signé ne se modifie pas. Révoquez-le, ou signez la version en vigueur.';
  end if;

  if old.revoque_le is not null and new.revoque_le is distinct from old.revoque_le then
    raise exception 'Un consentement déjà révoqué ne se réactive pas : signez de nouveau.';
  end if;

  return new;
end;
$$;


--
-- Name: figer_le_texte_publie(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.figer_le_texte_publie() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if new.contenu is distinct from old.contenu
  or new.titre is distinct from old.titre
  or new.type is distinct from old.type
  or new.version is distinct from old.version
  or new.obligatoire is distinct from old.obligatoire then
    raise exception 'Un texte de consentement ne se modifie pas : publiez une nouvelle version et retirez celle-ci.';
  end if;
  return new;
end;
$$;


--
-- Name: fil_du_chemin(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fil_du_chemin(p_name text) RETURNS uuid
    LANGUAGE sql IMMUTABLE
    AS $$
  select uuid_ou_null((storage.foldername(p_name))[2]);
$$;


--
-- Name: frise(uuid, date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.frise(p_enfant uuid, p_debut date, p_fin date) RETURNS TABLE(jour date, journee_id uuid, periode_id uuid, type_jour public.type_jour, emoji text, titre text, resume text, humeur public.humeur_jour, recit text, etapes bigint, etapes_faites bigint, reperes bigint, preparatifs_restants bigint, entrees bigint, medias bigint, encouragements bigint)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    d.jour::date,
    j.id,
    j.periode_id,
    coalesce(j.type_jour, case
      when extract(isodow from d.jour) >= 6 then 'week_end'::type_jour
      else 'ecole'::type_jour
    end),
    coalesce(j.emoji, ''),
    coalesce(j.titre, ''),
    coalesce(j.resume, ''),
    j.humeur,
    coalesce(j.recit, ''),
    count(distinct et.id),
    count(distinct et.id) filter (where et.faite_le is not null),
    count(distinct rp.id),
    count(distinct pr.id) filter (where pr.coche_le is null),
    count(distinct e.id),
    count(distinct m.id),
    count(distinct e.id) filter (where e.type = 'encouragement')
  from generate_series(p_debut, p_fin, interval '1 day') d(jour)
  left join journees j on j.enfant_id = p_enfant and j.jour = d.jour::date
  left join journee_etapes et on et.journee_id = j.id
  left join journee_reperes rp on rp.journee_id = j.id
  left join journee_preparatifs pr on pr.journee_id = j.id
  left join journal_entrees e on e.journee_id = j.id
  left join journal_medias m on m.journee_id = j.id
  where est_intervenant(p_enfant) or est_l_enfant(p_enfant)
  group by d.jour, j.id, j.periode_id, j.type_jour, j.emoji, j.titre, j.resume, j.humeur, j.recit
  order by d.jour;
$$;


--
-- Name: garnir_les_preparatifs(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.garnir_les_preparatifs() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  insert into journee_preparatifs (journee_id, libelle, note, essentiel, ordre)
  select new.id, r.libelle, r.note, r.essentiel, r.ordre
  from preparatifs_recurrents r
  where r.enfant_id = new.enfant_id and r.actif;
  return new;
end;
$$;


--
-- Name: groupe_de_maitrise(public.maitrise); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.groupe_de_maitrise(p_maitrise public.maitrise) RETURNS smallint
    LANGUAGE sql IMMUTABLE
    AS $$
  select case p_maitrise
    when 'a_travailler' then 1
    when 'en_cours'     then 2
    when 'acquise'      then 3
    -- Un point fort reste dans le groupe le plus élevé : les évaluations
    -- nationales n'ont pas de quatrième groupe pour le distinguer. C'est
    -- précisément ce que notre échelle sait dire et pas la leur, et c'est une
    -- raison de garder les deux.
    when 'point_fort'   then 3
    else null
  end::smallint;
$$;


--
-- Name: groupes_par_matiere(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.groupes_par_matiere(p_bilan uuid) RETURNS TABLE(matiere_code text, groupe smallint, repere_count bigint)
    LANGUAGE sql STABLE
    AS $$
  select
    r.matiere_code,
    percentile_disc(0.5) within group (
      order by groupe_de_maitrise(bm.maitrise)
    )::smallint as groupe,
    count(*) as repere_count
  from bilan_maitrises bm
  join reperes_competences r on r.id = bm.repere_id
  where bm.bilan_id = p_bilan
    and groupe_de_maitrise(bm.maitrise) is not null
  group by r.matiere_code;
$$;


--
-- Name: habilitation_du_chemin(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.habilitation_du_chemin(p_name text) RETURNS uuid
    LANGUAGE sql IMMUTABLE
    AS $$
  select uuid_ou_null((storage.foldername(p_name))[1]);
$$;


--
-- Name: habilitations_a_instruire(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.habilitations_a_instruire() RETURNS TABLE(demande_id uuid, prenom text, nom text, email text, fonction text, organisation text, uai text, etablissement_adresse text, numero_professionnel text, motivation text, directeur_nom text, directeur_contact text, pieces bigint, types_fournis text, pieces_perimees bigint, depuis_jours integer, manquantes text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    d.id, p.prenom, p.nom, p.email, d.fonction, d.organisation, d.uai,
    d.etablissement_adresse, d.numero_professionnel, d.motivation,
    d.directeur_nom, d.directeur_contact,
    count(pi.id),
    coalesce(string_agg(distinct pi.type_piece::text, ', '), ''),
    count(pi.id) filter (where pi.valable_jusqu_au is not null
                           and pi.valable_jusqu_au < current_date),
    (current_date - d.cree_le::date)::integer,
    array_to_string(pieces_manquantes(d.id), ', ')
  from demandes_habilitation d
  join profils p on p.id = d.profil_id
  left join habilitation_pieces pi on pi.demande_id = d.id
  where d.statut = 'en_attente' and est_admin()
  group by d.id, p.prenom, p.nom, p.email, d.fonction, d.organisation, d.uai,
           d.etablissement_adresse, d.numero_professionnel, d.motivation,
           d.directeur_nom, d.directeur_contact, d.cree_le
  order by d.cree_le;
$$;


--
-- Name: habilitations_a_renouveler(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.habilitations_a_renouveler(p_preavis_jours integer DEFAULT 60) RETURNS TABLE(profil_id uuid, prenom text, nom text, email text, organisation text, valable_jusqu_au date, jours_restants integer, dossiers_suivis bigint)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    p.id, p.prenom, p.nom, p.email, d.organisation, d.valable_jusqu_au,
    (d.valable_jusqu_au - current_date)::integer,
    (select count(*) from intervenants_enfant i
      where i.profil_id = p.id and i.role = 'referent' and i.retire_le is null)
  from demandes_habilitation d
  join profils p on p.id = d.profil_id
  where d.statut = 'acceptee'
    and d.valable_jusqu_au is not null
    and d.valable_jusqu_au <= current_date + p_preavis_jours
    and p.role_plateforme = 'referent'
    and est_admin()
  order by d.valable_jusqu_au;
$$;


--
-- Name: horizon_de(date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.horizon_de(p_date date) RETURNS public.horizon_recompense
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
  select case
    when p_date - current_date <= 3  then 'imminent'
    when p_date - current_date <= 14 then 'court_terme'
    when p_date - current_date <= 60 then 'moyen_terme'
    else 'long_terme'
  end::horizon_recompense;
$$;


--
-- Name: horodater_l_humeur(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.horodater_l_humeur() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if tg_op = 'INSERT' then
    if new.humeur is not null then new.humeur_le := now(); end if;
  elsif new.humeur is distinct from old.humeur then
    new.humeur_le := case when new.humeur is null then null else now() end;
  end if;
  return new;
end;
$$;


--
-- Name: informer_de_l_acces(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.informer_de_l_acces(p_acces uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_acces acces_exceptionnels%rowtype;
begin
  select * into v_acces from acces_exceptionnels where id = p_acces;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select
    i.profil_id, v_acces.enfant_id, 'acces_exceptionnel',
    'Accès administratif au dossier',
    'Motif : ' || v_acces.motif,
    '/enfants/' || v_acces.enfant_id || '/acces/' || v_acces.id
  from intervenants_enfant i
  where i.enfant_id = v_acces.enfant_id
    and i.retire_le is null
    and i.role in ('parent', 'referent');
end;
$$;


--
-- Name: inscrire_le_createur(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.inscrire_le_createur() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  insert into fils_participants (fil_id, profil_id, ajoute_par)
  values (new.id, new.cree_par, new.cree_par)
  on conflict do nothing;
  return new;
end;
$$;


--
-- Name: intervenant_couvre(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.intervenant_couvre(p_intervenant uuid, p_matiere text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from intervenants_enfant i
    where i.id = p_intervenant
      and (
        i.toutes_matieres
        or exists (
          select 1 from intervenants_matieres m
          where m.intervenant_id = i.id and m.matiere_code = p_matiere
        )
      )
  );
$$;


--
-- Name: invalider_le_modele_retouche(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.invalider_le_modele_retouche() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if old.statut = 'valide' and (
       new.consigne is distinct from old.consigne
    or new.contenu is distinct from old.contenu
    or new.parametres is distinct from old.parametres
    or new.correction is distinct from old.correction
    or new.type_reponse is distinct from old.type_reponse
  ) then
    new.statut := 'propose';
    new.valide_par := null;
    new.valide_le := null;
  end if;
  return new;
end;
$$;


--
-- Name: jauge_badge(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.jauge_badge(p_enfant uuid, p_matiere text DEFAULT NULL::text, p_domaine text DEFAULT NULL::text) RETURNS TABLE(champ text, libelle text, emoji text, niveau_actuel smallint, objectifs_total bigint, objectifs_atteints bigint, progression numeric, seuil numeric)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    coalesce(p_matiere, p_domaine),
    coalesce(m.libelle, d.libelle, ''),
    coalesce(m.emoji, d.emoji, '🎓'),
    coalesce((
      select max(b.niveau) from badges_obtenus b
      where b.enfant_id = p_enfant
        and b.matiere_code is not distinct from p_matiere
        and b.domaine_code is not distinct from p_domaine
    ), 0::smallint),
    count(o.id),
    count(o.id) filter (where o.statut = 'atteint'),
    case when count(o.id) = 0 then 0
         else round(100.0 * count(o.id) filter (where o.statut = 'atteint') / count(o.id), 0)
    end,
    seuil_badge()
  from (select 1) unite
  left join matieres m on m.code = p_matiere
  left join domaines_transversaux d on d.code = p_domaine
  left join annees_enfant a on a.enfant_id = p_enfant and a.close_le is null
  left join objectifs o
    on o.enfant_id = p_enfant
   and o.granularite = 'fin'
   and o.matiere_code is not distinct from p_matiere
   and o.domaine_code is not distinct from p_domaine
   and (o.annee_id is null or o.annee_id = a.id)
   and o.statut in ('valide', 'atteint')
  where est_intervenant(p_enfant) or est_l_enfant(p_enfant)
  group by m.libelle, d.libelle, m.emoji, d.emoji;
$$;


--
-- Name: journee_du_chemin(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.journee_du_chemin(p_name text) RETURNS uuid
    LANGUAGE sql IMMUTABLE
    AS $$
  select uuid_ou_null((storage.foldername(p_name))[2]);
$$;


--
-- Name: lever_le_secret(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.lever_le_secret(p_acces uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if not est_admin() then
    raise exception 'Réservé à l''administration.';
  end if;

  if not exists (
    select 1 from acces_exceptionnels
    where id = p_acces and information_faite_le is null
  ) then
    raise exception 'Cet accès a déjà été porté à la connaissance de la famille.';
  end if;

  perform informer_de_l_acces(p_acces);

  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  select a.enfant_id, auth.uid(), 'acces_exceptionnel_revele',
         'acces_exceptionnels', a.id,
         jsonb_build_object('ouvert_le', a.ouvert_le)
  from acces_exceptionnels a where a.id = p_acces;

  update acces_exceptionnels set information_faite_le = now() where id = p_acces;
end;
$$;


--
-- Name: libelle_groupe_de_maitrise(smallint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.libelle_groupe_de_maitrise(p_groupe smallint) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  select case p_groupe
    when 1 then 'Groupe 1 — à construire'
    when 2 then 'Groupe 2 — en cours de construction'
    when 3 then 'Groupe 3 — maîtrisé'
    else 'Non évalué'
  end;
$$;


--
-- Name: ma_quete(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ma_quete(p_enfant uuid) RETURNS TABLE(quete_id uuid, titre text, description text, trimestre smallint, statut public.statut_quete, badges_vises bigint, badges_obtenus bigint, missions_total bigint, missions_reussies bigint, pieces_gagnees bigint, progression numeric)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select p.quete_id, p.titre, q.description, p.trimestre, p.statut,
         p.badges_vises, p.badges_obtenus, p.missions_total, p.missions_reussies,
         p.pieces_gagnees, p.progression
  from quetes q
  cross join lateral progression_quete(q.id) p
  where q.enfant_id = p_enfant
    and q.statut = 'en_cours'
    and (est_l_enfant(p_enfant) or est_intervenant(p_enfant));
$$;


--
-- Name: masquer_le_dossier(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.masquer_le_dossier(p_demande uuid) RETURNS date
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_enfant uuid;
  v_prenom text;
  v_motif text;
  v_demandeur uuid;
  v_accords jsonb;
  v_purge date;
begin
  if not est_admin() then
    raise exception 'Le masquage d''un dossier revient à l''administration.';
  end if;

  select d.enfant_id, d.motif, d.demandee_par
    into v_enfant, v_motif, v_demandeur
  from demandes_suppression d
  where d.id = p_demande and d.statut = 'accordee';

  if v_enfant is null then
    raise exception 'Cette demande n''a pas reçu l''accord de tous les titulaires.';
  end if;

  select prenom into v_prenom from enfants where id = v_enfant;

  select coalesce(jsonb_agg(jsonb_build_object(
           'profil', a.profil_id, 'signature', a.signature_nom, 'le', a.accorde_le)), '[]'::jsonb)
    into v_accords
  from suppressions_accords a where a.demande_id = p_demande;

  -- Même durée qu'en 0031 : une suppression demandée et un archivage ordinaire
  -- n'ont aucune raison de se conserver différemment.
  v_purge := (now() + interval '5 years')::date;

  -- Le laissez-passer de 0031 : les colonnes d'archivage ne se posent que par
  -- les fonctions prévues.
  perform set_config('xylou.archivage', 'en_cours', true);

  update enfants
    set archive_le = now(),
        archive_par = auth.uid(),
        motif_archivage = v_motif,
        purge_prevue_le = v_purge
    where id = v_enfant;

  perform set_config('xylou.archivage', '', true);

  update demandes_suppression
    set statut = 'masquee', masquee_par = auth.uid(),
        masquee_le = now(), purge_prevue_le = v_purge
    where id = p_demande;

  insert into suppressions_effectuees
    (enfant_id, prenom, demandee_par, motif, accords, masquee_par, purge_prevue_le)
  values
    (v_enfant, coalesce(v_prenom, ''), v_demandeur, v_motif, v_accords, auth.uid(), v_purge);

  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  values (v_enfant, auth.uid(), 'dossier_masque', 'enfants', v_enfant,
          jsonb_build_object('motif', v_motif, 'purge_prevue_le', v_purge));

  return v_purge;
end;
$$;


--
-- Name: matiere_de_l_intervenant(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.matiere_de_l_intervenant(p_enfant uuid) RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select i.matiere_code
  from intervenants_enfant i
  where i.enfant_id = p_enfant
    and i.profil_id = auth.uid()
    and i.retire_le is null
  limit 1;
$$;


--
-- Name: matiere_ouverte_a_l_ecriture(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.matiere_ouverte_a_l_ecriture(p_enfant uuid, p_matiere text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1
    from intervenants_enfant i
    join enfants e on e.id = i.enfant_id
    where i.enfant_id = p_enfant
      and i.profil_id = auth.uid()
      and i.retire_le is null
      and e.archive_le is null
      and (i.role <> 'enseignant' or intervenant_couvre(i.id, p_matiere))
      and (
        i.role in ('parent', 'referent')
        or consentement_actif(p_enfant, 'partage_equipe_pedagogique')
      )
  );
$$;


--
-- Name: matieres_sans_enseignant(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.matieres_sans_enseignant(p_enfant uuid) RETURNS TABLE(matiere_code text, retire_le timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select mp.matiere_code, max(partis.retire_le)
  from intervenants_enfant partis
  join intervenants_matieres mp on mp.intervenant_id = partis.id
  where partis.enfant_id = p_enfant
    and partis.role = 'enseignant'
    and partis.retire_le is not null
    and est_intervenant(p_enfant)
    and not exists (
      select 1 from intervenants_enfant actifs
      where actifs.enfant_id = p_enfant
        and actifs.role = 'enseignant'
        and actifs.retire_le is null
        and intervenant_couvre(actifs.id, mp.matiere_code)
    )
  group by mp.matiere_code;
$$;


--
-- Name: mes_jauges(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mes_jauges(p_enfant uuid) RETURNS TABLE(champ text, libelle text, emoji text, niveau_actuel smallint, objectifs_total bigint, objectifs_atteints bigint, progression numeric, seuil numeric)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select j.*
  from (
    select distinct o.matiere_code, o.domaine_code
    from objectifs o
    left join annees_enfant a on a.id = o.annee_id
    where o.enfant_id = p_enfant
      and o.granularite = 'fin'
      and o.statut in ('valide', 'atteint')
  ) champs
  cross join lateral jauge_badge(p_enfant, champs.matiere_code, champs.domaine_code) j
  where est_intervenant(p_enfant) or est_l_enfant(p_enfant)
  order by j.progression desc;
$$;


--
-- Name: mes_recompenses(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mes_recompenses(p_enfant uuid) RETURNS TABLE(recompense_id uuid, devoilee boolean, libelle text, description text, photo_chemin text, surprise_libelle text, surprise_image_chemin text, prevue_le date, jours_restants integer, horizon public.horizon_recompense, points_requis integer, points_actuels integer, missions_requises integer, missions_actuelles integer, badges_requis integer, badges_actuels integer, progression numeric, de_la_part_de text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    r.id,
    (r.devoilee_le is not null),
    case when r.devoilee_le is not null or r.montrer_nature then r.libelle else '' end,
    case when r.devoilee_le is not null or r.montrer_nature then r.description else '' end,
    case when r.devoilee_le is not null or r.montrer_nature then r.photo_chemin else null end,
    coalesce(pm.surprise_libelle, 'Une surprise'),
    pm.surprise_image_chemin,
    case when r.devoilee_le is not null or r.montrer_date then r.prevue_le else null end,
    case when r.devoilee_le is not null or r.montrer_date
         then (r.prevue_le - current_date)::integer else null end,
    case when r.devoilee_le is not null or r.montrer_date
         then horizon_de(r.prevue_le) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.points_requis else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then coalesce(p.points_gagnes, 0) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.missions_requises else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then missions_reussies(p_enfant) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.badges_requis else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then badges_de_l_annee(p_enfant) else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then progression_vers(p_enfant, r.points_requis, r.missions_requises, r.badges_requis)
         else null end,
    coalesce(pr.prenom, '')
  from recompenses_familiales r
  left join points_enfant p on p.enfant_id = r.enfant_id
  left join profils pr on pr.id = r.proposee_par
  left join projets_moteurs pm on pm.enfant_id = r.enfant_id and pm.actif
  where r.enfant_id = p_enfant
    and r.statut = 'promise'
    and (r.montrer_existence or r.devoilee_le is not null)
    and (est_l_enfant(p_enfant) or est_intervenant(p_enfant))
  order by r.prevue_le nulls last;
$$;


--
-- Name: mettre_en_file(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mettre_en_file() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_email text;
  v_appareil record;
begin
  if not type_notifie_hors_application(new.type) then
    return new;
  end if;

  select email into v_email from profils where id = new.destinataire_id;

  -- Courriel : actif sauf refus explicite. L'absence de préférence vaut accord,
  -- sinon personne ne recevrait rien tant qu'il n'a pas visité un écran de
  -- réglages qu'il n'a aucune raison d'ouvrir.
  if v_email is not null and v_email <> '' and not exists (
    select 1 from preferences_notification p
    where p.profil_id = new.destinataire_id
      and p.type = new.type and p.canal = 'courriel' and not p.actif
  ) then
    insert into envois
      (notification_id, destinataire_id, canal, adresse, sujet, corps, lien)
    values
      (new.id, new.destinataire_id, 'courriel', v_email, new.titre, new.corps, new.lien);
  end if;

  -- Push : un envoi par appareil actif. Pas de préférence par défaut non plus,
  -- mais la question ne se pose que pour qui a installé l'application — donc
  -- pour qui a déjà accepté les notifications au niveau du système.
  for v_appareil in
    select a.jeton_push from appareils a
    where a.profil_id = new.destinataire_id and a.actif
  loop
    if not exists (
      select 1 from preferences_notification p
      where p.profil_id = new.destinataire_id
        and p.type = new.type and p.canal = 'push' and not p.actif
    ) then
      insert into envois
        (notification_id, destinataire_id, canal, adresse, sujet, corps, lien)
      values
        (new.id, new.destinataire_id, 'push', v_appareil.jeton_push,
         new.titre, new.corps, new.lien);
    end if;
  end loop;

  return new;
end;
$$;


--
-- Name: mission_est_un_devoir(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mission_est_un_devoir(p_mission uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from missions m
    where m.id = p_mission and m.nature::text = 'devoir'
  );
$$;


--
-- Name: mission_ouverte_a_l_enseignant(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mission_ouverte_a_l_enseignant(p_mission uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1
    from missions m
    join enfants enf on enf.id = m.enfant_id and enf.archive_le is null
    join intervenants_enfant i on i.enfant_id = m.enfant_id
    join objectifs o on o.id = m.objectif_id
    where m.id = p_mission
      and i.profil_id = auth.uid()
      and i.retire_le is null
      and i.role = 'enseignant'
      and intervenant_couvre(i.id, m.matiere_code)
      and o.statut in ('valide', 'atteint')
  );
$$;


--
-- Name: mission_relevant_de_l_enseignant(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.mission_relevant_de_l_enseignant(p_mission uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1
    from missions m
    join enfants enf on enf.id = m.enfant_id and enf.archive_le is null
    join intervenants_enfant moi
      on moi.enfant_id = m.enfant_id
     and moi.profil_id = auth.uid()
     and moi.retire_le is null
    left join adaptations a on a.id = m.adaptation_id
    left join supports s on s.id = a.support_id
    left join objectifs o on o.id = m.objectif_id
    where m.id = p_mission
      and (
        (
          moi.role = 'enseignant'
          and intervenant_couvre(moi.id, m.matiere_code)
          and (
            m.auteur_id = auth.uid()
            or m.fourni_par = auth.uid()
            or s.depose_par = auth.uid()
            or s.fourni_par = auth.uid()
            or o.propose_par = auth.uid()
          )
        )
        or (
          not exists (
            select 1 from intervenants_enfant src
            where src.enfant_id = m.enfant_id
              and src.retire_le is null
              and src.profil_id in (m.auteur_id, m.fourni_par,
                                    s.depose_par, s.fourni_par, o.propose_par)
          )
          and (
            (moi.role = 'enseignant' and intervenant_couvre(moi.id, m.matiere_code))
            or moi.role = 'referent'
          )
        )
      )
  );
$$;


--
-- Name: missions_a_retransposer(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.missions_a_retransposer(p_enfant uuid) RETURNS TABLE(mission_id uuid, titre text, matiere_code text, domaine_code text, exercices bigint)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select m.id, m.titre, m.matiere_code, m.domaine_code, count(e.id)
  from missions m
  left join exercices e on e.mission_id = m.id
  where m.enfant_id = p_enfant
    and m.a_retransposer
    and est_intervenant(p_enfant)
  group by m.id, m.titre, m.matiere_code, m.domaine_code
  order by m.ordre;
$$;


--
-- Name: missions_reussies(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.missions_reussies(p_enfant uuid) RETURNS integer
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select count(*)::integer from missions
  where enfant_id = p_enfant and statut = 'reussie';
$$;


--
-- Name: nom_affiche(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.nom_affiche(p_prenom text, p_nom text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
  select btrim(coalesce(p_prenom, '') || ' ' || coalesce(p_nom, ''));
$$;


--
-- Name: notifier_demande_objectif(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notifier_demande_objectif() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_enfant uuid;
  v_libelle text;
begin
  select o.enfant_id, o.libelle into v_enfant, v_libelle
  from objectifs o where o.id = new.objectif_id;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select
    i.profil_id,
    v_enfant,
    'objectif_modification_demandee',
    'Modification demandée : ' || v_libelle,
    new.motif,
    '/enfants/' || v_enfant || '/objectifs/' || new.objectif_id
  from intervenants_enfant i
  where i.enfant_id = v_enfant
    and i.retire_le is null
    and i.role in ('parent', 'referent')
    and i.profil_id <> new.demande_par;

  return new;
end;
$$;


--
-- Name: notifier_nouveau_message(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notifier_nouveau_message() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_fil fils%rowtype;
begin
  select * into v_fil from fils where id = new.fil_id;

  update fils
    set dernier_message_le = new.cree_le
    where id = new.fil_id;

  if v_fil.portee = 'equipe' then
    insert into notifications (destinataire_id, enfant_id, type, titre, lien, message_id)
    select
      i.profil_id,
      v_fil.enfant_id,
      'message',
      coalesce(nullif(v_fil.sujet, ''), 'Nouveau message'),
      '/enfants/' || v_fil.enfant_id || '/echanges/' || v_fil.id,
      new.id
    from intervenants_enfant i
    where i.enfant_id = v_fil.enfant_id
      and i.retire_le is null
      and i.profil_id <> new.auteur_id;
  else
    insert into notifications (destinataire_id, enfant_id, type, titre, lien, message_id)
    select
      p.profil_id,
      v_fil.enfant_id,
      'message',
      coalesce(nullif(v_fil.sujet, ''), 'Nouveau message'),
      '/enfants/' || v_fil.enfant_id || '/echanges/' || v_fil.id,
      new.id
    from fils_participants p
    where p.fil_id = v_fil.id
      and p.profil_id <> new.auteur_id;
  end if;

  return new;
end;
$$;


--
-- Name: notifier_objectif_propose(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notifier_objectif_propose() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select
    i.profil_id,
    new.enfant_id,
    'objectif_propose',
    'Objectif à valider',
    new.libelle,
    '/enfants/' || new.enfant_id || '/objectifs/' || new.id
  from intervenants_enfant i
  where i.enfant_id = new.enfant_id
    and i.retire_le is null
    and i.role in ('parent', 'referent')
    and i.profil_id is distinct from new.propose_par;

  return new;
end;
$$;


--
-- Name: objectif_pleinement_valide(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.objectif_pleinement_valide(p_objectif uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    composition_parentale_complete((select enfant_id from objectifs where id = p_objectif))
    and not exists (
      select 1 from valideurs_requis(p_objectif) r
      where not exists (
        select 1 from objectifs_validations v
        where v.objectif_id = p_objectif and v.profil_id = r.profil_id
      )
    );
$$;


--
-- Name: objectif_valide(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.objectif_valide(p_objectif uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from objectifs o
    where o.id = p_objectif and o.statut in ('valide', 'atteint')
  );
$$;


--
-- Name: objectifs_de_l_enfant(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.objectifs_de_l_enfant(p_enfant uuid) RETURNS TABLE(objectif_id uuid, granularite public.granularite_objectif, objectif_parent_id uuid, libelle text, description text, matiere_code text, domaine_code text, statut public.statut_objectif, debute_le date, echeance_le date, critere_fin text, reussites_visees smallint, exercices_vises smallint, exercices_proposes bigint, reussites bigint, seuil_atteint boolean, propose_par_prenom text, signatures bigint, signatures_attendues bigint)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    o.id, o.granularite, o.objectif_parent_id, o.libelle, o.description,
    o.matiere_code, o.domaine_code, o.statut, o.debute_le, o.echeance_le,
    o.critere_fin, o.reussites_visees, o.exercices_vises,
    coalesce(p.exercices_proposes, 0), coalesce(p.reussites, 0),
    coalesce(p.seuil_atteint, false),
    coalesce(pr.prenom, ''),
    (select count(*) from objectifs_validations v where v.objectif_id = o.id),
    (select count(*) from valideurs_requis(o.id))
  from objectifs o
  left join profils pr on pr.id = o.propose_par
  left join lateral progression_objectif(o.id) p on o.granularite = 'fin'
  where o.enfant_id = p_enfant
    and est_intervenant(p_enfant)
  order by o.granularite, o.debute_le desc;
$$;


--
-- Name: objectifs_non_atteints(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.objectifs_non_atteints(p_annee uuid) RETURNS TABLE(objectif_id uuid, libelle text, matiere_code text, domaine_code text, granularite public.granularite_objectif, statut public.statut_objectif)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select o.id, o.libelle, o.matiere_code, o.domaine_code, o.granularite, o.statut
  from objectifs o
  join annees_enfant a on a.id = o.annee_id
  where o.annee_id = p_annee
    and o.statut in ('propose', 'valide')
    and est_intervenant(a.enfant_id)
  order by o.granularite, o.libelle;
$$;


--
-- Name: partage_un_enfant(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.partage_un_enfant(p_profil uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1
    from intervenants_enfant a
    join intervenants_enfant b on b.enfant_id = a.enfant_id
    where a.profil_id = auth.uid() and a.retire_le is null
      and b.profil_id = p_profil and b.retire_le is null
  );
$$;


--
-- Name: passer_en_classe_superieure(uuid, public.niveau_classe, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.passer_en_classe_superieure(p_enfant uuid, p_classe public.niveau_classe, p_annee_scolaire text, p_etablissement text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_ancienne annees_enfant%rowtype;
  v_bilan uuid;
  v_nouvelle uuid;
begin
  if not peut_valider(p_enfant) then
    raise exception 'Le passage de classe est acté par la famille ou le référent.';
  end if;

  select * into v_ancienne
  from annees_enfant
  where enfant_id = p_enfant and close_le is null;

  if found then
    -- Le dernier bilan trimestriel validé de l'année qui se termine devient le
    -- point de départ de la suivante.
    select b.id into v_bilan
    from bilans_trimestriels b
    where b.enfant_id = p_enfant
      and b.annee_id = v_ancienne.id
      and b.statut = 'valide'
    order by b.trimestre desc
    limit 1;

    update annees_enfant set close_le = current_date where id = v_ancienne.id;
  end if;

  insert into annees_enfant (
    enfant_id, annee_scolaire, classe, etablissement,
    bilan_anterieur_id, annee_precedente_id
  )
  values (
    p_enfant, p_annee_scolaire, p_classe,
    coalesce(p_etablissement, v_ancienne.etablissement, ''),
    v_bilan, v_ancienne.id
  )
  returning id into v_nouvelle;

  update enfants set classe = p_classe where id = p_enfant;

  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  values (p_enfant, auth.uid(), 'passage_de_classe', 'annees_enfant', v_nouvelle,
          jsonb_build_object('classe', p_classe, 'annee', p_annee_scolaire));

  return v_nouvelle;
end;
$$;


--
-- Name: peut_composer_l_equipe(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.peut_composer_l_equipe(p_enfant uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select definit_l_autorite_parentale(p_enfant);
$$;


--
-- Name: peut_composer_le_fil(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.peut_composer_le_fil(p_fil uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from fils f
    where f.id = p_fil
      and (
        f.cree_par = auth.uid()
        or est_intervenant(f.enfant_id, array['parent']::role_intervenant[])
      )
  );
$$;


--
-- Name: peut_ouvrir_un_dossier(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.peut_ouvrir_un_dossier() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from profils p
    where p.id = auth.uid() and p.role_plateforme in ('referent', 'admin')
  );
$$;


--
-- Name: peut_valider(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.peut_valider(p_enfant uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select est_intervenant(p_enfant, array['parent', 'referent']::role_intervenant[]);
$$;


--
-- Name: pieces_exigees(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pieces_exigees() RETURNS public.type_piece_habilitation[]
    LANGUAGE sql IMMUTABLE
    AS $$
  -- PHASE PILOTE : aucune pièce exigée. Voir l'en-tête avant de modifier.
  select array[]::type_piece_habilitation[];
$$;


--
-- Name: FUNCTION pieces_exigees(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.pieces_exigees() IS 'Types de pièces sans lesquels une habilitation ne peut pas être accordée. Vide pendant le pilote — à renseigner avant la mise en production. Modifier ici et nulle part ailleurs.';


--
-- Name: pieces_manquantes(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pieces_manquantes(p_demande uuid) RETURNS public.type_piece_habilitation[]
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select coalesce(array_agg(t), array[]::type_piece_habilitation[])
  from unnest(pieces_exigees()) t
  where not exists (
    select 1 from habilitation_pieces p
    where p.demande_id = p_demande
      and p.type_piece = t
      -- Une pièce périmée ne compte pas : une attestation de 2019 ne prouve
      -- rien de 2026, et l'accepter viderait l'exigence de son sens.
      and (p.valable_jusqu_au is null or p.valable_jusqu_au >= current_date)
  );
$$;


--
-- Name: pieces_pour(smallint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pieces_pour(p_difficulte smallint) RETURNS integer
    LANGUAGE sql IMMUTABLE
    AS $$
  select case coalesce(p_difficulte, 3)
    when 1 then 2
    when 2 then 4
    when 3 then 6
    when 4 then 9
    else 12
  end;
$$;


--
-- Name: pieces_suffisantes(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pieces_suffisantes(p_acces uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select case a.nature
    when 'litige' then true
    when 'requisition' then exists (
      select 1 from acces_pieces p
      where p.acces_id = a.id
        and p.type_piece = 'requisition'
        and p.ecartee_le is null
    )
    else (
      select count(distinct p.emane_de)
      from acces_pieces p
      join intervenants_enfant i
        on i.profil_id = p.emane_de
       and i.enfant_id = a.enfant_id
       and i.role = 'parent'
       and i.retire_le is null
      where p.acces_id = a.id
        and p.type_piece = 'courrier_autorite_parentale'
        and p.ecartee_le is null
    ) >= e.titulaires_autorite_parentale
  end
  from acces_exceptionnels a
  join enfants e on e.id = a.enfant_id
  where a.id = p_acces;
$$;


--
-- Name: pilote_l_objectif(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pilote_l_objectif(p_objectif uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1
    from objectifs o
    join enfants e on e.id = o.enfant_id
    join intervenants_enfant i on i.enfant_id = o.enfant_id
    where o.id = p_objectif
      and i.profil_id = auth.uid()
      and i.retire_le is null
      and e.archive_le is null
      and (
        (o.matiere_code is not null
          and i.role = 'enseignant'
          and intervenant_couvre(i.id, o.matiere_code))
        or (o.domaine_code is not null and i.role = 'referent')
      )
  );
$$;


--
-- Name: programme_en_vigueur(public.niveau_classe, smallint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.programme_en_vigueur(p_classe public.niveau_classe, p_rentree smallint DEFAULT (EXTRACT(year FROM CURRENT_DATE))::smallint) RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select a.version_id
  from programme_applicable a
  where a.classe = p_classe
    and a.rentree_debut <= p_rentree
    and (a.rentree_fin is null or a.rentree_fin >= p_rentree)
  order by a.rentree_debut desc
  limit 1;
$$;


--
-- Name: progression_objectif(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.progression_objectif(p_objectif uuid) RETURNS TABLE(exercices_proposes bigint, reussites bigint, reussites_visees smallint, seuil_atteint boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    count(distinct e.id),
    count(distinct e.id) filter (where t.reussie),
    o.reussites_visees,
    count(distinct e.id) filter (where t.reussie) >= o.reussites_visees
  from objectifs o
  left join missions m on m.objectif_id = o.id
  left join exercices e on e.mission_id = m.id
  left join tentatives t on t.exercice_id = e.id and t.enfant_id = o.enfant_id
  where o.id = p_objectif
    and est_intervenant(o.enfant_id)
  group by o.id, o.reussites_visees;
$$;


--
-- Name: progression_quete(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.progression_quete(p_quete uuid) RETURNS TABLE(quete_id uuid, titre text, trimestre smallint, statut public.statut_quete, badges_vises bigint, badges_obtenus bigint, missions_total bigint, missions_reussies bigint, pieces_gagnees bigint, progression numeric)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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


--
-- Name: progression_vers(uuid, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.progression_vers(p_enfant uuid, p_points integer, p_missions integer, p_badges integer DEFAULT NULL::integer) RETURNS numeric
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select min(part) from (
    select case when p_points is null then null else
      least(100, round(100.0 * coalesce((select points_gagnes from points_enfant where enfant_id = p_enfant), 0) / p_points, 0))
    end as part
    union all
    select case when p_missions is null then null else
      least(100, round(100.0 * missions_reussies(p_enfant) / p_missions, 0))
    end
    union all
    select case when p_badges is null then null else
      least(100, round(100.0 * badges_de_l_annee(p_enfant) / p_badges, 0))
    end
  ) parts;
$$;


--
-- Name: proteger_l_archivage(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.proteger_l_archivage() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if (new.archive_le is distinct from old.archive_le
   or new.purge_prevue_le is distinct from old.purge_prevue_le
   or new.archive_par is distinct from old.archive_par)
   and current_setting('xylou.archivage', true) is distinct from 'en_cours' then
    raise exception 'Passez par archiver_le_dossier() ou desarchiver_le_dossier().';
  end if;
  return new;
end;
$$;


--
-- Name: proteger_la_composition_parentale(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.proteger_la_composition_parentale() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if new.titulaires_autorite_parentale is distinct from old.titulaires_autorite_parentale
     and auth.uid() is not null
     and not definit_l_autorite_parentale(new.id) then
    raise exception 'Seul le référent établit le nombre de titulaires de l''autorité parentale.';
  end if;
  return new;
end;
$$;


--
-- Name: proteger_la_page_de_l_enfant(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.proteger_la_page_de_l_enfant() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if est_l_enfant(new.enfant_id) then
    return new;
  end if;

  if new.humeur is distinct from old.humeur
  or new.recit is distinct from old.recit then
    raise exception 'L''humeur et le récit de la journée appartiennent à l''enfant. Écrivez une entrée pour dire ce que vous en observez.';
  end if;

  return new;
end;
$$;


--
-- Name: proteger_la_suppression_de_l_enfant(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.proteger_la_suppression_de_l_enfant() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if (
    select count(*) from intervenants_enfant i
    where i.enfant_id = old.id and i.role = 'parent' and i.retire_le is null
  ) > 1 then
    raise exception 'Deux titulaires de l''autorité parentale sont rattachés : archivez la fiche plutôt que de la supprimer, ou retirez-vous vous-même.';
  end if;
  return old;
end;
$$;


--
-- Name: proteger_le_compte_enfant(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.proteger_le_compte_enfant() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if new.compte_id is distinct from old.compte_id
     and auth.uid() is not null
     and not (peut_valider(new.id) or est_admin()) then
    raise exception 'Le compte d''un enfant est rattaché par ses parents ou son référent.';
  end if;
  return new;
end;
$$;


--
-- Name: proteger_le_lien_parental(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.proteger_le_lien_parental() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_profil uuid := coalesce(old.profil_id, new.profil_id);
  v_enfant uuid := coalesce(old.enfant_id, new.enfant_id);
  v_touche_un_parent boolean :=
    coalesce(old.role, new.role) = 'parent'
    or (tg_op = 'UPDATE' and new.role = 'parent');
begin
  if auth.uid() is null then
    if tg_op = 'DELETE' then return old; end if;
    return new;
  end if;

  if v_profil = auth.uid() then
    if tg_op = 'UPDATE'
       and new.role = 'parent'
       and old.role is distinct from 'parent' then
      raise exception 'On ne se déclare pas soi-même titulaire de l''autorité parentale.';
    end if;

  elsif v_touche_un_parent and not definit_l_autorite_parentale(v_enfant) then
    raise exception 'Seul le référent établit qui détient l''autorité parentale.';
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;


--
-- Name: proteger_le_role_plateforme(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.proteger_le_role_plateforme() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if new.role_plateforme is distinct from old.role_plateforme
     and auth.uid() is not null
     and not est_admin() then
    raise exception 'La qualité d''un compte est établie par l''administration.';
  end if;
  return new;
end;
$$;


--
-- Name: proteger_le_statut_de_la_quete(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.proteger_le_statut_de_la_quete() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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


--
-- Name: proteger_les_cases_de_l_enfant(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.proteger_les_cases_de_l_enfant() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_enfant uuid;
begin
  select j.enfant_id into v_enfant from journees j where j.id = new.journee_id;

  if new.faite_le is distinct from old.faite_le
     and not (est_l_enfant(v_enfant) or peut_valider(v_enfant)) then
    raise exception 'Cocher une étape revient à l''enfant, ou à ceux qui l''accompagnent de près.';
  end if;

  return new;
end;
$$;


--
-- Name: purge_prevue(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.purge_prevue(p_enfant uuid) RETURNS date
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select (e.archive_le + duree_conservation())::date
  from enfants e where e.id = p_enfant and e.archive_le is not null;
$$;


--
-- Name: purger_le_dossier(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.purger_le_dossier(p_enfant uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_prenom text;
  v_due date;
begin
  if not est_admin() then
    raise exception 'La purge revient à l''administration.';
  end if;

  select prenom into v_prenom from enfants
  where id = p_enfant and archive_le is not null;

  if v_prenom is null then
    raise exception 'Ce dossier n''existe pas, ou n''est pas masqué.';
  end if;

  v_due := purge_prevue(p_enfant);

  if v_due is null or v_due > current_date then
    raise exception 'Le terme de conservation n''est pas atteint : purge due le %.', v_due;
  end if;

  -- Consigner d'abord. Après les suppressions, il n'y aurait plus de quoi
  -- écrire, et une transaction qui échouerait entre les deux laisserait un
  -- dossier effacé sans justification.
  update suppressions_effectuees
    set purgee_le = now()
    where enfant_id = p_enfant and purgee_le is null;

  if not found then
    insert into suppressions_effectuees
      (enfant_id, prenom, motif, masquee_par, masquee_le, purge_prevue_le, purgee_le)
    select p_enfant, coalesce(v_prenom, ''),
           coalesce(nullif(e.motif_archivage, ''), 'Archivage arrivé à terme'),
           e.archive_par, e.archive_le, e.purge_prevue_le, now()
    from enfants e where e.id = p_enfant;
  end if;

  update demandes_suppression
    set statut = 'purgee', purgee_le = now()
    where enfant_id = p_enfant and statut = 'masquee';

  delete from intervenants_enfant where enfant_id = p_enfant;
  delete from enfants where id = p_enfant;
end;
$$;


--
-- Name: raisons_de_ne_pas_generer(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.raisons_de_ne_pas_generer(p_enfant uuid) RETURNS text[]
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select coalesce(array_agg(r order by ordre), '{}')
  from (
    -- Sans pré-bilan, la génération produirait un bilan standard et mesurerait
    -- le handicap de l'enfant plutôt que ses savoirs.
    select 1 as ordre,
           'Le pré-bilan n''a pas été rempli.' as r
    where not exists (
      select 1 from observations_capacites o
      where o.enfant_id = p_enfant and o.statut = 'complete'
    )

    union all

    select 2, 'L''autorisation de génération assistée n''est pas signée.'
    where not consentement_actif(p_enfant, 'generation_ia')

    union all

    -- Pas un blocage de principe, un blocage de fait : la file traite déjà
    -- cette demande, en déposer une seconde violerait l'index unique.
    select 3, 'Une génération est déjà en cours pour cet enfant.'
    where exists (
      select 1 from generations_bilan g
      where g.enfant_id = p_enfant
        and g.statut in ('en_attente', 'en_cours')
    )

    union all

    select 4, 'Un bilan est déjà ouvert pour cet enfant.'
    where exists (
      select 1 from bilans_positionnement b
      where b.enfant_id = p_enfant and b.statut = 'en_cours'
    )
  ) as raisons;
$$;


--
-- Name: recompenses_a_venir(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.recompenses_a_venir(p_enfant uuid) RETURNS TABLE(recompense_id uuid, libelle text, description text, photo_chemin text, prevue_le date, jours_restants integer, horizon public.horizon_recompense, points_requis integer, points_actuels integer, missions_requises integer, missions_actuelles integer, badges_requis integer, badges_actuels integer, progression numeric, condition text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    r.id,
    case when r.devoilee_le is not null or r.montrer_nature
         then r.libelle
         else coalesce(pm.surprise_libelle, 'Une surprise') end,
    case when r.devoilee_le is not null or r.montrer_nature then r.description else '' end,
    case when r.devoilee_le is not null or r.montrer_nature then r.photo_chemin else null end,
    case when r.devoilee_le is not null or r.montrer_date then r.prevue_le else null end,
    case when r.devoilee_le is not null or r.montrer_date
         then (r.prevue_le - current_date)::integer else null end,
    case when r.devoilee_le is not null or r.montrer_date
         then horizon_de(r.prevue_le) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.points_requis else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then coalesce(p.points_gagnes, 0) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.missions_requises else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then missions_reussies(p_enfant) else null end,
    case when r.devoilee_le is not null or r.montrer_progression then r.badges_requis else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then badges_de_l_annee(p_enfant) else null end,
    case when r.devoilee_le is not null or r.montrer_progression
         then progression_vers(p_enfant, r.points_requis, r.missions_requises, r.badges_requis)
         else null end,
    r.condition
  from recompenses_familiales r
  left join points_enfant p on p.enfant_id = r.enfant_id
  left join projets_moteurs pm on pm.enfant_id = r.enfant_id and pm.actif
  where r.enfant_id = p_enfant
    and r.statut = 'promise'
    and (r.montrer_existence or r.devoilee_le is not null)
    and (est_intervenant(p_enfant) or est_l_enfant(p_enfant))
  order by r.prevue_le nulls last;
$$;


--
-- Name: referents_du_dossier(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.referents_du_dossier(p_enfant uuid) RETURNS TABLE(profil_id uuid, prenom text, nom text, email text, fonction text, principal boolean, designe_le timestamp with time zone, habilitation_jusqu_au date)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select p.id, p.prenom, p.nom, p.email, i.fonction, i.principal, i.designe_le,
         (select d.valable_jusqu_au from demandes_habilitation d
          where d.profil_id = p.id and d.statut = 'acceptee'
          order by d.traitee_le desc limit 1)
  from intervenants_enfant i
  join profils p on p.id = i.profil_id
  where i.enfant_id = p_enfant
    and i.role = 'referent'
    and i.retire_le is null
    and est_intervenant(p_enfant)
  order by i.principal desc, p.nom;
$$;


--
-- Name: refuser_l_habilitation(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.refuser_l_habilitation(p_demande uuid, p_motif text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_profil uuid;
begin
  if not est_admin() then
    raise exception 'L''instruction des demandes revient à l''administration.';
  end if;

  if length(btrim(p_motif)) < 10 then
    raise exception 'Un refus se motive : la personne doit savoir ce qui manquait pour revenir avec.';
  end if;

  select profil_id into v_profil
  from demandes_habilitation
  where id = p_demande and statut = 'en_attente';

  if v_profil is null then
    raise exception 'Demande introuvable ou déjà instruite.';
  end if;

  update demandes_habilitation
    set statut = 'refusee', traitee_par = auth.uid(), traitee_le = now(),
        motif = btrim(p_motif)
    where id = p_demande;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  values (v_profil, null, 'habilitation_traitee',
          'Votre demande d''habilitation n''a pas été retenue',
          btrim(p_motif),
          '/habilitation');
end;
$$;


--
-- Name: refuser_la_note_sur_un_devoir(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.refuser_la_note_sur_un_devoir() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if auth.uid() is null then
    return new;
  end if;

  if not (
    mission_relevant_de_l_enseignant(new.mission_id)
    or est_intervenant(enfant_de_la_mission(new.mission_id),
                       array['referent']::role_intervenant[])
  ) then
    raise exception 'La note est portée par l''enseignant de la matière, ou par le référent.';
  end if;

  return new;
end;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: envois; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.envois (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    notification_id uuid,
    destinataire_id uuid NOT NULL,
    canal public.canal_envoi NOT NULL,
    adresse text NOT NULL,
    sujet text DEFAULT ''::text NOT NULL,
    corps text DEFAULT ''::text NOT NULL,
    lien text DEFAULT ''::text NOT NULL,
    statut public.statut_envoi DEFAULT 'a_envoyer'::public.statut_envoi NOT NULL,
    tentatives smallint DEFAULT 0 NOT NULL,
    derniere_erreur text DEFAULT ''::text NOT NULL,
    envoye_le timestamp with time zone,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    reserve_le timestamp with time zone
);


--
-- Name: reserver_envois(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reserver_envois(p_lot integer DEFAULT 50, p_tentatives_max integer DEFAULT 5) RETURNS SETOF public.envois
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  update envois e
  set reserve_le = now()
  where e.id in (
    select c.id
    from envois c
    where c.canal = 'courriel'
      -- On reprend aussi les échecs récupérables : un envoi raté une fois doit
      -- repartir, sinon la file se remplit d'attentes que rien ne relance.
      and (
        c.statut = 'a_envoyer'
        or (c.statut = 'echec' and c.tentatives < p_tentatives_max)
      )
      and (c.reserve_le is null or c.reserve_le < now() - interval '5 minutes')
    order by c.cree_le
    limit p_lot
    for update skip locked
  )
  returning e.*;
$$;


--
-- Name: generations_bilan; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.generations_bilan (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    bilan_id uuid,
    classe_reference public.niveau_classe,
    matieres text[] DEFAULT '{}'::text[] NOT NULL,
    statut public.statut_generation DEFAULT 'en_attente'::public.statut_generation NOT NULL,
    tentatives smallint DEFAULT 0 NOT NULL,
    derniere_erreur text DEFAULT ''::text NOT NULL,
    reserve_le timestamp with time zone,
    cout_centimes numeric(10,4) DEFAULT 0 NOT NULL,
    demande_par uuid NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    terminee_le timestamp with time zone
);


--
-- Name: reserver_generations(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reserver_generations(p_lot integer DEFAULT 5, p_tentatives_max integer DEFAULT 3) RETURNS SETOF public.generations_bilan
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  update generations_bilan g
  set statut = 'en_cours',
      reserve_le = now(),
      tentatives = g.tentatives + 1
  where g.id in (
    select c.id
    from generations_bilan c
    where (
        c.statut = 'en_attente'
        or (c.statut = 'echec' and c.tentatives < p_tentatives_max)
        -- Une réservation abandonnée — processus tué, déploiement au mauvais
        -- moment — doit repartir. Vingt minutes : une génération longue tient
        -- largement dedans, un traitement mort n'attend pas la journée.
        or (c.statut = 'en_cours' and c.reserve_le < now() - interval '20 minutes')
      )
    order by c.cree_le
    limit p_lot
    for update skip locked
  )
  returning g.*;
$$;


--
-- Name: restreindre_l_ecartement_de_piece(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restreindre_l_ecartement_de_piece() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  if new.acces_id   is distinct from old.acces_id
  or new.type_piece is distinct from old.type_piece
  or new.emane_de   is distinct from old.emane_de
  or new.chemin     is distinct from old.chemin
  or new.nom        is distinct from old.nom
  or new.depose_par is distinct from old.depose_par
  or new.depose_le  is distinct from old.depose_le then
    raise exception 'Une pièce ne se corrige pas : écartez-la en motivant, puis versez-en une autre. Les deux resteront visibles.';
  end if;

  if old.ecartee_le is not null then
    raise exception 'Cette pièce a déjà été écartée.';
  end if;

  return new;
end;
$$;


--
-- Name: restreindre_la_composition_de_mission(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restreindre_la_composition_de_mission() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_professionnel boolean;
begin
  if auth.uid() is null then
    return new;
  end if;

  v_professionnel :=
    est_intervenant(new.enfant_id, array['referent']::role_intervenant[])
    or mission_ouverte_a_l_enseignant(new.id)
    or mission_relevant_de_l_enseignant(new.id);

  if v_professionnel then
    return new;
  end if;

  -- La nature ne se change pas. Sans ce verrou, il suffirait de requalifier en
  -- devoir l'évaluation d'un enseignant pour en réécrire le contenu.
  if new.nature is distinct from old.nature then
    raise exception 'La nature d''un travail est fixée à sa création : un entraînement ne devient pas un devoir, ni l''inverse.';
  end if;

  -- Un devoir saisi par la famille lui reste ouvert. Elle l'a transcrit, elle
  -- peut le corriger — une consigne recopiée de travers se répare le soir même,
  -- et attendre l'enseignant reviendrait à perdre la soirée de travail.
  if old.nature::text = 'devoir' and peut_valider(new.enfant_id) then
    return new;
  end if;

  if new.titre             is distinct from old.titre
  or new.intitule_narratif is distinct from old.intitule_narratif
  or new.difficulte        is distinct from old.difficulte
  or new.points            is distinct from old.points
  or new.tentatives_max    is distinct from old.tentatives_max
  or new.indices_autorises is distinct from old.indices_autorises
  or new.matiere_code      is distinct from old.matiere_code
  or new.domaine_code      is distinct from old.domaine_code
  or new.objectif_id       is distinct from old.objectif_id
  or new.auteur_id         is distinct from old.auteur_id then
    raise exception 'Le contenu d''une mission est composé par l''enseignant de la matière, ou par le référent. Vous pouvez la valider, la refuser, ou demander qu''elle soit revue.';
  end if;

  return new;
end;
$$;


--
-- Name: restreindre_le_pilotage(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restreindre_le_pilotage() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_pilote boolean;
  v_auteur boolean;
begin
  -- Contexte de confiance (SQL Editor, clé de service) : rien à arbitrer.
  if auth.uid() is null then
    return new;
  end if;

  v_pilote := (new.granularite = 'fin' and pilote_l_objectif(new.id))
              or pilote_l_objectif(new.id);
  v_auteur := old.propose_par = auth.uid() and old.statut = 'propose';

  -- --------------------------------------------------------------- contenu
  -- Réécrire la formulation d'un objectif déjà validé revient à changer ce que
  -- la famille a accepté sans le lui redemander. Seul son auteur y touche, et
  -- seulement tant que personne n'a signé.
  if new.libelle            is distinct from old.libelle
  or new.description        is distinct from old.description
  or new.matiere_code       is distinct from old.matiere_code
  or new.domaine_code       is distinct from old.domaine_code
  or new.granularite        is distinct from old.granularite
  or new.objectif_parent_id is distinct from old.objectif_parent_id
  or new.repere_id          is distinct from old.repere_id
  or new.enfant_id          is distinct from old.enfant_id then
    if not v_auteur then
      raise exception 'La formulation d''un objectif appartient à qui l''a proposé, et se fige dès qu''il est signé. Ouvrez une demande de modification.';
    end if;
  end if;

  -- --------------------------------------------------------------- cadence
  -- Le réglage fin revient au pilote. Un parent qui trouve le rythme trop
  -- soutenu le dit à l'enseignant ; il ne baisse pas le compteur lui-même.
  if new.debute_le        is distinct from old.debute_le
  or new.echeance_le      is distinct from old.echeance_le
  or new.exercices_vises  is distinct from old.exercices_vises
  or new.reussites_visees is distinct from old.reussites_visees
  or new.critere_fin      is distinct from old.critere_fin
  or new.trimestre        is distinct from old.trimestre
  or new.annee_id         is distinct from old.annee_id then
    if not (v_pilote or v_auteur) then
      raise exception 'La période, le nombre d''exercices et le critère de fin sont réglés par l''enseignant de la matière — ou par le référent pour un domaine transversal.';
    end if;
  end if;

  -- ---------------------------------------------------------- trajectoire
  -- Valider, abandonner, déclarer atteint : cela engage l'enfant, et cela
  -- revient à la famille. Le quorum de 0023 et les signatures de 0022
  -- continuent de gouverner l'entrée dans « validé » ; ici on vérifie
  -- seulement que la décision vient du bon cercle.
  if new.statut     is distinct from old.statut
  or new.valide_par is distinct from old.valide_par
  or new.valide_le  is distinct from old.valide_le
  or new.atteint_le is distinct from old.atteint_le then
    if not (peut_valider(new.enfant_id) or v_pilote) then
      raise exception 'Le statut d''un objectif se décide par la famille, le référent, ou l''enseignant qui le pilote.';
    end if;
  end if;

  return new;
end;
$$;


--
-- Name: resultats_par_matiere(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.resultats_par_matiere(p_enfant uuid) RETURNS TABLE(matiere_code text, libelle text, emoji text, badge_niveau smallint, objectifs_en_cours bigint, objectifs_atteints bigint, missions_reussies bigint, exercices_reussis bigint, exercices_tentes bigint, taux_reussite numeric, note_moyenne numeric, alertes_ouvertes bigint, pieces_gagnees bigint)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    m.code,
    m.libelle,
    m.emoji,
    coalesce((
      select max(b.niveau) from badges_obtenus b
      where b.enfant_id = p_enfant and b.matiere_code = m.code
    ), 0::smallint),
    (select count(*) from objectifs o
      where o.enfant_id = p_enfant and o.matiere_code = m.code
        and o.statut = 'valide'),
    (select count(*) from objectifs o
      where o.enfant_id = p_enfant and o.matiere_code = m.code
        and o.statut = 'atteint'),
    (select count(*) from missions mi
      where mi.enfant_id = p_enfant and mi.matiere_code = m.code
        and mi.statut = 'reussie'),
    (select count(distinct t.exercice_id) from tentatives t
      join exercices e on e.id = t.exercice_id
      join missions mi on mi.id = e.mission_id
      where t.enfant_id = p_enfant and mi.matiere_code = m.code and t.reussie),
    (select count(distinct t.exercice_id) from tentatives t
      join exercices e on e.id = t.exercice_id
      join missions mi on mi.id = e.mission_id
      where t.enfant_id = p_enfant and mi.matiere_code = m.code),
    (select case when count(distinct t.exercice_id) = 0 then null
                 else round(100.0 * count(distinct t.exercice_id) filter (where t.reussie)
                            / count(distinct t.exercice_id), 0) end
      from tentatives t
      join exercices e on e.id = t.exercice_id
      join missions mi on mi.id = e.mission_id
      where t.enfant_id = p_enfant and mi.matiere_code = m.code),
    -- Ramenée sur 20, pour être comparable d'un barème à l'autre.
    (select round(avg(20.0 * n.note / n.bareme), 1)
      from notations n
      join missions mi on mi.id = n.mission_id
      where mi.enfant_id = p_enfant and mi.matiere_code = m.code and n.note is not null),
    (select count(*) from alertes_difficulte a
      join reperes_competences r on r.id = a.repere_id
      where a.enfant_id = p_enfant and r.matiere_code = m.code and a.statut = 'ouverte'),
    (select coalesce(sum(g.pieces), 0) from pieces_gagnees g
      left join exercices e on e.id = g.exercice_id
      left join missions mi on mi.id = coalesce(e.mission_id, g.mission_id)
      where g.enfant_id = p_enfant and mi.matiere_code = m.code)
  from matieres m
  where est_intervenant(p_enfant)
    and matiere_ouverte_a_l_ecriture(p_enfant, m.code)
    -- Seulement les matières où il se passe quelque chose. Afficher les dix
    -- matières du référentiel pour un enfant qui en travaille trois
    -- transformerait un tableau de progrès en tableau de manques.
    and exists (
      select 1 from objectifs o
      where o.enfant_id = p_enfant and o.matiere_code = m.code
    )
  order by m.ordre;
$$;


--
-- Name: retirer_l_habilitation(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.retirer_l_habilitation(p_profil uuid, p_motif text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if not est_admin() then
    raise exception 'Le retrait d''une habilitation revient à l''administration.';
  end if;

  if length(btrim(p_motif)) < 10 then
    raise exception 'Le retrait d''une habilitation se motive.';
  end if;

  update profils set role_plateforme = 'membre'
    where id = p_profil and role_plateforme = 'referent';

  update demandes_habilitation
    set statut = 'retiree', traitee_par = auth.uid(), traitee_le = now(),
        motif = btrim(p_motif)
    where profil_id = p_profil and statut = 'acceptee';

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  values (p_profil, null, 'habilitation_traitee',
          'Votre habilitation de référent a été retirée',
          btrim(p_motif), '/tableau-de-bord');
end;
$$;


--
-- Name: retirer_l_intervenant(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.retirer_l_intervenant(p_enfant uuid, p_profil uuid, p_motif text DEFAULT ''::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_role role_intervenant;
begin
  select role into v_role
  from intervenants_enfant
  where enfant_id = p_enfant and profil_id = p_profil and retire_le is null;

  if v_role is null then
    raise exception 'Cette personne n''est pas rattachée à ce dossier.';
  end if;

  -- Le lien parental relève de 0024 et 0025 : il ne se défait pas par ici.
  if v_role = 'parent' then
    raise exception 'Le rattachement d''un titulaire de l''autorité parentale ne se retire pas de cette façon.';
  end if;

  if not (definit_l_autorite_parentale(p_enfant) or p_profil = auth.uid()) then
    raise exception 'Retirer un intervenant revient au référent du dossier, ou à l''intéressé lui-même.';
  end if;

  update intervenants_enfant
    set retire_le = now(), motif_retrait = p_motif
    where enfant_id = p_enfant and profil_id = p_profil and retire_le is null;
end;
$$;


--
-- Name: seuil_badge(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.seuil_badge() RETURNS numeric
    LANGUAGE sql IMMUTABLE
    AS $$ select 70::numeric; $$;


--
-- Name: signaler_le_palier_atteint(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.signaler_le_palier_atteint() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_compte uuid;
begin
  if new.statut <> 'atteinte' or old.statut = 'atteinte' then
    return new;
  end if;

  insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
  select i.profil_id, new.enfant_id, 'recompense_atteinte',
         'Récompense atteinte : ' || new.libelle,
         'Prévue le ' || to_char(new.prevue_le, 'DD/MM/YYYY') || '.',
         '/enfants/' || new.enfant_id || '/recompenses/' || new.id
  from intervenants_enfant i
  where i.enfant_id = new.enfant_id
    and i.retire_le is null
    and i.role in ('parent', 'referent');

  select compte_id into v_compte from enfants where id = new.enfant_id;

  if v_compte is not null then
    insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
    values (v_compte, new.enfant_id, 'recompense_atteinte',
            'Tu as gagné : ' || new.libelle, '',
            '/mes-recompenses/' || new.id);
  end if;

  return new;
end;
$$;


--
-- Name: signaler_le_palier_franchi(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.signaler_le_palier_franchi() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_rec record;
  v_points integer;
begin
  if not new.reussie then
    return new;
  end if;

  select points_gagnes into v_points from points_enfant where enfant_id = new.enfant_id;

  for v_rec in
    select r.id, r.libelle, r.montrer_nature, r.devoilee_le
    from recompenses_familiales r
    where r.enfant_id = new.enfant_id
      and r.statut = 'promise'
      -- Toutes les conditions chiffrées renseignées doivent être remplies.
      and (r.points_requis is not null or r.missions_requises is not null)
      and (r.points_requis is null or r.points_requis <= coalesce(v_points, 0))
      and (r.missions_requises is null
           or r.missions_requises <= missions_reussies(new.enfant_id))
      and not exists (
        select 1 from notifications n
        where n.enfant_id = new.enfant_id
          and n.type = 'recompense_approche'
          and n.corps = r.id::text
      )
  loop
    insert into notifications (destinataire_id, enfant_id, type, titre, corps, lien)
    select i.profil_id, new.enfant_id, 'recompense_approche',
           case when v_rec.montrer_nature or v_rec.devoilee_le is not null
                then 'Palier atteint : ' || v_rec.libelle
                else 'Palier atteint — une surprise attend d''être dévoilée' end,
           v_rec.id::text,
           '/enfants/' || new.enfant_id || '/recompenses/' || v_rec.id
    from intervenants_enfant i
    where i.enfant_id = new.enfant_id
      and i.retire_le is null
      and i.role in ('parent', 'referent');
  end loop;

  return new;
end;
$$;


--
-- Name: signer_les_consentements(uuid, public.type_consentement[], text, public.type_consentement[], inet, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.signer_les_consentements(p_enfant uuid, p_types public.type_consentement[], p_signature text, p_refuses public.type_consentement[] DEFAULT '{}'::public.type_consentement[], p_ip inet DEFAULT NULL::inet, p_agent text DEFAULT ''::text) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_type type_consentement;
  v_texte textes_consentement%rowtype;
  v_compte integer := 0;
begin
  if not est_intervenant(p_enfant, array['parent']::role_intervenant[]) then
    raise exception 'Seuls les titulaires de l''autorité parentale signent les autorisations.';
  end if;

  if length(btrim(p_signature)) < 2 then
    raise exception 'La signature ne peut pas être vide.';
  end if;

  foreach v_type in array p_types loop
    select * into v_texte from textes_consentement
    where type = v_type and retire_le is null
    order by publie_le desc limit 1;

    if not found then
      raise exception 'Aucun texte en vigueur pour cette autorisation : %', v_type;
    end if;

    insert into consentements
      (enfant_id, profil_id, type, accorde, version_texte, texte_id,
       signature_nom, adresse_ip, agent)
    values
      (p_enfant, auth.uid(), v_type, true, v_texte.version, v_texte.id,
       btrim(p_signature), p_ip, p_agent);

    v_compte := v_compte + 1;
  end loop;

  -- Le refus reste enregistrable, et reste refusé pour un texte indispensable.
  -- Les quatre le sont désormais, donc cette boucle lève systématiquement. On la
  -- garde : elle redeviendra utile le jour où un texte optionnel existera, et
  -- elle énonce la règle au lieu de la laisser supposer.
  foreach v_type in array p_refuses loop
    select * into v_texte from textes_consentement
    where type = v_type and retire_le is null
    order by publie_le desc limit 1;

    if found and v_texte.obligatoire then
      raise exception 'Cette autorisation conditionne l''usage de l''outil et ne peut pas être refusée : %', v_type;
    end if;

    insert into consentements
      (enfant_id, profil_id, type, accorde, version_texte, texte_id, adresse_ip, agent)
    values
      (p_enfant, auth.uid(), v_type, false, coalesce(v_texte.version, ''), v_texte.id, p_ip, p_agent);
  end loop;

  return v_compte;
end;
$$;


--
-- Name: sonner_la_file(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sonner_la_file() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_url text;
  v_secret text;
begin
  select decrypted_secret into v_url
    from vault.decrypted_secrets where name = 'xylou_url_envois';
  select decrypted_secret into v_secret
    from vault.decrypted_secrets where name = 'xylou_cron_secret';

  if v_url is null or v_secret is null then
    return null;
  end if;

  -- Asynchrone : la transaction qui vient d'écrire dans la file ne l'attend pas.
  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_secret
    ),
    timeout_milliseconds := 60000
  );

  return null;
end;
$$;


--
-- Name: sonner_les_generations(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sonner_les_generations() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_url text;
  v_secret text;
begin
  select decrypted_secret into v_url
    from vault.decrypted_secrets where name = 'xylou_url_generations';
  select decrypted_secret into v_secret
    from vault.decrypted_secrets where name = 'xylou_cron_secret';

  if v_url is null or v_secret is null then
    return null;
  end if;

  perform net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || v_secret
    ),
    timeout_milliseconds := 60000
  );

  return null;
end;
$$;


--
-- Name: supports_sans_provenance(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.supports_sans_provenance(p_enfant uuid) RETURNS TABLE(support_id uuid, titre text, matiere_code text, type_support public.type_support, depose_par_prenom text, cree_le timestamp with time zone, missions_issues bigint)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    s.id, s.titre, s.matiere_code, s.type_support,
    coalesce(p.prenom, ''), s.cree_le,
    (select count(*) from missions m
     join adaptations a on a.id = m.adaptation_id
     where a.support_id = s.id)
  from supports s
  left join profils p on p.id = s.depose_par
  where s.enfant_id = p_enfant
    and s.fourni_par is null
    -- Déposé par quelqu'un qui n'enseigne pas la matière : c'est le cas d'une
    -- famille qui scanne. Un enseignant qui dépose son propre cours n'a rien à
    -- attribuer, il est déjà la provenance.
    and not exists (
      select 1 from intervenants_enfant i
      where i.enfant_id = p_enfant
        and i.profil_id = s.depose_par
        and i.retire_le is null
        and i.role = 'enseignant'
        and intervenant_couvre(i.id, s.matiere_code)
    )
    and est_intervenant(p_enfant)
  group by s.id, s.titre, s.matiere_code, s.type_support, p.prenom, s.cree_le
  order by s.cree_le desc;
$$;


--
-- Name: suppressions_en_cours(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.suppressions_en_cours() RETURNS TABLE(demande_id uuid, enfant_id uuid, enfant text, motif text, statut public.statut_suppression, demandee_par_prenom text, accords bigint, titulaires bigint, purge_prevue_le date, depuis_jours integer)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select
    d.id, d.enfant_id, nom_affiche(coalesce(e.prenom, ''), e.nom), d.motif, d.statut,
    coalesce(p.prenom, ''),
    (select count(*) from suppressions_accords a where a.demande_id = d.id),
    (select count(*) from intervenants_enfant i
      where i.enfant_id = d.enfant_id and i.role = 'parent' and i.retire_le is null),
    d.purge_prevue_le,
    (current_date - d.cree_le::date)::integer
  from demandes_suppression d
  left join enfants e on e.id = d.enfant_id
  left join profils p on p.id = d.demandee_par
  where d.statut in ('en_attente', 'accordee', 'masquee')
    and est_admin()
  order by d.statut, d.cree_le;
$$;


--
-- Name: tentative_ouverte_a_l_enseignant(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.tentative_ouverte_a_l_enseignant(p_tentative uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select exists (
    select 1 from tentatives t
    where t.id = p_tentative and exercice_relevant_de_l_enseignant(t.exercice_id)
  );
$$;


--
-- Name: touch_modifie_le(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.touch_modifie_le() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.modifie_le = now();
  return new;
end;
$$;


--
-- Name: tracer_la_correction_administrative(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.tracer_la_correction_administrative() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_enfant uuid;
  v_ligne uuid;
begin
  if not est_admin() then
    return null;
  end if;

  if tg_op = 'DELETE' then
    v_ligne := old.id;
    v_enfant := case tg_table_name when 'enfants' then old.id else old.enfant_id end;
  else
    v_ligne := new.id;
    v_enfant := case tg_table_name when 'enfants' then new.id else new.enfant_id end;
  end if;

  insert into journal_acces (enfant_id, profil_id, action, table_cible, ligne_id, detail)
  values (
    v_enfant,
    auth.uid(),
    'correction_administrative',
    tg_table_name,
    v_ligne,
    jsonb_build_object('operation', tg_op)
  );

  return null;
end;
$$;


--
-- Name: type_notifie_hors_application(public.type_notification); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.type_notifie_hors_application(p_type public.type_notification) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $$
  select p_type in (
    'message',
    'objectif_propose',
    'objectif_modification_demandee',
    'mission_a_valider',
    'difficulte_repetee',
    'bilan_pret',
    'invitation',
    'acces_exceptionnel',
    'habilitation_demandee',
    'habilitation_traitee',
    'quete_reussie'
  );
$$;


--
-- Name: types_notifies_hors_application(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.types_notifies_hors_application() RETURNS SETOF public.type_notification
    LANGUAGE sql STABLE
    AS $$
  -- `enum_range` énumère le type Postgres lui-même : la liste suit les
  -- `alter type … add value` à venir sans qu'on ait à y repenser.
  select t
  from unnest(enum_range(null::type_notification)) as t
  where type_notifie_hors_application(t)
  order by t;
$$;


--
-- Name: uuid_ou_null(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.uuid_ou_null(p_texte text) RETURNS uuid
    LANGUAGE plpgsql IMMUTABLE
    AS $$
begin
  return p_texte::uuid;
exception when others then
  return null;
end;
$$;


--
-- Name: valideurs_manquants(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.valideurs_manquants(p_objectif uuid) RETURNS TABLE(profil_id uuid, prenom text, nom text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select p.id, p.prenom, p.nom
  from valideurs_requis(p_objectif) r
  join profils p on p.id = r.profil_id
  where not exists (
    select 1 from objectifs_validations v
    where v.objectif_id = p_objectif and v.profil_id = r.profil_id
  )
    and est_intervenant((select enfant_id from objectifs where id = p_objectif));
$$;


--
-- Name: valideurs_requis(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.valideurs_requis(p_objectif uuid) RETURNS TABLE(profil_id uuid)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
  select i.profil_id
  from objectifs o
  join intervenants_enfant i on i.enfant_id = o.enfant_id
  where o.id = p_objectif
    and i.retire_le is null
    and (
      i.role = 'parent'
      or (i.role = 'referent' and i.principal and o.matiere_code is not null)
    );
$$;


--
-- Name: verifier_l_acquisition(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verifier_l_acquisition() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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


--
-- Name: verifier_la_validation_de_l_objectif(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verifier_la_validation_de_l_objectif() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
  if new.statut <> 'valide' then
    return new;
  end if;
  if tg_op = 'UPDATE' and old.statut = 'valide' then
    return new;
  end if;

  -- Sans utilisateur connecté, il n'y a personne pour signer : la vérification
  -- de signature n'a pas d'objet. Le quorum, lui, s'applique toujours.
  if auth.uid() is null then
    return new;
  end if;

  if new.valide_par is distinct from auth.uid() then
    raise exception 'Qui valide un objectif le signe : valide_par doit être le compte qui écrit.';
  end if;

  if new.domaine_code is not null
     and not est_intervenant(new.enfant_id, array['parent']::role_intervenant[]) then
    raise exception 'Un objectif transversal est validé par un titulaire de l''autorité parentale. Le référent le pilote, il ne l''arbitre pas.';
  end if;

  return new;
end;
$$;


--
-- Name: verifier_le_fournisseur(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verifier_le_fournisseur() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_libelle text;
  v_candidats integer;
begin
  -- Un devoir doit dire de qui il vient. Les autres natures n'y sont pas
  -- tenues : un entraînement composé par le référent n'a pas d'enseignant
  -- derrière lui, et l'exiger bloquerait le transversal.
  if new.nature::text = 'devoir' and new.fourni_par is null then
    select libelle into v_libelle from matieres where code = new.matiere_code;

    select count(*) into v_candidats
    from intervenants_enfant i
    where i.enfant_id = new.enfant_id
      and i.retire_le is null
      and i.role = 'enseignant'
      and (new.matiere_code is null or intervenant_couvre(i.id, new.matiere_code));

    if v_candidats = 0 then
      raise exception 'Aucun enseignant de % n''est rattaché au dossier. Un devoir vient de l''école : sans savoir de qui, personne ne pourra en lire les copies ni le corriger. Invitez l''enseignant, ou demandez au référent de le faire.',
        coalesce(v_libelle, 'cette matière');
    else
      raise exception 'Indiquez l''enseignant dont vient ce devoir : il est le seul à pouvoir en lire les copies et le noter.';
    end if;
  end if;

  if new.fourni_par is null then
    return new;
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    where i.enfant_id = new.enfant_id
      and i.profil_id = new.fourni_par
      and i.retire_le is null
      and i.role = 'enseignant'
      and (new.matiere_code is null or intervenant_couvre(i.id, new.matiere_code))
  ) then
    raise exception 'Le travail doit être attribué à un enseignant de cette matière, rattaché à l''enfant.';
  end if;

  return new;
end;
$$;


--
-- Name: verifier_le_fournisseur_du_support(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verifier_le_fournisseur_du_support() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_libelle text;
  v_candidats integer;
begin
  if new.type_support in ('devoir', 'evaluation') and new.fourni_par is null then
    -- Sauf si celui qui dépose est lui-même l'enseignant de la matière : il est
    -- alors la provenance, et se désigner soi-même serait une formalité vide.
    if exists (
      select 1 from intervenants_enfant i
      where i.enfant_id = new.enfant_id
        and i.profil_id = new.depose_par
        and i.retire_le is null
        and i.role = 'enseignant'
        and intervenant_couvre(i.id, new.matiere_code)
    ) then
      new.fourni_par := new.depose_par;
      return new;
    end if;

    select libelle into v_libelle from matieres where code = new.matiere_code;

    select count(*) into v_candidats
    from intervenants_enfant i
    where i.enfant_id = new.enfant_id
      and i.retire_le is null
      and i.role = 'enseignant'
      and intervenant_couvre(i.id, new.matiere_code);

    if v_candidats = 0 then
      raise exception 'Aucun enseignant de % n''est rattaché au dossier. Ce document vient de l''école : sans savoir de qui, personne ne pourra en lire les résultats. Invitez l''enseignant, ou demandez au référent de le faire.',
        coalesce(v_libelle, 'cette matière');
    else
      raise exception 'Indiquez l''enseignant dont vient ce document.';
    end if;
  end if;

  if new.fourni_par is null then
    return new;
  end if;

  if not exists (
    select 1 from intervenants_enfant i
    where i.enfant_id = new.enfant_id
      and i.profil_id = new.fourni_par
      and i.retire_le is null
      and i.role = 'enseignant'
      and intervenant_couvre(i.id, new.matiere_code)
  ) then
    raise exception 'Le document doit être attribué à un enseignant de cette matière, rattaché à l''enfant.';
  end if;

  return new;
end;
$$;


--
-- Name: verifier_le_parent_de_l_objectif(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verifier_le_parent_de_l_objectif() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
  v_parent objectifs%rowtype;
begin
  if new.objectif_parent_id is null then
    return new;
  end if;

  select * into v_parent from objectifs where id = new.objectif_parent_id;

  if v_parent.enfant_id <> new.enfant_id then
    raise exception 'Un objectif fin appartient au même enfant que son objectif large.';
  end if;

  if v_parent.granularite <> 'large' then
    raise exception 'Un objectif fin se rattache à un objectif large, pas à un autre objectif fin.';
  end if;

  return new;
end;
$$;


--
-- Name: verifier_le_prerequis_de_recompense(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verifier_le_prerequis_de_recompense() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: verifier_le_traitement_de_la_demande(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verifier_le_traitement_de_la_demande() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
declare
  v_role role_intervenant;
  v_enfant uuid;
begin
  if new.statut = 'ouverte' or (tg_op = 'UPDATE' and old.statut <> 'ouverte') then
    return new;
  end if;

  -- Retirer sa propre demande reste possible : on renonce, on ne tranche pas.
  if new.statut = 'retiree' then
    return new;
  end if;

  if new.traite_par = new.demande_par then
    select o.enfant_id into v_enfant from objectifs o where o.id = new.objectif_id;

    select i.role into v_role
    from intervenants_enfant i
    where i.enfant_id = v_enfant
      and i.profil_id = new.demande_par
      and i.retire_le is null
    limit 1;

    if v_role is distinct from 'parent' then
      raise exception 'Un professionnel ne tranche pas la demande de modification qu''il a formulée.';
    end if;
  end if;

  return new;
end;
$$;


--
-- Name: acces_exceptionnels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.acces_exceptionnels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    ouvert_par uuid NOT NULL,
    nature public.nature_acces DEFAULT 'litige'::public.nature_acces NOT NULL,
    motif text NOT NULL,
    reference_litige text DEFAULT ''::text NOT NULL,
    autorite_requerante text DEFAULT ''::text NOT NULL,
    base_legale text DEFAULT ''::text NOT NULL,
    information_faite_le timestamp with time zone,
    ouvert_le timestamp with time zone DEFAULT now() NOT NULL,
    expire_le timestamp with time zone DEFAULT (now() + '72:00:00'::interval) NOT NULL,
    clos_le timestamp with time zone,
    CONSTRAINT acces_borne_dans_le_temps CHECK ((expire_le > ouvert_le)),
    CONSTRAINT acces_exceptionnels_motif_check CHECK ((length(btrim(motif)) >= 20)),
    CONSTRAINT requisition_documente_son_fondement CHECK (((nature <> 'requisition'::public.nature_acces) OR ((length(btrim(autorite_requerante)) > 0) AND (length(btrim(base_legale)) > 0) AND (length(btrim(reference_litige)) > 0))))
);


--
-- Name: acces_pieces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.acces_pieces (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    acces_id uuid NOT NULL,
    type_piece public.type_piece_acces NOT NULL,
    emane_de uuid,
    nom text NOT NULL,
    chemin text NOT NULL,
    depose_par uuid NOT NULL,
    depose_le timestamp with time zone DEFAULT now() NOT NULL,
    ecartee_le timestamp with time zone,
    ecartee_par uuid,
    motif_ecartement text DEFAULT ''::text NOT NULL,
    CONSTRAINT courrier_designe_son_auteur CHECK (((type_piece = 'courrier_autorite_parentale'::public.type_piece_acces) = (emane_de IS NOT NULL))),
    CONSTRAINT ecartement_signe_et_motive CHECK ((((ecartee_le IS NULL) AND (ecartee_par IS NULL) AND (btrim(motif_ecartement) = ''::text)) OR ((ecartee_le IS NOT NULL) AND (ecartee_par IS NOT NULL) AND (length(btrim(motif_ecartement)) >= 10))))
);


--
-- Name: adaptations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.adaptations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    support_id uuid NOT NULL,
    forme public.forme_adaptation NOT NULL,
    contenu jsonb DEFAULT '{}'::jsonb NOT NULL,
    modele_ia text,
    genere_le timestamp with time zone DEFAULT now() NOT NULL,
    statut public.statut_adaptation DEFAULT 'brouillon'::public.statut_adaptation NOT NULL,
    valide_par uuid,
    valide_le timestamp with time zone,
    motif_rejet text DEFAULT ''::text NOT NULL,
    CONSTRAINT adaptation_decidee_a_un_decideur CHECK (((statut = 'brouillon'::public.statut_adaptation) OR ((valide_par IS NOT NULL) AND (valide_le IS NOT NULL))))
);


--
-- Name: alertes_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alertes_actions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    alerte_id uuid NOT NULL,
    type_action public.type_action_alerte NOT NULL,
    description text NOT NULL,
    auteur_id uuid NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    effet text DEFAULT ''::text NOT NULL,
    effet_constate_le timestamp with time zone,
    CONSTRAINT effet_constate_a_une_date CHECK (((effet = ''::text) = (effet_constate_le IS NULL)))
);


--
-- Name: alertes_difficulte; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alertes_difficulte (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    repere_id uuid,
    objectif_id uuid,
    echecs_consecutifs smallint NOT NULL,
    ouverte_le timestamp with time zone DEFAULT now() NOT NULL,
    derniere_le timestamp with time zone DEFAULT now() NOT NULL,
    statut public.statut_alerte DEFAULT 'ouverte'::public.statut_alerte NOT NULL,
    traitee_par uuid,
    traitee_le timestamp with time zone,
    CONSTRAINT alerte_porte_sur_un_seul_axe CHECK ((num_nonnulls(repere_id, objectif_id) = 1)),
    CONSTRAINT alerte_traitee_a_un_auteur CHECK (((statut = 'ouverte'::public.statut_alerte) OR ((traitee_par IS NOT NULL) AND (traitee_le IS NOT NULL))))
);


--
-- Name: amorces_ecriture; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.amorces_ecriture (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid,
    contexte text NOT NULL,
    texte text NOT NULL,
    ordre smallint DEFAULT 0 NOT NULL,
    actif boolean DEFAULT true NOT NULL
);


--
-- Name: annees_enfant; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.annees_enfant (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    annee_scolaire text NOT NULL,
    classe public.niveau_classe NOT NULL,
    etablissement text DEFAULT ''::text NOT NULL,
    debute_le date DEFAULT CURRENT_DATE NOT NULL,
    close_le date,
    bilan_positionnement_id uuid,
    bilan_anterieur_id uuid,
    annee_precedente_id uuid,
    CONSTRAINT annee_close_apres_son_debut CHECK (((close_le IS NULL) OR (close_le >= debute_le))),
    CONSTRAINT annee_part_d_un_seul_bilan CHECK ((num_nonnulls(bilan_positionnement_id, bilan_anterieur_id) <= 1))
);


--
-- Name: appareils; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.appareils (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    profil_id uuid NOT NULL,
    jeton_push text NOT NULL,
    plateforme public.plateforme_appareil NOT NULL,
    libelle text DEFAULT ''::text NOT NULL,
    actif boolean DEFAULT true NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    derniere_utilisation timestamp with time zone
);


--
-- Name: avis_ia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.avis_ia (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    mission_id uuid,
    adaptation_id uuid,
    verdict public.verdict_ia NOT NULL,
    motif text DEFAULT ''::text NOT NULL,
    auteur_id uuid NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT avis_porte_sur_une_seule_sortie CHECK ((num_nonnulls(mission_id, adaptation_id) = 1))
);


--
-- Name: badges_obtenus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.badges_obtenus (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    matiere_code text,
    domaine_code text,
    niveau smallint NOT NULL,
    annee_id uuid,
    trimestre smallint,
    objectifs_atteints smallint DEFAULT 0 NOT NULL,
    objectifs_total smallint DEFAULT 0 NOT NULL,
    progression numeric,
    attribue_par uuid,
    commentaire text DEFAULT ''::text NOT NULL,
    obtenu_le timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT badge_releve_d_un_seul_champ CHECK ((num_nonnulls(matiere_code, domaine_code) = 1)),
    CONSTRAINT badges_obtenus_niveau_check CHECK ((niveau >= 1)),
    CONSTRAINT badges_obtenus_trimestre_check CHECK (((trimestre >= 1) AND (trimestre <= 3)))
);


--
-- Name: bilan_maitrises; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bilan_maitrises (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bilan_id uuid NOT NULL,
    repere_id uuid NOT NULL,
    maitrise public.maitrise DEFAULT 'non_evaluee'::public.maitrise NOT NULL,
    commentaire text DEFAULT ''::text NOT NULL
);


--
-- Name: bilan_niveaux_matiere; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bilan_niveaux_matiere (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bilan_id uuid NOT NULL,
    enfant_id uuid NOT NULL,
    matiere_code text NOT NULL,
    niveau_estime public.niveau_classe,
    appuis text[] DEFAULT '{}'::text[] NOT NULL,
    fragilites text[] DEFAULT '{}'::text[] NOT NULL,
    synthese_ia text DEFAULT ''::text NOT NULL,
    synthese_humaine text DEFAULT ''::text NOT NULL,
    valide_par uuid,
    valide_le timestamp with time zone
);


--
-- Name: bilan_questions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bilan_questions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bilan_id uuid NOT NULL,
    repere_id uuid NOT NULL,
    ordre smallint DEFAULT 0 NOT NULL,
    enonce text NOT NULL,
    type_reponse public.type_reponse DEFAULT 'qcm'::public.type_reponse NOT NULL,
    contenu jsonb DEFAULT '{}'::jsonb NOT NULL,
    correction jsonb DEFAULT '{}'::jsonb NOT NULL,
    genere_par_ia boolean DEFAULT true NOT NULL,
    modele_ia text,
    cree_le timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: bilan_reponses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bilan_reponses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    question_id uuid NOT NULL,
    reponse jsonb DEFAULT '{}'::jsonb NOT NULL,
    duree_secondes integer,
    aide_utilisee boolean DEFAULT false NOT NULL,
    maitrise_ia public.maitrise DEFAULT 'non_evaluee'::public.maitrise NOT NULL,
    commentaire_ia text DEFAULT ''::text NOT NULL,
    maitrise_corrigee public.maitrise,
    corrigee_par uuid,
    corrigee_le timestamp with time zone,
    repondu_le timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: bilans_positionnement; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bilans_positionnement (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    statut public.statut_bilan DEFAULT 'en_cours'::public.statut_bilan NOT NULL,
    classe_reference public.niveau_classe,
    matieres text[] DEFAULT '{}'::text[] NOT NULL,
    modele_ia text,
    demarre_le timestamp with time zone DEFAULT now() NOT NULL,
    complete_le timestamp with time zone,
    valide_par uuid,
    valide_le timestamp with time zone,
    commentaire_referent text DEFAULT ''::text NOT NULL,
    cree_par uuid NOT NULL,
    modifie_le timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT bilan_valide_a_un_validateur CHECK (((statut = 'valide'::public.statut_bilan) = ((valide_par IS NOT NULL) AND (valide_le IS NOT NULL))))
);


--
-- Name: bilans_trimestriels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bilans_trimestriels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    trimestre smallint NOT NULL,
    annee_scolaire text DEFAULT public.annee_scolaire_courante() NOT NULL,
    statut public.statut_bilan_trimestriel DEFAULT 'brouillon'::public.statut_bilan_trimestriel NOT NULL,
    synthese_ia text DEFAULT ''::text NOT NULL,
    synthese_humaine text DEFAULT ''::text NOT NULL,
    modele_ia text,
    genere_le timestamp with time zone DEFAULT now() NOT NULL,
    valide_par uuid,
    valide_le timestamp with time zone,
    pdf_chemin text,
    modifie_le timestamp with time zone DEFAULT now() NOT NULL,
    annee_id uuid,
    CONSTRAINT bilan_trimestriel_valide_a_un_validateur CHECK (((statut = 'brouillon'::public.statut_bilan_trimestriel) OR ((valide_par IS NOT NULL) AND (valide_le IS NOT NULL)))),
    CONSTRAINT bilans_trimestriels_trimestre_check CHECK (((trimestre >= 1) AND (trimestre <= 3)))
);


--
-- Name: bilans_trimestriels_matieres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bilans_trimestriels_matieres (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bilan_id uuid NOT NULL,
    matiere_code text NOT NULL,
    appuis text[] DEFAULT '{}'::text[] NOT NULL,
    fragilites text[] DEFAULT '{}'::text[] NOT NULL,
    commentaire text DEFAULT ''::text NOT NULL,
    objectifs_atteints smallint DEFAULT 0 NOT NULL,
    objectifs_total smallint DEFAULT 0 NOT NULL,
    missions_reussies smallint DEFAULT 0 NOT NULL,
    reperes_progresses smallint DEFAULT 0 NOT NULL
);


--
-- Name: centres_interet; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.centres_interet (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    libelle text NOT NULL,
    intensite smallint DEFAULT 3 NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT centres_interet_intensite_check CHECK (((intensite >= 1) AND (intensite <= 5)))
);


--
-- Name: consentements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.consentements (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    profil_id uuid NOT NULL,
    type public.type_consentement NOT NULL,
    accorde boolean NOT NULL,
    version_texte text NOT NULL,
    accorde_le timestamp with time zone DEFAULT now() NOT NULL,
    revoque_le timestamp with time zone,
    texte_id uuid,
    signature_nom text DEFAULT ''::text NOT NULL,
    signature_chemin text,
    adresse_ip inet,
    agent text DEFAULT ''::text NOT NULL,
    CONSTRAINT consentement_accorde_est_signe CHECK (((accorde = false) OR ((texte_id IS NOT NULL) AND (length(btrim(signature_nom)) >= 2))))
);


--
-- Name: corrections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.corrections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    tentative_id uuid NOT NULL,
    points_obtenus numeric(5,2),
    commentaire text DEFAULT ''::text NOT NULL,
    corrigee_par uuid NOT NULL,
    corrigee_le timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: journal_ia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journal_ia (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid,
    operation public.operation_ia NOT NULL,
    modele text NOT NULL,
    empreinte_prompt text,
    tokens_entree integer DEFAULT 0 NOT NULL,
    tokens_sortie integer DEFAULT 0 NOT NULL,
    tokens_cache_lus integer DEFAULT 0 NOT NULL,
    cout_centimes numeric(10,4) DEFAULT 0 NOT NULL,
    duree_ms integer,
    succes boolean DEFAULT true NOT NULL,
    erreur text DEFAULT ''::text NOT NULL,
    declenche_par uuid,
    cree_le timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: cout_ia_mensuel; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.cout_ia_mensuel WITH (security_invoker='true') AS
 SELECT enfant_id,
    date_trunc('month'::text, cree_le) AS mois,
    count(*) AS appels,
    sum(tokens_entree) AS tokens_entree,
    sum(tokens_sortie) AS tokens_sortie,
    round((sum(cout_centimes) / (100)::numeric), 2) AS cout_euros
   FROM public.journal_ia
  GROUP BY enfant_id, (date_trunc('month'::text, cree_le));


--
-- Name: demandes_habilitation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.demandes_habilitation (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    profil_id uuid NOT NULL,
    organisation text DEFAULT ''::text NOT NULL,
    fonction text NOT NULL,
    numero_professionnel text DEFAULT ''::text NOT NULL,
    motivation text DEFAULT ''::text NOT NULL,
    statut public.statut_habilitation DEFAULT 'en_attente'::public.statut_habilitation NOT NULL,
    traitee_par uuid,
    traitee_le timestamp with time zone,
    motif text DEFAULT ''::text NOT NULL,
    valable_jusqu_au date,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    directeur_nom text DEFAULT ''::text NOT NULL,
    directeur_contact text DEFAULT ''::text NOT NULL,
    etablissement_adresse text DEFAULT ''::text NOT NULL,
    uai text DEFAULT ''::text NOT NULL,
    CONSTRAINT habilitation_traitee_a_un_auteur CHECK (((statut = 'en_attente'::public.statut_habilitation) OR ((traitee_par IS NOT NULL) AND (traitee_le IS NOT NULL)))),
    CONSTRAINT refus_motive CHECK (((statut <> 'refusee'::public.statut_habilitation) OR (length(btrim(motif)) >= 10))),
    CONSTRAINT uai_bien_forme CHECK (((uai = ''::text) OR (uai ~ '^[0-9]{7}[A-Z]$'::text)))
);


--
-- Name: COLUMN demandes_habilitation.directeur_contact; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.demandes_habilitation.directeur_contact IS 'Adresse ou téléphone du directeur d''établissement. Sert à vérifier l''attestation — c''est sa seule raison d''être, et il ne doit servir à rien d''autre.';


--
-- Name: COLUMN demandes_habilitation.etablissement_adresse; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.demandes_habilitation.etablissement_adresse IS 'Adresse de l''établissement. Le nom seul ne l''identifie pas — et c''est l''adresse qui permet à l''administration de retrouver la direction pour vérifier.';


--
-- Name: COLUMN demandes_habilitation.uai; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.demandes_habilitation.uai IS 'Code UAI de l''établissement scolaire, quand il en a un. Facultatif : les structures médico-sociales relèvent du répertoire FINESS.';


--
-- Name: demandes_suppression; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.demandes_suppression (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid,
    demandee_par uuid NOT NULL,
    motif text NOT NULL,
    statut public.statut_suppression DEFAULT 'en_attente'::public.statut_suppression NOT NULL,
    masquee_par uuid,
    masquee_le timestamp with time zone,
    purge_prevue_le date,
    purgee_le timestamp with time zone,
    motif_annulation text DEFAULT ''::text NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT demandes_suppression_motif_check CHECK ((length(btrim(motif)) >= 15))
);


--
-- Name: documents_diagnostic; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documents_diagnostic (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    nature text DEFAULT 'autre'::text NOT NULL,
    chemin text NOT NULL,
    nom_fichier text DEFAULT ''::text NOT NULL,
    depose_par uuid,
    depose_le timestamp with time zone DEFAULT now() NOT NULL,
    profil_extrait jsonb,
    extraction_statut text DEFAULT 'en_attente'::text NOT NULL,
    validee_par uuid,
    validee_le timestamp with time zone,
    revue_conservation_le date,
    CONSTRAINT documents_diagnostic_extraction_statut_check CHECK ((extraction_statut = ANY (ARRAY['en_attente'::text, 'faite'::text, 'echec'::text]))),
    CONSTRAINT documents_diagnostic_nature_check CHECK ((nature = ANY (ARRAY['diagnostic_autisme'::text, 'bilan_pluridisciplinaire'::text, 'autre'::text]))),
    CONSTRAINT extraction_validee_a_un_validateur CHECK (((validee_le IS NULL) = (validee_par IS NULL)))
);


--
-- Name: domaines_evaluation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.domaines_evaluation (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    version_id uuid NOT NULL,
    matiere_code text NOT NULL,
    classe public.niveau_classe NOT NULL,
    code text NOT NULL,
    libelle text NOT NULL,
    ordre smallint DEFAULT 0 NOT NULL
);


--
-- Name: domaines_transversaux; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.domaines_transversaux (
    code text NOT NULL,
    libelle text NOT NULL,
    ordre smallint DEFAULT 0 NOT NULL,
    emoji text DEFAULT '⭐'::text NOT NULL
);


--
-- Name: enfants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enfants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    prenom text NOT NULL,
    date_naissance date,
    classe public.niveau_classe,
    communication public.profil_communication DEFAULT 'verbal'::public.profil_communication NOT NULL,
    cree_par uuid NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    modifie_le timestamp with time zone DEFAULT now() NOT NULL,
    archive_le timestamp with time zone,
    titulaires_autorite_parentale smallint DEFAULT 2 NOT NULL,
    archive_par uuid,
    motif_archivage text DEFAULT ''::text NOT NULL,
    purge_prevue_le date,
    compte_id uuid,
    nom text DEFAULT ''::text NOT NULL,
    CONSTRAINT archivage_signe CHECK ((((archive_le IS NULL) AND (archive_par IS NULL) AND (purge_prevue_le IS NULL)) OR ((archive_le IS NOT NULL) AND (archive_par IS NOT NULL) AND (purge_prevue_le IS NOT NULL)))),
    CONSTRAINT enfants_titulaires_autorite_parentale_check CHECK ((titulaires_autorite_parentale = ANY (ARRAY[1, 2])))
);


--
-- Name: COLUMN enfants.titulaires_autorite_parentale; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.enfants.titulaires_autorite_parentale IS 'Établi par le référent. Deux par défaut : tant que le second titulaire n''a pas rejoint, aucun objectif ne se valide.';


--
-- Name: COLUMN enfants.purge_prevue_le; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.enfants.purge_prevue_le IS 'Date annoncée à la famille lors du masquage. Ne gouverne rien : la purge se décide sur purge_prevue(), recalculée depuis duree_conservation().';


--
-- Name: COLUMN enfants.compte_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.enfants.compte_id IS 'Compte personnel de l''enfant, quand il en a un. Nul sinon : il travaille alors depuis la session d''un parent.';


--
-- Name: COLUMN enfants.nom; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.enfants.nom IS 'Facultatif. Sert à distinguer deux enfants du même prénom dans la liste d''un référent — pas à identifier plus finement.';


--
-- Name: enfants_sante; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enfants_sante (
    enfant_id uuid NOT NULL,
    besoins_particuliers text DEFAULT ''::text NOT NULL,
    amenagements text DEFAULT ''::text NOT NULL,
    suivis_exterieurs text DEFAULT ''::text NOT NULL,
    modifie_le timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: exercices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.exercices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    mission_id uuid NOT NULL,
    ordre smallint DEFAULT 0 NOT NULL,
    consigne text NOT NULL,
    type_reponse public.type_reponse DEFAULT 'qcm'::public.type_reponse NOT NULL,
    contenu jsonb DEFAULT '{}'::jsonb NOT NULL,
    correction jsonb DEFAULT '{}'::jsonb NOT NULL,
    indice text DEFAULT ''::text NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    modele_id uuid,
    difficulte smallint,
    pieces integer,
    CONSTRAINT exercices_difficulte_check CHECK (((difficulte IS NULL) OR ((difficulte >= 1) AND (difficulte <= 5)))),
    CONSTRAINT exercices_pieces_check CHECK (((pieces IS NULL) OR (pieces >= 0)))
);


--
-- Name: fils; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fils (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    portee public.portee_fil NOT NULL,
    sujet text DEFAULT ''::text NOT NULL,
    cree_par uuid NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    dernier_message_le timestamp with time zone DEFAULT now() NOT NULL,
    clos_le timestamp with time zone
);


--
-- Name: fils_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fils_participants (
    fil_id uuid NOT NULL,
    profil_id uuid NOT NULL,
    ajoute_par uuid,
    ajoute_le timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: habilitation_pieces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.habilitation_pieces (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    demande_id uuid NOT NULL,
    type_piece public.type_piece_habilitation NOT NULL,
    libelle text DEFAULT ''::text NOT NULL,
    chemin text NOT NULL,
    delivree_le date,
    valable_jusqu_au date,
    deposee_le timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT piece_valide_apres_emission CHECK (((valable_jusqu_au IS NULL) OR (delivree_le IS NULL) OR (valable_jusqu_au >= delivree_le)))
);


--
-- Name: intervenants_enfant; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervenants_enfant (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    profil_id uuid NOT NULL,
    role public.role_intervenant NOT NULL,
    fonction text DEFAULT ''::text NOT NULL,
    matiere_code text,
    invite_par uuid,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    retire_le timestamp with time zone,
    succede_a uuid,
    motif_retrait text DEFAULT ''::text NOT NULL,
    toutes_matieres boolean DEFAULT false NOT NULL,
    principal boolean DEFAULT false NOT NULL,
    designe_le timestamp with time zone
);


--
-- Name: COLUMN intervenants_enfant.matiere_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.intervenants_enfant.matiere_code IS 'Obsolète depuis 0036. La ou les matières d''un intervenant vivent dans intervenants_matieres, ou sont couvertes par toutes_matieres.';


--
-- Name: COLUMN intervenants_enfant.principal; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.intervenants_enfant.principal IS 'Pour un référent : celui qui répond du dossier et entre dans le quorum de validation. Les autres sont suppléants — mêmes accès, sans la signature.';


--
-- Name: intervenants_matieres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.intervenants_matieres (
    intervenant_id uuid NOT NULL,
    matiere_code text NOT NULL
);


--
-- Name: invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invitations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    email text NOT NULL,
    role public.role_intervenant NOT NULL,
    fonction text DEFAULT ''::text NOT NULL,
    matiere_code text,
    jeton text DEFAULT encode(public.gen_random_bytes(24), 'hex'::text) NOT NULL,
    invite_par uuid NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    expire_le timestamp with time zone DEFAULT (now() + '30 days'::interval) NOT NULL,
    acceptee_le timestamp with time zone,
    annulee_le timestamp with time zone,
    matieres text[] DEFAULT '{}'::text[] NOT NULL,
    toutes_matieres boolean DEFAULT false NOT NULL,
    CONSTRAINT invitation_enseignant_a_une_matiere CHECK (((role <> 'enseignant'::public.role_intervenant) OR (matiere_code IS NOT NULL)))
);


--
-- Name: items_evaluation_nationale; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.items_evaluation_nationale (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    version_id uuid NOT NULL,
    domaine_evaluation_id uuid NOT NULL,
    repere_id uuid,
    test text NOT NULL,
    numero smallint NOT NULL,
    sous_domaine text DEFAULT ''::text NOT NULL,
    automatismes text DEFAULT ''::text NOT NULL,
    structure text DEFAULT ''::text NOT NULL,
    tache text NOT NULL,
    reponse_attendue text NOT NULL,
    erreurs_observees text[] DEFAULT '{}'::text[] NOT NULL,
    calculatrice boolean,
    taux_reussite_national numeric(5,2)
);


--
-- Name: journal_acces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journal_acces (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    profil_id uuid,
    action text NOT NULL,
    table_cible text DEFAULT ''::text NOT NULL,
    ligne_id uuid,
    detail jsonb DEFAULT '{}'::jsonb NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: journal_entrees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journal_entrees (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    journee_id uuid NOT NULL,
    auteur_id uuid NOT NULL,
    type public.type_entree NOT NULL,
    corps text DEFAULT ''::text NOT NULL,
    visible_par_l_enfant boolean DEFAULT false NOT NULL,
    support_id uuid,
    objectif_id uuid,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    modifie_le timestamp with time zone
);


--
-- Name: journal_medias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journal_medias (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    journee_id uuid NOT NULL,
    entree_id uuid,
    type_media public.type_media NOT NULL,
    chemin text NOT NULL,
    nom text DEFAULT ''::text NOT NULL,
    duree_secondes integer,
    octets bigint,
    depose_par uuid NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT journal_medias_duree_secondes_check CHECK (((duree_secondes IS NULL) OR (duree_secondes > 0)))
);


--
-- Name: journee_etapes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journee_etapes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    journee_id uuid NOT NULL,
    ordre smallint DEFAULT 0 NOT NULL,
    heure text DEFAULT ''::text NOT NULL,
    intitule text NOT NULL,
    detail text DEFAULT ''::text NOT NULL,
    faite_le timestamp with time zone,
    cree_le timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: journee_preparatifs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journee_preparatifs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    journee_id uuid NOT NULL,
    libelle text NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    essentiel boolean DEFAULT false NOT NULL,
    ordre smallint DEFAULT 0 NOT NULL,
    coche_le timestamp with time zone,
    coche_par uuid
);


--
-- Name: journee_reperes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journee_reperes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    journee_id uuid NOT NULL,
    etape_id uuid,
    type public.type_repere_jour NOT NULL,
    texte text NOT NULL,
    ordre smallint DEFAULT 0 NOT NULL,
    cree_par uuid NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: journees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.journees (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    jour date NOT NULL,
    type_jour public.type_jour DEFAULT 'ecole'::public.type_jour NOT NULL,
    humeur public.humeur_jour,
    humeur_le timestamp with time zone,
    recit text DEFAULT ''::text NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    modifie_le timestamp with time zone DEFAULT now() NOT NULL,
    periode_id uuid,
    titre text DEFAULT ''::text NOT NULL,
    resume text DEFAULT ''::text NOT NULL,
    emoji text DEFAULT ''::text NOT NULL,
    CONSTRAINT humeur_horodatee CHECK (((humeur IS NULL) = (humeur_le IS NULL)))
);


--
-- Name: matieres; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.matieres (
    code text NOT NULL,
    libelle text NOT NULL,
    ordre smallint DEFAULT 0 NOT NULL,
    emoji text DEFAULT '🎓'::text NOT NULL
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    fil_id uuid NOT NULL,
    auteur_id uuid NOT NULL,
    corps text NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    modifie_le timestamp with time zone
);


--
-- Name: missions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.missions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    projet_moteur_id uuid NOT NULL,
    objectif_id uuid,
    adaptation_id uuid,
    matiere_code text,
    titre text NOT NULL,
    intitule_narratif text DEFAULT ''::text NOT NULL,
    difficulte smallint DEFAULT 3 NOT NULL,
    points integer DEFAULT 10 NOT NULL,
    statut public.statut_mission DEFAULT 'proposee'::public.statut_mission NOT NULL,
    genere_par_ia boolean DEFAULT true NOT NULL,
    modele_ia text,
    valide_par uuid,
    valide_le timestamp with time zone,
    ordre smallint DEFAULT 0 NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    modifie_le timestamp with time zone DEFAULT now() NOT NULL,
    nature public.nature_travail DEFAULT 'entrainement'::public.nature_travail NOT NULL,
    auteur_id uuid,
    tentatives_max smallint,
    indices_autorises boolean DEFAULT true NOT NULL,
    domaine_code text,
    remplacee_par uuid,
    a_retransposer boolean DEFAULT false NOT NULL,
    quete_id uuid,
    fourni_par uuid,
    CONSTRAINT evaluation_annonce_ses_essais CHECK (((nature <> 'evaluation'::public.nature_travail) OR (tentatives_max IS NOT NULL))),
    CONSTRAINT mission_proposee_tant_qu_elle_n_est_pas_validee CHECK (((statut = 'proposee'::public.statut_mission) OR ((valide_par IS NOT NULL) AND (valide_le IS NOT NULL)))),
    CONSTRAINT mission_releve_d_un_seul_champ CHECK ((num_nonnulls(matiere_code, domaine_code) = 1)),
    CONSTRAINT missions_difficulte_check CHECK (((difficulte >= 1) AND (difficulte <= 5))),
    CONSTRAINT missions_points_check CHECK ((points >= 0)),
    CONSTRAINT missions_tentatives_max_check CHECK (((tentatives_max IS NULL) OR (tentatives_max >= 1)))
);


--
-- Name: COLUMN missions.fourni_par; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.missions.fourni_par IS 'L''enseignant dont émane le travail. Distinct de auteur_id, qui dit qui l''a saisi : un devoir transcrit par un parent reste le devoir du professeur.';


--
-- Name: modeles_exercice; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.modeles_exercice (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    matiere_code text NOT NULL,
    repere_id uuid,
    cycle public.cycle_scolaire,
    libelle text NOT NULL,
    consigne text NOT NULL,
    type_reponse public.type_reponse DEFAULT 'qcm'::public.type_reponse NOT NULL,
    contenu jsonb DEFAULT '{}'::jsonb NOT NULL,
    parametres jsonb DEFAULT '{}'::jsonb NOT NULL,
    correction jsonb DEFAULT '{}'::jsonb NOT NULL,
    indice text DEFAULT ''::text NOT NULL,
    difficulte smallint DEFAULT 3 NOT NULL,
    statut public.statut_modele DEFAULT 'propose'::public.statut_modele NOT NULL,
    valide_par uuid,
    valide_le timestamp with time zone,
    motif_retrait text DEFAULT ''::text NOT NULL,
    origine_exercice_id uuid,
    cree_par uuid NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    modifie_le timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT modele_valide_a_un_validateur CHECK (((statut = 'valide'::public.statut_modele) = ((valide_par IS NOT NULL) AND (valide_le IS NOT NULL)))),
    CONSTRAINT modeles_exercice_difficulte_check CHECK (((difficulte >= 1) AND (difficulte <= 5)))
);


--
-- Name: notations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    mission_id uuid NOT NULL,
    bareme numeric(5,2) NOT NULL,
    note numeric(5,2),
    appreciation text DEFAULT ''::text NOT NULL,
    note_par uuid NOT NULL,
    note_le timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT notations_bareme_check CHECK ((bareme > (0)::numeric)),
    CONSTRAINT note_dans_le_bareme CHECK (((note IS NULL) OR ((note >= (0)::numeric) AND (note <= bareme))))
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    destinataire_id uuid NOT NULL,
    enfant_id uuid,
    type public.type_notification NOT NULL,
    titre text NOT NULL,
    corps text DEFAULT ''::text NOT NULL,
    lien text DEFAULT ''::text NOT NULL,
    message_id uuid,
    lue_le timestamp with time zone,
    cree_le timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: objectifs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.objectifs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    matiere_code text,
    repere_id uuid,
    libelle text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    origine public.origine_contenu DEFAULT 'enseignant'::public.origine_contenu NOT NULL,
    propose_par uuid,
    statut public.statut_objectif DEFAULT 'propose'::public.statut_objectif NOT NULL,
    valide_par uuid,
    valide_le timestamp with time zone,
    atteint_le timestamp with time zone,
    trimestre smallint,
    annee_scolaire text DEFAULT public.annee_scolaire_courante() NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    modifie_le timestamp with time zone DEFAULT now() NOT NULL,
    debute_le date DEFAULT CURRENT_DATE NOT NULL,
    echeance_le date,
    valide_en_reunion boolean DEFAULT false NOT NULL,
    domaine_code text,
    granularite public.granularite_objectif DEFAULT 'large'::public.granularite_objectif NOT NULL,
    objectif_parent_id uuid,
    critere_fin text DEFAULT ''::text NOT NULL,
    reussites_visees smallint DEFAULT 3 NOT NULL,
    exercices_vises smallint,
    annee_id uuid,
    CONSTRAINT assez_d_exercices_pour_reussir CHECK (((exercices_vises IS NULL) OR (exercices_vises >= reussites_visees))),
    CONSTRAINT objectif_fin_a_un_parent CHECK (((granularite = 'fin'::public.granularite_objectif) = (objectif_parent_id IS NOT NULL))),
    CONSTRAINT objectif_periode_coherente CHECK (((echeance_le IS NULL) OR (echeance_le >= debute_le))),
    CONSTRAINT objectif_releve_d_un_seul_champ CHECK ((num_nonnulls(matiere_code, domaine_code) = 1)),
    CONSTRAINT objectif_valide_a_un_validateur CHECK (((statut = 'propose'::public.statut_objectif) OR ((valide_par IS NOT NULL) AND (valide_le IS NOT NULL)))),
    CONSTRAINT objectifs_exercices_vises_check CHECK (((exercices_vises IS NULL) OR (exercices_vises > 0))),
    CONSTRAINT objectifs_reussites_visees_check CHECK ((reussites_visees > 0)),
    CONSTRAINT objectifs_trimestre_check CHECK (((trimestre >= 1) AND (trimestre <= 3))),
    CONSTRAINT seuls_les_objectifs_fins_se_chiffrent CHECK (((granularite = 'fin'::public.granularite_objectif) OR ((exercices_vises IS NULL) AND (critere_fin = ''::text))))
);


--
-- Name: COLUMN objectifs.trimestre; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.objectifs.trimestre IS 'Facultatif. Renseigné quand l''objectif vise explicitement un trimestre scolaire.';


--
-- Name: COLUMN objectifs.valide_en_reunion; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.objectifs.valide_en_reunion IS 'Vrai quand la décision a été prise collectivement. valide_par porte alors qui a saisi, pas qui a décidé seul.';


--
-- Name: COLUMN objectifs.reussites_visees; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.objectifs.reussites_visees IS 'Nombre de réussites avant de tenir la compétence pour acquise. N''a de sens que sur un objectif fin.';


--
-- Name: objectifs_demandes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.objectifs_demandes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    objectif_id uuid NOT NULL,
    demande_par uuid NOT NULL,
    motif text NOT NULL,
    libelle_propose text DEFAULT ''::text NOT NULL,
    echeance_proposee date,
    statut public.statut_demande DEFAULT 'ouverte'::public.statut_demande NOT NULL,
    reponse text DEFAULT ''::text NOT NULL,
    traite_par uuid,
    traite_le timestamp with time zone,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT demande_traitee_a_un_decideur CHECK (((statut = 'ouverte'::public.statut_demande) OR ((traite_par IS NOT NULL) AND (traite_le IS NOT NULL))))
);


--
-- Name: objectifs_validations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.objectifs_validations (
    objectif_id uuid NOT NULL,
    profil_id uuid NOT NULL,
    valide_le timestamp with time zone DEFAULT now() NOT NULL,
    commentaire text DEFAULT ''::text NOT NULL
);


--
-- Name: observations_capacites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.observations_capacites (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    questionnaire_id uuid NOT NULL,
    rempli_par uuid,
    role_au_moment public.role_intervenant,
    statut text DEFAULT 'brouillon'::text NOT NULL,
    synthese jsonb DEFAULT '{}'::jsonb NOT NULL,
    rempli_le timestamp with time zone DEFAULT now() NOT NULL,
    modifie_le timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT observations_capacites_statut_check CHECK ((statut = ANY (ARRAY['brouillon'::text, 'complete'::text])))
);


--
-- Name: observations_reponses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.observations_reponses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    observation_id uuid NOT NULL,
    item_code text NOT NULL,
    valeur smallint,
    note text DEFAULT ''::text NOT NULL,
    CONSTRAINT observations_reponses_valeur_check CHECK (((valeur >= 0) AND (valeur <= 3)))
);


--
-- Name: periodes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.periodes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    titre text NOT NULL,
    sous_titre text DEFAULT ''::text NOT NULL,
    nature public.nature_periode DEFAULT 'ordinaire'::public.nature_periode NOT NULL,
    debut date NOT NULL,
    fin date NOT NULL,
    a_savoir text DEFAULT ''::text NOT NULL,
    cree_par uuid NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT periode_bornee CHECK ((fin >= debut))
);


--
-- Name: pieces_gagnees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pieces_gagnees (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    source public.source_pieces NOT NULL,
    exercice_id uuid,
    mission_id uuid,
    notation_id uuid,
    pieces integer NOT NULL,
    motif text DEFAULT ''::text NOT NULL,
    attribue_par uuid,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pieces_gagnees_pieces_check CHECK ((pieces > 0))
);


--
-- Name: pieces_jointes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pieces_jointes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    message_id uuid NOT NULL,
    nom text NOT NULL,
    chemin text NOT NULL,
    type_mime text DEFAULT ''::text NOT NULL,
    octets bigint,
    cree_le timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: recompenses_obtenues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recompenses_obtenues (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    recompense_id uuid NOT NULL,
    mission_id uuid,
    obtenue_le timestamp with time zone DEFAULT now() NOT NULL,
    offerte boolean DEFAULT false NOT NULL,
    offerte_par uuid,
    points_payes integer DEFAULT 0 NOT NULL,
    CONSTRAINT offre_a_un_auteur CHECK (((offerte = false) = (offerte_par IS NULL))),
    CONSTRAINT recompenses_obtenues_points_payes_check CHECK ((points_payes >= 0))
);


--
-- Name: points_enfant; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.points_enfant WITH (security_invoker='true') AS
 SELECT e.id AS enfant_id,
    COALESCE(gagnes.total, 0) AS points_gagnes,
    COALESCE(depenses.total, 0) AS points_depenses,
    (COALESCE(gagnes.total, 0) - COALESCE(depenses.total, 0)) AS solde
   FROM ((public.enfants e
     LEFT JOIN ( SELECT g.enfant_id,
            (sum(g.pieces))::integer AS total
           FROM public.pieces_gagnees g
          GROUP BY g.enfant_id) gagnes ON ((gagnes.enfant_id = e.id)))
     LEFT JOIN ( SELECT ro.enfant_id,
            (sum(ro.points_payes))::integer AS total
           FROM public.recompenses_obtenues ro
          WHERE (NOT ro.offerte)
          GROUP BY ro.enfant_id) depenses ON ((depenses.enfant_id = e.id)));


--
-- Name: preferences_notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preferences_notification (
    profil_id uuid NOT NULL,
    type public.type_notification NOT NULL,
    canal public.canal_envoi NOT NULL,
    actif boolean DEFAULT true NOT NULL
);


--
-- Name: preparatifs_recurrents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preparatifs_recurrents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    libelle text NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    essentiel boolean DEFAULT false NOT NULL,
    ordre smallint DEFAULT 0 NOT NULL,
    actif boolean DEFAULT true NOT NULL
);


--
-- Name: profils; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profils (
    id uuid NOT NULL,
    prenom text DEFAULT ''::text NOT NULL,
    nom text DEFAULT ''::text NOT NULL,
    email text DEFAULT ''::text NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    modifie_le timestamp with time zone DEFAULT now() NOT NULL,
    role_plateforme public.role_plateforme DEFAULT 'membre'::public.role_plateforme NOT NULL
);


--
-- Name: COLUMN profils.role_plateforme; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.profils.role_plateforme IS 'Qualité de la personne, indépendante de tout enfant. « membre » couvre les familles et les enseignants, dont les droits viennent de leur rattachement.';


--
-- Name: programme_applicable; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.programme_applicable (
    version_id uuid NOT NULL,
    classe public.niveau_classe NOT NULL,
    rentree_debut smallint NOT NULL,
    rentree_fin smallint,
    CONSTRAINT programme_fin_apres_debut CHECK (((rentree_fin IS NULL) OR (rentree_fin >= rentree_debut)))
);


--
-- Name: projets_moteurs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projets_moteurs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    titre text NOT NULL,
    univers public.univers_moteur DEFAULT 'autre'::public.univers_moteur NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    lexique jsonb DEFAULT '{}'::jsonb NOT NULL,
    actif boolean DEFAULT true NOT NULL,
    cree_par uuid NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    modifie_le timestamp with time zone DEFAULT now() NOT NULL,
    surprise_libelle text DEFAULT 'Une surprise'::text NOT NULL,
    surprise_image_chemin text
);


--
-- Name: supports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.supports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    matiere_code text NOT NULL,
    type_support public.type_support DEFAULT 'cours'::public.type_support NOT NULL,
    titre text NOT NULL,
    fichier_chemin text,
    fichier_type text,
    fichier_octets bigint,
    texte_extrait text DEFAULT ''::text NOT NULL,
    statut public.statut_support DEFAULT 'depose'::public.statut_support NOT NULL,
    erreur text DEFAULT ''::text NOT NULL,
    depose_par uuid NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    modifie_le timestamp with time zone DEFAULT now() NOT NULL,
    fourni_par uuid
);


--
-- Name: COLUMN supports.fourni_par; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.supports.fourni_par IS 'L''enseignant dont émane le document. Distinct de depose_par, qui dit qui l''a versé : une feuille photographiée par un parent reste le support du professeur.';


--
-- Name: qualite_ia; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.qualite_ia WITH (security_invoker='true') AS
 SELECT v.verdict,
    v.motif,
    v.cree_le,
    v.auteur_id,
    COALESCE(m.matiere_code, s.matiere_code) AS matiere_code,
    COALESCE(m.modele_ia, a.modele_ia) AS modele_ia,
        CASE
            WHEN (v.mission_id IS NOT NULL) THEN 'mission'::text
            ELSE 'adaptation'::text
        END AS sortie
   FROM (((public.avis_ia v
     LEFT JOIN public.missions m ON ((m.id = v.mission_id)))
     LEFT JOIN public.adaptations a ON ((a.id = v.adaptation_id)))
     LEFT JOIN public.supports s ON ((s.id = a.support_id)));


--
-- Name: questionnaires_capacites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.questionnaires_capacites (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    code text DEFAULT 'xylou_bilan_capacites'::text NOT NULL,
    version text NOT NULL,
    contenu jsonb NOT NULL,
    publie_le timestamp with time zone,
    courant boolean DEFAULT false NOT NULL,
    cree_par uuid,
    cree_le timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: quetes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quetes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    annee_id uuid,
    trimestre smallint NOT NULL,
    titre text NOT NULL,
    intitule_scolaire text DEFAULT ''::text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    projet_moteur_id uuid,
    recompense_id uuid,
    statut public.statut_quete DEFAULT 'en_cours'::public.statut_quete NOT NULL,
    ouverte_le date DEFAULT CURRENT_DATE NOT NULL,
    reussie_le date,
    close_le date,
    reussie_par uuid,
    motif_reussite text DEFAULT ''::text NOT NULL,
    cree_par uuid NOT NULL,
    CONSTRAINT quete_reussie_est_datee CHECK (((statut = 'reussie'::public.statut_quete) = (reussie_le IS NOT NULL))),
    CONSTRAINT quetes_trimestre_check CHECK (((trimestre >= 1) AND (trimestre <= 3))),
    CONSTRAINT reussite_sur_appreciation_motivee CHECK (((reussie_par IS NULL) OR (length(btrim(motif_reussite)) >= 5)))
);


--
-- Name: quetes_badges_vises; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quetes_badges_vises (
    quete_id uuid NOT NULL,
    matiere_code text,
    domaine_code text,
    CONSTRAINT badge_vise_a_un_champ CHECK ((num_nonnulls(matiere_code, domaine_code) = 1))
);


--
-- Name: recompenses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recompenses (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    projet_moteur_id uuid NOT NULL,
    libelle text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    cout_points integer DEFAULT 10 NOT NULL,
    image_chemin text,
    ordre smallint DEFAULT 0 NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    categorie public.categorie_recompense DEFAULT 'autre'::public.categorie_recompense NOT NULL,
    disponible boolean DEFAULT true NOT NULL,
    requiert_id uuid,
    unique_par_enfant boolean DEFAULT true NOT NULL,
    CONSTRAINT recompenses_cout_points_check CHECK ((cout_points >= 0))
);


--
-- Name: recompenses_familiales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recompenses_familiales (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    libelle text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    photo_chemin text,
    prevue_le date,
    points_requis integer,
    missions_requises integer,
    objectif_id uuid,
    condition text DEFAULT ''::text NOT NULL,
    statut public.statut_recompense_familiale DEFAULT 'promise'::public.statut_recompense_familiale NOT NULL,
    atteinte_le date,
    motif text DEFAULT ''::text NOT NULL,
    proposee_par uuid NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    modifie_le timestamp with time zone DEFAULT now() NOT NULL,
    montrer_existence boolean DEFAULT true NOT NULL,
    montrer_nature boolean DEFAULT true NOT NULL,
    montrer_date boolean DEFAULT true NOT NULL,
    montrer_progression boolean DEFAULT true NOT NULL,
    devoilee_le timestamp with time zone,
    devoilee_par uuid,
    badges_requis integer,
    CONSTRAINT atteinte_datee CHECK (((statut = 'atteinte'::public.statut_recompense_familiale) = (atteinte_le IS NOT NULL))),
    CONSTRAINT changement_motive CHECK (((statut <> ALL (ARRAY['reportee'::public.statut_recompense_familiale, 'annulee'::public.statut_recompense_familiale])) OR (length(btrim(motif)) >= 5))),
    CONSTRAINT devoilement_signe CHECK (((devoilee_le IS NULL) = (devoilee_par IS NULL))),
    CONSTRAINT recompense_a_une_condition CHECK (((prevue_le IS NOT NULL) OR (points_requis IS NOT NULL) OR (missions_requises IS NOT NULL) OR (objectif_id IS NOT NULL) OR (length(btrim(condition)) > 0))),
    CONSTRAINT recompenses_familiales_badges_requis_check CHECK (((badges_requis IS NULL) OR (badges_requis > 0))),
    CONSTRAINT recompenses_familiales_missions_requises_check CHECK (((missions_requises IS NULL) OR (missions_requises > 0))),
    CONSTRAINT recompenses_familiales_points_requis_check CHECK (((points_requis IS NULL) OR (points_requis > 0))),
    CONSTRAINT visibilite_coherente CHECK ((montrer_existence OR ((NOT montrer_nature) AND (NOT montrer_date) AND (NOT montrer_progression))))
);


--
-- Name: TABLE recompenses_familiales; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.recompenses_familiales IS 'Récompenses réelles promises par les parents ou par le référent. Le nom dit leur nature — réelles, tenues par un adulte — et non leur origine.';


--
-- Name: COLUMN recompenses_familiales.badges_requis; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.recompenses_familiales.badges_requis IS 'Nombre de badges à obtenir. Comptés sur l''année scolaire en cours, tous champs confondus.';


--
-- Name: recompenses_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recompenses_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    recompense_id uuid NOT NULL,
    ancienne_date date NOT NULL,
    nouvelle_date date NOT NULL,
    motif text NOT NULL,
    reporte_par uuid NOT NULL,
    reporte_le timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: reperes_competences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reperes_competences (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    matiere_code text NOT NULL,
    cycle public.cycle_scolaire NOT NULL,
    domaine text NOT NULL,
    libelle text NOT NULL,
    code text,
    source public.source_repere DEFAULT 'amorce'::public.source_repere NOT NULL,
    ordre smallint DEFAULT 0 NOT NULL,
    actif boolean DEFAULT true NOT NULL,
    version_programme_id uuid,
    domaine_evaluation_id uuid,
    code_programme text,
    consigne_reference text DEFAULT ''::text NOT NULL,
    critere_de_reussite text DEFAULT ''::text NOT NULL,
    erreurs_types text[] DEFAULT '{}'::text[] NOT NULL
);


--
-- Name: COLUMN reperes_competences.critere_de_reussite; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.reperes_competences.critere_de_reussite IS 'Ce qui distingue une réussite d''un échec. Sans lui, une réponse ne se corrige que par ressemblance.';


--
-- Name: reperes_generables; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.reperes_generables AS
SELECT
    NULL::uuid AS id,
    NULL::text AS matiere_code,
    NULL::public.cycle_scolaire AS cycle,
    NULL::text AS domaine,
    NULL::text AS libelle,
    NULL::public.source_repere AS source,
    NULL::boolean AS a_un_critere,
    NULL::boolean AS a_des_erreurs_types,
    NULL::boolean AS rattache_a_un_domaine,
    NULL::bigint AS items_publies,
    NULL::boolean AS generable;


--
-- Name: suppressions_accords; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppressions_accords (
    demande_id uuid NOT NULL,
    profil_id uuid NOT NULL,
    signature_nom text NOT NULL,
    accorde_le timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT suppressions_accords_signature_nom_check CHECK ((length(btrim(signature_nom)) >= 2))
);


--
-- Name: suppressions_effectuees; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.suppressions_effectuees (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    enfant_id uuid NOT NULL,
    prenom text DEFAULT ''::text NOT NULL,
    demandee_par uuid,
    motif text NOT NULL,
    accords jsonb DEFAULT '[]'::jsonb NOT NULL,
    masquee_par uuid,
    masquee_le timestamp with time zone DEFAULT now() NOT NULL,
    purge_prevue_le date,
    purgee_le timestamp with time zone
);


--
-- Name: tentatives; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tentatives (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    exercice_id uuid NOT NULL,
    enfant_id uuid NOT NULL,
    reponse jsonb DEFAULT '{}'::jsonb NOT NULL,
    reussie boolean DEFAULT false NOT NULL,
    aide_utilisee boolean DEFAULT false NOT NULL,
    duree_secondes integer,
    cree_le timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: textes_consentement; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.textes_consentement (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type public.type_consentement NOT NULL,
    version text NOT NULL,
    titre text NOT NULL,
    contenu text NOT NULL,
    obligatoire boolean DEFAULT false NOT NULL,
    publie_le timestamp with time zone DEFAULT now() NOT NULL,
    retire_le timestamp with time zone
);


--
-- Name: versions_programme; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions_programme (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    source text DEFAULT 'synthese'::text NOT NULL,
    edition smallint NOT NULL,
    reference text DEFAULT ''::text NOT NULL,
    publie_le date,
    notes text DEFAULT ''::text NOT NULL,
    cree_le timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT versions_programme_source_check CHECK ((source = ANY (ARRAY['eduscol'::text, 'synthese'::text, 'local'::text])))
);


--
-- Name: acces_exceptionnels acces_exceptionnels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acces_exceptionnels
    ADD CONSTRAINT acces_exceptionnels_pkey PRIMARY KEY (id);


--
-- Name: acces_pieces acces_pieces_chemin_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acces_pieces
    ADD CONSTRAINT acces_pieces_chemin_key UNIQUE (chemin);


--
-- Name: acces_pieces acces_pieces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acces_pieces
    ADD CONSTRAINT acces_pieces_pkey PRIMARY KEY (id);


--
-- Name: adaptations adaptations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adaptations
    ADD CONSTRAINT adaptations_pkey PRIMARY KEY (id);


--
-- Name: alertes_actions alertes_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertes_actions
    ADD CONSTRAINT alertes_actions_pkey PRIMARY KEY (id);


--
-- Name: alertes_difficulte alertes_difficulte_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertes_difficulte
    ADD CONSTRAINT alertes_difficulte_pkey PRIMARY KEY (id);


--
-- Name: amorces_ecriture amorces_ecriture_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.amorces_ecriture
    ADD CONSTRAINT amorces_ecriture_pkey PRIMARY KEY (id);


--
-- Name: annees_enfant annees_enfant_enfant_id_annee_scolaire_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annees_enfant
    ADD CONSTRAINT annees_enfant_enfant_id_annee_scolaire_key UNIQUE (enfant_id, annee_scolaire);


--
-- Name: annees_enfant annees_enfant_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annees_enfant
    ADD CONSTRAINT annees_enfant_pkey PRIMARY KEY (id);


--
-- Name: appareils appareils_jeton_push_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appareils
    ADD CONSTRAINT appareils_jeton_push_key UNIQUE (jeton_push);


--
-- Name: appareils appareils_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appareils
    ADD CONSTRAINT appareils_pkey PRIMARY KEY (id);


--
-- Name: avis_ia avis_ia_adaptation_id_auteur_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.avis_ia
    ADD CONSTRAINT avis_ia_adaptation_id_auteur_id_key UNIQUE (adaptation_id, auteur_id);


--
-- Name: avis_ia avis_ia_mission_id_auteur_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.avis_ia
    ADD CONSTRAINT avis_ia_mission_id_auteur_id_key UNIQUE (mission_id, auteur_id);


--
-- Name: avis_ia avis_ia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.avis_ia
    ADD CONSTRAINT avis_ia_pkey PRIMARY KEY (id);


--
-- Name: badges_obtenus badges_obtenus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges_obtenus
    ADD CONSTRAINT badges_obtenus_pkey PRIMARY KEY (id);


--
-- Name: bilan_maitrises bilan_maitrises_bilan_id_repere_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_maitrises
    ADD CONSTRAINT bilan_maitrises_bilan_id_repere_id_key UNIQUE (bilan_id, repere_id);


--
-- Name: bilan_maitrises bilan_maitrises_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_maitrises
    ADD CONSTRAINT bilan_maitrises_pkey PRIMARY KEY (id);


--
-- Name: bilan_niveaux_matiere bilan_niveaux_matiere_bilan_id_matiere_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_niveaux_matiere
    ADD CONSTRAINT bilan_niveaux_matiere_bilan_id_matiere_code_key UNIQUE (bilan_id, matiere_code);


--
-- Name: bilan_niveaux_matiere bilan_niveaux_matiere_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_niveaux_matiere
    ADD CONSTRAINT bilan_niveaux_matiere_pkey PRIMARY KEY (id);


--
-- Name: bilan_questions bilan_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_questions
    ADD CONSTRAINT bilan_questions_pkey PRIMARY KEY (id);


--
-- Name: bilan_reponses bilan_reponses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_reponses
    ADD CONSTRAINT bilan_reponses_pkey PRIMARY KEY (id);


--
-- Name: bilan_reponses bilan_reponses_question_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_reponses
    ADD CONSTRAINT bilan_reponses_question_id_key UNIQUE (question_id);


--
-- Name: bilans_positionnement bilans_positionnement_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilans_positionnement
    ADD CONSTRAINT bilans_positionnement_pkey PRIMARY KEY (id);


--
-- Name: bilans_trimestriels bilans_trimestriels_enfant_id_annee_scolaire_trimestre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilans_trimestriels
    ADD CONSTRAINT bilans_trimestriels_enfant_id_annee_scolaire_trimestre_key UNIQUE (enfant_id, annee_scolaire, trimestre);


--
-- Name: bilans_trimestriels_matieres bilans_trimestriels_matieres_bilan_id_matiere_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilans_trimestriels_matieres
    ADD CONSTRAINT bilans_trimestriels_matieres_bilan_id_matiere_code_key UNIQUE (bilan_id, matiere_code);


--
-- Name: bilans_trimestriels_matieres bilans_trimestriels_matieres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilans_trimestriels_matieres
    ADD CONSTRAINT bilans_trimestriels_matieres_pkey PRIMARY KEY (id);


--
-- Name: bilans_trimestriels bilans_trimestriels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilans_trimestriels
    ADD CONSTRAINT bilans_trimestriels_pkey PRIMARY KEY (id);


--
-- Name: centres_interet centres_interet_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.centres_interet
    ADD CONSTRAINT centres_interet_pkey PRIMARY KEY (id);


--
-- Name: consentements consentements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consentements
    ADD CONSTRAINT consentements_pkey PRIMARY KEY (id);


--
-- Name: corrections corrections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.corrections
    ADD CONSTRAINT corrections_pkey PRIMARY KEY (id);


--
-- Name: corrections corrections_tentative_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.corrections
    ADD CONSTRAINT corrections_tentative_id_key UNIQUE (tentative_id);


--
-- Name: demandes_habilitation demandes_habilitation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demandes_habilitation
    ADD CONSTRAINT demandes_habilitation_pkey PRIMARY KEY (id);


--
-- Name: demandes_suppression demandes_suppression_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demandes_suppression
    ADD CONSTRAINT demandes_suppression_pkey PRIMARY KEY (id);


--
-- Name: documents_diagnostic documents_diagnostic_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents_diagnostic
    ADD CONSTRAINT documents_diagnostic_pkey PRIMARY KEY (id);


--
-- Name: domaines_evaluation domaines_evaluation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domaines_evaluation
    ADD CONSTRAINT domaines_evaluation_pkey PRIMARY KEY (id);


--
-- Name: domaines_evaluation domaines_evaluation_version_id_matiere_code_classe_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domaines_evaluation
    ADD CONSTRAINT domaines_evaluation_version_id_matiere_code_classe_code_key UNIQUE (version_id, matiere_code, classe, code);


--
-- Name: domaines_transversaux domaines_transversaux_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domaines_transversaux
    ADD CONSTRAINT domaines_transversaux_pkey PRIMARY KEY (code);


--
-- Name: enfants enfants_compte_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enfants
    ADD CONSTRAINT enfants_compte_id_key UNIQUE (compte_id);


--
-- Name: enfants enfants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enfants
    ADD CONSTRAINT enfants_pkey PRIMARY KEY (id);


--
-- Name: enfants_sante enfants_sante_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enfants_sante
    ADD CONSTRAINT enfants_sante_pkey PRIMARY KEY (enfant_id);


--
-- Name: envois envois_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envois
    ADD CONSTRAINT envois_pkey PRIMARY KEY (id);


--
-- Name: exercices exercices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exercices
    ADD CONSTRAINT exercices_pkey PRIMARY KEY (id);


--
-- Name: fils_participants fils_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fils_participants
    ADD CONSTRAINT fils_participants_pkey PRIMARY KEY (fil_id, profil_id);


--
-- Name: fils fils_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fils
    ADD CONSTRAINT fils_pkey PRIMARY KEY (id);


--
-- Name: generations_bilan generations_bilan_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generations_bilan
    ADD CONSTRAINT generations_bilan_pkey PRIMARY KEY (id);


--
-- Name: habilitation_pieces habilitation_pieces_chemin_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.habilitation_pieces
    ADD CONSTRAINT habilitation_pieces_chemin_key UNIQUE (chemin);


--
-- Name: habilitation_pieces habilitation_pieces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.habilitation_pieces
    ADD CONSTRAINT habilitation_pieces_pkey PRIMARY KEY (id);


--
-- Name: intervenants_enfant intervenants_enfant_enfant_id_profil_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervenants_enfant
    ADD CONSTRAINT intervenants_enfant_enfant_id_profil_id_key UNIQUE (enfant_id, profil_id);


--
-- Name: intervenants_enfant intervenants_enfant_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervenants_enfant
    ADD CONSTRAINT intervenants_enfant_pkey PRIMARY KEY (id);


--
-- Name: intervenants_matieres intervenants_matieres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervenants_matieres
    ADD CONSTRAINT intervenants_matieres_pkey PRIMARY KEY (intervenant_id, matiere_code);


--
-- Name: invitations invitations_jeton_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_jeton_key UNIQUE (jeton);


--
-- Name: invitations invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_pkey PRIMARY KEY (id);


--
-- Name: items_evaluation_nationale items_evaluation_nationale_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items_evaluation_nationale
    ADD CONSTRAINT items_evaluation_nationale_pkey PRIMARY KEY (id);


--
-- Name: items_evaluation_nationale items_evaluation_nationale_version_id_test_numero_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items_evaluation_nationale
    ADD CONSTRAINT items_evaluation_nationale_version_id_test_numero_key UNIQUE (version_id, test, numero);


--
-- Name: journal_acces journal_acces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_acces
    ADD CONSTRAINT journal_acces_pkey PRIMARY KEY (id);


--
-- Name: journal_entrees journal_entrees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_entrees
    ADD CONSTRAINT journal_entrees_pkey PRIMARY KEY (id);


--
-- Name: journal_ia journal_ia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_ia
    ADD CONSTRAINT journal_ia_pkey PRIMARY KEY (id);


--
-- Name: journal_medias journal_medias_chemin_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_medias
    ADD CONSTRAINT journal_medias_chemin_key UNIQUE (chemin);


--
-- Name: journal_medias journal_medias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_medias
    ADD CONSTRAINT journal_medias_pkey PRIMARY KEY (id);


--
-- Name: journee_etapes journee_etapes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journee_etapes
    ADD CONSTRAINT journee_etapes_pkey PRIMARY KEY (id);


--
-- Name: journee_preparatifs journee_preparatifs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journee_preparatifs
    ADD CONSTRAINT journee_preparatifs_pkey PRIMARY KEY (id);


--
-- Name: journee_reperes journee_reperes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journee_reperes
    ADD CONSTRAINT journee_reperes_pkey PRIMARY KEY (id);


--
-- Name: journees journees_enfant_id_jour_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journees
    ADD CONSTRAINT journees_enfant_id_jour_key UNIQUE (enfant_id, jour);


--
-- Name: journees journees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journees
    ADD CONSTRAINT journees_pkey PRIMARY KEY (id);


--
-- Name: matieres matieres_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.matieres
    ADD CONSTRAINT matieres_pkey PRIMARY KEY (code);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: missions missions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missions
    ADD CONSTRAINT missions_pkey PRIMARY KEY (id);


--
-- Name: modeles_exercice modeles_exercice_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modeles_exercice
    ADD CONSTRAINT modeles_exercice_pkey PRIMARY KEY (id);


--
-- Name: notations notations_mission_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notations
    ADD CONSTRAINT notations_mission_id_key UNIQUE (mission_id);


--
-- Name: notations notations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notations
    ADD CONSTRAINT notations_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: objectifs_demandes objectifs_demandes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs_demandes
    ADD CONSTRAINT objectifs_demandes_pkey PRIMARY KEY (id);


--
-- Name: objectifs objectifs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs
    ADD CONSTRAINT objectifs_pkey PRIMARY KEY (id);


--
-- Name: objectifs_validations objectifs_validations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs_validations
    ADD CONSTRAINT objectifs_validations_pkey PRIMARY KEY (objectif_id, profil_id);


--
-- Name: observations_capacites observations_capacites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observations_capacites
    ADD CONSTRAINT observations_capacites_pkey PRIMARY KEY (id);


--
-- Name: observations_reponses observations_reponses_observation_id_item_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observations_reponses
    ADD CONSTRAINT observations_reponses_observation_id_item_code_key UNIQUE (observation_id, item_code);


--
-- Name: observations_reponses observations_reponses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observations_reponses
    ADD CONSTRAINT observations_reponses_pkey PRIMARY KEY (id);


--
-- Name: periodes periodes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodes
    ADD CONSTRAINT periodes_pkey PRIMARY KEY (id);


--
-- Name: pieces_gagnees pieces_gagnees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pieces_gagnees
    ADD CONSTRAINT pieces_gagnees_pkey PRIMARY KEY (id);


--
-- Name: pieces_jointes pieces_jointes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pieces_jointes
    ADD CONSTRAINT pieces_jointes_pkey PRIMARY KEY (id);


--
-- Name: preferences_notification preferences_notification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preferences_notification
    ADD CONSTRAINT preferences_notification_pkey PRIMARY KEY (profil_id, type, canal);


--
-- Name: preparatifs_recurrents preparatifs_recurrents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preparatifs_recurrents
    ADD CONSTRAINT preparatifs_recurrents_pkey PRIMARY KEY (id);


--
-- Name: profils profils_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profils
    ADD CONSTRAINT profils_pkey PRIMARY KEY (id);


--
-- Name: programme_applicable programme_applicable_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_applicable
    ADD CONSTRAINT programme_applicable_pkey PRIMARY KEY (version_id, classe);


--
-- Name: projets_moteurs projets_moteurs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projets_moteurs
    ADD CONSTRAINT projets_moteurs_pkey PRIMARY KEY (id);


--
-- Name: questionnaires_capacites questionnaires_capacites_code_version_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questionnaires_capacites
    ADD CONSTRAINT questionnaires_capacites_code_version_key UNIQUE (code, version);


--
-- Name: questionnaires_capacites questionnaires_capacites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questionnaires_capacites
    ADD CONSTRAINT questionnaires_capacites_pkey PRIMARY KEY (id);


--
-- Name: quetes quetes_enfant_id_annee_id_trimestre_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quetes
    ADD CONSTRAINT quetes_enfant_id_annee_id_trimestre_key UNIQUE (enfant_id, annee_id, trimestre);


--
-- Name: quetes quetes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quetes
    ADD CONSTRAINT quetes_pkey PRIMARY KEY (id);


--
-- Name: recompenses_familiales recompenses_familiales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses_familiales
    ADD CONSTRAINT recompenses_familiales_pkey PRIMARY KEY (id);


--
-- Name: recompenses_obtenues recompenses_obtenues_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses_obtenues
    ADD CONSTRAINT recompenses_obtenues_pkey PRIMARY KEY (id);


--
-- Name: recompenses recompenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses
    ADD CONSTRAINT recompenses_pkey PRIMARY KEY (id);


--
-- Name: recompenses_reports recompenses_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses_reports
    ADD CONSTRAINT recompenses_reports_pkey PRIMARY KEY (id);


--
-- Name: reperes_competences reperes_competences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reperes_competences
    ADD CONSTRAINT reperes_competences_pkey PRIMARY KEY (id);


--
-- Name: supports supports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supports
    ADD CONSTRAINT supports_pkey PRIMARY KEY (id);


--
-- Name: suppressions_accords suppressions_accords_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppressions_accords
    ADD CONSTRAINT suppressions_accords_pkey PRIMARY KEY (demande_id, profil_id);


--
-- Name: suppressions_effectuees suppressions_effectuees_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppressions_effectuees
    ADD CONSTRAINT suppressions_effectuees_pkey PRIMARY KEY (id);


--
-- Name: tentatives tentatives_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tentatives
    ADD CONSTRAINT tentatives_pkey PRIMARY KEY (id);


--
-- Name: textes_consentement textes_consentement_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.textes_consentement
    ADD CONSTRAINT textes_consentement_pkey PRIMARY KEY (id);


--
-- Name: textes_consentement textes_consentement_type_version_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.textes_consentement
    ADD CONSTRAINT textes_consentement_type_version_key UNIQUE (type, version);


--
-- Name: versions_programme versions_programme_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions_programme
    ADD CONSTRAINT versions_programme_pkey PRIMARY KEY (id);


--
-- Name: versions_programme versions_programme_source_edition_reference_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions_programme
    ADD CONSTRAINT versions_programme_source_edition_reference_key UNIQUE (source, edition, reference);


--
-- Name: acces_exceptionnels_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX acces_exceptionnels_enfant_idx ON public.acces_exceptionnels USING btree (enfant_id, ouvert_le DESC);


--
-- Name: acces_exceptionnels_un_seul_actif; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX acces_exceptionnels_un_seul_actif ON public.acces_exceptionnels USING btree (enfant_id, ouvert_par) WHERE (clos_le IS NULL);


--
-- Name: acces_information_due_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX acces_information_due_idx ON public.acces_exceptionnels USING btree (ouvert_le) WHERE ((nature = 'requisition'::public.nature_acces) AND (information_faite_le IS NULL));


--
-- Name: acces_pieces_acces_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX acces_pieces_acces_idx ON public.acces_pieces USING btree (acces_id);


--
-- Name: adaptations_support_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX adaptations_support_idx ON public.adaptations USING btree (support_id, forme);


--
-- Name: alertes_actions_alerte_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX alertes_actions_alerte_idx ON public.alertes_actions USING btree (alerte_id, cree_le);


--
-- Name: alertes_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX alertes_enfant_idx ON public.alertes_difficulte USING btree (enfant_id, derniere_le DESC);


--
-- Name: alertes_une_seule_ouverte_par_objectif; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX alertes_une_seule_ouverte_par_objectif ON public.alertes_difficulte USING btree (enfant_id, objectif_id) WHERE ((statut = 'ouverte'::public.statut_alerte) AND (objectif_id IS NOT NULL));


--
-- Name: alertes_une_seule_ouverte_par_repere; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX alertes_une_seule_ouverte_par_repere ON public.alertes_difficulte USING btree (enfant_id, repere_id) WHERE ((statut = 'ouverte'::public.statut_alerte) AND (repere_id IS NOT NULL));


--
-- Name: amorces_contexte_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX amorces_contexte_idx ON public.amorces_ecriture USING btree (contexte, ordre) WHERE actif;


--
-- Name: annees_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX annees_enfant_idx ON public.annees_enfant USING btree (enfant_id, debute_le DESC);


--
-- Name: annees_une_seule_ouverte; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX annees_une_seule_ouverte ON public.annees_enfant USING btree (enfant_id) WHERE (close_le IS NULL);


--
-- Name: appareils_profil_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX appareils_profil_idx ON public.appareils USING btree (profil_id) WHERE actif;


--
-- Name: avis_ia_adaptation_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX avis_ia_adaptation_idx ON public.avis_ia USING btree (adaptation_id);


--
-- Name: avis_ia_mission_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX avis_ia_mission_idx ON public.avis_ia USING btree (mission_id);


--
-- Name: avis_ia_negatifs_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX avis_ia_negatifs_idx ON public.avis_ia USING btree (cree_le DESC) WHERE (verdict <> 'pertinente'::public.verdict_ia);


--
-- Name: badge_un_niveau_par_domaine; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX badge_un_niveau_par_domaine ON public.badges_obtenus USING btree (enfant_id, domaine_code, niveau) WHERE (domaine_code IS NOT NULL);


--
-- Name: badge_un_niveau_par_matiere; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX badge_un_niveau_par_matiere ON public.badges_obtenus USING btree (enfant_id, matiere_code, niveau) WHERE (matiere_code IS NOT NULL);


--
-- Name: badges_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX badges_enfant_idx ON public.badges_obtenus USING btree (enfant_id, obtenu_le DESC);


--
-- Name: bilan_niveaux_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bilan_niveaux_enfant_idx ON public.bilan_niveaux_matiere USING btree (enfant_id, matiere_code);


--
-- Name: bilan_questions_bilan_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bilan_questions_bilan_idx ON public.bilan_questions USING btree (bilan_id, ordre);


--
-- Name: bilans_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bilans_enfant_idx ON public.bilans_positionnement USING btree (enfant_id, demarre_le DESC);


--
-- Name: bilans_trimestriels_annee_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bilans_trimestriels_annee_idx ON public.bilans_trimestriels USING btree (annee_id);


--
-- Name: bilans_trimestriels_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX bilans_trimestriels_enfant_idx ON public.bilans_trimestriels USING btree (enfant_id, annee_scolaire, trimestre);


--
-- Name: bilans_un_seul_en_cours; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX bilans_un_seul_en_cours ON public.bilans_positionnement USING btree (enfant_id) WHERE (statut = 'en_cours'::public.statut_bilan);


--
-- Name: centres_interet_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX centres_interet_enfant_idx ON public.centres_interet USING btree (enfant_id);


--
-- Name: consentements_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX consentements_enfant_idx ON public.consentements USING btree (enfant_id, type) WHERE (revoque_le IS NULL);


--
-- Name: corrections_correcteur_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX corrections_correcteur_idx ON public.corrections USING btree (corrigee_par, corrigee_le DESC);


--
-- Name: documents_diagnostic_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX documents_diagnostic_enfant_idx ON public.documents_diagnostic USING btree (enfant_id, depose_le DESC);


--
-- Name: domaines_evaluation_classe_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX domaines_evaluation_classe_idx ON public.domaines_evaluation USING btree (classe, matiere_code, ordre);


--
-- Name: enfants_a_purger_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enfants_a_purger_idx ON public.enfants USING btree (purge_prevue_le) WHERE (archive_le IS NOT NULL);


--
-- Name: enfants_cree_par_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX enfants_cree_par_idx ON public.enfants USING btree (cree_par) WHERE (archive_le IS NULL);


--
-- Name: envois_a_traiter_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX envois_a_traiter_idx ON public.envois USING btree (cree_le) WHERE (statut = 'a_envoyer'::public.statut_envoi);


--
-- Name: envois_destinataire_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX envois_destinataire_idx ON public.envois USING btree (destinataire_id, cree_le DESC);


--
-- Name: exercices_mission_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX exercices_mission_idx ON public.exercices USING btree (mission_id, ordre);


--
-- Name: exercices_modele_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX exercices_modele_idx ON public.exercices USING btree (modele_id);


--
-- Name: fils_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fils_enfant_idx ON public.fils USING btree (enfant_id, dernier_message_le DESC);


--
-- Name: fils_participants_profil_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX fils_participants_profil_idx ON public.fils_participants USING btree (profil_id);


--
-- Name: generations_a_traiter_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX generations_a_traiter_idx ON public.generations_bilan USING btree (cree_le) WHERE (statut = ANY (ARRAY['en_attente'::public.statut_generation, 'echec'::public.statut_generation]));


--
-- Name: generations_une_seule_en_cours; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX generations_une_seule_en_cours ON public.generations_bilan USING btree (enfant_id) WHERE (statut = ANY (ARRAY['en_attente'::public.statut_generation, 'en_cours'::public.statut_generation]));


--
-- Name: habilitation_pieces_demande_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX habilitation_pieces_demande_idx ON public.habilitation_pieces USING btree (demande_id);


--
-- Name: habilitation_une_seule_en_attente; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX habilitation_une_seule_en_attente ON public.demandes_habilitation USING btree (profil_id) WHERE (statut = 'en_attente'::public.statut_habilitation);


--
-- Name: habilitations_a_instruire_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX habilitations_a_instruire_idx ON public.demandes_habilitation USING btree (cree_le) WHERE (statut = 'en_attente'::public.statut_habilitation);


--
-- Name: intervenants_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX intervenants_enfant_idx ON public.intervenants_enfant USING btree (enfant_id) WHERE (retire_le IS NULL);


--
-- Name: intervenants_matieres_matiere_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX intervenants_matieres_matiere_idx ON public.intervenants_matieres USING btree (matiere_code);


--
-- Name: intervenants_profil_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX intervenants_profil_idx ON public.intervenants_enfant USING btree (profil_id) WHERE (retire_le IS NULL);


--
-- Name: intervenants_succession_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX intervenants_succession_idx ON public.intervenants_enfant USING btree (succede_a);


--
-- Name: invitations_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX invitations_email_idx ON public.invitations USING btree (lower(email)) WHERE ((acceptee_le IS NULL) AND (annulee_le IS NULL));


--
-- Name: items_evaluation_domaine_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX items_evaluation_domaine_idx ON public.items_evaluation_nationale USING btree (domaine_evaluation_id, test, numero);


--
-- Name: items_evaluation_repere_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX items_evaluation_repere_idx ON public.items_evaluation_nationale USING btree (repere_id);


--
-- Name: journal_acces_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journal_acces_enfant_idx ON public.journal_acces USING btree (enfant_id, cree_le DESC);


--
-- Name: journal_entrees_auteur_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journal_entrees_auteur_idx ON public.journal_entrees USING btree (auteur_id, cree_le DESC);


--
-- Name: journal_entrees_journee_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journal_entrees_journee_idx ON public.journal_entrees USING btree (journee_id, cree_le);


--
-- Name: journal_ia_cout_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journal_ia_cout_idx ON public.journal_ia USING btree (cree_le DESC);


--
-- Name: journal_ia_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journal_ia_enfant_idx ON public.journal_ia USING btree (enfant_id, cree_le DESC);


--
-- Name: journal_medias_journee_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journal_medias_journee_idx ON public.journal_medias USING btree (journee_id, cree_le);


--
-- Name: journee_etapes_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journee_etapes_idx ON public.journee_etapes USING btree (journee_id, ordre);


--
-- Name: journee_preparatifs_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journee_preparatifs_idx ON public.journee_preparatifs USING btree (journee_id, ordre);


--
-- Name: journee_reperes_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journee_reperes_idx ON public.journee_reperes USING btree (journee_id, ordre);


--
-- Name: journees_frise_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journees_frise_idx ON public.journees USING btree (enfant_id, jour DESC);


--
-- Name: journees_periode_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX journees_periode_idx ON public.journees USING btree (periode_id, jour);


--
-- Name: messages_fil_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_fil_idx ON public.messages USING btree (fil_id, cree_le);


--
-- Name: missions_a_corriger_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX missions_a_corriger_idx ON public.missions USING btree (auteur_id, cree_le) WHERE (nature = 'evaluation'::public.nature_travail);


--
-- Name: missions_a_retransposer_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX missions_a_retransposer_idx ON public.missions USING btree (enfant_id) WHERE a_retransposer;


--
-- Name: missions_a_valider_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX missions_a_valider_idx ON public.missions USING btree (enfant_id) WHERE (statut = 'proposee'::public.statut_mission);


--
-- Name: missions_auteur_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX missions_auteur_idx ON public.missions USING btree (auteur_id, cree_le DESC) WHERE (nature = 'evaluation'::public.nature_travail);


--
-- Name: missions_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX missions_enfant_idx ON public.missions USING btree (enfant_id, statut, ordre);


--
-- Name: missions_fourni_par_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX missions_fourni_par_idx ON public.missions USING btree (fourni_par);


--
-- Name: missions_nature_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX missions_nature_idx ON public.missions USING btree (enfant_id, nature, cree_le DESC);


--
-- Name: missions_quete_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX missions_quete_idx ON public.missions USING btree (quete_id);


--
-- Name: modeles_a_valider_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX modeles_a_valider_idx ON public.modeles_exercice USING btree (matiere_code, cree_le) WHERE (statut = 'propose'::public.statut_modele);


--
-- Name: modeles_utilisables_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX modeles_utilisables_idx ON public.modeles_exercice USING btree (matiere_code, repere_id, difficulte) WHERE (statut = 'valide'::public.statut_modele);


--
-- Name: notations_mission_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notations_mission_idx ON public.notations USING btree (mission_id);


--
-- Name: notifications_non_lues_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_non_lues_idx ON public.notifications USING btree (destinataire_id, cree_le DESC) WHERE (lue_le IS NULL);


--
-- Name: objectifs_a_valider_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX objectifs_a_valider_idx ON public.objectifs USING btree (enfant_id) WHERE (statut = 'propose'::public.statut_objectif);


--
-- Name: objectifs_annee_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX objectifs_annee_idx ON public.objectifs USING btree (annee_id);


--
-- Name: objectifs_demandes_objectif_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX objectifs_demandes_objectif_idx ON public.objectifs_demandes USING btree (objectif_id, cree_le DESC);


--
-- Name: objectifs_demandes_ouvertes_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX objectifs_demandes_ouvertes_idx ON public.objectifs_demandes USING btree (objectif_id) WHERE (statut = 'ouverte'::public.statut_demande);


--
-- Name: objectifs_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX objectifs_enfant_idx ON public.objectifs USING btree (enfant_id, debute_le DESC);


--
-- Name: objectifs_enfants_de_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX objectifs_enfants_de_idx ON public.objectifs USING btree (objectif_parent_id);


--
-- Name: objectifs_periode_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX objectifs_periode_idx ON public.objectifs USING btree (enfant_id, echeance_le) WHERE (statut = ANY (ARRAY['propose'::public.statut_objectif, 'valide'::public.statut_objectif]));


--
-- Name: objectifs_validations_profil_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX objectifs_validations_profil_idx ON public.objectifs_validations USING btree (profil_id);


--
-- Name: observations_capacites_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX observations_capacites_enfant_idx ON public.observations_capacites USING btree (enfant_id, rempli_le DESC);


--
-- Name: periodes_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX periodes_enfant_idx ON public.periodes USING btree (enfant_id, debut DESC);


--
-- Name: pieces_gagnees_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pieces_gagnees_enfant_idx ON public.pieces_gagnees USING btree (enfant_id, cree_le DESC);


--
-- Name: pieces_jointes_message_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX pieces_jointes_message_idx ON public.pieces_jointes USING btree (message_id);


--
-- Name: pieces_une_fois_par_exercice; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX pieces_une_fois_par_exercice ON public.pieces_gagnees USING btree (enfant_id, exercice_id) WHERE (source = 'exercice'::public.source_pieces);


--
-- Name: pieces_une_fois_par_mission; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX pieces_une_fois_par_mission ON public.pieces_gagnees USING btree (enfant_id, mission_id) WHERE (source = 'mission'::public.source_pieces);


--
-- Name: pieces_une_fois_par_notation; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX pieces_une_fois_par_notation ON public.pieces_gagnees USING btree (notation_id) WHERE (source = 'bonus_note'::public.source_pieces);


--
-- Name: preparatifs_recurrents_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX preparatifs_recurrents_idx ON public.preparatifs_recurrents USING btree (enfant_id, ordre) WHERE actif;


--
-- Name: programme_applicable_classe_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX programme_applicable_classe_idx ON public.programme_applicable USING btree (classe, rentree_debut DESC);


--
-- Name: projets_moteurs_un_seul_actif; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX projets_moteurs_un_seul_actif ON public.projets_moteurs USING btree (enfant_id) WHERE actif;


--
-- Name: questionnaires_un_seul_courant; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX questionnaires_un_seul_courant ON public.questionnaires_capacites USING btree (code) WHERE courant;


--
-- Name: quetes_badges_vises_unique; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX quetes_badges_vises_unique ON public.quetes_badges_vises USING btree (quete_id, COALESCE(matiere_code, domaine_code));


--
-- Name: quetes_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX quetes_enfant_idx ON public.quetes USING btree (enfant_id, trimestre);


--
-- Name: quetes_une_seule_en_cours; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX quetes_une_seule_en_cours ON public.quetes USING btree (enfant_id) WHERE (statut = 'en_cours'::public.statut_quete);


--
-- Name: recompenses_a_devoiler_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recompenses_a_devoiler_idx ON public.recompenses_familiales USING btree (enfant_id, prevue_le) WHERE ((statut = 'promise'::public.statut_recompense_familiale) AND (devoilee_le IS NULL) AND (NOT montrer_nature));


--
-- Name: recompenses_catalogue_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recompenses_catalogue_idx ON public.recompenses USING btree (projet_moteur_id, categorie, ordre) WHERE disponible;


--
-- Name: recompenses_familiales_a_venir_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recompenses_familiales_a_venir_idx ON public.recompenses_familiales USING btree (enfant_id, prevue_le) WHERE (statut = 'promise'::public.statut_recompense_familiale);


--
-- Name: recompenses_obtenues_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recompenses_obtenues_enfant_idx ON public.recompenses_obtenues USING btree (enfant_id, obtenue_le DESC);


--
-- Name: recompenses_projet_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recompenses_projet_idx ON public.recompenses USING btree (projet_moteur_id);


--
-- Name: recompenses_reports_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX recompenses_reports_idx ON public.recompenses_reports USING btree (recompense_id, reporte_le DESC);


--
-- Name: referent_un_seul_principal; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX referent_un_seul_principal ON public.intervenants_enfant USING btree (enfant_id) WHERE ((role = 'referent'::public.role_intervenant) AND principal AND (retire_le IS NULL));


--
-- Name: reperes_domaine_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reperes_domaine_idx ON public.reperes_competences USING btree (domaine_evaluation_id);


--
-- Name: reperes_matiere_cycle_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reperes_matiere_cycle_idx ON public.reperes_competences USING btree (matiere_code, cycle) WHERE actif;


--
-- Name: reperes_version_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reperes_version_idx ON public.reperes_competences USING btree (version_programme_id);


--
-- Name: supports_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX supports_enfant_idx ON public.supports USING btree (enfant_id, cree_le DESC);


--
-- Name: supports_fourni_par_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX supports_fourni_par_idx ON public.supports USING btree (fourni_par);


--
-- Name: suppression_une_seule_en_cours; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX suppression_une_seule_en_cours ON public.demandes_suppression USING btree (enfant_id) WHERE ((statut = ANY (ARRAY['en_attente'::public.statut_suppression, 'accordee'::public.statut_suppression])) AND (enfant_id IS NOT NULL));


--
-- Name: suppressions_a_purger_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX suppressions_a_purger_idx ON public.suppressions_effectuees USING btree (purge_prevue_le) WHERE (purgee_le IS NULL);


--
-- Name: suppressions_effectuees_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX suppressions_effectuees_idx ON public.suppressions_effectuees USING btree (masquee_le DESC);


--
-- Name: tentatives_enfant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tentatives_enfant_idx ON public.tentatives USING btree (enfant_id, cree_le DESC);


--
-- Name: tentatives_exercice_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tentatives_exercice_idx ON public.tentatives USING btree (exercice_id, cree_le DESC);


--
-- Name: textes_en_vigueur_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX textes_en_vigueur_idx ON public.textes_consentement USING btree (type, publie_le DESC) WHERE (retire_le IS NULL);


--
-- Name: reperes_generables _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.reperes_generables WITH (security_invoker='true') AS
 SELECT r.id,
    r.matiere_code,
    r.cycle,
    r.domaine,
    r.libelle,
    r.source,
    (r.critere_de_reussite <> ''::text) AS a_un_critere,
    (cardinality(r.erreurs_types) > 0) AS a_des_erreurs_types,
    (r.domaine_evaluation_id IS NOT NULL) AS rattache_a_un_domaine,
    count(i.id) AS items_publies,
    ((r.critere_de_reussite <> ''::text) OR (count(i.id) > 0)) AS generable
   FROM (public.reperes_competences r
     LEFT JOIN public.items_evaluation_nationale i ON ((i.repere_id = r.id)))
  WHERE r.actif
  GROUP BY r.id;


--
-- Name: acces_exceptionnels acces_exceptionnels_annoncent; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER acces_exceptionnels_annoncent AFTER INSERT ON public.acces_exceptionnels FOR EACH ROW EXECUTE FUNCTION public.annoncer_l_acces_exceptionnel();


--
-- Name: acces_exceptionnels acces_exceptionnels_figent_leur_borne; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER acces_exceptionnels_figent_leur_borne BEFORE UPDATE ON public.acces_exceptionnels FOR EACH ROW EXECUTE FUNCTION public.figer_la_borne_de_l_acces();


--
-- Name: acces_pieces acces_pieces_restreignent_l_ecartement; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER acces_pieces_restreignent_l_ecartement BEFORE UPDATE ON public.acces_pieces FOR EACH ROW EXECUTE FUNCTION public.restreindre_l_ecartement_de_piece();


--
-- Name: alertes_difficulte alertes_exigent_une_action; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER alertes_exigent_une_action BEFORE INSERT OR UPDATE ON public.alertes_difficulte FOR EACH ROW EXECUTE FUNCTION public.exiger_une_action_avant_cloture();


--
-- Name: badges_obtenus badges_concluent_la_quete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER badges_concluent_la_quete AFTER INSERT ON public.badges_obtenus FOR EACH ROW EXECUTE FUNCTION public.conclure_la_quete();


--
-- Name: bilans_positionnement bilans_positionnement_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER bilans_positionnement_touch BEFORE UPDATE ON public.bilans_positionnement FOR EACH ROW EXECUTE FUNCTION public.touch_modifie_le();


--
-- Name: bilans_trimestriels bilans_trimestriels_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER bilans_trimestriels_touch BEFORE UPDATE ON public.bilans_trimestriels FOR EACH ROW EXECUTE FUNCTION public.touch_modifie_le();


--
-- Name: consentements consentements_figes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER consentements_figes BEFORE UPDATE ON public.consentements FOR EACH ROW EXECUTE FUNCTION public.figer_le_consentement();


--
-- Name: enfants enfants_protegent_le_compte; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER enfants_protegent_le_compte BEFORE UPDATE ON public.enfants FOR EACH ROW EXECUTE FUNCTION public.proteger_le_compte_enfant();


--
-- Name: enfants enfants_protegent_leur_archivage; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER enfants_protegent_leur_archivage BEFORE UPDATE ON public.enfants FOR EACH ROW EXECUTE FUNCTION public.proteger_l_archivage();


--
-- Name: enfants enfants_protegent_leur_composition; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER enfants_protegent_leur_composition BEFORE UPDATE ON public.enfants FOR EACH ROW EXECUTE FUNCTION public.proteger_la_composition_parentale();


--
-- Name: enfants enfants_protegent_leur_suppression; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER enfants_protegent_leur_suppression BEFORE DELETE ON public.enfants FOR EACH ROW EXECUTE FUNCTION public.proteger_la_suppression_de_l_enfant();


--
-- Name: enfants_sante enfants_sante_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER enfants_sante_touch BEFORE UPDATE ON public.enfants_sante FOR EACH ROW EXECUTE FUNCTION public.touch_modifie_le();


--
-- Name: enfants enfants_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER enfants_touch BEFORE UPDATE ON public.enfants FOR EACH ROW EXECUTE FUNCTION public.touch_modifie_le();


--
-- Name: enfants enfants_tracent_les_corrections; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER enfants_tracent_les_corrections AFTER UPDATE ON public.enfants FOR EACH ROW EXECUTE FUNCTION public.tracer_la_correction_administrative();


--
-- Name: envois envois_sonnent; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER envois_sonnent AFTER INSERT ON public.envois FOR EACH STATEMENT EXECUTE FUNCTION public.sonner_la_file();


--
-- Name: fils fils_inscrivent_leur_createur; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER fils_inscrivent_leur_createur AFTER INSERT ON public.fils FOR EACH ROW EXECUTE FUNCTION public.inscrire_le_createur();


--
-- Name: fils fils_portee_figee; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER fils_portee_figee BEFORE UPDATE ON public.fils FOR EACH ROW EXECUTE FUNCTION public.figer_la_portee();


--
-- Name: generations_bilan generations_sonnent; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER generations_sonnent AFTER INSERT ON public.generations_bilan FOR EACH STATEMENT EXECUTE FUNCTION public.sonner_les_generations();


--
-- Name: intervenants_enfant intervenants_designent_le_premier_referent; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER intervenants_designent_le_premier_referent BEFORE INSERT ON public.intervenants_enfant FOR EACH ROW EXECUTE FUNCTION public.designer_le_premier_referent();


--
-- Name: intervenants_enfant intervenants_exigent_un_parent; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER intervenants_exigent_un_parent AFTER DELETE OR UPDATE ON public.intervenants_enfant DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.exiger_un_parent_rattache();


--
-- Name: intervenants_enfant intervenants_exigent_un_referent; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER intervenants_exigent_un_referent AFTER DELETE OR UPDATE ON public.intervenants_enfant DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.exiger_un_referent_principal();


--
-- Name: intervenants_enfant intervenants_exigent_une_matiere; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER intervenants_exigent_une_matiere AFTER INSERT OR UPDATE ON public.intervenants_enfant DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.exiger_une_matiere_au_rattachement();


--
-- Name: intervenants_matieres intervenants_matieres_exigent_une_matiere; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER intervenants_matieres_exigent_une_matiere AFTER DELETE ON public.intervenants_matieres DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION public.exiger_une_matiere_a_l_enseignant();


--
-- Name: intervenants_enfant intervenants_protegent_le_lien_parental; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER intervenants_protegent_le_lien_parental BEFORE DELETE OR UPDATE ON public.intervenants_enfant FOR EACH ROW EXECUTE FUNCTION public.proteger_le_lien_parental();


--
-- Name: intervenants_enfant intervenants_tracent_les_corrections; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER intervenants_tracent_les_corrections AFTER INSERT OR DELETE OR UPDATE ON public.intervenants_enfant FOR EACH ROW EXECUTE FUNCTION public.tracer_la_correction_administrative();


--
-- Name: journal_entrees journal_entrees_encouragements_visibles; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journal_entrees_encouragements_visibles BEFORE INSERT OR UPDATE ON public.journal_entrees FOR EACH ROW EXECUTE FUNCTION public.encouragement_toujours_visible();


--
-- Name: journee_etapes journee_etapes_protegent_les_cases; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journee_etapes_protegent_les_cases BEFORE UPDATE ON public.journee_etapes FOR EACH ROW EXECUTE FUNCTION public.proteger_les_cases_de_l_enfant();


--
-- Name: journees journees_garnissent_les_preparatifs; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journees_garnissent_les_preparatifs AFTER INSERT ON public.journees FOR EACH ROW EXECUTE FUNCTION public.garnir_les_preparatifs();


--
-- Name: journees journees_horodatent_l_humeur; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journees_horodatent_l_humeur BEFORE INSERT OR UPDATE ON public.journees FOR EACH ROW EXECUTE FUNCTION public.horodater_l_humeur();


--
-- Name: journees journees_protegent_la_page_de_l_enfant; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journees_protegent_la_page_de_l_enfant BEFORE UPDATE ON public.journees FOR EACH ROW EXECUTE FUNCTION public.proteger_la_page_de_l_enfant();


--
-- Name: journees journees_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER journees_touch BEFORE UPDATE ON public.journees FOR EACH ROW EXECUTE FUNCTION public.touch_modifie_le();


--
-- Name: messages messages_notifient; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER messages_notifient AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION public.notifier_nouveau_message();


--
-- Name: missions missions_attribuent_leurs_pieces; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER missions_attribuent_leurs_pieces AFTER UPDATE ON public.missions FOR EACH ROW EXECUTE FUNCTION public.attribuer_les_pieces_de_la_mission();


--
-- Name: missions missions_exigent_la_retransposition; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER missions_exigent_la_retransposition BEFORE INSERT OR UPDATE ON public.missions FOR EACH ROW EXECUTE FUNCTION public.exiger_la_retransposition();


--
-- Name: missions missions_restreignent_leur_composition; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER missions_restreignent_leur_composition BEFORE UPDATE ON public.missions FOR EACH ROW EXECUTE FUNCTION public.restreindre_la_composition_de_mission();


--
-- Name: missions missions_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER missions_touch BEFORE UPDATE ON public.missions FOR EACH ROW EXECUTE FUNCTION public.touch_modifie_le();


--
-- Name: missions missions_verifient_leur_fournisseur; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER missions_verifient_leur_fournisseur BEFORE INSERT OR UPDATE ON public.missions FOR EACH ROW EXECUTE FUNCTION public.verifier_le_fournisseur();


--
-- Name: modeles_exercice modeles_exercice_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER modeles_exercice_touch BEFORE UPDATE ON public.modeles_exercice FOR EACH ROW EXECUTE FUNCTION public.touch_modifie_le();


--
-- Name: modeles_exercice modeles_retouches_a_revalider; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER modeles_retouches_a_revalider BEFORE UPDATE ON public.modeles_exercice FOR EACH ROW EXECUTE FUNCTION public.invalider_le_modele_retouche();


--
-- Name: notations notations_attribuent_le_bonus; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notations_attribuent_le_bonus AFTER INSERT OR UPDATE ON public.notations FOR EACH ROW EXECUTE FUNCTION public.attribuer_le_bonus_de_note();


--
-- Name: notations notations_refusent_les_devoirs; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notations_refusent_les_devoirs BEFORE INSERT OR UPDATE ON public.notations FOR EACH ROW EXECUTE FUNCTION public.refuser_la_note_sur_un_devoir();


--
-- Name: notifications notifications_alimentent_la_file; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER notifications_alimentent_la_file AFTER INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION public.mettre_en_file();


--
-- Name: objectifs_demandes objectifs_demandes_notifient; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER objectifs_demandes_notifient AFTER INSERT ON public.objectifs_demandes FOR EACH ROW EXECUTE FUNCTION public.notifier_demande_objectif();


--
-- Name: objectifs_demandes objectifs_demandes_verifient_leur_traitement; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER objectifs_demandes_verifient_leur_traitement BEFORE INSERT OR UPDATE ON public.objectifs_demandes FOR EACH ROW EXECUTE FUNCTION public.verifier_le_traitement_de_la_demande();


--
-- Name: objectifs objectifs_exigent_le_quorum; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER objectifs_exigent_le_quorum BEFORE INSERT OR UPDATE ON public.objectifs FOR EACH ROW EXECUTE FUNCTION public.exiger_le_quorum();


--
-- Name: objectifs objectifs_proposes_notifient; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER objectifs_proposes_notifient AFTER INSERT ON public.objectifs FOR EACH ROW WHEN ((new.statut = 'propose'::public.statut_objectif)) EXECUTE FUNCTION public.notifier_objectif_propose();


--
-- Name: objectifs objectifs_restreignent_le_pilotage; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER objectifs_restreignent_le_pilotage BEFORE UPDATE ON public.objectifs FOR EACH ROW EXECUTE FUNCTION public.restreindre_le_pilotage();


--
-- Name: objectifs objectifs_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER objectifs_touch BEFORE UPDATE ON public.objectifs FOR EACH ROW EXECUTE FUNCTION public.touch_modifie_le();


--
-- Name: objectifs_validations objectifs_validations_concluent; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER objectifs_validations_concluent AFTER INSERT ON public.objectifs_validations FOR EACH ROW EXECUTE FUNCTION public.conclure_la_validation();


--
-- Name: objectifs objectifs_verifient_leur_parent; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER objectifs_verifient_leur_parent BEFORE INSERT OR UPDATE ON public.objectifs FOR EACH ROW EXECUTE FUNCTION public.verifier_le_parent_de_l_objectif();


--
-- Name: objectifs objectifs_verifient_leur_validation; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER objectifs_verifient_leur_validation BEFORE INSERT OR UPDATE ON public.objectifs FOR EACH ROW EXECUTE FUNCTION public.verifier_la_validation_de_l_objectif();


--
-- Name: observations_capacites observations_capacites_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER observations_capacites_touch BEFORE UPDATE ON public.observations_capacites FOR EACH ROW EXECUTE FUNCTION public.touch_modifie_le();


--
-- Name: profils profils_protegent_leur_role; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER profils_protegent_leur_role BEFORE UPDATE ON public.profils FOR EACH ROW EXECUTE FUNCTION public.proteger_le_role_plateforme();


--
-- Name: profils profils_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER profils_touch BEFORE UPDATE ON public.profils FOR EACH ROW EXECUTE FUNCTION public.touch_modifie_le();


--
-- Name: projets_moteurs projets_moteurs_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER projets_moteurs_touch BEFORE UPDATE ON public.projets_moteurs FOR EACH ROW EXECUTE FUNCTION public.touch_modifie_le();


--
-- Name: quetes quetes_protegent_leur_statut; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER quetes_protegent_leur_statut BEFORE UPDATE ON public.quetes FOR EACH ROW EXECUTE FUNCTION public.proteger_le_statut_de_la_quete();


--
-- Name: recompenses_familiales recompenses_familiales_signalent_le_palier; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER recompenses_familiales_signalent_le_palier AFTER UPDATE ON public.recompenses_familiales FOR EACH ROW EXECUTE FUNCTION public.signaler_le_palier_atteint();


--
-- Name: recompenses_familiales recompenses_familiales_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER recompenses_familiales_touch BEFORE UPDATE ON public.recompenses_familiales FOR EACH ROW EXECUTE FUNCTION public.touch_modifie_le();


--
-- Name: recompenses_familiales recompenses_figent_ce_qui_a_ete_vu; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER recompenses_figent_ce_qui_a_ete_vu BEFORE UPDATE ON public.recompenses_familiales FOR EACH ROW EXECUTE FUNCTION public.figer_ce_que_l_enfant_a_vu();


--
-- Name: recompenses_familiales recompenses_figent_la_visibilite; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER recompenses_figent_la_visibilite BEFORE UPDATE ON public.recompenses_familiales FOR EACH ROW EXECUTE FUNCTION public.figer_la_visibilite();


--
-- Name: recompenses_obtenues recompenses_obtenues_verifient_l_acquisition; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER recompenses_obtenues_verifient_l_acquisition BEFORE INSERT ON public.recompenses_obtenues FOR EACH ROW EXECUTE FUNCTION public.verifier_l_acquisition();


--
-- Name: recompenses recompenses_verifient_leur_prerequis; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER recompenses_verifient_leur_prerequis BEFORE INSERT OR UPDATE ON public.recompenses FOR EACH ROW EXECUTE FUNCTION public.verifier_le_prerequis_de_recompense();


--
-- Name: supports supports_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER supports_touch BEFORE UPDATE ON public.supports FOR EACH ROW EXECUTE FUNCTION public.touch_modifie_le();


--
-- Name: supports supports_verifient_leur_fournisseur; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER supports_verifient_leur_fournisseur BEFORE INSERT OR UPDATE ON public.supports FOR EACH ROW EXECUTE FUNCTION public.verifier_le_fournisseur_du_support();


--
-- Name: tentatives tentatives_alertent_sur_echec_repete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tentatives_alertent_sur_echec_repete AFTER INSERT ON public.tentatives FOR EACH ROW EXECUTE FUNCTION public.alerter_sur_echec_repete();


--
-- Name: tentatives tentatives_attribuent_les_pieces; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tentatives_attribuent_les_pieces AFTER INSERT ON public.tentatives FOR EACH ROW EXECUTE FUNCTION public.attribuer_les_pieces_de_l_exercice();


--
-- Name: tentatives tentatives_signalent_le_palier; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tentatives_signalent_le_palier AFTER INSERT ON public.tentatives FOR EACH ROW EXECUTE FUNCTION public.signaler_le_palier_franchi();


--
-- Name: textes_consentement textes_consentement_figes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER textes_consentement_figes BEFORE UPDATE ON public.textes_consentement FOR EACH ROW EXECUTE FUNCTION public.figer_le_texte_publie();


--
-- Name: acces_exceptionnels acces_exceptionnels_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acces_exceptionnels
    ADD CONSTRAINT acces_exceptionnels_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: acces_exceptionnels acces_exceptionnels_ouvert_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acces_exceptionnels
    ADD CONSTRAINT acces_exceptionnels_ouvert_par_fkey FOREIGN KEY (ouvert_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: acces_pieces acces_pieces_acces_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acces_pieces
    ADD CONSTRAINT acces_pieces_acces_id_fkey FOREIGN KEY (acces_id) REFERENCES public.acces_exceptionnels(id) ON DELETE CASCADE;


--
-- Name: acces_pieces acces_pieces_depose_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acces_pieces
    ADD CONSTRAINT acces_pieces_depose_par_fkey FOREIGN KEY (depose_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: acces_pieces acces_pieces_ecartee_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acces_pieces
    ADD CONSTRAINT acces_pieces_ecartee_par_fkey FOREIGN KEY (ecartee_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: acces_pieces acces_pieces_emane_de_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acces_pieces
    ADD CONSTRAINT acces_pieces_emane_de_fkey FOREIGN KEY (emane_de) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: adaptations adaptations_support_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adaptations
    ADD CONSTRAINT adaptations_support_id_fkey FOREIGN KEY (support_id) REFERENCES public.supports(id) ON DELETE CASCADE;


--
-- Name: adaptations adaptations_valide_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.adaptations
    ADD CONSTRAINT adaptations_valide_par_fkey FOREIGN KEY (valide_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: alertes_actions alertes_actions_alerte_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertes_actions
    ADD CONSTRAINT alertes_actions_alerte_id_fkey FOREIGN KEY (alerte_id) REFERENCES public.alertes_difficulte(id) ON DELETE CASCADE;


--
-- Name: alertes_actions alertes_actions_auteur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertes_actions
    ADD CONSTRAINT alertes_actions_auteur_id_fkey FOREIGN KEY (auteur_id) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: alertes_difficulte alertes_difficulte_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertes_difficulte
    ADD CONSTRAINT alertes_difficulte_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: alertes_difficulte alertes_difficulte_objectif_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertes_difficulte
    ADD CONSTRAINT alertes_difficulte_objectif_id_fkey FOREIGN KEY (objectif_id) REFERENCES public.objectifs(id) ON DELETE CASCADE;


--
-- Name: alertes_difficulte alertes_difficulte_repere_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertes_difficulte
    ADD CONSTRAINT alertes_difficulte_repere_id_fkey FOREIGN KEY (repere_id) REFERENCES public.reperes_competences(id) ON DELETE CASCADE;


--
-- Name: alertes_difficulte alertes_difficulte_traitee_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alertes_difficulte
    ADD CONSTRAINT alertes_difficulte_traitee_par_fkey FOREIGN KEY (traitee_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: amorces_ecriture amorces_ecriture_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.amorces_ecriture
    ADD CONSTRAINT amorces_ecriture_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: annees_enfant annees_enfant_annee_precedente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annees_enfant
    ADD CONSTRAINT annees_enfant_annee_precedente_id_fkey FOREIGN KEY (annee_precedente_id) REFERENCES public.annees_enfant(id) ON DELETE SET NULL;


--
-- Name: annees_enfant annees_enfant_bilan_anterieur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annees_enfant
    ADD CONSTRAINT annees_enfant_bilan_anterieur_id_fkey FOREIGN KEY (bilan_anterieur_id) REFERENCES public.bilans_trimestriels(id) ON DELETE SET NULL;


--
-- Name: annees_enfant annees_enfant_bilan_positionnement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annees_enfant
    ADD CONSTRAINT annees_enfant_bilan_positionnement_id_fkey FOREIGN KEY (bilan_positionnement_id) REFERENCES public.bilans_positionnement(id) ON DELETE SET NULL;


--
-- Name: annees_enfant annees_enfant_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.annees_enfant
    ADD CONSTRAINT annees_enfant_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: appareils appareils_profil_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.appareils
    ADD CONSTRAINT appareils_profil_id_fkey FOREIGN KEY (profil_id) REFERENCES public.profils(id) ON DELETE CASCADE;


--
-- Name: avis_ia avis_ia_adaptation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.avis_ia
    ADD CONSTRAINT avis_ia_adaptation_id_fkey FOREIGN KEY (adaptation_id) REFERENCES public.adaptations(id) ON DELETE CASCADE;


--
-- Name: avis_ia avis_ia_auteur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.avis_ia
    ADD CONSTRAINT avis_ia_auteur_id_fkey FOREIGN KEY (auteur_id) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: avis_ia avis_ia_mission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.avis_ia
    ADD CONSTRAINT avis_ia_mission_id_fkey FOREIGN KEY (mission_id) REFERENCES public.missions(id) ON DELETE CASCADE;


--
-- Name: badges_obtenus badges_obtenus_annee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges_obtenus
    ADD CONSTRAINT badges_obtenus_annee_id_fkey FOREIGN KEY (annee_id) REFERENCES public.annees_enfant(id) ON DELETE SET NULL;


--
-- Name: badges_obtenus badges_obtenus_attribue_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges_obtenus
    ADD CONSTRAINT badges_obtenus_attribue_par_fkey FOREIGN KEY (attribue_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: badges_obtenus badges_obtenus_domaine_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges_obtenus
    ADD CONSTRAINT badges_obtenus_domaine_code_fkey FOREIGN KEY (domaine_code) REFERENCES public.domaines_transversaux(code) ON DELETE RESTRICT;


--
-- Name: badges_obtenus badges_obtenus_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges_obtenus
    ADD CONSTRAINT badges_obtenus_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: badges_obtenus badges_obtenus_matiere_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.badges_obtenus
    ADD CONSTRAINT badges_obtenus_matiere_code_fkey FOREIGN KEY (matiere_code) REFERENCES public.matieres(code) ON DELETE RESTRICT;


--
-- Name: bilan_maitrises bilan_maitrises_bilan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_maitrises
    ADD CONSTRAINT bilan_maitrises_bilan_id_fkey FOREIGN KEY (bilan_id) REFERENCES public.bilans_positionnement(id) ON DELETE CASCADE;


--
-- Name: bilan_maitrises bilan_maitrises_repere_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_maitrises
    ADD CONSTRAINT bilan_maitrises_repere_id_fkey FOREIGN KEY (repere_id) REFERENCES public.reperes_competences(id) ON DELETE RESTRICT;


--
-- Name: bilan_niveaux_matiere bilan_niveaux_matiere_bilan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_niveaux_matiere
    ADD CONSTRAINT bilan_niveaux_matiere_bilan_id_fkey FOREIGN KEY (bilan_id) REFERENCES public.bilans_positionnement(id) ON DELETE CASCADE;


--
-- Name: bilan_niveaux_matiere bilan_niveaux_matiere_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_niveaux_matiere
    ADD CONSTRAINT bilan_niveaux_matiere_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: bilan_niveaux_matiere bilan_niveaux_matiere_matiere_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_niveaux_matiere
    ADD CONSTRAINT bilan_niveaux_matiere_matiere_code_fkey FOREIGN KEY (matiere_code) REFERENCES public.matieres(code) ON DELETE RESTRICT;


--
-- Name: bilan_niveaux_matiere bilan_niveaux_matiere_valide_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_niveaux_matiere
    ADD CONSTRAINT bilan_niveaux_matiere_valide_par_fkey FOREIGN KEY (valide_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: bilan_questions bilan_questions_bilan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_questions
    ADD CONSTRAINT bilan_questions_bilan_id_fkey FOREIGN KEY (bilan_id) REFERENCES public.bilans_positionnement(id) ON DELETE CASCADE;


--
-- Name: bilan_questions bilan_questions_repere_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_questions
    ADD CONSTRAINT bilan_questions_repere_id_fkey FOREIGN KEY (repere_id) REFERENCES public.reperes_competences(id) ON DELETE RESTRICT;


--
-- Name: bilan_reponses bilan_reponses_corrigee_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_reponses
    ADD CONSTRAINT bilan_reponses_corrigee_par_fkey FOREIGN KEY (corrigee_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: bilan_reponses bilan_reponses_question_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilan_reponses
    ADD CONSTRAINT bilan_reponses_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.bilan_questions(id) ON DELETE CASCADE;


--
-- Name: bilans_positionnement bilans_positionnement_cree_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilans_positionnement
    ADD CONSTRAINT bilans_positionnement_cree_par_fkey FOREIGN KEY (cree_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: bilans_positionnement bilans_positionnement_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilans_positionnement
    ADD CONSTRAINT bilans_positionnement_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: bilans_positionnement bilans_positionnement_valide_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilans_positionnement
    ADD CONSTRAINT bilans_positionnement_valide_par_fkey FOREIGN KEY (valide_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: bilans_trimestriels bilans_trimestriels_annee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilans_trimestriels
    ADD CONSTRAINT bilans_trimestriels_annee_id_fkey FOREIGN KEY (annee_id) REFERENCES public.annees_enfant(id) ON DELETE SET NULL;


--
-- Name: bilans_trimestriels bilans_trimestriels_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilans_trimestriels
    ADD CONSTRAINT bilans_trimestriels_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: bilans_trimestriels_matieres bilans_trimestriels_matieres_bilan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilans_trimestriels_matieres
    ADD CONSTRAINT bilans_trimestriels_matieres_bilan_id_fkey FOREIGN KEY (bilan_id) REFERENCES public.bilans_trimestriels(id) ON DELETE CASCADE;


--
-- Name: bilans_trimestriels_matieres bilans_trimestriels_matieres_matiere_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilans_trimestriels_matieres
    ADD CONSTRAINT bilans_trimestriels_matieres_matiere_code_fkey FOREIGN KEY (matiere_code) REFERENCES public.matieres(code) ON DELETE RESTRICT;


--
-- Name: bilans_trimestriels bilans_trimestriels_valide_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bilans_trimestriels
    ADD CONSTRAINT bilans_trimestriels_valide_par_fkey FOREIGN KEY (valide_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: centres_interet centres_interet_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.centres_interet
    ADD CONSTRAINT centres_interet_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: consentements consentements_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consentements
    ADD CONSTRAINT consentements_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: consentements consentements_profil_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consentements
    ADD CONSTRAINT consentements_profil_id_fkey FOREIGN KEY (profil_id) REFERENCES public.profils(id) ON DELETE CASCADE;


--
-- Name: consentements consentements_texte_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consentements
    ADD CONSTRAINT consentements_texte_id_fkey FOREIGN KEY (texte_id) REFERENCES public.textes_consentement(id) ON DELETE RESTRICT;


--
-- Name: corrections corrections_corrigee_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.corrections
    ADD CONSTRAINT corrections_corrigee_par_fkey FOREIGN KEY (corrigee_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: corrections corrections_tentative_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.corrections
    ADD CONSTRAINT corrections_tentative_id_fkey FOREIGN KEY (tentative_id) REFERENCES public.tentatives(id) ON DELETE CASCADE;


--
-- Name: demandes_habilitation demandes_habilitation_profil_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demandes_habilitation
    ADD CONSTRAINT demandes_habilitation_profil_id_fkey FOREIGN KEY (profil_id) REFERENCES public.profils(id) ON DELETE CASCADE;


--
-- Name: demandes_habilitation demandes_habilitation_traitee_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demandes_habilitation
    ADD CONSTRAINT demandes_habilitation_traitee_par_fkey FOREIGN KEY (traitee_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: demandes_suppression demandes_suppression_demandee_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demandes_suppression
    ADD CONSTRAINT demandes_suppression_demandee_par_fkey FOREIGN KEY (demandee_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: demandes_suppression demandes_suppression_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demandes_suppression
    ADD CONSTRAINT demandes_suppression_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE SET NULL;


--
-- Name: demandes_suppression demandes_suppression_masquee_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.demandes_suppression
    ADD CONSTRAINT demandes_suppression_masquee_par_fkey FOREIGN KEY (masquee_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: documents_diagnostic documents_diagnostic_depose_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents_diagnostic
    ADD CONSTRAINT documents_diagnostic_depose_par_fkey FOREIGN KEY (depose_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: documents_diagnostic documents_diagnostic_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents_diagnostic
    ADD CONSTRAINT documents_diagnostic_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: documents_diagnostic documents_diagnostic_validee_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents_diagnostic
    ADD CONSTRAINT documents_diagnostic_validee_par_fkey FOREIGN KEY (validee_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: domaines_evaluation domaines_evaluation_matiere_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domaines_evaluation
    ADD CONSTRAINT domaines_evaluation_matiere_code_fkey FOREIGN KEY (matiere_code) REFERENCES public.matieres(code) ON DELETE RESTRICT;


--
-- Name: domaines_evaluation domaines_evaluation_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domaines_evaluation
    ADD CONSTRAINT domaines_evaluation_version_id_fkey FOREIGN KEY (version_id) REFERENCES public.versions_programme(id) ON DELETE RESTRICT;


--
-- Name: enfants enfants_archive_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enfants
    ADD CONSTRAINT enfants_archive_par_fkey FOREIGN KEY (archive_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: enfants enfants_compte_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enfants
    ADD CONSTRAINT enfants_compte_id_fkey FOREIGN KEY (compte_id) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: enfants enfants_cree_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enfants
    ADD CONSTRAINT enfants_cree_par_fkey FOREIGN KEY (cree_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: enfants_sante enfants_sante_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enfants_sante
    ADD CONSTRAINT enfants_sante_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: envois envois_destinataire_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envois
    ADD CONSTRAINT envois_destinataire_id_fkey FOREIGN KEY (destinataire_id) REFERENCES public.profils(id) ON DELETE CASCADE;


--
-- Name: envois envois_notification_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.envois
    ADD CONSTRAINT envois_notification_id_fkey FOREIGN KEY (notification_id) REFERENCES public.notifications(id) ON DELETE SET NULL;


--
-- Name: exercices exercices_mission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exercices
    ADD CONSTRAINT exercices_mission_id_fkey FOREIGN KEY (mission_id) REFERENCES public.missions(id) ON DELETE CASCADE;


--
-- Name: exercices exercices_modele_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.exercices
    ADD CONSTRAINT exercices_modele_id_fkey FOREIGN KEY (modele_id) REFERENCES public.modeles_exercice(id) ON DELETE SET NULL;


--
-- Name: fils fils_cree_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fils
    ADD CONSTRAINT fils_cree_par_fkey FOREIGN KEY (cree_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: fils fils_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fils
    ADD CONSTRAINT fils_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: fils_participants fils_participants_ajoute_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fils_participants
    ADD CONSTRAINT fils_participants_ajoute_par_fkey FOREIGN KEY (ajoute_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: fils_participants fils_participants_fil_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fils_participants
    ADD CONSTRAINT fils_participants_fil_id_fkey FOREIGN KEY (fil_id) REFERENCES public.fils(id) ON DELETE CASCADE;


--
-- Name: fils_participants fils_participants_profil_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fils_participants
    ADD CONSTRAINT fils_participants_profil_id_fkey FOREIGN KEY (profil_id) REFERENCES public.profils(id) ON DELETE CASCADE;


--
-- Name: generations_bilan generations_bilan_bilan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generations_bilan
    ADD CONSTRAINT generations_bilan_bilan_id_fkey FOREIGN KEY (bilan_id) REFERENCES public.bilans_positionnement(id) ON DELETE SET NULL;


--
-- Name: generations_bilan generations_bilan_demande_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generations_bilan
    ADD CONSTRAINT generations_bilan_demande_par_fkey FOREIGN KEY (demande_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: generations_bilan generations_bilan_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generations_bilan
    ADD CONSTRAINT generations_bilan_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: habilitation_pieces habilitation_pieces_demande_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.habilitation_pieces
    ADD CONSTRAINT habilitation_pieces_demande_id_fkey FOREIGN KEY (demande_id) REFERENCES public.demandes_habilitation(id) ON DELETE CASCADE;


--
-- Name: intervenants_enfant intervenants_enfant_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervenants_enfant
    ADD CONSTRAINT intervenants_enfant_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: intervenants_enfant intervenants_enfant_invite_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervenants_enfant
    ADD CONSTRAINT intervenants_enfant_invite_par_fkey FOREIGN KEY (invite_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: intervenants_enfant intervenants_enfant_profil_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervenants_enfant
    ADD CONSTRAINT intervenants_enfant_profil_id_fkey FOREIGN KEY (profil_id) REFERENCES public.profils(id) ON DELETE CASCADE;


--
-- Name: intervenants_enfant intervenants_enfant_succede_a_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervenants_enfant
    ADD CONSTRAINT intervenants_enfant_succede_a_fkey FOREIGN KEY (succede_a) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: intervenants_matieres intervenants_matieres_intervenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervenants_matieres
    ADD CONSTRAINT intervenants_matieres_intervenant_id_fkey FOREIGN KEY (intervenant_id) REFERENCES public.intervenants_enfant(id) ON DELETE CASCADE;


--
-- Name: intervenants_matieres intervenants_matieres_matiere_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.intervenants_matieres
    ADD CONSTRAINT intervenants_matieres_matiere_code_fkey FOREIGN KEY (matiere_code) REFERENCES public.matieres(code) ON DELETE RESTRICT;


--
-- Name: invitations invitations_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: invitations invitations_invite_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_invite_par_fkey FOREIGN KEY (invite_par) REFERENCES public.profils(id) ON DELETE CASCADE;


--
-- Name: invitations invitations_matiere_connue; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invitations
    ADD CONSTRAINT invitations_matiere_connue FOREIGN KEY (matiere_code) REFERENCES public.matieres(code) ON DELETE RESTRICT;


--
-- Name: items_evaluation_nationale items_evaluation_nationale_domaine_evaluation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items_evaluation_nationale
    ADD CONSTRAINT items_evaluation_nationale_domaine_evaluation_id_fkey FOREIGN KEY (domaine_evaluation_id) REFERENCES public.domaines_evaluation(id) ON DELETE RESTRICT;


--
-- Name: items_evaluation_nationale items_evaluation_nationale_repere_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items_evaluation_nationale
    ADD CONSTRAINT items_evaluation_nationale_repere_id_fkey FOREIGN KEY (repere_id) REFERENCES public.reperes_competences(id) ON DELETE SET NULL;


--
-- Name: items_evaluation_nationale items_evaluation_nationale_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items_evaluation_nationale
    ADD CONSTRAINT items_evaluation_nationale_version_id_fkey FOREIGN KEY (version_id) REFERENCES public.versions_programme(id) ON DELETE RESTRICT;


--
-- Name: journal_acces journal_acces_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_acces
    ADD CONSTRAINT journal_acces_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: journal_acces journal_acces_profil_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_acces
    ADD CONSTRAINT journal_acces_profil_id_fkey FOREIGN KEY (profil_id) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: journal_entrees journal_entrees_auteur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_entrees
    ADD CONSTRAINT journal_entrees_auteur_id_fkey FOREIGN KEY (auteur_id) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: journal_entrees journal_entrees_journee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_entrees
    ADD CONSTRAINT journal_entrees_journee_id_fkey FOREIGN KEY (journee_id) REFERENCES public.journees(id) ON DELETE CASCADE;


--
-- Name: journal_entrees journal_entrees_objectif_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_entrees
    ADD CONSTRAINT journal_entrees_objectif_id_fkey FOREIGN KEY (objectif_id) REFERENCES public.objectifs(id) ON DELETE SET NULL;


--
-- Name: journal_entrees journal_entrees_support_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_entrees
    ADD CONSTRAINT journal_entrees_support_id_fkey FOREIGN KEY (support_id) REFERENCES public.supports(id) ON DELETE SET NULL;


--
-- Name: journal_ia journal_ia_declenche_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_ia
    ADD CONSTRAINT journal_ia_declenche_par_fkey FOREIGN KEY (declenche_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: journal_ia journal_ia_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_ia
    ADD CONSTRAINT journal_ia_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: journal_medias journal_medias_depose_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_medias
    ADD CONSTRAINT journal_medias_depose_par_fkey FOREIGN KEY (depose_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: journal_medias journal_medias_entree_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_medias
    ADD CONSTRAINT journal_medias_entree_id_fkey FOREIGN KEY (entree_id) REFERENCES public.journal_entrees(id) ON DELETE CASCADE;


--
-- Name: journal_medias journal_medias_journee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journal_medias
    ADD CONSTRAINT journal_medias_journee_id_fkey FOREIGN KEY (journee_id) REFERENCES public.journees(id) ON DELETE CASCADE;


--
-- Name: journee_etapes journee_etapes_journee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journee_etapes
    ADD CONSTRAINT journee_etapes_journee_id_fkey FOREIGN KEY (journee_id) REFERENCES public.journees(id) ON DELETE CASCADE;


--
-- Name: journee_preparatifs journee_preparatifs_coche_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journee_preparatifs
    ADD CONSTRAINT journee_preparatifs_coche_par_fkey FOREIGN KEY (coche_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: journee_preparatifs journee_preparatifs_journee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journee_preparatifs
    ADD CONSTRAINT journee_preparatifs_journee_id_fkey FOREIGN KEY (journee_id) REFERENCES public.journees(id) ON DELETE CASCADE;


--
-- Name: journee_reperes journee_reperes_cree_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journee_reperes
    ADD CONSTRAINT journee_reperes_cree_par_fkey FOREIGN KEY (cree_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: journee_reperes journee_reperes_etape_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journee_reperes
    ADD CONSTRAINT journee_reperes_etape_id_fkey FOREIGN KEY (etape_id) REFERENCES public.journee_etapes(id) ON DELETE CASCADE;


--
-- Name: journee_reperes journee_reperes_journee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journee_reperes
    ADD CONSTRAINT journee_reperes_journee_id_fkey FOREIGN KEY (journee_id) REFERENCES public.journees(id) ON DELETE CASCADE;


--
-- Name: journees journees_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journees
    ADD CONSTRAINT journees_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: journees journees_periode_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.journees
    ADD CONSTRAINT journees_periode_id_fkey FOREIGN KEY (periode_id) REFERENCES public.periodes(id) ON DELETE SET NULL;


--
-- Name: messages messages_auteur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_auteur_id_fkey FOREIGN KEY (auteur_id) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: messages messages_fil_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_fil_id_fkey FOREIGN KEY (fil_id) REFERENCES public.fils(id) ON DELETE CASCADE;


--
-- Name: missions missions_adaptation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missions
    ADD CONSTRAINT missions_adaptation_id_fkey FOREIGN KEY (adaptation_id) REFERENCES public.adaptations(id) ON DELETE SET NULL;


--
-- Name: missions missions_auteur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missions
    ADD CONSTRAINT missions_auteur_id_fkey FOREIGN KEY (auteur_id) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: missions missions_domaine_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missions
    ADD CONSTRAINT missions_domaine_code_fkey FOREIGN KEY (domaine_code) REFERENCES public.domaines_transversaux(code) ON DELETE RESTRICT;


--
-- Name: missions missions_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missions
    ADD CONSTRAINT missions_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: missions missions_fourni_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missions
    ADD CONSTRAINT missions_fourni_par_fkey FOREIGN KEY (fourni_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: missions missions_matiere_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missions
    ADD CONSTRAINT missions_matiere_code_fkey FOREIGN KEY (matiere_code) REFERENCES public.matieres(code) ON DELETE RESTRICT;


--
-- Name: missions missions_objectif_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missions
    ADD CONSTRAINT missions_objectif_id_fkey FOREIGN KEY (objectif_id) REFERENCES public.objectifs(id) ON DELETE SET NULL;


--
-- Name: missions missions_projet_moteur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missions
    ADD CONSTRAINT missions_projet_moteur_id_fkey FOREIGN KEY (projet_moteur_id) REFERENCES public.projets_moteurs(id) ON DELETE RESTRICT;


--
-- Name: missions missions_quete_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missions
    ADD CONSTRAINT missions_quete_id_fkey FOREIGN KEY (quete_id) REFERENCES public.quetes(id) ON DELETE SET NULL;


--
-- Name: missions missions_remplacee_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missions
    ADD CONSTRAINT missions_remplacee_par_fkey FOREIGN KEY (remplacee_par) REFERENCES public.missions(id) ON DELETE SET NULL;


--
-- Name: missions missions_valide_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.missions
    ADD CONSTRAINT missions_valide_par_fkey FOREIGN KEY (valide_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: modeles_exercice modeles_exercice_cree_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modeles_exercice
    ADD CONSTRAINT modeles_exercice_cree_par_fkey FOREIGN KEY (cree_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: modeles_exercice modeles_exercice_matiere_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modeles_exercice
    ADD CONSTRAINT modeles_exercice_matiere_code_fkey FOREIGN KEY (matiere_code) REFERENCES public.matieres(code) ON DELETE RESTRICT;


--
-- Name: modeles_exercice modeles_exercice_origine_exercice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modeles_exercice
    ADD CONSTRAINT modeles_exercice_origine_exercice_id_fkey FOREIGN KEY (origine_exercice_id) REFERENCES public.exercices(id) ON DELETE SET NULL;


--
-- Name: modeles_exercice modeles_exercice_repere_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modeles_exercice
    ADD CONSTRAINT modeles_exercice_repere_id_fkey FOREIGN KEY (repere_id) REFERENCES public.reperes_competences(id) ON DELETE SET NULL;


--
-- Name: modeles_exercice modeles_exercice_valide_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.modeles_exercice
    ADD CONSTRAINT modeles_exercice_valide_par_fkey FOREIGN KEY (valide_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: notations notations_mission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notations
    ADD CONSTRAINT notations_mission_id_fkey FOREIGN KEY (mission_id) REFERENCES public.missions(id) ON DELETE CASCADE;


--
-- Name: notations notations_note_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notations
    ADD CONSTRAINT notations_note_par_fkey FOREIGN KEY (note_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: notifications notifications_destinataire_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_destinataire_id_fkey FOREIGN KEY (destinataire_id) REFERENCES public.profils(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id) ON DELETE CASCADE;


--
-- Name: objectifs objectifs_annee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs
    ADD CONSTRAINT objectifs_annee_id_fkey FOREIGN KEY (annee_id) REFERENCES public.annees_enfant(id) ON DELETE SET NULL;


--
-- Name: objectifs_demandes objectifs_demandes_demande_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs_demandes
    ADD CONSTRAINT objectifs_demandes_demande_par_fkey FOREIGN KEY (demande_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: objectifs_demandes objectifs_demandes_objectif_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs_demandes
    ADD CONSTRAINT objectifs_demandes_objectif_id_fkey FOREIGN KEY (objectif_id) REFERENCES public.objectifs(id) ON DELETE CASCADE;


--
-- Name: objectifs_demandes objectifs_demandes_traite_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs_demandes
    ADD CONSTRAINT objectifs_demandes_traite_par_fkey FOREIGN KEY (traite_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: objectifs objectifs_domaine_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs
    ADD CONSTRAINT objectifs_domaine_code_fkey FOREIGN KEY (domaine_code) REFERENCES public.domaines_transversaux(code) ON DELETE RESTRICT;


--
-- Name: objectifs objectifs_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs
    ADD CONSTRAINT objectifs_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: objectifs objectifs_matiere_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs
    ADD CONSTRAINT objectifs_matiere_code_fkey FOREIGN KEY (matiere_code) REFERENCES public.matieres(code) ON DELETE RESTRICT;


--
-- Name: objectifs objectifs_objectif_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs
    ADD CONSTRAINT objectifs_objectif_parent_id_fkey FOREIGN KEY (objectif_parent_id) REFERENCES public.objectifs(id) ON DELETE CASCADE;


--
-- Name: objectifs objectifs_propose_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs
    ADD CONSTRAINT objectifs_propose_par_fkey FOREIGN KEY (propose_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: objectifs objectifs_repere_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs
    ADD CONSTRAINT objectifs_repere_id_fkey FOREIGN KEY (repere_id) REFERENCES public.reperes_competences(id) ON DELETE SET NULL;


--
-- Name: objectifs_validations objectifs_validations_objectif_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs_validations
    ADD CONSTRAINT objectifs_validations_objectif_id_fkey FOREIGN KEY (objectif_id) REFERENCES public.objectifs(id) ON DELETE CASCADE;


--
-- Name: objectifs_validations objectifs_validations_profil_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs_validations
    ADD CONSTRAINT objectifs_validations_profil_id_fkey FOREIGN KEY (profil_id) REFERENCES public.profils(id) ON DELETE CASCADE;


--
-- Name: objectifs objectifs_valide_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.objectifs
    ADD CONSTRAINT objectifs_valide_par_fkey FOREIGN KEY (valide_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: observations_capacites observations_capacites_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observations_capacites
    ADD CONSTRAINT observations_capacites_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: observations_capacites observations_capacites_questionnaire_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observations_capacites
    ADD CONSTRAINT observations_capacites_questionnaire_id_fkey FOREIGN KEY (questionnaire_id) REFERENCES public.questionnaires_capacites(id) ON DELETE RESTRICT;


--
-- Name: observations_capacites observations_capacites_rempli_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observations_capacites
    ADD CONSTRAINT observations_capacites_rempli_par_fkey FOREIGN KEY (rempli_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: observations_reponses observations_reponses_observation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.observations_reponses
    ADD CONSTRAINT observations_reponses_observation_id_fkey FOREIGN KEY (observation_id) REFERENCES public.observations_capacites(id) ON DELETE CASCADE;


--
-- Name: periodes periodes_cree_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodes
    ADD CONSTRAINT periodes_cree_par_fkey FOREIGN KEY (cree_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: periodes periodes_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodes
    ADD CONSTRAINT periodes_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: pieces_gagnees pieces_gagnees_attribue_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pieces_gagnees
    ADD CONSTRAINT pieces_gagnees_attribue_par_fkey FOREIGN KEY (attribue_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: pieces_gagnees pieces_gagnees_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pieces_gagnees
    ADD CONSTRAINT pieces_gagnees_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: pieces_gagnees pieces_gagnees_exercice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pieces_gagnees
    ADD CONSTRAINT pieces_gagnees_exercice_id_fkey FOREIGN KEY (exercice_id) REFERENCES public.exercices(id) ON DELETE SET NULL;


--
-- Name: pieces_gagnees pieces_gagnees_mission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pieces_gagnees
    ADD CONSTRAINT pieces_gagnees_mission_id_fkey FOREIGN KEY (mission_id) REFERENCES public.missions(id) ON DELETE SET NULL;


--
-- Name: pieces_gagnees pieces_gagnees_notation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pieces_gagnees
    ADD CONSTRAINT pieces_gagnees_notation_id_fkey FOREIGN KEY (notation_id) REFERENCES public.notations(id) ON DELETE SET NULL;


--
-- Name: pieces_jointes pieces_jointes_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pieces_jointes
    ADD CONSTRAINT pieces_jointes_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id) ON DELETE CASCADE;


--
-- Name: preferences_notification preferences_notification_profil_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preferences_notification
    ADD CONSTRAINT preferences_notification_profil_id_fkey FOREIGN KEY (profil_id) REFERENCES public.profils(id) ON DELETE CASCADE;


--
-- Name: preparatifs_recurrents preparatifs_recurrents_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preparatifs_recurrents
    ADD CONSTRAINT preparatifs_recurrents_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: profils profils_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profils
    ADD CONSTRAINT profils_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: programme_applicable programme_applicable_version_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.programme_applicable
    ADD CONSTRAINT programme_applicable_version_id_fkey FOREIGN KEY (version_id) REFERENCES public.versions_programme(id) ON DELETE CASCADE;


--
-- Name: projets_moteurs projets_moteurs_cree_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projets_moteurs
    ADD CONSTRAINT projets_moteurs_cree_par_fkey FOREIGN KEY (cree_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: projets_moteurs projets_moteurs_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projets_moteurs
    ADD CONSTRAINT projets_moteurs_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: questionnaires_capacites questionnaires_capacites_cree_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.questionnaires_capacites
    ADD CONSTRAINT questionnaires_capacites_cree_par_fkey FOREIGN KEY (cree_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: quetes quetes_annee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quetes
    ADD CONSTRAINT quetes_annee_id_fkey FOREIGN KEY (annee_id) REFERENCES public.annees_enfant(id) ON DELETE SET NULL;


--
-- Name: quetes_badges_vises quetes_badges_vises_domaine_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quetes_badges_vises
    ADD CONSTRAINT quetes_badges_vises_domaine_code_fkey FOREIGN KEY (domaine_code) REFERENCES public.domaines_transversaux(code) ON DELETE RESTRICT;


--
-- Name: quetes_badges_vises quetes_badges_vises_matiere_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quetes_badges_vises
    ADD CONSTRAINT quetes_badges_vises_matiere_code_fkey FOREIGN KEY (matiere_code) REFERENCES public.matieres(code) ON DELETE RESTRICT;


--
-- Name: quetes_badges_vises quetes_badges_vises_quete_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quetes_badges_vises
    ADD CONSTRAINT quetes_badges_vises_quete_id_fkey FOREIGN KEY (quete_id) REFERENCES public.quetes(id) ON DELETE CASCADE;


--
-- Name: quetes quetes_cree_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quetes
    ADD CONSTRAINT quetes_cree_par_fkey FOREIGN KEY (cree_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: quetes quetes_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quetes
    ADD CONSTRAINT quetes_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: quetes quetes_projet_moteur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quetes
    ADD CONSTRAINT quetes_projet_moteur_id_fkey FOREIGN KEY (projet_moteur_id) REFERENCES public.projets_moteurs(id) ON DELETE SET NULL;


--
-- Name: quetes quetes_recompense_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quetes
    ADD CONSTRAINT quetes_recompense_id_fkey FOREIGN KEY (recompense_id) REFERENCES public.recompenses_familiales(id) ON DELETE SET NULL;


--
-- Name: quetes quetes_reussie_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quetes
    ADD CONSTRAINT quetes_reussie_par_fkey FOREIGN KEY (reussie_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: recompenses_familiales recompenses_familiales_devoilee_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses_familiales
    ADD CONSTRAINT recompenses_familiales_devoilee_par_fkey FOREIGN KEY (devoilee_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: recompenses_familiales recompenses_familiales_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses_familiales
    ADD CONSTRAINT recompenses_familiales_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: recompenses_familiales recompenses_familiales_objectif_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses_familiales
    ADD CONSTRAINT recompenses_familiales_objectif_id_fkey FOREIGN KEY (objectif_id) REFERENCES public.objectifs(id) ON DELETE SET NULL;


--
-- Name: recompenses_familiales recompenses_familiales_proposee_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses_familiales
    ADD CONSTRAINT recompenses_familiales_proposee_par_fkey FOREIGN KEY (proposee_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: recompenses_obtenues recompenses_obtenues_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses_obtenues
    ADD CONSTRAINT recompenses_obtenues_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: recompenses_obtenues recompenses_obtenues_mission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses_obtenues
    ADD CONSTRAINT recompenses_obtenues_mission_id_fkey FOREIGN KEY (mission_id) REFERENCES public.missions(id) ON DELETE SET NULL;


--
-- Name: recompenses_obtenues recompenses_obtenues_offerte_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses_obtenues
    ADD CONSTRAINT recompenses_obtenues_offerte_par_fkey FOREIGN KEY (offerte_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: recompenses_obtenues recompenses_obtenues_recompense_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses_obtenues
    ADD CONSTRAINT recompenses_obtenues_recompense_id_fkey FOREIGN KEY (recompense_id) REFERENCES public.recompenses(id) ON DELETE CASCADE;


--
-- Name: recompenses recompenses_projet_moteur_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses
    ADD CONSTRAINT recompenses_projet_moteur_id_fkey FOREIGN KEY (projet_moteur_id) REFERENCES public.projets_moteurs(id) ON DELETE CASCADE;


--
-- Name: recompenses_reports recompenses_reports_recompense_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses_reports
    ADD CONSTRAINT recompenses_reports_recompense_id_fkey FOREIGN KEY (recompense_id) REFERENCES public.recompenses_familiales(id) ON DELETE CASCADE;


--
-- Name: recompenses_reports recompenses_reports_reporte_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses_reports
    ADD CONSTRAINT recompenses_reports_reporte_par_fkey FOREIGN KEY (reporte_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: recompenses recompenses_requiert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recompenses
    ADD CONSTRAINT recompenses_requiert_id_fkey FOREIGN KEY (requiert_id) REFERENCES public.recompenses(id) ON DELETE SET NULL;


--
-- Name: reperes_competences reperes_competences_domaine_evaluation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reperes_competences
    ADD CONSTRAINT reperes_competences_domaine_evaluation_id_fkey FOREIGN KEY (domaine_evaluation_id) REFERENCES public.domaines_evaluation(id) ON DELETE SET NULL;


--
-- Name: reperes_competences reperes_competences_matiere_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reperes_competences
    ADD CONSTRAINT reperes_competences_matiere_code_fkey FOREIGN KEY (matiere_code) REFERENCES public.matieres(code) ON DELETE CASCADE;


--
-- Name: reperes_competences reperes_competences_version_programme_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reperes_competences
    ADD CONSTRAINT reperes_competences_version_programme_id_fkey FOREIGN KEY (version_programme_id) REFERENCES public.versions_programme(id) ON DELETE RESTRICT;


--
-- Name: supports supports_depose_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supports
    ADD CONSTRAINT supports_depose_par_fkey FOREIGN KEY (depose_par) REFERENCES public.profils(id) ON DELETE RESTRICT;


--
-- Name: supports supports_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supports
    ADD CONSTRAINT supports_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: supports supports_fourni_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supports
    ADD CONSTRAINT supports_fourni_par_fkey FOREIGN KEY (fourni_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: supports supports_matiere_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.supports
    ADD CONSTRAINT supports_matiere_code_fkey FOREIGN KEY (matiere_code) REFERENCES public.matieres(code) ON DELETE RESTRICT;


--
-- Name: suppressions_accords suppressions_accords_demande_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppressions_accords
    ADD CONSTRAINT suppressions_accords_demande_id_fkey FOREIGN KEY (demande_id) REFERENCES public.demandes_suppression(id) ON DELETE CASCADE;


--
-- Name: suppressions_accords suppressions_accords_profil_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppressions_accords
    ADD CONSTRAINT suppressions_accords_profil_id_fkey FOREIGN KEY (profil_id) REFERENCES public.profils(id) ON DELETE CASCADE;


--
-- Name: suppressions_effectuees suppressions_effectuees_demandee_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppressions_effectuees
    ADD CONSTRAINT suppressions_effectuees_demandee_par_fkey FOREIGN KEY (demandee_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: suppressions_effectuees suppressions_effectuees_masquee_par_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.suppressions_effectuees
    ADD CONSTRAINT suppressions_effectuees_masquee_par_fkey FOREIGN KEY (masquee_par) REFERENCES public.profils(id) ON DELETE SET NULL;


--
-- Name: tentatives tentatives_enfant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tentatives
    ADD CONSTRAINT tentatives_enfant_id_fkey FOREIGN KEY (enfant_id) REFERENCES public.enfants(id) ON DELETE CASCADE;


--
-- Name: tentatives tentatives_exercice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tentatives
    ADD CONSTRAINT tentatives_exercice_id_fkey FOREIGN KEY (exercice_id) REFERENCES public.exercices(id) ON DELETE CASCADE;


--
-- Name: acces_exceptionnels; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.acces_exceptionnels ENABLE ROW LEVEL SECURITY;

--
-- Name: acces_exceptionnels acces_exceptionnels_cloture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY acces_exceptionnels_cloture ON public.acces_exceptionnels FOR UPDATE TO authenticated USING ((public.est_admin() AND (ouvert_par = auth.uid())));


--
-- Name: acces_exceptionnels acces_exceptionnels_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY acces_exceptionnels_lecture ON public.acces_exceptionnels FOR SELECT TO authenticated USING (((public.peut_valider(enfant_id) AND (information_faite_le IS NOT NULL)) OR (public.est_admin() AND (ouvert_par = auth.uid()))));


--
-- Name: acces_exceptionnels acces_exceptionnels_ouverture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY acces_exceptionnels_ouverture ON public.acces_exceptionnels FOR INSERT TO authenticated WITH CHECK ((public.est_admin() AND (ouvert_par = auth.uid())));


--
-- Name: acces_pieces; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.acces_pieces ENABLE ROW LEVEL SECURITY;

--
-- Name: acces_pieces acces_pieces_depot; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY acces_pieces_depot ON public.acces_pieces FOR INSERT TO authenticated WITH CHECK (((depose_par = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.acces_exceptionnels a
  WHERE ((a.id = acces_pieces.acces_id) AND (a.ouvert_par = auth.uid()) AND (a.clos_le IS NULL))))));


--
-- Name: acces_pieces acces_pieces_ecartement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY acces_pieces_ecartement ON public.acces_pieces FOR UPDATE TO authenticated USING (public.est_admin()) WITH CHECK ((public.est_admin() AND (ecartee_par = auth.uid())));


--
-- Name: acces_pieces acces_pieces_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY acces_pieces_lecture ON public.acces_pieces FOR SELECT TO authenticated USING (public.est_admin());


--
-- Name: adaptations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.adaptations ENABLE ROW LEVEL SECURITY;

--
-- Name: adaptations adaptations_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY adaptations_ecriture ON public.adaptations TO authenticated USING (public.peut_valider(public.enfant_de_l_adaptation(id))) WITH CHECK (public.peut_valider(public.enfant_du_support(support_id)));


--
-- Name: adaptations adaptations_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY adaptations_lecture ON public.adaptations FOR SELECT TO authenticated USING (public.est_intervenant(public.enfant_de_l_adaptation(id)));


--
-- Name: alertes_actions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.alertes_actions ENABLE ROW LEVEL SECURITY;

--
-- Name: alertes_actions alertes_actions_ajout; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY alertes_actions_ajout ON public.alertes_actions FOR INSERT TO authenticated WITH CHECK ((public.acces_a_l_alerte(alerte_id) AND (auteur_id = auth.uid())));


--
-- Name: alertes_actions alertes_actions_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY alertes_actions_lecture ON public.alertes_actions FOR SELECT TO authenticated USING (public.acces_a_l_alerte(alerte_id));


--
-- Name: alertes_actions alertes_actions_lecture_litige; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY alertes_actions_lecture_litige ON public.alertes_actions FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.alertes_difficulte a
  WHERE ((a.id = alertes_actions.alerte_id) AND public.acces_exceptionnel_actif(a.enfant_id)))));


--
-- Name: alertes_actions alertes_actions_maj; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY alertes_actions_maj ON public.alertes_actions FOR UPDATE TO authenticated USING ((auteur_id = auth.uid())) WITH CHECK ((auteur_id = auth.uid()));


--
-- Name: alertes_difficulte; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.alertes_difficulte ENABLE ROW LEVEL SECURITY;

--
-- Name: alertes_difficulte alertes_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY alertes_lecture ON public.alertes_difficulte FOR SELECT TO authenticated USING (public.acces_a_l_alerte(id));


--
-- Name: alertes_difficulte alertes_lecture_litige; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY alertes_lecture_litige ON public.alertes_difficulte FOR SELECT TO authenticated USING (public.acces_exceptionnel_actif(enfant_id));


--
-- Name: alertes_difficulte alertes_traitement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY alertes_traitement ON public.alertes_difficulte FOR UPDATE TO authenticated USING (public.acces_a_l_alerte(id)) WITH CHECK (((statut = 'ouverte'::public.statut_alerte) OR (traitee_par = auth.uid())));


--
-- Name: amorces_ecriture; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.amorces_ecriture ENABLE ROW LEVEL SECURITY;

--
-- Name: amorces_ecriture amorces_ecriture_maj; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY amorces_ecriture_maj ON public.amorces_ecriture TO authenticated USING (((enfant_id IS NOT NULL) AND public.peut_valider(enfant_id))) WITH CHECK (((enfant_id IS NOT NULL) AND public.peut_valider(enfant_id)));


--
-- Name: amorces_ecriture amorces_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY amorces_lecture ON public.amorces_ecriture FOR SELECT TO authenticated USING (((enfant_id IS NULL) OR public.est_intervenant(enfant_id) OR public.est_l_enfant(enfant_id)));


--
-- Name: annees_enfant; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.annees_enfant ENABLE ROW LEVEL SECURITY;

--
-- Name: annees_enfant annees_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY annees_lecture ON public.annees_enfant FOR SELECT TO authenticated USING ((public.est_intervenant(enfant_id) OR public.est_l_enfant(enfant_id)));


--
-- Name: annees_enfant annees_maj; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY annees_maj ON public.annees_enfant FOR UPDATE TO authenticated USING (public.peut_valider(enfant_id)) WITH CHECK (public.peut_valider(enfant_id));


--
-- Name: annees_enfant annees_ouverture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY annees_ouverture ON public.annees_enfant FOR INSERT TO authenticated WITH CHECK (public.peut_valider(enfant_id));


--
-- Name: appareils; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.appareils ENABLE ROW LEVEL SECURITY;

--
-- Name: appareils appareils_gestion; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY appareils_gestion ON public.appareils TO authenticated USING ((profil_id = auth.uid())) WITH CHECK ((profil_id = auth.uid()));


--
-- Name: avis_ia; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.avis_ia ENABLE ROW LEVEL SECURITY;

--
-- Name: avis_ia avis_ia_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY avis_ia_ecriture ON public.avis_ia TO authenticated USING ((auteur_id = auth.uid())) WITH CHECK (((auteur_id = auth.uid()) AND
CASE
    WHEN (mission_id IS NOT NULL) THEN (EXISTS ( SELECT 1
       FROM public.missions m
      WHERE ((m.id = avis_ia.mission_id) AND public.matiere_ouverte_a_l_ecriture(m.enfant_id, m.matiere_code))))
    ELSE (EXISTS ( SELECT 1
       FROM (public.adaptations a
         JOIN public.supports s ON ((s.id = a.support_id)))
      WHERE ((a.id = avis_ia.adaptation_id) AND public.matiere_ouverte_a_l_ecriture(s.enfant_id, s.matiere_code))))
END));


--
-- Name: avis_ia avis_ia_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY avis_ia_lecture ON public.avis_ia FOR SELECT TO authenticated USING (
CASE
    WHEN (mission_id IS NOT NULL) THEN public.est_intervenant(public.enfant_de_la_mission(mission_id))
    ELSE public.est_intervenant(public.enfant_de_l_adaptation(adaptation_id))
END);


--
-- Name: badges_obtenus badges_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY badges_lecture ON public.badges_obtenus FOR SELECT TO authenticated USING ((public.est_intervenant(enfant_id) OR public.est_l_enfant(enfant_id)));


--
-- Name: badges_obtenus; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.badges_obtenus ENABLE ROW LEVEL SECURITY;

--
-- Name: bilan_maitrises; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.bilan_maitrises ENABLE ROW LEVEL SECURITY;

--
-- Name: bilan_maitrises bilan_maitrises_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bilan_maitrises_ecriture ON public.bilan_maitrises TO authenticated USING (public.peut_valider(public.enfant_du_bilan(bilan_id))) WITH CHECK (public.peut_valider(public.enfant_du_bilan(bilan_id)));


--
-- Name: bilan_maitrises bilan_maitrises_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bilan_maitrises_lecture ON public.bilan_maitrises FOR SELECT TO authenticated USING (public.est_intervenant(public.enfant_du_bilan(bilan_id)));


--
-- Name: bilan_niveaux_matiere bilan_niveaux_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bilan_niveaux_ecriture ON public.bilan_niveaux_matiere TO authenticated USING (public.peut_valider(enfant_id)) WITH CHECK (public.peut_valider(enfant_id));


--
-- Name: bilan_niveaux_matiere bilan_niveaux_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bilan_niveaux_lecture ON public.bilan_niveaux_matiere FOR SELECT TO authenticated USING (public.est_intervenant(enfant_id));


--
-- Name: bilan_niveaux_matiere; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.bilan_niveaux_matiere ENABLE ROW LEVEL SECURITY;

--
-- Name: bilan_questions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.bilan_questions ENABLE ROW LEVEL SECURITY;

--
-- Name: bilan_questions bilan_questions_acces; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bilan_questions_acces ON public.bilan_questions TO authenticated USING (public.peut_valider(public.enfant_du_bilan(bilan_id))) WITH CHECK (public.peut_valider(public.enfant_du_bilan(bilan_id)));


--
-- Name: bilan_reponses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.bilan_reponses ENABLE ROW LEVEL SECURITY;

--
-- Name: bilan_reponses bilan_reponses_acces; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bilan_reponses_acces ON public.bilan_reponses TO authenticated USING (public.peut_valider(public.enfant_de_la_question(question_id))) WITH CHECK (public.peut_valider(public.enfant_de_la_question(question_id)));


--
-- Name: bilans_positionnement bilans_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bilans_ecriture ON public.bilans_positionnement TO authenticated USING (public.peut_valider(enfant_id)) WITH CHECK (public.peut_valider(enfant_id));


--
-- Name: bilans_positionnement bilans_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bilans_lecture ON public.bilans_positionnement FOR SELECT TO authenticated USING (public.est_intervenant(enfant_id));


--
-- Name: bilans_positionnement; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.bilans_positionnement ENABLE ROW LEVEL SECURITY;

--
-- Name: bilans_trimestriels bilans_trim_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bilans_trim_ecriture ON public.bilans_trimestriels TO authenticated USING (public.peut_valider(enfant_id)) WITH CHECK (public.peut_valider(enfant_id));


--
-- Name: bilans_trimestriels bilans_trim_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bilans_trim_lecture ON public.bilans_trimestriels FOR SELECT TO authenticated USING (public.est_intervenant(enfant_id));


--
-- Name: bilans_trimestriels_matieres bilans_trim_matieres_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bilans_trim_matieres_ecriture ON public.bilans_trimestriels_matieres TO authenticated USING (public.peut_valider(public.enfant_du_bilan_trimestriel(bilan_id))) WITH CHECK (public.peut_valider(public.enfant_du_bilan_trimestriel(bilan_id)));


--
-- Name: bilans_trimestriels_matieres bilans_trim_matieres_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY bilans_trim_matieres_lecture ON public.bilans_trimestriels_matieres FOR SELECT TO authenticated USING (public.est_intervenant(public.enfant_du_bilan_trimestriel(bilan_id)));


--
-- Name: bilans_trimestriels; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.bilans_trimestriels ENABLE ROW LEVEL SECURITY;

--
-- Name: bilans_trimestriels_matieres; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.bilans_trimestriels_matieres ENABLE ROW LEVEL SECURITY;

--
-- Name: centres_interet; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.centres_interet ENABLE ROW LEVEL SECURITY;

--
-- Name: centres_interet centres_interet_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY centres_interet_ecriture ON public.centres_interet TO authenticated USING (public.peut_valider(enfant_id)) WITH CHECK (public.peut_valider(enfant_id));


--
-- Name: centres_interet centres_interet_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY centres_interet_lecture ON public.centres_interet FOR SELECT TO authenticated USING (public.est_intervenant(enfant_id));


--
-- Name: centres_interet centres_interet_lecture_enfant; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY centres_interet_lecture_enfant ON public.centres_interet FOR SELECT TO authenticated USING (public.est_l_enfant(enfant_id));


--
-- Name: consentements; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.consentements ENABLE ROW LEVEL SECURITY;

--
-- Name: consentements consentements_creation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY consentements_creation ON public.consentements FOR INSERT TO authenticated WITH CHECK (((profil_id = auth.uid()) AND public.est_intervenant(enfant_id, ARRAY['parent'::public.role_intervenant])));


--
-- Name: consentements consentements_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY consentements_lecture ON public.consentements FOR SELECT TO authenticated USING (((profil_id = auth.uid()) OR public.est_intervenant(enfant_id, ARRAY['parent'::public.role_intervenant])));


--
-- Name: consentements consentements_revocation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY consentements_revocation ON public.consentements FOR UPDATE TO authenticated USING ((profil_id = auth.uid())) WITH CHECK ((profil_id = auth.uid()));


--
-- Name: corrections; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.corrections ENABLE ROW LEVEL SECURITY;

--
-- Name: corrections corrections_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY corrections_ecriture ON public.corrections TO authenticated USING ((public.est_intervenant(public.enfant_de_la_tentative(tentative_id), ARRAY['referent'::public.role_intervenant]) OR public.tentative_ouverte_a_l_enseignant(tentative_id))) WITH CHECK (((corrigee_par = auth.uid()) AND (public.est_intervenant(public.enfant_de_la_tentative(tentative_id), ARRAY['referent'::public.role_intervenant]) OR public.tentative_ouverte_a_l_enseignant(tentative_id))));


--
-- Name: corrections corrections_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY corrections_lecture ON public.corrections FOR SELECT TO authenticated USING ((public.peut_valider(public.enfant_de_la_tentative(tentative_id)) OR public.tentative_ouverte_a_l_enseignant(tentative_id)));


--
-- Name: corrections corrections_lecture_enfant; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY corrections_lecture_enfant ON public.corrections FOR SELECT TO authenticated USING (public.est_l_enfant(public.enfant_de_la_tentative(tentative_id)));


--
-- Name: corrections corrections_lecture_litige; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY corrections_lecture_litige ON public.corrections FOR SELECT TO authenticated USING (public.acces_exceptionnel_actif(public.enfant_de_la_tentative(tentative_id)));


--
-- Name: corrections corrections_lecture_pilote; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY corrections_lecture_pilote ON public.corrections FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.tentatives t
  WHERE ((t.id = corrections.tentative_id) AND public.exercice_sous_objectif_pilote(t.exercice_id)))));


--
-- Name: demandes_habilitation; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.demandes_habilitation ENABLE ROW LEVEL SECURITY;

--
-- Name: demandes_suppression; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.demandes_suppression ENABLE ROW LEVEL SECURITY;

--
-- Name: documents_diagnostic diagnostic_depot; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY diagnostic_depot ON public.documents_diagnostic FOR INSERT TO authenticated WITH CHECK ((public.est_intervenant(enfant_id, ARRAY['parent'::public.role_intervenant, 'referent'::public.role_intervenant]) AND (depose_par = auth.uid())));


--
-- Name: documents_diagnostic diagnostic_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY diagnostic_lecture ON public.documents_diagnostic FOR SELECT TO authenticated USING (public.est_intervenant(enfant_id, ARRAY['parent'::public.role_intervenant, 'referent'::public.role_intervenant]));


--
-- Name: documents_diagnostic diagnostic_maj; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY diagnostic_maj ON public.documents_diagnostic FOR UPDATE TO authenticated USING (public.est_intervenant(enfant_id, ARRAY['parent'::public.role_intervenant, 'referent'::public.role_intervenant])) WITH CHECK (public.est_intervenant(enfant_id, ARRAY['parent'::public.role_intervenant, 'referent'::public.role_intervenant]));


--
-- Name: documents_diagnostic diagnostic_retrait; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY diagnostic_retrait ON public.documents_diagnostic FOR DELETE TO authenticated USING (public.est_intervenant(enfant_id, ARRAY['parent'::public.role_intervenant, 'referent'::public.role_intervenant]));


--
-- Name: documents_diagnostic; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.documents_diagnostic ENABLE ROW LEVEL SECURITY;

--
-- Name: domaines_evaluation; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.domaines_evaluation ENABLE ROW LEVEL SECURITY;

--
-- Name: domaines_evaluation domaines_evaluation_administration; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY domaines_evaluation_administration ON public.domaines_evaluation TO authenticated USING (public.est_admin()) WITH CHECK (public.est_admin());


--
-- Name: domaines_evaluation domaines_evaluation_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY domaines_evaluation_lecture ON public.domaines_evaluation FOR SELECT TO authenticated USING (true);


--
-- Name: domaines_transversaux domaines_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY domaines_lecture ON public.domaines_transversaux FOR SELECT TO authenticated USING (true);


--
-- Name: domaines_transversaux; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.domaines_transversaux ENABLE ROW LEVEL SECURITY;

--
-- Name: enfants; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.enfants ENABLE ROW LEVEL SECURITY;

--
-- Name: enfants enfants_creation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY enfants_creation ON public.enfants FOR INSERT TO authenticated WITH CHECK (((cree_par = auth.uid()) AND public.peut_ouvrir_un_dossier()));


--
-- Name: enfants enfants_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY enfants_lecture ON public.enfants FOR SELECT TO authenticated USING ((public.est_intervenant(id) OR (cree_par = auth.uid())));


--
-- Name: enfants enfants_lecture_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY enfants_lecture_admin ON public.enfants FOR SELECT TO authenticated USING (public.est_admin());


--
-- Name: enfants enfants_lecture_enfant; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY enfants_lecture_enfant ON public.enfants FOR SELECT TO authenticated USING (((compte_id = auth.uid()) AND (archive_le IS NULL)));


--
-- Name: enfants enfants_maj; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY enfants_maj ON public.enfants FOR UPDATE TO authenticated USING ((public.peut_valider(id) OR (cree_par = auth.uid()) OR public.est_admin())) WITH CHECK ((public.peut_valider(id) OR (cree_par = auth.uid()) OR public.est_admin()));


--
-- Name: enfants_sante; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.enfants_sante ENABLE ROW LEVEL SECURITY;

--
-- Name: enfants_sante enfants_sante_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY enfants_sante_ecriture ON public.enfants_sante TO authenticated USING ((public.peut_valider(enfant_id) AND public.consentement_actif(enfant_id, 'traitement_donnees_sante'::public.type_consentement))) WITH CHECK ((public.peut_valider(enfant_id) AND public.consentement_actif(enfant_id, 'traitement_donnees_sante'::public.type_consentement)));


--
-- Name: enfants_sante enfants_sante_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY enfants_sante_lecture ON public.enfants_sante FOR SELECT TO authenticated USING (public.peut_valider(enfant_id));


--
-- Name: enfants_sante enfants_sante_lecture_famille; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY enfants_sante_lecture_famille ON public.enfants_sante FOR SELECT TO authenticated USING (public.peut_valider(enfant_id));


--
-- Name: enfants enfants_suppression; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY enfants_suppression ON public.enfants FOR DELETE TO authenticated USING (public.est_intervenant(id, ARRAY['parent'::public.role_intervenant]));


--
-- Name: envois; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.envois ENABLE ROW LEVEL SECURITY;

--
-- Name: envois envois_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY envois_lecture ON public.envois FOR SELECT TO authenticated USING (((destinataire_id = auth.uid()) OR public.est_admin()));


--
-- Name: exercices; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.exercices ENABLE ROW LEVEL SECURITY;

--
-- Name: exercices exercices_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY exercices_ecriture ON public.exercices TO authenticated USING ((public.est_intervenant(public.enfant_de_la_mission(mission_id), ARRAY['referent'::public.role_intervenant]) OR public.mission_ouverte_a_l_enseignant(mission_id) OR (public.mission_est_un_devoir(mission_id) AND public.peut_valider(public.enfant_de_la_mission(mission_id))))) WITH CHECK ((public.est_intervenant(public.enfant_de_la_mission(mission_id), ARRAY['referent'::public.role_intervenant]) OR public.mission_ouverte_a_l_enseignant(mission_id) OR (public.mission_est_un_devoir(mission_id) AND public.peut_valider(public.enfant_de_la_mission(mission_id)))));


--
-- Name: exercices exercices_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY exercices_lecture ON public.exercices FOR SELECT TO authenticated USING (public.est_intervenant(public.enfant_de_la_mission(mission_id)));


--
-- Name: exercices exercices_lecture_enfant; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY exercices_lecture_enfant ON public.exercices FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.missions m
  WHERE ((m.id = exercices.mission_id) AND public.est_l_enfant(m.enfant_id) AND (m.statut = ANY (ARRAY['validee'::public.statut_mission, 'en_cours'::public.statut_mission, 'reussie'::public.statut_mission]))))));


--
-- Name: exercices exercices_lecture_litige; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY exercices_lecture_litige ON public.exercices FOR SELECT TO authenticated USING (public.acces_exceptionnel_actif(public.enfant_de_la_mission(mission_id)));


--
-- Name: fils; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.fils ENABLE ROW LEVEL SECURITY;

--
-- Name: fils fils_creation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY fils_creation ON public.fils FOR INSERT TO authenticated WITH CHECK (((cree_par = auth.uid()) AND public.est_intervenant(enfant_id)));


--
-- Name: fils fils_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY fils_lecture ON public.fils FOR SELECT TO authenticated USING (public.acces_au_fil(id));


--
-- Name: fils fils_lecture_litige; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY fils_lecture_litige ON public.fils FOR SELECT TO authenticated USING (public.acces_exceptionnel_actif(enfant_id));


--
-- Name: fils fils_maj; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY fils_maj ON public.fils FOR UPDATE TO authenticated USING (public.acces_au_fil(id)) WITH CHECK (public.acces_au_fil(id));


--
-- Name: fils_participants; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.fils_participants ENABLE ROW LEVEL SECURITY;

--
-- Name: fils_participants fils_participants_ajout; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY fils_participants_ajout ON public.fils_participants FOR INSERT TO authenticated WITH CHECK ((public.peut_composer_le_fil(fil_id) AND (EXISTS ( SELECT 1
   FROM public.fils f
  WHERE ((f.id = fils_participants.fil_id) AND public.est_intervenant_de(fils_participants.profil_id, f.enfant_id))))));


--
-- Name: fils_participants fils_participants_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY fils_participants_lecture ON public.fils_participants FOR SELECT TO authenticated USING (public.acces_au_fil(fil_id));


--
-- Name: fils_participants fils_participants_retrait; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY fils_participants_retrait ON public.fils_participants FOR DELETE TO authenticated USING ((public.peut_composer_le_fil(fil_id) OR (profil_id = auth.uid())));


--
-- Name: generations_bilan generations_annulation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY generations_annulation ON public.generations_bilan FOR UPDATE TO authenticated USING (public.est_intervenant(enfant_id, ARRAY['referent'::public.role_intervenant, 'parent'::public.role_intervenant])) WITH CHECK (public.est_intervenant(enfant_id, ARRAY['referent'::public.role_intervenant, 'parent'::public.role_intervenant]));


--
-- Name: generations_bilan; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.generations_bilan ENABLE ROW LEVEL SECURITY;

--
-- Name: generations_bilan generations_depot; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY generations_depot ON public.generations_bilan FOR INSERT TO authenticated WITH CHECK ((public.est_intervenant(enfant_id, ARRAY['referent'::public.role_intervenant, 'parent'::public.role_intervenant]) AND (demande_par = auth.uid())));


--
-- Name: generations_bilan generations_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY generations_lecture ON public.generations_bilan FOR SELECT TO authenticated USING ((public.est_intervenant(enfant_id) OR public.est_admin()));


--
-- Name: habilitation_pieces; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.habilitation_pieces ENABLE ROW LEVEL SECURITY;

--
-- Name: habilitation_pieces habilitation_pieces_depot; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY habilitation_pieces_depot ON public.habilitation_pieces FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM public.demandes_habilitation d
  WHERE ((d.id = habilitation_pieces.demande_id) AND (d.profil_id = auth.uid()) AND (d.statut = 'en_attente'::public.statut_habilitation)))));


--
-- Name: habilitation_pieces habilitation_pieces_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY habilitation_pieces_lecture ON public.habilitation_pieces FOR SELECT TO authenticated USING ((public.est_admin() OR (EXISTS ( SELECT 1
   FROM public.demandes_habilitation d
  WHERE ((d.id = habilitation_pieces.demande_id) AND (d.profil_id = auth.uid()))))));


--
-- Name: habilitation_pieces habilitation_pieces_retrait; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY habilitation_pieces_retrait ON public.habilitation_pieces FOR DELETE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.demandes_habilitation d
  WHERE ((d.id = habilitation_pieces.demande_id) AND (d.profil_id = auth.uid()) AND (d.statut = 'en_attente'::public.statut_habilitation)))));


--
-- Name: demandes_habilitation habilitations_depot; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY habilitations_depot ON public.demandes_habilitation FOR INSERT TO authenticated WITH CHECK (((profil_id = auth.uid()) AND (statut = 'en_attente'::public.statut_habilitation)));


--
-- Name: demandes_habilitation habilitations_instruction; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY habilitations_instruction ON public.demandes_habilitation FOR UPDATE TO authenticated USING (public.est_admin()) WITH CHECK (public.est_admin());


--
-- Name: demandes_habilitation habilitations_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY habilitations_lecture ON public.demandes_habilitation FOR SELECT TO authenticated USING (((profil_id = auth.uid()) OR public.est_admin()));


--
-- Name: demandes_habilitation habilitations_retrait; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY habilitations_retrait ON public.demandes_habilitation FOR UPDATE TO authenticated USING (((profil_id = auth.uid()) AND (statut = 'en_attente'::public.statut_habilitation))) WITH CHECK (((profil_id = auth.uid()) AND (statut = ANY (ARRAY['en_attente'::public.statut_habilitation, 'retiree'::public.statut_habilitation]))));


--
-- Name: intervenants_enfant intervenants_ajout; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY intervenants_ajout ON public.intervenants_enfant FOR INSERT TO authenticated WITH CHECK ((public.est_admin() OR ((profil_id = auth.uid()) AND (role = 'referent'::public.role_intervenant) AND (EXISTS ( SELECT 1
   FROM public.enfants e
  WHERE ((e.id = intervenants_enfant.enfant_id) AND (e.cree_par = auth.uid())))))));


--
-- Name: intervenants_enfant; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.intervenants_enfant ENABLE ROW LEVEL SECURITY;

--
-- Name: intervenants_enfant intervenants_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY intervenants_lecture ON public.intervenants_enfant FOR SELECT TO authenticated USING (((profil_id = auth.uid()) OR public.est_intervenant(enfant_id)));


--
-- Name: intervenants_enfant intervenants_maj; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY intervenants_maj ON public.intervenants_enfant FOR UPDATE TO authenticated USING (((profil_id = auth.uid()) OR public.est_admin() OR public.est_intervenant(enfant_id, ARRAY['parent'::public.role_intervenant, 'referent'::public.role_intervenant]))) WITH CHECK (((profil_id = auth.uid()) OR public.est_admin() OR public.est_intervenant(enfant_id, ARRAY['parent'::public.role_intervenant, 'referent'::public.role_intervenant])));


--
-- Name: intervenants_matieres; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.intervenants_matieres ENABLE ROW LEVEL SECURITY;

--
-- Name: intervenants_matieres intervenants_matieres_composition; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY intervenants_matieres_composition ON public.intervenants_matieres TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.intervenants_enfant i
  WHERE ((i.id = intervenants_matieres.intervenant_id) AND (public.est_intervenant(i.enfant_id, ARRAY['parent'::public.role_intervenant, 'referent'::public.role_intervenant]) OR public.est_admin()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.intervenants_enfant i
  WHERE ((i.id = intervenants_matieres.intervenant_id) AND (public.est_intervenant(i.enfant_id, ARRAY['parent'::public.role_intervenant, 'referent'::public.role_intervenant]) OR public.est_admin())))));


--
-- Name: intervenants_matieres intervenants_matieres_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY intervenants_matieres_lecture ON public.intervenants_matieres FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.intervenants_enfant i
  WHERE ((i.id = intervenants_matieres.intervenant_id) AND public.est_intervenant(i.enfant_id)))));


--
-- Name: intervenants_enfant intervenants_retrait; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY intervenants_retrait ON public.intervenants_enfant FOR DELETE TO authenticated USING (((profil_id = auth.uid()) OR public.est_admin() OR public.est_intervenant(enfant_id, ARRAY['parent'::public.role_intervenant, 'referent'::public.role_intervenant])));


--
-- Name: invitations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.invitations ENABLE ROW LEVEL SECURITY;

--
-- Name: invitations invitations_creation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY invitations_creation ON public.invitations FOR INSERT TO authenticated WITH CHECK (((invite_par = auth.uid()) AND public.definit_l_autorite_parentale(enfant_id)));


--
-- Name: invitations invitations_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY invitations_lecture ON public.invitations FOR SELECT TO authenticated USING ((public.peut_valider(enfant_id) OR (lower(email) = public.email_courant())));


--
-- Name: invitations invitations_maj; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY invitations_maj ON public.invitations FOR UPDATE TO authenticated USING ((public.peut_valider(enfant_id) OR (lower(email) = public.email_courant()) OR public.est_admin())) WITH CHECK ((public.peut_valider(enfant_id) OR (lower(email) = public.email_courant()) OR public.est_admin()));


--
-- Name: items_evaluation_nationale items_evaluation_administration; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY items_evaluation_administration ON public.items_evaluation_nationale TO authenticated USING (public.est_admin()) WITH CHECK (public.est_admin());


--
-- Name: items_evaluation_nationale items_evaluation_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY items_evaluation_lecture ON public.items_evaluation_nationale FOR SELECT TO authenticated USING (true);


--
-- Name: items_evaluation_nationale; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.items_evaluation_nationale ENABLE ROW LEVEL SECURITY;

--
-- Name: journal_acces; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journal_acces ENABLE ROW LEVEL SECURITY;

--
-- Name: journal_acces journal_acces_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_acces_ecriture ON public.journal_acces FOR INSERT TO authenticated WITH CHECK ((public.est_intervenant(enfant_id) AND (profil_id = auth.uid())));


--
-- Name: journal_acces journal_acces_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_acces_lecture ON public.journal_acces FOR SELECT TO authenticated USING ((public.peut_valider(enfant_id) AND (NOT ((action = ANY (ARRAY['acces_exceptionnel_ouvert'::text, 'acces_exceptionnel_revele'::text])) AND (EXISTS ( SELECT 1
   FROM public.acces_exceptionnels a
  WHERE ((a.id = journal_acces.ligne_id) AND (a.information_faite_le IS NULL))))))));


--
-- Name: journal_acces journal_acces_lecture_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_acces_lecture_admin ON public.journal_acces FOR SELECT TO authenticated USING ((public.est_admin() AND (action = ANY (ARRAY['correction_administrative'::text, 'acces_exceptionnel_ouvert'::text, 'acces_exceptionnel_revele'::text]))));


--
-- Name: journal_acces journal_acces_lecture_litige; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_acces_lecture_litige ON public.journal_acces FOR SELECT TO authenticated USING (public.acces_exceptionnel_actif(enfant_id));


--
-- Name: journal_entrees; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journal_entrees ENABLE ROW LEVEL SECURITY;

--
-- Name: journal_entrees journal_entrees_correction; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_entrees_correction ON public.journal_entrees FOR UPDATE TO authenticated USING ((auteur_id = auth.uid())) WITH CHECK ((auteur_id = auth.uid()));


--
-- Name: journal_entrees journal_entrees_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_entrees_ecriture ON public.journal_entrees FOR INSERT TO authenticated WITH CHECK (((auteur_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.journees j
  WHERE ((j.id = journal_entrees.journee_id) AND public.est_intervenant(j.enfant_id))))));


--
-- Name: journal_entrees journal_entrees_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_entrees_lecture ON public.journal_entrees FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.journees j
  WHERE ((j.id = journal_entrees.journee_id) AND (public.est_intervenant(j.enfant_id) OR (public.est_l_enfant(j.enfant_id) AND journal_entrees.visible_par_l_enfant))))));


--
-- Name: journal_entrees journal_entrees_retrait; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_entrees_retrait ON public.journal_entrees FOR DELETE TO authenticated USING ((auteur_id = auth.uid()));


--
-- Name: journal_ia; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journal_ia ENABLE ROW LEVEL SECURITY;

--
-- Name: journal_ia journal_ia_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_ia_ecriture ON public.journal_ia FOR INSERT TO authenticated WITH CHECK (((enfant_id IS NULL) OR (public.est_intervenant(enfant_id) AND public.consentement_actif(enfant_id, 'generation_ia'::public.type_consentement))));


--
-- Name: journal_ia journal_ia_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_ia_lecture ON public.journal_ia FOR SELECT TO authenticated USING (((enfant_id IS NOT NULL) AND public.peut_valider(enfant_id)));


--
-- Name: journal_ia journal_ia_lecture_litige; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_ia_lecture_litige ON public.journal_ia FOR SELECT TO authenticated USING (((enfant_id IS NOT NULL) AND public.acces_exceptionnel_actif(enfant_id)));


--
-- Name: journal_medias; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journal_medias ENABLE ROW LEVEL SECURITY;

--
-- Name: journal_medias journal_medias_depot; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_medias_depot ON public.journal_medias FOR INSERT TO authenticated WITH CHECK (((depose_par = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.journees j
  WHERE ((j.id = journal_medias.journee_id) AND (public.est_intervenant(j.enfant_id) OR public.est_l_enfant(j.enfant_id)))))));


--
-- Name: journal_medias journal_medias_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_medias_lecture ON public.journal_medias FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.journees j
  WHERE ((j.id = journal_medias.journee_id) AND (public.est_intervenant(j.enfant_id) OR (public.est_l_enfant(j.enfant_id) AND ((journal_medias.entree_id IS NULL) OR (EXISTS ( SELECT 1
           FROM public.journal_entrees e
          WHERE ((e.id = journal_medias.entree_id) AND e.visible_par_l_enfant))))))))));


--
-- Name: journal_medias journal_medias_retrait; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journal_medias_retrait ON public.journal_medias FOR DELETE TO authenticated USING ((depose_par = auth.uid()));


--
-- Name: journee_etapes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journee_etapes ENABLE ROW LEVEL SECURITY;

--
-- Name: journee_etapes journee_etapes_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journee_etapes_ecriture ON public.journee_etapes TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.journees j
  WHERE ((j.id = journee_etapes.journee_id) AND public.est_intervenant(j.enfant_id))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.journees j
  WHERE ((j.id = journee_etapes.journee_id) AND public.est_intervenant(j.enfant_id)))));


--
-- Name: journee_etapes journee_etapes_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journee_etapes_lecture ON public.journee_etapes FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.journees j
  WHERE ((j.id = journee_etapes.journee_id) AND (public.est_intervenant(j.enfant_id) OR public.est_l_enfant(j.enfant_id))))));


--
-- Name: journee_preparatifs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journee_preparatifs ENABLE ROW LEVEL SECURITY;

--
-- Name: journee_preparatifs journee_preparatifs_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journee_preparatifs_ecriture ON public.journee_preparatifs FOR INSERT TO authenticated WITH CHECK ((EXISTS ( SELECT 1
   FROM public.journees j
  WHERE ((j.id = journee_preparatifs.journee_id) AND public.est_intervenant(j.enfant_id)))));


--
-- Name: journee_preparatifs journee_preparatifs_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journee_preparatifs_lecture ON public.journee_preparatifs FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.journees j
  WHERE ((j.id = journee_preparatifs.journee_id) AND (public.est_intervenant(j.enfant_id) OR public.est_l_enfant(j.enfant_id))))));


--
-- Name: journee_preparatifs journee_preparatifs_maj; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journee_preparatifs_maj ON public.journee_preparatifs FOR UPDATE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.journees j
  WHERE ((j.id = journee_preparatifs.journee_id) AND (public.est_intervenant(j.enfant_id) OR public.est_l_enfant(j.enfant_id)))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.journees j
  WHERE ((j.id = journee_preparatifs.journee_id) AND (public.est_intervenant(j.enfant_id) OR public.est_l_enfant(j.enfant_id))))));


--
-- Name: journee_preparatifs journee_preparatifs_retrait; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journee_preparatifs_retrait ON public.journee_preparatifs FOR DELETE TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.journees j
  WHERE ((j.id = journee_preparatifs.journee_id) AND public.est_intervenant(j.enfant_id)))));


--
-- Name: journee_reperes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journee_reperes ENABLE ROW LEVEL SECURITY;

--
-- Name: journee_reperes journee_reperes_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journee_reperes_ecriture ON public.journee_reperes TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.journees j
  WHERE ((j.id = journee_reperes.journee_id) AND public.est_intervenant(j.enfant_id))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.journees j
  WHERE ((j.id = journee_reperes.journee_id) AND public.est_intervenant(j.enfant_id)))));


--
-- Name: journee_reperes journee_reperes_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journee_reperes_lecture ON public.journee_reperes FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.journees j
  WHERE ((j.id = journee_reperes.journee_id) AND (public.est_intervenant(j.enfant_id) OR public.est_l_enfant(j.enfant_id))))));


--
-- Name: journees; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.journees ENABLE ROW LEVEL SECURITY;

--
-- Name: journees journees_creation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journees_creation ON public.journees FOR INSERT TO authenticated WITH CHECK ((public.est_intervenant(enfant_id) OR public.est_l_enfant(enfant_id)));


--
-- Name: journees journees_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journees_lecture ON public.journees FOR SELECT TO authenticated USING ((public.est_intervenant(enfant_id) OR public.est_l_enfant(enfant_id)));


--
-- Name: journees journees_maj; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY journees_maj ON public.journees FOR UPDATE TO authenticated USING ((public.est_intervenant(enfant_id) OR public.est_l_enfant(enfant_id))) WITH CHECK ((public.est_intervenant(enfant_id) OR public.est_l_enfant(enfant_id)));


--
-- Name: matieres; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.matieres ENABLE ROW LEVEL SECURITY;

--
-- Name: matieres matieres_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY matieres_lecture ON public.matieres FOR SELECT TO authenticated USING (true);


--
-- Name: messages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: messages messages_correction; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY messages_correction ON public.messages FOR UPDATE TO authenticated USING ((auteur_id = auth.uid())) WITH CHECK ((auteur_id = auth.uid()));


--
-- Name: messages messages_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY messages_ecriture ON public.messages FOR INSERT TO authenticated WITH CHECK ((public.acces_au_fil(fil_id) AND (auteur_id = auth.uid())));


--
-- Name: messages messages_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY messages_lecture ON public.messages FOR SELECT TO authenticated USING (public.acces_au_fil(fil_id));


--
-- Name: messages messages_lecture_litige; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY messages_lecture_litige ON public.messages FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.fils f
  WHERE ((f.id = messages.fil_id) AND public.acces_exceptionnel_actif(f.enfant_id)))));


--
-- Name: missions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.missions ENABLE ROW LEVEL SECURITY;

--
-- Name: missions missions_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY missions_ecriture ON public.missions TO authenticated USING ((public.peut_valider(enfant_id) OR (public.matiere_ouverte_a_l_ecriture(enfant_id, matiere_code) AND (objectif_id IS NOT NULL) AND public.objectif_valide(objectif_id)))) WITH CHECK ((public.peut_valider(enfant_id) OR (public.matiere_ouverte_a_l_ecriture(enfant_id, matiere_code) AND (objectif_id IS NOT NULL) AND public.objectif_valide(objectif_id) AND ((auteur_id IS NULL) OR (auteur_id = auth.uid())))));


--
-- Name: missions missions_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY missions_lecture ON public.missions FOR SELECT TO authenticated USING (public.est_intervenant(enfant_id));


--
-- Name: missions missions_lecture_enfant; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY missions_lecture_enfant ON public.missions FOR SELECT TO authenticated USING ((public.est_l_enfant(enfant_id) AND (statut = ANY (ARRAY['validee'::public.statut_mission, 'en_cours'::public.statut_mission, 'reussie'::public.statut_mission]))));


--
-- Name: missions missions_lecture_litige; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY missions_lecture_litige ON public.missions FOR SELECT TO authenticated USING (public.acces_exceptionnel_actif(enfant_id));


--
-- Name: modeles_exercice; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.modeles_exercice ENABLE ROW LEVEL SECURITY;

--
-- Name: modeles_exercice modeles_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY modeles_lecture ON public.modeles_exercice FOR SELECT TO authenticated USING (public.accompagne_un_enfant());


--
-- Name: modeles_exercice modeles_proposition; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY modeles_proposition ON public.modeles_exercice FOR INSERT TO authenticated WITH CHECK (((cree_par = auth.uid()) AND (statut = 'propose'::public.statut_modele) AND public.accompagne_un_enfant()));


--
-- Name: modeles_exercice modeles_suppression; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY modeles_suppression ON public.modeles_exercice FOR DELETE TO authenticated USING (((cree_par = auth.uid()) AND (statut = 'propose'::public.statut_modele)));


--
-- Name: modeles_exercice modeles_validation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY modeles_validation ON public.modeles_exercice FOR UPDATE TO authenticated USING ((public.enseigne_la_matiere(matiere_code) OR ((cree_par = auth.uid()) AND (statut = 'propose'::public.statut_modele)))) WITH CHECK (((public.enseigne_la_matiere(matiere_code) OR ((cree_par = auth.uid()) AND (statut = 'propose'::public.statut_modele))) AND ((statut <> 'valide'::public.statut_modele) OR (valide_par = auth.uid()))));


--
-- Name: notations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notations ENABLE ROW LEVEL SECURITY;

--
-- Name: notations notations_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY notations_ecriture ON public.notations TO authenticated USING ((public.est_intervenant(public.enfant_de_la_mission(mission_id), ARRAY['referent'::public.role_intervenant]) OR public.mission_relevant_de_l_enseignant(mission_id))) WITH CHECK (((note_par = auth.uid()) AND (public.est_intervenant(public.enfant_de_la_mission(mission_id), ARRAY['referent'::public.role_intervenant]) OR public.mission_relevant_de_l_enseignant(mission_id))));


--
-- Name: notations notations_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY notations_lecture ON public.notations FOR SELECT TO authenticated USING (public.est_intervenant(public.enfant_de_la_mission(mission_id)));


--
-- Name: notations notations_lecture_enfant; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY notations_lecture_enfant ON public.notations FOR SELECT TO authenticated USING (public.est_l_enfant(public.enfant_de_la_mission(mission_id)));


--
-- Name: notations notations_lecture_litige; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY notations_lecture_litige ON public.notations FOR SELECT TO authenticated USING (public.acces_exceptionnel_actif(public.enfant_de_la_mission(mission_id)));


--
-- Name: notifications; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

--
-- Name: notifications notifications_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY notifications_lecture ON public.notifications FOR SELECT TO authenticated USING ((destinataire_id = auth.uid()));


--
-- Name: notifications notifications_maj; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY notifications_maj ON public.notifications FOR UPDATE TO authenticated USING ((destinataire_id = auth.uid())) WITH CHECK ((destinataire_id = auth.uid()));


--
-- Name: notifications notifications_suppression; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY notifications_suppression ON public.notifications FOR DELETE TO authenticated USING ((destinataire_id = auth.uid()));


--
-- Name: objectifs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.objectifs ENABLE ROW LEVEL SECURITY;

--
-- Name: objectifs_demandes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.objectifs_demandes ENABLE ROW LEVEL SECURITY;

--
-- Name: objectifs_demandes objectifs_demandes_creation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY objectifs_demandes_creation ON public.objectifs_demandes FOR INSERT TO authenticated WITH CHECK (((demande_par = auth.uid()) AND public.est_intervenant(public.enfant_de_l_objectif(objectif_id)) AND (EXISTS ( SELECT 1
   FROM public.objectifs o
  WHERE ((o.id = objectifs_demandes.objectif_id) AND public.matiere_ouverte_a_l_ecriture(o.enfant_id, o.matiere_code))))));


--
-- Name: objectifs_demandes objectifs_demandes_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY objectifs_demandes_lecture ON public.objectifs_demandes FOR SELECT TO authenticated USING (public.est_intervenant(public.enfant_de_l_objectif(objectif_id)));


--
-- Name: objectifs_demandes objectifs_demandes_lecture_litige; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY objectifs_demandes_lecture_litige ON public.objectifs_demandes FOR SELECT TO authenticated USING (public.acces_exceptionnel_actif(public.enfant_de_l_objectif(objectif_id)));


--
-- Name: objectifs_demandes objectifs_demandes_traitement; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY objectifs_demandes_traitement ON public.objectifs_demandes FOR UPDATE TO authenticated USING ((public.peut_valider(public.enfant_de_l_objectif(objectif_id)) OR ((demande_par = auth.uid()) AND (statut = 'ouverte'::public.statut_demande)))) WITH CHECK ((public.peut_valider(public.enfant_de_l_objectif(objectif_id)) OR ((demande_par = auth.uid()) AND (statut = ANY (ARRAY['ouverte'::public.statut_demande, 'retiree'::public.statut_demande])))));


--
-- Name: objectifs objectifs_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY objectifs_lecture ON public.objectifs FOR SELECT TO authenticated USING (public.est_intervenant(enfant_id));


--
-- Name: objectifs objectifs_lecture_enfant; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY objectifs_lecture_enfant ON public.objectifs FOR SELECT TO authenticated USING ((public.est_l_enfant(enfant_id) AND (statut = ANY (ARRAY['valide'::public.statut_objectif, 'atteint'::public.statut_objectif]))));


--
-- Name: objectifs objectifs_lecture_litige; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY objectifs_lecture_litige ON public.objectifs FOR SELECT TO authenticated USING (public.acces_exceptionnel_actif(enfant_id));


--
-- Name: objectifs objectifs_maj; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY objectifs_maj ON public.objectifs FOR UPDATE TO authenticated USING ((public.peut_valider(enfant_id) OR ((propose_par = auth.uid()) AND (statut = 'propose'::public.statut_objectif)) OR ((granularite = 'fin'::public.granularite_objectif) AND public.pilote_l_objectif(id)))) WITH CHECK ((public.peut_valider(enfant_id) OR ((propose_par = auth.uid()) AND (statut = 'propose'::public.statut_objectif)) OR ((granularite = 'fin'::public.granularite_objectif) AND public.pilote_l_objectif(id))));


--
-- Name: objectifs objectifs_proposition; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY objectifs_proposition ON public.objectifs FOR INSERT TO authenticated WITH CHECK ((public.est_intervenant(enfant_id) AND (propose_par = auth.uid()) AND ((statut = 'propose'::public.statut_objectif) OR public.peut_valider(enfant_id)) AND public.matiere_ouverte_a_l_ecriture(enfant_id, matiere_code)));


--
-- Name: objectifs objectifs_suppression; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY objectifs_suppression ON public.objectifs FOR DELETE TO authenticated USING ((public.peut_valider(enfant_id) OR ((propose_par = auth.uid()) AND (statut = 'propose'::public.statut_objectif))));


--
-- Name: objectifs_validations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.objectifs_validations ENABLE ROW LEVEL SECURITY;

--
-- Name: objectifs_validations objectifs_validations_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY objectifs_validations_lecture ON public.objectifs_validations FOR SELECT TO authenticated USING (public.est_intervenant(public.enfant_de_l_objectif(objectif_id)));


--
-- Name: objectifs_validations objectifs_validations_lecture_litige; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY objectifs_validations_lecture_litige ON public.objectifs_validations FOR SELECT TO authenticated USING (public.acces_exceptionnel_actif(public.enfant_de_l_objectif(objectif_id)));


--
-- Name: objectifs_validations objectifs_validations_retrait; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY objectifs_validations_retrait ON public.objectifs_validations FOR DELETE TO authenticated USING (((profil_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.objectifs o
  WHERE ((o.id = objectifs_validations.objectif_id) AND (o.statut = 'propose'::public.statut_objectif))))));


--
-- Name: objectifs_validations objectifs_validations_signature; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY objectifs_validations_signature ON public.objectifs_validations FOR INSERT TO authenticated WITH CHECK (((profil_id = auth.uid()) AND (EXISTS ( SELECT 1
   FROM public.valideurs_requis(objectifs_validations.objectif_id) r(profil_id)
  WHERE (r.profil_id = auth.uid())))));


--
-- Name: observations_capacites; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.observations_capacites ENABLE ROW LEVEL SECURITY;

--
-- Name: observations_capacites observations_correction; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY observations_correction ON public.observations_capacites FOR UPDATE TO authenticated USING ((rempli_par = auth.uid())) WITH CHECK ((rempli_par = auth.uid()));


--
-- Name: observations_capacites observations_creation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY observations_creation ON public.observations_capacites FOR INSERT TO authenticated WITH CHECK ((public.est_intervenant(enfant_id) AND (rempli_par = auth.uid())));


--
-- Name: observations_capacites observations_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY observations_lecture ON public.observations_capacites FOR SELECT TO authenticated USING (public.est_intervenant(enfant_id));


--
-- Name: observations_reponses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.observations_reponses ENABLE ROW LEVEL SECURITY;

--
-- Name: periodes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.periodes ENABLE ROW LEVEL SECURITY;

--
-- Name: periodes periodes_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY periodes_ecriture ON public.periodes TO authenticated USING (public.peut_valider(enfant_id)) WITH CHECK (public.peut_valider(enfant_id));


--
-- Name: periodes periodes_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY periodes_lecture ON public.periodes FOR SELECT TO authenticated USING ((public.est_intervenant(enfant_id) OR public.est_l_enfant(enfant_id)));


--
-- Name: pieces_gagnees pieces_cadeau; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pieces_cadeau ON public.pieces_gagnees FOR INSERT TO authenticated WITH CHECK (((source = 'cadeau'::public.source_pieces) AND (attribue_par = auth.uid()) AND public.est_intervenant(enfant_id) AND (length(btrim(motif)) > 0)));


--
-- Name: pieces_gagnees; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pieces_gagnees ENABLE ROW LEVEL SECURITY;

--
-- Name: pieces_jointes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.pieces_jointes ENABLE ROW LEVEL SECURITY;

--
-- Name: pieces_jointes pieces_jointes_depot; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pieces_jointes_depot ON public.pieces_jointes FOR INSERT TO authenticated WITH CHECK (public.acces_au_message(message_id));


--
-- Name: pieces_jointes pieces_jointes_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pieces_jointes_lecture ON public.pieces_jointes FOR SELECT TO authenticated USING (public.acces_au_message(message_id));


--
-- Name: pieces_jointes pieces_jointes_lecture_litige; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pieces_jointes_lecture_litige ON public.pieces_jointes FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM (public.messages m
     JOIN public.fils f ON ((f.id = m.fil_id)))
  WHERE ((m.id = pieces_jointes.message_id) AND public.acces_exceptionnel_actif(f.enfant_id)))));


--
-- Name: pieces_gagnees pieces_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY pieces_lecture ON public.pieces_gagnees FOR SELECT TO authenticated USING ((public.est_intervenant(enfant_id) OR public.est_l_enfant(enfant_id)));


--
-- Name: preferences_notification preferences_gestion; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY preferences_gestion ON public.preferences_notification TO authenticated USING ((profil_id = auth.uid())) WITH CHECK ((profil_id = auth.uid()));


--
-- Name: preferences_notification; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.preferences_notification ENABLE ROW LEVEL SECURITY;

--
-- Name: preparatifs_recurrents; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.preparatifs_recurrents ENABLE ROW LEVEL SECURITY;

--
-- Name: preparatifs_recurrents preparatifs_recurrents_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY preparatifs_recurrents_ecriture ON public.preparatifs_recurrents TO authenticated USING (public.peut_valider(enfant_id)) WITH CHECK (public.peut_valider(enfant_id));


--
-- Name: preparatifs_recurrents preparatifs_recurrents_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY preparatifs_recurrents_lecture ON public.preparatifs_recurrents FOR SELECT TO authenticated USING ((public.est_intervenant(enfant_id) OR public.est_l_enfant(enfant_id)));


--
-- Name: profils; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profils ENABLE ROW LEVEL SECURITY;

--
-- Name: profils profils_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profils_lecture ON public.profils FOR SELECT TO authenticated USING (((id = auth.uid()) OR public.partage_un_enfant(id)));


--
-- Name: profils profils_maj; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profils_maj ON public.profils FOR UPDATE TO authenticated USING (((id = auth.uid()) OR public.est_admin())) WITH CHECK (((id = auth.uid()) OR public.est_admin()));


--
-- Name: programme_applicable; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.programme_applicable ENABLE ROW LEVEL SECURITY;

--
-- Name: programme_applicable programme_applicable_administration; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY programme_applicable_administration ON public.programme_applicable TO authenticated USING (public.est_admin()) WITH CHECK (public.est_admin());


--
-- Name: programme_applicable programme_applicable_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY programme_applicable_lecture ON public.programme_applicable FOR SELECT TO authenticated USING (true);


--
-- Name: projets_moteurs; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.projets_moteurs ENABLE ROW LEVEL SECURITY;

--
-- Name: projets_moteurs projets_moteurs_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY projets_moteurs_ecriture ON public.projets_moteurs TO authenticated USING (public.peut_valider(enfant_id)) WITH CHECK (public.peut_valider(enfant_id));


--
-- Name: projets_moteurs projets_moteurs_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY projets_moteurs_lecture ON public.projets_moteurs FOR SELECT TO authenticated USING (public.est_intervenant(enfant_id));


--
-- Name: projets_moteurs projets_moteurs_lecture_enfant; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY projets_moteurs_lecture_enfant ON public.projets_moteurs FOR SELECT TO authenticated USING (public.est_l_enfant(enfant_id));


--
-- Name: questionnaires_capacites questionnaires_administration; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY questionnaires_administration ON public.questionnaires_capacites TO authenticated USING (public.est_admin()) WITH CHECK (public.est_admin());


--
-- Name: questionnaires_capacites; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.questionnaires_capacites ENABLE ROW LEVEL SECURITY;

--
-- Name: questionnaires_capacites questionnaires_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY questionnaires_lecture ON public.questionnaires_capacites FOR SELECT TO authenticated USING (true);


--
-- Name: quetes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.quetes ENABLE ROW LEVEL SECURITY;

--
-- Name: quetes_badges_vises quetes_badges_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY quetes_badges_ecriture ON public.quetes_badges_vises TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.quetes q
  WHERE ((q.id = quetes_badges_vises.quete_id) AND public.peut_valider(q.enfant_id))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.quetes q
  WHERE ((q.id = quetes_badges_vises.quete_id) AND public.peut_valider(q.enfant_id)))));


--
-- Name: quetes_badges_vises quetes_badges_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY quetes_badges_lecture ON public.quetes_badges_vises FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.quetes q
  WHERE ((q.id = quetes_badges_vises.quete_id) AND (public.est_intervenant(q.enfant_id) OR public.est_l_enfant(q.enfant_id))))));


--
-- Name: quetes_badges_vises; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.quetes_badges_vises ENABLE ROW LEVEL SECURITY;

--
-- Name: quetes quetes_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY quetes_ecriture ON public.quetes TO authenticated USING (public.peut_valider(enfant_id)) WITH CHECK (public.peut_valider(enfant_id));


--
-- Name: quetes quetes_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY quetes_lecture ON public.quetes FOR SELECT TO authenticated USING ((public.est_intervenant(enfant_id) OR public.est_l_enfant(enfant_id)));


--
-- Name: recompenses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.recompenses ENABLE ROW LEVEL SECURITY;

--
-- Name: recompenses recompenses_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY recompenses_ecriture ON public.recompenses TO authenticated USING (public.peut_valider(public.enfant_du_projet_moteur(projet_moteur_id))) WITH CHECK (public.peut_valider(public.enfant_du_projet_moteur(projet_moteur_id)));


--
-- Name: recompenses_familiales; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.recompenses_familiales ENABLE ROW LEVEL SECURITY;

--
-- Name: recompenses_familiales recompenses_familiales_creation; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY recompenses_familiales_creation ON public.recompenses_familiales FOR INSERT TO authenticated WITH CHECK ((public.peut_valider(enfant_id) AND (proposee_par = auth.uid())));


--
-- Name: recompenses_familiales recompenses_familiales_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY recompenses_familiales_lecture ON public.recompenses_familiales FOR SELECT TO authenticated USING (public.est_intervenant(enfant_id));


--
-- Name: recompenses_familiales recompenses_familiales_maj; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY recompenses_familiales_maj ON public.recompenses_familiales FOR UPDATE TO authenticated USING (public.peut_valider(enfant_id)) WITH CHECK (public.peut_valider(enfant_id));


--
-- Name: recompenses recompenses_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY recompenses_lecture ON public.recompenses FOR SELECT TO authenticated USING (public.est_intervenant(public.enfant_du_projet_moteur(projet_moteur_id)));


--
-- Name: recompenses recompenses_lecture_enfant; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY recompenses_lecture_enfant ON public.recompenses FOR SELECT TO authenticated USING (public.est_l_enfant(public.enfant_du_projet_moteur(projet_moteur_id)));


--
-- Name: recompenses_obtenues; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.recompenses_obtenues ENABLE ROW LEVEL SECURITY;

--
-- Name: recompenses_obtenues recompenses_obtenues_achat_enfant; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY recompenses_obtenues_achat_enfant ON public.recompenses_obtenues FOR INSERT TO authenticated WITH CHECK ((public.est_l_enfant(enfant_id) AND (offerte = false)));


--
-- Name: recompenses_obtenues recompenses_obtenues_acquisition; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY recompenses_obtenues_acquisition ON public.recompenses_obtenues FOR INSERT TO authenticated WITH CHECK ((public.peut_valider(enfant_id) AND ((offerte = false) OR (offerte_par = auth.uid()))));


--
-- Name: recompenses_obtenues recompenses_obtenues_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY recompenses_obtenues_lecture ON public.recompenses_obtenues FOR SELECT TO authenticated USING (public.est_intervenant(enfant_id));


--
-- Name: recompenses_obtenues recompenses_obtenues_lecture_enfant; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY recompenses_obtenues_lecture_enfant ON public.recompenses_obtenues FOR SELECT TO authenticated USING (public.est_l_enfant(enfant_id));


--
-- Name: recompenses_reports; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.recompenses_reports ENABLE ROW LEVEL SECURITY;

--
-- Name: recompenses_reports recompenses_reports_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY recompenses_reports_lecture ON public.recompenses_reports FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.recompenses_familiales r
  WHERE ((r.id = recompenses_reports.recompense_id) AND (public.est_intervenant(r.enfant_id) OR (public.est_l_enfant(r.enfant_id) AND ((r.devoilee_le IS NOT NULL) OR r.montrer_date)))))));


--
-- Name: reperes_competences; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.reperes_competences ENABLE ROW LEVEL SECURITY;

--
-- Name: reperes_competences reperes_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reperes_lecture ON public.reperes_competences FOR SELECT TO authenticated USING (true);


--
-- Name: observations_reponses reponses_ecriture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reponses_ecriture ON public.observations_reponses TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.observations_capacites o
  WHERE ((o.id = observations_reponses.observation_id) AND (o.rempli_par = auth.uid()))))) WITH CHECK ((EXISTS ( SELECT 1
   FROM public.observations_capacites o
  WHERE ((o.id = observations_reponses.observation_id) AND (o.rempli_par = auth.uid())))));


--
-- Name: observations_reponses reponses_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reponses_lecture ON public.observations_reponses FOR SELECT TO authenticated USING ((EXISTS ( SELECT 1
   FROM public.observations_capacites o
  WHERE ((o.id = observations_reponses.observation_id) AND public.est_intervenant(o.enfant_id)))));


--
-- Name: supports; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.supports ENABLE ROW LEVEL SECURITY;

--
-- Name: supports supports_depot; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY supports_depot ON public.supports FOR INSERT TO authenticated WITH CHECK ((public.est_intervenant(enfant_id) AND (depose_par = auth.uid()) AND public.matiere_ouverte_a_l_ecriture(enfant_id, matiere_code)));


--
-- Name: supports supports_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY supports_lecture ON public.supports FOR SELECT TO authenticated USING (public.est_intervenant(enfant_id));


--
-- Name: supports supports_maj; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY supports_maj ON public.supports FOR UPDATE TO authenticated USING ((public.peut_valider(enfant_id) OR (depose_par = auth.uid()))) WITH CHECK (((public.peut_valider(enfant_id) OR (depose_par = auth.uid())) AND public.matiere_ouverte_a_l_ecriture(enfant_id, matiere_code)));


--
-- Name: supports supports_suppression; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY supports_suppression ON public.supports FOR DELETE TO authenticated USING ((public.peut_valider(enfant_id) OR (depose_par = auth.uid())));


--
-- Name: suppressions_accords; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.suppressions_accords ENABLE ROW LEVEL SECURITY;

--
-- Name: suppressions_accords suppressions_accords_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY suppressions_accords_lecture ON public.suppressions_accords FOR SELECT TO authenticated USING ((public.est_admin() OR (EXISTS ( SELECT 1
   FROM public.demandes_suppression d
  WHERE ((d.id = suppressions_accords.demande_id) AND (d.enfant_id IS NOT NULL) AND public.est_intervenant(d.enfant_id))))));


--
-- Name: suppressions_effectuees; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.suppressions_effectuees ENABLE ROW LEVEL SECURITY;

--
-- Name: suppressions_effectuees suppressions_effectuees_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY suppressions_effectuees_lecture ON public.suppressions_effectuees FOR SELECT TO authenticated USING (public.est_admin());


--
-- Name: demandes_suppression suppressions_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY suppressions_lecture ON public.demandes_suppression FOR SELECT TO authenticated USING ((public.est_admin() OR ((enfant_id IS NOT NULL) AND public.est_intervenant(enfant_id))));


--
-- Name: tentatives; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.tentatives ENABLE ROW LEVEL SECURITY;

--
-- Name: tentatives tentatives_acces; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tentatives_acces ON public.tentatives TO authenticated USING (public.peut_valider(enfant_id)) WITH CHECK (public.peut_valider(enfant_id));


--
-- Name: tentatives tentatives_ecriture_enfant; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tentatives_ecriture_enfant ON public.tentatives FOR INSERT TO authenticated WITH CHECK (public.est_l_enfant(enfant_id));


--
-- Name: tentatives tentatives_lecture_enfant; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tentatives_lecture_enfant ON public.tentatives FOR SELECT TO authenticated USING (public.est_l_enfant(enfant_id));


--
-- Name: tentatives tentatives_lecture_enseignant; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tentatives_lecture_enseignant ON public.tentatives FOR SELECT TO authenticated USING (public.exercice_relevant_de_l_enseignant(exercice_id));


--
-- Name: tentatives tentatives_lecture_litige; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tentatives_lecture_litige ON public.tentatives FOR SELECT TO authenticated USING (public.acces_exceptionnel_actif(enfant_id));


--
-- Name: tentatives tentatives_lecture_pilote; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY tentatives_lecture_pilote ON public.tentatives FOR SELECT TO authenticated USING (public.exercice_sous_objectif_pilote(exercice_id));


--
-- Name: textes_consentement; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.textes_consentement ENABLE ROW LEVEL SECURITY;

--
-- Name: textes_consentement textes_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY textes_lecture ON public.textes_consentement FOR SELECT TO authenticated USING (true);


--
-- Name: textes_consentement textes_publication; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY textes_publication ON public.textes_consentement FOR INSERT TO authenticated WITH CHECK (public.est_admin());


--
-- Name: textes_consentement textes_retrait; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY textes_retrait ON public.textes_consentement FOR UPDATE TO authenticated USING (public.est_admin());


--
-- Name: versions_programme; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.versions_programme ENABLE ROW LEVEL SECURITY;

--
-- Name: versions_programme versions_programme_administration; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY versions_programme_administration ON public.versions_programme TO authenticated USING (public.est_admin()) WITH CHECK (public.est_admin());


--
-- Name: versions_programme versions_programme_lecture; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY versions_programme_lecture ON public.versions_programme FOR SELECT TO authenticated USING (true);


--
-- PostgreSQL database dump complete
--


