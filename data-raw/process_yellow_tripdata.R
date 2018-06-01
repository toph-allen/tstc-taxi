library(tidyverse)
library(lubridate)
library(here)

data_raw <- here("data-raw")


# Load and process tripdata files

pudo_cols <- cols_only(
  PULocationID = col_integer(),
  DOLocationID = col_integer(),
  Pickup_DateTime = col_datetime()
)

tripdata_files <- list.files(file.path(data_raw, "tripdata"), full.names = TRUE)

# Yellow taxis

yellow_tripdata <- str_subset(tripdata_files, "yellow") %>%
  map(read_csv, col_types = pudo_cols) %>%
  bind_rows()


# Summarize pick-ups, drop-offs, and pick-up/drop-offs per taxi zone.

yellow_pu <- yellow_tripdata %>%
  group_by(PULocationID) %>%
  summarize(n = n()) %>%
  rename(LocationID = PULocationID, yellow_pu = n)

yellow_do <- yellow_tripdata %>%
  group_by(DOLocationID) %>%
  summarize(n = n()) %>%
  rename(LocationID = DOLocationID, yellow_do = n)

yellow_pudo <- full_join(yellow_pu, yellow_do) %>%
  replace_na(list(yellow_pu = 0, yellow_do = 0)) %>%
  mutate(yellow_pudo = yellow_pu + yellow_do)

save(yellow_pudo, file = here("data/yellow_pudo.RData"))
