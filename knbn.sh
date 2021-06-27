#!/bin/bash

knbn_directory="/opt/knbnBrd"
knbn_board="$knbn_directory/board"
LICENSE="$knbn_directory/LICENSE"
NOTICE="$knbn_directory/NOTICE"

get_column() { #Gets file for selected column
    file="$(< $knbn_board/"${1,,}")"
    file="${file// /_}"
    [[ "$2" == "," ]] && file="${file//,/_}"
}

get_lsl() { #Gets longest line in selected column
    get_column "${1,,}" #Gets file for selected column
    for task in $file; do
        text="|   ${task} "
        [[ ${#text} -gt $lsL ]] && lsL=${#text}
    done
}

ls_tasks(){ #Lists tasks in selected column
    print_border
    column_string="${1,,}"
    printf "%-${lsL}s|\\n" "| ${column_string//_/ }:" #Prints column name
    get_column "${1,,}" "," #Gets file for selected column
    for task in $file; do
        printf "%-${lsL}s|\\n" "|   ${task//_/ }" #Prints task
    done
}

get_length() { #Invokes get_lsl according to 1st argument
    if ! [[ -z "$1" ]]; then
        get_lsl "${1,,}"
    else
        for column in $(dir "$knbn_board"); do
            get_lsl "$column"
        done
    fi
}

print_border() { #Prints borders when listing tasks
    printf -v "border" "%-${lsL}s+" "+"
    printf "%s\\n" "${border// /-}"
}

regenerate_numbers() { #Regenerate line numbers in given column
    get_column "${1,,}" #Gets file for selected column
    newID=1
    for line in $file; do
        if [[ "${line%-,*}" != ",," ]]; then
            ID="${line%:,*}" #Get ID from line
            sed -i "/${ID}:,/s_${ID}:,_${newID}:,_" "$knbn_board/${1,,}" #Replace old ID with new ID
            newID=$(( newID + 1 ))
        fi
    done
}

#Delete all notes in a task from a column: rm_notes task_id target
#move all notes in a task to a note: rm_notes task_id old_column new_column
rm_notes() {
    check_next_line="$(sed -n "${1}p" "$knbn_board/$2")"
    while [[ ${check_next_line%,-,*} == "," ]]; do
        ! [[ -z "$3" ]] && printf "%s\\n" "$check_next_line" >> "$knbn_board/$3" #Insert note into new column
        sed -i "${1}d" "$knbn_board/$2" #Delete note from old column
        check_next_line="$(sed -n "${1}p" "$knbn_board/$2")"
    done
}

[[ "$1" != "-"* ]] && func="${1,,}" #To allow things like knbn ADD, or knbn Add, or knbn aDd
case $func in
    "add"|"-a"|"--add") #Syntax to add: knbn add column description
        if ! [[ -z "$3" ]]; then
            add_column="${2,,}"
            add_column="${add_column// /_}"
            printf "%s\\n" "tmp:,$3" >> "$knbn_board/${add_column}" #Add task to column specified by 3rd argument, turns any space into _
            regenerate_numbers "${add_column}"
            knbn "ls" "${add_column}"
        else
            printf "%s\\n" "tmp:,$3" >> "$knbn_board/nocat" #Add task to nocat if no 3rd argument given
            regenerate_numbers "nocat"
            knbn "ls" "nocat"
        fi
    ;;
    "nt"|"-n"|"--note") #Syntax: knbn nt column task_id description
        if ! [[ -z "$2" && -z "$3" && -z "$4" ]]; then
            add_column="${2,,}"
            add_column="${add_column// /_}"
            task_line="$(grep -n "${3}:," "$knbn_board/$add_column")"
            task_line="${task_line%:*:,*}"
            task_line=$(( task_line + 1 ))
            check_next_line="$(sed -n "${task_line}p" "$knbn_board/$add_column")"
            while [[ ${check_next_line%,-,*} == "," ]]; do
                task_line=$(( task_line + 1 ))
                check_next_line="$(sed -n "${task_line}p" "$knbn_board/$add_column")"
            done
            task_line=$(( task_line - 1 ))
            new_line="$(sed -n "${task_line}p" "$knbn_board/$add_column")\\n,,-,$4"
            sed -i "${task_line}s_.*_${new_line}_" "$knbn_board/$add_column"
        fi
    ;;
    "ls"|"-l"|"--list") #Syntax: knbn ls, knbn ls column
        if ! [[ -z $(dir "$knbn_board") ]]; then #Check if board is empty
            lsL=0
            if [[ -z "$2" ]]; then
                get_length
                for column in $(dir "$knbn_board"); do
                    ls_tasks "${column,,}"
                done
                print_border
            else
                ls_column="${2,,}"
                for column in ${ls_column//,/ }; do
                    get_length "${column,,}"
                done
                for column in ${ls_column//,/ }; do
                    ls_tasks "${column,,}"
                done
                print_border
            fi
        else
            printf "%s\\n" "The board is empty"
        fi
    ;;
    "mv"|"-m"|"--move") #Syntax: knbn mv old_column new_column, task_id
        if ! [[ -z "$2" && -z "$3" && -z "$4" ]]; then #Check if 3rd and 4th arguments are empty
            old_column="${2,,}"
            old_column="${old_column// /_}"
            new_column="${3,,}"
            new_column="${new_column// /_}"
            if [[ -f "$knbn_board/$old_column" ]]; then #Check if old column exists
                if grep -q "$4:," "$knbn_board/$old_column"; then #Check if task exists in old column
                    temporary_line="$(grep "$4:," "$knbn_board/$old_column")" #Get task string excluding the line nr
                    task_line=$(grep -n "$4:," "$knbn_board/$old_column")
                    task_line=${task_line%:*:,*}
                    printf "%s\\n" "${temporary_line/*:,/tmp:,}" >> "$knbn_board/$new_column" #Insert task into new column with temporary ID
                    sed -i "/${4}:,/d" "$knbn_board/$old_column" #Delete task from old column
                    rm_notes "$task_line" "$old_column" "$new_column"
                    file="$(< "$knbn_board/$old_column")"
                    if [[ -z $file ]]; then #Check if old column is empty
                        rm "$knbn_board/$old_column" #Delete column
                        regenerate_numbers "$new_column" #Regenerate line IDs in new column
                        knbn "ls" "$new_column"
                    else
                        regenerate_numbers "$old_column" #Regenerate line IDs in old column
                        regenerate_numbers "$new_column" #Regenerate line IDs in new column
                        knbn "ls" "$old_column,$new_column"
                    fi
                fi
            fi
        fi
    ;;
    "rm"|"-d"|"--remove") #Syntax: knbn rm column task_id
        if ! [[ -z "$2" &&  -z "$2" ]]; then
            rm_column="${2,,}"
            rm_column="${rm_column// /_}"
            grep -q "$3:," "$knbn_board/$rm_column" && sed -i "/${3}:,/d" "$knbn_board/$rm_column" #Check if ID in selected column exists
            rm_notes "$3" "$rm_column"
            file="$(< $knbn_board/"$rm_column")"
            if [[ -z $file ]]; then
                rm "${knbn_board:?}/$rm_column" #Delete file if column is empty
            else
                regenerate_numbers "$rm_column" #Regenerate line numbers
                knbn "ls" "$rm_column"
            fi
        fi
    ;;
    "rmnt"|"-r"|"--remove-note") #Syntax: knbn rmnt column task_id not_offset (how many lines down the note is)
        if ! [[ -z "$2" && -z "$3" && -z "$4" ]]; then
            column_name="${2,,}"
            column_name="${column_name// /_}"
            if grep -q "$3:," "$knbn_board/$column_name"; then
                task_line=$(grep -n "${3}:," "$knbn_board/$column_name")
                task_line=${task_line%:*:,*}
                note_line=$(( task_line + $4 ))
                get_task="$(sed -n "${note_line}p" "$knbn_board/$column_name")"
                if [[ ${get_task%,-,*} == "," ]]; then
                    sed -i "${note_line}d" "$knbn_board/$column_name"
                fi
            fi
        else
            printf "%s\\n" "Syntax: knbn ntrm [column] [task ID] [offset from task ID]"
        fi
    ;;
    "wipe"|"-w"|"--wipe") #Syntax: knbn wipe column
        wipe_column="${2,,}"
        [[ -f "$knbn_board/${wipe_column// /_}" ]] && rm "$knbn_board/${wipe_column// /_}"
    ;;
    "backup"|"-b"|"--backup") #Syntax: knbn backup column path_to_location
        if ! [[ -z "$2" && -z "$3" ]]; then
            if [[ "$2" == "*" || "$2" == "." ]]; then
                cp -r "$knbn_board/." "$3"
                printf "%s" "All columns have been saved to $3"
            else
                cp "$knbn_board/$2" "$3"
                printf "%s" "$2 has been saved to $3"
            fi
        fi
    ;;
    "merge"|"-M"|"--merge")
        if ! [[ -z "$2" ]]; then
            read -s -p "Are you sure you want to merge with backup? This will insert all tasks into their respective columns. (y/N)" -n 1 CONFIRM
            printf "%s\\n" ""
        fi
    ;;
    "restore"|"-R"|"--restore")
        if ! [[ -z "$2" ]]; then
            read -s -p "Are you sure you want to restore from backup? This will remove everything from the board. (y/N)" -n 1 CONFIRM
            printf "%s\\n" ""
            [[ ${CONFIRM,,} == "y" ]] && \
                rm -rf "${knbn_board:?}/*" && \
                cp -r "$2" "$knbn_board"
        fi
    ;;
    "help"|"-h"|"--help") #Display available commands
        knbn_list+=("add, -a, --add [column] [description]:,Add a task to a column")
        knbn_list+=("add, -a, --add [column] [description]:,Add a task to a column")
        knbn_list+=("mv, -m, --move [old column] [new column] [task id]:,Move a task")
        knbn_list+=("rm, -d, --remove [column] [task id]:,Delete a task from a column")
        knbn_list+=("ls, -l, --list [column],[column],etc:,List tasks in a column")
        knbn_list+=("ls, -l, --list:,List all tasks")

        knbn_list+=("nt, -n, --note [column] [task id] [description]:,Add a note to a task")
        knbn_list+=("rmnt, -r, --remove-note [column] [task id] [line offset]:,Delete a note from a task")

        knbn_list+=("wipe, -w, --wipe [column]:,Delete all tasks in a column")

        knbn_list+=("backup, -b, --backup [column] [backup location]:,Backup a column")
        knbn_list+=("backup, -b, --backup [* OR .] [backup location]:,Backup the board")
        knbn_list+=("merge, -M, --merge [backup location]:,Merge board with backup")
        knbn_list+=("restore, -R, --restore [backup location]:,Restore from backup")

        knbn_list+=("uninstall, -u, --uninstall:,Uninstall knbnBrd")
        knbn_list+=("license, -L, --license:,Print license")
        knbn_list+=("notice, -N, --notice:,Print GPLv3 notice")
        knbn_list+=("help, -h, --help:,Print this")
        knbn_list+=("examples, -e, --examples:,Print examples")

        printf "\\n"
        for command in "${knbn_list[@]}"; do
            command_flags="${command%:,*}"
            command_description="${command#*:,}"
            printf "%s\\n" "  $command_flags"
            printf "%s\\n" "    $command_description"
        done
    ;;
    "uninstall"|"-u"|"--uninstall") #Uninstall knbnBrd entirely
        rm -rf /opt/knbnBrd
        rm /usr/bin/knbnBrd
    ;;
    "license"|"-L"|"--license") #Display license
        file="$(< $LICENSE)"
        printf "\\n%s\\n" "$file" #Prints the license
    ;;
    "notice"|"-N"|"--notice"|*) #If no option display notice
        file="$(< $NOTICE)"
        printf "\\n%s\\n" "$file" #Prints the notice
        printf "\\n%s\\n\\nv1.1\\n\\n" "Type knbn license to view the entire license, knbn help to view options"
    ;;
esac
