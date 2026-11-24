# CV Flutter — Michée KADIMA

Application de portfolio/CV personnel développée avec Flutter. Elle présente
un profil, un parcours, des compétences, des centres d’intérêt, des informations
sur la famille et une page de contact. L’interface utilise des panneaux
translucides, des dégradés et une navigation adaptée aux petits et grands écrans.

## Résumé du profil

Michée KADIMA est étudiant en informatique et développeur en devenir, basé à
Goma, en République démocratique du Congo. Curieux et motivé, il s’intéresse à
la création d’expériences numériques utiles et accessibles.

Le CV présente une formation en informatique, des projets académiques et une
application mobile réalisée avec Flutter. Les compétences mises en avant sont
Flutter, Dart, HTML/CSS, Git, UI/UX et le travail en équipe. Les langues et les
centres d’intérêt sont également présentés dans l’application.

> Certaines informations du parcours sont des exemples ou des champs à
> compléter. Pensez à les adapter avant toute diffusion officielle.

## Fonctionnalités

- Authentification réelle via l’API : inscription et connexion avec email/mot de passe.
- Gestion dynamique des membres de famille : consultation, ajout, modification et suppression via l’API.
- Page **Mon CV** : profil, formation, projets, compétences, langues et intérêts.
- Page **Ma famille** : cartes de présentation des membres de la famille.
- Page **Contact** : actions pour appeler, envoyer un e-mail, copier l’adresse
  et ouvrir les réseaux sociaux.
- Navigation par menu latéral et barre de navigation inférieure.
- Mise en page responsive et composants réutilisables.

### Authentification et API

L’écran de connexion utilise les endpoints `/accounts/login` et
`/accounts/register` de l’API `api-test`. Créez un compte depuis l’application
avant de vous connecter.

Par défaut, l’application utilise `http://localhost/api-test/public`.
Pour Android Emulator, lancez le projet avec :

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2/api-test/public
```

## Technologies

- Flutter et Dart
- Material 3
- [`url_launcher`](https://pub.dev/packages/url_launcher) pour les actions de
  contact
- Tests d’interface avec `flutter_test`

Le dépôt contient les configurations de projet pour Android, iOS, le Web,
Windows, macOS et Linux. La disponibilité réelle de chaque cible dépend des
outils installés sur la machine.

## Prérequis

- Flutter installé et configuré (`flutter doctor`)
- Une version de Dart compatible avec la contrainte du projet (`^3.14.0`)
- Un navigateur ou un appareil/émulateur correspondant à la cible choisie

## Installation et lancement

Depuis la racine du projet :

```bash
flutter pub get
flutter run
```

Pour choisir explicitement une cible :

```bash
flutter devices
flutter run -d chrome
```

## Tests et analyse

```bash
flutter test
flutter analyze
```

Le test d’interface vérifie le formulaire de connexion et la navigation vers les
pages CV, famille et contact.

## Structure du projet

```text
.
├── assets/images/       # Images du profil et de la famille
├── lib/main.dart        # Application et écrans Flutter
├── test/                # Tests d’interface
├── android/             # Configuration Android
├── ios/                 # Configuration iOS
├── linux/               # Configuration Linux
├── macos/               # Configuration macOS
├── web/                 # Configuration Web
├── windows/             # Configuration Windows
├── pubspec.yaml         # Dépendances et ressources Flutter
└── CAPTURES DU TP.zip   # Archive des captures d’écran
```

## Captures d’écran

L’archive complète peut être téléchargée ici :

[Télécharger CAPTURES DU TP.zip](<./CAPTURES DU TP.zip>)

Captures disponibles séparément :

- [Capture 1](<./Screenshot 2026-11-20 090112.png>)
- [Capture 2](<./Screenshot 2026-11-20 090203.png>)
- [Capture 3](<./Screenshot 2026-11-20 090227.png>)
- [Capture 4](<./Screenshot 2026-11-20 090333.png>)
- [Capture 5](<./Screenshot 2026-11-20 090351.png>)

## Démonstration vidéo

<video src="./Screen Recording 2026-11-24 101646.mp4" controls width="720">
  Votre navigateur ne prend pas en charge la lecture vidéo intégrée.
</video>

[Télécharger ou ouvrir la vidéo](<./Screen Recording 2026-11-24 101646.mp4>)

## Personnalisation

Les textes du CV, les coordonnées, les profils familiaux et les liens sociaux
peuvent être adaptés dans `lib/main.dart`. Les ressources et dépendances Flutter
sont déclarées dans `pubspec.yaml`.
