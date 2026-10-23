# Torella · Soins naturels

Application de cabinet de naturopathie pour Raffaella Torello : dossiers patients, répertorisation des symptômes, remèdes, recherche du terrain (diathèses de Ménétrier), agenda, devis et factures au format **Tarif 590** avec QR-facture suisse et export PDF.

- **Application** : `index.html`, une seule page, sans étape de build.
- **Données** : Supabase, projet `torella` hébergé à Zurich (`eu-central-2`). Connexion obligatoire ; chaque compte ne voit que ses propres données (Row Level Security).
- **Hébergement** : GitHub Pages, branche `main`, dossier racine.

## Mise en service

1. **GitHub Pages** : Settings › Pages › Source « Deploy from a branch », branche `main`, dossier `/ (root)`.
   L'app est alors servie sur `https://dvd83.github.io/torella/`.
2. **Supabase › Authentication › URL Configuration** :
   - *Site URL* : `https://dvd83.github.io/torella/`
   - *Redirect URLs* : `https://dvd83.github.io/torella/`
   Sans ce réglage, les liens de confirmation et de réinitialisation envoyés par e-mail ne ramènent pas vers l'app.
3. Ouvrir l'app et **créer le compte du cabinet**. Le premier compte créé devient administrateur : c'est lui qui valide les mises à jour du catalogue Tarif 590.
4. Une fois ce compte confirmé, désactiver les nouvelles inscriptions : Authentication › Sign In / Providers › décocher « Allow new users to sign up ».
5. Dans **Gestion › Réglages**, remplacer le RCC (`Z000000`) et l'IBAN d'exemple par les vrais.

## Base de données

Le schéma est dans `supabase/migrations/`.

| Table | Contenu | Accès |
|---|---|---|
| `records` | Patients, rendez-vous, factures, dépenses, remèdes, symptômes ajoutés, réglages du cabinet (un objet JSON par ligne) | Propriétaire uniquement |
| `tarif590` | Catalogue en vigueur (`current`) et proposition annuelle (`pending`) | Lecture : comptes connectés · Écriture : administrateur |
| `app_admins` | Compte administrateur | Lecture de sa propre ligne |

La clé publiée dans `index.html` est la clé *publishable* de Supabase : elle est faite pour être visible côté navigateur, la sécurité repose sur la connexion et les règles RLS.

## Tarif 590

Les positions fournies sont un point de départ (libellés traduits). Elles doivent être vérifiées avec la liste officielle du centre d'enregistrement (RME ou ASCA). Une vérification automatique a lieu chaque 1er décembre et 6 janvier : elle dépose une proposition dans `tarif590` (`pending`), que l'administrateur applique ou écarte depuis l'app.
