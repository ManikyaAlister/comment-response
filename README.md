# Reanalyses for the reply to Shepherdson (2026)

Code and data for our reply to Shepherdson's (2026) commentary, *Individual differences or unsystematic noise?*, on Alister et al. (2025, *Psychological Science*). Every number and figure in the reply is produced by the scripts here. [Where each result comes from](#where-each-result-comes-from) maps each one to the script and output that produce it.

## Reproducing the results

1. Install R (we used R 4.5.3) and open `response-analyses.Rproj` in RStudio, or start R in this folder.
2. Install the exact package versions we used with [renv](https://rstudio.github.io/renv/). renv installs itself when the project first opens. Then run:
   ```r
   renv::restore()
   ```
3. Run every analysis in order:
   ```r
   source("run_all.R")
   ```
   Or run the scripts one at a time in the order in [What each script does](#what-each-script-does).

`run_all.R` takes about 6 minutes on a 10-core laptop (Apple M4), most of it in `robustness/01_tau_sensitivity.R`. The simulations run in parallel on all but one core. This uses `mclapply`, which only runs in parallel on macOS and Linux; on Windows the scripts still run, but on one core and more slowly.

The results are exactly reproducible. Each script sets the same seed and uses a random number generator that gives the same simulations however many cores are used (`RNGkind("L'Ecuyer-CMRG")` in `00_setup.R`). The outputs from our run are already in `results/` and `robustness/results/`, so you can check them without rerunning anything.

## Where each result comes from

All proportions are out of 1000 simulated datasets. "Times more often" compares each systematic model with the noise-only model.

| Result in the reply | Value | Script | Output (columns) |
|---|---|---|---|
| **Shepherdson's simulations** | | | |
| Proportion of Shepherdson's simulations that reproduce both of our original classification counts (17 more persuaded by independent consensus and 6 by dependent consensus) | .004 | `01_commentary_sims.R` | `results/01_commentary_sims.csv` (`p_both`) |
| **Random slopes analysis** | | | |
| Likelihood ratio comparing the models with and without by-participant random slopes for consensus independence | 11.35 | `02_random_slope_test.R` | `results/02_random_slope_test.csv` (`lrt`) |
| SD of participants' independence effects (τ) | 3.45 | `02_random_slope_test.R` | `results/02_random_slope_test.csv` (`tau`) |
| Proportion of datasets with no individual variation that give a likelihood ratio at least as large as ours (p) | .004 | `02_random_slope_test.R` | `results/02_random_slope_test.csv` (`p_no_variation`) |
| Figure 1 | | `05_plot_likelihood_ratios.R` | `results/05_likelihood_ratios.png` |
| **Model comparison** | | | |
| Observed results in the original data: classification counts, median effects and between-session correlations | 17 and 8; 8.05 and −6.53; r = .13 (all participants) | `03_simulate_accounts.R` | `results/03_observed.csv` |
| Proportion of simulations with at least 17 participants more persuaded by independent consensus | noise only .050; continuous .233 (4.7 times); subgroups .221 (4.4 times) | `03_simulate_accounts.R` | `results/03_reproduce_counts.csv` (`p_independent`, `ratio_independent`) |
| Proportion of simulations with at least 8 participants more persuaded by dependent consensus | noise only .020; continuous .198 (9.9 times); subgroups .182 (9.1 times) | `03_simulate_accounts.R` | `results/03_reproduce_counts.csv` (`p_dependent`, `ratio_dependent`) |
| Proportion of simulations with both counts within two participants of ours | noise only .011; continuous .193 (17.5 times); subgroups .160 (14.5 times) | `03_simulate_accounts.R` | `results/03_reproduce_counts.csv` (`p_both_near`, `ratio_both_near`) |
| Mean between-session correlation across all participants | noise only −.01; continuous .14; subgroups .13 | `03_simulate_accounts.R` | `results/03_reproduce_counts.csv` (`mean_cor_all`) |
| Proportion of simulations with a between-session correlation at least as large as ours | noise only .125; continuous .509 (4.1 times); subgroups .503 (4.0 times) | `03_simulate_accounts.R` | `results/03_reproduce_counts.csv` (`p_cor_all`, `ratio_cor_all`) |
| Proportion of simulations with a between-session correlation within .05 of ours | noise only .159; continuous .342 (2.2 times); subgroups .315 (2.0 times) | `03_simulate_accounts.R` | `results/03_reproduce_counts.csv` (`p_cor_all_near`, `ratio_cor_all_near`) |
| Typical median effect among participants more persuaded by dependent consensus | about −9.5 under every model | `03_simulate_accounts.R` | `results/03_reproduce_counts.csv` (`median_median_dependent`) |
| Figure 2 | | `04_plot_distributions.R` | `results/04_distributions.png` |
| **Robustness checks (footnotes)** | | | |
| Results for τ = 2.5, 3.45, 4 and 5 | systematic models above noise only at every τ; correlation matched most often at τ = 3.45 | `robustness/01_tau_sensitivity.R` | `robustness/results/01_tau_sensitivity.csv` |
| Both counts within 0 to 4 participants of ours | systematic models above noise only at every window (4 to 77 times) | `robustness/02_window_sensitivity.R` | `robustness/results/02_window_sensitivity.csv` |
| Between-session correlation within .025 to .1 of ours | 1.8 to 2.4 times as often as noise only | `robustness/02_window_sensitivity.R` | `robustness/results/02_window_sensitivity_correlation.csv` |

## What each script does

| Script | What it does |
|---|---|
| `00_setup.R` | Loads the data and defines everything the other scripts share: the models, the function that simulates data, and the functions that classify participants and summarise the individual-level results. Sourced by the analysis scripts; it doesn't produce output itself. |
| `01_commentary_sims.R` | Uses the results of Shepherdson's simulations (`data/commentary_sim_results.csv`) to find how often his simulations reproduced our original results. |
| `02_random_slope_test.R` | Fits Shepherdson's models with and without random slopes to our data, and compares their likelihood ratio with the likelihood ratios in 1000 datasets simulated with no individual variation. |
| `03_simulate_accounts.R` | Simulates 1000 datasets under each of three models (noise only, noise + continuous differences, noise + subgroups) and computes the same individual-level results as Shepherdson's simulations in each. |
| `04_plot_distributions.R` | Figure 2, from the simulations saved by 03. |
| `05_plot_likelihood_ratios.R` | Figure 1, from the simulations saved by 02. |
| `robustness/01_tau_sensitivity.R` | Reruns the simulations in 03 with τ = 2.5, 3.45, 4 and 5. |
| `robustness/02_window_sensitivity.R` | Recomputes the window-based results of 03 with narrower and wider windows, from the simulations saved by 03. |
| `run_all.R` | Runs all of the above in order. |

## How the data are simulated

Simulated data keep the real design of the original experiment: the same participants, prior beliefs, conditions (independent or dependent consensus), claims and sessions. Post beliefs are the fitted values of the model with no individual variation, plus each participant's own residuals shuffled across that participant's trials, clipped to the 0–100 scale. This gives every simulated participant the same amount of noise as the real participant.

The noise-only model adds nothing else. The two systematic models add an independence effect for each participant, with the same overall SD (τ, estimated by 02):
- **Continuous:** effects drawn from a normal distribution, N(0, τ).
- **Subgroups:** 70% of participants with no effect, 20% more persuaded by independent consensus and 10% by dependent consensus.

The models therefore differ only in the shape of the individual variation, not its amount.

Participants are classified as in the original paper, by comparing the leave-one-out fit of each participant's own regression with and without consensus. Here the leave-one-out fit is computed exactly for linear regressions with flat priors, instead of with brms, so that it is fast enough to run in every simulation. This changes the classification of two borderline participants: 8 participants are classified as more persuaded by dependent consensus here, rather than 6 in the original paper.

## Data

- `data/all_data_clean.Rdata`: the cleaned data from Alister et al. (2025), also available at https://osf.io/f92ja/. The analyses use the independent and dependent consensus trials.
- `data/commentary_sim_results.csv`: the results of Shepherdson's (2026) 1000 simulations (`simResults.csv` in the commentary's materials), used only by `01_commentary_sims.R`.

## References

Alister, M., et al. (2025). How convincing is a crowd? Quantifying the persuasiveness of a consensus for different individuals and types of claims. *Psychological Science*.

Shepherdson, P. (2026). Individual differences or unsystematic noise? *Psychological Science*.
