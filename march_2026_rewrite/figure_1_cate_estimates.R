# guess_coppock_2020 — figure_1_cate_estimates.R
# Output: output/figure_1_cate_estimates.pdf, output/figure_1_cate_estimates.png
# Depends on: original/GC_study_1.RData, GC_Study_2.RData, GC_Study_3.RData, helpers.R
# Description: Covariate-adjusted CATE estimates (Figure 1): 24 estimates from all three studies.

source(here::here("march_2026_rewrite", "helpers.R"))

load(here::here("original", "GC_study_1.RData"))
load(here::here("original", "GC_Study_2.RData"))
load(here::here("original", "GC_Study_3.RData"))

study_1 <- study_1 |> filter(!is.na(Z_information))

covs_1 <- "ppagecat + as.factor(PPREG4) + PPEDUCAT + hispanic + as.factor(PPGENDER) + PPINCIMP + as.factor(PPMARIT) + working + as.factor(XPARTY7) + as.factor(IDEO)"

# Study 1 ----
fit_1_1 <- lm_robust(as.formula(paste("W2_scale ~ Z_information +", covs_1)),
  weights = weight2, data = filter(study_1, W1_Q1 == 1), se_type = "HC2")
fit_1_2 <- lm_robust(as.formula(paste("W2_scale ~ Z_information +", covs_1)),
  weights = weight2, data = filter(study_1, W1_Q1 == 0), se_type = "HC2")
fit_1_3 <- lm_robust(as.formula(paste("W2_Q1 ~ Z_information +", covs_1)),
  weights = weight2, data = filter(study_1, W1_Q1 == 1), se_type = "HC2")
fit_1_4 <- lm_robust(as.formula(paste("W2_Q1 ~ Z_information +", covs_1)),
  weights = weight2, data = filter(study_1, W1_Q1 == 0), se_type = "HC2")

terms_1 <- c("Z_informationpro_information", "Z_informationcon_information")

tidy_s1 <- function(fit, dv_label, subset_label) {
  tidy(fit) |>
    filter(term %in% terms_1) |>
    mutate(
      dv     = dv_label,
      subset = subset_label,
      term   = if_else(term == "Z_informationpro_information",
                       "Positive Information", "Negative Information")
    )
}

df_1 <- bind_rows(
  tidy_s1(fit_1_1, "Study 1: Composite Scale",   "Proponents"),
  tidy_s1(fit_1_2, "Study 1: Composite Scale",   "Opponents"),
  tidy_s1(fit_1_3, "Study 1: Support Gun Control", "Proponents"),
  tidy_s1(fit_1_4, "Study 1: Support Gun Control", "Opponents")
)

# Study 2 ----
covs_2 <- "favor_T1_recode + age + male + ideology + partyid + education + amount_T1"
placebo_term <- "I(condition_type == 'Placebo')"

fit_2_1 <- lm_robust(as.formula(paste("amount_T2 ~ positive_information + negative_information +",
  placebo_term, "+", covs_2)), data = subset(study_2, initial_position == "pro_raise"), se_type = "HC2")
fit_2_2 <- lm_robust(as.formula(paste("amount_T2 ~ positive_information + negative_information +",
  placebo_term, "+", covs_2)), data = subset(study_2, initial_position == "con_raise"), se_type = "HC2")
fit_2_3 <- lm_robust(as.formula(paste("favor_T2_recode ~ positive_information + negative_information +",
  placebo_term, "+", covs_2)), data = subset(study_2, initial_position == "pro_raise"), se_type = "HC2")
fit_2_4 <- lm_robust(as.formula(paste("favor_T2_recode ~ positive_information + negative_information +",
  placebo_term, "+", covs_2)), data = subset(study_2, initial_position == "con_raise"), se_type = "HC2")

terms_23 <- c("positive_information", "negative_information")

tidy_s23 <- function(fit, dv_label, subset_label) {
  tidy(fit) |>
    filter(term %in% terms_23) |>
    mutate(
      dv     = dv_label,
      subset = subset_label,
      term   = if_else(term == "positive_information", "Positive Information", "Negative Information")
    )
}

df_2 <- bind_rows(
  tidy_s23(fit_2_1, "Study 2: T2 Amount", "Proponents"),
  tidy_s23(fit_2_2, "Study 2: T2 Amount", "Opponents"),
  tidy_s23(fit_2_3, "Study 2: T2 Favor",  "Proponents"),
  tidy_s23(fit_2_4, "Study 2: T2 Favor",  "Opponents")
)

# Study 3 ----
study_3 <- within(study_3, {
  positive_information <- info_content
  positive_information[info_content < 0] <- 0
  negative_information <- info_content
  negative_information[info_content > 0] <- 0
  negative_information <- negative_information * -1
})

covs_3 <- "support_recode_T1 + deter_recode_T1 + age + female + ideology + educ + race"
nn_term <- "I(condition_factor == 'NN')"

fit_3_1 <- lm_robust(as.formula(paste("support_recode_T2 ~ positive_information + negative_information +",
  nn_term, "+", covs_3)), data = subset(study_3, pro == 1), se_type = "HC2")
fit_3_2 <- lm_robust(as.formula(paste("support_recode_T2 ~ positive_information + negative_information +",
  nn_term, "+", covs_3)), data = subset(study_3, pro == 0), se_type = "HC2")
fit_3_3 <- lm_robust(as.formula(paste("deter_recode_T2 ~ positive_information + negative_information +",
  nn_term, "+", covs_3)), data = subset(study_3, pro == 1), se_type = "HC2")
fit_3_4 <- lm_robust(as.formula(paste("deter_recode_T2 ~ positive_information + negative_information +",
  nn_term, "+", covs_3)), data = subset(study_3, pro == 0), se_type = "HC2")

df_3 <- bind_rows(
  tidy_s23(fit_3_1, "Study 3: T2 Attitude Toward Capital Punishment", "Proponents"),
  tidy_s23(fit_3_2, "Study 3: T2 Attitude Toward Capital Punishment", "Opponents"),
  tidy_s23(fit_3_3, "Study 3: T2 Belief in Deterrent Effect",          "Proponents"),
  tidy_s23(fit_3_4, "Study 3: T2 Belief in Deterrent Effect",          "Opponents")
)

# Combine ----
gg_df <- bind_rows(df_1, df_2, df_3) |>
  mutate(
    term   = factor(term, levels = c("Positive Information", "Negative Information")),
    subset = factor(subset, levels = c("Proponents", "Opponents")),
    dv     = factor(dv, levels = c(
      "Study 1: Composite Scale", "Study 1: Support Gun Control",
      "Study 2: T2 Amount", "Study 2: T2 Favor",
      "Study 3: T2 Attitude Toward Capital Punishment",
      "Study 3: T2 Belief in Deterrent Effect"
    ))
  )

# Limits frame to keep scales comparable across panels ----
lims_df <- tibble(
  dv = rep(levels(gg_df$dv), each = 2),
  term = "Positive Information",
  estimate = c(-.25, .25, -.15, .15, -2.2, 2.2, -1.4, 1.4, -.5, .5, -.7, .7),
  subset = "Proponents",
  conf.low = NA_real_,
  conf.high = NA_real_
) |>
  mutate(dv = factor(dv, levels = levels(gg_df$dv)),
         term = factor(term, levels = levels(gg_df$term)),
         subset = factor(subset, levels = levels(gg_df$subset)))

g <- ggplot(gg_df, aes(x = term, y = estimate, group = subset, shape = subset)) +
  geom_blank(data = lims_df) +
  geom_point(size = 2, position = position_dodge(width = 0.5)) +
  geom_linerange(aes(ymin = conf.low, ymax = conf.high),
                 position = position_dodge(width = 0.5), show.legend = TRUE) +
  facet_wrap(~ dv, scales = "free", nrow = 3) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  ylab("Conditional Average Treatment Effect Estimates (Covariate Adjusted Models)") +
  theme_bw() +
  theme(
    strip.background  = element_blank(),
    axis.title.x      = element_blank(),
    legend.title      = element_blank(),
    legend.key.width  = unit(4, "lines"),
    legend.position   = "bottom"
  )

ggsave(here::here("march_2026_rewrite", "output", "figure_1_cate_estimates.pdf"),
       plot = g, width = 9, height = 10)
ggsave(here::here("march_2026_rewrite", "output", "figure_1_cate_estimates.png"),
       plot = g, width = 9, height = 10, dpi = 300)

# Save estimates ----
write_csv(gg_df, here::here("march_2026_rewrite", "output", "figure_1_cate_estimates.csv"))
