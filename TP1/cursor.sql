SET SERVEROUTPUT ON; -- Nécessaire pour afficher les résultats de DBMS_OUTPUT.PUT_LINE

DECLARE
  -- Déclaration d'un curseur paramétré avec deux paramètres : montant minimum et identifiant du magasin
  CURSOR c_payment (p_amount_min NUMERIC, p_store_id INT) IS
    SELECT
      c.customer_id,
      c.first_name,
      c.last_name,
      p.amount,
      p.payment_date
    FROM
      payment p
    JOIN
      customer c ON p.customer_id = c.customer_id
    WHERE
      p.amount >= p_amount_min
      AND c.store_id = p_store_id
    ORDER BY
      p.payment_date;

  v_count         NUMBER  := 0;    -- Compteur de paiements
  v_total_amount  NUMERIC := 0;    -- Somme des montants affichés

BEGIN
  -- Boucle FOR sur le curseur avec passage des paramètres
  -- Le curseur est exécuté pour les paiements >= 5.00 dans le magasin 1
  FOR rec IN c_payment(5.00, 1) LOOP

    -- Affichage des informations du paiement
    DBMS_OUTPUT.PUT_LINE(
      'Client ID: ' || rec.customer_id ||
      ' - Nom: ' || rec.first_name || ' ' || rec.last_name ||
      ' - Montant: ' || rec.amount ||
      ' - Date: ' || TO_CHAR(rec.payment_date, 'YYYY-MM-DD')
    );

    -- Conditions pour identifier et marquer les paiements importants
    IF rec.amount >= 10 THEN
      DBMS_OUTPUT.PUT_LINE('  → **Paiement élevé** (>= 10)');
    ELSIF rec.amount < 5 THEN
      -- Note : Ce bloc ne s'exécutera pas avec le paramètre 5.00, 
      -- mais est inclus pour la démonstration de la condition ELSE IF.
      DBMS_OUTPUT.PUT_LINE('  → Paiement faible (< 5)'); 
    END IF;

    -- Mise à jour des compteurs
    v_count := v_count + 1;
    v_total_amount := v_total_amount + rec.amount;

  END LOOP;
  
  ---
  
  -- Résumé après la boucle
  DBMS_OUTPUT.PUT_LINE('---');
  IF v_count = 0 THEN
    DBMS_OUTPUT.PUT_LINE('**Aucun paiement** ne correspond aux critères (Montant min: 5.00, Magasin: 1).');
  ELSE
    DBMS_OUTPUT.PUT_LINE('✅ Résumé du traitement :');
    DBMS_OUTPUT.PUT_LINE('  Nombre total de paiements affichés : **' || v_count || '**');
    DBMS_OUTPUT.PUT_LINE('  Montant total cumulé : **' || v_total_amount || '**');
  END IF;

END;
/