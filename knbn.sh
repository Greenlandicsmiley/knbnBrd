#!/bin/bash

knbn_directory="$HOME/.local/share/knbnBrd"
knbn_board="$knbn_directory/board"
LICENSE="/usr/share/doc/knbnBrd/LICENSE"
NOTICE="/usr/share/doc/knbnBrd/NOTICE"
EXAMPLES="/usr/share/doc/knbnBrd/EXAMPLES"

regenerate_numbers() { #Regenerate line numbers in given column
    ! [[ -f "$knbn_board/${1,,}" ]] && return 1 #Check if file exists
    file="$(< "$knbn_board/${1,,}")" #Gets file for selected column
    for line in ${file// /<}; do #Spaces are replaced with < to read by lines
        if ! [[ ${line:0:4} == "<<-<" ]]; then #Check if line is a note
            id="${line%>*}" #Get id
            sed -i "/${id}> /s|${id}>|${new_id:=1}>|" "$knbn_board/${1,,}" #Replace old id with new id
            new_id=$(( new_id + 1 ))
        fi
    done
}

rm_notes() {
    check_next_line="$(sed -n "${1}p" "$knbn_board/$2")" #Get string from line supplied by 1st argument
    while [[ ${check_next_line:0:4} == "  - " ]]; do
        ! [[ -z "$3" ]] && printf "%s\\n" "$check_next_line" >> "$knbn_board/$3" #Insert note into new column if 3rd argument is not empty
        sed -i "${1}d" "$knbn_board/$2" #Delete note from old column
        check_next_line="$(sed -n "${1}p" "$knbn_board/$2")"
    done
}

arg_column="${2,,}"
arg_column="${arg_column// /_}"

column_file="$knbn_board/$arg_column"

! [[ -z "$2" ]] && task_string="$(grep -n "$3> " "$column_file")"
task_line=${task_line:0:3}
task_line=${task_line%:*}

case $1 in
    "add"|"-a"|"--add")
        add_string="$3"
        [[ -z "$3" ]] && arg_column="nocat" && add_string="$2"
        printf "%s\\n" "tmp> $add_string" >> "$knbn_board/$arg_column"
        regenerate_numbers "$arg_column"
        knbn "ls"
    ;;
    "nt"|"-n"|"--note")
        ! [[ -f "$column_file" ]] || ! grep -q "$3> " "$column_file" && [[ -z "$4" || -z "$3" ]] && \
            printf "%s\\n" "Syntax: knbn nt [column] [task id] [description]" && exit 1

        check_next_line="$(sed -n "$((task_line+1))p" "$column_file")" #Get string of next line
        while [[ ${check_next_line:0:4} == "  - " ]]; do #Check if string is a note
            task_line=$(( task_line + 1 ))
            check_next_line="$(sed -n "${task_line}p" "$column_file")"
        done
        sed -i "${task_line}s_.*_${check_next_line}\\n  - ${4}_" "$column_file" #Add note to line
        knbn "ls"
    ;;
    "ls"|"-l"|"--list")
        [[ -z $(dir "$knbn_board") ]] && printf "%s\\n" "The board is empty" && exit 0 #Exit with 0 because board being empty is necessarily not an error
        [[ -z "$2" ]] && arg_column="$(dir "$knbn_board")" #Default to all columns
        for column in ${arg_column//,/ }; do #Replace comma with space to loop through selected columns
            file="$(< "$knbn_board/$column")"
            for task in ${file// /<}; do
                text="|   $task " #This is to visualize how many extra characters need to be accounted for length
                [[ ${#text} -gt $padding_length ]] && padding_length=${#text} #Set padding length to longest string
            done
            text="| $column: "
            [[ ${#text} -gt $padding_length ]] && padding_length=${#text} #Set padding length if task/note is not longer than column - this is to prevent cases where padding is not correct when column is longer than the tasks
        done
        printf -v "border" "%-${padding_length}s+" "+" #Need to store to variable to replace all whitespace with a hyphen
        for column in ${arg_column//,/ }; do
            printf "%s\\n" "${border// /-}"
            printf "%-${padding_length}s|\\n" "| ${column//_/ }:"
            file="$(< "$knbn_board/$column")"
            for task in ${file// /<}; do
                task="${task//>/:}"
                printf "%-${padding_length}s|\\n" "|   ${task//</ }"
            done
        done
        printf "%s\\n" "${border// /-}"
    ;;
    "mv"|"-m"|"--move")
        ! [[ -f "$column_file" ]] || ! grep -q "$4> " "$column_file" && [[ -z "$3" || -z "$4" ]] && \
            printf "%s\\n" "Syntax: knbn mv [old column] [new column] [task id]" && exit 1

        new_column="${3// /_}"
        task_string=${task_string:2}
        printf "%s\\n" "${task_string//*> /tmp> }" >> "$knbn_board/${new_column,,}"
        rm_notes "$(( task_line + 1 ))" "$arg_column" "${new_column,,}"
        sed -i "/${4}> /d" "$column_file"
        [[ -z "$(< "$column_file")" ]] && rm "${column_file:?}"
        regenerate_numbers "$arg_column"
        regenerate_numbers "$new_column"
        knbn "ls"
    ;;
    "rm"|"-d"|"--remove")
        ! [[ -f "$column_file" ]] || ! grep -q "$3> " "$column_file" && [[ -z "$3" ]] && \
            printf "%s\\n" "Syntax: knbn rm [column] [task id]" && exit 1

        rm_notes "$(( task_line + 1 ))" "$arg_column"
        sed -i "/${3}> /d" "$column_file"
        [[ -z "$(< "$column_file")" ]] && rm "${column_file:?}"
        regenerate_numbers "$arg_column"
        knbn "ls"
    ;;
    "rmnt"|"-r"|"--remove-note")
        ! [[ -f "$column_file" ]] || ! grep -q "$3> " "$column_file" && \
            [[ -z "$3" || -z "$4" ]] && \
            printf "%s\\n" "Syntax: knbn rmnt [column] [task id] [line offset]" && exit 1

        get_note="$(sed -n "$(( task_line + $4 ))p" "$column_file")"
        [[ ${get_note:0:4} == "  - " ]] && \
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
            printf "%s\\n" "Syntax: knbn backup [backup location]" && exit 1

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
        printf "\\n%s\\n" "Usage: knbn [option] [arguments]"
        printf "\\n%s\\n" "Tasks"
        printf "  %s\\n    %s\\n" "add, -a, --add [column] [description]" "Add a task to a column"
        printf "  %s\\n    %s\\n" "ls, -l, --list [column],..." "List tasks in selected columns"
        printf "  %s\\n    %s\\n" "ls, -l, --list" "List all tasks"
        printf "  %s\\n    %s\\n" "mv, -m, --move [old column] [new column] [task id]" "Move a task"
        printf "  %s\\n    %s\\n" "rm, -d, --remove [column] [task id]" "Delete a task from a column"
        printf "  %s\\n    %s\\n" "wipe, -w, --wipe [column]" "Delete all tasks in a column"

        printf "\\n%s\\n" "Notes"
        printf "  %s\\n    %s\\n" "nt, -n, --note [column] [task id] [description]" "Add a note to a task"
        printf "  %s\\n    %s\\n" "rmnt, -r, --remove-note [column] [task id] [line offset]" "Delete a note from a task"

        printf "\\n%s\\n" "Backup and restore"
        printf "  %s\\n    %s\\n" "backup, -b, --backup [column] [backup location]" "Backup the kanban board"
        printf "  %s\\n    %s\\n" "restore, -R, --restore [backup location]" "Restore from backup"

        printf "\\n%s\\n" "Other"
        printf "  %s\\n    %s\\n" "uninstall, -u, --uninstall" "Uninstall knbnBrd"
        printf "  %s\\n    %s\\n" "license, -L, --license" "Print license"
        printf "  %s\\n    %s\\n" "notice, -N, --notice" "Print GPLv3 notice and contact information"
        printf "  %s\\n    %s\\n" "help, -h, --help" "Print this"
        printf "  %s\\n    %s\\n" "examples, -e, --examples" "Print examples"
        printf "  %s\\n    %s\\n\\n" "--create-dir" "Create knbn board directory"
        printf "%s\\n" "Contact the author at greenlandicsmiley@gmail.com"
        printf "%s\\n\\n" "Or via reddit www.reddit.com/u/Greenlandicsmiley"
    ;;
esac