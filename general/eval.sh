#!/bin/bash

# Colours
source <(curl -s "https://raw.githubusercontent.com/Heixier/lib/refs/heads/main/colors")

prog_name="$1"
allowed_funcs=( "${@:2}" )

norm_check () {
	if ! command -v "norminette" >/dev/null; then
		printf "%sNorminette not found! Skipping...%s\n\n" "$RED" "$RESET"
		return 1
	fi
	printf "%sRunning norminette...%s" "$LIGHT_BLUE" "$RESET"
	local norm_errors="$(norminette 2>&1 | grep -v ': OK!')"
	local ko_errors="$(echo "$norm_errors" | grep -E ': Error!|Error: ')"
	printf "\r%s"; tput el
	if ! [[ $norm_errors ]]; then
		printf "%sNorminette OK!\n%s\n" "$LIGHT_GREEN" "$RESET"
	else
		if echo "$norm_errors" | grep -q "Traceback"; then
			printf "%sNorminette crashed!...??? (are you in the correct directory?)%s\n\n" "$RED" "$RESET"
		else
			if [[ $ko_errors ]]; then
				printf "%sNorminette errors found!%s\n%s\n\n" "$RED" "$RESET" "$ko_errors"
			else
				printf "%sNorminette OK, but warnings were found:%s\n%s\n\n" "$YELLOW" "$RESET" "$norm_errors"
			fi
		fi
	fi
}

header_check() {
	printf "%sChecking header authors...%s" "$LIGHT_BLUE" "$RESET"
	local authors="$(find . -name "*.c" -o -name "*.h" -type f | 
	xargs -I {} awk 'FNR==6 { print $3 } FNR==8 { print $6 } FNR==9 { print $6;nextfile }' {} | sort -u)"
	local emails="$(find . -name '*.c' -o -name '*.c' -type f | xargs -I {} awk 'FNR == 6 { print $4 }' {} | sort -u)"
	printf "\r"; tput el
	printf "%sHeader author ID list (check for additional names)\n%s%s\n\n" "$ORANGE" "$RESET" "$authors"
	# printf "%s%sHeader author email list\n%s%s\n\n" "$UNDERLINE" "$LIGHT_BLUE" "$RESET" "$emails"
}

nm_check() {
	if ! command -v "nm" >/dev/null; then
		printf "%snm not found! Skipping...%s\n\n" "$RED" "$RESET"
		return 1
	fi
	printf "%sChecking for forbidden functions...%s" "$LIGHT_BLUE" "$RESET"
	printf "\r"; tput el
	if [[ $1 ]]; then
		local used_functions=($(nm -u $1 | awk '{$1=$1};1' | awk -vORS="" -F"[ @]" '/U/ && !/__/{ if (NR>1) printf ", ";print $2 } END { printf "\n" }'))

		local sorted_used=($(
		for function in "${used_functions[@]}"
		do
			echo "${function//,}"
		done | sort
		))
		if [[ $2 ]]; then
			local sorted=($(
			for arg in "${@:2}"
			do
				echo "${arg//,}"
			done | sort
			))

			local mismatches="$(comm -23 <(printf "%s\n" "${sorted_used[@]}") <(printf "%s\n" "${sorted[@]}"))"
		fi
		if [[ $mismatches ]]; then
			printf "%sForbidden functions found!\n%s%s\n%s\n" "$RED" "$RESET" "$mismatches"
		else
			printf "%sTo automate function checking, copy the list from the PDF (and quote them)\ne.g ./%s program_name \"list of functions\"\n%sFunctions used (manual check mode):\n%s%s\n\n" "$LIGHT_GREY" "$(basename $0)" "$LIGHT_BLUE" "$RESET" "$(printf "%s\n" "${sorted_used[@]}")"
		fi
		printf "%sNote: %s%scheck the source code for false positives.\n\n" "$YELLOW" "$RESET"
	else
		printf "No program name provided, skipping forbidden function check\n"
	fi

}

norm_check
header_check
# MAKEFILE CHECK???? QUICK
nm_check $@