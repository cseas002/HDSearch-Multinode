import math
import argparse
import copy
import functools
import logging
import subprocess
import sys
import time 
import os
import configparser
import socket
import common 
#from paramiko import SSHClient
#from scp import SCPClient



log = logging.getLogger(__name__)

def safeStr(obj):
    try: return str(obj).encode('ascii', 'ignore').decode('ascii')
    except: return ""


def exec_command(cmd):
    logging.info(cmd)
    result = subprocess.run(cmd.split(), stdout=subprocess.PIPE,stderr=subprocess.PIPE)
    for l in result.stdout.decode('utf-8').splitlines():
        logging.info(l)
    for l in result.stderr.decode('utf-8').splitlines():
        logging.info(l)
    return result.stdout.decode('utf-8').splitlines()

def run_ansible_playbook(inventory, extravars=None, playbook=None, tags=None):
    extravars = ' '.join(extravars) if extravars else ''
    if tags:
        tags = '--tags "{}"'.format(tags) 
    else:
        tags = ""
    cmd = 'ansible-playbook -v -i {} -e "{}" {} {}'.format(inventory, extravars, tags, playbook)
    print(cmd)
    exit_status = os.system(cmd)
    return exit_status

def start_remote():
    run_ansible_playbook(
        inventory='hosts', 
        playbook='ansible/install.yml')

def set_uncore_freq(conf, freq_mhz):
    freq_hex=format(freq_mhz//100, 'x')
    msr_val = "0x{}{}".format(freq_hex, freq_hex) 
    
    extravars = [
       'MSR_VALUE={}'.format(msr_val)]
    run_ansible_playbook(
       inventory='hosts', 
       extravars=extravars, 
       playbook='ansible/configure.yml')

def set_core_freq(conf, freq_mhz):
    extravars = [
       'CORE_FREQ={}MHz'.format(freq_mhz)]
    run_ansible_playbook(
       inventory='hosts', 
       extravars=extravars, 
       playbook='ansible/configure_core_freq.yml')

def set_profiler_hosts():
    run_ansible_playbook(
        inventory='hosts',
        playbook='ansible/profiler.yml', 
        tags='set_profiler_hosts')

def run_profiler(id):
    extravars = [
        'HOST_FILE={}'.format("~/HDSearch-Multinode/hosts"),
        'ITERATION={}'.format(id)]
    status_output=run_ansible_playbook(
        inventory='hosts', 
        extravars=extravars,
        playbook='ansible/profiler.yml', 
        tags='run_profiler')
    return status_output

def stop_profiler(bucket,midtier):

    for node in bucket:
        exec_command("sudo python3 profiler/profiler.py -n {} stop".format(node))

    for node in midtier:
        exec_command("sudo python3 /users/ganton12/HDSearch-Multinode/profiler/profiler.py -n {} stop".format(node))

def report_profiler(bucket,midtier,results_dir_path):
    
    for node in bucket:
        dir_path = os.path.join(results_dir_path, "bucket_" + node)
        exec_command("sudo python3 /users/ganton12/HDSearch-Multinode/profiler/profiler.py -n {} report -d {}".format(node,dir_path))

    for node in midtier:
        dir_path = os.path.join(results_dir_path, "midtier_" + node)
        exec_command("sudo python3 /users/ganton12/HDSearch-Multinode/profiler/profiler.py -n {} report -d {}".format(node,dir_path))

def kill_profiler(bucket,midtier):
    run_ansible_playbook(
        inventory='hosts', 
        playbook='ansible/profiler.yml', 
        tags='kill_profiler')

def init_manager():
    run_ansible_playbook(
        inventory='hosts', 
        playbook='ansible/hdsearch.yml', 
        tags='init_master')

def init_worker():
    run_ansible_playbook(
        inventory='hosts', 
        playbook='ansible/hdsearch.yml', 
        tags='init_workers')
def get_dataset():
    run_ansible_playbook(
        inventory='hosts', 
        playbook='ansible/hdsearch.yml', 
        tags='get_dataset')
def install_script_run():
    run_ansible_playbook(
        inventory='hosts', 
        playbook='ansible/install.yml', 
        tags='setup_docker')

def leave_swarm():
    run_ansible_playbook(
        inventory='hosts', 
        playbook='ansible/hdsearch.yml', 
        tags='leave_swarm')

def run_remote(client_conf):
    
    fin = open("docker-compose-swarm.yml", "rt")
    #read file contents to string
    data = fin.read()
    #find line you want to replace
    line=""
    for line in data.splitlines():
        if "dummy1" in line:
            break
    replace_with=line.split(" ")
    replace_with[-5] = client_conf.hdsearch_qps
    replace_with[-6] = client_conf.run_time
    my_str = " ".join(map(str, replace_with))
    #replace all occurrences of the required string
    data = data.replace(line, my_str)
    #close the input file
    fin.close()
    #open the input file in write mode
    fin = open("docker-compose-swarm.yml", "wt")
    #overrite the input file with the resulting data
    fin.write(data)
    #close the file
    fin.close()
    
    #export nodes

    for i in range(0,3):
        key="NODE" + str(i)
        os.environ[str(key)] = exec_command("ssh node{} hostname".format(i))[0]
    
    # Print the list of user's
    # environment variables
    
    #start microservice
    rc = os.system("cd ~/HDSearch-Multinode/; sudo docker stack deploy --compose-file=docker-compose-swarm.yml microsuite")
    #exec_command("cd ~/HDSearch-Multinode; sudo docker stack deploy --compose-file=docker-compose-swarm.yml microsuite >> /local/logs/setup_node_swarm.log  2>&1")
    
def kill_remote():
    rc = os.system('ssh -n node0 "cd ~/HDSearch-Multinode; sudo docker stack rm microsuite"')
    #exec_command("cd ~/HDSearch-Multinode; sudo docker stack rm microsuite")  

def host_is_reachable(host):
    return True if os.system("ping -c 1 {}".format(host)) == 0 else False

def hdsearch_node():
    config = configparser.ConfigParser(allow_no_value=True)
    config.read('hosts')
    bucket = list(config['bucket'].items())
    midtier = list(config['midtier'].items())
   
    bucket = [item for t in bucket for item in t]
    while bucket[-1] is None:
        del bucket[-1]
    
    midtier = [item for t in midtier for item in t]
    while midtier[-1] is None:
        del midtier[-1]
    
    return bucket,midtier

def wait_for_remote_node(node):
    while not host_is_reachable(node):
        logging.info('Waiting for remote host {}...'.format(node))
        time.sleep(30)
        pass

def configure_hdsearch_node(conf):
    bucket,midtier = hdsearch_node()
    print(str(bucket) + str(midtier))
    for node in bucket:
        print('ssh -n {} "cd ~/HDSearch-Multinode; sudo python3 configure.py -v --turbo={} --kernelconfig={} -v"'.format(node, conf['turbo'], conf['kernelconfig'][1]))
        rc = os.system('ssh -n {} "cd ~/HDSearch-Multinode; sudo python3 configure.py -v --turbo={} --kernelconfig={} -v"'.format(node, conf['turbo'], conf['kernelconfig'][1]))
        exit_status = rc >> 8 
        if exit_status == 2:
            logging.info('Rebooting remote host {}...'.format(node))
            os.system('ssh -n {} "sudo shutdown -r now"'.format(node))
            logging.info('Waiting for remote host {}...'.format(node))
            time.sleep(30)
            while not host_is_reachable(node):
                logging.info('Waiting for remote host {}...'.format(node))
                time.sleep(30)
                pass
            os.system('ssh -n {} "cd ~/HDSearch-Multinode; sudo python3 configure.py -v --turbo={} --kernelconfig={} -v"'.format(node, conf['turbo'], conf['kernelconfig'][1]))
            if conf['ht'] == False:
                os.system('ssh -n {} "echo "forceoff" | sudo tee /sys/devices/system/cpu/smt/control"'.format(node))
            os.system('ssh -n {} "sudo cpupower frequency-set -g performance"'.format(node))
            os.system('ssh -n {} "echo "0" | sudo tee /proc/sys/kernel/nmi_watchdog"'.format(node))
            
            if conf['turbo'] == False:
                os.system('ssh -n {} "~/HDSearch-Multinode/turbo-boost.sh disable"'.format(node))
    for node in midtier:
        print('ssh -n {} "cd ~/HDSearch-Multinode; sudo python3 configure.py -v --turbo={} --kernelconfig={} -v"'.format(node, conf['turbo'], conf['kernelconfig'][0]))
        rc = os.system('ssh -n {} "cd ~/HDSearch-Multinode; sudo python3 configure.py -v --turbo={} --kernelconfig={} -v"'.format(node, conf['turbo'], conf['kernelconfig'][0]))
        exit_status = rc >> 8 
        if exit_status == 2:
            logging.info('Rebooting remote host {}...'.format(node))
            os.system('ssh -n {} "sudo shutdown -r now"'.format(node))
            logging.info('Waiting for remote host {}...'.format(node))
            time.sleep(30)
            while not host_is_reachable(node):
                logging.info('Waiting for remote host {}...'.format(node))
                time.sleep(30)
                pass
            os.system('ssh -n {} "cd ~/HDSearch-Multinode; sudo python3 configure.py -v --turbo={} --kernelconfig={} -v"'.format(node, conf['turbo'], conf['kernelconfig'][0]))
            if conf['ht'] == False:
                os.system('ssh -n {} "echo "forceoff" | sudo tee /sys/devices/system/cpu/smt/control"'.format(node))
            os.system('ssh -n {} "sudo cpupower frequency-set -g performance"'.format(node))
            
            #disable nmi watchdog
            os.system('ssh -n {} "echo "0" | sudo tee /proc/sys/kernel/nmi_watchdog"'.format(node))
            
            if conf['turbo'] == False:
                os.system('ssh -n {} "~/HDSearch-Multinode/turbo-boost.sh disable"'.format(node))
    return bucket,midtier

def run_single_experiment(system_conf,root_results_dir, name_prefix, client_conf, idx,bucket,midtier):
    name = name_prefix + client_conf.shortname()
    results_dir_name = "{}-{}".format(name, idx)
    results_dir_path = os.path.join(root_results_dir, results_dir_name)
    hdsearch_results_dir_path = os.path.join(results_dir_path, 'hdsearch')
      
    # cleanup any processes left by a previous run

    kill_remote()
    kill_profiler(bucket,midtier)

    time.sleep(15)
    
    #run_profiler
    run_remote(client_conf)
    profiler_output = run_profiler(idx)
    
    if profiler_output != 0:
        return profiler_output
    print("Profilerrrrr putput " + str(profiler_output))
    
    run_output = run_ansible_playbook(
        inventory='hosts', 
        playbook='ansible/hdsearch.yml', 
        tags='check_status')
    
    if run_output != 0:
        return run_output
    

    stop_profiler(bucket,midtier)
    report_profiler(bucket,midtier,hdsearch_results_dir_path)
    
    client_results_path_name = os.path.join(results_dir_path, 'hdsearch_client')
    rawoutput=exec_command("sudo docker service logs microsuite_client --raw")
    exec_command("sudo touch {}".format(client_results_path_name))
    exec_command("sudo chmod 777 {}".format(client_results_path_name))
    with open(client_results_path_name, 'w') as fo:
        for l in rawoutput:
            fo.write(safeStr(l)+'\n')
    
    # cleanup
    kill_remote()
    kill_profiler(bucket,midtier)

    return 0

def run_multiple_experiments(root_results_dir, batch_name, system_conf, client_conf, midtier_conf, bucket_conf, iter):
    bucket,midtier=configure_hdsearch_node(system_conf)
    install_script_run()
    set_profiler_hosts()
    leave_swarm()
    init_manager()
    init_worker()
   
    time.sleep(500)
    name_prefix = "turbo={}-kernelconfig={}-{}-hyperthreading={}-".format(system_conf['turbo'], system_conf['kernelconfig'][0],system_conf['kernelconfig'][1],system_conf['ht'])
    request_qps = [500, 1000, 2000, 4000, 6000, 7000, 8000]
    root_results_dir = os.path.join(root_results_dir, batch_name)
    set_uncore_freq(system_conf, 2000)
    #timetorun=0
    #for freq in [1400, 1600, 1800, 2000, 2200, 2400]: #2400
    #set_core_freq(system_conf, 1600)
    
    for qps in request_qps:
        instance_conf = copy.copy(client_conf)
        instance_conf.set('hdsearch_qps', qps)
        #same work experiment
        #timetorun=int(int(instance_conf.run_time)*min(request_qps)/qps)
        #instance_conf.set('run_time',timetorun)
        iters_cycle=math.ceil(float(bucket_conf.perf_counters)/4.0)
        it = iters_cycle*(iter)
        while it >= iters_cycle*(iter) and it < iters_cycle*(iter+1):
            status = run_single_experiment(system_conf,root_results_dir, name_prefix, instance_conf, iter,bucket,midtier)
            if status != 0:
                time.sleep(60)
                continue 
            it = it + 1       
            time.sleep(60)
    leave_swarm()

def main(argv):


    # kernelconfig first argument is for midtier and second for bucket server
    system_confs = [
          #{'turbo': False, 'kernelconfig': ['disable_cstates', 'disable_cstates'], 'ht': False},
          #{'turbo': False, 'kernelconfig': ['baseline', 'baseline'], 'ht': False},
          #{'turbo': False, 'kernelconfig': ['disable_cstates', 'disable_cstates'], 'ht': False},
          #{'turbo': False, 'kernelconfig': ['disable_c6', 'disable_c6'], 'ht': False},
          #{'turbo': False, 'kernelconfig': ['disable_c1e_c6', 'disable_c1e_c6'], 'ht': False},
          {'turbo': True, 'kernelconfig': ['disable_cstates', 'disable_cstates'], 'ht': True}
          #{'turbo': False, 'kernelconfig': ['disable_cstates', 'baseline'], 'ht': False},
          #{'turbo': False, 'kernelconfig': ['disable_cstates', 'disable_c6'], 'ht': False},
          #{'turbo': False, 'kernelconfig': ['disable_cstates', 'disable_c1e_c6'], 'ht': False},
          #{'turbo': False, 'kernelconfig': ['baseline', 'disable_cstates'], 'ht': False},
          #{'turbo': False, 'kernelconfig': ['disable_c6', 'disable_cstates'], 'ht': False},
          #{'turbo': False, 'kernelconfig': ['disable_c1e_c6', 'disable_cstates'], 'ht': False}
    ]
    client_conf = common.Configuration({
        'dataset_filepath': '/home/image_feature_vectors.dat',
        'result_filepath': './results',
        'knn': '1',
        'warmup_time': '10',
        'run_time': '120',
        'warmup_qps': '500',
        'run_qps': '1',
        'IP': '0.0.0.0',
        'port': '50054',
        'hdsearch_qps': '1',
        'cores': '1',
        'cpu': '3'
    })

    midtier_conf = common.Configuration({
        'hash_tables': '1',
        'key_length': '13',
        'probe_level': '1',
        'bucket_servers': '4',
        'ip_file_path': 'bucket_servers_IP.txt',
        'dataset_filepath': '/home/image_feature_vectors.dat',
        'readmode': '2',
        'IP': '0.0.0.0',
        'port': '50054',
        'network_threads': '1',
        'dispatch_threads': '1',
        'response_threads': '1',
        'stats': '0',
        'cores': '2'    #'2'
    })

    bucket_conf = common.Configuration({
        'dataset_filepath': '/home/image_feature_vectors.dat',
        'IP': ['0.0.0.0'],
        'port': ['50050', '50051', '50052', '50053'],
        'readmode': '2',
        'threads': '1',
        'bucket_id': ['0', '1', '2', '3'],
        'num_buckets': '4',
        'cores': ['3', '4', '5', '6'],
        'perf_counters': '4' #'50' #'15'
    })
   
    logging.getLogger('').setLevel(logging.INFO)
    if len(argv) < 1:
        raise Exception("Experiment name is missing")
    batch_name = argv[0]
    for iter in range(0, 5):
        for system_conf in system_confs:
            run_multiple_experiments('/users/ganton12/data', batch_name, system_conf, client_conf, midtier_conf, bucket_conf, iter)


if __name__ == '__main__':
    main(sys.argv[1:])
