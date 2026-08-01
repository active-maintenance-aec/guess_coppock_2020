# guess_coppock_2020/maintained/bart_helpers.R
# Shared by figure_2_bart.R and text_bart_seed_sensitivity.R. Kept out of helpers.R
# so the other ten scripts do not load dbarts, which masks tidyr::extract.

library(dbarts)

# Two things make BART reproducible here that the deposited script does not do.
# First, dbarts requires .Random.seed to already exist, so a seed is not optional:
# a fresh Rscript session has never drawn a random number and the fit errors out.
# Second, dbarts runs its four chains across as many threads as it finds (14 on
# this machine), and thread scheduling changes the answer: the same seed produced
# tau_hat estimates differing by up to 0.81 across two runs. n.threads = 1L
# serializes the chains and makes a seeded run reproducible.
bart_control <- dbartsControl(n.threads = 1L)

fit_bart_effects <- function(seed) {
  set.seed(seed)

  load(here::here("original", "GC_study_1.RData"))
  load(here::here("original", "GC_Study_2.RData"))
  load(here::here("original", "GC_Study_3.RData"))

  study_1 <- study_1 |>
    select(W2_scale, W2_Q1, pro, Z_information, ppagecat, PPREG4, PPEDUCAT, hispanic,
           PPGENDER, PPINCIMP, PPMARIT, working, XPARTY7, IDEO, weight2) |>
    drop_na()

  study_2 <- study_2 |>
    select(amount_T2, favor_T2_recode, positive_information, negative_information,
           condition_type, initial_position, favor_T1_recode, age, male, ideology,
           partyid, education, amount_T1) |>
    mutate(placebo_dummy = condition_type == "Placebo") |>
    drop_na()

  study_3 <- study_3 |>
    select(support_recode_T2, deter_recode_T2, positive_information, negative_information,
           condition_factor, support_recode_T1, deter_recode_T1, age, female, ideology,
           educ, race, pro) |>
    mutate(nn_dummy = condition_factor == "NN") |>
    drop_na()

  # Counterfactual test frames: every subject under control, then under positive
  # information, then under negative, stacked in that order. Study 3's information
  # variable runs 0 to 2, so its counterfactual dose is 2 rather than 1.
  test_1 <- bind_rows(
    study_1 |> mutate(Z_information = "control"),
    study_1 |> mutate(Z_information = "pro_information"),
    study_1 |> mutate(Z_information = "con_information")
  ) |>
    mutate(Z_information = factor(Z_information))

  test_2 <- bind_rows(
    study_2 |> mutate(positive_information = 0, negative_information = 0, placebo_dummy = FALSE),
    study_2 |> mutate(positive_information = 1, negative_information = 0, placebo_dummy = FALSE),
    study_2 |> mutate(positive_information = 0, negative_information = 1, placebo_dummy = FALSE)
  )

  test_3 <- bind_rows(
    study_3 |> mutate(positive_information = 0, negative_information = 0, nn_dummy = FALSE),
    study_3 |> mutate(positive_information = 2, negative_information = 0, nn_dummy = FALSE),
    study_3 |> mutate(positive_information = 0, negative_information = 2, nn_dummy = FALSE)
  )

  fit_1_1 <- dbarts(W2_scale ~ pro + Z_information + ppagecat + as.factor(PPREG4) + PPEDUCAT +
                      hispanic + as.factor(PPGENDER) + PPINCIMP + as.factor(PPMARIT) + working +
                      as.factor(XPARTY7) + as.factor(IDEO),
                    weights = weight2, test = test_1, data = study_1, control = bart_control)$run()

  fit_1_2 <- dbarts(W2_Q1 ~ pro + Z_information + ppagecat + as.factor(PPREG4) + PPEDUCAT +
                      hispanic + as.factor(PPGENDER) + PPINCIMP + as.factor(PPMARIT) + working +
                      as.factor(XPARTY7) + as.factor(IDEO),
                    weights = weight2, test = test_1, data = study_1, control = bart_control)$run()

  fit_2_1 <- dbarts(amount_T2 ~ positive_information + negative_information + placebo_dummy +
                      initial_position + favor_T1_recode + age + male + ideology + partyid +
                      education + amount_T1,
                    test = test_2, data = study_2, control = bart_control)$run()

  fit_2_2 <- dbarts(favor_T2_recode ~ positive_information + negative_information + placebo_dummy +
                      initial_position + favor_T1_recode + age + male + ideology + partyid +
                      education + amount_T1,
                    test = test_2, data = study_2, control = bart_control)$run()

  fit_3_1 <- dbarts(support_recode_T2 ~ positive_information + negative_information + nn_dummy +
                      support_recode_T1 + deter_recode_T1 + age + female + ideology + educ +
                      race + pro,
                    test = test_3, data = study_3, control = bart_control)$run()

  fit_3_2 <- dbarts(deter_recode_T2 ~ positive_information + negative_information + nn_dummy +
                      support_recode_T1 + deter_recode_T1 + age + female + ideology + educ +
                      race + pro,
                    test = test_3, data = study_3, control = bart_control)$run()

  bind_rows(
    individual_effects(fit_1_1, nrow(study_1), "Study 1: Composite Scale"),
    individual_effects(fit_1_2, nrow(study_1), "Study 1: Support Gun Control"),
    individual_effects(fit_2_1, nrow(study_2), "Study 2: T2 Amount"),
    individual_effects(fit_2_2, nrow(study_2), "Study 2: T2 Favor"),
    individual_effects(fit_3_1, nrow(study_3), "Study 3: T2 Attitude Toward Capital Punishment"),
    individual_effects(fit_3_2, nrow(study_3), "Study 3: T2 Belief in Deterrent Effect")
  ) |>
    mutate(seed = seed, .before = 1)
}

# Posterior draws for the test frame are stacked control / positive / negative,
# so differencing the blocks gives each subject's treatment effect draws.
individual_effects <- function(fit, n_subjects, study_dv) {
  draws <- matrix(fit$test, nrow = dim(fit$test)[1])
  control <- draws[seq_len(n_subjects), ]
  positive <- draws[n_subjects + seq_len(n_subjects), ] - control
  negative <- draws[2 * n_subjects + seq_len(n_subjects), ] - control

  bind_rows(
    tibble(
      treatment = "Positive Information",
      tau_hat = rowMeans(positive),
      ci_lower = apply(positive, 1, quantile, 0.025),
      ci_upper = apply(positive, 1, quantile, 0.975)
    ),
    tibble(
      treatment = "Negative Information",
      tau_hat = rowMeans(negative),
      ci_lower = apply(negative, 1, quantile, 0.025),
      ci_upper = apply(negative, 1, quantile, 0.975)
    )
  ) |>
    mutate(study_dv = study_dv, .before = 1) |>
    group_by(treatment) |>
    mutate(ordering = rank(tau_hat, ties.method = "first")) |>
    ungroup()
}
