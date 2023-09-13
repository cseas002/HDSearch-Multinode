import ast
import copy
import csv
import os
import re
import statistics
import sys

def derive_datatype(datastr):
    try:
        return type(ast.literal_eval(datastr))
    except:
        return type("")

def read_timeseries(filepath):
    header = None
    timeseries = None
    with open(filepath, 'r') as f:
        header = f.readline().strip()
        timeseries = []
        data = f.readline().strip().split(',')
        datatype = derive_datatype(data[1])
        f.seek(0)
        for l in f.readlines()[1:]:
            data = l.strip().split(',')
            timestamp = int(data[0])
            value = datatype(data[1])
            timeseries.append((timestamp, value))
    return (header, timeseries)            

def add_metric_to_dict(stats_dict, metric_name, metric_value):
    head = metric_name.split('.')[0]
    tail = metric_name.split('.')[1:]
    if tail:
        stats_dict = stats_dict.setdefault(head, {})
        add_metric_to_dict(stats_dict, '.'.join(tail), metric_value)
    else:
        stats_dict[head] = metric_value

def parse_cstate_stats(stats_dir):
    stats = {}
    prog = re.compile('(.*)\.(.*)\.(.*)')
    for f in os.listdir(stats_dir):
        m = prog.match(f)
        if m:
            stats_file = os.path.join(stats_dir, f)
            cpu_id = m.group(1)
            state_name = m.group(2)
            metric_name = m.group(3)
            (metric_name, timeseries) = read_timeseries(stats_file)
            add_metric_to_dict(stats, metric_name, timeseries)
    return stats

def parse_perf_stats(stats_dir):
    stats = {}
    prog = re.compile('(.*)\.(.*)\.(.*)')
    for f in os.listdir(stats_dir):
        m = prog.match(f)
        if not m:
            stats_file = os.path.join(stats_dir, f)
            (metric_name, timeseries) = read_timeseries(stats_file)
            add_metric_to_dict(stats, metric_name, timeseries)
    return stats

def cpu_state_time_perc(data, cpu_id, experiment_time_duration_us):
    cpu_str = "CPU{}".format(cpu_id)
    state_names = ['POLL', 'C1', 'C1E', 'C6']
    state_time_perc = []
    total_state_time = 0
    time_us = 0
    # determine time window of measurements
    for state_name in state_names:
        if state_name in data[cpu_str]:
            (ts_start, val_start) = data[cpu_str][state_name]['time'][0]
            (ts_end, val_end) = data[cpu_str][state_name]['time'][-1]
            time_us = max(time_us, (ts_end - ts_start) * 1000000.0)
            total_state_time += val_end - val_start
    time_us = max(time_us, total_state_time)
    extra_c6_time_us = time_us - experiment_time_duration_us
    # calculate percentage
    for state_name in state_names:
        if state_name == 'C6':
            extra = extra_c6_time_us
        else:
            extra = 0
        if state_name in data[cpu_str]:
            (ts_start, val_start) = data[cpu_str][state_name]['time'][0]
            (ts_end, val_end) = data[cpu_str][state_name]['time'][-1]
            state_time_perc.append((val_end-val_start-extra)/time_us)
    # calculate C0 as the remaining time 
    state_time_perc[0] = 1 - sum(state_time_perc[1:4])
    state_names[0] = 'C0' 
    return state_time_perc

def avg_state_time_perc(stats, cpu_id_list, experiment_time_duration_us):
    total_state_time_perc = [0]*4
    cpu_count = 0
    for cpud_id in cpu_id_list:
        cpu_count += 1
        total_state_time_perc = [a + b for a, b in zip(total_state_time_perc, cpu_state_time_perc(stats, cpud_id, experiment_time_duration_us))]
    avg_state_time_perc = [a/b for a, b in zip(total_state_time_perc, [cpu_count]*len(total_state_time_perc))]
    return avg_state_time_perc

def cpu_state_usage(data, cpu_id):
    cpu_str = "CPU{}".format(cpu_id)
    state_names = ['POLL', 'C1', 'C1E', 'C6']
    state_time_perc = []
    total_state_time = 0
    time_us = 0
    state_usage_vec = []
    for state_name in state_names:
        if state_name in data[cpu_str]:
            (ts_start, val_start) = data[cpu_str][state_name]['usage'][0]
            (ts_end, val_end) = data[cpu_str][state_name]['usage'][-1]
            state_usage = val_end - val_start
            state_usage_vec.append(state_usage)
    return state_usage_vec

def avg_state_usage(stats, cpu_id_list):
    total_state_usage = [0]*4
    cpu_count = 0
    for cpud_id in cpu_id_list:
        cpu_count += 1
        total_state_usage = [a + b for a, b in zip(total_state_usage, cpu_state_usage(stats, cpud_id))]
    avg_state_usage = [a/b for a, b in zip(total_state_usage, [cpu_count]*len(total_state_usage))]
    return avg_state_usage

def main(argv):
    stats_root_dir = argv[1]
    cpu_range_begin = int(argv[2])
    cpu_range_end_exclusive = int(argv[3])
    experiment_time_duration_us = int(argv[4])*1000000
    stats = parse_cstate_stats(stats_root_dir)
    p = avg_state_time_perc(stats, range(cpu_range_begin, cpu_range_end_exclusive), experiment_time_duration_us)
    print(p)

if __name__ == '__main__':
    main(sys.argv)
