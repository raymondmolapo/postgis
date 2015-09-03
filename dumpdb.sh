#!/bin/bash
#
# Dump all local databases. This script is to be run by user 'postgres'
#
today=$(date +%Y%m%d)
if [ $# -ne 1 ] || [ ! -d "$1" ]; then
  echo "usage: $0 existing_archive_directory" >&2
  exit 1
fi
# local dir where the backups go
myDir="$1"
# 20140725 rvddool - using custom format now: http://www.commandprompt.com/blogs/joshua_drake/2010/07/a_better_backup_with_postgresql_using_pg_dump/
function backup_pgsql {
  # Dump roles
  pg_dumpall --roles-only -f $myDir/roles-${today}.sql
  # Dump schema-only especially GRANTS
  pg_dump --schema-only -f $myDir/schema-${today}.sql
  for db in `psql -qtc '\l' | cut -f1 -d\| | grep -v '^[ ]*template[01]' | sed '/^[ ]*$/d'`; do
    mkdir -p $myDir/${db}
    pg_dump -Fc $db -f $myDir/${db}/${db}-${today}.dmp
  done
}
backup_pgsql
