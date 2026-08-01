# guess_coppock_2020/maintained/table_7_study3_conditions.R
# Output: output/table_7_study3_conditions.csv, output/table_7_study3_conditions.tex
# Depends on: original/GC_Study_3.RData, helpers.R
# Description: Study 3 (capital punishment) treatment condition means and bootstrapped SDs.

source(here::here("maintained", "helpers.R"))
set.seed(20180101)

# Data ----
load(here::here("original", "GC_Study_3.RData"))

study_3_sub <- study_3 |> select(condition_factor, support_recode_T2, deter_recode_T2)


# Observed means and SDs ----
tab_means <- study_3 |>
  group_by(condition_factor) |>
  summarise(
    n                    = n(),
    positive_information = mean(positive_information),
    negative_information = mean(negative_information),
    support_mean         = mean(support_recode_T2),
    support_sd           = sd(support_recode_T2),
    deter_mean           = mean(deter_recode_T2),
    deter_sd             = sd(deter_recode_T2),
    .groups = "drop"
  )


# Bootstrapped SEs of the mean and SD estimates ----
boot_sds <- bootstraps(study_3_sub, times = 1000) |>
  mutate(stats = map(splits, function(split) {
    d <- as.data.frame(split)
    d |>
      group_by(condition_factor) |>
      summarise(
        support_mean = mean(support_recode_T2),
        support_sd   = sd(support_recode_T2),
        deter_mean   = mean(deter_recode_T2),
        deter_sd     = sd(deter_recode_T2),
        .groups = "drop"
      )
  })) |>
  select(stats) |>
  unnest(stats) |>
  group_by(condition_factor) |>
  summarise(
    support_mean_bsd = sd(support_mean),
    support_sd_bsd   = sd(support_sd),
    deter_mean_bsd   = sd(deter_mean),
    deter_sd_bsd     = sd(deter_sd),
    .groups = "drop"
  )


# Assemble display table ----
tab <- tab_means |>
  left_join(boot_sds, by = "condition_factor") |>
  mutate(condition_factor = factor(condition_factor,
    levels = c("CC", "CN", "NN", "PC", "PN", "PP"),
    labels = c("Con Con", "Con Null", "Null Null", "Pro Con", "Pro Null", "Pro Pro"))) |>
  arrange(condition_factor)


# Save ----
write_csv(tab, here::here("maintained", "output", "table_7_study3_conditions.csv"))


# LaTeX table ----
tex <- kable(tab, format = "latex", booktabs = TRUE, digits = 2,
             caption = "Study 3 (capital punishment): treatment conditions") |>
  kable_styling(latex_options = c("hold_position", "scale_down"))

write_lines(tex, here::here("maintained", "output", "table_7_study3_conditions.tex"))
