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

    # Copy everything to $SL_TMPDIR that the model needs to run.  Exclude files
    # created by the PEST manager for example since they are not needed by the
    # agent or model and can be large.  Also exclude the beopest_screens
    # directory since it can be large and is not needed by the agent or model.
    #
    # Use ionice to reduce the priority of the copy operation so it doesn't
    # overload the system since when starting there will be simultaneously many
    # agents copying files.
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
