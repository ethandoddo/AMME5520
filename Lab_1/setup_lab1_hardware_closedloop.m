% setup_lab1_hardware_closedloop.m
%
% AMME5520 Lab 1.2 — Closed-loop hardware script
%
% Same as setup_lab1_closedloop.m but wired to the REAL Actual Plant
% (QUBE-Servo) instead of the Simulated Plant. Runs in External mode.
%
% HOW TO USE (on lab computer with QUARC installed):
%   1. Connect the QUBE-Servo USB cable
%   2. Run this script (type: setup_lab1_hardware_closedloop in Command Window)
%   3. Simulink will open in External mode — press Run to connect to hardware
%   4. After the run, save results:
%        save('lab1_hw_cl_results.mat', 'u', 'y', 't')

mdl    = 'Lab1';
backup = 'Lab1_original.slx';

%% --- Check QUARC is available ---
if isempty(which('quarc_library'))
    error('QUARC is not installed. Run this script on a lab computer with the QUBE-Servo connected.');
end

%% --- Ensure backup exists ---
if ~isfile(backup)
    error(['Backup file Lab1_original.slx not found.\n' ...
           'Please run setup_lab1_openloop.m first to create it.']);
end

%% --- Restore clean model from backup ---
if bdIsLoaded(mdl)
    close_system(mdl, 0);
end
copyfile(backup, [mdl '.slx']);
open_system(mdl);

%% =========================================================================
%  ADD BLOCKS
%  Actual Plant is at [515, 409, 655, 491] — blocks positioned around it.
% =========================================================================

% --- Step: velocity reference (rad/s) ---
add_block('simulink/Sources/Step', [mdl '/Step'], ...
    'Position', [200, 420, 240, 450], ...
    'Time',     '1', ...
    'Before',   '0', ...
    'After',    '10');          % 10 rad/s reference — change as needed

% --- Sum: error = x_ref - x ---
add_block('simulink/Math Operations/Sum', [mdl '/Sum'], ...
    'Position', [305, 420, 335, 450], ...
    'Inputs',   '+-');

% --- Gain: controller k = 1 ---
add_block('simulink/Math Operations/Gain', [mdl '/Gain_Controller'], ...
    'Position', [385, 420, 425, 450], ...
    'Gain',     '1');

% --- Scope: angular velocity output ---
add_block('simulink/Sinks/Scope', [mdl '/Scope_speed'], ...
    'Position', [730, 415, 760, 445], ...
    'Open',     'on');

% --- Scope: control input (V) ---
add_block('simulink/Sinks/Scope', [mdl '/Scope_Vm'], ...
    'Position', [730, 480, 760, 510], ...
    'Open',     'on');

% --- To Workspace: angular velocity (y) ---
add_block('simulink/Sinks/To Workspace', [mdl '/simout_y'], ...
    'Position',      [730, 360, 820, 385], ...
    'VariableName',  'y', ...
    'SaveFormat',    'Array', ...
    'MaxDataPoints', 'inf');

% --- To Workspace: control input (u) ---
add_block('simulink/Sinks/To Workspace', [mdl '/simout_u'], ...
    'Position',      [730, 525, 820, 550], ...
    'VariableName',  'u', ...
    'SaveFormat',    'Array', ...
    'MaxDataPoints', 'inf');

% --- Clock ---
add_block('simulink/Sources/Clock', [mdl '/Clock'], ...
    'Position', [350, 570, 390, 600]);

% --- To Workspace: time (t) ---
add_block('simulink/Sinks/To Workspace', [mdl '/simout_t'], ...
    'Position',      [450, 570, 540, 595], ...
    'VariableName',  't', ...
    'SaveFormat',    'Array', ...
    'MaxDataPoints', 'inf');

%% =========================================================================
%  WIRE CONNECTIONS  (Actual Plant instead of Simulated Plant)
% =========================================================================

% Forward path
add_line(mdl, 'Step/1',            'Sum/1',               'autorouting', 'on');
add_line(mdl, 'Sum/1',             'Gain_Controller/1',   'autorouting', 'on');
add_line(mdl, 'Gain_Controller/1', 'Actual Plant/1',      'autorouting', 'on');

% Output monitoring
add_line(mdl, 'Actual Plant/1',    'Scope_speed/1',       'autorouting', 'on');
add_line(mdl, 'Actual Plant/1',    'simout_y/1',          'autorouting', 'on');

% Feedback path
add_line(mdl, 'Actual Plant/1',    'Sum/2',               'autorouting', 'on');

% Control input monitoring
add_line(mdl, 'Gain_Controller/1', 'Scope_Vm/1',          'autorouting', 'on');
add_line(mdl, 'Gain_Controller/1', 'simout_u/1',          'autorouting', 'on');

% Time
add_line(mdl, 'Clock/1',           'simout_t/1',          'autorouting', 'on');

%% =========================================================================
%  SIMULATION SETTINGS
% =========================================================================

set_param(mdl, 'StopTime',        '5');
set_param(mdl, 'SimulationMode',  'external');   % External mode for hardware

%% =========================================================================
%  SAVE
% =========================================================================

save_system(mdl, 'lab1_hw_closedloop');

%% Done
disp('========================================================');
disp(' Lab1 hardware closed-loop setup COMPLETE');
disp('========================================================');
disp('Saved to: lab1_hw_closedloop.slx');
disp('Controller: Gain k=1  |  Reference: 10 rad/s step at t=1s');
disp(' ');
disp('Next steps:');
disp('  1. Make sure the QUBE-Servo is connected via USB');
disp('  2. Press Run in Simulink (External mode connects to hardware)');
disp('  3. Save results with:');
disp('       save(''lab1_hw_cl_results.mat'', ''u'', ''y'', ''t'')');
disp(' ');
disp('To change controller gain:');
disp('  set_param(''lab1_hw_closedloop/Gain_Controller'', ''Gain'', ''your_value'')');
disp('  then re-run the simulation.');
