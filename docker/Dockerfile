FROM ruby:3.2-bookworm

RUN \
    DEBIAN_FRONTEND=noninteractive \
    apt-get update &&        \
    apt-get install -y       \
        default-jre-headless \
        librsvg2-bin         \
        libsaxonb-java       \
        optipng              \
        protobuf-compiler    \
        texinfo              \
        zstd

WORKDIR /app

ADD . .
RUN bundle install --frozen

ENTRYPOINT [ "bundle", "exec", "./ffmpeg-filters-docs" ]
