#!/bin/bash

knbn_directory="~/.local/share/knbnBrd"
knbn_board="$knbn_directory/board"
LICENSE="$knbn_directory/LICENSE"
NOTICE="$knbn_directory/NOTICE"
EXAMPLES="$knbn_directory/EXAMPLES"

regenerate_numbers() { #Regenerate line numbers in given column
    if [[ -f "$knbn_board/${1,,}" ]]; then #Check if file exists
        file="$(< "$knbn_board/${1,,}")" #Gets file for selected column
        new_id=1
        for line in ${file// /<}; do
            if ! [[ ${line:0:4} == "<<-<" ]]; then #Check if line is a note
                id="${line%>*}" #Get id
                sed -i "/${id}>/s|${id}>|${new_id}>|" "$knbn_board/${1,,}" #Replace old id with new id
                new_id=$(( new_id + 1 ))
            fi
        done
    fi
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

task_line="$(grep -n "$3> " "$knbn_board/$arg_column")"
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
        [[ -z "$2" || -z "$3" || -z "$4" ]] && exit 1

        task_line=$(( task_line + 1 ))
        check_next_line="$(sed -n "${task_line}p" "$knbn_board/$arg_column")" #Get string of next line
        while [[ ${check_next_line:0:4} == "  - " ]]; do #Check if string is a note
            task_line=$(( task_line + 1 )) 
            check_next_line="$(sed -n "${task_line}p" "$knbn_board/$arg_column")"
        done
        task_line=$(( task_line - 1 ))
        replace_line="$(sed -n "${task_line}p" "$knbn_board/$arg_column")"
        sed -i "${task_line}s_.*_${replace_line}\\n  - ${4}_" "$knbn_board/$arg_column" #Add note to line
        knbn "ls"
    ;;
    "ls"|"-l"|"--list")
        [[ -z $(dir "$knbn_board") ]] && printf "%s\\n" "The board is empty" && exit 0
        [[ -z "$arg_column" ]] && arg_column="$(dir $knbn_board)" #Default to all columns if 2nd argument is empty
        for column in ${arg_column//,/ }; do
            file="$(< "$knbn_board/$column")"
            for task in ${file// /<}; do
                text="|   $task "
                [[ ${#text} -gt $lsL ]] && lsL=${#text} #Check if line is longest
            done
            text="| $column: "
            [[ ${#text} -gt $lsL ]] && lsL=${#text} #Prevents padding from being out of line if column name is shorter than the tasks
        done
        printf -v "border" "%-${lsL}s+" "+"
        for column in ${column//,/ }; do
            printf "%s\\n" "${border// /-}"
            printf "%-${lsL}s|\\n" "| ${column//_/ }:"
            file="$(< "$knbn_board/$column")"
            for task in ${file// /<}; do
                task="${task//>/:}"
                printf "%-${lsL}s|\\n" "|   ${task//</ }"
            done
        done
        printf "%s\\n" "${border// /-}"
    ;;
    "mv"|"-m"|"--move")
        [[ -z "$2" || -z "$3" || -z "$4" ]] && exit 1

        new_column="${3// /_}"

        ! [[ -f "$knbn_board/$arg_column" ]] || ! grep -q "$4> " "$knbn_board/$arg_column" && exit 1

        task_string="$(grep -n "$4> " "$knbn_board/$arg_column")" #Get task string excluding the line nr
        task_line=${task_string:0:3} #Extract line nr
        task_string=${task_string:2}
        printf "%s\\n" "${task_string//*> /tmp> }" >> "$knbn_board/${new_column,,}" #Insert task into new column with temporary ID
        rm_notes "$((${task_line%:*}+1))" "$arg_column" "${new_column,,}"
        sed -i "/${4}> /d" "$knbn_board/$arg_column" #Delete task from old column
        [[ -z "$(< "$knbn_board/$arg_column")" ]] && rm "${knbn_board:?}/$arg_column"
        regenerate_numbers "$arg_column"
        regenerate_numbers "$new_column"
        knbn "ls"
    ;;
    "rm"|"-d"|"--remove") #Syntax: knbn rm column task_id
        [[ -z "$2" || -z "$3" ]] && exit 1

        ! grep -q "$3> " "$knbn_board/$arg_column" && exit 1
        rm_notes "$((task_line+1))" "$arg_column"
        sed -i "/${3}> /d" "$knbn_board/$arg_column" #Delete notes first, then tasks if id exists in column
        [[ -z "$(< "$knbn_board/$arg_column")" ]] && rm "${knbn_board:?}/$arg_column" #Delete file if column is empty
        regenerate_numbers "$arg_column" #Regenerate ids
        knbn "ls"
    ;;
    "rmnt"|"-r"|"--remove-note")
        [[ -z "$2" || -z "$3" || -z "$4" ]] && \
            printf "%s\\n" "Syntax: knbn rmnt [column] [task id] [line offset]" && exit 1

        ! grep -q "$3> " "$knbn_board/$arg_column" || ! [[ -f "$knbn_board/$arg_column" ]] && exit 1

        task_line=$(grep -n "$3> " "$knbn_board/$arg_column") #Get string of id prepended by line nr
        task_line=${task_line:0:3} #Extract line nr
        note_line=$(( ${task_line%:*} + $4 )) #Adjust line number from task to note
        get_note="$(sed -n "${note_line}p" "$knbn_board/$arg_column")" #Get string of line
        [[ ${get_note:0:4} == "  - " ]] && \
            sed -i "${note_line}d" "$knbn_board/$arg_column" #Delete note if the line being check is a note
        knbn "ls"
    ;;
    "wipe"|"-w"|"--wipe")
        [[ -f "$knbn_board/$arg_column" ]] && rm "$knbn_board/$arg_column" #Delete column if it exists
        knbn "ls"
    ;;
    "backup"|"-b"|"--backup")
        [[ -z "$2" ]] && exit 1
        cp -r "$knbn_board/." "$2" #Copy all columns to specified path
        printf "%s\\n" "All columns have been saved to $2"
    ;;
    "restore"|"-R"|"--restore")
        [[ -z "$2" ]] && exit 1
        read -r -s -p "Are you sure you want to restore from backup? This will remove everything from the board. (y/N)" -n 1 CONFIRM
        printf "%s\\n" ""
        [[ ${CONFIRM,,} == "y" ]] && \
            rm -rf "${knbn_board:?}/*" && \
            cp -r "$2/." "$knbn_board" #Delete all columns then copy all columns in backup folder to board
        printf "%s\\n" "knbnBrd has restored from $2"
    ;;
    "uninstall"|"-u"|"--uninstall")
        rm -rf /opt/knbnBrd
        rm /usr/bin/knbn
    ;;
    "license"|"-L"|"--license")
        printf "\\n%s\\n" "$(< $LICENSE)"
    ;;
    "notice"|"-N"|"--notice")
        printf "\\n%s\\n" "$(< $NOTICE)"
    ;;
    "examples"|"-e"|"--examples")
        printf "\\n%s\\n" "$(< $EXAMPLES)"
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
        printf "  %s\\n    %s\\n\\n" "examples, -e, --examples" "Print examples"
    ;;
esac