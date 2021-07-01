#!/bin/bash

knbn_directory="$HOME/.local/share/knbnBrd"
knbn_board="$knbn_directory/board"
LICENSE="/usr/share/doc/knbnBrd/LICENSE"
NOTICE="/usr/share/doc/knbnBrd/NOTICE"
EXAMPLES="/usr/share/doc/knbnBrd/EXAMPLES"
EXAMPLES="/usr/share/doc/knbnBrd/HELP"

regenerate_numbers() { #Regenerate line numbers in given column
    ! [[ -f "$knbn_board/${1,,}" ]] && return 1
    new_id=1 #Need to set new_id to 1 so it does not carry over to the other column
    while IFS= read -r line; do
        ! [[ "$line" == "  - "* ]] && \
            sed -i "/${line%>*}> /s|${line%>*}>|${new_id}>|" "$knbn_board/${1,,}" && \
            new_id=$(( new_id + 1 ))
    done < <(grep -v '^ *#' < "$knbn_board/${1,,}")
}

get_notes() {
    end_line=$task_line
    while [[ "$(sed -n "$(( end_line + 1 ))p" "$column_file")" == "  - "* ]]; do
        end_line=$(( end_line + 1 ))
    done
    [[ "$1" == "nt" ]] && return 0
    [[ "$1" == "mv" ]] && sed -n "${task_line},${end_line}p" "$column_file" >> "$knbn_board/${new_column,,}" && \
        regenerate_numbers "$new_column"
    sed -i "${task_line},${end_line}d" "$column_file"
    [[ -z "$(< "$column_file")" ]] && rm "${column_file:?}"
    regenerate_numbers "$arg_column"
    knbn "ls"
}

check_grep() {
    [[ -z "$2" ]] && return 0 #Return 0 because it has to be successful to print syntax line and exit the script
    ! [[ -f "$column_file" ]] && return 0
    ! grep -q "${1:-mt}> " "$column_file" && return 0

    task_string="$(grep -n "$1> " "$column_file")"
    task_line="${task_string:0:3}"
    task_line="${task_line%:*}"
}

arg_column="${2,,}"
arg_column="${arg_column// /_}"
new_column="${3// /_}"
column_file="$knbn_board/$arg_column"

case $1 in
    "add"|"-a"|"--add")
        add_string="$3"
        [[ -z "$3" ]] && arg_column="nocat" && add_string="$2"
        printf "%s\\n" "tmp> $add_string" >> "$knbn_board/$arg_column"
        regenerate_numbers "$arg_column"
        knbn "ls"
    ;;
    "nt"|"-n"|"--note")
        check_grep "$3" "$4" && \
            printf "%s\\n" "Syntax: knbn nt [column] [task id] [description]" && exit 1

        get_notes "nt"
        replace_string="$(sed -n "${end_line}p" "$column_file")"
        sed -i "${end_line}s_.*_${replace_string}\\n  - ${4}_" "$column_file" #Add note to line
        knbn "ls"
    ;;
    "ls"|"-l"|"--list")
        [[ -z $(dir "$knbn_board") ]] && printf "%s\\n" "The board is empty" && exit 0 #Exit with 0 because board being empty is necessarily not an error
        [[ -z "$2" ]] && arg_column="$(dir "$knbn_board")" #Default to all columns
        for column in ${arg_column//,/ }; do #Replace comma with space to loop through selected columns
            while IFS= read -r task; do
                text="|   $task " #This is to visualize how many extra characters need to be accounted for length
                [[ ${#text} -gt $padding_length ]] && padding_length=${#text} #Set padding length to longest string
            done < <(grep -v '^ *#' < "$knbn_board/$column")
            text="| $column: "
            [[ ${#text} -gt $padding_length ]] && padding_length=${#text} #This is to prevent cases where padding is not correct when column is longer than the tasks
        done
        printf -v "border" "%-${padding_length}s+" "+" #Need to store to variable to replace all whitespace with a hyphen
        for column in ${arg_column//,/ }; do
            printf "%s\\n" "${border// /-}"
            printf "%-${padding_length}s|\\n" "| ${column//_/ }:"
            while IFS= read -r task; do
                task="${task//>/:}"
                printf "%-${padding_length}s|\\n" "|   $task"
            done < <(grep -v '^ *#' < "$knbn_board/$column")
        done
        printf "%s\\n" "${border// /-}"
    ;;
    "mv"|"-m"|"--move")
        check_grep "$4" "," && \
            printf "%s\\n" "Syntax: knbn mv [old column] [new column] [task id]" && exit 1

        get_notes "mv"
    ;;
    "rm"|"-d"|"--remove")
        check_grep "$3" "," && \
            printf "%s\\n" "Syntax: knbn rm [column] [task id]" && exit 1

        get_notes
    ;;
    "rmnt"|"-r"|"--remove-note")
        check_grep "$3" "$4" && \
            printf "%s\\n" "Syntax: knbn rmnt [column] [task id] [line offset]" && exit 1

        [[ "$(sed -n "$(( task_line + $4 ))p" "$column_file")" == "  - "* ]] && \
            sed -i "$(( task_line + $4 ))d" "$column_file" && knbn "ls"
    ;;
    "wipe"|"-w"|"--wipe")
        [[ -f "$column_file" ]] && rm "$column_file" && knbn "ls"
    ;;
    "backup"|"-b"|"--backup")
        [[ -z "$2" ]] && \
            printf "%s\\n" "Syntax: knbn backup [backup location]" && exit 1

        cp -r "$knbn_board/." "$2" && \
            printf "%s\\n" "All columns have been saved to $2"
    ;;
    "restore"|"-R"|"--restore")
        [[ -z "$2" ]] && \
            printf "%s\\n" "Syntax: knbn restore [backup location]" && exit 1

        read -r -s -p "Are you sure you want to restore from backup? This will remove everything from the board. (y/N)" -n 1 CONFIRM
        printf "%s\\n" ""
        [[ ${CONFIRM,,} == "y" ]] && \
            rm -rf "${knbn_board:?}/*" && \
            cp -r "$2/." "$knbn_board" && \
            printf "%s\\n" "knbnBrd has restored from $2"
    ;;
    "--create-dir")
        mkdir -p "$HOME/.local/share/knbnBrd/board"
    ;;
    "uninstall"|"-u"|"--uninstall")
        rm -rf "$knbn_directory"
        rm -rf "/usr/share/doc/knbnBrd"
        rm /usr/bin/knbn
    ;;
    "license"|"-L"|"--license")
        printf "\\n%s\\n" "$(< "$LICENSE")"
    ;;
    "notice"|"-N"|"--notice")
        printf "\\n%s\\n" "$(< "$NOTICE")"
    ;;
    "examples"|"-e"|"--examples")
        printf "\\n%s\\n" "$(< "$EXAMPLES")"
    ;;
    "help"|"-h"|"--help"|*)
        printf "\\n%s\\n" "$(< "$HELP")"
    ;;
esac
