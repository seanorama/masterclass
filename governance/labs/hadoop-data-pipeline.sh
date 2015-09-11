#!/usr/bin/env

function pause(){ read -p "$*" }

echo ## Creating Directories & Fetching Lab Files
sudo mkdir -p /tmp/data_pipeline_demo/input; chmod 777 /tmp/data_pipeline_demo/input
sudo mkdir /app; chown ${USER}:users /app; chmod 777 /app; cd /app
git clone -q https://github.com/seanorama/hadoop-data-pipeline/
cd hadoop-data-pipeline/scripts/

echo ## Preparing application environment
set+x; sudo ./setupAppOnHDFS.sh; set -x

pause "Press [Enter] to continue ..."

echo ## Updating feed & process dates
sudo ./changeValidityForFeed.sh
sudo ./changeValidityForProcess.sh

echo ## Inspect the feed:
set +x; cat ../falcon/feeds/inputFeed.xml; set -x
pause "Press [Enter] to continue ..."

echo ## Inspect the process:
set +x; cat ../falcon/process/processData.xml; set -x
pause "Press [Enter] to continue ..."

echo ## Submit & schedule the entities:
set+x
sudo ./submitEntities.sh
sudo ./scheduleEntities.sh
set -x
pause "Press [Enter] to continue ..."

echo ## Loading sample data to Flume
cp -a /app/hadoop-data-pipeline/input_data/SV-sample-1.xml /tmp/data_pipeline_demo/input/