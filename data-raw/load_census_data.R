library(tidyverse)
library(lubridate)
library(here)
library(sf)
library(viridis)
library(tidycensus)

data_raw <- here("data-raw")

taxi_zones <- read_sf(file.path(data_raw, "taxi_zones"))

api_key <- scan(here("data-raw", "census_api_key"), what = character())

# Grab income bracket data

vars <- load_variables(2016, "acs5", cache = TRUE)
nyc_fips_codes <- c("005", "047", "061", "081", "085")

bracket_vars <- vars %>%
  filter(str_detect(name, "B19001_")) %>%
  mutate(varname = str_sub(name, 1, str_length(name)-1))

# Here, we remove the "total" variable, and grab the category labels.
varnames <- pull(bracket_vars, varname)
distnames <- varnames[-1]
distlabels <- pull(bracket_vars, label)[-1] %>%
  map_chr(~ str_split(.x, pattern = "!!", simplify = TRUE)[3])

nyc_income_raw <- get_acs(geography = "tract",
                          variables = varnames,
                          cache_table = TRUE,
                          year = 2016,
                          state = "NY",
                          county = c("005", "047", "061", "081", "085"),
                          geometry = TRUE,
                          output = "wide",
                          key = api_key)

save(nyc_income_raw, file = here("data", "nyc_income_raw.RData"))

nyc_income <- nyc_income_raw %>%
  select(-ends_with("M")) %>%
  st_transform(st_crs(taxi_zones)) %>%
  mutate(tract_area = st_area(geometry))


# Generate an "intersections" dataset, splitting up census tracts across taxi
# zones.

intersections <- st_intersection(nyc_income, taxi_zones) %>%
  mutate(section_area = st_area(geometry),
         section_frac = section_area / tract_area) %>%
  mutate_at(vars(starts_with("B19001")), funs(. * section_frac))


#---------------------------------------#
# This section of code prints out some stuff to check that the way
# we're doing things makes sense.

# This code prints out the figures for a single zone.
intersections %>%
  filter(GEOID == 36061001300) %>%
  summarize_if(is.numeric, sum, na.rm = TRUE)

# The previous output should be the same as the numbers from this line:
filter(nyc_income, GEOID == 36061001300)

# For a given LocationID, the following...
intersections %>%
  filter(LocationID == 20) %>%
  summarize_if(is.numeric, sum, na.rm = TRUE) %>%
  select(2:17) %>%
  gather(key = "category", value = "value", -geometry, factor_key = TRUE) %>%
  summarize(tot = sum(value))
# ...should equal this:
intersections %>%
  filter(LocationID == 20) %>%
  summarize_if(is.numeric, sum, na.rm = TRUE) %>%
  pull(B19001_001E)

# Back to our regularly scheduled programming...
#---------------------------------------#

# We group the split up data by taxi zone and sum all the census tract pieces'
# data.
zone_income_wide <- intersections %>%
  group_by(LocationID) %>%
  summarize_at(vars(starts_with("B19001")), sum, na.rm = TRUE)

zone_income_tidy <- zone_income_wide %>%
  select(-B19001_001E) %>%
  gather(key = "category", value = "value", -LocationID, -geometry, factor_key = TRUE)

levels(zone_income_tidy$category) <- distlabels

save(zone_income_wide, file = here("data", "zone_income_wide.RData"))
save(zone_income_tidy, file = here("data", "zone_income_tidy.RData"))
