close all;
clear;
clc;

% Our example system
nodeLetters = ['s','A','B','C','D'];
 
% g(x,y), if no path set cost to inf
%    to s  to A, to B,  to C,  to D
g = [inf,    10,    5,   inf,   inf;... % from s
     inf,   inf,    3,     1,   inf;... % from A
     inf,     3,  inf,     9,     2;... % from B
     inf,   inf,  inf,   inf,     4;... % from C
       7,   inf,  inf,     6,   inf];   % from D

% Run the algorithm
[Vr_n, path_n] = dijkstra(g, nodeLetters);

% Print results
disp("Cost to reach:");
disp(Vr_n);

disp("Optimal paths to each node:")
disp(path_n);


% AMME5520 Advanced Control and Optimisation
% MATLAB Grader Week 3
%
% Function runs Dijkstra's algorithm given an adjacency matrix (node graph)
%
% INPUTS:
%   - g:            KxK adjacency matrix of weights for connected nodes
%   - node_names:   Array of node names (optional)
%
% OUTPUTS:
%   
%   - cost:         Total cost of the optimal path
%   - path:         Optimal path from start to end node
%
% Author: Nicholas Barbara
% Email:  nicholas.barbara@sydney.edu.au
%
% [cost_to_reach, path] = dijkstra(g, node_names)

function [cost_to_reach, path] = dijkstra(g, node_names)

    % Number of nodes and starting node
    [num_nodes,~] = size(g);
    start_node = 1;

    % Set up node IDs/names (if required)
    node_IDs = 1:num_nodes;
    if nargin < 2
        node_names = node_IDs;
    end
    
    % Initialise cost to reach, predecessor nodes, solved nodes, and the queue
    cost_to_reach = Inf(1,num_nodes);
    cost_to_reach(start_node) = 0;
    predecessor = NaN(1,num_nodes);
    solved = false(1,num_nodes);
    queue = true(1,num_nodes);
    
    % Loop Dijkstra's algorithm until the queue is empty
    iters = 0;
    while any(queue)
        
        % Select the node with minimum cost to reach and move this node 
        % to the set of solved nodes
        queued_nodes = node_IDs(queue);
        [~, indx] = min(cost_to_reach(queue));
        node = queued_nodes(indx);
        if length(node) > 1
            node = node(1);
        end
        queue(node) = false;
        solved(node) = true;
        
        % Pick out adjacent nodes that are in the queue
        indx = (g(node,:) > 0) & queue;
        adj_nodes = node_IDs(indx);
        adj_costs = g(node, indx);
        
        % Correct the label if appropriate
        for i = 1:length(adj_nodes)
            new_cost = cost_to_reach(node) + adj_costs(i);
            if new_cost < cost_to_reach(adj_nodes(i))
                cost_to_reach(adj_nodes(i)) = new_cost;
                predecessor(adj_nodes(i)) = node;
            end
        end
        
        % Update the iteration counter
        iters = iters + 1;
        
    end
    
    % Return the path
    path = cell(1,num_nodes);
    for i = 1:num_nodes
        p = NaN(1,num_nodes);
        k = 1;
        p(1) = node_IDs(i);
        while ~ismember(start_node, p)
            p(k+1) = predecessor(p(k));
            k = k + 1;
        end
        p = p(~isnan(p));
        path{i} = flip(node_names(p));
    end
end
