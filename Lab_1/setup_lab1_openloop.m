% setup_lab1_openloop.m
%
% AMME5520 Lab 1.2 — Step 2 setup script
%
% Adds a 2V Step input, two Scopes, and To Workspace blocks to Lab1.slx,
% then wires everything to the Simulated Plant for open-loop simulation
% in Normal mode.
%
% HOW TO USE:
%   1. Open MATLAB and set the current folder to the AMME5520 directory
%   2. Run this script (type: setup_lab1_openloop in the Command Window)
%   3. Simulink will open — press Play/Run (Normal mode)
%   4. After the run, save results:
%        save('lab1_sim_results.mat', 'u', 'y', 't')
%
% NOTE: Run on the original unmodified Lab1.slx.
%       If you have already run this script, re-run it to reset to a clean state.

mdl    = 'Lab1';
backup = 'Lab1_original.slx';

%% --- Create backup of the untouched original (once only) ---
% On first run, save a copy of the unmodified Lab1.slx so that subsequent
% scripts can always restore a clean starting point.
if ~isfile(backup)
    copyfile([mdl '.slx'], backup);
    fprintf('Backup created: %s\n', backup);
end

%% --- Restore clean model from backup ---
% Close any open (possibly modified) version, restore from backup, then open.
if bdIsLoaded(mdl)
    close_system(mdl, 0);   % discard unsaved changes
end
copyfile(backup, [mdl '.slx']);   % overwrite with original

%% =========================================================================
%  REMOVE QUARC HARDWARE BLOCKS IF QUARC IS NOT INSTALLED
%
%  QUARC (Quanser) is only available on lab computers with hardware.
%  At home, HIL Initialize and Actual Plant cause load errors because
%  Simulink tries to resolve quarc_library links at load time.
%
%  Fix: load the model silently (warnings suppressed), delete the QUARC
%  blocks, THEN open the GUI — so errors never appear.
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

    warning(ws);    % restore previous warning state

    % Now open the GUI — model is already loaded and QUARC blocks are gone
    open_system(mdl);
else
    open_system(mdl);
end

%% =========================================================================
%  ADD BLOCKS
%  All positions are [left, top, right, bottom] in pixels.
%  Existing blocks (from XML):
%    Simulated Plant  [515, 167, 655, 253]  (light blue, 1-in 1-out)
%    Actual Plant     [515, 409, 655, 491]  (green,      1-in 1-out)
%    HIL Initialize   [170,  54, 254, 129]  (QUARC hardware init)
% =========================================================================

% --- Step block: 2V step at t = 1s ---
% Position: left of Simulated Plant, vertically centred with it
add_block('simulink/Sources/Step', [mdl '/Step'], ...
    'Position',  [350, 195, 390, 225], ...
    'Time',      '1', ...       % step fires at t = 1s (matches Figure 1.3)
    'Before',    '0', ...       % value before step = 0 V
    'After',     '2');          % value after  step = 2 V

% --- Scope: angular velocity output (rad/s) ---
% Position: right of Simulated Plant
add_block('simulink/Sinks/Scope', [mdl '/Scope_speed'], ...
    'Position',  [730, 195, 760, 225], ...
    'Open',      'on');         % auto-open scope window on run

% --- Scope: motor voltage input (V) ---
% Position: below Scope_speed, so we can monitor the command signal  
add_block('simulink/Sinks/Scope', [mdl '/Scope_Vm'], ...
    'Position',  [730, 290, 760, 320], ...
    'Open',      'on');

% --- To Workspace: angular velocity → workspace variable 'y' ---
add_block('simulink/Sinks/To Workspace', [mdl '/simout_y'], ...
    'Position',    [730, 140, 820, 165], ...
    'VariableName', 'y', ...
    'SaveFormat',  'Array', ...     % MUST be Array, not timeseries (lab warning)
    'MaxDataPoints', 'inf');        % save all data points (default 1000 is too few)

% --- To Workspace: voltage command → workspace variable 'u' ---
add_block('simulink/Sinks/To Workspace', [mdl '/simout_u'], ...
    'Position',    [730, 330, 820, 355], ...
    'VariableName', 'u', ...
    'SaveFormat',  'Array', ...
    'MaxDataPoints', 'inf');

% --- Clock: provides the simulation time vector ---
add_block('simulink/Sources/Clock', [mdl '/Clock'], ...
    'Position',  [350, 330, 390, 360]);

% --- To Workspace: simulation time → workspace variable 't' ---
add_block('simulink/Sinks/To Workspace', [mdl '/simout_t'], ...
    'Position',    [450, 330, 540, 355], ...
    'VariableName', 't', ...
    'SaveFormat',  'Array', ...
    'MaxDataPoints', 'inf');

%% =========================================================================
%  WIRE CONNECTIONS
%  Syntax: add_line(model, 'SrcBlock/outPort', 'DstBlock/inPort')
%  Calling add_line multiple times from the same output port creates branches.
% =========================================================================

% Step → Simulated Plant  (send 2V command to simulated motor)
add_line(mdl, 'Step/1', 'Simulated Plant/1', 'autorouting', 'on');

% Simulated Plant output → speed Scope  (visualise angular velocity)
add_line(mdl, 'Simulated Plant/1', 'Scope_speed/1', 'autorouting', 'on');

% Simulated Plant output → simout_y  (save angular velocity to workspace)
add_line(mdl, 'Simulated Plant/1', 'simout_y/1', 'autorouting', 'on');

% Step → voltage Scope  (branch: monitor the command signal)
add_line(mdl, 'Step/1', 'Scope_Vm/1', 'autorouting', 'on');

% Step → simout_u  (branch: save command voltage to workspace)
add_line(mdl, 'Step/1', 'simout_u/1', 'autorouting', 'on');

% Clock → simout_t  (save time vector to workspace)
add_line(mdl, 'Clock/1', 'simout_t/1', 'autorouting', 'on');

%% =========================================================================
%  SIMULATION SETTINGS
% =========================================================================

set_param(mdl, 'StopTime', '5');            % 5 second run (matches Figure 1.2)
set_param(mdl, 'SimulationMode', 'normal'); % Normal mode for simulation

%% =========================================================================
%  SAVE
% =========================================================================

save_system(mdl);

%% Done
disp('========================================================');
disp(' Lab1 open-loop setup COMPLETE');
disp('========================================================');
disp('Next steps:');
disp('  1. In Simulink, confirm mode is set to Normal');
disp('  2. Press Play/Run');
disp('  3. Show scope results to your tutor (should match Figure 1.3)');
disp('  4. Save results with:');
disp('       save(''lab1_sim_results.mat'', ''u'', ''y'', ''t'')');
