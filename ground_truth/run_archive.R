# guess_coppock_2020/ground_truth/run_archive.R
# Output: ground_truth/archive_run_status.csv, ground_truth/archive_overwrites.csv
# Depends on: original/ (run download_original.R first)
# Description: Runs every deposited analysis script, as shipped, in a fresh R session
#   from a scratch copy of the archive, and records how each one ends and what it
#   leaves behind. GC_helpers.R is only ever sourced by the other scripts, so it gets
#   no row of its own.
#
#   The canonical record has two passes. The stripped pass removes every intermediate
#   the deposit ships, so a script has to pass on the deposit's data and code alone.
#   This deposit ships no intermediates: its three .RData files are the study data,
#   and every other file is code or the README. The stripped copy therefore withholds
#   nothing and is the shipped copy run a second time, which is recorded rather than
#   assumed.
#
#   This script is not part of run_all.R. The deposit needs dbarts and ggpubr beyond
#   what the maintained rewrite loads, its BART script is slow when it runs at all,
#   and its data loads name files in a case the deposit does not use ("GC_study_2.rdata"
#   for GC_Study_2.RData), which resolves on a case-insensitive file system only.

library(here)
here::i_am("ground_truth/run_archive.R")
library(tidyverse)

# The analysis scripts, in the order the deposit's README lists them ----
scripts <- tribble(
  ~script, ~role,
  "GC_Study_1_analysis.R", "analysis",
  "GC_Study_2_analysis.R", "analysis",
  "GC_Study_3_analysis.R", "analysis",
  "GC_figure_1.R", "analysis",
  "GC_figure_2.R", "analysis",
  "GC_alternative_specifications.R", "analysis"
)

# Shipped intermediates the stripped pass withholds. None, for the reason above.
intermediates <- character()

deposit <- list.files(here::here("original"))
stopifnot(all(scripts$script %in% deposit), all(intermediates %in% deposit))

file_state <- function(dir) {
  paths <- list.files(dir, recursive = TRUE)
  tibble(file = paths,
         md5 = unname(tools::md5sum(file.path(dir, paths))),
         mtime = file.mtime(file.path(dir, paths)))
}

deposited_state <- file_state(here::here("original"))

# One pass: a scratch copy, the scripts in order, a fresh session each ----
# stopped_at is the first error line the session printed, with the line after it,
# which is where R puts the message when the call is long.
first_error <- function(stderr) {
  lines <- str_split(stderr, "\n")[[1]]
  at <- which(str_detect(lines, "^Error"))
  if (length(at) == 0) return(NA_character_)
  str_squish(str_c(lines[at[1]:min(at[1] + 1, length(lines))], collapse = " "))
}

run_pass <- function(pass, withheld) {
  dir <- file.path(tempdir(), str_glue("archive_{pass}"))
  unlink(dir, recursive = TRUE)
  dir.create(dir)
  file.copy(here::here("original", setdiff(deposit, withheld)), dir)
  before <- file_state(dir)
  Sys.sleep(1)

  status <- map(scripts$script, function(s) {
    print(str_glue("{pass}: {s}"))
    res <- processx::run(file.path(R.home("bin"), "Rscript"), c("--vanilla", s), wd = dir,
                         error_on_status = FALSE, timeout = 3600)
    tibble(script = s, exit_status = res$status, timed_out = res$timeout,
           stopped_at = first_error(res$stderr))
  }) |>
    list_rbind()

  after <- file_state(dir)
  effects <- full_join(before, after, by = "file", suffix = c("_before", "_after")) |>
    left_join(select(deposited_state, file, md5_deposit = md5), by = "file") |>
    mutate(effect = case_when(
      is.na(md5_after) ~ "deleted",
      is.na(md5_before) & file %in% withheld ~ "rebuilt",
      is.na(md5_before) ~ "added",
      mtime_after != mtime_before | md5_after != md5_before ~ "overwritten",
      .default = NA_character_
    )) |>
    filter(!is.na(effect)) |>
    transmute(pass, file, effect,
              matches_deposit = if_else(effect == "added", NA, md5_after == md5_deposit))

  withheld_rows <- tibble(file = setdiff(withheld, after$file)) |>
    transmute(pass, file, effect = "withheld", matches_deposit = NA)

  list(status = mutate(status, pass = pass),
       overwrites = bind_rows(effects, withheld_rows))
}

as_shipped <- run_pass("as_shipped", withheld = character())
stripped <- run_pass("stripped", withheld = intermediates)

# The two archive tables, in the canonical long form ----
run_status <- bind_rows(as_shipped$status, stripped$status) |>
  left_join(scripts, by = "script") |>
  transmute(pass, script, role, exit_status,
            outcome = case_when(timed_out ~ "timeout", exit_status == 0 ~ "clean",
                                .default = "error"),
            stopped_at = if_else(outcome == "clean", NA_character_, stopped_at))

overwrites <- bind_rows(as_shipped$overwrites, stripped$overwrites)

stopifnot(nrow(run_status) == 2 * nrow(scripts), !anyNA(run_status$role))

write_csv(run_status, here::here("ground_truth", "archive_run_status.csv"))
write_csv(overwrites, here::here("ground_truth", "archive_overwrites.csv"))
print(run_status, n = nrow(run_status), width = 200)
print(overwrites, n = nrow(overwrites))
