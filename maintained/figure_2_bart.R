# guess_coppock_2020 — figure_2_bart.R
# Output: output/figure_2_bart.pdf, output/figure_2_bart.png, output/figure_2_bart.csv
# Depends on: original/GC_study_1.RData, GC_Study_2.RData, GC_Study_3.RData, helpers.R, bart_helpers.R
# Description: BART individual treatment effect estimates (Figure 2). Each subject
#   appears twice per outcome: once under positive information and once under
#   negative, both differenced against their own control-condition prediction.

source(here::here("maintained", "helpers.R"))
source(here::here("maintained", "bart_helpers.R"))

# Fit ----
effects <- fit_bart_effects(seed = 20180101)

write_csv(effects, here::here("maintained", "output", "figure_2_bart.csv"))

# Figure ----
gg_df <- effects |>
  mutate(
    study_dv = factor(study_dv, levels = c(
      "Study 1: Composite Scale", "Study 1: Support Gun Control",
      "Study 2: T2 Amount", "Study 2: T2 Favor",
      "Study 3: T2 Attitude Toward Capital Punishment",
      "Study 3: T2 Belief in Deterrent Effect"
    )),
    treatment = factor(treatment, levels = c("Positive Information", "Negative Information"))
  )

g <- ggplot(gg_df, aes(x = tau_hat, y = ordering)) +
  geom_linerange(aes(xmin = ci_lower, xmax = ci_upper), alpha = 0.05) +
  geom_point(alpha = 0.05, size = 0.5) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  facet_grid(study_dv ~ treatment, scales = "free", switch = "y",
             labeller = labeller(study_dv = label_wrap_gen(28))) +
  xlab("Estimated Treatment Effect") +
  theme_bw() +
  theme(
    axis.title.y = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    strip.background = element_blank(),
    strip.placement = "outside",
    strip.text.y.left = element_text(angle = 0, hjust = 0),
    panel.grid.minor.y = element_blank(),
    panel.grid.major.x = element_blank()
  )

ggsave(here::here("maintained", "output", "figure_2_bart.pdf"),
       plot = g, width = 9, height = 11)
ggsave(here::here("maintained", "output", "figure_2_bart.png"),
       plot = g, width = 9, height = 11, dpi = 300)
