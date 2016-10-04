FROM postgres:9.5
# Adapted from https://hub.docker.com/r/mdillon/postgis/

MAINTAINER Cheewai Lai <clai@csir.co.za>

# Subscribe to pgsql-pkg-debian@postgresql.org for release announcements
ENV POSTGIS_MAJOR 2.3
ENV POSTGIS_VERSION 2.3 

ENV DEBIAN_FRONTEND noninteractive
ENV LANG en_ZA.UTF-8
ENV LANGUAGE en_ZA.UTF-8

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
 postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
 postgis=$POSTGIS_VERSION \
 locales \
 rsyslog \
&& sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
&& sed -i -e 's/# en_ZA.UTF-8 UTF-8/en_ZA.UTF-8 UTF-8/' /etc/locale.gen \
&& echo 'LANG="en_ZA.UTF-8"'>/etc/default/locale \
&& dpkg-reconfigure locales \
&& update-locale LANG=en_ZA.UTF-8 \
&& dpkg-reconfigure locales \
&& rm -rf /var/lib/apt/lists/*
