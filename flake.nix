{
  description = "Documentation for FFmpeg filters.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    flake-utils.url =
      "github:numtide/flake-utils/1ef2e671c3b0c19053962c07dbda38332dcebf26";
  };

  outputs = { self, nixpkgs, flake-utils, }:
    flake-utils.lib.eachDefaultSystem (system:
      let

        pkgs = nixpkgs.legacyPackages.${system};

        bin-name = "ffmpeg-filters-docs";

        ruby-env = pkgs.bundlerEnv {
          name = "docs-builder";
          ruby = pkgs.ruby_3_2;
          gemset = ./.nix/gemset.nix;
          gemdir = ./.;
        };

        deps = with pkgs; [
          ruby-env
          ruby-env.wrappedRuby
          git
          librsvg
          optipng
          saxonb_9_1
          texinfo
          zstd
        ];

        shellDeps = let
          # Make a wrapper script to set GEM_PATH with the gems from the bundle.
          gemWrapper = gem:
            pkgs.writeShellScriptBin gem ''
              export GEM_PATH="$(
                bundle exec ruby -e \
                  'print Gem.loaded_specs.values.map(&:full_gem_path)*?:'
              )"

              exec ruby ${pkgs.rubyPackages_3_2.${gem}}/bin/${gem} "$@"
            '';

        in [
          pkgs.bundix
          (gemWrapper "solargraph") # LSP
          (gemWrapper "yard")
        ];

      in {
        formatter = pkgs.nixfmt-classic;

        packages.default = pkgs.stdenv.mkDerivation {
          name = bin-name;
          src = ./.;

          buildInputs = deps;

          installPhase = ''
            mkdir -p "$out"/{source,bin}

            cp -a "${bin-name}" lib "$out/source"

            bin="$out/bin/${bin-name}"

            {
                echo '#!/bin/bash'
                printf '\nPATH=%q\n\n' "$PATH"
                printf 'exec %q %q "$@"\n' \
                    '${ruby-env.wrappedRuby}/bin/ruby' \
                    "$out/source/${bin-name}"
            } > "$bin"

            chmod +x "$bin"
          '';
        };

        devShells.default = pkgs.mkShell { buildInputs = deps ++ shellDeps; };
      });
}
