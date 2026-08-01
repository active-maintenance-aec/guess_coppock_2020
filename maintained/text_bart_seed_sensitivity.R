# guess_coppock_2020 — text_bart_seed_sensitivity.R
# Output: output/text_bart_seed_sensitivity.csv
# Depends on: original/GC_study_1.RData, GC_Study_2.RData, GC_Study_3.RData, helpers.R, bart_helpers.R
# Description: How far the two in-text BART proportions move across random seeds.
#   The deposited script sets no seed, so this is the range within which its
#   published values ("93 per cent", "77 per cent") should be read.

source(here::here("maintained", "helpers.R"))
source(here::here("maintained", "bart_helpers.R"))

seeds <- c(20180101, 1, 2, 3, 5, 8, 13, 21, 34, 55)

# Refit across seeds ----
by_seed <- map(seeds, fit_bart_effects) |>
  list_rbind() |>
  group_by(seed, treatment) |>
  summarise(
    prop_correctly_signed = if_else(
      first(treatment) == "Positive Information",
      mean(tau_hat > 0),
      mean(tau_hat < 0)
    ),
    .groups = "drop"
  )

write_csv(by_seed, here::here("maintained", "output", "text_bart_seed_sensitivity.csv"))

# Range across seeds ----
across_seeds <- by_seed |>
  group_by(treatment) |>
  summarise(
    n_seeds = n(),
    min = min(prop_correctly_signed),
    median = median(prop_correctly_signed),
    max = max(prop_correctly_signed),
    .groups = "drop"
  )

print(across_seeds)
