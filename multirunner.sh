#!/bin/bash

prog=$1 # Save $1 in a variable because we're going to use shift later
valflags=(--leak-check=full --show-leak-kinds=all --track-fds=yes --trace-children=yes --track-origins=yes)
memcheck=0
sep="------------------------------"

check_prog () {
	if [ "$1" == "valgrind" ]; then
		memcheck=1
		prog=$2 # if valgrind is the first argument then the second one is our program name
	fi
	if ! [[ -x $prog ]]; then
		printf "Cannot find/execute \""$prog"\"!\n\
Usage: \e[38;5;105m./multirunner.sh \
\e[38;5;207mvalgrind \
\e[38;5;82mprogram \
\e[0mfile1 file2 file3 ...\n\
		       (optional)\n\
Examples:
\e[38;5;105m./multirunner.sh \e[38;5;82mso_long\e[0m maps/*\n\
\e[38;5;105m./multirunner.sh \e[38;5;207mvalgrind \e[38;5;82mget_next_line\e[0m texts/*\e[0m\n"
		exit 2
	fi
}

print_arr () {
	local count=1
	printf "\e[38;5;118;1mReceived:\e[0m\n"
	for arg in "$@"; do
		printf "$count: $arg\n"
		count=$((count+1))
	done
}

runner () {
	local count=0
	shift $((1 + $memcheck))
	print_arr "$@"
	for arg in "$@"; do
		printf "\e[38;5;118;1m%s\n\e[38;5;14mRunning: "$prog" "$arg"\n\e[38;5;226;1m%s\e[0m\n" "$sep" "$sep"
		if [[ $memcheck == 1 ]]; then
			printf "\e[38;5;207mvalgrind flags: %s\e[0m\n" "${valflags[*]}"
			valgrind "${valflags[@]}" ./"$prog" "$arg"
		else
			./"$prog" "$arg"
		fi
		local pid=$! # Potential race condition if pid is not caught fast enough?
		wait $pid
		printf "\e[38;5;160;1m%s\e[0m\n" "$sep"
		read -p "Press any key to continue ("$(($#-count - 1))" left)..."
		printf "\e[0m"
		count=$((count+1))
	done
	printf "\e[38;5;82;1mFinished!\e[0m\n"
}

check_prog "$@" && runner "$@"

#rsiah