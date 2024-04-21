curl 'https://uc4d4e5ac2d21976e8d90ac5bdd9.dl.dropboxusercontent.com/cd/0/get/CRecgdUYdHcqSd1S_VvckCz1o2_cEyyQtNsWdZGLAvKfJ474iwBhOHjFsarcpx6AzQzu-p06niLOMi0J6_HHkwYzdnQo8ez1OJ21rGOctYe5nL3xfh-GhUKWuRY2eIA0YXer1rAyAyGV_KvTkokx1FxBXhuMIuINcdmg14Bcv-elcQ/file?_download_id=708612180817331361800045212786992458988528850565336124193516380854&_notify_domain=www.dropbox.com&dl=1' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'accept-language: en-US,en;q=0.9' \
  -H 'referer: https://www.dropbox.com/' \
  -H 'sec-ch-ua: "Microsoft Edge";v="123", "Not:A-Brand";v="8", "Chromium";v="123"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  -H 'sec-fetch-dest: iframe' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-site: cross-site' \
  -H 'sec-fetch-user: ?1' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36 Edg/123.0.0.0' \
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