library(devtools)
library(tidyverse)
library(lubridate)
library(here)
library(sf)

load_all()

data_raw <- here("data-raw")

zones <- read_sf(file.path(data_raw, "taxi_zones"))

ggplot(zones) +
  geom_sf(aes(fill = LocationID), color = NA) + 
  coord_sf(datum = NA) + 
  theme_minimal() + 
  scale_fill_viridis()

data(yellow_pudo)
