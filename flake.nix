{
  # inspired by: https://medium.com/@sorenlind/tensorflow-with-gpu-support-on-apple-silicon-mac-with-homebrew-and-without-conda-miniforge-915b2f15425b
  # ---
  # 1. look at https://anaconda.org/apple/tensorflow-deps for the list of dependencies in the
  #   meta.yaml file
  # 2. add hdf5 to build inputs
  # 3. install the python dependencies with poetry, eg. for tensorflow-deps 2.10:
  #    - grpcio >=1.37.0,<2.0
  #    - h5py >=3.6.0,<3.7
  #    - numpy >=1.23.2,<1.23.3
  #    - protobuf >=3.19.1,<3.20

  description = "Tensorflow devShell for MacOS with poetry2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, poetry2nix, ... }:
    let
      myappOverlay = (final: prev:
        let
          myappConfig = {
            projectDir = self;
            preferWheels = true;
            python = final.${pythonVer};
            groups = if final.stdenv.isDarwin then [ "macos" ] else [ "linux" ];
            overrides = prev.poetry2nix.defaultPoetryOverrides.extend (self: super: {
              tensorflow-io-gcs-filesystem = super.tensorflow-io-gcs-filesystem.overrideAttrs (old: {
                buildInputs = old.buildInputs ++ [ prev.libtensorflow ];
              });
            });
          };
        in
        {

          myapp = final.poetry2nix.mkPoetryApplication myappConfig;

          myappEnv = final.poetry2nix.mkPoetryEnv myappConfig // {
            editablePackageSources = { myapp = ./.; };
          };

          poetry = (prev.poetry.override { python = final.${pythonVer}; });
        });

      forEachSystem = systems: func: nixpkgs.lib.genAttrs systems (system:
        func (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            poetry2nix.overlay
            myappOverlay
          ];
        })
      );

      forAllSystems = func: (forEachSystem [ "x86_64-linux" "aarch64-darwin" ] func);

      pythonVer =
        let
          versionList = builtins.filter builtins.isString
            (builtins.split ''\.''
              (builtins.elemAt
                (builtins.match ''^[>=~^]*([0-9]+(\.[0-9]+)*)(,[0-9<=.]*)?$''
                  (builtins.fromTOML (builtins.readFile ./pyproject.toml)).tool.poetry.dependencies.python
                ) 0
              )
            );
        in
        "python${builtins.elemAt versionList 0}${builtins.elemAt versionList 1}";
    in
    {
      devShells = forAllSystems (pkgs: with pkgs; {
        default = mkShellNoCC {
          packages = [
            # this package            
            myappEnv

            # development dependencies
            poetry
          ];

          shellHook = ''
            export PYTHONPATH=${pkgs.${pythonVer}}
            export LD_LIBRARY_PATH=${ lib.strings.concatStringsSep ":" [
              "${cudaPackages.cudatoolkit}/lib"
              "${cudaPackages.cudatoolkit.lib}/lib"
              "${cudaPackages.cudnn}/lib"
            ]}:$LD_LIBRARY_PATH
          '';
        };

      });

      packages = forAllSystems (pkgs: {
        default = pkgs.myapp;

        poetry = pkgs.poetry;
      });

    };
}
