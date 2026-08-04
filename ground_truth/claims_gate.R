# guess_coppock_2020/ground_truth/claims_gate.R
# Output: printed summary only; no files
# Depends on: ground_truth/published_claims.csv, ground_truth/published_condition_cells.csv,
#   ground_truth/guess_coppock_2020_ground_truth.csv, maintained/in_text_claims.R
# Description: The coverage gate. It halts the run if the extraction, the ground
#   truth and the second instrument disagree about which claims the article makes,
#   about what the article printed, or about what the pipeline produces.
#
#   This repository has no build_ground_truth.R: its ground truth was written by
#   hand, so Stage 2's rule that the file be generated is not met here. A gate is
#   still buildable and closes the channel that matters most. Sourcing
#   in_text_claims.R and comparing what it prints against the committed
#   value_rewrite column makes every hand-typed rewrite value auditable against a
#   live recomputation, which is the check a generator would otherwise provide.

library(here)
here::i_am("ground_truth/claims_gate.R")
library(tidyverse)

# value_paper is forced to character in every reader. A column whose entries all
# look numeric is guessed as double, which silently turns the article's 0.00 into
# 0 and destroys the printed precision every comparison here depends on.
claims <- read_csv(here::here("ground_truth", "published_claims.csv"),
                   col_types = cols(.default = col_character(),
                                    value_paper = col_character(),
                                    digits = col_integer())) |>
  mutate(needs_block = needs_block == "TRUE")

gt <- read_csv(here::here("ground_truth", "guess_coppock_2020_ground_truth.csv"),
               col_types = cols(.default = col_character(),
                                value_paper = col_character())) |>
  mutate(across(c(match, match_rewrite, holds), as.numeric))

cells <- read_csv(here::here("ground_truth", "published_condition_cells.csv"),
                  col_types = cols(.default = col_character(),
                                   value_paper = col_character()))

stopifnot(!any(duplicated(claims$claim_id)), !any(duplicated(gt$claim_id)))

# Coverage: every pipeline and descriptive claim needs a ground-truth row, and no
# ground-truth row may name a claim the article does not make.
required_rows <- claims$claim_id[claims$claim_type %in% c("pipeline", "descriptive")]
stopifnot(length(setdiff(required_rows, gt$claim_id)) == 0,
          length(setdiff(gt$claim_id, claims$claim_id)) == 0)

# Transcription: the extraction and the ground truth are two hand transcriptions
# of the same pages and are free to drift apart. Nothing else compares them.
transcription <- gt |>
  select(claim_id, gt_paper = value_paper) |>
  inner_join(claims |> select(claim_id, claim_paper = value_paper), by = "claim_id") |>
  filter(!(is.na(gt_paper) & is.na(claim_paper))) |>
  mutate(agrees = !is.na(gt_paper) & !is.na(claim_paper) & gt_paper == claim_paper)
if (any(!transcription$agrees)) print(filter(transcription, !agrees), n = Inf, width = 200)
stopifnot(all(transcription$agrees))

# The locus rule, three states. An adverse row must carry a defect_locus, a clean
# match must not, and a row with no verdict may.
adverse <- (!is.na(gt$match) & gt$match == 0) |
  (!is.na(gt$match_rewrite) & gt$match_rewrite == 0) |
  (!is.na(gt$holds) & gt$holds == 0)
clean <- !is.na(gt$match_rewrite) & gt$match_rewrite == 1 &
  (is.na(gt$match) | gt$match == 1) & (is.na(gt$holds) | gt$holds == 1)
stopifnot(all(!is.na(gt$defect_locus[adverse])), all(is.na(gt$defect_locus[clean])))
stopifnot(all(na.omit(gt$defect_locus) %in%
                c("paper_internal", "archive", "environment", "rewrite", "unresolved")))

# The second instrument is read as a program, not as text. A block that errors at
# runtime, or that ends in a bare expression and so prints nothing under source(),
# would satisfy any check that merely looked for its claim id in the file. It is
# sourced into its own environment because both files necessarily read the same
# outputs and name objects for what they hold, so a bare source() would replace
# this script's own claims, gt and cells with the claims file's.
claims_log <- capture.output(
  source(here::here("maintained", "in_text_claims.R"), local = new.env())
)

printed <- str_match(claims_log, "^CLAIM (\\S+) = (\\S+) \\|\\| (.*)$")
printed <- tibble(claim_id = printed[, 2], printed_value = printed[, 3],
                  label = printed[, 4]) |>
  filter(!is.na(claim_id))

declared <- claims$claim_id[claims$needs_block]
stopifnot(
  !any(duplicated(printed$claim_id)),
  nrow(printed) == length(declared),
  length(setdiff(declared, printed$claim_id)) == 0,
  length(setdiff(printed$claim_id, declared)) == 0
)

# Two instruments, compared value by value. The ground truth's value_rewrite was
# typed; in_text_claims.R computes the same quantity from maintained/output/ by
# its own path. A descriptive claim has no printed value, so its verdict in holds
# is what the block prints and what is compared here.
cross_check <- printed |>
  inner_join(gt |> select(claim_id, value_rewrite, holds), by = "claim_id") |>
  inner_join(claims |> select(claim_id, claim_type, digits), by = "claim_id") |>
  mutate(
    expected = if_else(claim_type == "descriptive", holds, as.numeric(value_rewrite)),
    digits = if_else(claim_type == "descriptive", 0L, digits),
    gt_printed = if_else(is.na(expected), "NA", sprintf(paste0("%.", digits, "f"), expected)),
    agrees = printed_value == gt_printed
  )

if (any(!cross_check$agrees)) print(filter(cross_check, !agrees), n = Inf, width = 200)
stopifnot(length(setdiff(required_rows, cross_check$claim_id)) == 0,
          all(cross_check$agrees))

# Float coverage. Every published float gets at least one ground-truth row, and
# the fraction of its published numbers that the ground truth reaches is stated
# rather than assumed. Tables 1, 4 and 7 are covered cell by cell through
# published_condition_cells.csv; the six regression tables are covered at their
# estimates rather than their standard errors, constants and fit statistics.
float_cells <- tribble(
  ~table_figure, ~published_numbers,
  "table_1", 27, "table_2", 32, "table_3", 32, "table_4", 77,
  "table_5", 60, "table_6", 60, "table_7", 66, "table_8", 40,
  "table_9", 40, "figure_1", 24, "figure_2", 2
)

covered <- gt |>
  filter(table_figure %in% float_cells$table_figure) |>
  mutate(cells = case_when(
    claim_id %in% c("study1_table_1_cells", "study2_table_4_cells", "study3_table_7_cells",
                    "study1_table_1_boot_cells", "study2_table_4_boot_cells",
                    "study3_table_7_boot_cells") ~ as.numeric(value_paper),
    claim_id %in% c("study1_N_control", "study1_N_pos_info", "study1_N_neg_info",
                    "study1_W2scale_control_mean", "study1_W2scale_pos_mean",
                    "study1_W2scale_neg_mean", "study1_W2Q1_control_mean",
                    "study1_W2Q1_pos_mean", "study1_W2Q1_neg_mean",
                    "study1_W2scale_control_sd", "study1_W2scale_pos_sd",
                    "study1_W2scale_neg_sd", "study1_W2Q1_control_sd",
                    "study1_W2Q1_pos_sd", "study1_W2Q1_neg_sd",
                    "study2_N_placebo", "study2_N_conyoung_conold", "study2_N_proold_conold",
                    "study2_N_proold_conyoung", "study2_N_proyoung_conold",
                    "study2_N_proyoung_conyoung", "study2_N_proyoung_proold",
                    "study3_N_CC", "study3_N_CN", "study3_N_NN", "study3_N_PC",
                    "study3_N_PN", "study3_N_PP", "study3_n_conditions",
                    "study3_propro_score", "study3_pronull_score",
                    "study1_n_conditions", "bart_wrong_sign_intervals",
                    "study1_sds_do_not_vary", "study1_table_2_note_threshold",
                    "study1_table_3_reference", "study2_favor_all_signed",
                    "study2_favor_sig_exception", "study3_deterrence_swing") ~ 0,
    .default = 1
  )) |>
  summarise(covered = sum(cells), rows = n(), .by = table_figure) |>
  right_join(float_cells, by = "table_figure") |>
  mutate(covered = replace_na(covered, 0), rows = replace_na(rows, 0L),
         fraction = covered / published_numbers) |>
  arrange(table_figure, .locale = "en")

stopifnot(all(covered$rows > 0))
print(covered)

print(tibble(
  quantity = c("ground truth rows", "archive comparable", "archive matching",
               "rewrite comparable", "rewrite matching", "rewrite differing",
               "descriptive claims with a verdict", "descriptive claims holding",
               "rows carrying a defect locus", "extraction rows",
               "extraction rows needing a block", "claims printed by in_text_claims.R",
               "claims compared across the two instruments",
               "published condition cells transcribed"),
  value = c(nrow(gt), sum(!is.na(gt$match)), sum(gt$match == 1, na.rm = TRUE),
            sum(!is.na(gt$match_rewrite)), sum(gt$match_rewrite == 1, na.rm = TRUE),
            sum(gt$match_rewrite == 0, na.rm = TRUE),
            sum(!is.na(gt$holds)), sum(gt$holds == 1, na.rm = TRUE),
            sum(!is.na(gt$defect_locus)), nrow(claims), length(declared),
            nrow(printed), nrow(cross_check), nrow(cells))
))
