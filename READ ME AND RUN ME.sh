curl 'https://uc41afe9e97059dac2a701f32fe8.dl.dropboxusercontent.com/cd/0/get/CP7gzWmbqjXksI3QCoZ0sKYJvyu8CmGzSdvk_MNba7M5XxeLUwXYj76bS8Es9rB7nAcdQ68DI3DEeXwAxnmIH-kFoLAK2wh1jhBFXtQYiqcpoMOHpa2irB4rYH47oMW4ZSLVWNceolT2yYaYFj7MjE_uM6xpI-s_v2_-SWv9cXJSeg/file?_download_id=59787192845323147075982389919127328637655843556247246594446056034&_notify_domain=www.dropbox.com&dl=1' \
  -H 'authority: uc41afe9e97059dac2a701f32fe8.dl.dropboxusercontent.com' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'accept-language: en-US,en;q=0.9' \
  -H 'cache-control: no-cache' \
  -H 'pragma: no-cache' \
  -H 'referer: https://www.dropbox.com/' \
  -H 'sec-ch-ua: "Chromium";v="122", "Not(A:Brand";v="24", "Microsoft Edge";v="122"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  -H 'sec-fetch-dest: iframe' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-site: cross-site' \
  -H 'sec-fetch-user: ?1' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 Edg/122.0.0.0' \
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