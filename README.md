# PostgreSQL and PostGIS in a Docker container


## About

This Docker project creates a PostgreSQL and PostGIS database server in a container on a suitable host machine. It is inspired by base image [mdillon/postgis](https://hub.docker.com/r/mdillon/postgis/~/dockerfile/) but added with [pg-barman](http://www.pgbarman.org/) which is an essential tool for database archive/backup/restore.

Refer to the root base image [postgres](https://hub.docker.com/_/postgres/) for the full details on customizing the runtime environment.

> If you would like to do additional initialization in an image derived from this one, add one or more *.sql or *.sh scripts under /docker-entrypoint-initdb.d (creating the directory if necessary). After the entrypoint calls initdb to create the default postgres user and database, it will run any *.sql files and source any *.sh scripts found in that directory to do further initialization before starting the service.
>
>These initialization files will be executed in sorted name order as defined by the current locale, which defaults to en_US.utf8. Any *.sql files will be executed by POSTGRES_USER, which defaults to the postgres superuser. It is recommended that any psql commands that are run inside of a *.sh script be executed as POSTGRES_USER by using the --username "$POSTGRES_USER" flag. This user will be able to connect without a password due to the presence of trust authentication for Unix socket connections made inside the container.
>
>...
>
>If there is no database when postgres starts in a container, then postgres will create the default database for you. While this is the expected behavior of postgres, this means that it will not accept incoming connections during that time. This may cause issues when using automation tools, such as **docker-compose**, that start several containers simultaneously.

The actual database directory is - intentionally - located outside the container. The default *pg_hba.conf* allows an md5-connection (i.e. password-based access) from any CSIR Meraka subnet address (i.e. in the range 146.64.19.\* and 146.64.28.\*), excluding WiFi DHCP ranges.

## Usage

```
#TODO: include a complete commented compose-docker.yml
```

2. Build the Docker image:

```
docker-compose -f docker-compose.yml build
```

3. Run the newly built Docker image:

```
docker-compose -f docker-compose.yml up -d
```

7. To run any bootstrap commands as soon as Postgresql server starts up, set environment variable PG_APPS_SCRIPT to the name of your executable script (without directory path) in build_run_env, and store the script in *main* subdirectory. This script will be executed in Bash shell with the effective user-id of the database superusersh after the Postgresql server has started up each time the Docker container runs. An example of such a script:

7. Sample bootstrap script

```
#! /bin/bash
set -ux

psql -h localhost -c "CREATE USER fynbosuser WITH PASSWORD 'q1w2e3r4';"

for _db in fynbosfire_data fynbosfire_viewer; do
  # Do nothing if database already exists
  rc=$(psql -h localhost -A -t -c "SELECT 1 FROM pg_database WHERE datname = '$_db'")
  [ -z "$rc" ] && {
    psql -h localhost -c "CREATE DATABASE $_db OWNER=fynbosuser;"
    psql -h localhost $_db -c "CREATE EXTENSION postgis;"
    psql -h localhost $_db -c "CREATE EXTENSION postgis_topology;"

    if [ "$_db" = "fynbosfire_viewer" ]; then
      SQLDIR="/usr/share/postgresql/9.3/contrib/postgis-2.1/"
      [ -f "$SQLDIR/legacy_minimal.sql" ] && psql -h localhost fynbosfire_viewer -f $SQLDIR/legacy_minimal.sql
      [ -f "$SQLDIR/legacy_gist.sql" ] && psql -h localhost fynbosfire_viewer -f $SQLDIR/legacy_gist.sql
    fi
  }
done
``` 

## Production Use

Plan for disaster.

### Daily Backup

This repo includes a script, *dumpdb.sh* which is intended to be run by Postgresql admin user *postgres* inside the container. When executed, it dumps the roles, schema (including GRANT) and all databases as separate files suffixed with *yyyy-mm-dd*

You can schedule a nightly cron job to execute it using *docker exec*, e.g.

```
docker exec {DOCKER_NAME} su - postgres /runtime/dumpdb.sh /restore
```

You should consider storing the daily dumps to a different server.

To restore a specific database. This will wipe out all existing data:

```
docker exec -it {DOCKER_NAME} su - postgres
pg_restore -j4 --clean --create {dumpfile}
```

To restore every database, either drop all your databases first, or run a separate instance of postgresql container but pointing to an existing empty PGDATA_DIR directory.

```
pg_restore -j4 -d postgres {postgres_dumpfile}
psql -f {roles_sql}
grep GRANT {schema_sql} | psql
# Repeat for every dumpfile
pg_restore -j4 --clean --create {dumpfile}
```

### Continuous Archiving

First and foremost, read the official documentation for **Continuous Archiving and Point-in-Time Recovery** for your specific version of Postgresql.

> At all times, PostgreSQL maintains a write ahead log (WAL) in the pg_xlog/ subdirectory of the cluster's data directory. The log records every change made to the database's data files. This log exists primarily for crash-safety purposes: if the system crashes, the database can be restored to consistency by "replaying" the log entries made since the last checkpoint.

Make use of these settings in *main/postgresql\_nogit.conf* to enable WAL archiving:

* wal_level
* archive_mode = on
* archive_command = 'rsync -a %p /path/to/wal_archive/%f'


### High-availability

*postgresql.conf* has a section for replication. Refer to https://wiki.postgresql.org/wiki/Streaming_Replication


## Other

You can create a more readable PDF version of this file by running:

```
pandoc README.md -V geometry:margin=1in -o README.pdf
```
