-- ============================================================================
-- TP COMPLET : Transactions dans PostgreSQL
-- Base utilisée : testdb
-- Fichier unique avec commentaires détaillés
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Se connecter à la base testdb (exécuté dans psql, non dans ce fichier)
-- \c testdb
-- ---------------------------------------------------------------------------


-- ============================================================================
-- 2) Création des tables
-- ============================================================================

-- Table des clients
CREATE TABLE IF NOT EXISTS clients (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(50),
    balance NUMERIC(12,2) DEFAULT 0
);

-- Table des opérations (historique)
CREATE TABLE IF NOT EXISTS operations (
    id SERIAL PRIMARY KEY,
    client_id INT REFERENCES clients(id),
    montant NUMERIC(12,2),
    type VARCHAR(20),
    date_op TIMESTAMP DEFAULT NOW()
);


-- ============================================================================
-- 3) Insertion des données initiales
-- ============================================================================

INSERT INTO clients (nom, balance) VALUES
('Ali', 1000),
('Sara', 2000),
('Youssef', 500);


-- ============================================================================
-- 4) Exercice 1 : Transaction simple
-- Objectif : virement de 300 DH de Ali (id=1) vers Sara (id=2)
-- Tout doit réussir sinon tout est annulé.
-- ============================================================================

BEGIN;

UPDATE clients SET balance = balance - 300 WHERE id = 1;
UPDATE clients SET balance = balance + 300 WHERE id = 2;

COMMIT;

--✅ Exemple pour vérifier (check) résultat 

SELECT id, nom, balance FROM clients WHERE id IN (1, 2);

-- Fin Exercice 1


-- ============================================================================
-- 5) Exercice 2 : ROLLBACK en cas d'erreur
-- Objectif : tenter un virement de 1000 DH de Youssef (id=3) 
-- vers Ali (id=1) → Mais il n'a que 500 DH. On annule tout.
-- ============================================================================

BEGIN;

-- Vérification manuelle du solde (facultatif)
SELECT balance FROM clients WHERE id = 3;

-- Cette opération est "logiquement incorrecte"
UPDATE clients SET balance = balance - 1000 WHERE id = 3;

-- On décide d'annuler (ROLLBACK manuel)
ROLLBACK;
-- Fin Exercice 2


-- ============================================================================
-- 6) Exercice 3 : SAVEPOINT
-- Objectif :
--  - Ajouter une opération correcte
--  - Tenter une opération incorrecte (client inexistant)
--  - Annuler uniquement la partie erronée
-- ============================================================================

BEGIN;

-- 1) Opération correcte
INSERT INTO operations (client_id, montant, type)
VALUES (1, 200, 'deposit');

-- Création du SAVEPOINT
SAVEPOINT sp1;

-- 2) Opération incorrecte → client_id = 9999 n'existe pas
INSERT INTO operations (client_id, montant, type)
VALUES (9999, 500, 'withdraw');  -- ERREUR volontaire

-- 3) On annule uniquement l'instruction fautive
ROLLBACK TO sp1;

-- 4) La première opération reste valide
COMMIT;
-- Fin Exercice 3


-- ============================================================================
-- 7) Exercice 4 : Isolation Level
-- Note :
-- Ce test doit être fait dans 2 sessions différentes de psql.
-- Ici nous ne mettons que les commandes.
-- ============================================================================

-- Session A :
-- BEGIN;
-- SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- SELECT * FROM clients WHERE id = 1;

-- Session B :
-- UPDATE clients SET balance = balance + 100 WHERE id = 1;

-- Retour dans Session A :
-- SELECT * FROM clients WHERE id = 1;   -- Même résultat qu’au début
-- COMMIT;


-- ============================================================================
-- 8) Exercice 5 : Erreur → ROLLBACK automatique
-- Objectif : provoquer une erreur SQL pour voir comment PostgreSQL gère 
-- automatiquement la transaction.
-- ============================================================================

BEGIN;

-- montant ne doit pas être NULL
INSERT INTO operations (client_id, montant, type)
VALUES (1, NULL, 'deposit');  -- Cela génère ERROR

-- PostgreSQL va automatiquement mettre la transaction en état "aborted"
-- Toute tentative de COMMIT échouera :
-- COMMIT;  -- donnera: "no transaction in progress"

-- Fin Exercice 5


-- ============================================================================
-- FIN DU TP
-- ============================================================================
SELECT rolname FROM pg_roles;


SELECT rolname 
FROM pg_roles
WHERE rolname NOT LIKE 'pg_%';
---------------------------------------------------------------------------

SELECT * FROM clients WHERE id = 1;
BEGIN;

-- تحديث بيانات العميل
UPDATE clients SET balance = balance + 500 WHERE id = 1;
------------------------------------------------------




