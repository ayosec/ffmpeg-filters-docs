FROM ruby:3-slim

ARG UID

RUN \
  apt-get update &&  \
  apt-get install -y \
    pkg-config       \
    libxml2-dev      \
    libxslt-dev      \
    texinfo          \
    &&               \
  apt-get clean

RUN useradd --create-home --uid "$UID" app

CMD [ "/bin/bash" ]
