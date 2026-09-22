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

has_add_or_sub=0

for ((i = data_count + 1; i < ${#lines[@]}; i++)); do
    line="${lines[i]}"

    [[ -z "${line//[[:space:]]/}" ]] && continue

    IFS=',' read -r operation reg operand <<< "$line"

    operation="${operation//[[:space:]]/}"
    reg="${reg//[[:space:]]/}"
    operand="${operand//[[:space:]]/}"

    case "$operation" in
        LOAD)
            opcode=4
            ;;
        STORE)
            opcode=8
            ;;
        ADD)
            opcode=12
            has_add_or_sub=1
            ;;
        SUB)
            opcode=16
            has_add_or_sub=1
            ;;
        QUIT)
            opcode=32
            ;;
        PRINT)
            opcode=36
            ;;
        *)
            rm -f "$output"
            echo "usage: unknown instruction $operation"
            exit 1
            ;;
    esac

    first_byte=$((opcode + reg))

    write_byte "$first_byte"
    write_byte "$operand"
done

