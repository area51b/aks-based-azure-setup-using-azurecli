#!/bin/bash

# ---------------------------------------------------------------------------
# This is run script... TODO

# Usage: run.sh [OPTIONS]
# Options
#  -c, --command     Command for script [deploy | destroy]
#  -e, --env         Environment for the script [staging | production]
#  -l, --log         Print log to file
#  -s, --strict      Exit script with null variables.  i.e 'set -o nounset'
#  -d, --debug       Runs script in BASH debug mode (set -x)
#  -h, --help        Display this help and exit
#      --version     Output version information and exit
# Example
#  ./run.sh -c deploy -e staging -l
#  ./run.sh -c destroy -e staging -l
# ---------------------------------------------------------------------------

version="1.0.0"               # Sets version variable

# Provide a variable with the location of this script.
scriptPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# trapCleanup Function
# -----------------------------------
# Any actions that should be taken if the script is prematurely
# exited.
# -----------------------------------
function trapCleanup() {
  echo ""
  echo '##################'
  echo '# Get Epoch Time #'
  echo '##################'
  echo ${epoch}
  echo $(date)

  az account clear
}

# safeExit
# -----------------------------------
# Non destructive exit for when script exits naturally.
# -----------------------------------
function safeExit() {
  trap - INT TERM EXIT
  exit
}

# Set Flags
# -----------------------------------
# Flags which can be overridden by user input.
# Default values are below
# -----------------------------------
command=
env=staging
printLog=false
strict=false
debug=false
args=()

function mainScript() {

  case "${command}" in
  'deploy')
    source ${scriptPath}/scripts/deploy.sh
    ;;
  'destroy')
    source ${scriptPath}/scripts/destroy.sh
    ;;
  esac
  exit 0
}

############## Begin Options and Usage ###################

# Print usage
usage() {
  echo -n " run.sh [OPTIONS]

 ${bold}Options:${reset}
  -c, --command     Command for script [deploy | destroy]. This is mandatory.
  -e, --env         Environment for the script [staging | production]
  -l, --log         Print log to file
  -s, --strict      Exit script with null variables.  i.e 'set -o nounset'
  -d, --debug       Runs script in BASH debug mode (set -x)
  -h, --help        Display this help and exit
      --version     Output version information and exit

 ${bold}Example:${reset}
 ./run.sh -c deploy -e staging
"
}

# Iterate over options breaking -ab into -a -b when needed and --foo=bar into
# --foo bar
optstring=h
unset options
while (($#)); do
  case $1 in
    # If option is of type -ab
    -[!-]?*)
      # Loop over each character starting with the second
      for ((i=1; i < ${#1}; i++)); do
        c=${1:i:1}

        # Add current char to options
        options+=("-$c")

        # If option takes a required argument, and it's not the last char make
        # the rest of the string its argument
        if [[ $optstring = *"$c:"* && ${1:i+1} ]]; then
          options+=("${1:i+1}")
          break
        fi
      done
      ;;

    # If option is of type --foo=bar
    --?*=*) options+=("${1%%=*}" "${1#*=}") ;;
    # add --endopts for --
    --) options+=(--endopts) ;;
    # Otherwise, nothing special
    *) options+=("$1") ;;
  esac
  shift
done
set -- "${options[@]}"
unset options

# Print help if no arguments were passed.
[[ $# -eq 0 ]] && set -- "--help"

# Read the options and set stuff
while [[ $1 = -?* ]]; do
  case $1 in
    -h|--help) usage >&2; safeExit ;;
    --version) echo "$(basename $0) ${version}"; safeExit ;;
    -c|--command) shift; command=${1} ;;
    -e|--env) shift; env=${1} ;;
    -l|--log) printLog=true ;;
    -s|--strict) strict=true;;
    -d|--debug) debug=true;;
    --endopts) shift; break ;;
    *) echo "invalid option: '$1'."; safeExit ;;
  esac
  shift
done

# Command is mandatory input
[ -z "${command}" ] && echo "ERROR: Command is missing." && echo && usage >&2 && safeExit

# Store the remaining part as arguments.
args+=("$@")

# Source Scripting Utilities
envVariables="${scriptPath}/parameters/env-${env}.sh"

if [ -f "${envVariables}" ]; then
  source "${envVariables}"
else
  echo "Please find the file env.sh and add a reference to it in this script. Exiting."
  exit 1
fi

# Logging
# -------------------------------------------
# Log is only used when the '-l' flag is set.
# -------------------------------------------
epoch=$(date +%s)dv
logFile="${scriptPath}/logs/${command}_${env}_${epoch}.log"
if ${log}; then
  exec > >(tee -i ${logFile})
  exec 2>&1
fi

############## End Options and Usage ###################

# ############# ############# #############
# ##       TIME TO RUN THE SCRIPT        ##
# ############# ############# #############

# Trap bad exits with your cleanup function
trap trapCleanup EXIT INT TERM

# Set IFS to preferred implementation
IFS=$'\n\t'

# Exit on error. Append '||true' when you run the script if you expect an error.
set -o errexit

# Run in debug mode, if set
if ${debug}; then set -x ; fi

# Exit on empty variable
if ${strict}; then set -o nounset ; fi

set -o pipefail

echo 'Start Time:' $(date)

# Run the script
mainScript

# Exit cleanlyd
safeExit