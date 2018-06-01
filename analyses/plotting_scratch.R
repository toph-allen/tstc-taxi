# The following code was copied from the end of load_census.R.
library(lubridate) # Loading lubridate here this because of function masking issues.
library(here)
source(here("data-raw", "load_census_data.R"))

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
