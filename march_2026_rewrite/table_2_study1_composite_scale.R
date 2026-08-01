# guess_coppock_2020 — table_2_study1_composite_scale.R
# Output: output/table_2_study1_composite_scale.csv, output/table_2_study1_composite_scale.tex
# Depends on: original/GC_study_1.RData, helpers.R
# Description: OLS effects of information on Study 1 composite gun control scale.

source(here::here("march_2026_rewrite", "helpers.R"))

# Data ----
load(here::here("original", "GC_study_1.RData"))
study_1 <- study_1 |> filter(!is.na(Z_information))


# Models ----
covs <- "ppagecat + as.factor(PPREG4) + PPEDUCAT + hispanic + as.factor(PPGENDER) + PPINCIMP + as.factor(PPMARIT) + working + as.factor(XPARTY7) + as.factor(IDEO)"

fit_opp_unadj <- lm_robust(
  as.formula(paste("W2_scale ~ Z_information")),
  weights = weight2, data = filter(study_1, pro == 0), se_type = "HC2"
)
fit_opp_adj <- lm_robust(
  as.formula(paste("W2_scale ~ Z_information +", covs)),
  weights = weight2, data = filter(study_1, pro == 0), se_type = "HC2"
)
fit_pro_unadj <- lm_robust(
  as.formula(paste("W2_scale ~ Z_information")),
  weights = weight2, data = filter(study_1, pro == 1), se_type = "HC2"
)
fit_pro_adj <- lm_robust(
  as.formula(paste("W2_scale ~ Z_information +", covs)),
  weights = weight2, data = filter(study_1, pro == 1), se_type = "HC2"
)


# Extract estimates ----
extract_rows <- function(fit, label) {
  td <- tidy(fit)
  terms_keep <- c("Z_informationpro_information", "Z_informationcon_information", "(Intercept)")
  td |>
    filter(term %in% terms_keep) |>
    mutate(
      term_label = case_when(
        term == "Z_informationpro_information" ~ "Positive Information",
        term == "Z_informationcon_information" ~ "Negative Information",
        term == "(Intercept)"                   ~ "Constant"
      ),
      group = label,
      N = fit$nobs,
      r2 = summary(fit)$r.squared
    )
}

results <- bind_rows(
  extract_rows(fit_opp_unadj, "Among Opponents (No Covariates)"),
  extract_rows(fit_opp_adj,   "Among Opponents (Covariates)"),
  extract_rows(fit_pro_unadj, "Among Proponents (No Covariates)"),
  extract_rows(fit_pro_adj,   "Among Proponents (Covariates)")
)


# Save estimates ----
write_csv(results, here::here("march_2026_rewrite", "output", "table_2_study1_composite_scale.csv"))

# Build display table ----
display <- results |>
  select(term_label, group, estimate, std.error, N, r2) |>
  pivot_wider(names_from = group, values_from = c(estimate, std.error)) |>
  arrange(factor(term_label, levels = c("Positive Information", "Negative Information", "Constant")))

tex <- kable(display, format = "latex", booktabs = TRUE, digits = 2,
             caption = "Study 1: Effects of information on gun control composite scale") |>
  kable_styling(latex_options = c("hold_position", "scale_down"))

write_lines(tex, here::here("march_2026_rewrite", "output", "table_2_study1_composite_scale.tex"))
