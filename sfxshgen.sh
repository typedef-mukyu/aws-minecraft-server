#!/bin/bash
# Self-extracting shell script generator
set -e
if [[ $# == 0 ]]; then
echo "Usage: $0 file1.sh [file2 ...]" >&2
exit 1
fi
arg1=$1
echo "#!/bin/bash"
while (( $# )); do
    echo "echo \"$(base64 -w 0 $1)\" | base64 -d > $1"
    shift
done
echo "chmod +x ./$arg1"
echo "./$arg1"