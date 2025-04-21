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
	"3 610 200 190 20"
	"3 500 200 100"
	# "200 410 200 200"
)

print_header () {
	local cpu_model="$(lscpu -e=MODELNAME | awk 'NR==2 { print }')"
	local cpu_arch="$(lscpu | grep 'Architecture: ' | awk '{ print $2}')"
	local cpu_cores="$(lscpu -e=CPU | awk 'NR>1 {count++} END {print count}')"
	local cpu_cache="$(lscpu -C=NAME,ONE-SIZE | awk 'NR>1 { printf "%s%s: %s", sep, $1, $2; sep=" | " } END { print ""}')"

	local warning
	local thread_total=$(count_thread_total)
	if (( thread_total * 100 > cpu_cores * 75 )); then
		warning="${ORANGE}Warning: ${thread_total} threads exceeds the recommended stable limit (75% of CPU count)."
	fi

	local header_arr=(
		"${LIGHT_GREY}SYSTEM SPECIFICATIONS${RESET}"
		"${LIGHT_GREY}Model: ${cpu_model} (Arch: ${cpu_arch})${RESET}"
		"${LIGHT_GREY}CPUs:  ${cpu_cores} Cores/Threads${RESET}"
		"${LIGHT_GREY}Cache: ${cpu_cache}${RESET}"
		""
		"${PURPLE}Begin test(s)!${RESET}"
		"${warning}"
		"${LIGHT_GREY_REG}Large sleep/eat times may cause update delays${RESET}"
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

count_thread_total () {
	local total_threads=0
	local threads_used
	for test in "${test_cases[@]}"
	do
		threads_used=$(awk '{printf $1}' <(printf "%s\n" "$test"))
		total_threads=$(( total_threads + threads_used ))
	done
	printf "%d\n" $total_threads
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
	tput el
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
	local last_timestamp=0
	local current_timestamp=0
	local death_flag=0
	local status="Done! 😋"
	local status_color="$ORANGE"
	local last_line
	shift 1

	while IFS= read -r line
	do
		# Check if any message prints after death is printed
		if (( $death_flag )); then
			status="Printed after death ☠️"
			status_color="$RED"
			break
		fi
		if [[ "$line" == *"died" ]]; then
			status="Died 💀"
			status_color="$RED"
			death_flag=1
		fi

		# Check if timestamps are out of order
		current_timestamp=$(awk '{ print $1 }' <(printf "%s" "$line"))
		if (( $current_timestamp < $last_timestamp )); then
			status="Printed out of order ⏱️"
			status_color="$RED"
			break
		fi
		last_timestamp="$(awk '{ print $1 }' <(printf "%s" "$line"))"
		last_line="$line"
	done < <(./"${prog}" $@) # Prevent running | in subshell so I can still use my local variables
	lock
	shift_to_line $id
	printf "\t%s%s%s %-${longest_line}s : %s%s%s\n" "$LIGHT_GREY" "./$prog" "$RESET" "${@}" "$status_color" "$status" "$RESET"
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
		printf "\t%s%s%s %-${longest_line}s : %s%s%s\n" "$LIGHT_GREY" "./$prog" "$RESET" "$test" "$LIGHT_GREEN" "Running 🤔" "$RESET"
		run_philo $i "$test" &
		running+=($!)
		i=$(( i + 1 ))
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