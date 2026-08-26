-- 0012 — Un objectif ne tient pas dans un trimestre.
--
-- 0005 rangeait chaque objectif dans un trimestre obligatoire, calqué sur le
-- calendrier de l'école. C'est le mauvais découpage pour cet enfant-là : un
-- objectif d'écriture peut demander six semaines ou toute l'année, et le forcer
-- dans une case trimestrielle obligerait à le clore artificiellement en décembre
-- pour le rouvrir en janvier — en donnant à l'enfant deux fois le sentiment de
-- recommencer ce qu'il avait déjà entamé.
--
-- La période devient donc libre : une date de début, et une échéance seulement
-- si quelqu'un a une raison d'en fixer une.

alter table objectifs alter column trimestre drop default;
alter table objectifs alter column trimestre drop not null;

-- `trimestre` survit, facultatif : le bilan trimestriel (0007) reste rendu à
-- l'école selon son calendrier à elle, et savoir qu'un objectif visait
-- explicitement le deuxième trimestre garde du sens quand c'est le cas.
comment on column objectifs.trimestre is
  'Facultatif. Renseigné quand l''objectif vise explicitement un trimestre scolaire.';

alter table objectifs
  add column debute_le date not null default current_date,
  add column echeance_le date;

alter table objectifs
  add constraint objectif_periode_coherente
  check (echeance_le is null or echeance_le >= debute_le);

-- Les objectifs en cours, du plus proche de son échéance au plus lointain, ceux
-- sans échéance en dernier. C'est l'ordre dans lequel on les présente.
create index objectifs_periode_idx
  on objectifs (enfant_id, echeance_le nulls last)
  where statut in ('propose', 'valide');

-- L'ancien index rangeait par trimestre, colonne désormais souvent nulle.
drop index if exists objectifs_enfant_idx;
create index objectifs_enfant_idx on objectifs (enfant_id, debute_le desc);
