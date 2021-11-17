#!/bin/bash

# Copyright 2013-2017 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# This script can help you download and run a script from S3 using aws-cli.
# It can also download a zip file from S3 and run a script from inside.
# See below for usage instructions.

PATH="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
BASENAME="${0##*/}"

usage () {
  if [ "${#@}" -ne 0 ]; then
    echo "* ${*}"
    echo
  fi
  cat <<ENDUSAGE
Usage:

export BATCH_FILE_URL="s3://my-bucket/my-script"
export LOG_S3_URL="s3://log-bucket/"
${BASENAME} script-from-s3 [ <script arguments> ]
ENDUSAGE

  exit 2
}

# Standard function to print an error and exit with a failing return code
error_exit () {
  echo "${BASENAME} - ${1}" >&2
  exit 1
}


if [ -z "${BATCH_FILE_URL}" ]; then
  usage "BATCH_FILE_URL not set. No object to download."
fi

# Check that necessary programs are available
which aws >/dev/null 2>&1 || error_exit "Unable to find AWS CLI executable."
which unzip >/dev/null 2>&1 || error_exit "Unable to find unzip executable."

# Create a temporary directory to hold the downloaded contents, and make sure
# it's removed later, unless the user set KEEP_BATCH_FILE_CONTENTS.
cleanup () {
   if [ -z "${KEEP_BATCH_FILE_CONTENTS}" ] \
     && [ -n "${TMPDIR}" ] \
     && [ "${TMPDIR}" != "/" ]; then
      rm -r "${TMPDIR}"
   fi
}
trap 'cleanup' EXIT HUP INT QUIT TERM
# mktemp arguments are not very portable.  We make a temporary directory with
# portable arguments, then use a consistent filename within.
TMPDIR="$(mktemp -d -t tmp.XXXXXXXXX)" || error_exit "Failed to create temp directory."
TMPFILE="${TMPDIR}/batch-file-temp"
CUR_DATE=$(date +'%Y-%m-%d')
install -m 0600 /dev/null "${TMPFILE}" || error_exit "Failed to create temp file."

# Fetch and run a script
fetch_and_run_script () {
  # Create a temporary file and download the script
  curl -qfsL ${BATCH_FILE_URL} > "${TMPFILE}" || error_exit "Failed to download startup script."
  # Make the temporary file executable and run it with any given arguments
  local script="./${1}"; shift
  chmod u+x "${TMPFILE}" || error_exit "Failed to chmod script."
  mkdir -p log/"${REPOSITORY}"/"${AWS_BATCH_JOB_ID}"
  ( (sh ${TMPFILE} "${@}"; echo > log/"${REPOSITORY}"/"${AWS_BATCH_JOB_ID}"/exit_code.log $?) | tee log/"${REPOSITORY}"/"${AWS_BATCH_JOB_ID}"/stdout.log) 3>&1 1>&2 2>&3 | tee log/"${REPOSITORY}"/"${AWS_BATCH_JOB_ID}"/stderr.log
  aws s3 sync log/"${REPOSITORY}" "${LOG_S3_URL}/${CUR_DATE}/${REPOSITORY}"
}

fetch_and_run_script "${@}"
