# Debian Bookworm to build the website.
FROM ruby:3.2-bookworm AS docs

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


# Install gems before adding the source code, so they can be reused
# if the pages are rebuilt without changing dependencies.

ENV BUNDLE_FORCE_RUBY_PLATFORM=true

WORKDIR /gemfile
ADD Gemfile .
ADD Gemfile.lock .
RUN bundle install


WORKDIR /app
ADD . .
RUN ./ffmpeg-filters-docs --output /output


# HTTP server.
FROM nginx
COPY --from=docs /output /usr/share/nginx/html
