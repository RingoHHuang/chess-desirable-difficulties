% 1. Count the number of games per player (both as black and as white)
% 2. Decide on a upper/lower cutoff
% 3. For each player that meets the number of games criteria, get the eco
% code


clear S_combined S_group S_players T

lower_rating = 1200;
upper_rating = 1400;
rating_range = ['rating_' num2str(lower_rating) 'to' num2str(upper_rating)];

ALLgames_files = dir([rating_range '*_ALLgames.mat']);




for file_num = 1:numel(ALLgames_files)
%for file_num = 1:2
    S_players = struct();
    load(ALLgames_files(file_num).name);
    disp(ALLgames_files(file_num).name);
    % Only include games for subjects that were in the first day of the month
    if file_num > 1
        [~, i_wg, i_wc] = intersect({S_group.White},{S_combined.Player});
        [~, i_bg, i_bc] = intersect({S_group.Black},{S_combined.Player});
        i_g = union(i_wg, i_bg);
        S_group = S_group(i_g);
    end
    
    tic
    for Sides = {'Black', 'White'}
        Side = Sides{1};
        
        [b_sorted, b_ind] = sort({S_group.(Side)});
        i = 1;
        while i <= numel(b_sorted)
            S_player_ind = numel(S_players) + 1;
            
            current_player = b_sorted{i};
            b_indices = b_ind(i);
            i = i+1;
            while i <= numel(b_sorted) && strcmp(current_player, b_sorted{i})
                b_indices = [b_indices b_ind(i)];
                i = i+1;
            end
            
            S_players(S_player_ind).Player = {S_group(b_indices(1)).(Side)};
            S_players(S_player_ind).Side = Side;
            S_players(S_player_ind).Count = numel(b_indices);
            S_players(S_player_ind).MatchOrder = b_indices;
            S_players(S_player_ind).UTCDate = {S_group(b_indices).UTCDate};
            S_players(S_player_ind).UTCTime = {S_group(b_indices).UTCTime};
            S_players(S_player_ind).Elo = {S_group(b_indices).([Side 'Elo'])};
            S_players(S_player_ind).ECO = {S_group(b_indices).ECO};
            S_players(S_player_ind).Opening = {S_group(b_indices).Opening};
            S_players(S_player_ind).Result = {S_group(b_indices).Result};
            S_players(S_player_ind).TimeControl = {S_group(b_indices).TimeControl};
        end
    end
    toc
    
    tic
    S_players(1) = [];
    T = struct2table(S_players);
    T = sortrows(T, 'Player');
    S_players = table2struct(T);    % structures are faster
    clear T;

    
    % Remove subjects who do not appear on first day (note - weird
    % intersect behavior does not keep repetitions)
    if file_num > 1
        i_p = find(ismember({S_players.Player}, {S_combined.Player}));
        S_players = S_players(i_p);
    end
    toc
        
    S_row = 1;
    S_combined_num = 1;
    tic
    while S_row <= height(S_players)
 
        b_S_row = [];
        w_S_row = [];
        Player = S_players(S_row).Player;
        if strcmp(S_players(S_row).Side, 'Black')
            b_S_row = S_row;
        elseif strcmp(S_players(S_row).Side, 'White')
            w_S_row = S_row;
        end
        if S_row < height(S_players) && strcmp(S_players(S_row+1).Player, Player)
            if strcmp(S_players(S_row+1).Side, 'Black')
                b_S_row = S_row + 1;
            elseif strcmp(S_players(S_row+1).Side, 'White')
                w_S_row = S_row + 1;
            end
        end
        S_row = S_row + ~isempty(b_S_row) + ~isempty(w_S_row);      % update T_row either once (if only one side) or twice (if two sides)

        
        b_order = [];
        w_order = [];
        if ~isempty(b_S_row)
            b_order = S_players(b_S_row).MatchOrder;
        end
        if ~isempty(w_S_row)
            w_order = S_players(w_S_row).MatchOrder;
        end
        [sorted, sorted_ind] = sort([b_order w_order]);
        sequence = [zeros(1,numel(b_order)) ones(1,numel(w_order))];    % black/white match sequence (0's = Black, 1's = white)
        sequence = sequence(sorted_ind);            % sequence is sorted according to the match order
        
        % Find S_combined_num for file_num > 1(efficiently)

        if file_num > 1
            while ~strcmp(S_combined(S_combined_num).Player,Player)
                S_combined_num = S_combined_num + 1;
            end
            b_cell_sub = find(~sequence) + numel(S_combined(S_combined_num).Side);
            w_cell_sub = find(sequence) + numel(S_combined(S_combined_num).Side);
        elseif file_num == 1
            b_cell_sub = find(~sequence);
            w_cell_sub = find(sequence);
            S_combined(S_combined_num).WhiteCount = 0;
            S_combined(S_combined_num).BlackCount = 0;
        end

        if ~isempty(b_S_row)
            S_combined(S_combined_num).Player = S_players(b_S_row).Player;
            S_combined(S_combined_num).BlackCount = S_players(b_S_row).Count + S_combined(S_combined_num).BlackCount;
            [S_combined(S_combined_num).Side{b_cell_sub}] = deal('Black');
            [S_combined(S_combined_num).Elo{b_cell_sub}] = deal(S_players(b_S_row).Elo{:});
            [S_combined(S_combined_num).ECO{b_cell_sub}] = deal(S_players(b_S_row).ECO{:});
            [S_combined(S_combined_num).Opening{b_cell_sub}] = deal(S_players(b_S_row).Opening{:});
            [S_combined(S_combined_num).Result{b_cell_sub}] = deal(S_players(b_S_row).Result{:});
            [S_combined(S_combined_num).TimeControl{b_cell_sub}] = deal(S_players(b_S_row).TimeControl{:});
            [S_combined(S_combined_num).UTCDate{b_cell_sub}] = deal(S_players(b_S_row).UTCDate{:});
            [S_combined(S_combined_num).UTCTime{b_cell_sub}] = deal(S_players(b_S_row).UTCTime{:});
        end
        
        if ~isempty(w_S_row)
            S_combined(S_combined_num).Player = S_players(w_S_row).Player;
            S_combined(S_combined_num).WhiteCount = S_players(w_S_row).Count +  S_combined(S_combined_num).WhiteCount;
            [S_combined(S_combined_num).Side{w_cell_sub}] = deal('White');
            [S_combined(S_combined_num).Elo{w_cell_sub}] = deal(S_players(w_S_row).Elo{:});
            [S_combined(S_combined_num).ECO{w_cell_sub}] = deal(S_players(w_S_row).ECO{:});
            [S_combined(S_combined_num).Opening{w_cell_sub}] = deal(S_players(w_S_row).Opening{:});
            [S_combined(S_combined_num).Result{w_cell_sub}] = deal(S_players(w_S_row).Result{:});
            [S_combined(S_combined_num).TimeControl{w_cell_sub}] = deal(S_players(w_S_row).TimeControl{:});
            [S_combined(S_combined_num).UTCDate{w_cell_sub}] = deal(S_players(w_S_row).UTCDate{:});
            [S_combined(S_combined_num).UTCTime{w_cell_sub}] = deal(S_players(w_S_row).UTCTime{:});
        end

        S_combined_num = S_combined_num + 1;
    end
    toc
    

end

% Minimum Exclusion Criteria (at least 5 games)
inclusion_la = [S_combined.WhiteCount] + [S_combined.BlackCount] > 5;
S_combined = S_combined(inclusion_la);

save(['S_combined_' rating_range '.mat'],'S_combined');
