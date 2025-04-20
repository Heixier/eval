#!/bin/bash

source <(curl -s "https://raw.githubusercontent.com/Heixier/lib/refs/heads/main/colors")

lockfile=/tmp/philo_lock.lock
prog="philo"
longest_line=0

running=()
test_cases=(
	"5 800 200 200"
	"4 410 200 200"
	"4 410 200 200 7"
	"5 800 200 200 5"
)

print_header () {
	local cpu_model="$(lscpu -e=MODELNAME | awk 'NR==2 { print }')"
	local cpu_arch="$(lscpu | grep 'Architecture: ' | awk '{ print $2}')"
	local cpu_cores="$(lscpu -e=CPU | awk 'NR>1 {count++} END {print count}')"
	local cpu_cache="$(lscpu -C=NAME,ONE-SIZE | awk 'NR>1 { printf "%s%s: %s", sep, $1, $2; sep=" | " } END { print ""}')"
	local header_arr=(
		"${LIGHT_GREY}SYSTEM SPECIFICATIONS${RESET}"
		"${LIGHT_GREY}Model: ${cpu_model} (Arch: ${cpu_arch})${RESET}"
		"${LIGHT_GREY}CPUs:  ${cpu_cores} Cores/Threads${RESET}"
		"${LIGHT_GREY}Cache: ${cpu_cache}${RESET}"
		""
		"${PURPLE}Begin test(s)!${RESET}"
		"${LIGHT_GREY_REG}large sleep/eat times may cause inaccuracy${RESET}"
		""
	)
	lock
	for header in "${header_arr[@]}"
	do
		printf "%s\n" "$header"
	done
	header_len=${#header_arr[@]}
	shift_to_line 0
	unlock
	return 0
}

lock () {
	while ! mkdir "$lockfile" 2>/dev/null
	do
		sleep 0.1
	done
}

unlock () {
	rmdir "$lockfile" 2>/dev/null
}

get_longest_line () {
	for test in "${test_cases[@]}"
	do
		if (( ${#test} > $longest_line )); then
			longest_line=${#test}
		fi
	done
}

shift_to_line () {
	tput cup $(( $header_len + $1 )) 0
}

check_for_prog () {
	if ! [ -f "$prog" ]; then # If program does not exist try running make
		make
		if ! [ -f "$prog" ]; then
			print "%s Could not find \'%s\'!%s\n" "$RED" "$prog" "$RESET"
		fi
	fi
}

run_philo () {
	local id=$1
	shift 1

	./"$prog" $@ | while IFS= read -r line
	do
		if [[ "$line" == *"died" ]]; then
			break;
		fi
	done
	lock
	shift_to_line $id
	printf "\t%s%s%s %-${longest_line}s : %s%s%s\n" "$LIGHT_GREY" "./$prog" "$RESET" "${@}" "$RED" "Stopped 💀" "$RESET"
	unlock
	return 0
}

begin_test () {
	local i=0
	local process_name

	clear
	print_header
	for test in "${test_cases[@]}"
	do
		printf "\t%s%s%s %-${longest_line}s : %s%s%s\n" "$LIGHT_GREY" "./$prog" "$RESET" "$test" "$LIGHT_GREEN" "Running 😋" "$RESET"
		run_philo $i "$test" &
		running+=($!)
		i=$(( $i + 1))
	done

}

timer () {
	while :
	do
		lock
		shift_to_line $((${#test_cases[@]} + 1))
		printf "%sTime elapsed: %ds \n%s" "$LIGHT_BLUE" $SECONDS "$RESET"
		unlock
		sleep 1
	done
}

interrupt_msg () {
	return
}

cleanup () {
	tput cnorm
	lock
	# THIS IS VERY HARDCODE
	shift_to_line $((2 + ${#test_cases[@]})) # Don't overwrite the timer
	printf "\r%sstopping...%s\n" "$LIGHT_GREY" "$RESET"
	shift_to_line $((3 + ${#test_cases[@]}))
	unlock

	# Important for SIGQUIT as SIGQUIT does not terminate gracefully
	for pid in "${running[@]}"
	do
		kill $pid 2>/dev/null
	done
	kill $timer_pid 2>/dev/null
	# Reset cursor position to bottom
	exit
}

trap cleanup EXIT SIGINT SIGQUIT

# Begin to do stuff
unlock
tput civis
check_for_prog
get_longest_line
begin_test
timer &
timer_pid=$!

tput sc

# Wait for all philo threads to finish
for pid in "${running[@]}"
do
	wait $pid 2>/dev/null
done
kill $timer_pid

exit