-- 0011 — Un enseignant sans matière n'existe pas.
--
-- 0001 laissait `matiere_code` libre pour tous les rôles. C'était une erreur de
-- modélisation : un rattachement d'enseignant sans matière est un rattachement
-- incomplet, et la politique d'écriture de 0009 n'a alors aucun périmètre à
-- appliquer. Plutôt que de décider au cas par cas ce qu'un tel profil a le droit
-- de faire, on l'interdit à la création.
--
-- Le rattachement et l'invitation portent la même règle : l'invitation précède
-- le rattachement, et laisser passer une invitation d'enseignant sans matière
-- reviendrait à créer le profil incomplet un cran plus tard, au moment où la
-- personne accepte — c'est-à-dire au pire moment pour lui expliquer pourquoi.

alter table intervenants_enfant
  add constraint enseignant_a_une_matiere
  check (role <> 'enseignant' or matiere_code is not null);

alter table invitations
  add constraint invitation_enseignant_a_une_matiere
  check (role <> 'enseignant' or matiere_code is not null);

-- `matiere_code` n'a jamais eu de clé étrangère vers `matieres` : impossible en
-- 0001, où la table des matières n'existait pas encore. Maintenant qu'elle
-- existe, une faute de frappe — « math » pour « maths » — cantonnerait
-- silencieusement un enseignant à une matière fantôme, sans erreur ni ligne
-- visible nulle part. C'est exactement le genre de panne qu'on met des semaines
-- à imputer au bon endroit.
alter table intervenants_enfant
  add constraint intervenants_matiere_connue
  foreign key (matiere_code) references matieres on delete restrict;

alter table invitations
  add constraint invitations_matiere_connue
  foreign key (matiere_code) references matieres on delete restrict;
