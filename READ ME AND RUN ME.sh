curl 'https://uc957d3cfd4ce4e9a2a7693b596f.dl.dropboxusercontent.com/cd/0/get/CO594HidQMaouO-dy2Ui5R-GYLfEwk_fd0wbTvLt-NbX9uYMu0qlCe6jzvxmU_fuOe4Tw-NU5i5-IO7JD8q7trT-QnCi8n07Wk0jB3RH0LJl7X_giYtUcdzT-tSf6Y_-kvKQ9WIEz2dI-R9TtqYdJ-FMyEwE3kuO2VbBwrR3-hjWDw/file?_download_id=54011573735578952279416289084949949853881837179620392379633633&_notify_domain=www.dropbox.com&dl=1' \
  -H 'authority: uc957d3cfd4ce4e9a2a7693b596f.dl.dropboxusercontent.com' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'accept-language: en-GB,en-US;q=0.9,en;q=0.8' \
  -H 'accept-language: en-GB,en-US;q=0.9,en;q=0.8' \
  -H 'referer: https://www.dropbox.com/' \
  -H 'sec-ch-ua: "Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"' \
  -H 'sec-ch-ua: "Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: iframe' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-site: cross-site' \
  -H 'sec-fetch-user: ?1' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36' \
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
bash hdsearch-multinode.sh build_install
# nohup python3 run_experiment.py > exponential_run.txt EXPONENTIAL_RUN &