#!/bin/bash
#
# Update or generate the `gemset.nix` file needed by the Nix flake.
#
# If the `-u` flag is present, it also executes `bundle update`.

set -euo pipefail

export BUNDLE_FORCE_RUBY_PLATFORM=true

SOURCE=$(realpath "$(dirname "$0")")

gemset=$SOURCE/gemset.nix
lockfile=$(realpath "$SOURCE/../Gemfile.lock")

# CLI arguments.

bundle_update=no

for arg
do
  case "$arg" in
    -u)
      bundle_update=yes
      ;;

    *)
      printf 'Invalid argument: %q\n\n' "$arg"
      printf 'USAGE:\n\n\t%q [-u]\n' "$0"
      exit 1
  esac
done

# Create an empty gemset if it is missing.

if [ ! -e "$gemset" ]
then
  echo '{}' > "$gemset"
fi


# Ensure that Bundle doesn't use native libraries, since they can have
# issues with bundix.
export BUNDLE_FORCE_RUBY_PLATFORM=true


if [ $bundle_update = yes ]
then
  (
    set -x
    nix develop --command bundle lock --update --lockfile="$lockfile"
  )
fi

set -x
nix develop --command bundix --lock --gemset="$gemset"
nix fmt "$gemset"
