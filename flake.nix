{
  description = "Tensorflow devShell for MacOS with poetry2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, poetry2nix, ... }:
    {
      overlay = final: prev: {
    
        myapp = final.poetry2nix.mkPoetryApplication {
          projectDir = self;
          preferWheels = true;
          python = final.python311;
        };

        myappEnv = final.poetry2nix.mkPoetryEnv {
          projectDir = self;
          preferWheels = true;
          python = final.python311;
          editablePackageSources = { myapp = self; };
        };

        poetry = (prev.poetry.override { python = prev.python311; });
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
            myapp
            myappEnv
            poetry
          ];

          shellHook = ''
            export PYTHONPATH=${python311}
          '';
        };

      });

      packages = forAllSystems (pkgs: {
        default = pkgs.myapp;
        
        poetry = pkgs.poetry;
      });

    });
}