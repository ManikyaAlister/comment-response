
# How often did the commentary's own simulations (no individual variation)
# reproduce our original results?

source(here::here("00_setup.R"))

commentary_sims <- read_csv(here("data/commentary_sim_results.csv"),
                            show_col_types = FALSE, name_repair = "unique_quiet") %>%
  mutate(nDepGreater = nAltPreferred - nIndGreater)

# original results: 17 participants more persuaded by an independent consensus,
# 6 by a dependent consensus, and a between-session correlation of .57 among them
results <- commentary_sims %>%
  summarise(p_17_independent = mean(nIndGreater >= 17),
            p_6_dependent = mean(nDepGreater >= 6),
            p_both = mean(nIndGreater >= 17 & nDepGreater >= 6),
            p_session_cor_57 = mean(altCor >= .57, na.rm = TRUE))

results
write_csv(results, here("results/01_commentary_sims.csv"))
