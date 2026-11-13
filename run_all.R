
# Reproduce every result and figure in the reply, in order. Each script runs in
# its own R session, so they are independent of one another (apart from 04, 05
# and robustness/02, which use the simulations saved by 02 and 03).
# Takes about 6 minutes on a 10-core laptop.

scripts <- c("01_commentary_sims.R",
             "02_random_slope_test.R",
             "03_simulate_accounts.R",
             "04_plot_distributions.R",
             "05_plot_likelihood_ratios.R",
             "robustness/01_tau_sensitivity.R",
             "robustness/02_window_sensitivity.R")

for (script in scripts){
  message("Running ", script)
  start <- Sys.time()
  status <- system2("Rscript", here::here(script))
  if (status != 0) stop(script, " failed")
  message("  done in ", round(difftime(Sys.time(), start, units = "mins"), 1), " minutes")
}
