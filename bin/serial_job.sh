#!/bin/bash

#SBATCH --error slurm_stderr.%x.%j.txt
#SBATCH --output slurm_stdout.%x.%j.txt

umask 002

# These have to match what is in the #SBATCH pseudo-comments above.
ERRORNAME=slurm_stderr.${SLURM_JOB_NAME}.${SLURM_JOB_ID}.txt
OUTFILENAME=slurm_stdout.${SLURM_JOB_NAME}.${SLURM_JOB_ID}.txt

mtype=$(file --mime-type -b "$1")
case ${mtype} in
    text/x-shellscript) bash $@ ;;
    text/x-python) python $@ ;;
    application/x-executable) $@ ;;
    text/plain)
        case $1 in
            *.py) python $@ ;;
            *.sh) bash $@ ;;
            *) $@ ;;
        esac ;;
    *) $@ ;;
esac

if [ ! -s "${ERRORNAME}" ]; then
    rm -f "${ERRORNAME}"
fi

logger -s "${OUTPUT_OPTION}"
logger -s "${NOUTPUT_FILENAME}"
if [ "${OUTPUT_OPTION}" == "n" ] && [ -z "${NOUTPUT_FILENAME}" ]; then
    rm -f "${OUTFILENAME}"
elif [ -n "${NOUTPUT_FILENAME}" ]; then
    mv -f "${OUTFILENAME}" "${NOUTPUT_FILENAME}"
fi

if [ ! -s "${STDINFILE}" ]; then
    rm -f "${STDINFILE}"
fi
