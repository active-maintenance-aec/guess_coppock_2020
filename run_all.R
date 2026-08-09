# guess_coppock_2020/run_all.R
# Runs the whole reproduction in order: fetch and verify the deposited archive,
# then every published table and figure, then the in-text quantities.
# Every script is self-contained and can also be run on its own.

library(here)
here::i_am("run_all.R")

# Deposited archive ----
# Downloads from Dataverse on a fresh clone; verifies checksums either way.
source(here::here("download_original.R"))

# Tables ----
source(here::here("maintained", "table_1_study1_conditions.R"))
source(here::here("maintained", "table_2_study1_composite_scale.R"))
source(here::here("maintained", "table_3_study1_gun_support.R"))
source(here::here("maintained", "table_4_study2_conditions.R"))
source(here::here("maintained", "table_5_study2_amount.R"))
source(here::here("maintained", "table_6_study2_favor.R"))
source(here::here("maintained", "table_7_study3_conditions.R"))
source(here::here("maintained", "table_8_study3_support.R"))
source(here::here("maintained", "table_9_study3_deterrence.R"))

# Figures ----
source(here::here("maintained", "figure_1_cate_estimates.R"))
source(here::here("maintained", "figure_2_bart.R"))

# In-text quantities ----
# text_summary_stats.R reads both figures' estimates, so it runs after them.
# text_bart_seed_sensitivity.R refits BART at ten seeds and takes several minutes.
source(here::here("maintained", "text_summary_stats.R"))
source(here::here("maintained", "text_bart_seed_sensitivity.R"))

# Figure timestamps ----
# R's pdf() device stamps a wall-clock /CreationDate and /ModDate into every figure it
# writes, and those two fields are the only reason two runs of this pipeline produce
# differing files. Blanking them lets the determinism check cover every file the
# pipeline writes rather than all but the figures.
source(here::here("maintained", "helpers.R"))
walk(
  list.files(here::here("maintained", "output"), pattern = "\\.pdf$", full.names = TRUE),
  blank_pdf_timestamps
)

# Coverage gate ----
# Checks the extraction of published claims against the ground truth and against
# in_text_claims.R, which it sources into its own environment and reads as a
# program. It halts the run on any disagreement.
source(here::here("ground_truth", "claims_gate.R"))

# In-text claims, printed ----
# The same file again, this time for a reader: one line per published claim,
# carrying the number the pipeline produces for it.
source(here::here("maintained", "in_text_claims.R"), local = new.env())

# Deposited archive, again ----
# The check at the top of this file is a precondition: it says original/ was intact
# before anything ran. Nothing above writes to original/, and this second pass is what
# demonstrates it rather than assuming it. Nothing is downloaded; the files are already
# present and are re-checked against the manifest on checksum, byte size and membership.
source(here::here("download_original.R"))
