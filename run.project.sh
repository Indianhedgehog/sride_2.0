#!/usr/bin/env bash
#
# Snakemake launcher from Solida
#

usage="$(basename "$0") [-h] [-s SNAKEFILE] -c FILENAME [-w DIR] [-p \"parameters\"] --script to execute a snakemake workflow

where:
    -h  show this help text
    -s  different snakefile name from standard Snakefile
    -c  path to the snakemake's configuration file.
    -w  is the project's workdir label. Default is current timestamp.
    -p  snakemake parameters as \"--rerun-incomplete --dryrun --keep-going --profile label_of_cluster_profile\"
"

while getopts ':hc:p:w:s:' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    s) SNAKE_FILE=$OPTARG
       ;;
    c) CONFIG_FILE=$OPTARG
       ;;
    w) SM_WORK_DIR=$OPTARG
       ;;
    p) SM_PARAMETERS=$OPTARG
       ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
    *) echo "$usage"
       exit
  esac
done
shift $((OPTIND - 1))

[ -z ${SM_WORK_DIR:=$(date +%F_%s)} ]

if [ ! -d ${SM_WORK_DIR} ]; then
  # Control will enter here if $DIRECTORY doesn't exist.
  mkdir ${SM_WORK_DIR}
fi


if [ -f "$CONFIG_FILE" ]
then
   CONFIG_FILEPATH=$(readlink -e "${CONFIG_FILE}")
   echo "Running snakemake with ${CONFIG_FILEPATH} on $(pwd)/${SM_WORK_DIR}"
else
   echo "${CONFIG_FILE} config file not found"
   echo "$usage" >&2
   exit 1
fi

if [ -f ".git_repo_last_commit" ]
then
   cp .git_repo_last_commit "${SM_WORK_DIR}"
fi

PROJECT_NAME="pal"
source activate ${PROJECT_NAME}

SHORTNAME=${PROJECT_NAME:0:1}${PROJECT_NAME: -1}

if [ -f "$SNAKE_FILE" ]
then
   SNAKEFILE=$SNAKE_FILE
else
   SNAKEFILE="Snakefile"
fi

snakemake --snakefile ${SNAKEFILE} \
      --use-conda \
      --stats "stats_"${SM_WORK_DIR}".json" \
      --configfile ${CONFIG_FILEPATH} \
      --directory ${SM_WORK_DIR} \
      --printshellcmds \
      --restart-times 3 \
      --jobname ${SHORTNAME}".{rulename}.{jobid}.sh" \
      --jobs 200 \
      ${SM_PARAMETERS}

 
          

