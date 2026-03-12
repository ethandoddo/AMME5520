# Lab 1.2 — QUBE-Servo Implementation Plan

## Model Analysis (Verified from XML)

**Existing top-level blocks in `Lab1.slx`:**

| Block | Type | Position | Ports |
|---|---|---|---|
| `Simulated Plant` | SubSystem (light blue) | [515, 167, 655, 253] | 1 in, 1 out |
| `Actual Plant` | SubSystem (green, ReadOnly) | [515, 409, 655, 491] | 1 in, 1 out |
| `HIL Initialize` | Reference (QUARC) | [170, 54, 254, 129] | none |

**What's currently missing (no blocks, no wiring at the top level):**
- No Step block
- No Scope blocks
- No To Workspace blocks
- No lines/connections between blocks

**Simulated Plant internals (ReadOnly):**
- Transfer function: `23.2 / (0.1175s + 1)`
- Input port: `u` (voltage)
- Output port: `theta_dot` (rad/s)

**Actual Plant internals (ReadOnly):**
- Signal chain: Input(V) → Saturation(±10V) → HIL Write Analog → HIL Read Encoder → Inverse Modulus → Gain(2π/2048) → Transfer Fcn(150s/(s+150)) → Output(rad/s)

---

## Implementation Steps

### Step 1: Open-Loop Simulation (Normal Mode)

**Goal:** Send a 2V step to the Simulated Plant and observe with Scope.

**MATLAB script `setup_lab1_openloop.m` should:**

1. **Open the model**
   - `open_system('Lab1')`

2. **Add a Step block** (2V step at t=1s)
   - Block: `simulink/Sources/Step`
   - Path: `Lab1/Step`
   - Position: to the left of Simulated Plant (~[350, 190, 380, 220])
   - Parameters:
     - `Time` = `1` (step at t=1s — matches Figure 1.3 where step occurs ~1s)
     - `Before` = `0`
     - `After` = `2` (2V step command)

3. **Add a Scope block** for speed output (rad/s)
   - Block: `simulink/Sinks/Scope`
   - Path: `Lab1/speed (rad//s)`
   - Position: to the right of Simulated Plant (~[750, 190, 780, 220])

4. **Add a Scope block** for input voltage monitoring
   - Block: `simulink/Sinks/Scope`
   - Path: `Lab1/Vm (V)`
   - Position: below the Step block (~[350, 280, 380, 310])

5. **Add To Workspace blocks** (for saving data as `.mat`)
   - `Lab1/simout_y` — captures speed output
     - `VariableName` = `y`
     - `SaveFormat` = `Array`
   - `Lab1/simout_u` — captures voltage input
     - `VariableName` = `u`
     - `SaveFormat` = `Array`
   - `Lab1/simout_t` — captures time via Clock block
     - `VariableName` = `t`
     - `SaveFormat` = `Array`

6. **Add a Clock block** (for time vector)
   - Block: `simulink/Sources/Clock`
   - Path: `Lab1/Clock`

7. **Wire connections:**
   - `Step/1` → `Simulated Plant/1` (step input to plant)
   - `Simulated Plant/1` → `speed (rad//s)/1` (output to scope)
   - `Step/1` → `Vm (V)/1` (input to voltage scope — branch line)
   - `Simulated Plant/1` → `simout_y/1` (output to workspace)
   - `Step/1` → `simout_u/1` (input to workspace)
   - `Clock/1` → `simout_t/1` (time to workspace)

8. **Set simulation parameters:**
   - Stop time: `5` (matches Figure 1.3 — 5 second simulation)
   - Solver: `ode45` (default, fine for this)

9. **Save the model**

### Step 2: Run and Verify (Manual in MATLAB)

After running the script:
1. Press **Play/Run** in Simulink (Normal mode)
2. Verify Scope output matches Figure 1.3:
   - Speed should rise to ~40 rad/s steady state (from 23.2/0.1175 × 2V ≈ 39.5 rad/s after transient)
   - Input should show clean 2V step
3. Save results: `save('lab1_sim_results.mat', 'u', 'y', 't')`

### Step 3: Hardware Mode (Actual Plant — External Mode)

**Goal:** Replace Simulated Plant with Actual Plant for hardware testing.

**MATLAB script `setup_lab1_hardware.m` should:**

1. Disconnect lines from `Simulated Plant`
2. Reconnect `Step/1` → `Actual Plant/1`
3. Reconnect `Actual Plant/1` → `speed (rad//s)/1` and `simout_y/1`
4. Set simulation mode to External: `set_param('Lab1', 'SimulationMode', 'external')`
5. Save model

**Manual steps after script (cannot be scripted):**
- Click **Build** in Simulink toolbar
- Click **Connect to Target**
- Click **Play/Run**
- Save results: `save('lab1_hw_results.mat', 'u', 'y', 't')`

---

## Uncertainties & Notes

| Item | Certainty | Notes |
|---|---|---|
| Block positions | ~90% | Chosen to avoid overlap with existing blocks. May need minor adjustment if layout looks off — visually verify in Simulink after running script. |
| Step time = 1s | 95% | Figure 1.3 shows step at ~1s. Will use `1`. |
| Stop time = 5s | 200% | Lab instructions explicitly say "Run for 5s" in Figure 1.2. Model XML also has `PauseTimes = 5`. |
| To Workspace format = Array | 200% | Lab instructions explicitly warn to change from timeseries to Array. |
| Port numbering (`/1`) | 200% | Both plant subsystems have exactly 1 input port and 1 output port (verified from XML `Ports=[1,1]`). |
| `add_line` syntax | 200% | Standard MATLAB Simulink API: `add_line('model', 'srcBlock/portNum', 'dstBlock/portNum')` |
| Simulated Plant transfer function | 200% | Verified: `Numerator=[23.2]`, `Denominator=[0.1175 1]` from XML. |

---

## File Structure After Implementation

```
AMME5520/
├── Lab1.slx                      (modified by scripts)
├── setup_lab1_openloop.m         (Step 1: add blocks + wire for simulation)
├── setup_lab1_hardware.m         (Step 3: rewire for actual plant)
├── lab1_sim_results.mat          (saved after simulation run)
├── lab1_hw_results.mat           (saved after hardware run)
├── Lab1_implementation_plan.md   (this file)
├── dijkstra_algorithm.m          (existing — unrelated)
└── dp_verify.m                   (existing — unrelated)
```

---

## Ready to Proceed?

Once you approve this plan, I will create:
1. `setup_lab1_openloop.m` — builds the open-loop simulation model
2. `setup_lab1_hardware.m` — switches wiring to actual plant for hardware

Both scripts are designed to be run once in MATLAB before opening the Simulink model.
