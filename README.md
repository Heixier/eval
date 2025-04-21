# bash-scripts

README IS VERY OUTDATED

Collection of some of my bash scripts.

## Multirunner
![image](https://github.com/user-attachments/assets/9b174b0d-59b7-4faf-884b-bb08c2fed84f)


Runs a program multiple times with a set of different arguments.
- Utilises the first argument in the program
- Useful for testing simple programs with different starting parameters e.g. different maps

## ps_gen
![image](https://github.com/user-attachments/assets/d8295a39-1309-4ba7-bca1-36ce81e5c4fb)

Generates multiple random values for testing/benchmarking 42's push_swap sorting project (sort within x amount of moves).
- Different flags and settings
- Produces an output file

This version of the script, unlike the [original](https://github.com/Heixier/veryc/blob/main/utils/scripts/ps_gen.sh), does not include the external checker program.

Included is my own [push_swap](https://github.com/Heixier/veryc/tree/main/push_swap) for testing.

## Sanity check
Script to ensure git remote is set correctly, simply paste the desired URL as an argument to check for a match.
