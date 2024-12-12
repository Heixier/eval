#!/bin/bash

# DEFAULTS
TESTS=500
SIZE=100
NEGATIVE=true
PROG="push_swap"
CHECKER="checker_linux"
OUTFILE="gen_out.txt"
true > "$OUTFILE" # Reset file

# INIT FLAGS
MEMTEST=false
OUTFILE_ENABLED=false
DETAILS=false
TARGET_SET=false
RESULT=()
OVERSHOOT=()
OPTSTR=":s:n:t:odhvp"

while getopts "$OPTSTR" opt
	do
		case "$opt" in
			h)
				echo  -e "Usage: $0 [OPTION]...\nBenchmarking tool for push_swap.\n\n\
OPTIONS:\n\
	-s 		size and test count (delimited by '-')
	-n		custom program name (default: \"push_swap\")
	-t		custom target
	-p		positive integers only
	-o		save overshot values in $OUTFILE
	-d		include details with '-o'
	-v		valgrind (warning: takes more time!)
	-h		opens this help page

Example: $0 -s \e[4;37m100\e[0m-\e[4;37m500\e[0m -t \e[4;37m700\e[0m -n \e[4;37mpush_swap_rsiah\e[0m
(Tests \e[4;37m100\e[0m numbers \e[4;37m500\e[0m times with a target of ≤\e[4;37m700\e[0m using \e[4;37mpush_swap_rsiah\e[0m)

QUICK REF:
	5:	\e[1;92m≤12\e[0m
	100:	\e[1;92m≤700\e[0m  | \e[1;93m≤900\e[0m  | \e[1;93m≤1100\e[0m | \e[1;91m≤1300\e[0m  | \e[1;91m≤1500\e[0m
	500:	\e[1;92m≤5500\e[0m | \e[1;93m≤7000\e[0m | \e[1;93m≤8500\e[0m | \e[1;91m≤10000\e[0m | \e[1;91m≤11500\e[0m"
				exit 0 ;;
			s)
				if [[ "$OPTARG" =~ "-" ]]; then
					SIZE=$(printf "%s" "$OPTARG" | cut -d "-" -f 1)
					TESTS=$(printf "%s" "$OPTARG" | cut -d "-" -f 2)
				else
					printf "%s: -s: invalid format -- '%s'
Usage: -s 'size'-'tests'
Try '-h' for more information.\n" "$0" "$OPTARG"
					exit 22
				fi
				if ! ([[ "$SIZE" =~ ^[-+]?[0-9]+$ ]] && (( "$SIZE" >= 0 ))) ||\
				! ([[ "$TESTS" =~ ^[-+]?[0-9]+$ ]] && (( "$TESTS" >= 0 ))); then
					printf "%s: '-s' requires positive integers.\nTry '-h' for more information.\n" "$0"
					exit 22
				fi ;;
			v)
				MEMTEST=true ;;
			n)
				PROG="$OPTARG"
				if [ -x "$PROG" ]
					then
						echo "Running '$PROG'"
					else
						echo "$0: could not find/execute '$PROG'"
						exit 2
				fi ;;
			t)
				TARGET="$OPTARG" 
				TARGET_SET=true ;;
			o)
				OUTFILE_ENABLED=true ;;
			d)
				DETAILS=true ;;
			p)
				NEGATIVE=false ;;
			?)
				echo -e "$0: invalid option/usage -- '$OPTARG'"
				echo "Try '-h' for more information."
				exit 22 ;;
		esac
	done

check_execute () {
	if ! [ -x "$1" ]; then
		echo -e "$0: could not find/execute '$1'"
		exit 2
	fi
}

check_target () {
	if (( $1 > "$TARGET" )); then
		printf "%s\nMoves:%s\n\n" "$2" "$1" >> "$OUTFILE"
		if "$DETAILS"; then
			printf "%s\n\n" "$3" >> "$OUTFILE"
		fi	
		OVERSHOOT+=("$1")
	fi
	RESULT+=("$1")
}

init_target () {
	if ! "$TARGET_SET"; then
		case "$SIZE" in
			5)
				TARGET=12 ;;
			100)
				TARGET=700 ;;
			500)
				TARGET=5500 ;;
			*)
				TARGET=0 ;;
		esac
	fi
	if (( TARGET )); then 
		echo -e "Size: $SIZE Target: ≤$TARGET"
	fi
}

check_error () {
	local ERROR=false
	local errmsg 
	local checker_output=$(printf "%s\n" "$2" | ./"$CHECKER" "$1" 2>&1)

	if [ "$2" = "Error" ]; then
		errmsg="Program reported an error."
		ERROR=true
	elif [ "$checker_output" == "KO" ]; then
		errmsg="Sort KO."
		ERROR=true
	else
		:
	fi
	if $ERROR; then
		printf "\n\e[1;91m%s\e[0m\nSaving last result to %s and exiting.\n" "$errmsg" "$OUTFILE"
		printf "%s\n\nARGS: %s\nRESULT: %s\n" "$errmsg" "$1" "$2" >> "$OUTFILE"
		exit 1
	fi
}

check_execute "$PROG"
check_execute "$CHECKER"
init_target

main () {
	tput sc
	if $MEMTEST; then
		echo "(note: valgrind can take a while)"
	fi
	for i in $(seq 1 "$TESTS"); do
		ARGS=$(shuf -i 0-2147483647 -n "$SIZE" | if "$NEGATIVE"; then while read -r line; do echo "$((line * (1 - 2 * (RANDOM % 2))))"; done else cat; fi | tr '\n' ' ')
		if $MEMTEST; then
			printf "%s" "$(tput rc)$(tput el)"
			printf "Processing... %d/%d" "$i" "$TESTS"
			out=$(valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes -s ./"$PROG" $ARGS 2>&1)
			if printf "%s" "$out" | grep -E "definitely lost|indirectly lost|possibly lost|ERROR SUMMARY: [^0]|Invalid" > /dev/null; then
					printf "\n\e[1;91m%s\e[0m" "$out"
					exit 1
			fi
		else
			printf "%s" "$(tput rc)$(tput el)"
			printf "Processing... %d/%d" "$i" "$TESTS"
			out=$(./"$PROG" $ARGS)
		fi
		result=$(printf "%s" "$out" | grep -v "==")
		check_error "$ARGS" "$result"

		moves=$(printf "%s\n" "$result" | wc -l)
		check_target "$moves" "$ARGS" "$out"
	done
	printf "%s" "$(tput rc)$(tput el)"
}

TIMEFORMAT=$'CPU: %P%% (%Rs)'; time main

if "$OUTFILE_ENABLED" && (( TARGET )) && (( "${#OVERSHOOT[@]}" )); then
	printf "Overshoots:\n"
	printf "%s\n" "${OVERSHOOT[@]}" | sort | uniq -c | sort -nr | \
	awk '{printf("\t%d (%d times)\n", $2, $1)}'; printf "\e[4;37mResults saved to %s\e[0m\n" "$OUTFILE"
fi

printf "%s\n" "${RESULT[@]}" | sort -n | \
awk -v size="$SIZE" -v TESTS="$TESTS" '{avg += $1} NR==1 {min = $1} END \
{printf("\\e[1;92mTest complete!\\e[0m\\nSize: %d \\t Tests: %d\\nMax: %d \\t Min: %d \\t Avg: %d", size, TESTS, $1, min, avg/NR)}' | \
echo -e "$(cat)"

if (( TARGET )) && (( TESTS )); then
	overshoot_percent=$(awk -v overshoot="${#OVERSHOOT[@]}" -v TESTS="$TESTS" 'BEGIN {printf("%.3f", (overshoot * 100 / TESTS))}')
	if awk 'BEGIN {exit !('"$overshoot_percent"' <= 1)}'; then
		colour="\e[1;92m"
	elif awk 'BEGIN {exit !('"$overshoot_percent"' <= 5)}'; then
		colour="\e[1;93m"
	else
		colour="\e[1;91m"
	fi
	printf "Target: %d\tOvershoots: %d/%d %b(%.3f%%)\e[0m\n" "${TARGET}" "${#OVERSHOOT[@]}" "${TESTS}" "${colour}" "${overshoot_percent}"
fi

#rsiah