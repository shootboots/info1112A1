#!/usr/bin/env bash

# checks if no arguments were given
if [[ $# -eq 0 ]]; then
    echo "usage: no argument is provided"
    exit 1
fi

# checks if more than one argument was given
if [[ $# -gt 1 ]]; then
    echo "usage: more than one arguments are provided"
    exit 1
fi 

# stores the first argument as the input file
input="$1"

# checks that the input exists and is a regular file
if [[ ! -f "$input" ]]; then
    echo "usage: input is not a file or it does not exist"
    exit 1
fi

# checks that the input file ends in vsc
if [[ "$input" != *.vsc ]]; then
    echo "usage: input does not have the extension .vsc"
    exit 1
fi 

# checks that the input file is not empty
if [[ ! -s "$input" ]]; then
    echo "usage: the file is empty – no .bin file is produced"
    exit 1
fi

# removes the vsc extension and replaces it with bin
output="${input%.vsc}.bin"

# removes an old output file so new bytes are not added onto it
rm -f "$output"

# function that writes one value as an actual byte into the bin file
write_byte(){

    # stores the value passed into the function
    local value="$1"

    # converts the decimal value to octal so printf can write it as a raw byte
    # the double greater than signs append each new byte to the output file
    printf "\\$(printf '%03o' "$value")" >> "$output"
}

# creates an empty array to store every line from the input file
lines=()

# reads the input file one line at a time
while IFS= read -r line || [[ -n "$line" ]]; do

    # removes carriage returns so windows style line endings do not cause problems
    line="${line//$'\r'/}"

    # adds the current line to the end of the lines array
    lines[${#lines[@]}]="$line"

done < "$input"

# this line is not really needed because carriage returns were already removed above
line="${line//$'\r'/}"

# gets the first line which tells us how many starting data values there are
data_count="${lines[0]}"

# loops through all of the starting data values
for ((i = 1; i <= data_count; i++)); do

    # writes each starting data value as a byte into the bin file
    write_byte "${lines[i]}"

done

# keeps track of whether the program contains an add or sub instruction
has_add_or_sub=0

# starts after the starting data and loops through every instruction
for ((i = data_count + 1; i < ${#lines[@]}; i++)); do

    # gets the current instruction from the array
    line="${lines[i]}"

    # skips the current loop if the line is empty
    [[ -z "${line//[[:space:]]/}" ]] && continue

    # splits the instruction at each comma into three separate parts
    # these parts are the operation register and operand
    IFS=',' read -r operation reg operand <<< "$line"

    # removes any spaces from the operation
    operation="${operation//[[:space:]]/}"

    # removes any spaces from the register
    reg="${reg//[[:space:]]/}"

    # removes any spaces from the operand
    operand="${operand//[[:space:]]/}"

    # checks which operation the instruction contains
    case "$operation" in

        # load has an opcode value of four
        LOAD)
            opcode=4
            ;;

        # store has an opcode value of eight
        STORE)
            opcode=8
            ;;

        # add has an opcode value of twelve
        ADD)
            opcode=12

            # marks the program as an add or sub program
            has_add_or_sub=1
            ;;

        # sub has an opcode value of sixteen
        SUB)
            opcode=16

            # marks the program as an add or sub program
            has_add_or_sub=1
            ;;

        # quit has an opcode value of thirty two
        QUIT)
            opcode=32
            ;;

        # print has an opcode value of thirty six
        PRINT)
            opcode=36
            ;;

        # catches anything that is not a recognised instruction
        *)
            # removes the incomplete bin file
            rm -f "$output"

            # tells the user which instruction was not recognised
            echo "usage: unknown instruction $operation"

            # stops the script with an error
            exit 1
            ;;
    esac

    # combines the opcode and register to make the first instruction byte
    first_byte=$((opcode + reg))

    # writes the first instruction byte to the bin file
    write_byte "$first_byte"

    # writes the operand as the second instruction byte
    write_byte "$operand"

done

# checks whether an add or sub instruction was found
if [[ $has_add_or_sub -eq 1 ]]; then

    # this means the program contained add or sub
    echo "It is an ADD/SUB program"

else

    # otherwise the supplied test treats it as a quit program
    echo "It is a QUIT program"

fi

# prints the heading before showing the bytes
echo "The content of the .bin file is"

# reads the bin file and displays every byte in hexadecimal on its own line
od -An -v -t x1 "$output" | tr -s ' ' '\n' | sed '/^$/d'

# exits successfully because assembly finished
exit 0
