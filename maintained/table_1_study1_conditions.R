# guess_coppock_2020 — table_1_study1_conditions.R
# Output: output/table_1_study1_conditions.csv, output/table_1_study1_conditions.tex
# Depends on: original/GC_study_1.RData, helpers.R
# Description: Study 1 (gun control) treatment condition means and bootstrapped SDs.

source(here::here("maintained", "helpers.R"))
set.seed(20180101)

load(here::here("original", "GC_study_1.RData"))
study_1 <- study_1 |> filter(!is.na(Z_information))

# Weighted SD of a vector ----
weighted_sd <- function(x, w, na.rm = FALSE) {
  if (na.rm) { keep <- !is.na(x); w <- w[keep]; x <- x[keep] }
  xbar <- weighted.mean(x, w)
  sqrt(sum(w * (x - xbar)^2) / sum(w))
}

# Observed means, SEs (of mean), and SDs (of distribution) ----
tab_means <- study_1 |>
  group_by(Z_information) |>
  summarise(
    n             = n(),
    W2_scale_mean = weighted.mean(W2_scale, weight2, na.rm = TRUE),
    W2_scale_se   = weighted_se(W2_scale, weight2, na.rm = TRUE),
    W2_scale_sd   = weighted_sd(W2_scale, weight2, na.rm = TRUE),
    W2_Q1_mean    = weighted.mean(W2_Q1, weight2, na.rm = TRUE),
    W2_Q1_se      = weighted_se(W2_Q1, weight2, na.rm = TRUE),
    W2_Q1_sd      = weighted_sd(W2_Q1, weight2, na.rm = TRUE),
    .groups = "drop"
  )

# Bootstrapped SEs of the mean and SD estimates ----
boot_sds <- bootstraps(study_1, times = 1000) |>
  mutate(stats = map(splits, function(split) {
    d <- as.data.frame(split)
    d |>
      group_by(Z_information) |>
      summarise(
        W2_scale_mean = weighted.mean(W2_scale, weight2, na.rm = TRUE),
        W2_scale_se   = weighted_se(W2_scale, weight2, na.rm = TRUE),
        W2_scale_sd   = weighted_sd(W2_scale, weight2, na.rm = TRUE),
        W2_Q1_mean    = weighted.mean(W2_Q1, weight2, na.rm = TRUE),
        W2_Q1_se      = weighted_se(W2_Q1, weight2, na.rm = TRUE),
        W2_Q1_sd      = weighted_sd(W2_Q1, weight2, na.rm = TRUE),
        .groups = "drop"
      )
  })) |>
  select(stats) |>
  unnest(stats) |>
  group_by(Z_information) |>
  summarise(
    W2_scale_mean_bse = sd(W2_scale_mean),
    W2_scale_sd_bse   = sd(W2_scale_sd),
    W2_Q1_mean_bse    = sd(W2_Q1_mean),
    W2_Q1_sd_bse      = sd(W2_Q1_sd),
    .groups = "drop"
  )

# Assemble display table ----
tab <- tab_means |>
  left_join(boot_sds, by = "Z_information") |>
  mutate(
    condition = case_when(
      Z_information == "control"         ~ "Control",
      Z_information == "pro_information" ~ "Positive Information",
      Z_information == "con_information" ~ "Negative Information"
    ),
    condition = factor(condition, levels = c("Control", "Positive Information", "Negative Information"))
  ) |>
  arrange(condition)

# Save CSV ----
write_csv(tab, here::here("maintained", "output", "table_1_study1_conditions.csv"))

# Build display rows: mean/SD row then (bootstrapped SE) row ----
display_rows <- tab |>
  transmute(
    Condition          = as.character(condition),
    N                  = as.character(n),
    `T2 Attitude Mean` = format_num(W2_scale_mean, 2),
    `T2 Attitude SD`   = format_num(W2_scale_sd, 2),
    `T2 Belief Mean`   = format_num(W2_Q1_mean, 2),
    `T2 Belief SD`     = format_num(W2_Q1_sd, 2)
  )

se_rows <- tab |>
  transmute(
    Condition          = "",
    N                  = "",
    `T2 Attitude Mean` = add_parens(W2_scale_mean_bse, 2),
    `T2 Attitude SD`   = add_parens(W2_scale_sd_bse, 2),
    `T2 Belief Mean`   = add_parens(W2_Q1_mean_bse, 2),
    `T2 Belief SD`     = add_parens(W2_Q1_sd_bse, 2)
  )

# Interleave rows: mean then bootstrapped SD ----
interleaved <- map2(
  split(display_rows, seq_len(nrow(display_rows))),
  split(se_rows, seq_len(nrow(se_rows))),
  ~ bind_rows(.x, .y)
) |> bind_rows()

tex <- kable(interleaved, format = "latex", booktabs = TRUE,
             caption = "Study 1 (gun control): treatment conditions") |>
  kable_styling(latex_options = c("hold_position", "scale_down"))

write_lines(tex, here::here("maintained", "output", "table_1_study1_conditions.tex"))
