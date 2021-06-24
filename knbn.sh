#!/bin/bash

knbn_directory="/opt/knbn"
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
    printf "%-${lsL}s|\\n" "| ${1,,}:" #Prints column name
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

print_border() { #Prints borders for when listing tasks
    border="$(printf "%-${lsL}s+" "+")"
    printf "%s\\n" "${border// /-}"
}

regenerate_numbers() { #Regenerate line numbers in given column
    get_column "${1,,}" #Gets file for selected column
    newID=1
    for line in $file; do
        ID="${line%:,*}" #Get ID from line
        sed -i "/${ID}:,/s_${ID}:,_${newID}:,_" "$knbn_board/${1,,}" #Replace old ID with new ID
        newID=$(( newID + 1 ))
    done
}

case $1 in
    "add") #Add tasks
        if ! [[ -z "$3" ]]; then
            add_column="${3,,}"
            printf "%s\\n" "tmp:,$2" >> "$knbn_board/${add_column// /_}" #Add task to column specified by 3rd argument, turns any space into _
            regenerate_numbers "${add_column// /_}"
            $0 "ls" "${add_column// /_}"
        else
            printf "%s\\n" "tmp:,$2" >> "$knbn_board/nocat" #Add task to nocat if no 3rd argument given
            regenerate_numbers "nocat"
            $0 "ls" "nocat"
        fi
    ;;
    "ls") #List tasks
        if ! [[ -z $(dir "$knbn_board") ]]; then #Check if board is empty
            lsL=0
            if [[ -z "$2" ]]; then
                get_length
                for column in $(dir "$knbn_board"); do
                    ls_tasks "$column"
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
            new_column="${4,,}"
            if [[ -f "$knbn_board/${old_column// /_}" ]]; then #Check if old column exists
                if grep -q "$2:," "$knbn_board/${old_column// /_}"; then #Check if task exists in old column
                    temporary_line="$(grep "$2:," "$knbn_board/${old_column// /_}")" #Get task string excluding the line nr
                    printf "%s\\n" "${temporary_line/*:,/tmp:,}" >> "$knbn_board/${new_column// /_}" #Insert task into new column with temporary ID
                    sed -i "/${2}:,/d" "$knbn_board/${old_column// /_}" #Delete task from old column
                    file="$(< $knbn_board/"${old_column// /_}")"
                    if [[ -z $file ]]; then #Check if old column is empty
                        rm "$knbn_board/${old_column// /_}" #Delete column
                        regenerate_numbers "${new_column// /_}" #Regenerate line nr in new column
                        $0 "ls" "${new_column// /_}"
                    else
                        regenerate_numbers "${old_column// /_}" #Regenerate line nr in old column
                        regenerate_numbers "${new_column// /_}" #Regenerate line nr in new column
                        $0 "ls" "${old_column// /_},${new_column// /_}"
                    fi
                fi
            fi
        fi
    ;;
    "rm") #Delete a note if 3rd argument has been set
        if ! [[ -z "$3" ]]; then
            rm_column="${3,,}"
            grep -q "$2:," "$knbn_board/${rm_column// /_}" && sed -i "/${2}:,/d" "$knbn_board/${rm_column// /_}" #Check if ID in selected column exists
            file="$(< $knbn_board/"${rm_column// /_}")"
            if [[ -z $file ]]; then
                rm "${knbn_board:?}/${rm_column// /_}" #Delete file if column is empty
            else
                regenerate_numbers "${rm_column// /_}" #Regenerate line numbers
                $0 "ls" "${rm_column// /_}"
            fi
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
