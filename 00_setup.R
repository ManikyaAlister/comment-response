
library(here)
library(tidyverse)
library(lme4)
library(parallel)

# random number generator that gives reproducible results when simulations
# are run in parallel
RNGkind("L'Ecuyer-CMRG")
set.seed(2025)

n_sim <- 1000 # number of simulations in each analysis
n_cores <- detectCores() - 1 # cores used to run simulations in parallel

load(here("data/all_data_clean.Rdata"))

# get only consensus independence info (independent and dependent trials, as
# in the commentary's model comparison)
data <- all_data[[1]] %>%
  filter(consensus != "contested") %>%
  mutate(participant = factor(participant),
         consensus = factor(consensus, levels = c("dependent", "independent")))

# get individual subjects
n_sub <- length(unique(data$participant))

# the commentary's models: without and with by-participant random slopes for
# consensus independence
formula_null <- post_adjusted ~ pre_adjusted + consensus + claim_type + (1 | participant)
formula_slopes <- post_adjusted ~ pre_adjusted + consensus + claim_type + (consensus | participant)

fitModel <- function(model_formula, model_data){
  lmer(model_formula, data = model_data, REML = FALSE,
       control = lmerControl(optimizer = "bobyqa", check.conv.singular = "ignore"))
}

# sd of the participant-level independence effects in a random slopes model
getTau <- function(model){
  as.numeric(attr(VarCorr(model)$participant, "stddev")["consensusindependent"])
}

# Simulated data keeps the real design (participants, prior beliefs, conditions
# and claims). Post beliefs are the fitted values of the null model plus each
# participant's own residuals shuffled across their trials, so there is no
# individual variation in the independence effect unless it is added through
# independence_effects (one value per participant).
model_null <- fitModel(formula_null, data)
data$fitted <- fitted(model_null)
data$residual <- residuals(model_null)

simulateData <- function(independence_effects = rep(0, n_sub), model_data = data){
  model_data %>%
    group_by(participant) %>%
    mutate(residual = sample(residual)) %>%
    ungroup() %>%
    mutate(independence_effect = independence_effects[as.integer(participant)],
           ind = ifelse(consensus == "independent", 0.5, -0.5),
           post_adjusted = fitted + residual + ind * independence_effect,
           post_adjusted = pmin(pmax(post_adjusted, 0), 100))
}

# Leave-one-out expected log predictive density (elpd) of a linear regression.
# With flat priors this is exact and needs no refitting: each trial's
# leave-one-out prediction is a Student-t distribution centred on the
# leave-one-out residual e / (1 - h), with a scale from the residual variance
# without that trial. This is a fast version of the LOOIC comparison used in
# the original paper (LOOIC = -2 * elpd).
getLooElpd <- function(model){
  e <- residuals(model)
  h <- hatvalues(model)
  n <- length(e)
  p <- length(coef(model))
  s2_loo <- (sum(e^2) - e^2 / (1 - h)) / (n - p - 1)
  scale <- sqrt(s2_loo / (1 - h))
  sum(dt(e / (1 - h) / scale, df = n - p - 1, log = TRUE) - log(scale))
}

# fit each participant's own regressions (all trials, and each session
# separately). As in the original paper, participants are classified as more
# persuaded by an independent (or dependent) consensus if the model including
# consensus has better leave-one-out fit than the model with only prior belief.
analyseParticipants <- function(model_data){
  participant_results <- NULL
  for (participant_data in split(model_data, model_data$participant)){
    model_null <- lm(post_adjusted ~ pre_adjusted, data = participant_data)
    model <- lm(post_adjusted ~ pre_adjusted + consensus, data = participant_data)
    estimate <- coef(model)["consensusindependent"]
    consensus_better <- getLooElpd(model) > getLooElpd(model_null)
    session_estimates <- NULL
    for (session_data in split(participant_data, participant_data$session_number)){
      session_model <- lm(post_adjusted ~ pre_adjusted + consensus, data = session_data)
      session_estimates <- c(session_estimates, coef(session_model)["consensusindependent"])
    }
    change <- participant_data$post_adjusted - participant_data$pre_adjusted
    participant_results <- rbind(participant_results, data.frame(
      difference = mean(change[participant_data$consensus == "independent"]) -
        mean(change[participant_data$consensus == "dependent"]),
      classification = case_when(consensus_better & estimate > 0 ~ "independent",
                                 consensus_better & estimate < 0 ~ "dependent",
                                 TRUE ~ "none"),
      estimate_session_1 = session_estimates[1],
      estimate_session_2 = session_estimates[2]))
  }
  participant_results
}

# summarise the individual-level results in the same way as the commentary
summariseParticipants <- function(participant_results){
  classified <- participant_results$classification != "none"
  participant_results %>%
    summarise(n_independent = sum(classification == "independent"),
              n_dependent = sum(classification == "dependent"),
              median_independent = median(difference[classification == "independent"]),
              median_dependent = median(difference[classification == "dependent"]),
              cor_all = cor(estimate_session_1, estimate_session_2),
              cor_classified = cor(estimate_session_1[classified], estimate_session_2[classified]),
              cor_unclassified = cor(estimate_session_1[!classified], estimate_session_2[!classified]))
}

# simulate one dataset under an account and summarise its individual-level
# results. Each account has the same overall amount of variation (tau).
# Subgroup effects of 0, +x and -x (70/20/10%) have an sd of x * sqrt(.29), so
# x = tau / sqrt(.29) gives the subgroups the same sd as tau. Effects are
# centred (- 0.1) so the average independence effect stays the same as in the data.
simulateAccount <- function(account, tau){
  if (account == "no_variation") independence_effects <- rep(0, n_sub)
  if (account == "continuous") independence_effects <- rnorm(n_sub, 0, tau)
  if (account == "subgroups") {
    subgroup <- sample(c(0, 1, -1), n_sub, replace = TRUE, prob = c(0.7, 0.2, 0.1))
    independence_effects <- tau / sqrt(0.29) * (subgroup - 0.1)
  }
  participant_results <- analyseParticipants(simulateData(independence_effects))
  list(summary = cbind(account, summariseParticipants(participant_results)),
       differences = sort(participant_results$difference))
}
