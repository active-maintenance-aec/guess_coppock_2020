# guess_coppock_2020 — table_4_study2_conditions.R
# Output: output/table_4_study2_conditions.csv, output/table_4_study2_conditions.tex
# Depends on: original/GC_Study_2.RData, helpers.R
# Description: Study 2 (minimum wage) treatment condition means and bootstrapped SDs.

source(here::here("maintained", "helpers.R"))
set.seed(20180101)

# Data ----
load(here::here("original", "GC_Study_2.RData"))

study_2_sub <- study_2 |> select(condition_type, favor_T2_recode, amount_T2)


# Observed means and SDs ----
tab_means <- study_2 |>
  group_by(condition_type) |>
  summarise(
    n                    = n(),
    positive_information = mean(positive_information),
    negative_information = mean(negative_information),
    favor_mean           = mean(favor_T2_recode),
    favor_sd             = sd(favor_T2_recode),
    amount_mean          = mean(amount_T2),
    amount_sd            = sd(amount_T2),
    .groups = "drop"
  )


# Bootstrapped SEs of the mean and SD estimates ----
boot_sds <- bootstraps(study_2_sub, times = 1000) |>
  mutate(stats = map(splits, function(split) {
    d <- as.data.frame(split)
    d |>
      group_by(condition_type) |>
      summarise(
        favor_mean  = mean(favor_T2_recode),
        favor_sd    = sd(favor_T2_recode),
        amount_mean = mean(amount_T2),
        amount_sd   = sd(amount_T2),
        .groups = "drop"
      )
  })) |>
  select(stats) |>
  unnest(stats) |>
  group_by(condition_type) |>
  summarise(
    favor_mean_bsd  = sd(favor_mean),
    favor_sd_bsd    = sd(favor_sd),
    amount_mean_bsd = sd(amount_mean),
    amount_sd_bsd   = sd(amount_sd),
    .groups = "drop"
  )


# Assemble display table ----
tab <- tab_means |>
  left_join(boot_sds, by = "condition_type") |>
  mutate(condition_type = factor(condition_type,
    labels = c("Placebo", "Con Young / Con Old", "Pro Old / Con Old",
               "Pro Old / Con Young", "Pro Young / Con Old",
               "Pro Young / Con Young", "Pro Young / Pro Old"))) |>
  arrange(condition_type)


# Save ----
write_csv(tab, here::here("maintained", "output", "table_4_study2_conditions.csv"))


# LaTeX table ----
tex <- kable(tab, format = "latex", booktabs = TRUE, digits = 2,
             caption = "Study 2 (minimum wage): treatment conditions") |>
  kable_styling(latex_options = c("hold_position", "scale_down"))

write_lines(tex, here::here("maintained", "output", "table_4_study2_conditions.tex"))
