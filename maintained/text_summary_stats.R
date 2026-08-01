# guess_coppock_2020 — text_summary_stats.R
# Output: output/text_summary_stats.csv
# Depends on: figure_1_cate_estimates.R and figure_2_bart.R output, helpers.R
# Description: In-text statistics: count of correctly signed estimates, binomial test.

source(here::here("maintained", "helpers.R"))

# Data ----
df <- read_csv(here::here("maintained", "output", "figure_1_cate_estimates.csv"),
               show_col_types = FALSE)


# Correctly signed estimates ----
# Correctly signed: positive info -> positive estimate; negative info -> negative estimate
n_pos_correct <- df |>
  filter(term == "Positive Information") |>
  summarise(n = sum(estimate >= 0)) |>
  pull(n)

n_neg_correct <- df |>
  filter(term == "Negative Information") |>
  summarise(n = sum(estimate <= 0)) |>
  pull(n)

n_total   <- nrow(df)
n_correct <- n_pos_correct + n_neg_correct

btest <- binom.test(n_correct, n = n_total)


# BART individual effects: the two proportions quoted in the text ----
bart <- read_csv(here::here("maintained", "output", "figure_2_bart.csv"),
                 show_col_types = FALSE)

prop_pos_correct <- bart |>
  filter(treatment == "Positive Information") |>
  summarise(p = mean(tau_hat > 0)) |>
  pull(p)

prop_neg_correct <- bart |>
  filter(treatment == "Negative Information") |>
  summarise(p = mean(tau_hat < 0)) |>
  pull(p)

# Assemble and save ----
results <- tibble(
  statistic      = c("n_estimates_total", "n_correctly_signed",
                     "n_sig_at_05", "binom_test_pvalue",
                     "bart_prop_positive_under_pos_info",
                     "bart_prop_negative_under_neg_info"),
  value          = c(n_total, n_correct,
                     sum(df$p.value < 0.05),
                     btest$p.value,
                     prop_pos_correct,
                     prop_neg_correct)
)

print(results)
write_csv(results, here::here("maintained", "output", "text_summary_stats.csv"))
