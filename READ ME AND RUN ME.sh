curl 'https://uc27a62618fb0eaaf8dd8ae98fc3.dl.dropboxusercontent.com/cd/0/get/CO5evd06lcNGcwqmwKqTY2Jm8_Wr32zbBl6oPUSadaxmHJjCwj8YS676tcCdZ3uBgBXclnTGstP1k-Tg0Q66Yug9PtwLHoztwnWOsDy8t24rhiL5Tl05455SlFc_FATKbBXSRHZanRL7Jd5aEFd5jkJZ2OASW8wO1bD0ED4ydch6zw/file?_download_id=96342342328030163703358406056072970775045877162920830948050107856&_notify_domain=www.dropbox.com&dl=1' \
  -H 'authority: uc27a62618fb0eaaf8dd8ae98fc3.dl.dropboxusercontent.com' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'accept-language: en-GB,en-US;q=0.9,en;q=0.8' \
  -H 'referer: https://www.dropbox.com/' \
  -H 'sec-ch-ua: "Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: iframe' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-site: cross-site' \
  -H 'sec-fetch-user: ?1' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36' \
  --output HDSearch-dataset.tgz

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
# bash hdsearch-multinode.sh build_install
# nohup python3 run_experiment.py > first_test.txt FIRST_TEST &