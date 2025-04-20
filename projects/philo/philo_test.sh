#!/bin/bash

source <(curl -s "https://raw.githubusercontent.com/Heixier/lib/refs/heads/main/colors")

test_cases=(
	"5 1600 200 200"
	"2 800 200 200"
	"2 800 200 100"
	"2 800 200 100"
)

named_pipes=()
process_ids=()

run_philo () {
	local id=$1
	shift 1

	local pipe_name="/tmp/philo_test_$id"
	mkfifo "$pipe_name" 2>/dev/null
	./philo $@ > "$pipe_name" &
	process_ids+=("$!")
	named_pipes+=("$pipe_name")
}

cleanup () {
	for pid in "${process_ids[@]}"
	do
		kill "$pid" 2>/dev/null
	done
	for pipe in "${named_pipes[@]}"
	do
		rm "$pipe" 2>/dev/null
	done
}

begin_monitor () {
	local running=1
	local idx=0
	local fd
	local finished=()

	while (( $running ))
	do
		running=0
		idx=0
		for pid in "${process_ids[@]}"
		do

			if kill -0 "$pid" 2>/dev/null; then
				exec {fd}<"${named_pipes[$idx]}"
				while IFS= read -r -t 1 -u $fd line
				do
					if [[ "$line" == *"died" ]]; then
						tput cup $idx
						printf "\r"
						tput el
						printf "%s: %s%s%s\n" "${test_cases[$idx]}" "$ORANGE" "Stopped 🤔" "$RESET"
						tput rc
						kill "${process_ids[$idx]}" 2>/dev/null
						finished+=("$idx")
						break
					fi
				done
				exec {fd}<&-
				running=1
			else
				if ! [[ " ${finished[@]} " =~ "$idx" ]]; then
					tput cup $idx
					printf "\r"
					tput el
					printf "%s: %s%s%s\n" "${test_cases[$idx]}" "$ORANGE" "Stopped 🤔" "$RESET"
					tput rc
					finished+=("$idx")
				fi
			fi
			idx=$(( $idx + 1 ))
		done
		sleep 0.1
	done
	return 0
}

begin_test () {
	local i=0
	local process_name

	clear

	for test in "${test_cases[@]}"
	do
		printf "%s: %s%s%s\n" "$test" "$LIGHT_GREEN" "Running 😋" "$RESET"
		run_philo $i "$test"
		i=$(( $i + 1))
	done
	tput sc
	begin_monitor
}

trap cleanup EXIT INT TERM

begin_test

wait