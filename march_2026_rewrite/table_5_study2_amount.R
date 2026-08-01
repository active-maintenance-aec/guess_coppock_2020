# guess_coppock_2020 — table_5_study2_amount.R
# Output: output/table_5_study2_amount.csv, output/table_5_study2_amount.tex
# Depends on: original/GC_Study_2.RData, helpers.R
# Description: OLS effects of minimum wage information on T2 Amount, by initial position.

source(here::here("march_2026_rewrite", "helpers.R"))

# Data ----
load(here::here("original", "GC_Study_2.RData"))


# Models ----
covs <- "favor_T1_recode + age + male + ideology + partyid + education + amount_T1"
base <- "amount_T2 ~ positive_information + negative_information + I(condition_type == 'Placebo')"

fit_opp_unadj <- lm_robust(as.formula(base),
  data = subset(study_2, initial_position == "con_raise"), se_type = "HC2")
fit_opp_adj   <- lm_robust(as.formula(paste(base, "+", covs)),
  data = subset(study_2, initial_position == "con_raise"), se_type = "HC2")
fit_mod_unadj <- lm_robust(as.formula(base),
  data = subset(study_2, initial_position == "inconsistent_raise"), se_type = "HC2")
fit_mod_adj   <- lm_robust(as.formula(paste(base, "+", covs)),
  data = subset(study_2, initial_position == "inconsistent_raise"), se_type = "HC2")
fit_pro_unadj <- lm_robust(as.formula(base),
  data = subset(study_2, initial_position == "pro_raise"), se_type = "HC2")
fit_pro_adj   <- lm_robust(as.formula(paste(base, "+", covs)),
  data = subset(study_2, initial_position == "pro_raise"), se_type = "HC2")


# Extract estimates ----
extract_rows <- function(fit, label) {
  terms_keep <- c("positive_information", "negative_information",
                  "I(condition_type == \"Placebo\")TRUE", "(Intercept)")
  tidy(fit) |>
    filter(term %in% terms_keep) |>
    mutate(
      term_label = case_when(
        term == "positive_information"                      ~ "Pos. Info (0 to 1)",
        term == "negative_information"                      ~ "Neg. Info (0 to 1)",
        term == "I(condition_type == \"Placebo\")TRUE"      ~ "Condition: Placebo",
        term == "(Intercept)"                               ~ "Constant"
      ),
      group = label,
      N = fit$nobs
    )
}

results <- bind_rows(
  extract_rows(fit_opp_unadj, "Opponents (No Covariates)"),
  extract_rows(fit_opp_adj,   "Opponents (Covariates)"),
  extract_rows(fit_mod_unadj, "Moderates (No Covariates)"),
  extract_rows(fit_mod_adj,   "Moderates (Covariates)"),
  extract_rows(fit_pro_unadj, "Proponents (No Covariates)"),
  extract_rows(fit_pro_adj,   "Proponents (Covariates)")
)


# Save estimates ----
write_csv(results, here::here("march_2026_rewrite", "output", "table_5_study2_amount.csv"))


# Display table ----
display <- results |>
  select(term_label, group, estimate, std.error, N) |>
  pivot_wider(names_from = group, values_from = c(estimate, std.error)) |>
  arrange(factor(term_label, levels = c("Pos. Info (0 to 1)", "Neg. Info (0 to 1)",
                                        "Condition: Placebo", "Constant")))

tex <- kable(display, format = "latex", booktabs = TRUE, digits = 2,
             caption = "Study 2: Effects of information on preferred minimum wage amount") |>
  kable_styling(latex_options = c("hold_position", "scale_down"))

write_lines(tex, here::here("march_2026_rewrite", "output", "table_5_study2_amount.tex"))
