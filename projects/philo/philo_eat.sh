#!/bin/bash

# Script to display the actual minimum times eaten
# DEPRECATED. USE philo_test instead

source <(curl -s "https://raw.githubusercontent.com/Heixier/lib/refs/heads/main/colors")

printf "%sTHIS SCRIPT IS DEPRECATED, USE THE MAIN PHILO_TEST INSTEAD\n%s" "$ORANGE" "$RESET"

PROGRAM_NAME="philo"

check_prog_exist () {
	if ! [ -f "$PROGRAM_NAME" ]; then
		printf "%serror: \"philo\" not found!\n%s" "$RED" "$RESET"
		exit 127
	fi
}

main () {
	check_prog_exist

	printf "%sRunning program...%s" "$ORANGE" "$RESET"
	result=("$(./"$PROGRAM_NAME" "$@")")
	printf "\r"; tput el
	local died="$(printf "%s\n" "${result[@]}" | grep "died")"

	if [[ "$died" ]]; then
		printf "%sTest invalid: %s%s\n" "$RED" "$died" "$RESET"
		return 1
	fi
	min_eat="$(printf "%s\n" "${result[@]}" | grep "is eating" | awk '{ print $2 }' | sort | uniq -c |  sort -n | awk 'NR==1 { print $1 }')"
	printf "%sMinimum times eaten: %s%s%s%s\n" "$ORANGE" "$LIGHT_BLUE" "$min_eat" "$RESET"
}

main "$@"
