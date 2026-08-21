# guess_coppock_2020/maintained/in_text_claims.R
# Output: printed CLAIM lines only; no files
# Depends on: maintained/output/, ground_truth/published_claims.csv, helpers.R
# Description: One block per numeric claim the published article makes, each
#   carrying the article's own sentence verbatim and then recomputing the number
#   from the pipeline's committed output. This is the second instrument: it never
#   reads ground_truth/guess_coppock_2020_ground_truth.csv, it never refits a
#   model, and it reaches every quantity by its own path, so where it and the
#   ground truth disagree one of them is wrong.
#
#   Every block prints a line of the form
#
#       CLAIM <claim_id> = <value> || <label>
#
#   which is what ground_truth/claims_gate.R parses to check coverage against
#   ground_truth/published_claims.csv. The number of decimals is taken from that
#   file rather than passed in here, so the two instruments cannot disagree about
#   the precision at which a claim is compared.
#
#   Quotes are the sentences the article prints today, however wrong. The
#   published PDF renders its minus sign as a spaced en dash and its scale-point
#   arithmetic with a centre dot; both are written below as ASCII. A sentence that
#   is wrong is recorded in the ground truth and in errata.qmd, never by editing
#   the quote.

source(here::here("maintained", "helpers.R"))
library(excheckr)

options(width = 200)

out <- function(f) read_csv(here::here("maintained", "output", f), show_col_types = FALSE)

t1 <- out("table_1_study1_conditions.csv")
t2 <- out("table_2_study1_composite_scale.csv")
t3 <- out("table_3_study1_gun_support.csv")
t4 <- out("table_4_study2_conditions.csv")
t5 <- out("table_5_study2_amount.csv")
t6 <- out("table_6_study2_favor.csv")
t7 <- out("table_7_study3_conditions.csv")
t8 <- out("table_8_study3_support.csv")
t9 <- out("table_9_study3_deterrence.csv")
f1 <- out("figure_1_cate_estimates.csv")
f2 <- out("figure_2_bart.csv")
txt <- out("text_summary_stats.csv")
seeds <- out("text_bart_seed_sensitivity.csv")

claims <- read_csv(here::here("ground_truth", "published_claims.csv"),
                   col_types = cols(.default = col_character(),
                                    value_paper = col_character(),
                                    digits = col_integer()))

published_cells <- read_csv(here::here("ground_truth", "published_condition_cells.csv"),
                            col_types = cols(.default = col_character(),
                                             value_paper = col_character()))

# The corrections this paper's errata note publishes, read from the spine errata.qmd writes
# rather than from the note's prose. A claim an entry names is scored against the correction
# and not against the sentence the article prints, so a corrected claim that drifted back to
# the published value stops the run instead of quietly reading as a match.
errata_entries <- read_csv(here::here("errata_entries.csv"),
                           col_types = cols(.default = col_character()))

# The scoring machinery comes from excheckr, which carries the verdict ladder, the typography
# parser and the printed form this file used to define for itself. What is passed here is
# what the package cannot know: the extraction, the errata spine, which errata classes move a
# claim's value, and the shape of the printed line. format = "id" is the
# CLAIM <id> = <value> || [verdict] <label> line ground_truth/claims_gate.R parses, and it
# must stay exactly that.
#
# Three classes move a value in this note. A quantity states one in a sentence. Entry 1 is a
# float: Table 6 reprints Table 5, and the correction is the table the note sets rather than
# a sentence, so its twelve cells are corrected claims whose values live in the float. Entry
# 7 is a cross-reference whose claim IS the table number, so correcting the reference
# corrects the value. A typography entry turns one comparison operator round and moves no
# claim's value, so it declares none.
#
# The label stays at the call site rather than being fetched from the extraction's claim
# column, because most of this file's labels are glued at run time and report the evidence
# behind a descriptive claim: which coefficients were correctly signed, what the ten-seed
# spread was. That sentence is about the check rather than about the article.
#
# Four claims declare expect = "absent" at their own call sites rather than in the extraction,
# because the package refuses that rung in a column: a claim asserting the deposit has no
# counterpart for it must be visible where the value would have been. All four are the same
# absence, that the archive ships no randomization inference code.
#
# The precision is NOT read off the typography here, unlike the two claims files converted
# before this one. This extraction's digits column disagrees with claim_digits(value_paper)
# on three rows and it is right on all three: the article states a p-value as the bound
# "p < 0.001" and the block prints six decimals to show the value clears it, and the two BART
# percentages are printed to a tenth against a page that prints whole per cents, because the
# comparison is against a ten-seed spread quoted to a tenth. Those three declare their own
# digits at the call site, where the reason is visible, and so do the six descriptive blocks,
# which print a truth value the article's precision does not apply to.
claim_start(published = claims, errata = errata_entries, format = "id",
            quantity_classes = c("quantity", "float", "cross_reference"),
            expect_column = "expect")

# cell: one coefficient out of a regression table's output. The assertion is what
# stops a widened output file from turning a scalar into a vector and a claim into
# a silently empty line.
cell <- function(d, grp, trm, column = "estimate") {
  hits <- d[[column]][d$group == grp & d$term == trm]
  stopifnot(length(hits) == 1, !is.na(hits))
  hits
}

group_n <- function(d, grp) {
  hits <- unique(d$N[str_detect(d$group, grp)])
  stopifnot(length(hits) == 1)
  hits
}

stat <- function(s) {
  hits <- txt$value[txt$statistic == s]
  stopifnot(length(hits) == 1)
  hits
}

# printed_decimals / cells_agreeing: the condition-summary tables are covered by a
# transcription of every published cell rather than one claim per cell, so the
# claim a block prints is the number of those cells the rewrite reproduces.
printed_decimals <- function(txt) {
  txt <- str_remove_all(txt, ",")
  if_else(str_detect(txt, "\\."), nchar(str_remove(txt, "^[^.]*\\.")), 0L)
}

condition_long <- bind_rows(
  t1 |> transmute(table_figure = "table_1", row_label = condition, N = n,
                  `T2 Attitude mean` = W2_scale_mean, `T2 Attitude SD` = W2_scale_sd,
                  `T2 Belief mean` = W2_Q1_mean, `T2 Belief SD` = W2_Q1_sd,
                  `T2 Attitude mean SE` = W2_scale_mean_bse, `T2 Attitude SD SE` = W2_scale_sd_bse,
                  `T2 Belief mean SE` = W2_Q1_mean_bse, `T2 Belief SD SE` = W2_Q1_sd_bse),
  t4 |> transmute(table_figure = "table_4", row_label = condition_type, N = n,
                  `Positive information` = positive_information,
                  `Negative information` = negative_information,
                  `Favor mean` = favor_mean, `Favor SD` = favor_sd,
                  `Amount mean` = amount_mean, `Amount SD` = amount_sd,
                  `Favor mean SE` = favor_mean_bsd, `Favor SD SE` = favor_sd_bsd,
                  `Amount mean SE` = amount_mean_bsd, `Amount SD SE` = amount_sd_bsd),
  t7 |> transmute(table_figure = "table_7", row_label = condition_factor, N = n,
                  `Positive information` = positive_information,
                  `Negative information` = negative_information,
                  `T2 Attitude mean` = support_mean, `T2 Attitude SD` = support_sd,
                  `T2 Belief mean` = deter_mean, `T2 Belief SD` = deter_sd,
                  `T2 Attitude mean SE` = support_mean_bsd, `T2 Attitude SD SE` = support_sd_bsd,
                  `T2 Belief mean SE` = deter_mean_bsd, `T2 Belief SD SE` = deter_sd_bsd)) |>
  pivot_longer(-c(table_figure, row_label), names_to = "quantity", values_to = "value_rewrite")

condition_agreement <- published_cells |>
  left_join(condition_long, by = c("table_figure", "row_label", "quantity"))
stopifnot(nrow(condition_agreement) == nrow(published_cells),
          !any(is.na(condition_agreement$value_rewrite)))
condition_agreement <- condition_agreement |>
  mutate(agrees = sprintf(paste0("%.", printed_decimals(value_paper), "f"), value_rewrite) == value_paper)

cells_agreeing <- function(tf, stoch) {
  sum(condition_agreement$agrees[condition_agreement$table_figure == tf &
                                   condition_agreement$stochastic == stoch])
}

n_studies <- n_distinct(str_extract(f1$dv, "^Study \\d"))

# Abstract ----

# "It then presents the results from three survey experiments - two on Mechanical
#  Turk and one on a nationally representative sample - that find no evidence of
#  backlash, even under theoretically favorable conditions."
claim("abstract_n_experiments", n_studies,
      "studies represented in the Figure 1 estimates")

# Introduction ----

# "In this article, we present the results from three well-powered randomized
#  experiments, each designed to identify the effect of exposure to information on
#  the attitudes and beliefs of different subgroups."
claim("intro_n_experiments", n_studies,
      "randomized experiments represented in the Figure 1 estimates")

# "We chose three distinct issues intended to cover a range of possible backlash
#  triggers."
claim("intro_n_issues", n_studies,
      "issues, one per study, in the Figure 1 estimates")

# Study 1: Procedure ----

# "We fielded Study 1 on a nationally representative sample (N = 2,122)
#  administered by the survey firm GfK from 22-28 June 2016, roughly 10 days after
#  the mass shooting in Orlando, Florida."
claim("study1_N_total", sum(t1$n), "Study 1 subjects across the three conditions")

# "In the experiment, subjects were randomly assigned to one of three conditions:
#  no information (control), pro-gun-control information (positive) or
#  anti-gun-control information (negative)."
claim("study1_n_conditions", nrow(t1), "treatment conditions in the Table 1 output")

# Table 1, as corrected by the corrigendum ----

# The three condition rows carry fifteen cells that the deposit computes
# deterministically and twelve that it bootstraps. Every one is transcribed in
# ground_truth/published_condition_cells.csv, so the claim here is how many of
# them the rewrite reproduces.
claim("study1_table_1_cells", cells_agreeing("table_1", "FALSE"),
      "of 15 deterministic Table 1 cells reproduced")
claim("study1_table_1_boot_cells", cells_agreeing("table_1", "TRUE"),
      "of 12 bootstrapped Table 1 standard error cells reproduced at the rewrite's seed")

t1_row <- function(condition, column) {
  hits <- t1[[column]][t1$condition == condition]
  stopifnot(length(hits) == 1)
  hits
}

claim("study1_N_control", t1_row("Control", "n"), "Table 1, control group N")
claim("study1_N_pos_info", t1_row("Positive Information", "n"), "Table 1, positive information N")
claim("study1_N_neg_info", t1_row("Negative Information", "n"), "Table 1, negative information N")
claim("study1_W2scale_control_mean", t1_row("Control", "W2_scale_mean"),
      "Table 1, control mean of the composite scale")
claim("study1_W2scale_pos_mean", t1_row("Positive Information", "W2_scale_mean"),
      "Table 1, positive information mean of the composite scale")
claim("study1_W2scale_neg_mean", t1_row("Negative Information", "W2_scale_mean"),
      "Table 1, negative information mean of the composite scale")
claim("study1_W2Q1_control_mean", t1_row("Control", "W2_Q1_mean"),
      "Table 1, control mean of gun control support")
claim("study1_W2Q1_pos_mean", t1_row("Positive Information", "W2_Q1_mean"),
      "Table 1, positive information mean of gun control support")
claim("study1_W2Q1_neg_mean", t1_row("Negative Information", "W2_Q1_mean"),
      "Table 1, negative information mean of gun control support")

# Corrigendum: "The authors apologise for a coding error which affected Table 1 in
#  the published article. It caused the reported standard deviations of each
#  treatment group, and their standard errors, to be inaccurate."
claim("study1_W2scale_control_sd", t1_row("Control", "W2_scale_sd"),
      "corrigendum Table 1, control SD of the composite scale")
claim("study1_W2scale_pos_sd", t1_row("Positive Information", "W2_scale_sd"),
      "corrigendum Table 1, positive information SD of the composite scale")
claim("study1_W2scale_neg_sd", t1_row("Negative Information", "W2_scale_sd"),
      "corrigendum Table 1, negative information SD of the composite scale")
claim("study1_W2Q1_control_sd", t1_row("Control", "W2_Q1_sd"),
      "corrigendum Table 1, control SD of gun control support")
claim("study1_W2Q1_pos_sd", t1_row("Positive Information", "W2_Q1_sd"),
      "corrigendum Table 1, positive information SD of gun control support")
claim("study1_W2Q1_neg_sd", t1_row("Negative Information", "W2_Q1_sd"),
      "corrigendum Table 1, negative information SD of gun control support")

# "As it happens, the standard deviations of the outcomes do not appear to vary by
#  treatment condition and are very precisely estimated."
# Read against the corrigendum's SD column rather than the article's, which the
# corrigendum withdrew. The widest spread across the three conditions is a
# fortieth of a scale point on either outcome.
sd_spread <- max(diff(range(t1$W2_scale_sd)), diff(range(t1$W2_Q1_sd)))
claim("study1_sds_do_not_vary", as.numeric(sd_spread < 0.05),
      str_glue("SDs vary by at most {sprintf('%.3f', sd_spread)} across conditions"),
      digits = 0)

# Table 2 ----

# "In Table 2, the coefficients on the positive information treatment are
#  estimates of the CAPTE. Likewise, the coefficients on negative information
#  correspond to the CANTE."
claim("study1_W2scale_opp_pos_unadj",
      cell(t2, "Among Opponents (No Covariates)", "Z_informationpro_information"),
      "Table 2, opponents, positive information, unadjusted")
claim("study1_W2scale_opp_neg_unadj",
      cell(t2, "Among Opponents (No Covariates)", "Z_informationcon_information"),
      "Table 2, opponents, negative information, unadjusted")
claim("study1_W2scale_opp_const_unadj",
      cell(t2, "Among Opponents (No Covariates)", "(Intercept)"),
      "Table 2, opponents, constant, unadjusted")
claim("study1_W2scale_opp_pos_adj",
      cell(t2, "Among Opponents (Covariates)", "Z_informationpro_information"),
      "Table 2, opponents, positive information, adjusted")
claim("study1_W2scale_opp_neg_adj",
      cell(t2, "Among Opponents (Covariates)", "Z_informationcon_information"),
      "Table 2, opponents, negative information, adjusted")
claim("study1_N_opponents", group_n(t2, "Opponents"), "Table 2, opponents N")
claim("study1_W2scale_pro_pos_unadj",
      cell(t2, "Among Proponents (No Covariates)", "Z_informationpro_information"),
      "Table 2, proponents, positive information, unadjusted")
claim("study1_W2scale_pro_neg_unadj",
      cell(t2, "Among Proponents (No Covariates)", "Z_informationcon_information"),
      "Table 2, proponents, negative information, unadjusted")
claim("study1_W2scale_pro_const_unadj",
      cell(t2, "Among Proponents (No Covariates)", "(Intercept)"),
      "Table 2, proponents, constant, unadjusted")
claim("study1_N_proponents", group_n(t2, "Proponents"), "Table 2, proponents N")

# Table 2 note: "*p < 0.1; **p < 0.05; ***p > 0.01"
# Three stars mark the most significant cells, so the threshold they stand for is
# a p-value below 0.01 and not above it. Table 3's note, on the facing page, marks
# the same threshold as p < 0.01. The claim is whether the inequality as printed
# describes the cells it annotates: the three-star cells in Table 3 all have
# p-values under 0.01, so it does not.
starred_p <- t3$p.value[t3$group == "Among Proponents (Covariates)" &
                          t3$term == "Z_informationcon_information"]
claim("study1_table_2_note_threshold", as.numeric(starred_p > 0.01),
      str_glue("a three-star cell has p = {sprintf('%.4f', starred_p)}, which is below 0.01, not above it"),
      digits = 0)

# Study 1: Results ----

# "In Table 2, we turn to the binary gun control support dependent variable, which
#  asks whether respondents support 'stricter gun control laws in the United
#  States.'"
binary_table <- if (unique(t3$outcome) == "W2_Q1") 3 else NA_real_
claim("study1_table_3_reference", binary_table,
      "the binary gun control support models are Table 3; Table 2 is the composite scale")

# Table 3 ----

claim("study1_W2Q1_opp_pos_unadj",
      cell(t3, "Among Opponents (No Covariates)", "Z_informationpro_information"),
      "Table 3, opponents, positive information, unadjusted")
claim("study1_W2Q1_opp_neg_unadj",
      cell(t3, "Among Opponents (No Covariates)", "Z_informationcon_information"),
      "Table 3, opponents, negative information, unadjusted")
claim("study1_W2Q1_opp_pos_adj",
      cell(t3, "Among Opponents (Covariates)", "Z_informationpro_information"),
      "Table 3, opponents, positive information, adjusted")
claim("study1_W2Q1_opp_neg_adj",
      cell(t3, "Among Opponents (Covariates)", "Z_informationcon_information"),
      "Table 3, opponents, negative information, adjusted")
claim("study1_W2Q1_pro_pos_unadj",
      cell(t3, "Among Proponents (No Covariates)", "Z_informationpro_information"),
      "Table 3, proponents, positive information, unadjusted")
claim("study1_W2Q1_pro_neg_unadj",
      cell(t3, "Among Proponents (No Covariates)", "Z_informationcon_information"),
      "Table 3, proponents, negative information, unadjusted")
claim("study1_W2Q1_pro_pos_adj",
      cell(t3, "Among Proponents (Covariates)", "Z_informationpro_information"),
      "Table 3, proponents, positive information, adjusted")
claim("study1_W2Q1_pro_neg_adj",
      cell(t3, "Among Proponents (Covariates)", "Z_informationcon_information"),
      "Table 3, proponents, negative information, adjusted")
claim("study1_N_opp_Q1", group_n(t3, "Opponents"), "Table 3, opponents N")
claim("study1_N_pro_Q1", group_n(t3, "Proponents"), "Table 3, proponents N")

# Study 2: Procedure ----

# "Of the 1,500 recruited to the main survey, 1,170 participated."
claim("study2_N_participated", sum(t4$n),
      "Study 2 subjects across the seven Table 4 groups")

# Table 4 ----

claim("study2_table_4_cells", cells_agreeing("table_4", "FALSE"),
      "of 49 deterministic Table 4 cells reproduced")
claim("study2_table_4_boot_cells", cells_agreeing("table_4", "TRUE"),
      "of 28 bootstrapped Table 4 standard error cells reproduced at the rewrite's seed")

t4_n <- function(condition) {
  hits <- t4$n[t4$condition_type == condition]
  stopifnot(length(hits) == 1)
  hits
}

claim("study2_N_placebo", t4_n("Placebo"), "Table 4, Placebo N")
claim("study2_N_conyoung_conold", t4_n("Con Young / Con Old"), "Table 4, Con Young / Con Old N")
claim("study2_N_proold_conold", t4_n("Pro Old / Con Old"), "Table 4, Pro Old / Con Old N")
claim("study2_N_proold_conyoung", t4_n("Pro Old / Con Young"), "Table 4, Pro Old / Con Young N")
claim("study2_N_proyoung_conold", t4_n("Pro Young / Con Old"), "Table 4, Pro Young / Con Old N")
claim("study2_N_proyoung_conyoung", t4_n("Pro Young / Con Young"), "Table 4, Pro Young / Con Young N")
claim("study2_N_proyoung_proold", t4_n("Pro Young / Pro Old"), "Table 4, Pro Young / Pro Old N")

# "Turning to the differences in standard deviations, formal tests under the sharp
#  null of no effect lend some support to the hypothesis that the treatments lead
#  to increases in the polarization of opinion - the differences between the
#  placebo condition and the Pro Old, Con Old condition are statistically
#  significant for both dependent variables at the p < 0.01 level."
# The deposited archive contains no randomization inference: none of its seven
# scripts permutes an assignment vector or computes a sharp-null p-value. What
# the pipeline can show is that the two conditions' bootstrapped standard errors
# do not overlap, which is not the test the sentence describes.
claim("study2_placebo_sd_test", NA_real_,
      "no counterpart in the deposit: the archive ships no randomization inference code",
      expect = "absent")

# Table 5 ----

claim("study2_opp_pos_unadj", cell(t5, "Opponents (No Covariates)", "positive_information"),
      "Table 5, opponents, positive information, unadjusted")
claim("study2_opp_neg_unadj", cell(t5, "Opponents (No Covariates)", "negative_information"),
      "Table 5, opponents, negative information, unadjusted")
claim("study2_opp_pos_adj", cell(t5, "Opponents (Covariates)", "positive_information"),
      "Table 5, opponents, positive information, adjusted")
claim("study2_opp_neg_adj", cell(t5, "Opponents (Covariates)", "negative_information"),
      "Table 5, opponents, negative information, adjusted")
claim("study2_pro_pos_unadj", cell(t5, "Proponents (No Covariates)", "positive_information"),
      "Table 5, proponents, positive information, unadjusted")
claim("study2_pro_neg_unadj", cell(t5, "Proponents (No Covariates)", "negative_information"),
      "Table 5, proponents, negative information, unadjusted")
claim("study2_pro_pos_adj", cell(t5, "Proponents (Covariates)", "positive_information"),
      "Table 5, proponents, positive information, adjusted")
claim("study2_pro_neg_adj", cell(t5, "Proponents (Covariates)", "negative_information"),
      "Table 5, proponents, negative information, adjusted")
claim("study2_N_opponents", group_n(t5, "Opponents"), "Table 5, opponents N")
claim("study2_N_proponents", group_n(t5, "Proponents"), "Table 5, proponents N")
claim("study2_N_moderates", group_n(t5, "Moderates"), "Table 5, moderates N")

# Table 6 ----

# Table 6 as published reprints Table 5 cell for cell, header included, under the
# caption "Effects of information on favoring minimum wage raise". Every value
# below is what the deposit's own Table 6 block produces, which is a model of the
# Favor outcome rather than the Amount outcome, and it is what Figure 1's
# "Study 2: T2 Favor" panel plots.
claim("study2_favor_opp_pos_unadj", cell(t6, "Opponents (No Covariates)", "positive_information"),
      "Table 6, opponents, positive information, unadjusted")
claim("study2_favor_opp_neg_unadj", cell(t6, "Opponents (No Covariates)", "negative_information"),
      "Table 6, opponents, negative information, unadjusted")
claim("study2_favor_opp_pos_adj", cell(t6, "Opponents (Covariates)", "positive_information"),
      "Table 6, opponents, positive information, adjusted")
claim("study2_favor_opp_neg_adj", cell(t6, "Opponents (Covariates)", "negative_information"),
      "Table 6, opponents, negative information, adjusted")
claim("study2_favor_mod_pos_unadj", cell(t6, "Moderates (No Covariates)", "positive_information"),
      "Table 6, moderates, positive information, unadjusted")
claim("study2_favor_mod_neg_unadj", cell(t6, "Moderates (No Covariates)", "negative_information"),
      "Table 6, moderates, negative information, unadjusted")
claim("study2_favor_mod_pos_adj", cell(t6, "Moderates (Covariates)", "positive_information"),
      "Table 6, moderates, positive information, adjusted")
claim("study2_favor_mod_neg_adj", cell(t6, "Moderates (Covariates)", "negative_information"),
      "Table 6, moderates, negative information, adjusted")
claim("study2_favor_pro_pos_unadj", cell(t6, "Proponents (No Covariates)", "positive_information"),
      "Table 6, proponents, positive information, unadjusted")
claim("study2_favor_pro_neg_unadj", cell(t6, "Proponents (No Covariates)", "negative_information"),
      "Table 6, proponents, negative information, unadjusted")
claim("study2_favor_pro_pos_adj", cell(t6, "Proponents (Covariates)", "positive_information"),
      "Table 6, proponents, positive information, adjusted")
claim("study2_favor_pro_neg_adj", cell(t6, "Proponents (Covariates)", "negative_information"),
      "Table 6, proponents, negative information, adjusted")

# Study 2: Results ----

# "A similar pattern of response is evident in Table 6. All coefficients are
#  correctly signed. With the exception of negative information among opponents,
#  all these coefficients are statistically significant."
t6_info <- t6 |> filter(term %in% c("positive_information", "negative_information"))
t6_signed <- t6_info |>
  mutate(correct = if_else(term == "positive_information", estimate > 0, estimate < 0))
claim("study2_favor_all_signed", as.numeric(all(t6_signed$correct)),
      str_glue("{sum(t6_signed$correct)} of {nrow(t6_signed)} Table 6 information coefficients correctly signed"),
      digits = 0)

t6_exceptions <- t6_info |>
  filter(p.value >= 0.05) |>
  distinct(term, group)
claim("study2_favor_sig_exception",
      as.numeric(all(t6_exceptions$term == "negative_information") &
                   all(str_detect(t6_exceptions$group, "Opponents"))),
      str_glue("the {nrow(t6_exceptions)} Table 6 information coefficients with p at or above 0.05 are all negative information among opponents"),
      digits = 0)

# Study 3: Procedure ----

# "A total of 683 subjects participated in the main survey (287 proponents and 396
#  opponents)."
claim("study3_N_main", sum(t7$n), "Study 3 subjects across the six Table 7 groups")
claim("study3_N_proponents_text", group_n(t8, "Proponents"),
      "Study 3 proponents, as estimated in Tables 8 and 9")
claim("study3_N_opponents_text", group_n(t8, "Opponents"),
      "Study 3 opponents, as estimated in Tables 8 and 9")

# Table 7 ----

claim("study3_table_7_cells", cells_agreeing("table_7", "FALSE"),
      "of 42 deterministic Table 7 cells reproduced")
claim("study3_table_7_boot_cells", cells_agreeing("table_7", "TRUE"),
      "of 24 bootstrapped Table 7 standard error cells reproduced at the rewrite's seed")

t7_n <- function(condition) {
  hits <- t7$n[t7$condition_factor == condition]
  stopifnot(length(hits) == 1)
  hits
}

claim("study3_N_CC", t7_n("Con Con"), "Table 7, Con Con N")
claim("study3_N_CN", t7_n("Con Null"), "Table 7, Con Null N")
claim("study3_N_NN", t7_n("Null Null"), "Table 7, Null Null N")
claim("study3_N_PC", t7_n("Pro Con"), "Table 7, Pro Con N")
claim("study3_N_PN", t7_n("Pro Null"), "Table 7, Pro Null N")
claim("study3_N_PP", t7_n("Pro Pro"), "Table 7, Pro Pro N")

# "Subjects were randomly assigned to one of six conditions, as shown in Table 7
#  below."
claim("study3_n_conditions", nrow(t7), "treatment conditions in the Table 7 output")

# "The positive information content of two Pro reports is coded as 2, one Pro and
#  one Null as 1, and so on."
claim("study3_propro_score", max(t7$positive_information),
      "Table 7, positive information content of the Pro Pro condition")
claim("study3_pronull_score", min(t7$positive_information[t7$positive_information > 0]),
      "Table 7, positive information content of the Pro Null condition")

# "Relative to the Null Null condition, the differences in standard deviations
#  across groups are generally not statistically significant at the 5 per cent
#  level, according to a randomization inference test conducted under the sharp
#  null hypothesis of no effect for any unit. The only exception is the difference
#  in standard deviations between the Null Null and Pro Null conditions for the
#  Support dependent variable (p = 0.04)."
claim("study3_sd_test_level", NA_real_,
      "no counterpart in the deposit: the archive ships no randomization inference code",
      expect = "absent")
claim("study3_sd_test_pvalue", NA_real_,
      "no counterpart in the deposit: the archive ships no randomization inference code",
      expect = "absent")

# "Each report is associated with seven intermediate dependent variables in
#  addition to the two endline dependent variables."
claim("study3_n_endline_dvs", n_distinct(c(t8$outcome, t9$outcome)),
      "endline dependent variables carried by the two Study 3 regression tables")

# Table 8 ----

claim("study3_pro_pos_unadj", cell(t8, "Proponents (No Covariates)", "positive_information"),
      "Table 8, proponents, positive information, unadjusted")
claim("study3_pro_neg_unadj", cell(t8, "Proponents (No Covariates)", "negative_information"),
      "Table 8, proponents, negative information, unadjusted")
claim("study3_pro_pos_adj", cell(t8, "Proponents (Covariates)", "positive_information"),
      "Table 8, proponents, positive information, adjusted")
claim("study3_pro_neg_adj", cell(t8, "Proponents (Covariates)", "negative_information"),
      "Table 8, proponents, negative information, adjusted")
claim("study3_opp_pos_unadj", cell(t8, "Opponents (No Covariates)", "positive_information"),
      "Table 8, opponents, positive information, unadjusted")
claim("study3_opp_neg_unadj", cell(t8, "Opponents (No Covariates)", "negative_information"),
      "Table 8, opponents, negative information, unadjusted")
claim("study3_opp_pos_adj", cell(t8, "Opponents (Covariates)", "positive_information"),
      "Table 8, opponents, positive information, adjusted")
claim("study3_opp_neg_adj", cell(t8, "Opponents (Covariates)", "negative_information"),
      "Table 8, opponents, negative information, adjusted")
claim("study3_N_proponents", group_n(t8, "Proponents"), "Table 8, proponents N")
claim("study3_N_opponents", group_n(t8, "Opponents"), "Table 8, opponents N")

# Table 9 ----

claim("study3_pro_pos_unadj_deter", cell(t9, "Proponents (No Covariates)", "positive_information"),
      "Table 9, proponents, positive information, unadjusted")
claim("study3_pro_neg_unadj_deter", cell(t9, "Proponents (No Covariates)", "negative_information"),
      "Table 9, proponents, negative information, unadjusted")
claim("study3_pro_pos_adj_deter", cell(t9, "Proponents (Covariates)", "positive_information"),
      "Table 9, proponents, positive information, adjusted")
claim("study3_pro_neg_adj_deter", cell(t9, "Proponents (Covariates)", "negative_information"),
      "Table 9, proponents, negative information, adjusted")
claim("study3_opp_pos_unadj_deter", cell(t9, "Opponents (No Covariates)", "positive_information"),
      "Table 9, opponents, positive information, unadjusted")
claim("study3_opp_neg_unadj_deter", cell(t9, "Opponents (No Covariates)", "negative_information"),
      "Table 9, opponents, negative information, unadjusted")
claim("study3_opp_pos_adj_deter", cell(t9, "Opponents (Covariates)", "positive_information"),
      "Table 9, opponents, positive information, adjusted")
claim("study3_opp_neg_adj_deter", cell(t9, "Opponents (Covariates)", "negative_information"),
      "Table 9, opponents, negative information, adjusted")

# Study 3: Results ----

# "Focusing on the covariate-adjusted models, we estimate that a one-unit increase
#  in positive information causes an average increase in support for capital
#  punishment of 0.015 scale points among proponents and 0.068 scale points among
#  opponents, neither of which is statistically significant."
claim("study3_text_pro_pos_adj", cell(t8, "Proponents (Covariates)", "positive_information"),
      "Table 8, proponents, positive information, adjusted, at the text's precision")
claim("study3_text_opp_pos_adj", cell(t8, "Opponents (Covariates)", "positive_information"),
      "Table 8, opponents, positive information, adjusted, at the text's precision")

# "Negative information has a strong negative effect among proponents (-0.326,
#  p < 0.01), and a weakly negative effect among opponents (-0.042, p = 0.43)."
claim("study3_text_pro_neg_adj", cell(t8, "Proponents (Covariates)", "negative_information"),
      "Table 8, proponents, negative information, adjusted, at the text's precision")
claim("study3_text_opp_neg_adj", cell(t8, "Opponents (Covariates)", "negative_information"),
      "Table 8, opponents, negative information, adjusted, at the text's precision")
claim("study3_text_opp_neg_pvalue",
      cell(t8, "Opponents (Covariates)", "negative_information", "p.value"),
      "Table 8, opponents, negative information, adjusted, p-value")

# "These estimates imply that moving from the Con Con condition to the Pro Pro
#  condition would cause proponents to move 2*0.015 + 2*0.326 = 0.682 scale points
#  and opponents to move 2*0.068 + 2*0.042 = 0.220 scale points."
swing <- function(d, grp) {
  2 * (cell(d, grp, "positive_information") - cell(d, grp, "negative_information"))
}
claim("study3_text_pro_swing", swing(t8, "Proponents (Covariates)"),
      "twice the sum of the two adjusted proponent coefficients in Table 8")
claim("study3_text_opp_swing", swing(t8, "Opponents (Covariates)"),
      "twice the sum of the two adjusted opponent coefficients in Table 8")

# "While the treatment effects do appear to differ by subject type (p < 0.05), we
#  do not observe the 'incorrectly' signed treatment effects that backlash would
#  produce."
# Neither the deposit nor the rewrite fits a model interacting treatment with
# subject type, so nothing in output/ tests this. Estimating one here would be a
# refit, which the second instrument may not do.
claim("study3_subject_type_test", NA_real_,
      "no counterpart in the deposit: the archive fits no treatment by subject type interaction",
      expect = "absent")

# "For both groups, moving from Con Con to Pro Pro results in an entire scale
#  point's worth of movement."
det_pro <- swing(t9, "Proponents (Covariates)")
det_opp <- swing(t9, "Opponents (Covariates)")
claim("study3_deterrence_swing",
      as.numeric(abs(det_pro - 1) < 0.1 & abs(det_opp - 1) < 0.1),
      str_glue("Table 9 gives {sprintf('%.2f', det_pro)} scale points for proponents and {sprintf('%.2f', det_opp)} for opponents"),
      digits = 0)

# Summary of Results ----

# "Figure 1 summarizes the results of all three experiments, plotting the
#  covariate-adjusted treatment effect estimates of positive and negative
#  information from Tables 2, 3, 5, 6, 8 and 9."
claim("summary_n_tables_plotted", n_distinct(f1$dv),
      "study and outcome panels in Figure 1, one per published regression table")

# "Out of twenty-four opportunities, twenty-three estimates are correctly signed.
#  Needless to say, this pattern is unlikely to occur by chance: a formal binomial
#  test roundly rejects the null hypothesis that the treatment effects were
#  equally likely to be correctly or incorrectly signed (p < 0.001)."
claim("n_estimates_total", nrow(f1), "treatment effect estimates plotted in Figure 1")
claim("n_correctly_signed", stat("n_correctly_signed"),
      "Figure 1 estimates whose sign matches the direction of the information")
claim("binom_test_pvalue", stat("binom_test_pvalue"),
      "binomial test p-value, which the article states as below 0.001",
      digits = 6)

# "Eleven of the twenty-four treatment effect estimates are statistically
#  significant at p <0.05 or better."
claim("n_sig_at_05", sum(f1$p.value < 0.05),
      "Figure 1 estimates with a p-value below 0.05")

# Exploring Treatment Effect Heterogeneity ----

# "Figure 2 plots the estimated treatment effect for each subject as a function of
#  their individual covariate profile, along with a 95 per cent credible interval.
#  According to this analysis, 93 per cent of subjects have a positive treatment
#  effect estimate when exposed to positive information and 77 per cent have a
#  negative treatment effect estimate when exposed to negative information."
# The deposited script sets no seed, so each published proportion is one unseeded
# draw and the comparison is against the ten-seed spread rather than a point.
pos_range <- range(seeds$prop_correctly_signed[seeds$treatment == "Positive Information"])
neg_range <- range(seeds$prop_correctly_signed[seeds$treatment == "Negative Information"])
claim("pct_pos_te_under_pos_treatment",
      100 * mean(f2$tau_hat[f2$treatment == "Positive Information"] > 0),
      str_glue("per cent positive under positive information; ten seeds run {sprintf('%.1f', 100 * pos_range[1])} to {sprintf('%.1f', 100 * pos_range[2])} and the published 93 lies below all of them"),
      digits = 1)
claim("pct_neg_te_under_neg_treatment",
      100 * mean(f2$tau_hat[f2$treatment == "Negative Information"] < 0),
      str_glue("per cent negative under negative information; ten seeds run {sprintf('%.1f', 100 * neg_range[1])} to {sprintf('%.1f', 100 * neg_range[2])} and the published 77 sits inside that range"),
      digits = 1)

# "In none of the cases for which a subject was predicted to have an incorrectly
#  signed treatment effect does the 95 per cent confidence interval exclude 0."
wrong_signed <- f2 |>
  filter((treatment == "Positive Information" & tau_hat < 0) |
           (treatment == "Negative Information" & tau_hat > 0))
n_excluding_zero <- sum(wrong_signed$ci_lower > 0 | wrong_signed$ci_upper < 0)
claim("bart_wrong_sign_intervals", as.numeric(n_excluding_zero == 0),
      str_glue("{n_excluding_zero} of {nrow(wrong_signed)} incorrectly signed estimates have an interval excluding zero"),
      digits = 0)

# Figure 1 caption ----

# "Figure 1. Regression coefficients from models (with controls) reported for all
#  three studies, with 95 per cent confidence intervals"
# The level is recovered from the plotted interval rather than asserted: the
# half-width divided by the standard error is the t quantile the interval used.
f1_level <- with(f1[1, ], 100 * (2 * pt((conf.high - estimate) / std.error, df) - 1))
claim("figure_1_interval", f1_level,
      "confidence level implied by Figure 1's own interval, estimate, standard error and degrees of freedom")

# Gates ----
# The verdicts above are assertions only if something reads them. assert_claims() is what
# reads them: no claim ended on a failing verdict, every claim a quantity erratum names was
# printed and printed as corrected, the claims printed are exactly those the extraction
# declares need a block, and the verdict counts partition the claims.
assert_claims()

# The exemptions are counted, never merely allowed. A file that let the unasserted set grow
# in silence would report the same clean run whether it checked every claim or none.
invisible(claim_summary())
