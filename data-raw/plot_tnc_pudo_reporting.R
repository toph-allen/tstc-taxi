library(tidyverse)
library(lubridate)
library(here)

data_raw <- here("data-raw")

# Load and process tripdata files

pudo_cols <- cols_only(
  Dispatching_base_num = col_character(),
  Pickup_DateTime = col_datetime(),
  PUlocationID = col_integer(),
  DOlocationID = col_integer()
)

tripdata_files <- c("https://s3.amazonaws.com/nyc-tlc/trip+data/fhv_tripdata_2017-01.csv",
                    "https://s3.amazonaws.com/nyc-tlc/trip+data/fhv_tripdata_2017-02.csv",
                    "https://s3.amazonaws.com/nyc-tlc/trip+data/fhv_tripdata_2017-03.csv",
                    "https://s3.amazonaws.com/nyc-tlc/trip+data/fhv_tripdata_2017-04.csv",
                    "https://s3.amazonaws.com/nyc-tlc/trip+data/fhv_tripdata_2017-05.csv",
                    "https://s3.amazonaws.com/nyc-tlc/trip+data/fhv_tripdata_2017-06.csv")

# This takes a while to run, because these are big files.
fhv_tripdata <- tripdata_files %>%
  map(read_csv, col_types = pudo_cols, progress = TRUE) %>%
  bind_rows()

# Get TNC base list
fhv_bases <- read_csv(file.path(data_raw, "fhv_bases.csv"))
tnc_bases <- fhv_bases %>%
  filter(dba_category != "other") %>%
  pull(base_number)

tnc_tripdata <- filter(fhv_tripdata, Dispatching_base_num %in% tnc_bases)
otherfhv_tripdata <- filter(fhv_tripdata, !Dispatching_base_num %in% tnc_bases)


# Not all TNC trips have both PU and DO LocationIDs reported.

# 8%
sum(is.na(tnc_tripdata$PUlocationID)) / nrow(tnc_tripdata)

# 83%
sum(is.na(tnc_tripdata$DOlocationID)) / nrow(tnc_tripdata)

# For other FHVs:

# 91%
sum(is.na(otherfhv_tripdata$PUlocationID)) / nrow(otherfhv_tripdata)

# 85%
sum(is.na(otherfhv_tripdata$DOlocationID)) / nrow(otherfhv_tripdata)

# We could see if it differs by month.

tnc_nas <- tnc_tripdata %>%
  mutate(month = month(Pickup_DateTime)) %>%
  group_by(month) %>%
  summarize(pu_na = sum(is.na(PUlocationID)),
            do_na = sum(is.na(DOlocationID)),
            n = n()) %>%
  mutate(pickup_nas = pu_na / n,
         dropoff_nas = do_na / n) %>%
  select(-pu_na, -do_na, -n) %>%
  gather(category, proportion, pickup_nas, dropoff_nas)

month_levels <- seq(1, 12)
month_labels <- c(
  "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
)

tnc_nas <- mutate(tnc_nas, month_fct = factor(month, month_levels, month_labels))

ggplot(tnc_nas, aes(x = month_fct, group = category)) +
  geom_col(aes(y = proportion, fill = category), position = "dodge") +
  labs(title = "Proportion of TNC pick-ups and drop-offs with missing data", y = "Proportion not reported", x = "Month of 2017")

ggsave(here("figures", "tnc_pudo_reporting.png"), width = 6.5, height = 5)
