#!/bin/bash

printf "Comparing... \n"
git remote -v | awk -v url="$1" 'END {print ($2 == url)? $2 "\n" url "\n" "\033[38;5;118mMatch!\033[0m": $2 "\n" url "\n" "\033[38;5;196mMismatch!\033[0m"}'
