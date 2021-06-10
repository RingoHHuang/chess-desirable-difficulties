library(readxl)
library(ggplot2)
library(tidyverse)
library(jmv)
library(gridExtra)
library(grid)
library(ggsignif)
library(latex2exp)
library(hexbin)
library(ggExtra)
setwd('E:\\Lichess\\')

lower_rating = 1200;
upper_rating = 1400;
num_games = 50;

sub_measures_dfdata = read.csv(paste('E:\\Lichess\\Subject_Measures_rating_',toString(lower_rating),'to',toString(upper_rating),'_',toString(num_games),'games.csv',sep=''))



# Outliers
elochange_lower_bound <- quantile(sub_measures_dfdata$EloChange, .01, names = TRUE)
elochange_upper_bound <- quantile(sub_measures_dfdata$EloChange, .99)
variation_lower_bound <- quantile(sub_measures_dfdata$MostFrequentECO_Cat_Frequency, .001)
variation_upper_bound <- quantile(sub_measures_dfdata$MostFrequentECO_Cat_Frequency, .999)
spacing_lower_bound <- quantile(sub_measures_dfdata$MeanSpacing, .001)
spacing_upper_bound <- quantile(sub_measures_dfdata$MeanSpacing, .999)

outlier_la = sub_measures_dfdata$EloChange < elochange_lower_bound |
  sub_measures_dfdata$EloChange > elochange_upper_bound

sub_measures_dfdata$outlier = 0
sub_measures_dfdata$outlier[outlier_la] = 1
sub_measures_nooutlier_dfdata = subset(sub_measures_dfdata, outlier==0)

# Regression:
model = lm(EloChange~MeanSpacing + MostFrequentECO_Cat_Frequency, sub_measures_nooutlier_dfdata)
model = lm(EloChange~MostFrequentECO_Cat_Frequency, sub_measures_nooutlier_dfdata)

# Define colors:
manual_colors = c("#8BB8E8","#2774AE") # UCLA Blues
boxplot_color = "#FFD100" # UCLA Gold

title_str = paste("4. Elo Range:", lower_rating, "to", upper_rating)
# With Margins
pl_1 <- ggplot(sub_measures_nooutlier_dfdata, aes(x=MostFrequentECO_Cat_Frequency, y=EloChange)) +
  geom_point(alpha = .07, size = .6, position = "jitter") +
  geom_smooth(formula=y~x, color=manual_colors[2], lwd = 1.2) +
  ylim(elochange_lower_bound, upper_bound) +
  labs(title = title_str,
        x = "Frequency of Most Commonly Played Opening",
       y = "Change in Elo Rating")

ggMarginal(pl_1, fill = manual_colors[1], color = manual_colors[1], gtype = "density", size = 10)

pl_2 <- ggplot(sub_measures_nooutlier_dfdata, aes(x=MeanSpacing, y=EloChange)) +
  geom_point(alpha = .08, size = .6) +
  geom_smooth(formula=y~x, color=manual_colors[2], lwd = 1.2) +
  ylim(lower_bound, upper_bound) +
  labs(title = title_str,
       x = "Average Time Between Games (s)",
       y = "Change in Elo Rating")

ggMarginal(pl_2, fill = manual_colors[1], color = manual_colors[1], gtype = "density", size = 10)

# Violin with BoxPlot - Spacing
boxplots_dfdata <- sub_measures_nooutlier_dfdata %>%
  subset(MeanSpacing_Quartile == c(1,4)) %>%
  mutate(MeanSpacing_Quartile = factor(MeanSpacing_Quartile))
title_str = paste("1. Elo Range:", lower_rating, "to", upper_rating)

pl_spacing <- ggplot(boxplots_dfdata, aes(group = MeanSpacing_Quartile, x=MeanSpacing_Quartile, y=EloChange, fill = MeanSpacing_Quartile, color = MeanSpacing_Quartile)) +
  geom_violin(draw_quantiles = TRUE, width = .55) +
  geom_boxplot(width=0.35, color=boxplot_color, alpha=0.5, outlier.alpha = 0, lwd = 1, fatten = 1) +
  geom_signif(comparisons = list(c("1","4")), map_signif_level=TRUE, test = "t.test", test.args = list(paired = FALSE), textsize = 4, color = "black") + # compare means using independent t-tests
  scale_fill_manual(values = manual_colors) +
  scale_color_manual(values = manual_colors) +
  ylim(-300, 300) +
  labs(title = title_str,
        x = "Average Time Between Games Quartile",
       y = "Change in Elo Rating") +
  theme(legend.position = "none")  # remove legend


# Variation
boxplots_dfdata <- sub_measures_nooutlier_dfdata %>%
  subset(MostFrequentECO_Cat_Frequency_Quartile == c(1,4)) %>%
  mutate(MostFrequentECO_Cat_Frequency_Quartile = factor(MostFrequentECO_Cat_Frequency_Quartile))

#t.test(boxplots_dfdata$EloChange,boxplots_dfdata$MostFrequentECO_Cat_Frequency_Quartile)

pl_variation <- ggplot(boxplots_dfdata, aes(group = MostFrequentECO_Cat_Frequency_Quartile, x=MostFrequentECO_Cat_Frequency_Quartile, y=EloChange, fill = MostFrequentECO_Cat_Frequency_Quartile, color = MostFrequentECO_Cat_Frequency_Quartile)) +
  geom_violin(draw_quantiles = TRUE, width = .55) +
  geom_boxplot(width=0.35, color=boxplot_color, alpha=0.5, outlier.alpha = 0, lwd = 1, fatten = 1) + 
  geom_signif(comparisons = list(c("1","4")),map_signif_level=TRUE, test = "t.test", test.args = list(paired = FALSE), textsize = 4, color = "black") + # compare means using independent t-tests
  scale_fill_manual(values = manual_colors) +
  scale_color_manual(values = manual_colors) +
  ylim(-300, 300) +
  labs(x = "Most Frequent Opening Frequency Quartile",
       y = "") +
  theme(legend.position = "none")  # remove legend

grid.arrange(pl_spacing, pl_variation, nrow = 1)
