#!/usr/bin/env bash
# Short script to create a md5 checksum file of the file or directory to copy to
# ADDI so the data transfered can be verified in ADDI
function help() {
    cat <<EOF
Copy files to ADDI with a MD5 checksum file to verify transfer

  -s  file or directory to copy to ADDI. You must quote the string if using wildcards
  -t  The ADDI token generated from the Upload -> Manage token page
  -r  Recursive flag, mandatory if copying a directory
  -u  Only upload the files added after TIME, formatted as "2025-05-16T12:00:00Z"
  -v  Verbosity flag
  -h  This help message

EOF
}

verbose=0
recursive=""
base_params="--skip-version-check --put-md5"
# The timestamp_filer has been added to facilitate the addition of new singularity
# images
timestamp_filter=""

while getopts "hvrs:t:u:" option; do
   case $option in
      s)
        source=$OPTARG
        ;;
      t)
        token=$OPTARG
        ;;
      u)
        timestamp_filter=$OPTARG
        ;;
      r)
        recursive="--recursive"
        ;;
      v)
        verbose=$((verbose+1))
        ;;
      h)
        help
        exit 0
        ;;                                                                                                                                                                                        *)                                                                                                                                                                                            help                                                                                                                                                                                        exit 1
        ;;
   esac
done

if [[ -z "${source}" ]] || [[ -z "${token}" ]]; then
  help
  exit 2
fi
# Create a temporary directory to store the md5 checksum file
tempdir=$(mktemp -d)
md5file="${tempdir}/$(basename ${source//\*/_}).md5"

echo "Generating the md5sum file at ${md5file}"
if [[ -d $source ]]; then
  if [[ -n "${timestamp_filter}" ]]; then
    base_params="${base_params} --include-after ${timestamp_filter}"
    for F in $(azcopy copy --dry-run $base_params $recursive $source "${token}" | grep DRYRUN | cut -f3); do
      echo "${timestamp_filter} $F"
      md5sum $F >> $md5file
    done
    if [[ ! -s $md5file ]]; then
      echo "No file found with a timestamp after ${timestamp_filter}"
      exit 0
    fi
  else
    # It cannot use -execdir as we would loose the full path to the file
    find $source -type f -exec md5sum {} \; >> $md5file
  fi
  parent=$(dirname $source)
  if [[ "$parent" != "." ]]; then
    sed -i "s'$parent/''" $md5file
  fi
else
  md5sum $source > $md5file
  recursive=""
fi

if [[ $verbose -eq 0 ]]; then
  base_params="${base_params} --output-level quiet"
elif [[ $verbose -eq 1 ]]; then
  base_params="${base_params} --output-level essential"
fi

# If all azcopy commands are successful, we delete the temp directory
echo "Copying the files to ADDI"
azcopy copy $base_params $md5file "${token}" && \
azcopy copy $base_params $recursive "$source" "${token}" && \
rm -rf ${tempdir} && \
echo "Done!"