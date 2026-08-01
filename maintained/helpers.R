# guess_coppock_2020/maintained/helpers.R
# Shared packages and helper functions sourced by all scripts.

library(here)
library(tidyverse)
library(estimatr)
library(knitr)
library(kableExtra)
library(rsample)

here::i_am("maintained/helpers.R")

# Weighted standard error (Cochran 1977 definition) ----
weighted_var <- function(x, w, na.rm = FALSE) {
  if (na.rm) {
    keep <- !is.na(x)
    w <- w[keep]
    x <- x[keep]
  }
  n <- length(w)
  x_wbar <- weighted.mean(x, w, na.rm = na.rm)
  w_bar  <- mean(w)
  n / ((n - 1) * sum(w)^2) * (
    sum((w * x - w_bar * x_wbar)^2) -
    2 * x_wbar * sum((w - w_bar) * (w * x - w_bar * x_wbar)) +
    x_wbar^2 * sum((w - w_bar)^2)
  )
}

weighted_se <- function(x, w, na.rm = TRUE) {
  sqrt(weighted_var(x = x, w = w, na.rm = na.rm))
}

se_mean <- function(x) {
  x_nona <- x[!is.na(x)]
  sd(x_nona) / sqrt(length(x_nona))
}

format_num <- function(x, digits = 3) {
  sprintf(paste0("%.", digits, "f"), as.numeric(x))
}

add_parens <- function(x, digits = 3) {
  paste0("(", sprintf(paste0("%.", digits, "f"), as.numeric(x)), ")")
}
