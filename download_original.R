# guess_coppock_2020 — download_original.R
# Output: original/ (the deposited replication archive, not redistributed in this repo)
# Depends on: original_manifest.csv
# Description: Fetch the deposited archive from Harvard Dataverse and verify every
#   file against the checksums the archive itself publishes. Run this once before
#   running anything in maintained/.

library(tidyverse)
library(here)

here::i_am("download_original.R")

dataset_doi <- "doi:10.7910/DVN/J7WNTM"
base_url <- "https://dataverse.harvard.edu/api/access/datafile"

# Manifest ----
manifest <- read_csv(here::here("original_manifest.csv"), show_col_types = FALSE)

dir.create(here::here("original"), showWarnings = FALSE)

# Download, requesting the originally deposited bytes rather than the ----
# tabular representation Dataverse derives for ingested files.
downloaded <- manifest |>
  mutate(
    path = here::here("original", file),
    url = str_glue("{base_url}/{dataverse_file_id}?format=original")
  )

walk2(downloaded$url, downloaded$path, function(url, path) {
  download.file(url, destfile = path, mode = "wb", quiet = TRUE)
})

# Verify against the checksums Dataverse publishes for the deposit ----
verified <- downloaded |>
  mutate(
    md5_downloaded = unname(tools::md5sum(path)),
    match = md5_downloaded == md5
  ) |>
  select(file, bytes, md5, md5_downloaded, match)

print(verified, n = nrow(verified))

if (!all(verified$match)) {
  stop("Checksum mismatch: the downloaded archive does not match the published deposit.")
}

print(str_glue("All {nrow(verified)} files match the checksums published at {dataset_doi}."))
