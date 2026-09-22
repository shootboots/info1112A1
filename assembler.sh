#!/usr/bin/env bash

if [[ $# -eq 0 ]]; then
    echo "usage: no argument is provided"
    exit 1
fi

if [[ $# -gt 1 ]]; then
    echo "usage: more than one arguments are provided"
    exit 1
fi 

input="$1"

if [[ ! -f "$input" ]]; then
    echo "usage: input is not a file or it does not exist"
    exit 1
fi

if [[ "$input" != *.vsc ]]; then
    echo "usage: input does not have the extension .vsc"
    exit 1
fi 

if [[ ! -s "$input" ]]; then
    echo "usage: the file is empty - no .bin file is produced"
    exit 1
fi

output="${input%.vsc}.bin"
rm -f "$output"

write_byte(){
    local value="$1"
    printf "\\$(printf '%03o' "$value")" >> "$output"
}

lines=()

while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line//$'\r'/}"
    lines[${#lines[@]}]="$line"
done < "$input"

line="${line//$'\r'/}"

data_count="${lines[0]}"

for ((i = 1; i <= data_count; i++)); do
    write_byte "${lines[i]}"
done