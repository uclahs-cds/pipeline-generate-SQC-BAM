#!/bin/bash
function md5_txt {
    cat "$1" | grep -v '^#' | md5sum | cut -f 1 -d ' '
}

received=$(md5_txt "$1")
expected=$(md5_txt "$2")

if [ "$received" == "$expected" ]; then
    echo "Non-header text is equal"
    exit 0
else
    echo "Text files are not equal" >&2
    exit 1
fi
