#!/bin/bash
#
# Run the `--sync-ffmpeg-data` command to update the snapshot of the required
# data from the FFmpeg repository.

set -euo pipefail

cd "$(dirname "$0")/.."

set -x
exec nix develop --command \
    bundle exec ./ffmpeg-filters-docs --sync-ffmpeg-data
