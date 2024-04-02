#!/usr/bin/env bash

# -*- mode: jinja-shell -*-

source .scripts/logging_utils.sh

set -xe

MINIFORGE_HOME=${MINIFORGE_HOME:-${HOME}/miniforge3}

( startgroup "Installing a fresh version of Miniforge" ) 2> /dev/null

MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download"
MINIFORGE_FILE="Mambaforge-MacOSX-$(uname -m).sh"
curl -L -O "${MINIFORGE_URL}/${MINIFORGE_FILE}"
rm -rf ${MINIFORGE_HOME}
bash $MINIFORGE_FILE -b -p ${MINIFORGE_HOME}

( endgroup "Installing a fresh version of Miniforge" ) 2> /dev/null

( startgroup "Configuring conda" ) 2> /dev/null

source ${MINIFORGE_HOME}/etc/profile.d/conda.sh
conda activate base
export CONDA_SOLVER="libmamba"
export CONDA_LIBMAMBA_SOLVER_NO_CHANNELS_FROM_INSTALLED=1

mamba install --update-specs --quiet --yes --channel conda-forge --strict-channel-priority \
    pip mamba rattler-build conda-forge-ci-setup=4 "conda-build>=24.1"
mamba update --update-specs --yes --quiet --channel conda-forge --strict-channel-priority \
    pip mamba rattler-build conda-forge-ci-setup=4 "conda-build>=24.1"



echo -e "\n\nSetting up the condarc and mangling the compiler."
setup_conda_rc ./ ./recipe ./.ci_support/${CONFIG}.yaml

if [[ "${CI:-}" != "" ]]; then
  mangle_compiler ./ ./recipe .ci_support/${CONFIG}.yaml
fi

if [[ "${CI:-}" != "" ]]; then
  echo -e "\n\nMangling homebrew in the CI to avoid conflicts."
  /usr/bin/sudo mangle_homebrew
  /usr/bin/sudo -k
else
  echo -e "\n\nNot mangling homebrew as we are not running in CI"
fi

if [[ "${sha:-}" == "" ]]; then
  sha=$(git rev-parse HEAD)
fi

echo -e "\n\nRunning the build setup script."
source run_conda_forge_build_setup



( endgroup "Configuring conda" ) 2> /dev/null

if [[ -f LICENSE.txt ]]; then
  cp LICENSE.txt "recipe/recipe-scripts-license.txt"
fi

if [[ "${BUILD_WITH_CONDA_DEBUG:-0}" == 1 ]]; then
      echo "rattler-build don't support debug mode right now"
else

    
      rattler-build build --recipe "${RECIPE_ROOT}" -m "${CI_SUPPORT}/${CONFIG}.yaml"

      ls -al $CONDA_BLD_PATH
    ( startgroup "Validating outputs" ) 2> /dev/null

    validate_recipe_outputs "${FEEDSTOCK_NAME}"

    ( endgroup "Validating outputs" ) 2> /dev/null

    ( startgroup "Uploading packages" ) 2> /dev/null

    if [[ "${UPLOAD_PACKAGES}" != "False" ]] && [[ "${IS_PR_BUILD}" == "False" ]]; then
      upload_package --validate --feedstock-name="${FEEDSTOCK_NAME}" ./ ./recipe ./.ci_support/${CONFIG}.yaml
    fi

    ( endgroup "Uploading packages" ) 2> /dev/null
fi