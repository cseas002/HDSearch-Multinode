# See logs
sudo docker service logs microsuite_client --raw

# Mannually run docker 
sudo docker stack deploy --compose-file=docker-compose-swarm.yml microsuite