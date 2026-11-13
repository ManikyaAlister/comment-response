
# Figure 1: likelihood ratios comparing the models with and without random
# slopes in 1000 datasets simulated with no individual variation (from 02).
# The dashed line shows the likelihood ratio in our data.

library(here)
library(tidyverse)

load(here("results/02_random_slope_test.Rdata"))

p_value <- mean(sim_results[, "lrt"] >= observed[["lrt"]])

likelihood_plot <- data.frame(lrt = sim_results[, "lrt"]) %>%
  ggplot(aes(x = lrt)) +
  geom_histogram(binwidth = 0.5, boundary = 0, fill = "#2a78d6", colour = "white", linewidth = 0.1) +
  geom_vline(xintercept = observed[["lrt"]], linetype = "dashed") +
  annotate("text", x = observed[["lrt"]], y = Inf, vjust = 1.5, hjust = 1.05,
           label = paste0("Observed\n(p = ", sub("^0", "", format(p_value, nsmall = 3)), ")")) +
  labs(x = "Likelihood ratio (random slopes vs. no random slopes)",
       y = "Simulations") +
  theme_classic()

ggsave(here("results/05_likelihood_ratios.png"), likelihood_plot, width = 6, height = 4)
