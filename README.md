# pkl-shell

[![Build Unix readers](https://github.com/Agence-Fluor/pkl-shell/actions/workflows/build.yml/badge.svg)](https://github.com/Agence-Fluor/pkl-shell/actions/workflows/build.yml)

Une fonction `shell.run("commande")` pour Pkl. Le package versionné contient le module Pkl **et** les readers Unix : il suffit d'avoir Pkl, sans installer Go ni télécharger un second paquet.

## Démarrer

Avec le **CLI Pkl 0.31.1 ou plus récent** et `sh` sur Unix, créez ce `PklProject` à la racine de votre projet :

```pkl
amends "pkl:Project"

dependencies {
  ["shell"] {
    uri = "package://raw.githubusercontent.com/Agence-Fluor/pkl-shell/main/pkg/pkl-shell@0.1.0"
  }
}

evaluatorSettings {
  externalResourceReaders {
    ["shell"] {
      executable = "sh"
      arguments {
        "-ec"
        "reader=.pkl-shell/0.1.0/reader; if [ ! -x \"$reader\" ]; then pkl run @shell/install.pkl >/dev/null; chmod +x \"$reader\"; fi; exec \"$reader\""
      }
    }
  }
}
```

Puis dans `example.pkl` :

```pkl
import "@shell/shell.pkl"

message = shell.run("printf 'Bonjour depuis Pkl'")
```

Depuis la racine du projet :

```sh
pkl project resolve
pkl eval example.pkl
```

Le premier `shell.run` appelle [`install.pkl`](lib/install.pkl) : Pkl lit le binaire adapté à votre plateforme dans le package et l'écrit dans `.pkl-shell/0.1.0/reader`. Le bootstrap lui donne le droit d'exécution et le réutilise ensuite. Ajoutez `.pkl-shell/` à votre `.gitignore`. Le [package `0.1.0`](https://raw.githubusercontent.com/Agence-Fluor/pkl-shell/main/pkg/pkl-shell@0.1.0) sera accessible dès le premier push de ce dépôt sur `main`.

### Pourquoi un bootstrap ?

Pkl garde le ZIP du package dans son cache et lit les modules à l'intérieur. Son réglage [`externalResourceReaders.executable`](https://pkl-lang.org/package-docs/pkl/0.32.1/EvaluatorSettings/ExternalReader.html) demande un chemin ou un programme du `PATH`. Une URL `https://...` y est traitée comme un nom de fichier, et une URI `package:` n'est pas exécutable non plus. Le moyen utilisé ici est `executable = "sh"` : ses arguments lancent [`pkl run`](https://pkl-lang.org/main/current/pkl-cli/index.html#pkl-run), qui extrait le reader du package au premier appel, puis `exec` le démarre. Les [`evaluatorSettings` d'un package ne sont pas publiés ni hérités par ses consommateurs](https://pkl-lang.org/package-docs/pkl/0.32.1/Project/index.html#evaluatorSettings) ; le bloc ci-dessus doit donc figurer dans leur `PklProject`.

## Essayer le dépôt en local

Le [flake Nix](flake.nix) fournit Go et Pkl. Cette commande compile le reader de votre machine et lance l'exemple local :

```sh
git clone https://github.com/Agence-Fluor/pkl-shell.git
cd pkl-shell
nix --extra-experimental-features 'nix-command flakes' develop . --command sh -c 'sh scripts/build-unix.sh --host && cd test && pkl eval --external-resource-reader=shell=../pkl-shell example.pkl'
```

Sortie attendue :

```text
result = "hello"
special = "é # ? % /"
```

Le dossier [`test/`](test/) déclare seulement la dépendance locale ; l'option CLI enregistre le reader pour cette démo. La [CI](https://github.com/Agence-Fluor/pkl-shell/actions/workflows/build.yml) teste aussi le ZIP publié et son installation automatique via un miroir HTTP local.

## Plateformes

| Système | Architectures | Binaire dans le package |
| --- | --- | --- |
| Linux | amd64, arm64 | `bin/pkl-shell-linux-<arch>` |
| macOS | amd64, arm64 | `bin/pkl-shell-darwin-<arch>` |
| FreeBSD | amd64, arm64 | `bin/pkl-shell-freebsd-<arch>` |

Les six binaires sont compilés dans la CI ; le fonctionnement complet est testé sur Linux amd64. La [CI fournit aussi une archive](https://github.com/Agence-Fluor/pkl-shell/actions/workflows/build.yml) avec un lanceur `pkl-shell` qui choisit le binaire précompilé dans `dist/`. Le ZIP Pkl pèse environ 20 Mo car il contient les six plateformes.

## Versions et publication

L'URI d'un [package Pkl exige une version SemVer](https://pkl-lang.org/main/latest/language-reference/index.html#package-asset-uri) : `@latest` n'est pas utilisable ici. Épinglez `@0.1.0`, puis mettez à jour explicitement l'URI et le chemin `.pkl-shell/<version>/reader` lors d'une nouvelle version.

Pour publier une nouvelle version, modifiez `version` dans [`lib/PklProject`](lib/PklProject) et le chemin de sortie dans `install.pkl`, puis régénérez les artefacts :

```sh
sh scripts/build-unix.sh
sh scripts/package-pkl.sh
```

Commitez les quatre fichiers de `pkg/` et poussez sur `main`. Gardez les anciennes versions : leurs URI et sommes de contrôle doivent rester stables. La CI vérifie que le ZIP correspond au code source et que l'installation depuis le package fonctionne.

`shell.run` encode la commande en base64 pour éviter l'encodage URI manuel. Pkl met en cache chaque URI pendant une évaluation : deux appels identiques peuvent partager le même résultat. Les commandes s'exécutent via `sh -c` avec les droits du processus Pkl ; utilisez seulement des commandes et des modules de confiance.
