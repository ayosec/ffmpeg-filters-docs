FROM ruby:3

ARG UID

RUN useradd --create-home --uid "$UID" app

RUN \
  apt-get update &&  \
  apt-get install -y \
    less             \
    texinfo          \
    &&               \
  apt-get clean

CMD [ "/bin/bash" ]
