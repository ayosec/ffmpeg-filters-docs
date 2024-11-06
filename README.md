# FFmpeg Filters Documentation

The tool in this repository builds an alternative presentation of the
[official documentation for FFmpeg filters][offdocs]. It aims to be easier
to read and easier to navigate.

[![Open Website](.github/readme/badge.svg)][website]

<!-- differences -->

## Differences with the Official Documentation

* Each filter has its own dedicated page.

* Filters are organized into groups (like *Filters / Audio*, or
  *Sources / Multimedia*).

    The groups are guessed from the section headers in the official
    documentation.

* All pages have a search box to jump to another filter.

    It can be focused by pressing the key <kbd>/</kbd>, and then use arrows
    (<kbd>↓</kbd>, <kbd>↑</kbd>) to select one of the results.

    The filter's description in the search results is the first sentence of its
    documentation.

* Many code snippets are rendered with syntax highlighting.

    <!-- [highlight] This is an example from the filter:overlay filter:

        ffmpeg -i left.avi -i right.avi -filter_complex "
        nullsrc=size=200x100 [background];
        [0:v] setpts=PTS-STARTPTS, scale=100x100 [left];
        [1:v] setpts=PTS-STARTPTS, scale=100x100 [right];
        [background][left]       overlay=shortest=1       [background+left];
        [background+left][right] overlay=shortest=1:x=100 [left+right]
        "
    -->

    The highlighting is inferred from the content, so it may not work in some
    cases. The official documentation does not specify the language in which the
    snippets are written.

* Responsive design for smaller screens.

* Dark and light themes.

* Documentation for all _major.minor_ versions, under *Other Vers.* in the sidebar.

    This is helpful when you have to use an older version of FFmpeg.

* The *Version Matrix* shows which filters are available in each FFmpeg version.

<!-- end differences -->

## Usage

The documentation can be [read in GitHub Pages][website], and it is possible to
build it locally.

### Nix Flakes

The recommended way to run the generator is with [`nix run`][nix-run]:

```console
$ nix run github:ayosec/ffmpeg-filters-docs
```

The tool accepts some command-line arguments (see `--help`). For example, to
build only the documentation for FFmpeg 7.1 in the path `/tmp/ffdocs`:

```console
$ nix run github:ayosec/ffmpeg-filters-docs -- --versions 7.1 --output /tmp/ffdocs
```

To execute the tool from a copy of this repository:

```console
$ nix develop --command ./ffmpeg-filters-docs […]
```

### Docker

A Docker image can be built with the file [`docker/Dockerfile`](./docker/Dockerfile).

```console
$ docker build --tag ffdocs --file docker/Dockerfile .

$ docker run --volume /tmp/web:/tmp/web ffdocs --versions 7.1 --output /tmp/web
```


[offdocs]: https://ffmpeg.org/ffmpeg-filters.html
[website]: https://ayosec.github.io/ffmpeg-filters-docs/
[nix-run]: https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix3-run.html
