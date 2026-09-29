# pkl-shell

[![Build Unix readers](https://github.com/Agence-Fluor/pkl-shell/actions/workflows/build.yml/badge.svg)](https://github.com/Agence-Fluor/pkl-shell/actions/workflows/build.yml)

Une fonction `shell.run("commande")` pour Pkl. Le package versionné contient le module Pkl **et** les readers Unix : il suffit d'avoir Pkl, sans installer Go ni télécharger un second paquet.

## Démarrer

Avec le **CLI Pkl 0.31.1 ou plus récent** et `sh` sur Unix, créez ce `PklProject` à la racine de votre projet :

```pkl
amends "pkl:Project"

dependencies {
  ["shell"] {
    uri = "package://pkg.pkl-lang.org/github.com/Agence-Fluor/pkl-shell/pkl-shell@0.1.0"
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

Le premier `shell.run` appelle [`install.pkl`](lib/install.pkl) : Pkl lit le binaire adapté à votre plateforme dans le package et l'écrit dans `.pkl-shell/0.1.0/reader`. Le bootstrap lui donne le droit d'exécution et le réutilise ensuite. Ajoutez `.pkl-shell/` à votre `.gitignore`. Le package sera accessible après la publication de la [release `pkl-shell@0.1.0`](https://github.com/Agence-Fluor/pkl-shell/releases/tag/pkl-shell@0.1.0).

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

Le dossier [`test/`](test/) déclare seulement la dépendance locale ; l'option CLI enregistre le reader pour cette démo. La [CI](https://github.com/Agence-Fluor/pkl-shell/actions/workflows/build.yml) construit aussi le ZIP Pkl et teste son installation automatique via un miroir HTTP local.

## Plateformes

| Système | Architectures | Binaire dans le package |
| --- | --- | --- |
| Linux | amd64, arm64 | `bin/pkl-shell-linux-<arch>` |
| macOS | amd64, arm64 | `bin/pkl-shell-darwin-<arch>` |
| FreeBSD | amd64, arm64 | `bin/pkl-shell-freebsd-<arch>` |

Les six binaires sont compilés dans la CI ; le fonctionnement complet est testé sur Linux amd64. La [CI fournit aussi une archive](https://github.com/Agence-Fluor/pkl-shell/actions/workflows/build.yml) avec un lanceur `pkl-shell` qui choisit le binaire précompilé dans `dist/`. Le ZIP Pkl pèse environ 20 Mo car il contient les six plateformes. Sur un tag `pkl-shell@<version>`, la CI publie le ZIP et ses métadonnées comme assets de la GitHub Release. L'URI `pkg.pkl-lang.org` redirige vers cette release.

## Versions et publication

L'URI d'un [package Pkl exige une version SemVer](https://pkl-lang.org/main/latest/language-reference/index.html#package-asset-uri) : `@latest` n'est pas utilisable ici. Épinglez `@0.1.0`, puis mettez à jour explicitement l'URI et le chemin `.pkl-shell/<version>/reader` lors d'une nouvelle version.

Pour publier une nouvelle version, modifiez `version` dans [`lib/PklProject`](lib/PklProject), le chemin de sortie dans `install.pkl`, ainsi que les exemples de version dans ce README et `scripts/test-package.sh`. Poussez le commit, puis son tag `pkl-shell@<version>`. Pour la première version :

```sh
git tag 'pkl-shell@0.1.0'
git push github 'pkl-shell@0.1.0'
```

La CI construit le package dans `dist/package`, teste son installation et publie les quatre fichiers Pkl sur la release. Aucun ZIP n'est commité. Gardez chaque release de version intacte : les URI et sommes de contrôle doivent rester stables.

`shell.run` encode la commande en base64 pour éviter l'encodage URI manuel. Pkl met en cache chaque URI pendant une évaluation : deux appels identiques peuvent partager le même résultat. Les commandes s'exécutent via `sh -c` avec les droits du processus Pkl ; utilisez seulement des commandes et des modules de confiance.
