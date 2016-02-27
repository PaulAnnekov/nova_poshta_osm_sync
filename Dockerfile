FROM ubuntu:15.10

RUN apt-get update && apt-get -qqy install curl apt-transport-https
RUN sh -c 'curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -'
RUN sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
RUN apt-get update && apt-get -qqy install dart=1.14.2-1

RUN groupadd -g 1000 nova_poshta_osm
RUN useradd -m -u 1000 -g 1000 nova_poshta_osm

COPY . /home/nova_poshta_osm/project/
RUN chown -R 1000:1000 /home/nova_poshta_osm/project/

USER nova_poshta_osm

ENV PATH /usr/lib/dart/bin:$PATH

CMD cd /home/nova_poshta_osm/project && pub get && pub serve --mode=release --hostname=0.0.0.0 web data