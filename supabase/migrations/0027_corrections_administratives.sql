-- 0027 — Ce que l'administration peut corriger.
--
-- 0026 a donné à l'administration la qualité d'arbitre, mais seulement dans les
-- triggers. Les politiques RLS, elles, datent de 0009 et ne la connaissent pas :
-- elles refusent l'écriture avant que le trigger ait l'occasion de l'autoriser.
-- Deux conséquences, dont une bloquante :
--
--   `profils_maj` ne laisse modifier que sa propre ligne. Un administrateur ne
--   peut donc promouvoir personne — et la mise en route décrite en 0026, où
--   l'administration crée les comptes référents, est impossible.
--
--   `enfants_maj` demande `peut_valider()` ou d'avoir créé la fiche. Un
--   administrateur qui reprend un dossier ouvert par un référent parti ne peut
--   pas corriger la composition parentale, alors même que le trigger de 0025
--   l'y autorise.
--
-- Ce fichier ouvre donc les trois tables administratives, et seulement
-- celles-là. Le principe posé en 0026 tient : administrer n'est pas accompagner.
-- `est_admin()` n'apparaît toujours dans aucune politique sur les objectifs, les
-- tentatives, les échanges, les notations ou `enfants_sante`. Un administrateur
-- corrige des rattachements et des qualités ; il ne lit pas le dossier.

-- ------------------------------------------------------------------ profils

drop policy profils_maj on profils;

create policy profils_maj on profils for update to authenticated
  using (id = auth.uid() or est_admin())
  with check (id = auth.uid() or est_admin());

-- Le trigger de 0026 continue de tenir la colonne sensible : `role_plateforme`
-- ne bouge que sous la main d'un administrateur, y compris sur sa propre ligne.
-- La politique élargit qui peut écrire, elle ne change pas ce qui est protégé.

-- ------------------------------------------------------------------ enfants

drop policy enfants_maj on enfants;

create policy enfants_maj on enfants for update to authenticated
  using (peut_valider(id) or cree_par = auth.uid() or est_admin())
  with check (peut_valider(id) or cree_par = auth.uid() or est_admin());

-- -------------------------------------------------------------- invitations

-- Annuler une invitation partie à la mauvaise adresse est une correction
-- ordinaire, et le référent qui l'a émise n'est pas toujours joignable.
drop policy invitations_maj on invitations;

create policy invitations_maj on invitations for update to authenticated
  using (peut_valider(enfant_id) or lower(email) = email_courant() or est_admin())
  with check (peut_valider(enfant_id) or lower(email) = email_courant() or est_admin());

-- ================================================== trace des corrections

-- Un pouvoir de correction qui ne laisse pas de trace est un pouvoir dont
-- personne ne peut rendre compte. `journal_acces` existe depuis 0008 pour les
-- obligations du §3.4 ; il est le bon endroit.
--
-- On n'y consigne que les interventions administratives sur le dossier d'un
-- enfant : celles d'un parent ou d'un référent sur leur propre dossier sont
-- l'usage normal, les tracer noierait le signal. Ce qu'on veut pouvoir relire un
-- an plus tard, c'est « qui, extérieur au suivi, a touché à quoi ».
-- Trigger AFTER : la valeur de retour est ignorée, d'où le `null` final. Et
-- `new` n'existe pas pendant un DELETE — y accéder, même sous coalesce, lève
-- « record new is not assigned yet ». D'où le branchement explicite sur TG_OP
-- plutôt qu'une expression qui aurait l'air de gérer les deux cas.
create or replace function tracer_la_correction_administrative()
returns trigger language plpgsql security definer set search_path = public as $$
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

create trigger enfants_tracent_les_corrections
  after update on enfants
  for each row execute function tracer_la_correction_administrative();

create trigger intervenants_tracent_les_corrections
  after insert or update or delete on intervenants_enfant
  for each row execute function tracer_la_correction_administrative();

-- L'administration lit ce qu'elle a écrit : sans cela, la trace ne servirait
-- qu'à la famille, et un administrateur ne pourrait pas vérifier son propre
-- travail. Elle ne voit que les lignes d'intervention administrative — le reste
-- du journal, qui porte les accès au dossier, lui reste fermé.
create policy journal_acces_lecture_admin on journal_acces for select to authenticated
  using (est_admin() and action = 'correction_administrative');
