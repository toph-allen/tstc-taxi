library(devtools)
library(tidyverse)
library(lubridate)
library(here)
library(sf)
library(viridis)
library(tidycensus)

load_all()

data_raw <- here("data-raw")

taxi_zones <- read_sf(file.path(data_raw, "taxi_zones"))

api_key <- scan(here("data-raw", "census_api_key"), what = character())

vars <- load_variables(2016, "acs5", cache = TRUE)
nyc_fips_codes <- c("005", "047", "061", "081", "085")

bracket_vars <- vars %>%
  filter(str_detect(name, "B19001_")) %>%
  mutate(varname = str_sub(name, 1, str_length(name)-1))

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


# Figure out which taxi zones overlap which tracts

intersections <- st_intersection(nyc_income, taxi_zones) %>%
  mutate(section_area = st_area(geometry),
         section_frac = section_area / tract_area) %>%
  mutate_at(vars(starts_with("B19001")), funs(. * section_frac))

intersections %>%
  filter(GEOID == 36061001300) %>%
  summarize_if(is.numeric, sum, na.rm = TRUE)

# This should be the same as the numbers from this line:
filter(nyc_income, GEOID == 36061001300)

# For a given LocationID, the following should be true.
intersections %>%
  filter(LocationID == 20) %>%
  summarize_if(is.numeric, sum, na.rm = TRUE) %>%
  select(2:17) %>%
  gather(key = "category", value = "value", -geometry, factor_key = TRUE) %>%
  summarize(tot = sum(value))
# should equal
intersections %>%
  filter(LocationID == 20) %>%
  summarize_if(is.numeric, sum, na.rm = TRUE) %>%
  pull(B19001_001E)

zone_income_wide <- intersections %>%
  group_by(LocationID) %>%
  summarize_at(vars(starts_with("B19001")), sum, na.rm = TRUE)

zone_income_wide %>%
  filter(LocationID == 20)

# Zones 3
zone_income_tidy <- zone_income_wide %>%
  select(-B19001_001E) %>%
  gather(key = "category", value = "value", -LocationID, -geometry, factor_key = TRUE)

levels(zone_income_tidy$category) <- distlabels

save(zone_income_wide, file = here("data", "zone_income_wide.RData"))
save(zone_income_tidy, file = here("data", "zone_income_tidy.RData"))

# Plotting

lid <- 183

zone_income_tidy %>%
  filter(LocationID == lid) %>%
  ggplot() +
  geom_col(aes(x = category, y = as.numeric(value))) +
  theme(axis.text.x=element_text(angle = 45, vjust = 0.75, hjust = 0.9))

ggplot(zone_income_wide) +
  geom_sf() +
  geom_sf(data = filter(zone_income_tidy, LocationID == lid), fill = "red", size = 1) +
  coord_sf(datum = NA) +
  theme_minimal()

taxi_zones %>%
  filter(LocationID == lid) %>%
  pull(zone)

# DO SOMETHING LIKE THIS
with(df, median(rep.int(avg, count)) )

# A plot of the variable which shows the number of people in the zone
ggplot(zone_income_wide) +
  geom_sf(aes(fill = as.numeric(B19001_001E))) +
  coord_sf(datum = NA)

ggplot(filter(zone_income_wide, LocationID == "50")) +
  geom_bar()
  # coord_sf(datum = NA)

zone <- filter(intersections, LocationID == "40")

ggplot() + 
  geom_sf(data = filter(nyc_income, GEOID %in% zone$GEOID)) +
  geom_sf(data = zone, fill = "red", size = 2) +
  facet_wrap(~ GEOID) +
  coord_sf(datum = NA)

ggplot() + 
  geom_sf(data = filter(taxi_zones, LocationID == "100")) +
  geom_sf(data = filter(intersections, LocationID == "100"), fill = "red", size = 2) +
  coord_sf(datum = NA)

mutate(zone, area = st_area(geometry)) %>% pull(area)

# Plots

ggplot(nyc_tracts) + 
  geom_sf() + 
  coord_sf(datum = NA)
  # theme_minimal()
  # scale_fill_viridis()


ggplot(nyc_income) + 
  geom_sf() + 
  coord_sf(datum = NA) + 
  theme_minimal()
