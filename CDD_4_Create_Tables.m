% 1) Create TimeCourse Table for each Quartile (MeanSpacing and Variation)
% (e.g., 50 columns of Elo) and 8 rows
% 2) Create Subject Table (Rows = Subjects; Columns = MeanSpacing,
% MOstFrequentECO_Cat_Frequency, EloChange etc.)

clear S_timecourse T_timecourse elo_by_game elo_by_game_mean elo_by_game_sem
lower_rating = 2000;
upper_rating = 2200;
rating_range = ['rating_' num2str(lower_rating) 'to' num2str(upper_rating)];

num_games = 50;

tic
load(['S_quartiles_' rating_range '_' num2str(num_games) 'games.mat']);
toc

clear elo_by_game elo_by_game_mean elo_by_game_sem
%% Timecourse Table:
% Elo by Variation Quartile:
for q_num = 1:4
    elo = {S_quartiles([S_quartiles.MostFrequentECO_Cat_Frequency_Quartile] == q_num).Elo};
    tic
    for elo_num = 1:numel(elo)
        elo_by_game(elo_num,:) = [str2double({elo{elo_num}{1:num_games}})];
    end

    
    elo_by_game_mean = num2cell(mean(elo_by_game));
    elo_by_game_sem = num2cell(std(elo_by_game)/sqrt(length(elo_by_game)));
    [S_timecourse(1:num_games).(['Elo_Mean_by_MostFrequentECO_Cat_Frequency_Quartile_' num2str(q_num)])] = deal(elo_by_game_mean{:});
    [S_timecourse(1:num_games).(['Elo_SEM_by_MostFrequentECO_Cat_Frequency_Quartile_' num2str(q_num)])] = deal(elo_by_game_sem{:});
    toc
end

clear elo_by_game elo_by_game_mean elo_by_game_sem
% Elo by Spacing Quartile:
for q_num = 1:4
    elo = {S_quartiles([S_quartiles.MeanSpacing_Quartile] == q_num).Elo};
    tic
    for elo_num = 1:numel(elo)
        elo_by_game(elo_num,:) = [str2double({elo{elo_num}{1:num_games}})];
    end

    elo_by_game_mean = num2cell(mean(elo_by_game));
    elo_by_game_sem = num2cell(std(elo_by_game)/sqrt(length(elo_by_game)));
    [S_timecourse(1:num_games).(['Elo_Mean_by_MeanSpacing_Quartile_' num2str(q_num)])] = deal(elo_by_game_mean{:});
    [S_timecourse(1:num_games).(['Elo_SEM_by_MeanSpacing_Quartile_' num2str(q_num)])] = deal(elo_by_game_sem{:});
    toc
end
tic
T_timecourse = struct2table(S_timecourse);
writetable(T_timecourse, ['Quartiles_Timecourse_' rating_range '_' num2str(num_games) 'games.csv']);
toc

%% Subject Table:
S_measures = rmfield(S_quartiles, {'WhiteCount','BlackCount','Side','Elo','ECO','Opening','Result','TimeControl','UTCDateTime'});
MeanSpacing_sec = num2cell(seconds([S_quartiles.MeanSpacing]));
[S_measures(:).MeanSpacing] = deal(MeanSpacing_sec{:});
tic
T_measures = struct2table(S_measures);
writetable(T_measures, ['Subject_Measures_' rating_range '_' num2str(num_games) 'games.csv']);
toc
