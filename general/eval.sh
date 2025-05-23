#!/bin/bash

# Colours
source <(curl -s "https://raw.githubusercontent.com/Heixier/lib/refs/heads/main/colors")

prog_name="$1"
allowed_funcs=( "${@:2}" )
errors=0
warnings=0

norm_check () {
	printf "%sNorminette -v: %s%s\n\n" "$LIGHT_GREY" "$(norminette -v)" "$RESET"
	if ! command -v "norminette" >/dev/null; then
		printf "%sError: Norminette not found!%s\n\n" "$RED" "$RESET"
		errors=$(( errors + 1 ))
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
			errors=$(( errors + 1 ))
		else
			if [[ $ko_errors ]]; then
				printf "%sNorminette errors found!%s\n%s\n\n" "$RED" "$RESET" "$ko_errors"
				errors=$(( errors + 1 ))
			else
				printf "%sNorminette OK, but warnings were found:%s\n%s\n\n" "$YELLOW" "$RESET" "$norm_errors"
				warnings=$(( warnings + 1 ))
			fi
		fi
	fi
}

header_check () {
	printf "%sChecking header authors...%s" "$LIGHT_BLUE" "$RESET"
	local authors="$(find . -name "*.c" -o -name "*.h" -type f | 
	xargs -I {} awk 'FNR==6 { print $3 } FNR==8 { print $6 } FNR==9 { print $6;nextfile }' {} | sort -u)"
	local emails="$(find . -name '*.c' -o -name '*.c' -type f | xargs -I {} awk 'FNR == 6 { print $4 }' {} | sort -u)"
	printf "\r"; tput el
	printf "%sHeader author list %s(check for unknown names)\n%s%s\n\n" "$ORANGE" "$LIGHT_GREY" "$RESET" "$authors"
	# printf "%s%sHeader author email list\n%s%s\n\n" "$UNDERLINE" "$LIGHT_BLUE" "$RESET" "$emails"
}

makefile_check () {
	local make_relink
	local header_check

	if ! [[ -f "Makefile" ]]; then
		printf "%sNo 'Makefile' found%s\n\n" "$RED" "$RESET"
		errors=$(( errors + 1 ))
		return 1
	fi

	printf "%sChecking Makefile rules...%s" "$LIGHT_BLUE" "$RESET"

	# Do basic rule check
	local rules=(
		"all"
		"clean"
		"fclean"
		"re"
	)
	if [[ $prog_name ]]; then
		rules+=("$prog_name")
	fi
	for rule in "${rules[@]}"
	do
		if ! make "$rule" >/dev/null 2>&1; then
			printf "\r"; tput el
			printf "%sRule %s not found!%s\n\n" "$RED" "$rule" "$RESET"
			errors=$(( errors + 1 ))
			return 1
		fi
	done
	printf "\r"; tput el
	printf "%sChecking for relinks...%s" "$LIGHT_BLUE" "$RESET"
	make fclean >/dev/null 2>&1 && make >/dev/null 2>&1
	make_relink="$(make 2>&1)"
	if ! [[ "$make_relink" == *"Nothing to be done"* ]]; then
		printf "\r"; tput el
		printf "%sMakefile relinked!%s\n\n" "$RED" "$RESET"
		errors=$(( errors + 1 ))
		return 1
	fi
	printf "\r"; tput el
	printf "%sChecking if header update triggers Makefile...%s" "$LIGHT_BLUE" "$RESET"

	if find . | grep -q ".h"; then
		touch **.h
		header_check=$(make)
		local something_done=0
		for output in "${header_check}"
		do
			if printf "%s\n" "$output" | grep -qv "Nothing to be done"; then
				something_done=1
			fi
		done
		if ! (( $something_done )); then
			printf "\r"; tput el
			printf "%sMakefile did not trigger an update when headers were changed!%s\n\n" "$YELLOW" "$RESET"
			warnings=$(( warnings + 1 ))
			return 1
		fi
	else
		printf "%sNo header files found (?!) %sCHECK THE CODE%s\n\n" "$YELLOW" "$LIGHT_GREY" "$RESET"
		warnings=$(( warnings + 1 ))
		return 1
	fi
	printf "\r"; tput el
	printf "%sMakefile tests complete!\n%sBut open up the Makefile anyway to double check%s\n\n" "$PURPLE" "$LIGHT_GREY" "$RESET"
}


nm_check () {
	if ! command -v "nm" >/dev/null; then
		printf "%sError: nm not found! %s(how is this possible...)%s\n\n" "$RED" "$LIGHT_GREY_REG" "$RESET"
		errors=$(( errors + 1 ))
		return 1
	fi
	if (( ${#@} > 2 )); then
		printf "%sIncorrect format! Did you remember to quote the functions?%s\n\n" "$ORANGE" "$RESET"
		warnings=$(( warnings + 1 ))
		return 1
	fi
	if ! [[ -f $prog_name ]]; then
		printf "%sProgram/library %s%s%s not found! %s(did you spell it correctly?)%s\n\n" "$RED" "$LIGHT_GREY" "$prog_name" "$RED" "$LIGHT_GREY" "$RESET"
		errors=$(( errors + 1 ))
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
		done | sort | uniq
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
			errors=$(( errors + 1 ))
		elif ! [[ $2 ]]; then
			printf "%sFunction checker (manual check mode):\n%sTo automate function checking, copy the list from the PDF (and quote them)\ne.g ./%s program_name \"list of functions\"\n\n%sUsed functions: %s%s\n\n"  "$LIGHT_BLUE" "$LIGHT_GREY" "$(basename $0)" "$ORANGE" "$RESET" "$(printf "%s\n" "${sorted_used[@]}" | awk '{ printf "%s%s", sep, $0; sep=", " } END { print "" }')"
		else
			printf "%sNo forbidden functions found!%s\n\n" "$PURPLE" "$RESET"
			return 0
		fi
		printf "%sReminder: %sthere may be false positives; double check the source code!%s\n\n" "$PURPLE" "$LIGHT_GREY" "$RESET"
	else
		printf "%sWarning: no program name provided, skipping forbidden function check%s\n\n" "$YELLOW" "$RESET"
		warnings=$(( warnings + 1 ))
	fi

}

header () {
	clear
	tput civis
	stty -echo

	printf "%s%sBasic Project Tester%s\n\n" "$LIGHT_BLUE" "$UNDERLINE" "$RESET"
	printf "%sProject name: %s%s%s\n\n" "$LIGHT_GREY" "$UNDERLINE" "$1" "$RESET"
}

cleanup () {
	tput cnorm
	stty echo
	printf "\n"
	exit
}

trap cleanup EXIT SIGINT SIGQUIT
# Main

header
norm_check
header_check
makefile_check
nm_check "$@"

printf "%sTest Summary:\n\n%s" "$LIGHT_BLUE" "$RESET"
if (( $warnings )); then
	printf "\t%sWarnings: %d%s\n" "$YELLOW" $warnings "$RESET"
fi
if (( $errors )); then
	printf "\t%sErrors: %d%s\n" "$RED" $errors "$RESET"
fi
if ! (( $warnings )) && ! (( $errors )); then
	printf "%sSeems good! %sAlso remember to do any required manual checks!%s\n" "$LIGHT_GREEN" "$LIGHT_GREY" "$RESET"
fi
