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
    let pythonVer = "python310"; in
    {
      overlay = final: prev: {
    
        myapp = final.poetry2nix.mkPoetryApplication {
          projectDir = self;
          preferWheels = true;
          python = final.${pythonVer};
        };

        myappEnv = final.poetry2nix.mkPoetryEnv {
          projectDir = self;
          preferWheels = true;
          python = final.${pythonVer};
          editablePackageSources = { myapp = ./.; };
        };

        poetry = (prev.poetry.override { python = final.${pythonVer}; });
      };
    } // (let

      forEachSystem = systems: func: nixpkgs.lib.genAttrs systems (system:
        func (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            poetry2nix.overlay
            self.overlay
          ];
        })
      );

      forAllSystems = func: (forEachSystem [ "x86_64-linux" "aarch64-darwin" ] func);

    in {
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
          '';
        };

      });

      packages = forAllSystems (pkgs: {
        default = pkgs.myapp;
        
        poetry = pkgs.poetry;
      });

    });
}