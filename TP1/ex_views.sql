-- ============================================================================
-- TP : LES VUES (VIEWS) DANS POSTGRESQL
-- ============================================================================

-- 🎯 Objectif :
-- Apprendre à créer, interroger, mettre à jour et supprimer des VIEWS.
-- Découvrir les vues matérialisées et leur différence avec les vues classiques.
-- ============================================================================


-- ============================================================================
-- 1. CRÉATION DE LA BASE ET DES TABLES
-- ============================================================================

CREATE DATABASE tp_views;
\c tp_views

-- Table des clients
CREATE TABLE client (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(50),
    ville VARCHAR(50)
);

-- Table des commandes
CREATE TABLE commande (
    id SERIAL PRIMARY KEY,
    client_id INT REFERENCES client(id),
    date_commande DATE,
    montant NUMERIC(10,2)
);

-- Remplissage des tables
INSERT INTO client (nom, ville) VALUES
('Ali', 'Casablanca'),
('Sara', 'Rabat'),
('Youssef', 'Fès'),
('Nadia', 'Marrakech');

INSERT INTO commande (client_id, date_commande, montant) VALUES
(1, '2024-01-10', 250.50),
(2, '2024-02-12', 900.00),
(1, '2024-03-05', 120.75),
(3, '2024-03-20', 300.00),
(4, '2024-03-22', 150.00),
(2, '2024-04-02', 220.40);


-- ============================================================================
-- 2. VUE SIMPLE
-- ============================================================================

-- Création d'une vue affichant toutes les commandes avec le nom du client
CREATE VIEW vue_commandes AS
SELECT 
    c.id AS commande_id,
    cl.nom AS client,
    cl.ville,
    c.date_commande,
    c.montant
FROM commande c
JOIN client cl ON c.client_id = cl.id;

-- Afficher le contenu de la vue
SELECT * FROM vue_commandes;

-- 🔍 La vue est une "table virtuelle" qui exécute cette requête à chaque appel.


-- ============================================================================
-- 3. UTILISATION DE LA VUE
-- ============================================================================

-- Sélection des commandes de Casablanca uniquement
SELECT * FROM vue_commandes WHERE ville = 'Casablanca';

-- Calcul du total des ventes par ville
SELECT ville, SUM(montant) AS total_ventes
FROM vue_commandes
GROUP BY ville;


-- ============================================================================
-- 4. VUE AVEC AGRÉGATION
-- ============================================================================

-- Vue donnant le total des ventes par client
CREATE VIEW vue_ventes_clients AS
SELECT 
    cl.nom AS client,
    SUM(c.montant) AS total_ventes,
    COUNT(c.id) AS nb_commandes
FROM commande c
JOIN client cl ON c.client_id = cl.id
GROUP BY cl.nom;

-- Consulter la vue
SELECT * FROM vue_ventes_clients
ORDER BY total_ventes DESC;


-- ============================================================================
-- 5. MISE À JOUR VIA UNE VUE (simple)
-- ============================================================================

-- Exemple : vue directe sur la table client
CREATE VIEW vue_clients AS
SELECT * FROM client;

-- Modifier la ville d’un client via la vue
UPDATE vue_clients
SET ville = 'Tanger'
WHERE nom = 'Youssef';

-- Vérifier la mise à jour dans la table d’origine
SELECT * FROM client;


-- ============================================================================
-- 6. VUE MATÉRIALISÉE
-- ============================================================================

-- Vue matérialisée (les résultats sont stockés physiquement)
CREATE MATERIALIZED VIEW vue_stats AS
SELECT ville, SUM(montant) AS total_ventes
FROM vue_commandes
GROUP BY ville;

-- Consulter la vue matérialisée
SELECT * FROM vue_stats;

-- ⚠️ Si on ajoute une nouvelle commande, cette vue ne se met pas à jour automatiquement
INSERT INTO commande (client_id, date_commande, montant)
VALUES (1, '2024-05-01', 100.00);

-- La vue n’a pas changé
SELECT * FROM vue_stats;

-- Rafraîchir la vue matérialisée
REFRESH MATERIALIZED VIEW vue_stats;

-- Re-vérifier
SELECT * FROM vue_stats;


-- ============================================================================
-- 7. MODIFICATION ET SUPPRESSION DE VUES
-- ============================================================================

-- Modifier une vue (remplacer son contenu)
CREATE OR REPLACE VIEW vue_ventes_clients AS
SELECT 
    cl.nom AS client,
    COUNT(c.id) AS nb_commandes
FROM commande c
JOIN client cl ON c.client_id = cl.id
GROUP BY cl.nom;

-- Supprimer une vue
DROP VIEW IF EXISTS vue_clients;
DROP MATERIALIZED VIEW IF EXISTS vue_stats;


-- ============================================================================
-- 8. QUESTIONS À RÉPONDRE
-- ============================================================================

-- 1️⃣ Quelle est la différence entre une vue classique et une vue matérialisée ?
-- 2️⃣ Les vues stockent-elles physiquement les données ?
-- 3️⃣ Quand faut-il rafraîchir une vue matérialisée ?
-- 4️⃣ Peut-on modifier les données à travers une vue ?
-- 5️⃣ Quelle est l’utilité principale des vues dans une base de données ?


-- ============================================================================
-- FIN DU TP 🎉
-- ============================================================================
