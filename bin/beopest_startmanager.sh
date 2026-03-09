#!/bin/bash

# The first command line argument is the pst file

export BEOPEST_PESTFILE=${PWD:?}/${1}
export BEOPEST_PESTFILE_LOCAL=${1}

# Make a script that a agent can use to stop the manager
COPY_FAILED_AGENT=$(hostname).$$.sh
export COPY_FAILED_AGENT
failedagent=failed_agent
failedagentpath="${PWD:?}/${failedagent}.${SLURM_JOB_ID}"
echo mkdir "${failedagentpath}" > "${COPY_FAILED_AGENT}"
echo cp \* "${failedagentpath}" >> "${COPY_FAILED_AGENT}"
chmod a+x "${COPY_FAILED_AGENT}"

cleanup() {
    if [[ ${DELETE_TMP_PST} ]]; then
        rm "$(basename ${DELETE_TMP_PST} .pst)".*
    fi

    rm -f "${QPEST_RUNNING}"

    # Remove the program that the agent can use to kill the manager
    rm -f "${COPY_FAILED_AGENT}"

    # If /i option was used remove interactive input file
    rm -f "${INAME}"
}
trap cleanup EXIT

# Establish network port that the manager will use
read -r LOWERPORT UPPERPORT < /proc/sys/net/ipv4/ip_local_port_range
while :
do
    PORT="$(shuf -i "$LOWERPORT"-"$UPPERPORT" -n 1)"
    ss -ltn4 | grep -q ":${PORT} " || break
done

export BEOPEST_PORT=${PORT}

BEOPEST_HOST=$(hostname)
export BEOPEST_HOST
BEOPEST_MANAGERJOBID=${SLURM_JOB_ID}
BEOPEST_MANAGERJOBID=${BEOPEST_MANAGERJOBID:-${PBS_JOBID}}

# run pest
echo "${MANAGERFNAME} ${BEOPEST_PESTFILE} ${PEST_OPTIONS} ${MANAGERFLAG}${BEOPEST_PORT}"
if [ -z "${INAME}" ]; then
    ${MANAGERFNAME} ${BEOPEST_PESTFILE_LOCAL} ${PEST_OPTIONS} ${MANAGERFLAG}${BEOPEST_PORT} &
else
    ${MANAGERFNAME} ${BEOPEST_PESTFILE_LOCAL} ${PEST_OPTIONS} ${MANAGERFLAG}${BEOPEST_PORT} < ${INAME} &
fi

# sleep a little to make sure the manager is started before starting the agents
sleep 1

# If any ${failedagent} directories exist, delete...
rm -rf "${PWD:?}/${failedagent}"*

# start the agents as task jobs, limited to the optimum number of agents
agent_output=agent_output
rm -rf ${agent_output}
mkdir ${agent_output}

if [ "${PLATFORM}" == "slurm" ]; then
    cmd_agent="\
        sbatch                           \
        --ntasks 1                       \
        --ntasks-per-core 1              \
        --job-name=bp_agent              \
        --partition=${PEST_AGENTS_QUEUE} \
        --oversubscribe                  \
        --distribution cyclic            \
        --array=1-${BEOPEST_NUMAGENTS}   \
        --output="${PWD:?}/${agent_output}/out_%x_%j.txt" \
        --error="${PWD:?}/${agent_output}/err_%x_%j.txt"  \
        beopest_startagent.sh"
elif [ "${PLATFORM}" == "pbs" ]; then
    cmd_agent="\
        qsub                      \
        --ppn 1                   \
        -N bp_agent               \
        -q ${PEST_AGENTS_QUEUE}   \
        -J 1-${BEOPEST_NUMAGENTS} \
        -o "${PWD:?}/${agent_output}/out_%x_%j.txt" \
        -e "${PWD:?}/${agent_output}/err_%x_%j.txt" \
        beopest_startagent.sh"
fi

arr=$(${cmd_agent})

# wait until manager as a child process is done
wait

if [ -f qpest_cleanup.sh ]; then
    sh qpest_cleanup.sh
fi

scancel ${arr}
