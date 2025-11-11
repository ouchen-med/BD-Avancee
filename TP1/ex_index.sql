-- ============================================================================
-- TP : OPTIMISATION DE REQUÊTES AVEC INDEX DANS POSTGRESQL
-- ============================================================================

-- 🎯 Objectif :
-- Apprendre à utiliser les INDEX (B-tree, fonctionnels, composites)
-- et à analyser les performances des requêtes avec EXPLAIN ANALYZE.
-- ============================================================================


-- ============================================================================
-- 1. CRÉATION DE LA BASE ET DE LA TABLE
-- ============================================================================

CREATE DATABASE tp_index;
\c tp_index

-- Création d'une table "produit"
CREATE TABLE produit (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(100),
    categorie VARCHAR(50),
    prix NUMERIC(8,2),
    stock INT
);

-- Remplissage de la table avec 100 000 lignes factices
INSERT INTO produit (nom, categorie, prix, stock)
SELECT 
    'Produit ' || i,
    CASE 
        WHEN i % 5 = 0 THEN 'Alimentaire'
        WHEN i % 5 = 1 THEN 'Electronique'
        WHEN i % 5 = 2 THEN 'Vêtements'
        WHEN i % 5 = 3 THEN 'Bricolage'
        ELSE 'Beauté'
    END,
    ROUND(random() * 500 + 10, 2),
    (random() * 100)::INT
FROM generate_series(1, 100000) AS i;


-- ============================================================================
-- 2. OBSERVATION SANS INDEX
-- ============================================================================

-- Requête de test
EXPLAIN ANALYZE
SELECT * FROM produit WHERE categorie = 'Electronique';

-- 🔍 Observer :
-- - Type de scan → "Seq Scan" (parcours séquentiel de toute la table)
-- - Temps d’exécution total (coût élevé sur grande table)


-- ============================================================================
-- 3. CRÉATION D’UN INDEX SIMPLE
-- ============================================================================

CREATE INDEX idx_produit_categorie ON produit(categorie);

-- Refaire la même requête
EXPLAIN ANALYZE
SELECT * FROM produit WHERE categorie = 'Electronique';

-- 💡 Observation :
-- - Type de scan → "Index Scan"
-- - Temps d’exécution fortement réduit


-- ============================================================================
-- 4. INDEX SUR UNE FONCTION
-- ============================================================================

-- Cas : recherche insensible à la casse
EXPLAIN ANALYZE
SELECT * FROM produit WHERE UPPER(categorie) = 'ELECTRONIQUE';

-- ⚠️ PostgreSQL ne peut pas utiliser idx_produit_categorie ici
-- car la fonction UPPER() modifie la colonne.

-- ✅ Solution : index fonctionnel
CREATE INDEX idx_upper_categorie ON produit(UPPER(categorie));

-- Test
EXPLAIN ANALYZE
SELECT * FROM produit WHERE UPPER(categorie) = 'ELECTRONIQUE';


-- ============================================================================
-- 5. INDEX COMPOSITE
-- ============================================================================

-- Cas : recherche par catégorie ET prix
CREATE INDEX idx_cat_prix ON produit(categorie, prix);

-- Test
EXPLAIN ANALYZE
SELECT * FROM produit 
WHERE categorie = 'Electronique' AND prix > 300;

-- 💡 Comparer le plan d’exécution avant/après création de l’index.


-- ============================================================================
-- 6. INDEX PARTIEL (BONUS)
-- ============================================================================

-- Index uniquement sur les produits disponibles (stock > 0)
CREATE INDEX idx_stock_dispo ON produit(stock) WHERE stock > 0;

-- Test
EXPLAIN ANALYZE
SELECT * FROM produit WHERE stock > 0;


-- ============================================================================
-- 7. QUESTIONS À RÉPONDRE
-- ============================================================================

-- 1️⃣ Quelle est la différence entre Seq Scan et Index Scan ?
-- 2️⃣ Pourquoi PostgreSQL ne peut-il pas utiliser un index pour UPPER(categorie) sans un index fonctionnel ?
-- 3️⃣ Que se passe-t-il sur une petite table (100 lignes) ?
-- 4️⃣ Dans quel ordre placer les colonnes d’un index composite ?
-- 5️⃣ Que montre EXPLAIN ANALYZE exactement ?


-- ============================================================================
-- 8. NETTOYAGE (OPTIONNEL)
-- ============================================================================

DROP INDEX IF EXISTS idx_produit_categorie;
DROP INDEX IF EXISTS idx_upper_categorie;
DROP INDEX IF EXISTS idx_cat_prix;
DROP INDEX IF EXISTS idx_stock_dispo;


-- ============================================================================
-- FIN DU TP 🎉
-- ============================================================================
