#!/usr/bin/env bash

# PLEASE NOTE: This script has been automatically generated by conda-smithy. Any changes here
# will be lost next time ``conda smithy rerender`` is run. If you would like to make permanent
# changes to this script, consider a proposal to conda-smithy so that other feedstocks can also
# benefit from the improvement.

# -*- mode: jinja-shell -*-

set -xeuo pipefail
export FEEDSTOCK_ROOT="${FEEDSTOCK_ROOT:-/home/conda/feedstock_root}"
source ${FEEDSTOCK_ROOT}/.scripts/logging_utils.sh


( endgroup "Start Docker" ) 2> /dev/null

( startgroup "Configuring conda" ) 2> /dev/null

export PYTHONUNBUFFERED=1
export RECIPE_ROOT="${RECIPE_ROOT:-/home/conda/recipe_root}"
export CI_SUPPORT="${FEEDSTOCK_ROOT}/.ci_support"
export CONFIG_FILE="${CI_SUPPORT}/${CONFIG}.yaml"


mamba install --update-specs --yes --quiet --channel conda-forge --strict-channel-priority \
    pip rattler-build mamba conda-build conda-forge-ci-setup=4 "conda-build>=24.1"
mamba update --update-specs --yes --quiet --channel conda-forge --strict-channel-priority \
    pip rattler-build mamba conda-build conda-forge-ci-setup=4 "conda-build>=24.1"



# make the build number clobber
make_build_number "${FEEDSTOCK_ROOT}" "${RECIPE_ROOT}" "${CONFIG_FILE}"



( endgroup "Configuring conda" ) 2> /dev/null

if [[ -f "${FEEDSTOCK_ROOT}/LICENSE.txt" ]]; then
  cp "${FEEDSTOCK_ROOT}/LICENSE.txt" "${RECIPE_ROOT}/recipe-scripts-license.txt"
fi

if [[ "${BUILD_WITH_CONDA_DEBUG:-0}" == 1 ]]; then
    if [[ "x${BUILD_OUTPUT_ID:-}" != "x" ]]; then
        EXTRA_CB_OPTIONS="${EXTRA_CB_OPTIONS:-} --output-id ${BUILD_OUTPUT_ID}"
    fi
    conda debug "${RECIPE_ROOT}" -m "${CI_SUPPORT}/${CONFIG}.yaml" \
        ${EXTRA_CB_OPTIONS:-} \
        --clobber-file "${CI_SUPPORT}/clobber_${CONFIG}.yaml"

    # Drop into an interactive shell
    /bin/bash
else
    rattler-build build --recipe "${RECIPE_ROOT}" -m "${CI_SUPPORT}/${CONFIG}.yaml"
fi

( startgroup "Final checks" ) 2> /dev/null

touch "${FEEDSTOCK_ROOT}/build_artifacts/conda-forge-build-done-${CONFIG}"