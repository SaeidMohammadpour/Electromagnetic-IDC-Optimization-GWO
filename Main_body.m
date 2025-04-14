% main_GWO_IDC.m
clc; clear; close all;

%% Constants and Target
epsilon_r = 2.33;        % Dielectric constant
N = 10;                  % Number of fingers
target_C_series = 1.30;  % Target series capacitance in pF

%% Design Variable Bounds [W, S, l]
lb = [0.05, 0.05, 5000];  % Lower bounds
ub = [0.3,  0.3,  7000];  % Upper bounds

%% GWO Parameters
SearchAgents_no = 30;    % Number of search agents (wolves)
Max_iter = 200;          % Maximum number of iterations
dim = 3;                 % Number of design variables

%% Initialize the Positions of Search Agents
Positions = zeros(SearchAgents_no, dim);
for i = 1:dim
    Positions(:,i) = lb(i) + rand(SearchAgents_no,1) * (ub(i) - lb(i));
end

%% Initialize Alpha, Beta, and Delta
Alpha_pos = zeros(1,dim);   Alpha_score = inf;
Beta_pos = zeros(1,dim);    Beta_score  = inf;
Delta_pos = zeros(1,dim);   Delta_score = inf;

% To store historical data for plotting
Alpha_history = zeros(Max_iter, dim);
Beta_history  = zeros(Max_iter, dim);
Delta_history = zeros(Max_iter, dim);
Alpha_C_history = zeros(Max_iter, 1);
Beta_C_history  = zeros(Max_iter, 1);
Delta_C_history = zeros(Max_iter, 1);
Convergence_curve = zeros(1, Max_iter);

a_linear_component = 2; % 'a' decreases linearly from 2 to 0

%% Main GWO Loop
for iter = 1:Max_iter
    % Evaluate fitness for each search agent
    for i = 1:SearchAgents_no
        % Ensure the current agent is within the bounds
        for j = 1:dim
            Positions(i,j) = max(Positions(i,j), lb(j));
            Positions(i,j) = min(Positions(i,j), ub(j));
        end
        
        % Compute the objective function (absolute error from target)
        fitness = objectiveFunction(Positions(i,:), epsilon_r, N, target_C_series);
        
        % Update Alpha, Beta, and Delta wolves based on fitness (minimization)
        if fitness < Alpha_score
            Delta_score = Beta_score;
            Delta_pos = Beta_pos;
            
            Beta_score = Alpha_score;
            Beta_pos = Alpha_pos;
            
            Alpha_score = fitness;
            Alpha_pos = Positions(i,:);
        elseif fitness < Beta_score
            Delta_score = Beta_score;
            Delta_pos = Beta_pos;
            
            Beta_score = fitness;
            Beta_pos = Positions(i,:);
        elseif fitness < Delta_score
            Delta_score = fitness;
            Delta_pos = Positions(i,:);
        end
    end
    
    % Store current iteration's best wolf positions and capacitances
    Alpha_history(iter,:) = Alpha_pos;
    Beta_history(iter,:)  = Beta_pos;
    Delta_history(iter,:) = Delta_pos;
    
    Alpha_C_history(iter) = calculate_C_series(Alpha_pos(1), Alpha_pos(2), Alpha_pos(3), epsilon_r, N);
    Beta_C_history(iter)  = calculate_C_series(Beta_pos(1), Beta_pos(2), Beta_pos(3), epsilon_r, N);
    Delta_C_history(iter) = calculate_C_series(Delta_pos(1), Delta_pos(2), Delta_pos(3), epsilon_r, N);
    
    % Update convergence information
    Convergence_curve(iter) = Alpha_score;
    fprintf('Iteration %d: Best Fitness = %e\n', iter, Alpha_score);
    
    % Update the coefficient 'a', linearly decreasing from 2 to 0
    a = a_linear_component - iter * (a_linear_component / Max_iter);
    
    % Update the positions of search agents
    for i = 1:SearchAgents_no
        for j = 1:dim
            % Compute coefficients for Alpha
            r1 = rand(); r2 = rand();
            A1 = 2 * a * r1 - a; C1 = 2 * r2;
            D_alpha = abs(C1 * Alpha_pos(j) - Positions(i,j));
            X1 = Alpha_pos(j) - A1 * D_alpha;
            
            % Compute coefficients for Beta
            r1 = rand(); r2 = rand();
            A2 = 2 * a * r1 - a; C2 = 2 * r2;
            D_beta = abs(C2 * Beta_pos(j) - Positions(i,j));
            X2 = Beta_pos(j) - A2 * D_beta;
            
            % Compute coefficients for Delta
            r1 = rand(); r2 = rand();
            A3 = 2 * a * r1 - a; C3 = 2 * r2;
            D_delta = abs(C3 * Delta_pos(j) - Positions(i,j));
            X3 = Delta_pos(j) - A3 * D_delta;
            
            % Update the position of the current agent
            Positions(i,j) = (X1 + X2 + X3) / 3;
        end
    end   
end

%% Display the Optimized Parameters and Resulting Capacitance
fprintf('\nOptimized Parameters:\n');
fprintf('Finger Width (W'') = %.4f mm\n', Alpha_pos(1));
fprintf('Finger Spacing (S)  = %.4f mm\n', Alpha_pos(2));
fprintf('Finger Length (l)   = %.2f µm\n', Alpha_pos(3));
fprintf('Resulting Series Capacitance = %.4f pF\n', Alpha_C_history(end));

%% Plotting the Diagrams
iterations = 1:Max_iter;

% Note: The ordering in our design vector is [W, S, l]. 
% The plots are requested in the order: S (finger spacing), W (finger width), L (finger length), and Series capacitance.
% Hence, for S we use column 2, for W column 1, for L column 3.

figure;
plot(iterations, Alpha_history(:,2), 'r-', 'LineWidth', 2); hold on;
plot(iterations, Beta_history(:,2), 'b--', 'LineWidth', 2);
plot(iterations, Delta_history(:,2), 'g-.', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Finger Spacing (S) [mm]');
title('Evolution of Finger Spacing (S)');
legend('Alpha', 'Beta', 'Delta');
grid on;

figure;
plot(iterations, Alpha_history(:,1), 'r-', 'LineWidth', 2); hold on;
plot(iterations, Beta_history(:,1), 'b--', 'LineWidth', 2);
plot(iterations, Delta_history(:,1), 'g-.', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Finger Width (W) [mm]');
title('Evolution of Finger Width (W)');
legend('Alpha', 'Beta', 'Delta');
grid on;

figure;
plot(iterations, Alpha_history(:,3), 'r-', 'LineWidth', 2); hold on;
plot(iterations, Beta_history(:,3), 'b--', 'LineWidth', 2);
plot(iterations, Delta_history(:,3), 'g-.', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Finger Length (L) [µm]');
title('Evolution of Finger Length (L)');
legend('Alpha', 'Beta', 'Delta');
grid on;

figure;
plot(iterations, Alpha_C_history, 'r-', 'LineWidth', 2); hold on;
plot(iterations, Beta_C_history, 'b--', 'LineWidth', 2);
plot(iterations, Delta_C_history, 'g-.', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Series Capacitance [pF]');
title('Evolution of Series Capacitance');
legend('Alpha', 'Beta', 'Delta');
grid on;
% Convergence curve
figure;
plot(1:Max_iter, Convergence_curve, 'k-', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Best Fitness (Error)');
title('Convergence Curve of GWO');
grid on;

