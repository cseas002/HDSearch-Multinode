curl 'https://uc1fe2bbbedaa9621a3d4ebc5bae.dl.dropboxusercontent.com/cd/0/get/CM9lFVSIaNQycpC61X_rGTEyYqvBxk4FBkYeArnLTjIlNnPxzRiZmgFenG59JxKDpN6w0LlFsoK4XqDjU1R_6jh5DJHnRtMSOOsBpnOW8cHxncIl03qlImyvEcv6e0eWgSjaMLv8ZnSzxTxZjGeckAZVZ9ngBfezh20kT9wWZGLvlA/file?_download_id=56740495792785283365005960704277169649353272382445136655064965403&_notify_domain=www.dropbox.com&dl=1' \
  -H 'authority: uc1fe2bbbedaa9621a3d4ebc5bae.dl.dropboxusercontent.com' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'accept-language: en-GB,en-US;q=0.9,en;q=0.8' \
  -H 'referer: https://www.dropbox.com/' \
  -H 'sec-ch-ua: "Not A(Brand";v="99", "Google Chrome";v="121", "Chromium";v="121"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: iframe' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-site: cross-site' \
  -H 'sec-fetch-user: ?1' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36' \
  --compressed --output HDSearch-dataset.tgz

tar -xzvf HDSearch-dataset.tgz
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