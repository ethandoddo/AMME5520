% setup_lab1_closedloop.m
%
% AMME5520 Lab 1.2 — Section 1.2.1 Closing the Loop
%
% Builds the closed-loop feedback model and saves it as lab1_closed.slx
% (Lab1.slx is left untouched). Uses the Simulated Plant for simulation
% in Normal mode (no hardware required).
%
% Control law implemented (Equation 1.1 from lab notes):
%   u(t) = -k * (x(t) - x_ref(t))  =  k * (x_ref(t) - x(t))
%   with k = 1 (Gain block as specified in lab)
%
% Block diagram:
%   x_ref --> [Sum(+-)] --> [Gain k=1] --> [Simulated Plant] --> x
%                ^_______________________________feedback (-)___|
%
% HOW TO USE:
%   1. Open MATLAB, set folder to AMME5520 directory
%   2. Run this script (type: setup_lab1_closedloop in Command Window)
%   3. Simulink will open with the closed-loop model wired up
%   4. Verify SimulationMode = Normal in the Simulink toolbar
%   5. Press Play/Run
%   6. Save results:
%        save('lab1_cl_results.mat', 'u', 'y', 't')
%   7. Run plot_results.m to generate the required plot
%
% NOTE: This script always starts from the original Lab1.slx.
%       Any previous unsaved changes to the model are discarded.

mdl     = 'Lab1';
backup  = 'Lab1_original.slx';
out_mdl = 'lab1_closed';    % output file — Lab1.slx is NOT overwritten

%% --- Ensure backup exists ---
if ~isfile(backup)
    error(['Backup file Lab1_original.slx not found.\n' ...
           'Please run setup_lab1_openloop.m first to create it.']);
end

%% --- Restore clean model from backup ---
if bdIsLoaded(mdl)
    close_system(mdl, 0);   % discard unsaved changes
end
copyfile(backup, [mdl '.slx']);   % overwrite with original

%% =========================================================================
%  REMOVE QUARC HARDWARE BLOCKS IF QUARC IS NOT INSTALLED
% =========================================================================

quarc_available = ~isempty(which('quarc_library'));

if ~quarc_available
    % Load into memory quietly and keep warnings suppressed through
    % the entire deletion section — find_system also triggers QUARC warnings.
    ws = warning('off', 'all');
    load_system(mdl);

    fprintf('QUARC not detected — removing hardware blocks for simulation.\n');

    % HIL Initialize is a Reference block — no Permissions parameter, just delete.
    if ~isempty(find_system(mdl, 'SearchDepth', 1, 'Name', 'HIL Initialize'))
        delete_block([mdl '/HIL Initialize']);
    end

    % Actual Plant is a ReadOnly SubSystem — must unlock before deleting.
    if ~isempty(find_system(mdl, 'SearchDepth', 1, 'Name', 'Actual Plant'))
        set_param([mdl '/Actual Plant'], 'Permissions', 'ReadWrite');
        delete_block([mdl '/Actual Plant']);
    end

    warning(ws);

    open_system(mdl);
else
    open_system(mdl);
end

%% =========================================================================
%  ADD BLOCKS
%
%  Canvas layout (x increases right, y increases down):
%
%    [200]         [310]   [390]      [515-------655]    [730]
%
%    Step(ref) --> Sum --> Gain  -->  Simulated Plant --> Scope_speed
%       |                  |                    |         simout_y
%       |                  |                    |
%       |     feedback (-) |____________________|
%       |
%    (branch)  --> Scope_Vm  (monitor u is wired from Gain output below)
%
%  HIL Initialize stays at [170, 54, 254, 129] untouched.
%  Actual Plant stays at [515, 409, 655, 491] untouched (used in hardware step).
% =========================================================================

% --- Step block: velocity reference signal (rad/s) ---
% "Make sure your Step block has your reference value (rad/s) in it,
%  NOT the control input value (V)" — lab notes Section 1.2.1
% Using 10 rad/s as the target.  Change 'After' to any velocity you want.
add_block('simulink/Sources/Step', [mdl '/Step'], ...
    'Position', [200, 200, 240, 230], ...
    'Time',     '1', ...        % step fires at t = 1s
    'Before',   '0', ...        % 0 rad/s before step
    'After',    '10');          % 10 rad/s reference — edit as needed

% --- Sum block: computes error  e = x_ref - x ---
% Inputs '+-' : first input is positive (reference), second is negative (feedback)
add_block('simulink/Math Operations/Sum', [mdl '/Sum'], ...
    'Position', [305, 200, 335, 230], ...
    'Inputs',   '+-');          % e = x_ref(+) - x(-)

% --- Gain block: controller with k = 1 ---
% This is the "Gain block with a gain of 1" specified in lab Section 1.2.1.
% To experiment with different gains, change the Gain value here.
add_block('simulink/Math Operations/Gain', [mdl '/Gain_Controller'], ...
    'Position', [385, 200, 425, 230], ...
    'Gain',     '1');           % k = 1; change to tune controller

% --- Scope: angular velocity output (rad/s) ---
add_block('simulink/Sinks/Scope', [mdl '/Scope_speed'], ...
    'Position', [730, 195, 760, 225], ...
    'Open',     'on');

% --- Scope: control input u (V) ---
add_block('simulink/Sinks/Scope', [mdl '/Scope_Vm'], ...
    'Position', [730, 290, 760, 320], ...
    'Open',     'on');

% --- To Workspace: angular velocity (y) ---
add_block('simulink/Sinks/To Workspace', [mdl '/simout_y'], ...
    'Position',      [730, 140, 820, 165], ...
    'VariableName',  'y', ...
    'SaveFormat',    'Array', ...   % MUST be Array, not timeseries
    'MaxDataPoints', 'inf');

% --- To Workspace: control input (u) ---
add_block('simulink/Sinks/To Workspace', [mdl '/simout_u'], ...
    'Position',      [730, 330, 820, 355], ...
    'VariableName',  'u', ...
    'SaveFormat',    'Array', ...
    'MaxDataPoints', 'inf');

% --- Clock: simulation time ---
add_block('simulink/Sources/Clock', [mdl '/Clock'], ...
    'Position', [350, 390, 390, 420]);

% --- To Workspace: time (t) ---
add_block('simulink/Sinks/To Workspace', [mdl '/simout_t'], ...
    'Position',      [450, 390, 540, 415], ...
    'VariableName',  't', ...
    'SaveFormat',    'Array', ...
    'MaxDataPoints', 'inf');

%% =========================================================================
%  WIRE CONNECTIONS
%
%  Forward path:
%    Step/1 ---> Sum/1           (reference x_ref, positive input)
%    Sum/1  ---> Gain_Controller/1   (error e)
%    Gain_Controller/1 ---> Simulated Plant/1   (control input u)
%
%  Output monitoring:
%    Simulated Plant/1 ---> Scope_speed/1   (angular velocity display)
%    Simulated Plant/1 ---> simout_y/1      (save y to workspace)
%
%  Feedback path:
%    Simulated Plant/1 ---> Sum/2   (x fed back into Sum negative input)
%
%  Control input monitoring:
%    Gain_Controller/1 ---> Scope_Vm/1    (display u)
%    Gain_Controller/1 ---> simout_u/1    (save u to workspace)
%
%  Time:
%    Clock/1 ---> simout_t/1
% =========================================================================

% Forward path
add_line(mdl, 'Step/1',             'Sum/1',                'autorouting', 'on');
add_line(mdl, 'Sum/1',              'Gain_Controller/1',    'autorouting', 'on');
add_line(mdl, 'Gain_Controller/1',  'Simulated Plant/1',    'autorouting', 'on');

% Output monitoring (two branches from Simulated Plant output)
add_line(mdl, 'Simulated Plant/1',  'Scope_speed/1',        'autorouting', 'on');
add_line(mdl, 'Simulated Plant/1',  'simout_y/1',           'autorouting', 'on');

% Feedback path
add_line(mdl, 'Simulated Plant/1',  'Sum/2',                'autorouting', 'on');

% Control input monitoring (two branches from Gain output)
add_line(mdl, 'Gain_Controller/1',  'Scope_Vm/1',           'autorouting', 'on');
add_line(mdl, 'Gain_Controller/1',  'simout_u/1',           'autorouting', 'on');

% Time
add_line(mdl, 'Clock/1',            'simout_t/1',           'autorouting', 'on');

%% =========================================================================
%  SIMULATION SETTINGS
% =========================================================================

set_param(mdl, 'StopTime',        '5');        % 5 second run
set_param(mdl, 'SimulationMode',  'normal');   % Normal mode (no hardware)

%% =========================================================================
%  SAVE
% =========================================================================

save_system(mdl, out_mdl);  % saves as lab1_closed.slx; Lab1.slx untouched

%% Done
disp('========================================================');
disp(' Lab1 closed-loop setup COMPLETE (Simulated Plant)');
disp('========================================================');
disp('Saved to: lab1_closed.slx');
disp('Controller: Gain k=1   |   Reference: 10 rad/s step at t=1s');
disp(' ');
disp('Next steps:');
disp('  1. Confirm Normal mode in Simulink toolbar');
disp('  2. Press Play/Run');
disp('  3. Save results with:');
disp('       save(''lab1_cl_results.mat'', ''u'', ''y'', ''t'')');
disp('  4. Run plot_results.m to generate the required plot');
disp(' ');
disp('To change controller gain:');
disp('  set_param(''lab1_closed/Gain_Controller'', ''Gain'', ''your_value'')');
disp('  then re-run the simulation.');
