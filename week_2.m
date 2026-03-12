rng(1);

% Set up the cost map
N = 150;
T = 100;
g = rand(T,N);

% Run the dynamic programming algorithm
V = dynamic_programming(g);
[~,i] = min(V(1,:));
cost = V(1,i);

fprintf('Optimal cost: %.2f\n',cost);


% Helper function to do dynamic programming
function V = dynamic_programming(g)

    [T, N] = size(g);

    % Initialise value function
    V = zeros(size(g));
    V(T,:) = g(T,:);
    
    % Possible control inputs (decisions)
    us = [-1, 0, 1];
    M = length(us);
    
    % Loop time
    for k = (T-1):-1:1
        
        % Loop states (columns)
        for j = 1:N
            
            % Search over control actions for optimal cost to go
            cost_to_go = NaN(1,3);
            for l = 1:M
                cost_to_go(l) = cost_g(j, us(l), k, g) + V(k+1, f(j, us(l), N));
            end
            V(k,j) = min(cost_to_go);
            
        end
        
    end
    
end 

% Dynamics: states are column positions, j
function x1 = f(x,u,N)
    x1 = x + u;
    
    % Wrap around boundaries
    if x1 < 1
        x1 = x1 + N;
    elseif x1 > N
        x1 = x1 - N;
    end
end

% Cost function (including state transitions)
function cg = cost_g(x,u,t,g)
    cg = g(t,x) + 0.4*abs(u);
end
