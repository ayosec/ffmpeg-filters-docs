FROM ruby:3-slim

ARG UID

RUN \
  apt-get update && \
  apt-get install -y texinfo && \
  apt-get clean

RUN useradd --create-home --uid "$UID" app

CMD [ "/bin/bash" ]
