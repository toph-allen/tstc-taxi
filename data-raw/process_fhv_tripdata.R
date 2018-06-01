library(tidyverse)
library(lubridate)
library(here)

data_raw <- here("data-raw")

# Load and process tripdata files

pudo_cols <- cols_only(
  Dispatching_base_num = col_character(),
  PUlocationID = col_integer(),
  DOlocationID = col_integer()
)

tripdata_files <- list.files(file.path(data_raw, "tripdata"), full.names = TRUE)

# FHVs

# Get TNC base list
fhv_bases <- read_csv(file.path(data_raw, "fhv_bases.csv"))
tnc_bases <- fhv_bases %>%
  filter(dba_category != "other") %>%
  pull(base_number)

fhv_tripdata <- str_subset(tripdata_files, "fhv") %>%
  map(read_csv, col_types = pudo_cols) %>%
  bind_rows()

tnc_tripdata <- filter(fhv_tripdata, Dispatching_base_num %in% tnc_bases)
otherfhv_tripdata <- filter(fhv_tripdata, !Dispatching_base_num %in% tnc_bases)


# Not all TNC trips have both PU and DO LocationIDs reported.

sum(is.na(tnc_tripdata$PUlocationID)) / nrow(tnc_tripdata)
sum(is.na(tnc_tripdata$DOlocationID)) / nrow(tnc_tripdata)

# For other FHVs:

sum(is.na(otherfhv_tripdata$PUlocationID)) / nrow(otherfhv_tripdata)
sum(is.na(otherfhv_tripdata$DOlocationID)) / nrow(otherfhv_tripdata)


# Summarize pick-ups, drop-offs, and pick-up/drop-offs per taxi zone.

tnc_pu <- tnc_tripdata %>%
  group_by(PUlocationID) %>%
  summarize(n = n()) %>%
  rename(LocationID = PUlocationID, tnc_pu = n)

tnc_do <- tnc_tripdata %>%
  group_by(DOlocationID) %>%
  summarize(n = n()) %>%
  rename(LocationID = DOlocationID, tnc_do = n)

tnc_pudo <- full_join(tnc_pu, tnc_do) %>%
  replace_na(list(tnc_pu = 0, tnc_do = 0)) %>%
  mutate(tnc_pudo = tnc_pu + tnc_do)

save(tnc_pudo, file = here("data/tnc_pudo.RData"))

# Do the same for FHVs which *aren't* TNCs.

fhv_pu <- fhv_tripdata %>%
  group_by(PUlocationID) %>%
  summarize(n = n()) %>%
  rename(LocationID = PUlocationID, fhv_pu = n)

fhv_do <- fhv_tripdata %>%
  group_by(DOlocationID) %>%
  summarize(n = n()) %>%
  rename(LocationID = DOlocationID, fhv_do = n)

fhv_pudo <- full_join(fhv_pu, fhv_do) %>%
  replace_na(list(fhv_pu = 0, fhv_do = 0)) %>%
  mutate(fhv_pudo = fhv_pu + fhv_do)

save(fhv_pudo, file = here("data/fhv_pudo.RData"))
