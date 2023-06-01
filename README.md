# Python Development Environment with Nix, Poetry, direnv and VSCode

This project acts as a boilerplate for a fully-featured, reproducible, Python development environment.
Namely, it provides:

1. Reproducible builds, packaging, and development environments with [Nix](https://nixos.org/nix/)
2. Automatic integration of Python dependencies into the Nix ecosystem with [Poetry](https://python-poetry.org/) and [Poetry2nix](https://github.com/nix-community/poetry2nix).
3. Event-based activation and deactivation of the development environment with [direnv](https://direnv.net/) and [nix-direnv](https://github.com/nix-community/nix-direnv).
4. Automatic Python intepreter selection for execution and debugging in [VSCode](https://code.visualstudio.com/) with using direnv's VSCode extension [direnv-vscode](https://marketplace.visualstudio.com/items?itemName=mkhl.direnv).
5. Sane defaults in terms of Python tooling that can easily be modified (`black`, `isort`, `autoflake`, and `pytest`).
6. A standard project layout as per Kenneth Reitz's [recommendations](https://kennethreitz.org/essays/2013/01/27/repository-structure-and-python).


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