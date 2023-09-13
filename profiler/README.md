# C-States profiler

A simple profiler for collecting and analyzing processor C-state residency times in a cluster.

## Setting up and starting the profiler

Edit file ```hosts``` to specify the names of the machines where to install the profiler.

Install the profiler on the specified machines:

```
$ ./profiler.sh install
```

Start the profiler process on the specified machines:

```
$ ./profiler.sh run_profiler
```

Note: This only starts the profiler process.


## Profiling

To start profiling, invoke the profiler in client mode, providing the name of the machine to start profiling on. For example: 

```
$ python3 ./profiler.py -n node1 start
```

To stop profiling, invoke the profiler in client mode, providing the name of the machine to stop profiling on. For example: 

```
$ python3 ./profiler.py -n node1 stop
```

To collect and report profiling data, invoke the profiler in client mode, providing the name of the machine to collect profiling data from and the name of the local directory where to store profiling data. For example: 

```
$ python3 ./profiler.py -n node1 report -d /tmp/data
```

## Analyzing

To analyze c-state residency, use the analyze script, providing the directory containing the profiling data to analyze, the CPUs to analyze, and the actual duration of the experiment. 

For example, to analyze data for CPUs in the range [0..10) (that is from 0 to 10 excluding) for an experiment of duration 5s:

```
$ python3 ./analyze.py /tmp/data 0 10 5
```

## Shutting down the profiler

When done with profiling, shutdown the profiler process:

```
$ profiler.sh kill_profiler
```
