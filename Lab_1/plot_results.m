% plot_results.m
%
% AMME5520 Lab 1.2 — Results plotting script
%
% Loads saved .mat results and generates publication-quality figures of
% the angular velocity response and control input.
%
% HOW TO USE:
%   After running a simulation or hardware test and saving results:
%     save('lab1_cl_results.mat', 'u', 'y', 't')   % or lab1_sim_results.mat
%
%   Edit the SETTINGS section below (filename, reference value),
%   then run: plot_results in the MATLAB Command Window.

%% =========================================================================
%  SETTINGS — edit these to match your run
% =========================================================================

results_file = 'lab1_cl_results.mat';  % file to load (change as needed)
x_ref        = 10;                     % reference velocity used (rad/s)
plot_title   = 'Closed-Loop Step Response — Simulated Plant';

% Set to true if you also want to save the figure as a .png
save_figure  = false;
figure_file  = 'lab1_cl_response.png';

%% =========================================================================
%  LOAD DATA
% =========================================================================

if ~isfile(results_file)
    error('Results file ''%s'' not found.\nRun the simulation first and save with:\n  save(''%s'', ''u'', ''y'', ''t'')', ...
        results_file, results_file);
end

data = load(results_file);

% Support both variable-name conventions
t = data.t(:);   % time vector (s)
y = data.y(:);   % angular velocity output (rad/s)
u = data.u(:);   % control input (V)

%% =========================================================================
%  PLOT
% =========================================================================

fig = figure('Name', 'Lab 1 Results', 'NumberTitle', 'off', ...
             'Units', 'centimeters', 'Position', [2, 2, 20, 14]);

% --- Top subplot: angular velocity ---
ax1 = subplot(2, 1, 1);
hold on;

% Reference line
yline(x_ref, '--', 'Reference', ...
    'Color', [0.6, 0.6, 0.6], ...
    'LineWidth', 1.2, ...
    'LabelVerticalAlignment', 'bottom');

% System response
plot(t, y, 'b-', 'LineWidth', 1.5);

hold off;
xlabel('Time (s)');
ylabel('Angular velocity (rad/s)');
title(plot_title);
legend('Reference', 'Response', 'Location', 'southeast');
grid on;
xlim([t(1), t(end)]);

% --- Bottom subplot: control input ---
ax2 = subplot(2, 1, 2);
plot(t, u, 'r-', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Control input, u (V)');
title('Control input');
grid on;
xlim([t(1), t(end)]);

% Link x-axes so zooming on one zooms both
linkaxes([ax1, ax2], 'x');

%% =========================================================================
%  OPTIONAL: SAVE FIGURE
% =========================================================================

if save_figure
    exportgraphics(fig, figure_file, 'Resolution', 300);
    fprintf('Figure saved to: %s\n', figure_file);
end

%% Print summary statistics
fprintf('\n--- Response Summary ---\n');
fprintf('Reference velocity : %.1f rad/s\n', x_ref);

% Find steady-state (average of last 20%% of the run)
ss_idx = t >= 0.8 * t(end);
ss_val = mean(y(ss_idx));
fprintf('Steady-state output: %.2f rad/s\n', ss_val);
fprintf('Steady-state error : %.2f rad/s  (%.1f%%)\n', ...
    x_ref - ss_val, 100 * (x_ref - ss_val) / x_ref);

% Rise time: 10%% to 90%% of reference
y_norm = (y - y(1)) / (x_ref - y(1));
i10 = find(y_norm >= 0.10, 1);
i90 = find(y_norm >= 0.90, 1);
if ~isempty(i10) && ~isempty(i90)
    fprintf('Rise time (10-90%%): %.3f s\n', t(i90) - t(i10));
end
