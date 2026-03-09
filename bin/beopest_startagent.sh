#!/bin/bash
shopt -s extglob

if [[ ! $RUN_PWD ]]; then
    if [ "${PLATFORM}" == "slurm" ]; then
        SL_TMPDIR=/tmp/${USER}/${SLURM_JOB_ID}
    elif [ "${PLATFORM}" == "pbs" ]; then
        SL_TMPDIR=/tmp/${USER}/${PBS_JOBID}
    fi

    cleanup() {
        rm -rf "${SL_TMPDIR}"
    }
    trap cleanup EXIT

    mkdir -p "${SL_TMPDIR}"

    # Copy everything to $SL_TMPDIR that the model needs to run.  Exclude PEST
    # files for example.
    ionice -c3                                     \
        cp                                         \
        --preserve=mode,ownership,timestamps,links \
        -r                                         \
        !(*.dap|*.de1|*.svd|*.jac|*.jcb|*.jco|*.prf|*.rec|*.res|*.rei|*.rmr|*.rnj|*.rnu|*.jst|*.rst|*.sen|*.png|*.tif|beopest_screens|agent_output) \
        "${SL_TMPDIR}"

    cd "${SL_TMPDIR}" || exit
fi

echo "${AGENTFNAME}" "${BEOPEST_PESTFILE_LOCAL}" "${AGENTFLAG}" "${BEOPEST_HOST}:${BEOPEST_PORT}"

if "${AGENTFNAME}" "${BEOPEST_PESTFILE_LOCAL}" "${AGENTFLAG}" "${BEOPEST_HOST}:${BEOPEST_PORT}"; then
    ${COPY_FAILED_AGENT}
fi
wait
