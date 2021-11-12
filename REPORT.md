# Enhancing xv6 OS

## Syscall Tracing

- added int `tmask` to `struct proc`
- added an array `struct syscall_info syscall_infos[]` that contains syscalls functions are stored
- added `trace` function to the `tmask` of a process
- modified `syscall` function to print all the syscalls
- implemented `strace.c` which solves the arguments and executes the specified command

## Scheduling

### First Come First Serve (FCFS)

- added int `ctime` to `struct proc` to store time of creation of process
- set `ctime` of each process in `allocproc` function using ticks
- disabled preemption of process by setting `yield` in both user and kernel trap to just for RR and MLFQ
- FCFS scheduler code is added to `scheduler` function that selects the process with lowest `ctime` by traversing through the proc list and runs it.

### Priority Based Scheduling (PBS)
- added `run_time`, `notime`, `statprior`, `sleep_time`, `start_time`, `total_runtime` and `wake_time` to `struct proc`
- `set_prority` syscall added which takes argument pid and priority from user and sets `statprior` of the process with given pid to the priority argument entered
- added PBS scheduler to `scheduler` function which selects process according to `dp`, `ctime` and `notime`(numeber of times scheduled) from the list of process.
- Dynamic Priority of each process is calculated just after acquiring its lock using the formula </br>
```c
niceness = ((10 * (p->wake_time -  p->sleep_time)) / ( (p->wake_time -  p->sleep_time) + p->run_time));
int proc_dp = max(0, min(p->statprior - niceness + 5 , 100));   // stores dp of the proc
```
- made changes to `sleep` and `wake` function to note `sleep_time` and `wake_time` of process using ticks
- made changes to `clockintr` which updates the `run_time` and `total_runtime` by implementing an `updatetime` function

### Procdump
- added `total_runtime` to the `struct proc` which is used to display the total run time of process since its creation.
- calculated `dynamic priority` and printed the required values using printf closed under pre-processor directives.

### Comparison of Schedulers
- **RR** : Average run_time 17,  wait_time 115
- **FCFS** : Average run_time 36,  wait_time 49
- **PBS** : Average run_time 23 ,  wait_time 103