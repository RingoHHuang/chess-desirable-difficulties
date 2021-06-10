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
library(mmtable2)
setwd('E:\\Lichess\\')


lower_ratings = c(1000,1200,1400,1600,1800,2000)
upper_ratings = c(1200,1400,1600,1800,2000,2200)
num_games = 50


## Regression Summary Table:
summary_df <- data.frame(rating_range = character(), N = double(), coefficient = double(), r.square = double(), p = double(), group = character())
ttest_summary_df <- data.frame()
for (i in 1:6) {
  lower_rating = lower_ratings[i]
  upper_rating = upper_ratings[i]
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
  
  ## Regression:
  variation_model = lm(EloChange~MostFrequentECO_Cat_Frequency, sub_measures_nooutlier_dfdata)
  spacing_model = lm(EloChange~MeanSpacing, sub_measures_nooutlier_dfdata)
  
  # Save to summary_df
  summary_df = rbind(summary_df, 
                     list(paste(lower_rating, ' to ', upper_rating),
                          nrow(sub_measures_dfdata),
                          summary(variation_model)$coefficient[2,1], 
                          summary(variation_model)$r.squared, 
                          summary(variation_model)$coefficients[2,4],
                          "Variation")
                          )
  summary_df = rbind(summary_df, 
                     list(paste(lower_rating, ' to ', upper_rating),
                          nrow(sub_measures_dfdata),
                          summary(spacing_model)$coefficient[2,1], 
                          summary(spacing_model)$r.squared, 
                          summary(spacing_model)$coefficients[2,4],
                          "Spacing"))
  
  ## T-Tests:
  variation_ttest = t.test(sub_measures_nooutlier_dfdata$EloChange[sub_measures_nooutlier_dfdata$MostFrequentECO_Cat_Frequency_Quartile == 1],sub_measures_nooutlier_dfdata$EloChange[sub_measures_nooutlier_dfdata$MostFrequentECO_Cat_Frequency_Quartile == 4])
  spacing_ttest = t.test(sub_measures_nooutlier_dfdata$EloChange[sub_measures_nooutlier_dfdata$MeanSpacing_Quartile == 1],sub_measures_nooutlier_dfdata$EloChange[sub_measures_nooutlier_dfdata$MeanSpacing_Quartile == 4])
  
  ttest_summary_df = rbind(ttest_summary_df,
                           list(paste(lower_rating, ' to ', upper_rating),
                                nrow(sub_measures_dfdata),
                                variation_ttest$estimate[1],
                                variation_ttest$estimate[2],
                                variation_ttest$statistic,
                                variation_ttest$p.value,
                                'Variation'
                                ))
  ttest_summary_df = rbind(ttest_summary_df,
                           list(paste(lower_rating, ' to ', upper_rating),
                                nrow(sub_measures_dfdata),
                                spacing_ttest$estimate[1],
                                spacing_ttest$estimate[2],
                                spacing_ttest$statistic,
                                spacing_ttest$p.value,
                                'Spacing'
                           ))  
}


# Build table
names(summary_df) = list('rating_range','N','coefficient','r.square','p','group')
main_table <- summary_df %>%
  mutate(p = round(p, 3)) %>%
  mutate(r.square = round(r.square, 5)) %>%
  gt(rowname_col = "rating_range", groupname_col = "group") %>%
  tab_header(title = md("**Table 1: Regression Analyses Summary**")) %>%
  cols_label(rating_range = "Rating Range", coefficient = "Coefficient", r.square = md("*r*-squared"), p = md("*p*-value"))
  
  
main_table <- main_table %>%
  fmt_scientific(columns = coefficient, rows = c(2,4,6,8,10,12)) %>%
  fmt_number(columns = coefficient, rows = c(1,3,5,7,9,11), decimals = 2) %>%
  tab_footnote(
    footnote = md("*p*<.001"),
    locations = cells_body(columns = 'p', rows = c(5,7))
  ) %>%
  tab_footnote(
    footnote = md("*p*<.01"),
    locations = cells_body(columns = 'p', rows = c(3,6))
  ) %>%
  tab_footnote(
    footnote = md("*p*<.05"),
    locations = cells_body(columns = 'p', rows = c(9))
  ) %>%
  tab_footnote(
    footnote = md("*p*-values are uncorrected"),
    locations = cells_column_labels(columns = 'p')
  ) %>%
  tab_options(
    footnotes.marks = c('1','**','***','*'),
  )

main_table


### T-Tests Summary Table:
names(ttest_summary_df) = list('rating_range','N','x','y','statistic','p','group')
ttest_table <- ttest_summary_df %>%
  mutate(p = round(p, 3)) %>%
  mutate(x = round(x, 5)) %>%
  mutate(y = round(y, 5)) %>%
  gt(rowname_col = "rating_range", groupname_col = "group") %>%
  tab_header(title = md("**Table 2: Independent T-Tests Summary**")) %>%
  cols_label(rating_range = "Rating Range", x = md("Elo Change<br>1<sup>st</sup> Quartile"), y = md("Elo Change<br>4<sup>th</sup> Quartile"), statistic = md("*t*-stat"), p = md("*p*-value"))

ttest_table <- ttest_table %>%
  fmt_number(columns = c(x,y,statistic), decimals = 3) %>%
  tab_footnote(
    footnote = md("*p*<.001"),
    locations = cells_body(columns = 'p', rows = c(5,7))
  ) %>%
  tab_footnote(
    footnote = md("*p*<.01"),
    locations = cells_body(columns = 'p', rows = c(3,6))
  ) %>%
  tab_footnote(
    footnote = md("*p*-values are uncorrected"),
    locations = cells_column_labels(columns = 'p')
  ) %>%
  tab_options(
    footnotes.marks = c('1','**','***','*'),
  )

ttest_table