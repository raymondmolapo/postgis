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

Once you understand the directory structure and the settings for **all** the variables that are needed, do the following:

1. Create a *build_run_env_nogit.sh* file inside the *main* directory (the one under this README file), with correct settings for **all** the variables. PGDATA_DIR, PGARCHIVE_DIR PGRESTORE_DIR PGLOG_DIR may be left undefined in which case the *run* script expects to find them pre-existing in the same level with **main** directory as **data**, **archive**, **restore**, **logs** respectively. RUN_OPTIONS is optional. It is mainly intended for mounting additional volumes to containing your ad-hoc scripts, e.g. database backup, etc. And then, in order to execute any script, set IS_CRON=1 before the *run /path/to/my/adhoc/script*

2. Copy and customize access control pg\_hba\_sample to *main/pg\_hba\_nogit.conf* 

2. Copy and customize postgresql.conf.93 or postgresql.conf.94 for reference depending on your choice of Postgresql version, save as *main/postgresql\_nogit.conf*.  Key parameters are as follows. The server will fail to start with *"could not access private key file"* because the default *ssl\_key\_file* points to /etc/ssl/private/ which is only accessibly by root.
    - shared_buffer
    - work_mem
    - maintenance_work_mem
    - effective_cache_size
    - ssl_cert_file = '/var/lib/postgresql/9.3/main/ssl-cert-snakeoil.pem'
    - ssl_key_file = '/var/lib/postgresql/9.3/main/ssl-cert-snakeoil.key'
    - checkpoint_segments - use a value greater than default 3 if you intend to restore large amount of data

2. To use guided parameter tuning, go to http://pgtune.leopard.in.ua/

2. Build the Docker image:

    ```
    cd main
    sudo ./build
    ```
3. Run the newly built Docker image:

    ```
    cd main
    sudo ./run
    ```

    This should produce a response such as the following, where the string corresponds to the ID of the Docker container:

    ```
    c71423a502e16b87f0bc10fd11b3124a344ba1a2280c4a0fgt990053b59917d
    ```
4. Test that the database server is running properly.  To do this, you need to have installed the psql client on your machine: 

    ```
    psql -h host.name.com -p 22432 -U user_name --dbname=postgres
    ```
    The '22432' should be replaced by the SERVICE_PORT, and 'user_name' replaced by PG_ADMIN_USER, for the variables you have specified below.  The 'host.name.com', for a simple local install will just be *localhost*.
    
5. Ad-hoc runtime override and debugging. You can override one or more of the following variables at the command line:

    ```
    * PGUID
    * PGGID
    * DOCKER_BASEIMAGE
    * DOCKER_NAME
    * PG_ADMIN_USER
    * PG_ADMIN_PASSWORD
    * PGDATA_DIR 
    * PGLOG_DIR
    * PG_APPS_SCRIPT
    * SERVICE_PORT
    * USE_APT_PROXY
    ```

    For example,
    ```
    cd main
    env SERVICE_PORT=22432 PGDATA_DIR=/tmp/pgdata-copy ./run
    ```

    To launch the container with an interactive bash terminal, instead of running in the background:
    ```
    cd main
    env DEBUG=1 SERVICE_PORT=22432 PGDATA_DIR=/tmp/pgdata-copy ./run
    ```

## Structure

### main directory

This directory contains the scripts and files used to build and run the Docker container image.

Inside the *main* directory you need to create a new *build_run_env_nogit.sh* file  (you can copy the *build_run_env.sh.example* file and use this as a starting point). In this file you define the mandatory fixed and runtime variables (see below for the ones you need to include). This file is then *sourced* by the *build* and *run* scripts (see above).  This file is not meant to be added to the git repository as it may contain sensitive information, such as login credentials.

The user (e.g. *eouser*) who creates and runs the Docker image must also have 'docker' as one of their supplementary groups i.e.

```
sudo usermod -a -G docker eouser
```

### Fixed variables 'baked' into the Docker image

**NOTE: If the variables below are changed, the Docker image must undergo a re*build*.**

    REPO_NAME=pg93pg21
    REPO_TAG=0.1
    PGSQLVER=9.3
    PGISVER=2.1
    PG_ADMIN_USER=*name of database superuser*
    PG_ADMIN_PASSWORD=*database superuser password in plaintext*

Notes:

- REPO_NAME : use this as is, or create a Docker repo name that is unique for the host on which you are installing.
- PGSQLVER and PGISVER: do not change these unless you are *sure* you that the different versions you select are available *and* usable.
- The *PG_ADMIN_...* details need to be defined by yourself (consult the PostgreSQL documentation if unsure).  The admin can be used to, for example, create new users for third-party applications.

### Runtime variables

If the variables below are changed, there is no need to rebuild the Docker image.

    DOCKER_BASEIMAGE=*see advanced usage*
    DOCKER_NAME=*passed as --name argument to docker run; default is the same as REPO_NAME*
    PGDATA_DIR=*database directory outside of container*
    PG_APPS_SCRIPT=*see advanced usage*
    SERVICE_PORT=*host_ip:host_port OR host_port*
    USE_APT_PROXY=*see advanced usage*

Notes:

- PGDATA_DIR: This must be an existing directory which could be located anywhere on the host. If one does not exist, you may create it in a suitable location. It is strongly recommended that the directory is located *outside* of this git repository.  If, for some reason, the host already contains a PostgreSQL data directory, you can set that directory to be used instead. One option is simply to use or create the "default" directory for a standard Ubuntu install which is */var/lib/postgresql/9.3/data/*.
- SERVICE_PORT: This follows the Docker approach of mapping a port that will be accessible on the server, to one that is used internally by Docker  (see http://docs.docker.io/use/port_redirection/#port-redirection). So, for example, if you set *10342* as the port, this would equate, at Docker runtime, to a setting of *-p 10342:5432*. The actual port you use should be chosen in consultation with the host administrator so as to avoid clashes or conflicts with other services.
- SSH_PORT: This follows the Docker approach of mapping a port that will be accessible on the server, to one that is used internally by Docker  (see http://docs.docker.io/use/port_redirection/#port-redirection). So, for example, if you set *2222* as the port, this would equate, at Docker runtime, to a setting of *-p 2222:22*. The actual port you use should be chosen in consultation with the host administrator so as to avoid clashes or conflicts with other services.
- HOME_DIR : an existing full directory path outside the container which will be mounted as the **HOME** directory of the *virtual user* (APPUSER) defined in the Docker image. This can be used by third-party apps as needed.

## Advanced Usage

6. To run commands on the database server as superuser:

    ```
    # Use password defined in build_run_env when prompted
    ssh {APPUSER}@localhost -p {SSH_PORT} 
    sudo su - postgres 
    psql {database} -f {adhoc_script}
    ```

7. To run any bootstrap commands as soon as Postgresql server starts up, set environment variable PG_APPS_SCRIPT to the name of your executable script (without directory path) in build_run_env, and store the script in *main* subdirectory. This script will be executed in Bash shell with the effective user-id of the database superusersh after the Postgresql server has started up each time the Docker container runs. An example of such a script:

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

8. To use a proxy server for all apt-get operations during docker build, e.g. *http://proxy.example.com:3142/*, define USE_APT_PROXY as follows:

```
USE_APT_PROXY=$(cat <<'END_HEREDOC'
RUN echo 'Acquire::http { Proxy "http://proxy.example.com:3142/"; };' >/etc/apt/apt.conf.d/71-apt-cacher-ng
END_HEREDOC
)
```

9. To use an alternative docker base image other than the default from http://index.docker.io/, define DOCKER_BASEIMAGE. For example:

```
DOCKER_BASEIMAGE="dockerreg:5000/fynbosfire_ubuntu_trusty"
```

    - The Dockerfile used to build this container pulls the base image from a private docker registry by the hostname **dockerreg** and port **5000**

    - Doing so allows a container to be built without Internet connectivity as long as a docker registry service is accessible and it has a cached copy of the required base image. The other benefit is faster build time.

    - For example, while in Meraka office, you could add the following entry to /etc/hosts on the computer used to build the container. The IP address belongs to *barge.dhcp.meraka.csir.co.za* which is running a private [docker-registry](https://github.com/docker/docker-registry):
    ```
    146.64.19.209 dockerreg
    ```
    - For project-specific deployment using a private registry, e.g. Fynbos Fire, *dockerreg:5000/fynbosfire_ubuntu_trusty* the docker image *fynbosfire_ubuntu_trusty* must have been pushed to the private registry prior to running docker build.


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
