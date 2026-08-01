# guess_coppock_2020 — table_9_study3_deterrence.R
# Output: output/table_9_study3_deterrence.csv, output/table_9_study3_deterrence.tex
# Depends on: original/GC_Study_3.RData, helpers.R
# Description: OLS effects of capital punishment information on T2 deterrence belief, by proponent status.

source(here::here("march_2026_rewrite", "helpers.R"))

# Data ----
load(here::here("original", "GC_Study_3.RData"))


# Models ----
covs <- "support_recode_T1 + deter_recode_T1 + age + female + ideology + educ + race"
base <- "deter_recode_T2 ~ positive_information + negative_information + I(condition_factor == 'NN')"

fit_pro_unadj <- lm_robust(as.formula(base),
  data = subset(study_3, pro == 1), se_type = "HC2")
fit_pro_adj   <- lm_robust(as.formula(paste(base, "+", covs)),
  data = subset(study_3, pro == 1), se_type = "HC2")
fit_opp_unadj <- lm_robust(as.formula(base),
  data = subset(study_3, pro == 0), se_type = "HC2")
fit_opp_adj   <- lm_robust(as.formula(paste(base, "+", covs)),
  data = subset(study_3, pro == 0), se_type = "HC2")


# Extract estimates ----
extract_rows <- function(fit, label) {
  terms_keep <- c("positive_information", "negative_information",
                  "I(condition_factor == \"NN\")TRUE", "(Intercept)")
  tidy(fit) |>
    filter(term %in% terms_keep) |>
    mutate(
      term_label = case_when(
        term == "positive_information"               ~ "Positive Information (0 to 2)",
        term == "negative_information"               ~ "Negative Information (0 to 2)",
        term == "I(condition_factor == \"NN\")TRUE"  ~ "Condition: Null Null",
        term == "(Intercept)"                        ~ "Constant"
      ),
      group = label,
      N = fit$nobs
    )
}

results <- bind_rows(
  extract_rows(fit_pro_unadj, "Proponents (No Covariates)"),
  extract_rows(fit_pro_adj,   "Proponents (Covariates)"),
  extract_rows(fit_opp_unadj, "Opponents (No Covariates)"),
  extract_rows(fit_opp_adj,   "Opponents (Covariates)")
)


# Save estimates ----
write_csv(results, here::here("march_2026_rewrite", "output", "table_9_study3_deterrence.csv"))


# Display table ----
display <- results |>
  select(term_label, group, estimate, std.error, N) |>
  pivot_wider(names_from = group, values_from = c(estimate, std.error)) |>
  arrange(factor(term_label, levels = c("Positive Information (0 to 2)",
                                        "Negative Information (0 to 2)",
                                        "Condition: Null Null", "Constant")))

tex <- kable(display, format = "latex", booktabs = TRUE, digits = 2,
             caption = "Study 3: Effects of information on belief in deterrent effect of capital punishment") |>
  kable_styling(latex_options = c("hold_position", "scale_down"))

write_lines(tex, here::here("march_2026_rewrite", "output", "table_9_study3_deterrence.tex"))
