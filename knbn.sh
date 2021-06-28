#!/bin/bash

knbn_directory="/opt/knbnBrd"
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

case $1 in
    "add"|"-a"|"--add")
        add_column="${2// /_}" #Replace all spaces with an underscore to prevent catastrophic failure
        [[ -z "$3" ]] && add_column="nocat" #Default to nocat if 3rd argument is empty
        printf "%s\\n" "tmp> $3" >> "$knbn_board/${add_column,,}" #Add task to column
        regenerate_numbers "$add_column" #Generate ids
        knbn "ls"
    ;;
    "nt"|"-n"|"--note")
        if ! [[ -z "$2" && -z "$3" && -z "$4" ]]; then
            nt_column="${2,,}" #Make all characters lowercase
            nt_column="${nt_column// /_}" #Replace all spaces with an underscore to prevent catastrophic failure
            task_line="$(grep -n "${3}> " "$knbn_board/$nt_column")" #Get entire string prepended by line nr
            task_line="${task_line:0:3}" #Extract line number from string
            task_line=$(( ${task_line%:*} + 1 ))
            check_next_line="$(sed -n "${task_line}p" "$knbn_board/$nt_column")" #Get string of next line
            while [[ ${check_next_line:0:4} == "  - " ]]; do #Check if string is a note
                task_line=$(( task_line + 1 )) 
                check_next_line="$(sed -n "${task_line}p" "$knbn_board/$nt_column")"
            done
            task_line=$(( task_line - 1 ))
            replace_line="$(sed -n "${task_line}p" "$knbn_board/$nt_column")"
            sed -i "${task_line}s_.*_${replace_line}\\n  - ${4}_" "$knbn_board/$nt_column" #Add note to line
            knbn "ls"
        fi
    ;;
    "ls"|"-l"|"--list")
        if ! [[ -z $(dir "$knbn_board") ]]; then #Check if board is empty
            ls_column="${2// /_}" #Replace all spaces with an underscore to prevent catastrophic failure
            ls_column="${ls_column,,}" #Make all characters lowercase
            [[ -z "$ls_column" ]] && ls_column="$(dir $knbn_board)" #Default to all columns if 2nd argument is empty
            for column in ${ls_column//,/ }; do
                file="$(< "$knbn_board/$column")" #Get file contents of column
                for task in ${file// /<}; do
                    text="|   $task "
                    [[ ${#text} -gt $lsL ]] && lsL=${#text} #Check if line is longest
                done
                text="| $column: "
                [[ ${#text} -gt $lsL ]] && lsL=${#text}
            done
            printf -v "border" "%-${lsL}s+" "+" #Insert border string into variable
            for column in ${ls_column//,/ }; do
                printf "%s\\n" "${border// /-}" #Print border
                printf "%-${lsL}s|\\n" "| ${column//_/ }:" #Print column name
                file="$(< "$knbn_board/$column")" #Get file contents of column
                for task in ${file// /<}; do
                    task="${task//>/:}"
                    printf "%-${lsL}s|\\n" "|   ${task//</ }" #Print task and note
                done
            done
            printf "%s\\n" "${border// /-}"
        else
            printf "%s\\n" "The board is empty"
        fi
    ;;
    "mv"|"-m"|"--move")
        if ! [[ -z "$2" && -z "$3" && -z "$4" ]]; then #Check if 3rd and 4th arguments are empty
            old_column="${2,,}"
            old_column="${old_column// /_}"
            new_column="${3// /_}"
            if [[ -f "$knbn_board/$old_column" ]]; then #Check if old column exists
                if grep -q "$4> " "$knbn_board/$old_column"; then #Check if task exists in old column
                    task_string="$(grep "$4> " "$knbn_board/$old_column")" #Get task string excluding the line nr
                    task_line=$(grep -n "$4> " "$knbn_board/$old_column")
                    task_line=${task_line:0:3} #Extract line nr
                    printf "%s\\n" "${task_string/*> /tmp> }" >> "$knbn_board/${new_column,,}" #Insert task into new column with temporary ID
                    rm_notes "$((${task_line%:*}+1))" "$old_column" "${new_column,,}"
                    sed -i "/${4}> /d" "$knbn_board/$old_column" #Delete task from old column
                    file="$(< "$knbn_board/$old_column")"
                    [[ -z $file ]] && rm "${knbn_board:?}/$old_column"
                    regenerate_numbers "$old_column"
                    regenerate_numbers "$new_column"
                    knbn "ls"
                fi
            fi
        fi
    ;;
    "rm"|"-d"|"--remove") #Syntax: knbn rm column task_id
        if ! [[ -z "$2" &&  -z "$2" ]]; then
            rm_column="${2,,}" #Make all characters lowercase
            rm_column="${rm_column// /_}" #Replace all spaces with an underscore to prevent catastrophic failure
            note_line="$(grep -n "$3> " "$knbn_board/$rm_column")"
            note_line=${note_line:0:3}
            grep -q "$3> " "$knbn_board/$rm_column" && \
                rm_notes "$((${note_line%:*}+1))" "$rm_column" && \
                sed -i "/${3}> /d" "$knbn_board/$rm_column" #Delete notes first, then tasks if id exists in column
            file="$(< "$knbn_board/$rm_column")" #Get file contents of column
            [[ -z $file ]] && rm "${knbn_board:?}/$rm_column" #Delete file if column is empty
            regenerate_numbers "$rm_column" #Regenerate ids
            knbn "ls"
        fi
    ;;
    "rmnt"|"-r"|"--remove-note")
        if ! [[ -z "$2" && -z "$3" && -z "$4" ]]; then
            rmnt_column="${2,,}" #Make all characters lowercase
            rmnt_column="${rmnt_column// /_}" #Replace all spaces with an underscore to prevent catastrophic failure
            if grep -q "$3> " "$knbn_board/$rmnt_column"; then #Check if id exists in column
                task_line=$(grep -n "${3}> " "$knbn_board/$rmnt_column") #Get string of id prepended by line nr
                task_line=${task_line:0:3} #Extract line nr
                note_line=$(( ${task_line%:*} + $4 )) #Adjust line number from task to note
                get_note="$(sed -n "${note_line}p" "$knbn_board/$rmnt_column")" #Get string of line
                [[ ${get_note:0:4} == "  - " ]] && \
                    sed -i "${note_line}d" "$knbn_board/$rmnt_column" #Delete note if the line being check is a note
                knbn "ls"
            fi
        else
            printf "%s\\n" "Syntax: knbn rmnt [column] [task id] [line offset]"
        fi
    ;;
    "wipe"|"-w"|"--wipe")
        wipe_column="${2,,}" #Make all characters lowercase
        [[ -f "$knbn_board/${wipe_column// /_}" ]] && rm "$knbn_board/${wipe_column// /_}" #Delete column if it exists
        knbn "ls"
    ;;
    "backup"|"-b"|"--backup")
        if ! [[ -z "$2" ]]; then
            cp -r "$knbn_board/." "$2" #Copy all columns to specified path
            printf "%s\\n" "All columns have been saved to $2"
        fi
    ;;
    "restore"|"-R"|"--restore")
        if ! [[ -z "$2" ]]; then
            read -r -s -p "Are you sure you want to restore from backup? This will remove everything from the board. (y/N)" -n 1 CONFIRM
            printf "%s\\n" ""
            [[ ${CONFIRM,,} == "y" ]] && \
                rm -rf "${knbn_board:?}/*" && \
                cp -r "$2/." "$knbn_board" #Delete all columns then copy all columns in backup folder to board
            printf "%s\\n" "knbnBrd has restored from $2"
        fi
    ;;
    "uninstall"|"-u"|"--uninstall") #Uninstall knbnBrd entirely
        rm -rf /opt/knbnBrd
        rm /usr/bin/knbn
    ;;
    "license"|"-L"|"--license")
        printf "\\n%s\\n" "$(< $LICENSE)" #Print the license
    ;;
    "notice"|"-N"|"--notice")
        printf "\\n%s\\n" "$(< $NOTICE)" #Print the notice
        printf "\\n%s\\n\\nv2.0\\n\\n" "Type knbn license to view the entire license, knbn help to view options"
    ;;
    "examples"|"-e"|"--examples")
        printf "\\n%s\\n" "$(< $EXAMPLES)" #Print the examples
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
