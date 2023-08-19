#!/bin/bash
# setup the gpinitsystem config
primary_array() {
  num_primary_segments=$1
  array=""
  newline=$'\n'
  # master has db_id 0, primary starts with db_id 1, primaries are always odd
  for i in $( seq 0 $(( num_primary_segments - 1 )) ); do
    content_id=${i}
    db_id=$(( i + 1 ))
    array+="sdw${db_id}~sdw${db_id}~6000~/gpdata/primary/gpseg${content_id}~${db_id}~${content_id}${newline}"
  done
  echo "${array}"
}

create_gpinitsystem_config() {
  num_primary_segments=$1
  echo "Generate gpinitsystem"

cat <<EOF> ./gpinitsystem_config
ARRAY_NAME="Greenplum Data Platform"
TRUSTED_SHELL=ssh
CHECK_POINT_SEGMENTS=8
ENCODING=UNICODE
SEG_PREFIX=gpseg
HEAP_CHECKSUM=on
HBA_HOSTNAMES=0
QD_PRIMARY_ARRAY=mdw~mdw~5432~/gpdata/master/gpseg-1~0~-1
declare -a PRIMARY_ARRAY=(
$( primary_array ${num_primary_segments} )
)
EOF

}
num_primary_segments=$1
if [ -z "$num_primary_segments" ]; then
  echo "Usage: bash create_gpinitsystem_config.sh <num_primary_segments>"
else
  create_gpinitsystem_config ${num_primary_segments}
fi
