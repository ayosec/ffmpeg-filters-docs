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

      in {
        formatter = pkgs.nixfmt;

        packages.default = pkgs.stdenv.mkDerivation {
          name = bin-name;
          src = ./.;

          buildInputs = with pkgs; [
            ruby-env
            git
            librsvg
            optipng
            saxonb_9_1
            texinfo
            zstd
          ];

          nativeBuildInputs = with pkgs; [ bundix ];

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
      });
}