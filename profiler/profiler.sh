#!/bin/bash

export ANSIBLE_HOST_KEY_CHECKING=False
export PROFILER_HOME=~/HDSearch-Multinode/profiler

install_dep () {
  sudo apt-add-repository ppa:ansible/ansible -y
  sudo apt update
  sudo apt install ansible -y
  ansible-playbook -i hosts ansible/install_dep.yml
}

install () {
  install_dep
  local vars="PROFILER_HOME=${PROFILER_HOME}"
  ansible-playbook -v -i hosts -e "$vars" ansible/install.yml
}

run_profiler () {
  local vars="PROFILER_HOME=${PROFILER_HOME} ITERATION=$1 PID=$2"
  ansible-playbook -v -i hosts ansible/profiler.yml -e "$vars" --tags "run_profiler"
}

kill_profiler () {
  local vars="PROFILER_HOME=${PROFILER_HOME}"
  ansible-playbook -v -i hosts ansible/profiler.yml -e "$vars" --tags "kill_profiler"
}

"$@"

