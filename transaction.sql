/**
 * Fichier : transaction_pagila.sql
 * Base de données : Pagila (PostgreSQL)
 * Description : Démonstration des transactions (COMMIT et ROLLBACK)
 * en ajustant le coût de remplacement (replacement_cost) de films.
 */

-------------------------------------------------------------------------------
-- 1. PRÉPARATION ET ÉTAT INITIAL
-------------------------------------------------------------------------------

-- Désactive le mode autocommit si vous utilisez un client qui l'active par défaut.
-- En psql, le mode est manuel par défaut.
-- SET autocommit = OFF;

-- IDs des films utilisés (supposons 1 et 5 pour les exemples courants)
-- NOTE : Ces IDs sont généralement stables dans Pagila.
-- Film 1 : 'ACADEMY DINOSAUR'
-- Film 5 : 'ADIEU GENERAL'

-- Affichage des coûts initiaux de remplacement pour les films 1 et 5
SELECT 
    '--- 1. ÉTAT INITIAL DES COÛTS ---' AS Etape,
    film_id, 
    title, 
    replacement_cost
FROM 
    film
WHERE 
    film_id IN (1, 5);

-------------------------------------------------------------------------------
-- 2. SCÉNARIO 1 : AJUSTEMENT RÉUSSI (COMMIT)
-------------------------------------------------------------------------------

-- Objectif : Augmenter le coût du Film 1 de 1.00.

-- DÉBUT DE LA TRANSACTION :
BEGIN; 

-- 2.1. Augmentation du coût pour 'ACADEMY DINOSAUR' (Film 1)
-- Par exemple, si le coût initial est 20.99, il passera à 21.99.
UPDATE film
SET replacement_cost = replacement_cost + 1.00
WHERE film_id = 1;

-- Vérification de l'état interne (Film 1 a changé)
SELECT '--- T1 INTERNE (AVANT COMMIT) ---' AS Etape, film_id, title, replacement_cost FROM film WHERE film_id IN (1, 5); 

-- COMMIT : Validation de l'ajustement. Le changement est permanent.
COMMIT;

-- Vérification de l'état final après COMMIT
SELECT '--- 2. ÉTAT APRÈS COMMIT (Film 1 modifié) ---' AS Etape, film_id, title, replacement_cost FROM film WHERE film_id IN (1, 5);

-------------------------------------------------------------------------------
-- 3. SCÉNARIO 2 : AJUSTEMENT ÉCHOUÉ (ROLLBACK)
-------------------------------------------------------------------------------

-- Objectif : Augmenter le coût du Film 5, puis simuler une erreur, et annuler.

-- DÉBUT DE LA TRANSACTION :
BEGIN;

-- 3.1. Augmentation du coût pour 'ADIEU GENERAL' (Film 5)
-- Par exemple, si le coût initial est 20.99, il passera à 21.99 dans cette transaction.
UPDATE film
SET replacement_cost = replacement_cost + 1.00
WHERE film_id = 5;

-- Vérification de l'état interne (Le coût du Film 5 a augmenté)
SELECT '--- T2 INTERNE (AVANT ROLLBACK) ---' AS Etape, film_id, title, replacement_cost FROM film WHERE film_id IN (1, 5); 

-- 3.2. Simulation d'une erreur critique :
-- Tentons de mettre un coût négatif (ce qui devrait provoquer une erreur
-- si une contrainte CHECK existe, mais pour la démo, nous simulons l'échec).
-- Dans ce TP, nous faisons un ROLLBACK manuel pour simuler l'échec d'une étape suivante.

-- Le système s'arrête ici car une autre opération a échoué (simulée).

-- ROLLBACK : Annuler TOUS les changements depuis le BEGIN.
-- L'augmentation du coût du Film 5 est annulée.
ROLLBACK;

-- Vérification de l'état final après ROLLBACK
SELECT '--- 3. ÉTAT APRÈS ROLLBACK (Film 5 non modifié) ---' AS Etape, film_id, title, replacement_cost FROM film WHERE film_id IN (1, 5);

-- NOTE : Après le ROLLBACK, le coût de 'ADIEU GENERAL' est revenu à la valeur 
-- qu'il avait avant le BEGIN de la Transaction 2.

-------------------------------------------------------------------------------
-- FIN DU TP
-------------------------------------------------------------------------------