#!/bin/bash

source <(curl -s "https://raw.githubusercontent.com/Heixier/lib/refs/heads/main/colors")

lockfile=/tmp/philo_lock.lock

running=()
test_cases=(
	"5 800 200 200 5"
	"4 410 200 2000"
	"4 410 200 1500"
	"4 410 200 1500"
	"4 410 200 1500"
	"4 410 200 1500"
)

lock () {
	while ! mkdir "$lockfile" 2>/dev/null
	do
		sleep 0.1
	done
}

unlock () {
	rmdir "$lockfile" 2>/dev/null
}

shift_to_line () {
	tput cup $(( $header_len + $1 )) 0
}

run_philo () {
	local id=$1
	shift 1

	./philo $@ | while IFS= read -r line
	do
		if [[ "$line" == *"died" ]]; then
			break;
		fi
	done
	lock
	shift_to_line $id
	printf "\t%s: %s%s%s\n" "${@}" "$RED" "Stopped 🤔" "$RESET"
	unlock
	return 0
}

begin_test () {
	local i=0
	local process_name

	clear
	print_header
	tput civis
	for test in "${test_cases[@]}"
	do
		printf "\t%s: %s%s%s\n" "$test" "$LIGHT_GREEN" "Running 😋" "$RESET"
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

print_header () {
	lock
	printf "%sDining philosophers!%s\n" "$PINK" "$RESET"
	printf "%sDocumentation is still incomplete%s\n" "$LIGHT_GREY" "$RESET"
	printf "\n"
	header_len=3 #worst hardcode in history
	shift_to_line 0
	unlock
	return 0
}

cleanup () {
	tput cnorm
	lock
	shift_to_line $(( $header_len + ${#test_cases[@]}))
	printf "\r%sstopping...%s\n" "$YELLOW" "$RESET"
	shift_to_line $(( $header_len + ${#test_cases[@]}))
	unlock
	exit
}

trap cleanup EXIT INT TERM QUIT

begin_test
timer &
timer_pid=$!

tput sc

for pid in "${running[@]}"
do
	wait $pid 2>/dev/null
done
kill $timer_pid
shift_to_line $(( $header_len + ${#test_cases[@]}))