# Python Development Environment with Nix, Poetry, direnv and VSCode

This project acts as a boilerplate for a fully-featured, reproducible, Python development environment.
Namely, it provides:

1. Reproducible builds, packaging, and development environments with [Nix](https://nixos.org/nix/)
2. Automatic integration of Python dependencies into the Nix ecosystem with [Poetry](https://python-poetry.org/) and [Poetry2nix](https://github.com/nix-community/poetry2nix).
3. Event-based activation and deactivation of the development environment with [direnv](https://direnv.net/) and [nix-direnv](https://github.com/nix-community/nix-direnv).
4. Automatic Python intepreter selection for execution and debugging in [VSCode](https://code.visualstudio.com/) with using direnv's VSCode extension [direnv-vscode](https://marketplace.visualstudio.com/items?itemName=mkhl.direnv).
5. Sane defaults in terms of Python tooling that can easily be modified (`black`, `isort`, `autoflake`, and `pytest`).
6. A standard project layout as per Kenneth Reitz's [recommendations](https://kennethreitz.org/essays/2013/01/27/repository-structure-and-python).
7. A fully reproducible environment for [TensorFlow](https://www.tensorflow.org/) on Apple Silicon.


## Prerequisites

- [Nix](https://nixos.org/nix/) with flakes enabled.
- [direnv](https://direnv.net/), its shell hook, and `nix-direnv` installed.
- [VSCode](https://code.visualstudio.com/) with the `direnv-vscode` and `python` extensions.

## Get started

1. Clone this repository.
2. Run `direnv allow` to activate the development environment.
   > `direnv` will load the environment `flake.nix` and populate the environment with the dependencies specified in `pyproject.toml`. 
   > This will take a while the first time, but subsequent loads will be much faster as `nix-direnv` will cache the environment.
3. Open the project in VSCode, and load the environment if prompted.
   > `direnv-vscode` will automatically load the environment, and especially the `$PYTHONPATH` variable, that VSCode will use to select the correct Python interpreter.
4. Profit!

## Usage / FAQ

### How do I add a Python dependency?

Poetry manages the dependencies in `pyproject.toml`, and will generate the lockfile `poetry.lock` when you run `poetry lock`. 
Using `poetry add <package>` will add the package to both files.
You can also edit manually `pyproject.toml` and run `poetry lock` to update the lockfile.

### Direnv is not loading the environment

Direnv will automatically load the environment when you enter the project directory.
It will also rebuild the environment if `flake.nix` or `pyproject.toml` have changed.
If you want to force a rebuild, you can run `direnv reload`.

### It still doesn't work!

One caveat of this setup is that an empty `pyproject.toml`, an error in the syntax, or inconsistencies between `pyproject.toml` and `poetry.lock` will cause `nix-direnv` to fail. 
At that point, the Nix environment will not be loaded, and even poetry won't be available anymore (unless you have poetry installed globally).

To fix the issue, the flake provides a poetry distribution that is pinned to the same version as the one used in the environment.
You can use it to regenerate the lockfile or interact with poetry in general, via `nix run .#poetry <args_or_subcommands>`.
For example, to regenerate the lockfile, run `nix run .#poetry lock`.

### How do I update TensorFlow?

TensorFlow is a special case, as it is not directly available on Apple Silicon, especially with GPU support.
Apple provides [installation instructions](https://developer.apple.com/metal/tensorflow-plugin/) for the Metal plugin, but they are not compatible with Nix.
Therefore, updating TensorFlow requires a bit of manual work.

1. Identify the Python version compatible with the TensorFlow version you want to install.
   > For example, TensorFlow 2.10 is incompatible with Python 3.11.
2. Update the `pythonVer` attribute in `flake.nix` to point to the correct version.
3. Identify the `tensorflow-metal` plugin version compatible with the TensorFlow version you want to install.
   > For example, TensorFlow 2.10 is compatible with the Metal plugin 0.6. See the compatibility table [below](#annex-a-tensorflow-compatibility-table).
4. Extract the other dependency requirements for the version that you want to use, from the metadata of Apple's `tensorflow-deps` [Conda metapackage](https://anaconda.org/apple/tensorflow-deps/files). Download the archive corresponding to your TensorFlow version, and extract the `info/recipe/meta.yaml` file.
   > For example, TensorFlow 2.10 requires `grpcio >=1.37.0,<2.0`, `h5py >=3.6.0,<3.7`, `numpy >=1.23.2,<1.23.3`, and `protobuf >=3.19.1,<3.20`.
5. Update `pyproject.toml` with the new dependencies.
6. Generate the lockfile with `nix run .#poetry lock`, and let direnv reload the environment.

## Annex A: TensorFlow compatibility table

Note that Apple's documented [releases](https://developer.apple.com/metal/tensorflow-plugin/) are not always up-to-date.
I found more tested association on Apple's [community forum](https://developer.apple.com/forums/thread/689300?answerId=751771022#751771022). 

| TensorFlow version | Metal plugin version |
|--------------------|----------------------|
| 2.5                | 0.1.2                |
| 2.6                | 0.2                  |
| 2.7                | 0.3                  |
| 2.8                | 0.4                  |
| 2.9                | 0.5                  |
| 2.10               | 0.6                  |

While `tensorflow-metal` has versions up to 0.8, I have not yet managed to make them work with the latest TensorFlow versions.

