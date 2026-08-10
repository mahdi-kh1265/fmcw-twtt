# V0 / V1 Implementation Specification

**Status:** DRAFT — awaiting approval before any code is written.
**Scope:** Ideal complex-baseband FMCW truth model (V0) and ideal reciprocal two-way timing (V1).
**Repository:** `fmcw-theory`
**Date:** 2026-08-10

---

## A. Model Conventions

Every equation, variable name, and unit choice stated below is **binding** for the implementation. If any ambiguity arises during coding, this section is authoritative.

### A.1 Chirp Slope

```
S = B / Tc    [Hz/s]
```

where `B` is sweep bandwidth in Hz and `Tc` is the physical FMCW ramp duration in seconds.

The slope `S` is the single parameter that enters all V0/V1 waveform and estimation equations. It is stored and used internally in **Hz/s only**. Any TI-convention value (e.g., MHz/us) is converted exactly once at the configuration boundary:

```
S_Hz_per_s = S_MHz_per_us * 1e12
```

The nominal AWR-like demonstration value is:

```
S = 29.982 MHz/us = 2.9982e13 Hz/s
```

`B` and `Tc` may appear in the config struct as metadata (for documentation, future AWR2944 profile mapping, and plot labeling), but they do not independently enter any V0/V1 equation. Only `S` does.

### A.2 Observation Duration vs. Chirp Duration

The V0/V1 model requires exactly three waveform parameters: `S`, `Fs`, and `N`.

The **observation duration** is:

```
Tobs = N / Fs    [s]
```

This is the sampled ADC window. For the headline parameters:

```
N  = 256
Fs = 10e6 Hz
Tobs = 25.6 us
```

`Tobs` is **not** equated with the physical chirp duration `Tc`. On real AWR2944 hardware, the chirp ramp duration, ADC start time, number of ADC samples, and ramp end time are distinct hardware parameters. The chirp may extend before and/or beyond the ADC observation window.

For V0/V1, the analytic chirp `s(t) = exp(j*pi*S*t^2)` is evaluated over the time vector `t = (0:N-1)'/Fs` regardless of any physical ramp boundary. No `Tc` parameter is needed in the V0/V1 signal chain.

### A.3 Time Vector Convention

The discrete time vector is:

```
t[n] = n / Fs,    n = 0, 1, ..., N-1
```

where `Fs` is the baseband sample rate in Hz and `N` is the number of samples.

- **Time origin:** `t[0] = 0`.
- `t` is a **column vector** of length `N`.
- All times are in **seconds (SI)**.

### A.4 Complex-Baseband Transmitted Waveform

The transmitted signal is a unit-amplitude complex-baseband LFM chirp:

```
s(t) = exp(j * pi * S * t^2)
```

This is a true complex-baseband chirp. The RF carrier frequency `fc` (nominally ~77 GHz) **does not appear** in the V0/V1 sampled waveform. Specifically:

- Do NOT numerically include `exp(j*2*pi*fc*t)` in V0/V1.
- Do NOT add the `2*pi*fc*delta` constant phase term to the beat merely to make the model appear more RF-like.
- `fc` may exist in the configuration struct as metadata for plot annotations and documentation, but it must not participate in V0/V1 waveform generation, dechirping, or beat-frequency estimation.

Carrier-phase / frequency-phase fusion is a later extension and must be introduced deliberately with its phase ambiguity modeled correctly.

The instantaneous frequency of the baseband signal is:

```
f_bb(t) = S * t    [Hz]
```

### A.5 Continuous Fractional-Delay Implementation

The received signal delayed by delta seconds is:

```
r(t) = s(t - delta) = exp(j * pi * S * (t - delta)^2)
```

This is implemented by **evaluating the analytic phase expression at the shifted argument** `(t - delta)`:

```matlab
phi_rx = pi * S * (t - delta).^2;
rx     = exp(1j * phi_rx);
```

**PROHIBITED implementations:**
- `circshift` or any integer-sample shift
- `round(delta * Fs)` or `floor(delta * Fs)`
- Sinc interpolation of a pre-sampled waveform (unnecessary for V0/V1)
- Any operation whose delay granularity is `1/Fs`

The analytic evaluation keeps a 10-ps delay **exact** even when the sample spacing is 100 ns (at 10 MHz).

### A.6 Dechirp / Mixer Convention

The dechirped beat signal is formed by:

```
z(t) = s(t) * conj(r(t))
```

That is: **local reference chirp times conjugate of received signal.**

Expanding the phase:

```
phi_z(t) = pi*S*t^2 - pi*S*(t - delta)^2
         = pi*S*[t^2 - t^2 + 2*t*delta - delta^2]
         = 2*pi*S*delta * t  -  pi*S*delta^2
```

This is **exactly linear in t**, confirming the dechirped signal is a pure complex tone.

### A.7 Resulting Sign of Beat Frequency

From A.6, the beat frequency is:

```
    f_b = S * delta
```

Under this convention:

| Condition | Beat frequency sign |
|---|---|
| Positive slope S > 0, positive delay delta > 0 | f_b > 0 |
| Positive slope S > 0, negative delay delta < 0 | f_b < 0 |
| Negative slope S < 0, positive delay delta > 0 | f_b < 0 |
| Reversing conjugation to z = r * conj(s) | f_b changes sign |

The constant phase offset is:

```
phi_0 = -pi * S * delta^2
```

This is a **constant** that does not affect frequency estimation.

### A.8 Closed-Form Dechirped Waveform

For the baseband chirp `s(t) = exp(j*pi*S*t^2)`, delayed copy `r(t) = exp(j*pi*S*(t-delta)^2)`, and dechirp convention `z(t) = s(t).*conj(r(t))`, the resulting beat signal has the closed-form expression:

```
z_expected(t) = exp(j * (2*pi*S*delta*t - pi*S*delta^2))
```

This identity must be tested directly (see test T13 in Section F). The simulated complex beat vector must match `z_expected` sample-by-sample to tight tolerance. This test is important because estimator-only tests could allow a waveform bug and an estimator bug to compensate one another.

### A.9 Units

All internal computation uses SI units. No exceptions.

| Quantity | Symbol | Unit | MATLAB variable |
|---|---|---|---|
| Chirp slope | S | Hz/s | `cfg.S` |
| Sample rate | Fs | Hz | `cfg.Fs` |
| Number of samples | N | — | `cfg.N` |
| Carrier frequency (metadata) | fc | Hz | `cfg.fc` |
| Speed of light (metadata) | c | m/s | `cfg.c` |
| One-way delay | tau | s | (function argument) |
| Clock offset | theta | s | (function argument) |
| Effective delay | delta | s | (function argument) |
| Beat frequency | f_b | Hz | (computed) |
| Observation duration | Tobs | s | `cfg.N / cfg.Fs` (derived, not stored) |

Conversions from TI conventions (MHz/us, GHz, ksps, us) happen **only** inside `make_default_params.m` and are documented there.

### A.10 One-Way Cross-Link vs. Monostatic Round-Trip

This project models an **active cooperative one-way cross-link** between two stations, not a monostatic radar echo.

Do not introduce the monostatic radar round-trip relationship `tau = 2R/c` or `f_b = 2*S*R/c` into the active one-way A-to-B cross-link model.

For two cooperating stations A and B separated by distance d:

```
tau = d / c     (one-way propagation delay)
```

If a delay delta is applied to the V0 waveform, the recovered delay is:

```
delta_hat = f_hat / S
```

The factors of 2 that do legitimately appear in this project are in the **TWTT sum/difference solution**:

```
tau_hat   = (f_AB + f_BA) / (2*S)
theta_hat = (f_AB - f_BA) / (2*S)
```

These arise from averaging two independent one-way measurements, not from a round-trip doubling.

### A.11 Two-Way Sign Convention — Derivation from Explicit Clock Models

The effective delays `delta_AB` and `delta_BA` are **derived**, not asserted. The derivation proceeds from explicit local clock functions under the V0/V1 ideal assumptions (identical slopes, identical clock rates, zero frequency offset).

**Clock definitions:**

```
T_A(t) = t                 (Station A's local clock = physical time)
T_B(t) = t + theta          (Station B's local clock, offset by theta)
```

Positive `theta` means clock B reads ahead of clock A.

**A-to-B link:** Station A transmits. Station B receives the signal after one-way propagation delay `tau` and dechirps it against its own local chirp.

```
B's local reference:    s(T_B(t))       = s(t + theta)
Received A signal:      s(T_A(t - tau)) = s(t - tau)

z_AB(t) = s(T_B(t)) * conj(s(T_A(t - tau)))
        = s(t + theta) * conj(s(t - tau))
```

Expanding with `s(t) = exp(j*pi*S*t^2)`:

```
phi_z_AB(t) = pi*S*(t + theta)^2 - pi*S*(t - tau)^2
            = pi*S*[(t + theta)^2 - (t - tau)^2]
            = pi*S*[t^2 + 2*theta*t + theta^2 - t^2 + 2*tau*t - tau^2]
            = pi*S*[2*(tau + theta)*t + theta^2 - tau^2]
            = 2*pi*S*(tau + theta)*t + pi*S*(theta^2 - tau^2)
```

The beat frequency is `S*(tau + theta)`, corresponding to an effective delay:

```
delta_AB = tau + theta
```

**B-to-A link:** Station B transmits. Station A receives and dechirps against its own local chirp.

```
A's local reference:    s(T_A(t))       = s(t)
Received B signal:      s(T_B(t - tau)) = s(t - tau + theta)

z_BA(t) = s(T_A(t)) * conj(s(T_B(t - tau)))
        = s(t) * conj(s(t - tau + theta))
```

Expanding:

```
phi_z_BA(t) = pi*S*t^2 - pi*S*(t - tau + theta)^2
            = pi*S*[t^2 - (t - (tau - theta))^2]
            = 2*pi*S*(tau - theta)*t - pi*S*(tau - theta)^2
```

The beat frequency is `S*(tau - theta)`, corresponding to an effective delay:

```
delta_BA = tau - theta
```

**Recovery:**

```
f_AB = S * (tau + theta)
f_BA = S * (tau - theta)

tau_hat   = (f_AB + f_BA) / (2*S)
theta_hat = (f_AB - f_BA) / (2*S)
```

**Future extensibility:** Clock skew is introduced by generalizing the clock model to:

```
T_B(t) = t + theta + epsilon*t
```

where `epsilon` is the fractional clock-rate offset. This modifies the effective delay expressions without restructuring the simulator. This is deferred to V3.

---

## B. V0 — Single-Link Ideal Truth Model

### B.1 Inputs

| Parameter | Symbol | Default value |
|---|---|---|
| Chirp slope | S | `2.9982e13` Hz/s |
| Sample rate | Fs | `10e6` Hz |
| Number of samples | N | `256` |
| Injected one-way delay | delta | (test-dependent) |

### B.2 Processing Chain

V0 is implemented as a single call to `simulate_ideal_link` (see B.6), followed by estimation:

```
1. link = simulate_ideal_link(cfg, delta)
2. fb_fft   = estimate_beat_fft(link.beat, cfg.Fs)           % diagnostic
3. fb_phase = estimate_beat_phase_slope(link.beat, cfg.Fs)   % primary
4. delta_hat = fb_phase.f_est / cfg.S                        % recovered delay
```

### B.3 Outputs

| Output | Description | Variable |
|---|---|---|
| `link.t` | Time vector, length N | Column vector [s] |
| `link.tx` | Complex baseband TX chirp, length N | Column vector |
| `link.rx` | Complex baseband delayed RX chirp, length N | Column vector |
| `link.beat` | Dechirped signal z = tx .* conj(rx), length N | Column vector |
| `link.fb_theory` | Theoretical beat frequency S*delta | Scalar [Hz] |
| `link.delta` | Injected delay (echo of input) | Scalar [s] |
| `fb_fft` | FFT peak estimate (struct) | Struct |
| `fb_phase` | Phase-slope LS estimate (struct) | Struct |
| `delta_hat` | Recovered delay f_hat / S | Scalar [s] |

### B.4 Required Identity

In the noiseless ideal case:

```
delta_hat = f_hat / S = delta_injected
```

Tolerance: relative error < 1e-10 (see Section F.3 for full tolerance specification).

### B.5 Function Contracts

#### `fmcw_baseband(t, S)`
- **Input:** Time vector `t` [s], slope `S` [Hz/s].
- **Output:** Complex column vector `s = exp(j * pi * S * t.^2)`.
- **Invariant:** `abs(s) == 1` for all samples.

#### `fmcw_delayed_baseband(t, S, delta)`
- **Input:** Time vector `t` [s], slope `S` [Hz/s], delay `delta` [s].
- **Output:** Complex column vector `r = exp(j * pi * S * (t - delta).^2)`.
- **Invariant:** When `delta = 0`, output equals `fmcw_baseband(t, S)` exactly.

#### `dechirp_signal(tx, rx)`
- **Input:** Two complex column vectors of equal length.
- **Output:** `z = tx .* conj(rx)`.
- **Convention:** Local reference chirp times conjugate of received signal. Documented in a comment at the top of the function.
- **Invariant:** When `tx == rx`, output is all ones (zero beat).

#### `estimate_beat_fft(beat, Fs)`
- **Input:** Complex beat signal, sample rate.
- **Output:** Struct with fields:
  - `.f_peak` — frequency of the FFT magnitude peak [Hz]
  - `.spectrum_mag` — magnitude spectrum (for plotting)
  - `.freq_axis` — frequency axis [Hz]
  - `.df` — FFT bin spacing [Hz]
- **Not an authoritative estimator.** Used for visualization and coarse sanity checks only.
- Zero-padding, if applied, changes the displayed frequency grid but does not change the physical observation time or information content.

#### `estimate_beat_phase_slope(beat, Fs)`
- **Input:** Complex beat signal, sample rate.
- **Output:** Struct with fields:
  - `.f_est` — estimated beat frequency [Hz]
  - `.phi0` — estimated phase intercept [rad]
  - `.residual_rms` — RMS of phase-fit residual [rad]
- **Algorithm:**
  1. `phi = unwrap(angle(beat))`
  2. Fit `phi[n] = m * n + b` via least squares (using sample indices `n = 0:N-1`)
  3. `f_est = m * Fs / (2*pi)`
- **Invariant:** For a noise-free pure complex tone, `residual_rms < 1e-10` rad.

#### `solve_twtt(fAB, fBA, S)`
- **Input:** Two beat frequencies [Hz] and slope [Hz/s].
- **Output:** `[tau_hat, theta_hat]` — recovered propagation delay [s] and clock offset [s].
- **Implementation:**
  ```matlab
  tau_hat   = (fAB + fBA) / (2 * S);
  theta_hat = (fAB - fBA) / (2 * S);
  ```
- **No DSP inside this function.** It is pure algebra.
- **Sign convention:** Matches the derivation in A.11. Documented in function header.

#### `make_default_params()`
- **Output:** Struct `cfg` with fields:
  - `cfg.S` — chirp slope [Hz/s], default `2.9982e13`
  - `cfg.Fs` — sample rate [Hz], default `10e6`
  - `cfg.N` — number of samples, default `256`
  - `cfg.fc` — carrier frequency [Hz], default `77e9` (metadata only, not used in V0/V1 waveform)
  - `cfg.c` — speed of light [m/s], default `299792458`
- All values in SI. No TI-convention fields leak into the struct.
- `B`, `Tc`, and other AWR2944 profile parameters may be included as optional metadata fields for documentation and future use, but do not enter V0/V1 equations.

### B.6 Reusable Ideal-Link Function

#### `simulate_ideal_link(cfg, delta)`

**Purpose:** Single authoritative function that executes the complete V0 ideal-link signal chain. All V0 and V1 processing must use this function.

- **Input:** Configuration struct `cfg` (from `make_default_params`), delay `delta` [s].
- **Output:** Struct `link` with fields:
  - `.t` — time vector `(0:N-1)'/Fs` [s]
  - `.tx` — baseband TX chirp [complex column vector]
  - `.rx` — baseband delayed RX chirp [complex column vector]
  - `.beat` — dechirped beat signal [complex column vector]
  - `.fb_theory` — theoretical beat frequency `S * delta` [Hz]
  - `.delta` — injected delay (echo of input) [s]
  - `.cfg` — configuration struct (echo of input)

- **Internal implementation calls:**
  ```
  t    = (0:cfg.N-1).' / cfg.Fs;
  tx   = fmcw_baseband(t, cfg.S);
  rx   = fmcw_delayed_baseband(t, cfg.S, delta);
  beat = dechirp_signal(tx, rx);
  ```

- **Invariant:** V0 calls this function once. V1 calls this function exactly twice:
  ```
  link_AB = simulate_ideal_link(cfg, tau + theta);
  link_BA = simulate_ideal_link(cfg, tau - theta);
  ```
  No signal-chain logic is duplicated outside this function.

---

## C. V1 — Ideal Reciprocal Two-Way FMCW Timing

### C.1 Inputs

| Parameter | Symbol | Default value |
|---|---|---|
| One-way propagation delay | tau | `5e-9` s (5 ns) |
| Relative clock offset | theta | `100e-12` s (100 ps) |

Plus all V0 waveform parameters (same S, Fs, N via `cfg`).

### C.2 Processing Chain

```
1. delta_AB = tau + theta           % derived in A.11
2. delta_BA = tau - theta           % derived in A.11

3. link_AB = simulate_ideal_link(cfg, delta_AB)
4. link_BA = simulate_ideal_link(cfg, delta_BA)

5. fb_AB = estimate_beat_phase_slope(link_AB.beat, cfg.Fs).f_est
6. fb_BA = estimate_beat_phase_slope(link_BA.beat, cfg.Fs).f_est

7. [tau_hat, theta_hat] = solve_twtt(fb_AB, fb_BA, cfg.S)
```

Steps 3-4 call **the same `simulate_ideal_link` function** used by V0. V1 does not contain a separate dechirp or waveform implementation.

### C.3 Required Identities

In the noiseless ideal case:

```
tau_hat = tau_injected
theta_hat = theta_injected
```

Tolerance: absolute error < 1e-14 s (see Section F.3).

### C.4 What V1 Does NOT Do

- Does not model independent oscillators or carrier-frequency offset.
- Does not model clock skew (time-varying theta). The clock model is `T_B(t) = t + theta` with constant `theta`.
- Does not model different slopes at A and B.
- Does not inject noise.
- Does not use a separate implementation for the two directions — both call `simulate_ideal_link`.

---

## D. Numerical Demonstration

### D.1 Headline Parameters

| Parameter | Value | MATLAB |
|---|---|---|
| S | 29.982 MHz/us = 2.9982e13 Hz/s | `2.9982e13` |
| Fs | 10 MHz | `10e6` |
| N | 256 | `256` |
| Tobs | N/Fs = 25.6 us | derived |
| tau | 5 ns | `5e-9` |
| theta | 100 ps | `100e-12` |

### D.2 Derived Quantities (Independently Verified)

| Quantity | Formula | Value |
|---|---|---|
| Tobs | N / Fs | 25.6 us |
| FFT bin spacing (df) | Fs / N | **39,062.5 Hz** (39.0625 kHz) |
| S * tau | | 149,910.0 Hz (149.910 kHz) |
| S * theta | | 2,998.2 Hz (2.9982 kHz) |
| delta_AB | tau + theta | 5.1 ns |
| delta_BA | tau - theta | 4.9 ns |
| f_AB | S * delta_AB | **152,908.2 Hz** (152.9082 kHz) |
| f_BA | S * delta_BA | **146,911.8 Hz** (146.9118 kHz) |
| f_AB - f_BA | 2 * S * theta | 5,996.4 Hz (5.9964 kHz) |

These values were independently computed in Python and confirmed to match the prompt-provided values exactly.

### D.3 FFT Resolution Analysis

For N = 256 and Fs = 10 MHz, the nearest-bin FFT estimator maps both directional beat frequencies to the same raw DFT bin. Therefore, nearest-bin FFT estimates cannot recover the ~5,996.4 Hz AB/BA difference for the 100-ps headline case.

| Metric | Value |
|---|---|
| FFT bin spacing | 39,062.5 Hz |
| f_AB falls in DFT bin | 3.914 (between bins 3 and 4) |
| f_BA falls in DFT bin | 3.761 (between bins 3 and 4) |
| AB/BA separation | 0.154 bins |
| S*theta displacement from mean | 0.077 bins |

The A-to-B and B-to-A beats are obtained from **separate directional dechirp operations** (separate complex records). They do not need to be resolved in a single spectrum. However, the nearest-bin FFT estimate of each individual record has a precision of only `df/2 = 19.5 kHz`, which is far too coarse to measure a 3 kHz displacement.

The **phase-slope estimator** operates on each separate complex record and recovers the underlying off-bin sinusoidal frequency exactly in the ideal noise-free model.

Zero-padding changes the displayed frequency grid, not the physical observation time or information content. It does not improve the fundamental frequency precision of a nearest-bin estimator.

### D.4 Phase-Slope Estimator Feasibility

For f_AB = 152,908.2 Hz at Fs = 10 MHz:
- Phase increment per sample: `2*pi*f_AB/Fs = 0.09608` rad/sample
- Total accumulated phase over 256 samples: 24.60 rad = 3.91 cycles
- This is well within the regime where `unwrap(angle(...))` works reliably.

The LS fit of a perfectly linear phase gives f_hat to double-precision tolerance. The RMS residual should be at the level of floating-point roundoff.

### D.5 Demonstration Outputs

The demos must print a result table similar to:

```
====================================================
  V0 Single-Link Result
====================================================
  Injected delay (delta):      5.000000000 ns
  Theoretical f_b:             149910.000000 Hz
  Phase-slope estimate:        149910.000000 Hz
  FFT peak estimate:           156250.000000 Hz
  Recovered delay:             5.000000000 ns
  Delay error:                 0.000e+00 s
  FFT bin spacing:             39062.500 Hz
  NOTE: FFT peak != truth (nearest-bin limitation)
====================================================
```

```
====================================================
  V1 Two-Way Result
====================================================
  Injected tau:    5.000000000 ns
  Injected theta:  100.000000000 ps
  f_AB estimate:   152908.200000 Hz
  f_BA estimate:   146911.800000 Hz
  Recovered tau:   5.000000000 ns
  Recovered theta: 100.000000000 ps
  tau error:       0.000e+00 s
  theta error:     0.000e+00 s
  CONDITIONS: ideal, noise-free, matched clocks
====================================================
```

---

## E. Code Structure

```
10_SIMULATION_WORKSPACE/matlab/
|
|-- README.md                          % Setup, usage, assumptions
|-- run_all.m                          % Run all demos + tests sequentially
|
|-- scripts/
|   |-- demo_v0_single_link.m          % V0 demo: single link + Figures 1, 3
|   |-- demo_v1_two_way.m             % V1 demo: two-way  + Figures 2, 4
|
|-- src/
|   |-- make_default_params.m          % Config struct with SI defaults
|   |-- fmcw_baseband.m               % s(t) = exp(j*pi*S*t^2)
|   |-- fmcw_delayed_baseband.m       % r(t) = exp(j*pi*S*(t-delta)^2)
|   |-- dechirp_signal.m              % z = tx .* conj(rx)
|   |-- simulate_ideal_link.m         % Authoritative V0 link: waveform + delay + dechirp
|   |-- estimate_beat_fft.m           % FFT peak finder (diagnostic)
|   |-- estimate_beat_phase_slope.m   % LS phase-slope estimator (primary)
|   |-- solve_twtt.m                  % (fAB+fBA)/(2S), (fAB-fBA)/(2S)
|
|-- tests/
|   |-- test_v0_single_link.m         % Tests T01-T05
|   |-- test_v1_two_way.m            % Tests T06-T09
|   |-- test_fractional_delay.m       % Test T10
|   |-- test_sign_convention.m        % Tests T11-T12
|   |-- test_waveform_closedform.m    % Test T13
|   |-- run_all_tests.m              % Runner that reports pass/fail
|
|-- figures/                           % Generated .png/.fig outputs
|   |-- (generated at runtime)
|
|-- results/
    |-- saeed_morning_summary.md      % Generated PM-facing report
```

### E.1 Design Constraints

- **No classes.** Pure functions and structs.
- **No toolbox dependencies** beyond base MATLAB (specifically: no Signal Processing Toolbox, no Phased Array Toolbox required for V0/V1).
- **No globals or persistent state.** Every function receives its inputs explicitly.
- **No hidden unit conversions inside mathematical functions.** Only `make_default_params` converts units.
- **Column vectors throughout.** Time vectors, signal vectors, and phase vectors are all N-by-1.
- **Deterministic.** V0/V1 produce identical output on every run (no random seeds needed yet).
- **Single link API.** All waveform/delay/dechirp logic flows through `simulate_ideal_link`. Demo scripts and V1 do not duplicate this chain.

### E.2 `run_all.m` Behavior

```matlab
% run_all.m
% Runs all tests, then all demos. Fails loudly on test failure.
%
% Usage: >> run_all
%
% Exits cleanly only if all tests pass.

addpath('src');
addpath('tests');
addpath('scripts');

fprintf('=== Running Tests ===\n');
run_all_tests;

fprintf('\n=== Running Demos ===\n');
demo_v0_single_link;
demo_v1_two_way;

fprintf('\nAll done.\n');
```

---

## F. Tests

### F.1 Test Matrix

| ID | Test | Injected condition | Expected result |
|---|---|---|---|
| **T01** | Zero delay | delta = 0 | f_hat = 0, delta_hat = 0 |
| **T02** | Nanosecond delay | delta = 5 ns | f_hat = S*delta = 149,910 Hz |
| **T03** | Sub-bin delay | delta = 100 ps | f_hat = 2,998.2 Hz |
| **T04** | Picosecond delay | delta = 10 ps | f_hat = 299.82 Hz |
| **T05** | Half-sample delay | delta = 0.5/Fs = 50 ns | f_hat = S * 50e-9 |
| **T06** | V1 symmetric | tau = 5 ns, theta = 0 | f_AB = f_BA, theta_hat = 0 |
| **T07** | V1 headline | tau = 5 ns, theta = 100 ps | tau_hat = 5 ns, theta_hat = 100 ps |
| **T08** | V1 sign reversal | tau = 5 ns, theta = -100 ps | theta_hat = -100 ps |
| **T09** | V1 pure-offset algebra | tau = 0, theta = 100 ps | tau_hat = 0, theta_hat = 100 ps |
| **T10** | Fractional delay sweep | delta in {10 ps, 37 ps, 123.456 ps, 1.234 ns, 7.891 ns} | All recovered exactly |
| **T11** | Slope scaling | delta fixed, S -> 2*S | f_hat doubles |
| **T12** | Conjugation reversal | z = rx .* conj(tx) instead of tx .* conj(rx) | f_hat changes sign |
| **T13** | Closed-form waveform | delta = 5 ns | Simulated beat matches `exp(j*(2*pi*S*delta*t - pi*S*delta^2))` |

### F.2 Test Notes

**T09 (pure-offset algebra):** This test has `tau = 0` and `theta > 0`, which creates one negative effective delay (`delta_BA = -theta`). This is a **nonphysical algebra / sign-convention test** of `solve_twtt`. It verifies that the sum/difference algebra handles the `tau = 0` edge case correctly. It does not represent a physically realizable link configuration.

All waveform-level reciprocal-link tests (T06, T07, T08) use `tau > |theta|` so that both effective link delays remain physically positive.

### F.3 Tolerance Specification

| Quantity | Tolerance type | Value | Rationale |
|---|---|---|---|
| Beat frequency (f_hat vs S*delta, delta > 0) | Relative | `abs(f_hat - S*delta) / (S*delta) < 1e-10` | ~4 orders above IEEE 754 double eps; catches algorithm errors while allowing floating-point roundoff |
| Beat frequency (delta = 0) | Absolute | `abs(f_hat) < 1e-6 Hz` | No meaningful relative tolerance at zero |
| Propagation delay (tau_hat) | Absolute | `abs(tau_hat - tau) < 1e-14 s` | Sub-femtosecond; well within double-precision arithmetic for ns-scale values |
| Clock offset (theta_hat) | Absolute | `abs(theta_hat - theta) < 1e-14 s` | Same as tau |
| Complex waveform agreement (T13) | Per-sample absolute | `max(abs(z_sim - z_expected)) < 1e-10` | Unit-amplitude signals; 1e-10 is ~8 orders above double eps |
| Phase-fit residual (noise-free) | Absolute | `residual_rms < 1e-10 rad` | Pure complex tone should have zero-residual LS fit |
| Conjugation reversal (T12) | Absolute | `abs(f_swap + f_normal) < 1e-6 Hz` | Sign flip should be exact to roundoff |

Do not loosen any tolerance after seeing a test fail without first diagnosing the root cause.

### F.4 Test Mechanics

- Each test file is a function that runs silently on success and throws an error on failure.
- `run_all_tests.m` calls every test function, counts pass/fail, and prints a summary.
- Tests do **not** produce figures. Demos produce figures.
- Tests use `assert(...)` or equivalent with descriptive error messages that include the actual and expected values.

### F.5 What Tests Do NOT Cover (Deferred)

- Noise robustness (deferred to V2)
- Amplitude variations (deferred to V2)
- Initial phase invariance (deferred to V3, trivially true for frequency estimation but formally tested after phi_0 parameter is added)
- Negative slope / down-chirp (deferred to V2)
- Multiple estimator comparison under noise (deferred to V3)

---

## G. Figures

### Figure 1 — FMCW Delay-to-Frequency Conversion

**File:** `figures/fig01_v0_single_link.png`

**Layout:** Two vertically stacked subplots.

**Top subplot — Chirp geometry:**
- X-axis: time [us]
- Y-axis: instantaneous baseband frequency [kHz]
- Plot the TX chirp frequency `f_TX(t) = S*t` and the delayed RX chirp frequency `f_RX(t) = S*(t - delta)`
- Annotate the vertical frequency gap `S*delta` with an arrow and label
- Title: "FMCW Delay to Frequency: delta = X ns, S = Y MHz/us"

**Bottom subplot — Beat spectrum:**
- X-axis: frequency [kHz]
- Y-axis: magnitude [dB] (normalized to peak)
- Plot `|FFT(beat)|` in dB
- Mark with a vertical dashed line: theoretical f_b = S*delta
- Mark with a marker: FFT peak estimate
- Mark with a different marker: phase-slope estimate
- Text annotation box:
  - Injected delay: X ns
  - Theoretical f_b: Y kHz
  - Phase-slope f_hat: Z kHz
  - Recovered delta_hat: W ns
  - FFT bin spacing: V kHz
- Label: "IDEAL — noise-free, matched oscillators"

### Figure 2 — Two-Way FMCW / TWTT

**File:** `figures/fig02_v1_two_way.png`

**Layout:** Two subplots side by side (or stacked).

**Left/Top — Two beat spectra:**
- Overlay or vertically offset the A-to-B and B-to-A beat spectra
- Mark f_AB and f_BA with distinct colors/markers
- Annotate the mean (f_AB + f_BA)/2 and half-difference (f_AB - f_BA)/2

**Right/Bottom — Recovery summary:**
- Text/equation box showing:
  - tau_hat = (f_AB + f_BA) / (2*S)
  - theta_hat = (f_AB - f_BA) / (2*S)
  - Injected: tau = X ns, theta = Y ps
  - Recovered: tau_hat = X ns, theta_hat = Y ps
  - tau error: ... s
  - theta error: ... s
- Label: "IDEAL — noise-free, matched oscillators, reciprocal path"

### Figure 3 (Optional) — Delay Linearity Sweep

**File:** `figures/fig03_delay_linearity.png`

- Sweep delta over a range (e.g., 10 ps to 100 ns, log-spaced, ~20 points)
- X-axis: injected delay [ns] (log scale)
- Y-axis: estimated f_hat [kHz]
- Overlay: theoretical line f = S*delta
- Residual subplot: f_hat - S*delta vs delta (should be ~zero everywhere)
- Label: "IDEAL — phase-slope estimator, noise-free"

### Figure 4 (Optional) — Clock-Offset Recovery Sweep

**File:** `figures/fig04_theta_recovery.png`

- Fix tau = 5 ns
- Sweep theta over [-1 ns, +1 ns] with specific markers at +/-10 ps, +/-100 ps, +/-1 ns
- X-axis: injected theta [ps]
- Y-axis: recovered theta_hat [ps]
- Overlay: 45-degree identity line
- Residual subplot: theta_hat - theta [ps] (should be ~zero)
- Label: "IDEAL — noise-free, matched oscillators"

### Figure Style Requirements

- All figures: white background, publication-quality fonts, labeled axes with units.
- All figures: must state "IDEAL — noise-free" prominently.
- Any picosecond-level result must be explicitly labeled IDEAL / NOISE-FREE unless an impairment model has actually been enabled.
- Font size: >= 10pt for axis labels, >= 8pt for annotations.
- Saved as `.png` at >= 300 DPI and optionally `.fig` for MATLAB re-editing.

---

## H. Morning Deliverable

### File: `results/saeed_morning_summary.md`

Generated by `demo_v1_two_way.m` (or a wrapper). Contains:

**Section 1 — Objective** (~1 paragraph): Demonstrate that FMCW dechirping converts sub-nanosecond propagation delay and picosecond clock offset into easily estimated low-frequency beats, and that two-way sum/difference algebra recovers both quantities exactly under ideal conditions.

**Section 2 — V0 Single-Link Result:** Injected delay, theoretical f_b, estimated f_b, recovered delay, error.

**Section 3 — V1 Two-Way Result:** Injected tau and theta, f_AB and f_BA, recovered tau and theta, errors.

**Section 4 — Model Assumptions:** Exhaustive list of ideal conditions (identical slopes, zero CFO, zero phase noise, zero clock skew, etc.).

**Section 5 — Numerical Parameters:** S, Fs, N, Tobs, FFT bin spacing.

**Section 6 — Equations:** f_b = S*delta, delta_AB = tau + theta, delta_BA = tau - theta, tau_hat = (f_AB + f_BA)/(2*S), theta_hat = (f_AB - f_BA)/(2*S).

**Section 7 — Figures:** Repository-relative paths to generated figures.

**Section 8 — Next Steps:** (1) Add AWGN to quantify estimator precision vs SNR; (2) Introduce independent carrier-frequency offset; (3) Compare FFT / phase-slope / CZT estimators under noise; (4) Map AWR2944 chirp parameters to simulation config; (5) Characterize hardware with second AWR2944 board.

**Section 9 — Disclaimer:** "These results are from an IDEAL, NOISE-FREE simulation. They demonstrate mathematical correctness of the FMCW timing model, NOT achievable hardware performance. 10-ps accuracy on real AWR2944 hardware has NOT been demonstrated and requires additional modeling and measurement."

---

## I. Future Extensibility

The following insertion points are documented here so the V0/V1 code can be extended without restructuring. **None are implemented in V0/V1.**

Version labels below follow the project-wide numbering established in the Master Index (see `_SOURCE_DOCUMENTS_LATEX/MASTER_INDEX.tex`, Section 2) and the Simulation Blueprint (see `_SOURCE_DOCUMENTS_LATEX/AWR2944_FMCW_TWTT_MATLAB_Simulation_Blueprint.tex`).

### V2 — Additive Noise and Basic Receiver Effects

| Feature | Insertion point | Implementation sketch |
|---|---|---|
| AWGN / SNR | Add after `dechirp_signal`, before estimation | `beat = beat + noise_vector` where `noise_vector` is complex Gaussian at specified post-dechirp SNR |
| ADC quantization | Add after AWGN, before estimation | Quantize real/imag parts to N_b bits with specified full-scale |
| Monte Carlo | Wrapper around V0/V1 chain | Loop over random seeds, collect estimates, compute bias/std/RMSE |

New files: `src/add_awgn.m`, `src/quantize_adc.m`, `scripts/demo_v2_monte_carlo.m`
New tests: `test_awgn_zero.m` (SNR=Inf reproduces V0 exactly), `test_variance_vs_snr.m`

### V3 — Independent Oscillator Effects

| Feature | Insertion point | Implementation sketch |
|---|---|---|
| Carrier-frequency offset Df | Multiply received signal by `exp(j*2*pi*Df*t)` before dechirp | Beat frequency shifts by Df; use up/down slopes to separate |
| Clock skew epsilon | Replace `T_B(t) = t + theta` with `T_B(t) = t + theta + epsilon*t` | Effective delay becomes time-varying; beat drifts |
| Slope mismatch dS | Use different S in `fmcw_delayed_baseband` | Beat becomes chirped (not pure tone); estimator bias |
| Initial phase phi_0 | Add to chirp phase argument | Should not affect frequency estimation (test this) |

New files: `src/apply_cfo.m`, `src/apply_clock_skew.m`
New tests: `test_cfo_up_down.m`, `test_slope_mismatch_chirp.m`

### V4 — Colored Phase Noise and Ramp Distortion

| Feature | Insertion point | Implementation sketch |
|---|---|---|
| Colored phase noise | Add phi_PN(t) to chirp phase before `exp(j*...)` | Generate from PSD via spectral shaping of white Gaussian process |
| Systematic ramp distortion | Add phi_sys(t) to chirp phase | Polynomial, sinusoidal, or measured error profile |
| PLL/synthesizer settling | Modify chirp phase near ramp boundaries | Model loop bandwidth / settling time |
| Correlated vs. independent PN | Common + uncorrelated decomposition | phi_A = phi_c + phi_Au, phi_B = phi_c + phi_Bu |

New files: `src/generate_phase_noise.m`, `src/apply_ramp_distortion.m`
New tests: `test_pn_zero.m`, `test_pn_correlation.m`

### V5 — Channel and Hardware Effects

| Feature | Insertion point | Implementation sketch |
|---|---|---|
| Multipath | Sum of delayed/scaled copies in channel | `r = sum(alpha_l * fmcw_delayed_baseband(t, S, tau_l))` |
| TX/RX group delay asymmetry | Per-station constant delays added to effective delta | delta_AB = tau + theta + g_A_TX + g_B_RX |
| IF filter | Apply transfer function to beat signal | `beat = ifft(fft(beat) .* H_IF)` |
| Calibration | Compensate known fixed delays in `solve_twtt` | Subtract calibrated offsets before solving |

New files: `src/multipath_channel.m`, `src/apply_group_delay.m`, `src/apply_if_filter.m`

### V6 — Coded FMCW

| Feature | Insertion point | Implementation sketch |
|---|---|---|
| Phase code overlay | Multiply chirp by `exp(j * phi_code(t))` | Code-chip duration, sequence design, cross-correlation |
| Code-delay misalignment | Delayed code != local code after dechirp | Requires alignment/correlation processing |
| Multi-node identity | Different code per station | Correlation-based station identification |

New files: `src/apply_phase_code.m`, `src/decode_phase_code.m`

**Do not implement V6 before V1 tests pass.** Code-delay misalignment effects are subtle and can silently bias timing estimates if the baseline algebra is not validated first.

---

## Resolved Questions

### Q1: Code location — RESOLVED

Code lives under `10_SIMULATION_WORKSPACE/matlab/`, consistent with the existing repository convention and the `README_NEXT_STEP.md` in that directory.

### Q2: Observation duration vs. chirp duration — RESOLVED

`Tobs = N / Fs` is the sampled observation window (25.6 us for headline parameters). It is **not** equated with the physical chirp duration `Tc`. The V0/V1 model requires only `S`, `Fs`, `N`, and the injected delay `delta`. Physical ramp parameters (`Tc`, `B`, ADC start time) are deferred to AWR2944 profile mapping.

---

## Remaining Blockers

None. All conventions, sign derivations, function contracts, tolerances, and structural decisions are fully specified.

**V0/V1 specification is ready for implementation approval.**
