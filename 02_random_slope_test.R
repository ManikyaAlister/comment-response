
# Does the commentary's random slopes model fit our data better than we would
# expect if there were no individual variation in the independence effect?

source(here::here("00_setup.R"))

compareModels <- function(model_data){
  model_null <- fitModel(formula_null, model_data)
  model_slopes <- fitModel(formula_slopes, model_data)
  c(lrt = 2 * as.numeric(logLik(model_slopes) - logLik(model_null)),
    tau = getTau(model_slopes))
}

observed <- compareModels(data)

# group-level independence effect (model without random slopes, as in the
# original paper), for comparison with tau
group_effect <- fixef(fitModel(formula_null, data))[["consensusindependent"]]

# likelihood ratio in data simulated with no individual variation (run in parallel)
sim_results <- mclapply(1:n_sim, function(i) compareModels(simulateData()),
                        mc.cores = n_cores, mc.set.seed = TRUE)
sim_results <- do.call(rbind, sim_results)

results <- data.frame(lrt = observed[["lrt"]],
                      tau = observed[["tau"]],
                      group_effect = group_effect,
                      p_no_variation = mean(sim_results[, "lrt"] >= observed[["lrt"]]))

results
write_csv(results, here("results/02_random_slope_test.csv"))
# simulated likelihood ratios, plotted in 05
save(observed, sim_results, file = here("results/02_random_slope_test.Rdata"))
