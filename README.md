# tstc-taxi: Exploring the income distribution of NYC's car services

This repository is a visualization of the income distribution the areas served by different types of car services in New York City.

The repo contains the code required to download and process the raw data, interstitial .RData files produced by the raw data processing, scripts to produce plots of car service income distributions, and the resulting plots.

## Directory Structure

The code is in R. This repo doesn't currently conform to the R package standard. The directory structure is as follows:

- `analyses`: Scripts to produce plots (and any other outputs to be added at a later date).
- `data-raw`: Scripts to download and process raw data. Raw data files are also downloaded to this directory. Outputs to `data`.
- `data`: Processed .RData files containing the processed and aggregated output of the scripts in `data-raw`.
- `figures`: The outputs of `analyses`.

## Running the Code

### Downloading Raw Taxi Data

Make sure you've installed all the packages which are referenced by the scripts.

```r
install.packages(c("devtools", "tidyverse", "here", "sf", "viridis", "tidycensus" "scales"))
```

Run the `download_data_files.sh` script, which downloads (1) taxicab tripdata files from TLC for the second half of 2017 (the list of files is stored in `2017_tripdata_urls.txt`), (2) taxi zone shapefiles, and (3) the FHV (For Hire Vehicle) taxi bases CSV file from Todd Schneider's [nyc-taxi-data repo](https://github.com/toddwschneider/nyc-taxi-data). We use the latter data file instead of any provided by the city because it lets us distinguish between transit network companies (TNCs) like Lyft and Uber and other for-hire non-taxi cars.

```bash
cd data-raw
./download_data_files.sh
cd ..
```

We only use the second half of 2017 because at the start of that year, TNCs didn't report the location of their pick-ups and drop-offs. The script `data-raw/plot_tnc_pudo_reporting.R` will plot this data, using downloading the requisite data files at runtime using `read_csv()`. Be warned, these are large files, so this script is fairly RAM-heavy and takes a while to run. It's not required to do the full analysis.

### Processing Taxi Data

The three scripts `process_fhv_tripdata.R`, `process_yellow_tripdata.R`, and `process_green_tripdata.R` each process the respective tripdata files for that type of car service.

All of these scripts read the tripdata files, and aggregate pick-ups only (PUs), drop-offs only (DOs), and pick-ups and drop-offs combined (PUDOs) by taxi zone, saving a data file with four columns: one for taxi zone, and one for each type of aggregation. (The interstitial data files are saved as .RData files containing tibbles in the `data` directory.)

Green and yellow cab data are processed identically. FHV data are first filtered by the taxi base of the car making the trip to separate TNCs and other FHVs. We save the other FHV data, but don't use it later on.

### Processing Census Data

The script `load_census_data.R` downloads and processes the census data used in the analysis.

N.B. To run this script, you must first [sign up for a US census API key](https://api.census.gov/data/key_signup.html). When you receive the key, put it in a file named `census_api_key` in the `data-raw` directory.

TODO: Finish write-up.
