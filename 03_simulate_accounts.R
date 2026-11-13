
# How often do different accounts of individual variation reproduce our
# individual-level results? Each account has the same overall amount of
# variation (tau):
#   no_variation: everyone has the same independence effect (the commentary's account)
#   continuous:   each participant's effect is drawn from a normal distribution
#   subgroups:    70% no effect, 20% more persuaded by independent, 10% by dependent
# For each simulated dataset we compute the same individual-level results as the
# commentary's simulations (Fig. 1 in the commentary), which are plotted in 04.

source(here::here("00_setup.R"))

observed_participants <- analyseParticipants(data)
observed <- summariseParticipants(observed_participants)
observed_differences <- sort(observed_participants$difference)

tau <- getTau(fitModel(formula_slopes, data))

# run the simulations for each account in parallel
sim_summaries <- NULL
sim_differences <- NULL
for (account in c("no_variation", "continuous", "subgroups")){
  account_results <- mclapply(1:n_sim, function(i) simulateAccount(account, tau),
                              mc.cores = n_cores, mc.set.seed = TRUE)
  sim_summaries <- rbind(sim_summaries, do.call(rbind, lapply(account_results, `[[`, "summary")))
  sim_differences <- rbind(sim_differences, data.frame(
    account,
    sim = rep(1:n_sim, each = n_sub),
    rank = rep(1:n_sub, n_sim),
    difference = unlist(lapply(account_results, `[[`, "differences"))))
}

# how often each account produces at least as many classified participants as
# we observed (each count separately, as in the commentary's Fig. 1), how often
# both counts are within 2 participants of ours, how often the between-session
# correlation across all participants is at least as large as ours and within .05
# of ours, and how many times more often each happens than with noise only
results <- sim_summaries %>%
  group_by(account) %>%
  summarise(mean_independent = mean(n_independent),
            mean_dependent = mean(n_dependent),
            p_independent = mean(n_independent >= observed$n_independent),
            p_dependent = mean(n_dependent >= observed$n_dependent),
            p_both_near = mean(abs(n_independent - observed$n_independent) <= 2 &
                                 abs(n_dependent - observed$n_dependent) <= 2),
            median_median_independent = median(median_independent, na.rm = TRUE),
            median_median_dependent = median(median_dependent, na.rm = TRUE),
            mean_cor_all = mean(cor_all, na.rm = TRUE),
            p_cor_all = mean(cor_all >= observed$cor_all, na.rm = TRUE),
            p_cor_all_near = mean(abs(cor_all - observed$cor_all) <= 0.05, na.rm = TRUE)) %>%
  mutate(ratio_independent = p_independent / p_independent[account == "no_variation"],
         ratio_dependent = p_dependent / p_dependent[account == "no_variation"],
         ratio_both_near = p_both_near / p_both_near[account == "no_variation"],
         ratio_cor_all = p_cor_all / p_cor_all[account == "no_variation"],
         ratio_cor_all_near = p_cor_all_near / p_cor_all_near[account == "no_variation"])

observed
results
write_csv(observed, here("results/03_observed.csv"))
write_csv(results, here("results/03_reproduce_counts.csv"))
save(observed, observed_differences, sim_summaries, sim_differences,
     file = here("results/03_simulations.Rdata"))
