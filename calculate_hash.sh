#!/bin/bash

# Purpose:  Custom Action for file browsers which support scripts. Calculates hashes.
# Usage:    Select one or more files, click right button, select desired hash and wait.
# Date:     January 22, 2022
# Licence:  GPLv3


trap '{ rm -f -- "$temp_file"; }' EXIT

####################
# supported hashes #
####################
# To add hashes, add a line here 
# with the format HashName=( "False" "HashName" "HashCommand" )
# where HashCommand is the command you call to compute the 'HashName' hash.
####################
MD5=( "TRUE" "MD5" "md5sum" )
SHA1=( "FALSE" "SHA-1" "sha1sum" )
SHA224=( "FALSE" "SHA-224" "sha224sum" )
SHA256=( "FALSE" "SHA-256" "sha256sum" )
SHA348=( "FALSE" "SHA-348" "sha348sum" )
SHA512=( "FALSE" "SHA-512" "sha512sum" )

# If you added an hash, add the corresponding voice "${HashName[@]}" 
# in the sixth line of the command substitution 
# for the variable "selection".
selection=$(zenity --list --radiolist --height=300 --title="Checksum" \
                   --text="File:  <b>${file##*/}</b>\nPick the hash funcion." \
                   --column="Pick" \
                   --column="Hash"  \
                   --column="Command" \
                   "${MD5[@]}" "${SHA1[@]}" "${SHA224[@]}" "${SHA256[@]}" "${SHA384[@]}" "${SHA512[@]}" \
                   --hide-column=3 \
                   --print-column=ALL)


# If Quit is clicked then exit
if [ "${PIPESTATUS[0]}" -ne "0" ]; then
    exit 0
fi

commandToExecute=${selection#*|}
commandName=${selection%|*}
temp_file=$(mktemp)

for file in "$@";
do
    ((( "$commandToExecute" "$file"| tee  >> "$temp_file" ) 3>&1 1>&2 2>&3 | tee >> "$temp_file" ) 3>&1 1>&2 2>&3 ) | 
    zenity --progress --title="$commandName" \
           --text="Calculating $commandName for:\n${file}" \
           --pulsate --auto-close
done

sum=$( awk '{ if ($0 ~ /^[^:]* /) { $(NF+1)="\n"$1; gsub(/^[^ ]* /,""); print }  else {gsub(/^[^:]*: /, ""); print}  }' "$temp_file" )
zenity --info --title="$commandName" --text="${sum[@]}"

exit 0
