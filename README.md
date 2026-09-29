# pkl-shell

[![CI](https://github.com/Agence-Fluor/pkl-shell/actions/workflows/build.yml/badge.svg)](https://github.com/Agence-Fluor/pkl-shell/actions/workflows/build.yml)

Utilise `shell.run("commande")` dans Pkl. Le package contient le module et les binaires Unix.

## Démarrer

Prérequis : Pkl CLI 0.31.1+ et `sh` sur Linux, macOS ou FreeBSD. Ajoute ceci au `PklProject` :

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
        "r=.pkl-shell/0.1.0/reader; test -x \"$r\" || pkl run @shell/install.pkl >/dev/null; chmod +x \"$r\"; exec \"$r\""
      }
    }
  }
}
```

Dans `example.pkl` :

```pkl
import "@shell/shell.pkl"

message = shell.run("printf 'Bonjour depuis Pkl'")
```

```sh
pkl project resolve
pkl eval example.pkl
```

Au premier appel, le bootstrap extrait le binaire de la plateforme dans `.pkl-shell/`. Ajoute ce dossier à `.gitignore`.

## Plateformes

| Système | Architectures |
| --- | --- |
| Linux | amd64, arm64 |
| macOS | amd64, arm64 |
| FreeBSD | amd64, arm64 |

## Développement et versions

Pour essayer le dépôt avec Nix :

```sh
nix develop --command sh -c 'sh scripts/build-unix.sh --host && cd test && pkl eval --external-resource-reader=shell=../pkl-shell example.pkl'
```

La CI compile les six binaires, construit et teste le package. Pour publier une version, mets à jour `version` dans [`lib/PklProject`](lib/PklProject) et le chemin dans [`lib/install.pkl`](lib/install.pkl), pousse le commit, puis crée le tag `pkl-shell@<version>`. La CI publie le package sur la [GitHub Release](https://github.com/Agence-Fluor/pkl-shell/releases) ; garde les releases existantes intactes.
