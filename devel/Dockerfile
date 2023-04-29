FROM ruby:3

ARG UID

RUN useradd --create-home --uid "$UID" app

RUN \
  apt-get update &&         \
  apt-get install -y        \
    entr                    \
    less                    \
    librsvg2-bin            \
    libsaxonb-java          \
    openjdk-11-jre-headless \
    optipng                 \
    texinfo                 \
    &&                      \
  apt-get clean

CMD [ "/bin/bash" ]
