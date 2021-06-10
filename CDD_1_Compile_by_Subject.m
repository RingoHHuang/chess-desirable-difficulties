% Calculate number of games per player
% Game Count: Black Count and White Count


lower_rating = 1000;
upper_rating = 1200;
rating_range = ['rating_' num2str(lower_rating) 'to' num2str(upper_rating)];

ALLgames_files = dir([rating_range '*_ALLgames.mat']);

S_players = struct('Player',[],'BlackCount',[],'WhiteCount',[],'Elo',[]);
players = {};
discarded_players = {};
for file_num = 1:numel(ALLgames_files)
    tic
    load(ALLgames_files(file_num).name);
    toc
    
    disp(['Working on ' ALLgames_files(file_num).name '...']);
    
    players = unique([players {S_group.White} {S_group.Black}]);    % append new unique players from this file to the players cell array
    
    tic
    for i = 1:numel(players)
        player = players{i};

        % Initiate new row if new player
        if ~strcmp({S_players.Player},player)
            next_ind = numel(S_players)+1;
            S_players(next_ind).Player = player;
            S_players(next_ind).BlackCount = 0;
            S_players(next_ind).WhiteCount = 0;
        end

        S_players_la = strcmp({S_players.Player},player);   
        
        % Get current cell length (before updating the counts)
        cell_length = S_players(S_players_la).BlackCount + S_players(S_players_la).WhiteCount;

        tic
        % Update the count
        S_group_black_la = strcmp({S_group.Black},player);
        S_group_white_la = strcmp({S_group.White},player);
        S_players(S_players_la).BlackCount = S_players(S_players_la).BlackCount + sum(S_group_black_la);
        S_players(S_players_la).WhiteCount = S_players(S_players_la).WhiteCount + sum(S_group_white_la);
        toc
        tic
        % Elo/ECO/Opening (This is a complicated but efficient? way of merging and
        % retaining order of black/white matches)
        combined_seq = double(S_group_black_la);
        combined_seq(S_group_black_la) = 2;
        combined_seq = combined_seq + S_group_white_la;
        combined_seq(combined_seq==0) = [];
        black_sub = find(combined_seq == 2) + cell_length;
        white_sub = find(combined_seq == 1) + cell_length;
        toc

        [S_players(S_players_la).Elo{black_sub}] = deal(S_group(S_group_black_la).BlackElo);
        [S_players(S_players_la).Elo{white_sub}] = deal(S_group(S_group_white_la).WhiteElo);

        [S_players(S_players_la).ECO{black_sub}] = deal(S_group(S_group_black_la).ECO);
        [S_players(S_players_la).ECO{white_sub}] = deal(S_group(S_group_white_la).ECO);

%         tic
%         S_players(S_players_la).ECO = {S_group(logical(S_group_black_la + S_group_white_la)).ECO};
%         toc

        [S_players(S_players_la).Opening{black_sub}] = deal(S_group(S_group_black_la).Opening);
        [S_players(S_players_la).Opening{white_sub}] = deal(S_group(S_group_white_la).Opening);

        % Remove players that if the ELO of their first match was outside the defined range (it
        % happens if e.g. higher rated player plays against another player
        % within the defined range)

        if str2double(S_players(S_players_la).Elo(1)) < lower_rating || str2double(S_players(S_players_la).Elo(1)) >= upper_rating
            discarded_players = [discarded_players S_players(S_players_la).Player];
            S_players(S_players_la) = [];
            
        end
        
        if mod(i,2000) == 0
            % Every 2000 rows, remove all rows from S_group that's
            % already had their Black and White players recorded (makes
            % strcmp faster)

            [~, ~, i_b] = intersect([{S_players(2:end).Player}, discarded_players],{S_group.Black});
            [~, ~, i_w] = intersect([{S_players(2:end).Player}, discarded_players],{S_group.White});
            i_intersect = intersect(i_b, i_w);

            S_group(i_intersect) = [];
        end

        disp('end')
    end
    toc    
end