-- 0066 — Deux corrections sur les autorisations.
--
-- 1. Le référent ne signe pas. 0037 l'admettait à la signature au même titre
--    qu'un titulaire de l'autorité parentale. C'était une erreur : le
--    consentement au traitement des données d'un enfant appartient à ceux qui
--    en détiennent l'autorité, et à personne d'autre. Un référent de bonne foi
--    qui signe « pour débloquer le dossier » produit un consentement sans
--    valeur, et le produit sans savoir qu'il le fait.
--
-- 2. Les quatre textes deviennent indispensables. Deux étaient facultatifs, au
--    motif qu'« un parent doit pouvoir dire non à la génération par l'IA sans
--    renoncer au suivi ». Le motif ne tient pas à l'usage : sans partage avec
--    l'équipe, aucun enseignant ne voit le dossier ; sans génération, il n'y a
--    plus d'adaptation des exercices. Ce qui restait n'était pas un outil
--    dégradé, c'était une coquille.
--
-- ---------------------------------------------------------------------------
-- CE QUE LE POINT 2 COÛTE, ET QU'IL FAUT DIRE
--
-- Un consentement RGPD doit être libre. Le rendre indispensable au service
-- affaiblit précisément ce caractère : si le refus n'ouvre sur rien, l'accord
-- n'est plus vraiment un choix.
--
-- La réponse probable est que le partage avec l'équipe et le recours à l'IA ne
-- relèvent pas du consentement mais de l'exécution du service — on ne demande
-- pas son consentement à ce qui définit l'outil, on le décrit dans les CGU. Ce
-- qui relève réellement du consentement, ce sont les données de santé.
--
-- Cette migration fait ce qui est demandé et le fait proprement ; la question
-- de la base légale est portée en 1.8 de docs/questions-juriste.md.
-- ---------------------------------------------------------------------------

-- =================================================== 1. qui signe

-- La liste proposée. Un référent n'y a plus rien à signer — il continue de voir
-- où en est le dossier par `etat_des_consentements()`, qui reste ouverte aux
-- deux rôles : diagnostiquer un dossier muet fait partie de son travail.
create or replace function consentements_a_signer(p_enfant uuid)
returns table (
  texte_id uuid,
  type type_consentement,
  version text,
  titre text,
  contenu text,
  obligatoire boolean
)
language sql stable security definer set search_path = public as $$
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

-- La signature elle-même. C'est ici que la règle compte : masquer le formulaire
-- dans l'interface ne suffit pas, une requête directe passerait encore.
create or replace function signer_les_consentements(
  p_enfant uuid,
  p_types type_consentement[],
  p_signature text,
  p_refuses type_consentement[] default '{}',
  p_ip inet default null,
  p_agent text default ''
)
returns integer
language plpgsql security definer set search_path = public as $$
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

-- Les signatures déjà recueillies auprès de qui n'est pas titulaire sont
-- révoquées. Elles ne comptaient pas dans le quorum — `consentement_actif()`
-- n'interroge que les parents — mais elles s'affichaient dans le décompte des
-- signatures, où elles donnaient à croire qu'une autorisation avait progressé.
update consentements c
set revoque_le = now()
where c.revoque_le is null
  and not exists (
    select 1 from intervenants_enfant i
    where i.enfant_id = c.enfant_id
      and i.profil_id = c.profil_id
      and i.role = 'parent'
      and i.retire_le is null
  );

-- =================================================== 2. plus rien de facultatif

-- `obligatoire` est figé après publication par le trigger de 0037, et c'est
-- voulu : on ne change pas la portée d'un texte sous la signature de quelqu'un.
-- La voie normale est donc celle-ci — retirer, republier. Les signatures de la
-- v1 restent attachées à ce que les gens ont lu, et la v2 leur est présentée.
--
-- Le dossier ne s'éteint pas dans l'intervalle : `consentement_actif()` se
-- prononce par type, pas par version. Une famille servie ne perd pas son outil
-- parce qu'un texte a été reformulé — elle est invitée à resigner.

update textes_consentement
set retire_le = now()
where retire_le is null
  and type in ('partage_equipe_pedagogique', 'generation_ia')
  and not obligatoire;

insert into textes_consentement (type, version, titre, contenu, obligatoire) values
(
  'partage_equipe_pedagogique', 'v2-travail',
  'Ce que voit l''équipe qui accompagne votre enfant',
  'Les enseignants et les accompagnants rattachés au dossier voient ce qui leur permet d''accompagner votre enfant : ses objectifs, sa progression, les travaux proposés, et le suivi quotidien.

Un enseignant ne voit que sa propre matière pour ce qu''il écrit, et les copies des seuls travaux dont il est à l''origine. Il ne voit ni les informations de santé, ni vos échanges privés, ni les conversations auxquelles il n''est pas convié.

Cette autorisation est nécessaire au fonctionnement de Xylou : sans elle, aucun enseignant ni accompagnant n''accède au dossier, et l''outil n''a plus d''objet. Vous pouvez la retirer à tout moment ; le dossier cesse alors d''être accessible à l''équipe, et vous pouvez en demander la suppression.',
  true
),
(
  'generation_ia', 'v2-travail',
  'Le recours à l''intelligence artificielle',
  'Xylou utilise un modèle d''intelligence artificielle pour transformer les exercices scolaires en missions adaptées aux centres d''intérêt de votre enfant, et pour proposer des contenus à partir des objectifs fixés par l''équipe.

Aucune proposition de l''IA n''atteint votre enfant sans qu''un adulte l''ait validée.

Le contenu des demandes envoyées au modèle n''est pas conservé : nous enregistrons seulement leur volume et leur coût, afin de suivre le budget et de détecter une baisse de qualité. Le prestataire du modèle est un sous-traitant, lié par contrat.

Cette autorisation est nécessaire au fonctionnement de Xylou : l''adaptation des contenus est ce que l''outil fait. Vous pouvez la retirer à tout moment ; la génération s''arrête alors, et le dossier ne conserve que ce qui a déjà été produit et validé.',
  true
)
on conflict (type, version) do nothing;
