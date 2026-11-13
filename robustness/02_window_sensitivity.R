
# Do the results of 03 depend on the window used to decide whether a simulated
# dataset produced results like ours? 03 counts a simulation as matching if both
# counts are within 2 participants of ours; here we use windows of 0 to 4. 03 also
# counts a simulation as matching our between-session correlation across all
# participants if it is within .05 of ours; here we use windows of .025 to .1.
# Uses the simulations saved by 03 (run 03 first).

library(here)
library(tidyverse)

load(here("results/03_simulations.Rdata"))

count_windows <- 0:4
cor_windows <- c(0.025, 0.05, 0.075, 0.1)

count_results <- NULL
for (window in count_windows){
  window_results <- sim_summaries %>%
    group_by(account) %>%
    summarise(window = window,
              n_both_near = sum(abs(n_independent - observed$n_independent) <= window &
                                  abs(n_dependent - observed$n_dependent) <= window),
              p_both_near = n_both_near / n()) %>%
    mutate(ratio_both_near = p_both_near / p_both_near[account == "no_variation"])
  count_results <- rbind(count_results, window_results)
}

cor_results <- NULL
for (window in cor_windows){
  window_results <- sim_summaries %>%
    group_by(account) %>%
    summarise(window = window,
              p_cor_all_near = mean(abs(cor_all - observed$cor_all) <= window, na.rm = TRUE)) %>%
    mutate(ratio_cor_all_near = p_cor_all_near / p_cor_all_near[account == "no_variation"])
  cor_results <- rbind(cor_results, window_results)
}

count_results
cor_results
write_csv(count_results, here("robustness/results/02_window_sensitivity.csv"))
write_csv(cor_results, here("robustness/results/02_window_sensitivity_correlation.csv"))
