
# Figure 2: distributions of the individual-level results under each account, in the
# style of the commentary's Fig. 1. Dashed lines show our observed values.

library(here)
library(tidyverse)
library(patchwork)

load(here("results/03_simulations.Rdata"))

account_labels <- c(no_variation = "Noise only", continuous = "Noise + continuous differences",
                    subgroups = "Noise + subgroups")
account_colours <- c("Noise only" = "#2a78d6", "Noise + continuous differences" = "#eb6834",
                     "Noise + subgroups" = "#1baf7a")

sim_summaries <- sim_summaries %>%
  mutate(account = factor(account_labels[account], levels = account_labels))
sim_differences <- sim_differences %>%
  mutate(account = factor(account_labels[account], levels = account_labels))

# frequency of a result across simulations, one line per account
plotDistribution <- function(result, title, xlab, binwidth){
  sim_summaries %>%
    ggplot(aes(x = .data[[result]], colour = account)) +
    geom_freqpoly(binwidth = binwidth, linewidth = 0.7, na.rm = TRUE) +
    geom_vline(xintercept = observed[[result]], linetype = "dashed") +
    scale_colour_manual(values = account_colours) +
    labs(title = title, x = xlab, y = "Simulations", colour = "Account") +
    theme_classic()
}

p_n_ind <- plotDistribution("n_independent", "Independent > dependent", "Number of participants", 1)
p_n_dep <- plotDistribution("n_dependent", "Dependent > independent", "Number of participants", 1)
p_med_ind <- plotDistribution("median_independent", "Median effect, independent > dependent",
                              "Source independence effect", 1)
p_med_dep <- plotDistribution("median_dependent", "Median effect, dependent > independent",
                              "Source independence effect", 1)
p_cor_all <- plotDistribution("cor_all", "Between-session correlation, all participants",
                              "Pearson's r", 0.05)
p_cor_class <- plotDistribution("cor_classified", "Between-session correlation, classified",
                                "Pearson's r", 0.05)
p_cor_unclass <- plotDistribution("cor_unclassified", "Between-session correlation, unclassified",
                                  "Pearson's r", 0.05)

# ordered independent - dependent differences: median and middle 90% of
# simulations for each account, with the observed values
ordered_differences <- sim_differences %>%
  group_by(account, rank) %>%
  summarise(median = median(difference),
            lower = quantile(difference, 0.05),
            upper = quantile(difference, 0.95),
            .groups = "drop")

p_ordered <- ordered_differences %>%
  ggplot(aes(x = rank, colour = account, fill = account)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.15, colour = NA) +
  geom_line(aes(y = median), linewidth = 0.7) +
  geom_line(data = data.frame(rank = seq_along(observed_differences),
                              difference = observed_differences),
            aes(x = rank, y = difference), inherit.aes = FALSE, linetype = "dashed") +
  scale_colour_manual(values = account_colours) +
  scale_fill_manual(values = account_colours, guide = "none") +
  labs(title = "Independent vs. dependent consensus", x = "Participant (ordered by difference)",
       y = "Belief difference", colour = "Account") +
  theme_classic()

# both counts together: each point is a combination of counts, sized by the
# number of simulations producing it. The dashed box marks counts within 2
# participants of ours and the cross marks our counts
p_joint <- sim_summaries %>%
  count(account, n_independent, n_dependent) %>%
  ggplot(aes(x = n_independent, y = n_dependent, colour = account, size = n)) +
  geom_point(alpha = 0.35, position = position_dodge(width = 0.6), show.legend = FALSE) +
  annotate("rect", xmin = observed$n_independent - 2.5, xmax = observed$n_independent + 2.5,
           ymin = observed$n_dependent - 2.5, ymax = observed$n_dependent + 2.5,
           fill = NA, colour = "black", linetype = "dashed") +
  annotate("point", x = observed$n_independent, y = observed$n_dependent, shape = 4, size = 3, stroke = 1.2) +
  scale_colour_manual(values = account_colours) +
  scale_size_area(max_size = 4, guide = "none") +
  labs(title = "Both counts", x = "Independent > dependent (participants)",
       y = "Dependent > independent (participants)", colour = "Account") +
  theme_classic()

# proportion of simulations with both counts within 2 participants of ours
p_near <- sim_summaries %>%
  group_by(account) %>%
  summarise(p_both_near = mean(abs(n_independent - observed$n_independent) <= 2 &
                                 abs(n_dependent - observed$n_dependent) <= 2)) %>%
  ggplot(aes(x = account, y = p_both_near, fill = account)) +
  geom_col(width = 0.6, show.legend = FALSE) +
  geom_text(aes(label = sub("^0", "", sprintf("%.3f", p_both_near))), vjust = -0.4) +
  scale_fill_manual(values = account_colours) +
  scale_x_discrete(labels = c("Noise\nonly", "Noise +\ncontinuous", "Noise +\nsubgroups")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
  labs(title = "Both counts within 2 of observed", x = NULL, y = "Proportion of simulations") +
  theme_classic()

# section headings: the commentary's results first, then both counts together
plotHeading <- function(heading){
  wrap_elements(full = grid::textGrob(heading, x = 0, hjust = 0,
                                      gp = grid::gpar(fontsize = 15, fontface = "bold")))
}

distribution_plot <- plotHeading("A. Results reported by Shepherdson (2026)") /
  (p_n_ind + p_n_dep) / (p_med_ind + p_med_dep) /
  (p_cor_all + p_cor_class) / (p_cor_unclass + p_ordered) /
  plotHeading("B. How often both observed counts occur together (new analyses)") /
  (p_joint + p_near) +
  plot_layout(guides = "collect", heights = c(0.15, 1, 1, 1, 1, 0.15, 1)) &
  theme(legend.position = "bottom")

ggsave(here("results/04_distributions.png"), distribution_plot, width = 9, height = 16)
