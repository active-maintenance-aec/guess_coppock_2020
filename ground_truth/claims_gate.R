# guess_coppock_2020/ground_truth/claims_gate.R
# Output: ground_truth/guess_coppock_2020_ground_truth.csv (its derived columns),
#   ground_truth/float_coverage.csv
# Depends on: ground_truth/published_claims.csv, ground_truth/published_condition_cells.csv,
#   ground_truth/guess_coppock_2020_ground_truth.csv, errata_entries.csv,
#   maintained/in_text_claims.R, maintained/output/
# Description: The coverage gate. It halts the run if the extraction, the ground
#   truth and the second instrument disagree about which claims the article makes,
#   about what the article printed, or about what the pipeline produces.
#
#   This repository has no build_ground_truth.R: the values in its ground truth were
#   written by hand, so Stage 2's rule that the file be generated is not met here. A
#   gate is still buildable and closes the channel that matters most. Sourcing
#   in_text_claims.R and comparing what it prints against the committed
#   value_rewrite column makes every hand-typed rewrite value auditable against a
#   live recomputation, which is the check a generator would otherwise provide.
#
#   The columns that restate another file are not typed. location, claim_type, and
#   digits are copied from the extraction, and disposition is computed from the
#   errata spine and the judgments below, so this script rewrites the ground truth
#   with those columns derived and leaves every hand-typed column as it read it.
#   It also writes float_coverage.csv.

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
                                value_paper = col_character(),
                                match = col_logical(), match_rewrite = col_logical(),
                                holds = col_logical()))

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
adverse <- (!is.na(gt$match) & !gt$match) |
  (!is.na(gt$match_rewrite) & !gt$match_rewrite) |
  (!is.na(gt$holds) & !gt$holds)
clean <- !is.na(gt$match_rewrite) & gt$match_rewrite &
  (is.na(gt$match) | gt$match) & (is.na(gt$holds) | gt$holds)
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
    expected = if_else(claim_type == "descriptive", as.numeric(holds), as.numeric(value_rewrite)),
    digits = if_else(claim_type == "descriptive", 0L, digits),
    gt_printed = if_else(is.na(expected), "NA", sprintf(paste0("%.", digits, "f"), expected)),
    agrees = printed_value == gt_printed
  )

if (any(!cross_check$agrees)) print(filter(cross_check, !agrees), n = Inf, width = 200)
stopifnot(length(setdiff(required_rows, cross_check$claim_id)) == 0,
          all(cross_check$agrees))

# Errata spine ----
# errata.qmd names, for each published entry, the ground truth rows that entry
# corrects. An id that no longer exists is a typo or a renamed claim, and a dangling
# reference in a document whose whole purpose is correcting the record is worse than
# a gate that refuses to finish.
errata <- read_csv(here::here("errata_entries.csv"),
                   col_types = cols(.default = col_character()))

spine_ids <- function(rows) {
  ids <- rows$claim_ids |> str_split(";") |> unlist() |> str_trim()
  ids[!is.na(ids) & ids != ""]
}

errata_ids <- spine_ids(errata)
dangling_errata_ids <- setdiff(errata_ids, gt$claim_id)
if (length(dangling_errata_ids) > 0) {
  stop("errata_entries.csv lists claim ids absent from the ground truth: ",
       str_c(dangling_errata_ids, collapse = ", "))
}
print(str_glue("Errata spine: {length(unique(errata_ids))} distinct claim ids ",
               "listed, all present in the ground truth."))

# A note (form == "note") quotes a passage and proposes no change to it, so the rows it
# names are documented there and not corrected. Only the corrections count as
# corrected_here.
corrected_ids <- spine_ids(filter(errata, form != "note"))

# Columns copied from the extraction ----
# Every ground truth row has an extraction row (the coverage check above), so location,
# claim_type, and digits are read from there and never typed twice. The extraction's
# digits are the precision the article prints, except for the two BART percentages and
# the binomial p-value, whose overrides the extraction's notes explain.
gt <- gt |>
  select(-any_of(c("location", "claim_type", "digits"))) |>
  left_join(select(claims, claim_id, location, claim_type, digits), by = "claim_id")

stopifnot(!anyNA(gt$location), !anyNA(gt$claim_type), !anyNA(gt$digits))

# Disposition: what became of each defect ----
# corrected_here is computed from the errata spine and never typed. Every other
# judgment is one the repository's README, report or errata already make, keyed by
# claim id; a defect nobody has judged stays NA.
corrigendum_reason <- str_c(
  "The authors' corrigendum (British Journal of Political Science 50(4), 1517) corrects ",
  "Table 1's standard deviations; the deposit still computes the standard error of the ",
  "mean, as the README's Table 1 section records."
)
disposition_judgments <- tribble(
  ~claim_id, ~judgment, ~disposition_reason,
  "study1_W2scale_control_sd", "corrected_by_journal", corrigendum_reason,
  "study1_W2scale_pos_sd", "corrected_by_journal", corrigendum_reason,
  "study1_W2Q1_control_sd", "corrected_by_journal", corrigendum_reason,
  "study1_W2Q1_pos_sd", "corrected_by_journal", corrigendum_reason,
  "study1_W2Q1_neg_sd", "corrected_by_journal", corrigendum_reason,
  "pct_pos_te_under_pos_treatment", "not_corrected",
    str_c("Errata entry 12 carries the sentence as a note and corrects nothing: the ",
          "deposited BART script sets no seed, so no single corrected value exists.")
)
stopifnot(all(disposition_judgments$claim_id %in% gt$claim_id))

gt <- gt |>
  select(-any_of(c("disposition", "disposition_reason"))) |>
  left_join(disposition_judgments, by = "claim_id") |>
  mutate(
    disposition = case_when(
      is.na(defect_locus) ~ NA_character_,
      claim_id %in% corrected_ids ~ "corrected_here",
      .default = judgment
    ),
    disposition_reason = if_else(is.na(disposition) | disposition == "corrected_here",
                                 NA_character_, disposition_reason)
  ) |>
  select(-judgment)

# A judgment on a row with no defect, or a correction of a row with none, is a typo.
stopifnot(all(!is.na(gt$defect_locus[gt$claim_id %in% c(disposition_judgments$claim_id,
                                                          corrected_ids)])))

undisposed <- gt |> filter(defect_locus == "paper_internal", is.na(disposition))
if (nrow(undisposed) > 0) {
  print(undisposed |> select(claim_id, location, claim), n = nrow(undisposed))
  stop(str_glue("{nrow(undisposed)} paper_internal rows carry no disposition."))
}
print(gt |> filter(!is.na(defect_locus)) |> count(defect_locus, disposition))

# Float coverage ----
# One row per published float. A table's published_numbers is the count of numbers it
# prints. Tables 1, 4 and 7 are covered cell by cell through
# published_condition_cells.csv, so what they cover and reproduce is read from their
# summary rows in the ground truth. The six regression tables are covered at their
# estimates and sample sizes rather than their standard errors, constants, and fit
# statistics, through the ground truth rows the extraction locates on the table itself.
# Neither figure prints a number on its face; what each carries is a count of plotted
# quantities.
f1 <- read_csv(here::here("maintained", "output", "figure_1_cate_estimates.csv"),
               show_col_types = FALSE)
f2 <- read_csv(here::here("maintained", "output", "figure_2_bart.csv"),
               show_col_types = FALSE)

float_numbers <- tribble(
  ~float, ~published_numbers,
  "Table 1", 27L, "Table 2", 32L, "Table 3", 32L, "Table 4", 77L, "Table 5", 60L,
  "Table 6", 60L, "Table 7", 66L, "Table 8", 40L, "Table 9", 40L,
  "Figure 1", 0L, "Figure 2", 0L
)

cell_tables <- tribble(
  ~float, ~cells_row, ~boot_row,
  "Table 1", "study1_table_1_cells", "study1_table_1_boot_cells",
  "Table 4", "study2_table_4_cells", "study2_table_4_boot_cells",
  "Table 7", "study3_table_7_cells", "study3_table_7_boot_cells"
)

gt_value <- function(id, column) as.integer(gt[[column]][gt$claim_id == id])

cell_coverage <- cell_tables |>
  mutate(
    covered = map2_int(cells_row, boot_row, \(a, b) gt_value(a, "value_paper") +
                         gt_value(b, "value_paper")),
    reproduced_by_rewrite = map2_int(cells_row, boot_row, \(a, b) gt_value(a, "value_rewrite") +
                                       gt_value(b, "value_rewrite")),
    transcribed = map_int(float, \(f) sum(cells$table_figure == str_replace(str_to_lower(f), " ", "_")))
  )
stopifnot(all(cell_coverage$covered == cell_coverage$transcribed))

# The archive was never compared cell by cell; what it reached is the claims the
# extraction locates on each table, counted the same way for every table.
located <- gt |>
  mutate(float = str_match(location, "^((Table|Figure) \\d+),")[, 2]) |>
  filter(!is.na(float), !is.na(value_paper))

row_coverage <- located |>
  summarise(
    covered = n(),
    reproduced_by_rewrite = sum(match_rewrite, na.rm = TRUE),
    reproduced_by_archive = if_else(all(is.na(match)), NA_integer_, sum(match, na.rm = TRUE)),
    .by = float
  )

figure_1_plotted <- nrow(f1)
figure_1_reproduced <- gt$match_rewrite[gt$claim_id == "n_estimates_total"]

float_coverage <- float_numbers |>
  left_join(row_coverage, by = "float") |>
  rows_update(select(cell_coverage, float, covered, reproduced_by_rewrite), by = "float") |>
  mutate(
    is_figure = str_starts(float, "Figure"),
    covered = if_else(is_figure, 0L, covered),
    reproduced_by_rewrite = if_else(is_figure, 0L, reproduced_by_rewrite),
    reproduced_by_archive = if_else(is_figure, 0L, reproduced_by_archive),
    plotted = case_when(float == "Figure 1" ~ figure_1_plotted,
                        float == "Figure 2" ~ nrow(f2),
                        .default = NA_integer_),
    plotted_reproduced = case_when(
      float == "Figure 1" ~ if_else(figure_1_reproduced, figure_1_plotted, 0L),
      .default = NA_integer_
    ),
    note = case_when(
      float %in% cell_tables$float ~
        "Covered cell by cell through published_condition_cells.csv; the bootstrapped cells are single unseeded draws in the deposit.",
      float == "Table 6" ~
        "Covered at its estimates; the page reprints Table 5's cells, so none of them is reproduced (errata entry 6).",
      !is_figure ~ "Covered at its estimates and sample sizes; standard errors, constants, and fit statistics are not transcribed.",
      float == "Figure 1" ~
        "Prints no numbers on its face; plots the 24 covariate-adjusted estimates of Tables 2, 3, 5, 6, 8, and 9, reproduced when the rewrite plots as many as the article does.",
      float == "Figure 2" ~
        "Prints no numbers on its face; plots one BART estimate per subject, outcome and treatment, from a deposit that sets no seed, so no plotted point can be compared."
    )
  ) |>
  select(float, published_numbers, covered, reproduced_by_rewrite, reproduced_by_archive,
         plotted, plotted_reproduced, note)

stopifnot(
  !anyNA(float_coverage$covered),
  with(filter(float_coverage, str_starts(float, "Table")), all(covered > 0 & covered <= published_numbers))
)

write_csv(float_coverage, here::here("ground_truth", "float_coverage.csv"))
print(float_coverage, n = nrow(float_coverage), width = 200)

# The ground truth, in the canonical column order ----
gt <- gt |>
  select(paper_id, claim_id, location, claim_type, claim, value_paper, digits,
         value_script, match, value_rewrite, match_rewrite, holds, defect_locus,
         disposition, disposition_reason, notes)

write_csv(gt, here::here("ground_truth", "guess_coppock_2020_ground_truth.csv"))

print(tibble(
  quantity = c("ground truth rows", "archive comparable", "archive matching",
               "rewrite comparable", "rewrite matching", "rewrite differing",
               "descriptive claims with a verdict", "descriptive claims holding",
               "rows carrying a defect locus", "extraction rows",
               "extraction rows needing a block", "claims printed by in_text_claims.R",
               "claims compared across the two instruments",
               "published condition cells transcribed"),
  value = c(nrow(gt), sum(!is.na(gt$match)), sum(gt$match, na.rm = TRUE),
            sum(!is.na(gt$match_rewrite)), sum(gt$match_rewrite, na.rm = TRUE),
            sum(!gt$match_rewrite, na.rm = TRUE),
            sum(!is.na(gt$holds)), sum(gt$holds, na.rm = TRUE),
            sum(!is.na(gt$defect_locus)), nrow(claims), length(declared),
            nrow(printed), nrow(cross_check), nrow(cells))
))
