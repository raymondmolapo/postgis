FROM postgres:9.4
# Adapted from mdillon/postgis, modified to include barman
# https://hub.docker.com/r/mdillon/postgis/
# with changes for syslog, pgbarman, and /start.sh

MAINTAINER Cheewai Lai <clai@csir.co.za>

ENV POSTGIS_MAJOR 2.1
ENV POSTGIS_VERSION 2.1.7+dfsg-3~94.git954a8d0.pgdg80+1

RUN apt-get update \ 
&& apt-get install -y --no-install-recommends \ 
postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
postgis=$POSTGIS_VERSION \
postgresql-$PG_MAJOR-pgespresso \
barman \
rsyslog \
&& rm -rf /var/lib/apt/lists/* 

ENV DEBIAN_FRONTEND=noninteractive
RUN locale-gen en_ZA.UTF-8 && dpkg-reconfigure locales && \
 localedef -i en_ZA -c -f UTF-8 -A /usr/share/locale/locale.alias en_ZA.UTF-8
ENV LANG en_ZA.UTF-8
ENV LC_CTYPE=en_ZA.UTF-8

# Not required in postgresql 9.3+ using extension
#RUN mkdir -p /docker-entrypoint-initdb.d
#ADD https://github.com/appropriate/docker-postgis/raw/master/initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh

#
# Base image "postgres" defines these:
#   https://github.com/docker-library/postgres
#   https://github.com/docker-library/postgres/blob/master/docker-entrypoint.sh
#
#COPY docker-entrypoint.sh /
#ENTRYPOINT ["/docker-entrypoint.sh"]
#CMD ["postgres"]
