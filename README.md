# Evaluations

Evaluation scripts for 42 Singapore. These scripts are designed to streamline program testing for evaluations.  

They are separated into two categories at the moment: general and project-specific scripts.

# General

## eval.sh
![image](https://github.com/user-attachments/assets/195bb6de-4f7c-4e82-afd5-83f9572a6838)

This script is designed to be run at the start of C project evaluations as a standard baseline check. 

It automatically runs norminette, header author checks, makefile checks, and forbidden function checks on the provided program name

Example usage

    ./eval.sh libft.a
Or curl

    bash <(curl https://raw.githubusercontent.com/Heixier/eval/refs/heads/main/general/eval.sh) libft.a

## Multirunner
![image](https://github.com/user-attachments/assets/9b174b0d-59b7-4faf-884b-bb08c2fed84f)


Runs a program multiple times with a set of different arguments.
- Utilises the first argument in the program
- Useful for testing simple programs with different starting parameters e.g. different maps
####

    bash <(curl https://raw.githubusercontent.com/Heixier/eval/refs/heads/main/general/multirunner.sh)

# Project-specific

## push_swap
### ps_gen.sh
![image](https://github.com/user-attachments/assets/d8295a39-1309-4ba7-bca1-36ce81e5c4fb)

Generates multiple random values for testing/benchmarking 42's push_swap sorting project (sort within x amount of moves).
- Different flags and settings
- Produces an output file

Included is my own [push_swap](https://github.com/Heixier/veryc/tree/main/push_swap) and the external checker program for testing.

## Philosophers
### philo_test.sh
![image](https://github.com/user-attachments/assets/927ac40a-a7d9-47a2-973f-739a54e78564)

Simultaneously tests multiple philosophers. The default test cases do overcommit the processors by a small amount, so if anything fails unexpectedly do retry with less threads

Error cases:

* Timestamps printed in wrong order
* Messages appear after death message
* At least one philosopher did not hit eat limit on exit

At the moment, you will need to edit the script to change the default test cases. Otherwise, if you just want to run with the defaults:

    bash <(curl -s https://raw.githubusercontent.com/Heixier/eval/refs/heads/main/projects/philo/philo_test.sh)

### Example parameters
Non-exhaustive list of test cases, but these cover the main logic cases

* Run indefinitely if program is really good (do not run multiple tests simultaneously with these edge cases)

  *     200 410 200 200
  *     3 600 200 60
* Run indefinitely

  *     3 610 200 200
  *     3 610 200 190
  *     5 800 200 200
  *     4 410 200 200
  *     200 1000 200 200
* Die
  
  *     1 800 200 200
  *     3 600 200 400
  *     4 399 200 200
