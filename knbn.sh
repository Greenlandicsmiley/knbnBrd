#!/bin/bash

knbn_directory="/opt/knbnBrd"
knbn_board="$knbn_directory/board"
LICENSE="$knbn_directory/LICENSE"
NOTICE="$knbn_directory/NOTICE"

check_if_longest_string() { #Checks if string from 1st argument is longer than the last string
    [[ ${#1} -gt $longest_string ]] && longest_string=${#1}
}

get_column() { #Gets file for selected column
    file="$(< $knbn_board/"${1,,}")"
    file="${file// /_}"
    [[ $2 == "," ]] && file="${file//,/_}"
}

get_lsl() { #Gets longest line in selected column
    get_column "${1,,}" #Gets file for selected column
    for task in $file; do
        text="|   ${task} "
        [[ ${#text} -gt $lsL ]] && \
            lsL=${#text}
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

#Delete all notes in a task from a column: rm_note "task ID" "target"
#move all notes in a task to a note: rm_note "task ID" "old column" "new column"
rm_notes() {
    check_next_line="$(sed -n "${1}p" "$knbn_board/${2}")"
    while [[ ${check_next_line%,-,*} == "," ]]; do
        ! [[ -z "${3}" ]] && printf "%s\\n" "${check_next_line}" >> "$knbn_board/${3}" #Insert note into new column
        sed -i "/${2}:,/d" "$knbn_board/${2}" #Delete note from old column
        check_next_line="$(sed -n "${1}p" "$knbn_board/${2}")"
    done
}

case $1 in
    "add") #Add tasks
        if ! [[ -z "$3" ]]; then
            add_column="${3,,}"
            add_column="${add_column// /_}"
            printf "%s\\n" "tmp:,$2" >> "$knbn_board/${add_column}" #Add task to column specified by 3rd argument, turns any space into _
            regenerate_numbers "${add_column}"
            $0 "ls" "${add_column}"
        else
            printf "%s\\n" "tmp:,$2" >> "$knbn_board/nocat" #Add task to nocat if no 3rd argument given
            regenerate_numbers "nocat"
            $0 "ls" "nocat"
        fi
    ;;
    "nt")
        if ! [[ -z "$2" && -z "$3" && -z "$4" ]]; then
            add_column="${2,,}"
            add_column="${add_column// /_}"
            note="  - $4"
            new_line="$(grep "${3}:," "$knbn_board/${add_column}")\\n,,-,${4}"
            sed -i "/${3}:,/s_.*_${new_line}_" "$knbn_board/${add_column}"
        fi
    ;;
    "ls") #List tasks
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
    "mv") #Move a file
        if ! [[ -z "$3" && -z "$4" ]]; then #Check if 3rd and 4th arguments are empty
            old_column="${3,,}"
            old_column="${old_column// /_}"
            new_column="${4,,}"
            new_column="${new_column// /_}"
            if [[ -f "$knbn_board/$old_column" ]]; then #Check if old column exists
                if grep -q "$2:," "$knbn_board/$old_column"; then #Check if task exists in old column
                    temporary_line="$(grep "$2:," "$knbn_board/$old_column")" #Get task string excluding the line nr
                    printf "%s\\n" "${temporary_line/*:,/tmp:,}" >> "$knbn_board/$new_column" #Insert task into new column with temporary ID
                    sed -i "/${2}:,/d" "$knbn_board/$old_column" #Delete task from old column
                    rm_notes "$2" "$old_column" "$new_column"
                    file="$(< "$knbn_board/$old_column")"
                    if [[ -z $file ]]; then #Check if old column is empty
                        rm "$knbn_board/$old_column" #Delete column
                        regenerate_numbers "$new_column" #Regenerate line nr in new column
                        $0 "ls" "$new_column"
                    else
                        regenerate_numbers "$old_column" #Regenerate line nr in old column
                        regenerate_numbers "$new_column" #Regenerate line nr in new column
                        $0 "ls" "$old_column,$new_column"
                    fi
                fi
            fi
        fi
    ;;
    "rm") #Delete a note if 3rd argument has been set
        if ! [[ -z "$3" ]]; then
            rm_column="${3,,}"
            rm_column="${rm_column// /_}"
            grep -q "$2:," "$knbn_board/$rm_column" && sed -i "/${2}:,/d" "$knbn_board/$rm_column" #Check if ID in selected column exists
            rm_notes "$2" "$rm_column"
            file="$(< $knbn_board/"$rm_column")"
            if [[ -z $file ]]; then
                rm "${knbn_board:?}/$rm_column" #Delete file if column is empty
            else
                regenerate_numbers "$rm_column" #Regenerate line numbers
                $0 "ls" "$rm_column"
            fi
        fi
    ;;
    "ntrm") #Delete a note
        if ! [[ -z "$2" && -z "$3" && -z "$4" ]]; then
            column_name="${2,,}"
            column_name="${column_name// /_}"
            if grep -q "$3:," "$knbn_board/${column_name}"; then
                offset_line=$(( $3 + $4 ))
                get_note="$(sed -n "${offset_line}p" "$knbn_board/${column_name}")"
                if [[ ${get_note%,-,*} == "," ]]; then
                    sed -i "${offset_line}d" "$knbn_board/${column_name}"
                fi
            fi
        else
            printf "%s\\n" "Syntax: knbn ntrm [column] [task ID] [offset from task ID]"
        fi
    ;;
    "wipe") #Wipe a board if knbn_board has been set, if not fail
        wipe_column="${2,,}"
        [[ -f "$knbn_board/${wipe_column// /_}" ]] && \
            rm "$knbn_board/${wipe_column// /_}"
    ;;
    "--help"|"help") #Display available commands
        longest_string=0
        knbnandc="Add a task to a column:,knbn add \"[description]\" [column]"; check_if_longest_string "${knbnandc%,*}"
        knband="Add a task:,knbn add \"[description]\""; check_if_longest_string "${knband%,*}"
        knbnlsc="List tasks in a column:,knbn ls [column]"; check_if_longest_string "${knbnlsc%,*}"
        knbnls="List all tasks:,knbn ls"; check_if_longest_string "${knbnls%,*}"
        knbnmvnon="Move a task:,knbn mv [number] [old column] [new column]"; check_if_longest_string "${knbnmvnon%,*}"
        knbnrmnc="Delete a task from a column:,knbn rm [number] [column]"; check_if_longest_string "${knbnrmnc%,*}"
        knbnwc="Delete all tasks in a column:,knbn wipe [column]"; check_if_longest_string "${knbnwc%,*}"
        printf "\\n"
        printf "\\x1B[32m%${longest_string}s" "${knbnandc%,*}"; printf "%b" "\\x1B[37m${knbnandc#*:,}\\n"
        printf "\\x1B[32m%${longest_string}s" "${knband%,*}"; printf "%b" "\\x1B[37m${knband#*:,}\\n"
        printf "\\x1B[35m%${longest_string}s" "${knbnlsc%,*}"; printf "%b" "\\x1B[37m${knbnlsc#*:,}\\n"
        printf "\\x1B[35m%${longest_string}s" "${knbnls%,*}"; printf "%b" "\\x1B[37m${knbnls#*:,}\\n"
        printf "\\x1B[34m%${longest_string}s" "${knbnmvnon%,*}"; printf "%b" "\\x1B[37m${knbnmvnon#*:,}\\n"
        printf "\\x1B[31m%${longest_string}s" "${knbnrmnc%,*}"; printf "%b" "\\x1B[37m${knbnrmnc#*:,}\\n"
        printf "\\x1B[31m%${longest_string}s" "${knbnwc%,*}"; printf "%b" "\\x1B[37m${knbnwc#*:,}\\n"
        printf "\\n"
    ;;
    "--uninstall"|"uninstall")
        rm -rf /opt/knbn
        rm /usr/bin/knbn
    ;;
    "--license"|"license") #Display license
        file="$(< $LICENSE)"
        printf "\\n%s\\n" "$file" #Prints the license
    ;;
    *) #If no option display notice
        file="$(< $NOTICE)"
        printf "\\n%s\\n" "$file" #Prints the notice
        printf "\\n%s\\n\\n" "Type knbn license to view the entire license, knbn help to view options"
    ;;
esac
