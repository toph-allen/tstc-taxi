#!/bin/bash

# Download TLC tripdata files from the specified list.
tripdata
wget -i 2017_tripdata_urls.txt -P tripdata

# Download TLC taxi_zones shapefiles
wget https://s3.amazonaws.com/nyc-tlc/misc/taxi_zones.zip
unzip taxi_zones.zip -d taxi_zones

# Download Todd Schneider's FHV bases CSV file.
wget https://raw.githubusercontent.com/toddwschneider/nyc-taxi-data/master/data/fhv_bases.csv