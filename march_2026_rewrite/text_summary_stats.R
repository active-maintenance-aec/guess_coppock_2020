# guess_coppock_2020 — text_summary_stats.R
# Output: output/text_summary_stats.csv
# Depends on: figure_1_cate_estimates.R output, helpers.R
# Description: In-text statistics: count of correctly signed estimates, binomial test.

source(here::here("march_2026_rewrite", "helpers.R"))

# Data ----
df <- read_csv(here::here("march_2026_rewrite", "output", "figure_1_cate_estimates.csv"),
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


# Assemble and save ----
results <- tibble(
  statistic      = c("n_estimates_total", "n_correctly_signed",
                     "n_sig_at_05", "binom_test_pvalue"),
  value          = c(n_total, n_correct,
                     sum(df$p.value < 0.05),
                     btest$p.value)
)

print(results)
write_csv(results, here::here("march_2026_rewrite", "output", "text_summary_stats.csv"))
