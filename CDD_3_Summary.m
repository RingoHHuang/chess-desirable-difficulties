% Variation Score: 
%   1. Number of ECO openings 
%   2. Number of ECO family
%   3. Weighted ECO openings (e.g., the first instance is a 1; the second
%   instance of the same opening is a 2; etc)

% Spacing Score

% "Learning" Performance Outcome;
%   1. Change in ELO
%   2. Win/Loss/Tie rate


lower_rating = 1200;
upper_rating = 1400;
rating_range = ['rating_' num2str(lower_rating) 'to' num2str(upper_rating)];


tic
%load(['S_combined_' rating_range '.mat']);
toc

% Criteria - Number of games
num_games = 50;
tic
S_quartiles = S_combined([S_combined.WhiteCount] + [S_combined.BlackCount] > num_games);
toc

tic
for S_num = 1:numel(S_quartiles)

    % Spacing Score (average time between games):
    S_quartiles(S_num).UTCDateTime = datetime(strcat(S_quartiles(S_num).UTCDate, S_quartiles(S_num).UTCTime),'InputFormat','yyyy.MM.ddHH:mm:ss');   % Convert to datetime
    S_quartiles(S_num).MeanSpacing = mean(diff(S_quartiles(S_num).UTCDateTime(1:num_games)));
    
    % Variation Score:
    S_quartiles(S_num).UniqueECO_SubCat = numel(unique(S_quartiles(S_num).ECO(1:num_games)));
    cat = cellfun(@(x) x(1), S_quartiles(S_num).ECO(1:num_games));
    S_quartiles(S_num).UniqueECO_Cat = numel(unique(cat));
    [S_quartiles(S_num).MostFrequentECO_Cat, count, ~] = mode(cat);
    S_quartiles(S_num).MostFrequentECO_Cat_Frequency = count/num_games;

    % Overall Outcome (Change in Elo through num_games)
    S_quartiles(S_num).EloChange = str2double(S_quartiles(S_num).Elo{num_games}) - str2double(S_quartiles(S_num).Elo{1});
end
toc

% No longer need these two fields
S_quartiles = rmfield(S_quartiles, {'UTCDate', 'UTCTime'});



% label with quartile of the most frequently played ECO category frequency
freq_quartiles = quantile([S_quartiles.MostFrequentECO_Cat_Frequency],[.25, .5, .75]);
first_quartile_freq_sub = find([S_quartiles.MostFrequentECO_Cat_Frequency] < freq_quartiles(1));
second_quartile_freq_sub = find([S_quartiles.MostFrequentECO_Cat_Frequency] >= freq_quartiles(1) & [S_quartiles.MostFrequentECO_Cat_Frequency] < freq_quartiles(2));
third_quartile_freq_sub = find([S_quartiles.MostFrequentECO_Cat_Frequency] >= freq_quartiles(2) & [S_quartiles.MostFrequentECO_Cat_Frequency] < freq_quartiles(3));
fourth_quartile_freq_sub = find([S_quartiles.MostFrequentECO_Cat_Frequency] >= freq_quartiles(3));
[S_quartiles(first_quartile_freq_sub).MostFrequentECO_Cat_Frequency_Quartile] = deal(1);
[S_quartiles(second_quartile_freq_sub).MostFrequentECO_Cat_Frequency_Quartile] = deal(2);
[S_quartiles(third_quartile_freq_sub).MostFrequentECO_Cat_Frequency_Quartile] = deal(3);
[S_quartiles(fourth_quartile_freq_sub).MostFrequentECO_Cat_Frequency_Quartile] = deal(4);


% label with quartile of the MeanSpacing
spacing_quartiles = quantile([S_quartiles.MeanSpacing],[.25, .5, .75]);
first_quartile_spacing_sub = find([S_quartiles.MeanSpacing] < spacing_quartiles(1));
second_quartile_spacing_sub = find([S_quartiles.MeanSpacing] >= spacing_quartiles(1) & [S_quartiles.MeanSpacing] < spacing_quartiles(2));
third_quartile_spacing_sub = find([S_quartiles.MeanSpacing] >= spacing_quartiles(2) & [S_quartiles.MeanSpacing] < spacing_quartiles(3));
fourth_quartile_spacing_sub = find([S_quartiles.MeanSpacing] >= spacing_quartiles(3));
[S_quartiles(first_quartile_spacing_sub).MeanSpacing_Quartile] = deal(1);
[S_quartiles(second_quartile_spacing_sub).MeanSpacing_Quartile] = deal(2);
[S_quartiles(third_quartile_spacing_sub).MeanSpacing_Quartile] = deal(3);
[S_quartiles(fourth_quartile_spacing_sub).MeanSpacing_Quartile] = deal(4);

save(['S_quartiles_' rating_range '_' num2str(num_games) 'games.mat'], 'S_quartiles');


% Random stats:
scatter([S_quartiles.MostFrequentECO_Cat_Frequency],[S_quartiles.EloChange]);

[r1,p1] = corrcoef([S_quartiles.MostFrequentECO_Cat_Frequency],[S_quartiles.EloChange]);


 scatter([S_quartiles.MeanSpacing],[S_quartiles.EloChange]);
 [r2,p2] = corrcoef(seconds([S_quartiles.MeanSpacing]),[S_quartiles.EloChange]);
