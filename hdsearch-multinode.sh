#!/bin/bash

export ANSIBLE_HOST_KEY_CHECKING=False

get_profiler () {

  if [[ ! -d "profiler/" ]]; then
 
    git clone https://github.com/georgiantoniou/profiler.git

  fi
 
}

install_dep () {
  #sudo apt update
  sudo apt-add-repository ppa:ansible/ansible -y
  sudo apt update
  sudo apt install ansible -y
  ansible-playbook -i hosts ansible/install_dep.yml
}

build () {
  get_profiler
  pushd ~
  tar -czf HDSearch-Multinode.tgz HDSearch-Multinode
  popd
 }	

build_install () {
  install_dep
  build
  ansible-playbook -v -i hosts ansible/install.yml
  echo "irtaaaaaaaaaa"
}

"$@"
