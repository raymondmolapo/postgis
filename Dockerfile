FROM postgres:9.4
# Adapted from https://hub.docker.com/r/mdillon/postgis/

MAINTAINER Cheewai Lai <clai@csir.co.za>

# Subscribe to pgsql-pkg-debian@postgresql.org for release announcements
ARG POSTGIS_MAJOR=2.2
#ARG POSTGIS_VERSION=2.2.2+dfsg-1.pgdg80+1 
ARG POSTGIS_VERSION=2.2.2+dfsg-1~bpo8+1

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG en_ZA.UTF-8
ENV LANGUAGE en_ZA.UTF-8

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >>/etc/apt/sources.list.d/postgis.list \
&& apt-get update \
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
