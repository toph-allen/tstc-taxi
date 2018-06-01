library(devtools)
library(tidyverse)
library(lubridate)
library(here)
library(sf)
library(scales)

figure_dir <- here("figures")
data_dir <- here("data")

load(file.path(data_dir, "zone_income_tidy.RData"))

zone_income <- zone_income_tidy %>%
  group_by(LocationID) %>%
  mutate(proportion = as.numeric(value) / sum(as.numeric(value))) %>%
  st_set_geometry(NULL)


# Green Taxi

load(file.path(data_dir, "green_pudo.RData"))

green_dist <- zone_income %>%
  select(LocationID, category, proportion) %>%
  left_join(select(green_pudo, LocationID, green_do)) %>%
  mutate(dist_by_zone = proportion * green_do) %>%
  ungroup() %>%
  group_by(category) %>%
  summarize(do_income_dist = sum(dist_by_zone, na.rm = TRUE)) %>%
  mutate(taxi = "Green")

# ggplot(green_dist) +
#   geom_col(aes(x = category, y = do_income_dist)) +
#   theme(axis.text.x=element_text(angle = 45, vjust = 0.75, hjust = 0.9))


# Yellow Taxi

load(file.path(data_dir, "yellow_pudo.RData"))

yellow_dist <- zone_income %>%
  select(LocationID, category, proportion) %>%
  left_join(select(yellow_pudo, LocationID, yellow_do)) %>%
  mutate(dist_by_zone = proportion * yellow_do) %>%
  ungroup() %>%
  group_by(category) %>%
  summarize(do_income_dist = sum(dist_by_zone, na.rm = TRUE)) %>%
  mutate(taxi = "Yellow")

# ggplot(yellow_dist) +
#   geom_col(aes(x = category, y = do_income_dist)) +
#   theme(axis.text.x=element_text(angle = 45, vjust = 0.75, hjust = 0.9))


# TNCs

load(file.path(data_dir, "tnc_pudo.RData"))

tnc_dist <- zone_income %>%
  select(LocationID, category, proportion) %>%
  left_join(select(tnc_pudo, LocationID, tnc_do)) %>%
  mutate(dist_by_zone = proportion * tnc_do) %>%
  ungroup() %>%
  group_by(category) %>%
  summarize(do_income_dist = sum(dist_by_zone, na.rm = TRUE)) %>%
  mutate(taxi = "TNC")

# ggplot(tnc_dist) +
#   geom_col(aes(x = category, y = do_income_dist)) +
#   theme(axis.text.x=element_text(angle = 45, vjust = 0.75, hjust = 0.9))


# Join

do_income_dist <- bind_rows(list(green_dist, yellow_dist, tnc_dist)) %>%
  mutate(taxi = factor(taxi)) %>%
  group_by(taxi) %>%
  mutate(proportion = do_income_dist / sum(do_income_dist))


# Plot

ggplot(do_income_dist) +
  geom_col(aes(x = category, y = do_income_dist, fill = taxi),
           position = "dodge") +
  theme(axis.text.x=element_text(angle = 45, vjust = 0.75, hjust = 0.9)) +
  labs(x = "Income Category (ACS 2016 Data)",
       y = "Number of Trips per Income Category Share",
       title = "Aggregated Income Distributions for Drop-offs\nMade by Car Services in NYC in Q3-Q4 2017") +
  scale_y_continuous(labels = comma) +
  scale_fill_manual(values = c("#9BD134", "#48C0DA", "#F7B731"))
ggsave(here("figures", "do_income_dist.png"), width = 6.5, height = 5)


ggplot(do_income_dist) +
  geom_col(aes(x = category, y = proportion, fill = taxi),
           position = "dodge") +
  theme(axis.text.x=element_text(angle = 45, vjust = 0.75, hjust = 0.9)) +
  labs(x = "Income Category (ACS 2016 Data)",
       y = "Proportion of Drop-offs",
       title = "Income Distribution of Drop-off Taxi Zones Served by\nCar Services in NYC in Q3-Q4 2017 (Drop-offs Only)") +
  scale_y_continuous(labels = comma) +
  scale_fill_manual(values = c("#9BD134", "#48C0DA", "#F7B731"))
ggsave(here("figures", "do_relative_income_dist_1.png"), width = 6.5, height = 5)


ggplot(do_income_dist) +
  geom_path(aes(x = category, y = proportion, color = taxi, group = taxi)) +
  theme(axis.text.x=element_text(angle = 45, vjust = 0.75, hjust = 0.9)) +
  labs(x = "Income Category (ACS 2016 Data)",
       y = "Proportion of Drop-offs",
       title = "Income Distribution of Drop-off Taxi Zones Served by\nCar Services in NYC in Q3-Q4 2017 (Drop-offs Only)") +
  scale_y_continuous(labels = comma) +
  scale_color_manual(values = c("#9BD134", "#48C0DA", "#F7B731"))
ggsave(here("figures", "do_relative_income_dist_2.png"), width = 6.5, height = 5)


# Collapsing income categories

do_income_dist2 <- bind_rows(list(green_dist, yellow_dist, tnc_dist)) %>%
  mutate(category = fct_collapse(category,
    "Less than $44,999" = c("Less than $10,000",
                            "$10,000 to $14,999",
                            "$15,000 to $19,999",
                            "$20,000 to $24,999",
                            "$25,000 to $29,999",
                            "$30,000 to $34,999",
                            "$35,000 to $39,999",
                            "$40,000 to $44,999"),
    "45,000 to $99,999" = c("$45,000 to $49,999",
                            "$50,000 to $59,999",
                            "$60,000 to $74,999",
                            "$75,000 to $99,999"),
    "$100,000 or more" = c("$100,000 to $124,999",
                           "$125,000 to $149,999",
                           "$150,000 to $199,999",
                           "$200,000 or more"))) %>%
  group_by(category, taxi) %>%
  summarize(do_income_dist = sum(do_income_dist)) %>%
  mutate(taxi = factor(taxi)) %>%
  group_by(taxi) %>%
  mutate(proportion = do_income_dist / sum(do_income_dist))


# Plot these

ggplot(do_income_dist2) +
  geom_col(aes(x = category, y = do_income_dist, fill = taxi),
           position = "dodge") +
  labs(x = "Income Category (Aggregated ACS 2016 Data)",
       y = "Number of Trips per Income Category Share",
       title = "Aggregated Income Distributions for Drop-offs\nMade by Car Services in NYC in Q3-Q4 2017") +
  scale_y_continuous(labels = comma) +
  scale_fill_manual(values = c("#9BD134", "#48C0DA", "#F7B731"))
ggsave(here("figures", "do_income_dist_new_cats.png"), width = 6.5, height = 5)


ggplot(do_income_dist2) +
  geom_col(aes(x = category, y = proportion, fill = taxi),
           position = "dodge") +
  labs(x = "Income Category (Aggregated ACS 2016 Data)",
       y = "Proportion of Drop-offs",
       title = "Income Distribution of Drop-off Taxi Zones Served by\nCar Services in NYC in Q3-Q4 2017 (Drop-offs Only)") +
  scale_y_continuous(labels = comma) +
  scale_fill_manual(values = c("#9BD134", "#48C0DA", "#F7B731"))
ggsave(here("figures", "do_relative_income_dist_1_new_cats.png"), width = 6.5, height = 5)


ggplot(do_income_dist2) +
  geom_path(aes(x = category, y = proportion, color = taxi, group = taxi)) +
  labs(x = "Income Category (Aggregated ACS 2016 Data)",
       y = "Proportion of Drop-offs",
       title = "Income Distribution of Drop-off Taxi Zones Served by\nCar Services in NYC in Q3-Q4 2017 (Drop-offs Only)") +
  scale_y_continuous(labels = comma) +
  scale_color_manual(values = c("#9BD134", "#48C0DA", "#F7B731"))
ggsave(here("figures", "do_relative_income_dist_2_new_cats.png"), width = 6.5, height = 5)