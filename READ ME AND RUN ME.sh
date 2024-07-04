# FIRSTLY, SEE fixed_cpu.sh UNDER cseas_scripts TO SET UP FIXED FREQUENCY

curl 'https://uc610185013189784f76acedf04b.dl.dropboxusercontent.com/cd/0/get/CV9_JjR9pYVx7eoRwvYHGsidiLKlSy6ngcSaZg1w4hdp5u7ag-tNuSBiL42Ar8CzoXnNpQHpcUrkibusFzTY0xhKYPRfoNLTplVdaBXWsvgzD-S1MQuNvk9-4NlsFOWyNYmifQ4KwkaUYLxnyp5dUHZLZpW53JjcOWEesS196LjqGA/file?_download_id=60704493642151223823677481109349914813287885175422509480808120808&_notify_domain=www.dropbox.com&dl=1' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'accept-language: en-US,en;q=0.9' \
  -H 'priority: u=0, i' \
  -H 'referer: https://www.dropbox.com/' \
  -H 'sec-ch-ua: "Not/A)Brand";v="8", "Chromium";v="126", "Microsoft Edge";v="126"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  -H 'sec-fetch-dest: iframe' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-site: cross-site' \
  -H 'sec-fetch-user: ?1' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36 Edg/126.0.0.0' \
  --output HDSearch-dataset.tgz

tar -xzvf HDSearch-dataset.tgz
rm HDSearch-dataset.tgz
sudo cp -r HDSearch /mydata/
cd

# find . -type d -exec chmod 700 {} \;
# find . -type f -exec chmod 700 {} \;


# mkdir /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
sudo cp /users/cseas002/HDSearch-Multinode/microsuite_files/bucket/* /mydata/HDSearch  # This doesn't do anything but whatever

for node in node1 node2 
do
sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
done

cd /users/cseas002/HDSearch-Multinode/
bash hdsearch-multinode.sh build_install
# You can do bash run.sh to run with different pre-request times
# nohup python3 run_experiment.py > ../pre.txt WITH_PRE_HELPER_THREAD &