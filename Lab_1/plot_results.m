% plot_results.m
%
% AMME5520 Lab 1 — Results plotting script
%
% Loads hardware open-loop and closed-loop .mat results and generates
% publication-quality figures.

close all; clear; clc;

%% =========================================================================
%  SETTINGS
% =========================================================================

x_ref = 10;  % reference velocity (rad/s) — closed-loop only

%% =========================================================================
%  FIGURE 1: Open-Loop Hardware Response
% =========================================================================

ol = load('lab1_hw_openloop_results.mat');
t_ol = ol.t(:);
y_ol = ol.y(:);
u_ol = double(ol.u(:));

fig1 = figure('Name', 'Open-Loop Response', 'NumberTitle', 'off', ...
              'Units', 'centimeters', 'Position', [2, 2, 22, 14]);

% --- Angular velocity ---
ax1 = subplot(2,1,1);
plot(t_ol, y_ol, 'Color', [0 0.45 0.74], 'LineWidth', 1.4);
ylabel('Angular velocity (rad/s)', 'FontSize', 11);
title('Open-Loop Hardware Response', 'FontSize', 13);
grid on; box on;
set(ax1, 'FontSize', 10);
xlim([t_ol(1) t_ol(end)]);

% --- Control input ---
ax2 = subplot(2,1,2);
plot(t_ol, u_ol, 'Color', [0.85 0.33 0.10], 'LineWidth', 1.4);
xlabel('Time (s)', 'FontSize', 11);
ylabel('Control input (V)', 'FontSize', 11);
title('Control Input', 'FontSize', 13);
grid on; box on;
set(ax2, 'FontSize', 10);
xlim([t_ol(1) t_ol(end)]);

linkaxes([ax1 ax2], 'x');

%% =========================================================================
%  FIGURE 2: Closed-Loop Hardware Response
% =========================================================================

cl = load('lab1_hw_closedloop_results.mat');
t_cl = cl.t(:);
y_cl = cl.y(:);
u_cl = cl.u(:);

fig2 = figure('Name', 'Closed-Loop Response', 'NumberTitle', 'off', ...
              'Units', 'centimeters', 'Position', [26, 2, 22, 14]);

% --- Angular velocity with reference ---
ax3 = subplot(2,1,1);
hold on;
yline(x_ref, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.2);
plot(t_cl, y_cl, 'Color', [0 0.45 0.74], 'LineWidth', 1.4);
hold off;
ylabel('Angular velocity (rad/s)', 'FontSize', 11);
title('Closed-Loop Hardware Step Response', 'FontSize', 13);
legend('Reference', 'Response', 'Location', 'best', 'FontSize', 10);
grid on; box on;
set(ax3, 'FontSize', 10);
xlim([t_cl(1) t_cl(end)]);

% --- Control input ---
ax4 = subplot(2,1,2);
plot(t_cl, u_cl, 'Color', [0.85 0.33 0.10], 'LineWidth', 1.4);
xlabel('Time (s)', 'FontSize', 11);
ylabel('Control input (V)', 'FontSize', 11);
title('Control Input', 'FontSize', 13);
grid on; box on;
set(ax4, 'FontSize', 10);
xlim([t_cl(1) t_cl(end)]);

linkaxes([ax3 ax4], 'x');

%% =========================================================================
%  SUMMARY STATISTICS (closed-loop)
% =========================================================================

fprintf('\n--- Closed-Loop Response Summary ---\n');
fprintf('Reference velocity : %.1f rad/s\n', x_ref);

ss_idx = t_cl >= 0.8 * t_cl(end);
ss_val = mean(y_cl(ss_idx));
fprintf('Steady-state output: %.2f rad/s\n', ss_val);
fprintf('Steady-state error : %.2f rad/s  (%.1f%%)\n', ...
    x_ref - ss_val, 100 * abs(x_ref - ss_val) / x_ref);

y_norm = (y_cl - y_cl(1)) / (x_ref - y_cl(1));
i10 = find(y_norm >= 0.10, 1);
i90 = find(y_norm >= 0.90, 1);
if ~isempty(i10) && ~isempty(i90)
    fprintf('Rise time (10-90%%): %.3f s\n', t_cl(i90) - t_cl(i10));
end

y_peak = max(y_cl);
if y_peak > x_ref
    fprintf('Overshoot          : %.1f%%\n', 100*(y_peak - x_ref)/x_ref);
else
    fprintf('Overshoot          : none\n');
end
