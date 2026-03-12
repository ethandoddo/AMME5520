% setup_lab1_hardware_openloop.m
%
% AMME5520 Lab 1.2 — Open-loop hardware script
%
% Same as setup_lab1_openloop.m but wired to the REAL Actual Plant
% (QUBE-Servo) instead of the Simulated Plant. Runs in External mode.
%
% HOW TO USE (on lab computer with QUARC installed):
%   1. Connect the QUBE-Servo USB cable
%   2. Run this script (type: setup_lab1_hardware_openloop in Command Window)
%   3. Simulink will open in External mode — press Run to connect to hardware
%   4. After the run, save results:
%        save('lab1_hw_ol_results.mat', 'u', 'y', 't')

mdl    = 'Lab1';
backup = 'Lab1_original.slx';

%% --- Check QUARC is available ---
if isempty(which('quarc_library'))
    error('QUARC is not installed. Run this script on a lab computer with the QUBE-Servo connected.');
end

%% --- Ensure backup exists ---
if ~isfile(backup)
    copyfile([mdl '.slx'], backup);
    fprintf('Backup created: %s\n', backup);
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

% --- Step block: 2V step at t = 1s ---
add_block('simulink/Sources/Step', [mdl '/Step'], ...
    'Position',  [350, 415, 390, 445], ...
    'Time',      '1', ...
    'Before',    '0', ...
    'After',     '2');

% --- Scope: angular velocity output (rad/s) ---
add_block('simulink/Sinks/Scope', [mdl '/Scope_speed'], ...
    'Position',  [730, 415, 760, 445], ...
    'Open',      'on');

% --- Scope: motor voltage input (V) ---
add_block('simulink/Sinks/Scope', [mdl '/Scope_Vm'], ...
    'Position',  [730, 490, 760, 520], ...
    'Open',      'on');

% --- To Workspace: angular velocity → 'y' ---
add_block('simulink/Sinks/To Workspace', [mdl '/simout_y'], ...
    'Position',    [730, 360, 820, 385], ...
    'VariableName', 'y', ...
    'SaveFormat',  'Array', ...
    'MaxDataPoints', 'inf');

% --- To Workspace: voltage command → 'u' ---
add_block('simulink/Sinks/To Workspace', [mdl '/simout_u'], ...
    'Position',    [730, 530, 820, 555], ...
    'VariableName', 'u', ...
    'SaveFormat',  'Array', ...
    'MaxDataPoints', 'inf');

% --- Clock ---
add_block('simulink/Sources/Clock', [mdl '/Clock'], ...
    'Position',  [350, 570, 390, 600]);

% --- To Workspace: time → 't' ---
add_block('simulink/Sinks/To Workspace', [mdl '/simout_t'], ...
    'Position',    [450, 570, 540, 595], ...
    'VariableName', 't', ...
    'SaveFormat',  'Array', ...
    'MaxDataPoints', 'inf');

%% =========================================================================
%  WIRE CONNECTIONS  (Actual Plant instead of Simulated Plant)
% =========================================================================

% Step → Actual Plant
add_line(mdl, 'Step/1', 'Actual Plant/1', 'autorouting', 'on');

% Actual Plant output → speed Scope
add_line(mdl, 'Actual Plant/1', 'Scope_speed/1', 'autorouting', 'on');

% Actual Plant output → simout_y
add_line(mdl, 'Actual Plant/1', 'simout_y/1', 'autorouting', 'on');

% Step → voltage Scope
add_line(mdl, 'Step/1', 'Scope_Vm/1', 'autorouting', 'on');

% Step → simout_u
add_line(mdl, 'Step/1', 'simout_u/1', 'autorouting', 'on');

% Clock → simout_t
add_line(mdl, 'Clock/1', 'simout_t/1', 'autorouting', 'on');

%% =========================================================================
%  SIMULATION SETTINGS
% =========================================================================

set_param(mdl, 'StopTime', '5');
set_param(mdl, 'SimulationMode', 'external');   % External mode for hardware

%% =========================================================================
%  SAVE
% =========================================================================

save_system(mdl, 'lab1_hw_openloop');

%% Done
disp('========================================================');
disp(' Lab1 hardware open-loop setup COMPLETE');
disp('========================================================');
disp('Saved to: lab1_hw_openloop.slx');
disp('Next steps:');
disp('  1. Make sure the QUBE-Servo is connected via USB');
disp('  2. Press Run in Simulink (External mode connects to hardware)');
disp('  3. Save results with:');
disp('       save(''lab1_hw_ol_results.mat'', ''u'', ''y'', ''t'')');
