curl 'https://uc8549a2d74bbbcf70579bcd66c5.dl.dropboxusercontent.com/cd/0/get/CNHFMrzrYt9WhVIAvoSysALTVlvnT4cxJvy1n5cjqnp5cwnyTYP_tCLo8p6s9UcsCBdgygeWtN4wL9EFTTVHYE12BreRo0zi_k8xM1Gzn3GBorokoypYDB9_GODJprHiVazv-IR0z-3upfLVMWNNamITzhEN-txogg2wFDrCf8ZUUA/file?_download_id=90378392951427182527942368102092197594712249607129924562630242992&_notify_domain=www.dropbox.com&dl=1' \
  -H 'authority: uc8549a2d74bbbcf70579bcd66c5.dl.dropboxusercontent.com' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'accept-language: en-US,en;q=0.9' \
  -H 'cache-control: no-cache' \
  -H 'pragma: no-cache' \
  -H 'referer: https://www.dropbox.com/' \
  -H 'sec-ch-ua: "Not A(Brand";v="99", "Microsoft Edge";v="121", "Chromium";v="121"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  -H 'sec-fetch-dest: iframe' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-site: cross-site' \
  -H 'sec-fetch-user: ?1' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36 Edg/121.0.0.0' \
  --compressed --output HDSearch-dataset.tgz

tar -xzvf HDSearch-dataset.tgz
rm HDSearch-dataset.tgz
sudo cp -r HDSearch /mydata/
cd

# find . -type d -exec chmod 700 {} \;
# find . -type f -exec chmod 700 {} \;


# mkdir /mydata/HDSearch
sudo cp ./HDSearch-Multinode/microsuite_files/client/* /mydata/HDSearch
sudo cp ./HDSearch-Multinode/microsuite_files/midtier/* /mydata/HDSearch
sudo cp ./HDSearch-Multinode/microsuite_files/bucket/* /mydata/HDSearch  # This doesn't do anything but whatever

for node in node1 node2 
do
sudo scp -r /mydata/HDSearch cseas002@$node:/mydata/
done

cd /users/cseas002/HDSearch-Multinode/
bash hdsearch-multinode.sh build_install
nohup python3 run_experiment.py > midtier_change.txt MIDTIER_CHANGE &