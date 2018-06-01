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

# Green taxis

green_tripdata <- str_subset(tripdata_files, "green") %>%
  map(read_csv, col_types = pudo_cols) %>%
  bind_rows()


# Summarize pick-ups, drop-offs, and pick-up/drop-offs per taxi zone.

green_pu <- green_tripdata %>%
  group_by(PULocationID) %>%
  summarize(n = n()) %>%
  rename(LocationID = PULocationID, green_pu = n)

green_do <- green_tripdata %>%
  group_by(DOLocationID) %>%
  summarize(n = n()) %>%
  rename(LocationID = DOLocationID, green_do = n)

green_pudo <- full_join(green_pu, green_do) %>%
  replace_na(list(green_pu = 0, green_do = 0)) %>%
  mutate(green_pudo = green_pu + green_do)

save(green_pudo, file = here("data/green_pudo.RData"))
