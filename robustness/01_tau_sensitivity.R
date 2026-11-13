
# Do the results of 03 depend on the exact amount of individual variation (tau)?
# Reruns the accounts with a range of taus around our estimate (3.45; the
# bias-corrected value is about 4 and its approximate 90% interval is 2.3 to 5.5).
# Also checks the median effects, which larger taus should push further from ours,
# and how often the between-session correlation across all participants is within
# .05 of ours (a window, because larger taus overshoot our correlation).

source(here::here("00_setup.R"))

observed <- summariseParticipants(analyseParticipants(data))
taus <- c(2.5, round(getTau(fitModel(formula_slopes, data)), 2), 4, 5)

# noise only does not depend on tau, so it is run once (tau = 0)
settings <- rbind(data.frame(account = "no_variation", tau = 0),
                  expand.grid(account = c("continuous", "subgroups"), tau = taus,
                              stringsAsFactors = FALSE))

sim_summaries <- NULL
for (i in 1:nrow(settings)){
  setting_results <- mclapply(1:n_sim, function(j) simulateAccount(settings$account[i], settings$tau[i])$summary,
                              mc.cores = n_cores, mc.set.seed = TRUE)
  sim_summaries <- rbind(sim_summaries, cbind(tau = settings$tau[i], do.call(rbind, setting_results)))
}

results <- sim_summaries %>%
  group_by(account, tau) %>%
  summarise(p_independent = mean(n_independent >= observed$n_independent),
            p_dependent = mean(n_dependent >= observed$n_dependent),
            p_median_independent = mean(median_independent <= observed$median_independent, na.rm = TRUE),
            p_median_dependent = mean(median_dependent >= observed$median_dependent, na.rm = TRUE),
            p_cor_all_near = mean(abs(cor_all - observed$cor_all) <= 0.05, na.rm = TRUE),
            .groups = "drop") %>%
  mutate(ratio_independent = p_independent / p_independent[account == "no_variation"],
         ratio_dependent = p_dependent / p_dependent[account == "no_variation"],
         ratio_cor_all_near = p_cor_all_near / p_cor_all_near[account == "no_variation"])

results
write_csv(results, here("robustness/results/01_tau_sensitivity.csv"))
