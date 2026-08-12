# CFO and Phase-Coded FMCW Implementation Specification

**Status:** DRAFT — awaiting approval before any code is written.
**Scope:** Carrier-frequency offset / presynchronization (V2a) and ideal orthogonal phase-coded FMCW (V2b).
**Repository:** `fmcw-twtt`
**Baseline:** V0/V1 frozen at commit `ed26760`, validated by audit report `docs/V0_V1_AUDIT_REPORT.md`.
**Date:** 2026-08-12

---

## Source Traceability

Every derivation below traces to one or more of the following binding references:

| Label | Source | Location |
|---|---|---|
| **SPEC** | V0/V1 Implementation Specification | `docs/V0_V1_IMPLEMENTATION_SPEC.md` |
| **HANDBOOK** | FMCW/TWTT Mathematical Handbook | `08_EQUATION_HANDBOOK/FMCW_TWTT_Mathematical_Handbook.pdf` |
| **BLUEPRINT** | AWR2944 FMCW/TWTT MATLAB Simulation Blueprint | `00_START_HERE/AWR2944_FMCW_TWTT_MATLAB_Simulation_Blueprint.pdf` |
| **LIT-REVIEW** | FMCW/TWTT Literature and Prior Art Review | `00_START_HERE/FMCW_TWTT_Literature_and_Prior_Art_Review.pdf` |
| **ROEHR-2007** | Roehr/Vossiek/Gulden, "Method for High Precision Radar Distance Measurement and Synchronization" | `09_RESTRICTED.../2007_Roehr_High_Precision_Radar_Distance_Synchronization.pdf` |
| **GOTTINGER-2019** | Gottinger et al., "Coherent Full-Duplex Double-Sided Two-Way Ranging" (CFDDS-TWR) | `09_RESTRICTED.../2019_Gottinger_CFDDS_TWR.pdf` |
| **GOTTINGER-2021** | Gottinger et al., "Coherent Automotive Radar Networks" | `09_RESTRICTED.../2021_Gottinger_Coherent_Automotive_Radar_Networks.pdf` |
| **UYSAL-2020a** | Uysal, "Phase-Coded FMCW System Design and Interference Mitigation" | `04_CODED.../2020_Uysal_Phase_Coded_FMCW_System_Design_Interference_Mitigation.pdf` |
| **UYSAL-2020b** | Uysal & Orru, "Phase-Coded FMCW Application and Challenges" | `04_CODED.../2020_Uysal_Orru_Phase_Coded_FMCW_Application_and_Challenges.pdf` |
| **LAMPEL-2020** | Lampel et al., "System Level Synchronization of Phase-Coded FMCW RadCom" | `09_RESTRICTED.../2020_Lampel_System_Level_Synchronization_Phase_Coded_FMCW_RadCom.pdf` |
| **KUMBUL-2022** | Kumbul et al., "Smoothed Phase-Coded FMCW" | `04_CODED.../phase_coded_FMCW/2022_Kumbul_Smoothed_Phase_Coded_FMCW.pdf` |
| **TI-CHIRP** | TI, "Programming Chirp Parameters" | `06_TI.../chirp_config_calibration_and_MIMO/TI_Programming_Chirp_Parameters.pdf` |
| **TI-MIMO** | TI, "MIMO Radar" | `06_TI.../chirp_config_calibration_and_MIMO/TI_MIMO_Radar.pdf` |
| **TI-TRM** | TI, "AWR294x Technical Reference Manual RevD" | `06_TI.../AWR2944/TI_AWR294x_Technical_Reference_Manual_RevD.pdf` |
| **TI-CASCADE** | TI, "Cascade Coherency Phase Shifter Calibration" | `06_TI.../chirp_config_calibration_and_MIMO/TI_Cascade_Coherency_Phase_Shifter_Calibration.pdf` |

---

## Explicit Out-of-Scope Items

The following are **not** modeled in V2a or V2b:

- AWGN / receiver noise (V2-noise, future)
- Clock skew / time-varying theta (V3)
- Chirp slope mismatch between stations (V3)
- Phase noise — colored or white (V4)
- Chirp nonlinearity / ramp distortion (V5)
- IF filter / group delay asymmetry (V5)
- ADC quantization / clipping (V5)
- Multipath (V5)
- Hardware calibration (V5)
- Doppler / moving nodes (V5)
- Multi-chirp coherent integration (V5)
- CZT estimator (deferred)

---

## Part A — Carrier-Frequency Offset Model

### A.1 Station-Specific Phase Model

Each station generates its own baseband chirp from its own local oscillator. In full RF, the phase of station X's transmitted signal is:

```
phi_X(t) = 2*pi*f_X * T_X(t) + pi*S * T_X(t)^2
```

where `f_X` is station X's carrier frequency and `T_X(t)` is X's local clock mapping. For V2a, retain the V0/V1 ideal clock model:

```
T_A(t) = t               (Station A = reference)
T_B(t) = t + theta        (Station B offset by theta)
```

No clock skew (epsilon = 0). No phase noise. Identical chirp slope S at both stations.

### A.2 Carrier-Frequency Offset Convention

Define the **carrier-frequency offset** as:

```
Delta_f = f_B - f_A
```

Positive `Delta_f` means station B's carrier frequency is higher than station A's.

In V0/V1, `Delta_f = 0` and the carrier frequency was suppressed entirely (pure complex-baseband model). In V2a, `Delta_f` enters as a new physical parameter. It represents the static RF frequency difference between the two stations' local oscillators.

### A.3 A→B Beat Phase Derivation

Station A transmits. Station B receives the signal after one-way propagation delay `tau` and dechirps it against B's own local reference chirp.

**B's local reference phase (full RF):**
```
phi_B_LO(t) = 2*pi*f_B * T_B(t) + pi*S * T_B(t)^2
            = 2*pi*f_B*(t + theta) + pi*S*(t + theta)^2
```

**Received A signal phase at station B (full RF):**
```
phi_A_RX(t) = 2*pi*f_A * T_A(t - tau) + pi*S * T_A(t - tau)^2
            = 2*pi*f_A*(t - tau) + pi*S*(t - tau)^2
```

**Dechirped beat phase** using the project convention `z = LO * conj(RX)`:
```
Phi_AB(t) = phi_B_LO(t) - phi_A_RX(t)
          = 2*pi*f_B*(t + theta) + pi*S*(t + theta)^2
            - 2*pi*f_A*(t - tau) - pi*S*(t - tau)^2
```

Separate the carrier terms and chirp terms:

**Carrier contribution:**
```
2*pi*f_B*(t + theta) - 2*pi*f_A*(t - tau)
= 2*pi*(f_B - f_A)*t + 2*pi*f_B*theta + 2*pi*f_A*tau
= 2*pi*Delta_f*t + 2*pi*(f_B*theta + f_A*tau)
```

**Chirp contribution (identical to V0/V1 derivation):**
```
pi*S*(t + theta)^2 - pi*S*(t - tau)^2
= 2*pi*S*(tau + theta)*t + pi*S*(theta^2 - tau^2)
```

**Combined linear-in-t term (beat frequency):**
```
f_AB = (1/(2*pi)) * d(Phi_AB)/dt = Delta_f + S*(tau + theta)
```

Therefore:
```
┌────────────────────────────────────────┐
│  f_AB = S*(tau + theta) + Delta_f      │
└────────────────────────────────────────┘
```

### A.4 B→A Beat Phase Derivation

Station B transmits. Station A receives and dechirps against A's own local reference.

**A's local reference phase:**
```
phi_A_LO(t) = 2*pi*f_A * T_A(t) + pi*S * T_A(t)^2
            = 2*pi*f_A*t + pi*S*t^2
```

**Received B signal phase at station A:**
```
phi_B_RX(t) = 2*pi*f_B * T_B(t - tau) + pi*S * T_B(t - tau)^2
            = 2*pi*f_B*(t - tau + theta) + pi*S*(t - tau + theta)^2
```

**Dechirped beat phase** `z = LO * conj(RX)`:
```
Phi_BA(t) = phi_A_LO(t) - phi_B_RX(t)
          = 2*pi*f_A*t + pi*S*t^2
            - 2*pi*f_B*(t - tau + theta) - pi*S*(t - tau + theta)^2
```

**Carrier contribution:**
```
2*pi*f_A*t - 2*pi*f_B*(t - tau + theta)
= -2*pi*Delta_f*t + 2*pi*f_B*(tau - theta)
```

**Chirp contribution:**
```
pi*S*t^2 - pi*S*(t - (tau - theta))^2
= 2*pi*S*(tau - theta)*t - pi*S*(tau - theta)^2
```

**Combined beat frequency:**
```
f_BA = S*(tau - theta) - Delta_f
```

Therefore:
```
┌────────────────────────────────────────┐
│  f_BA = S*(tau - theta) - Delta_f      │
└────────────────────────────────────────┘
```

### A.5 Summary: Signed Beat Frequencies Under Project Convention

Under the project's `z = LO * conj(RX)` mixer convention with positive slope S > 0:

```
f_AB = S*(tau + theta) + Delta_f
f_BA = S*(tau - theta) - Delta_f
```

**Sign structure:** `Delta_f` enters with **opposite signs** in the two directions. This is the key that enables separation.

### A.6 Two-Way Recovery Algebra Under CFO

**Sum:**
```
f_AB + f_BA = S*(tau + theta) + Delta_f + S*(tau - theta) - Delta_f
            = 2*S*tau
```

The `Delta_f` terms cancel exactly. The `theta` terms also cancel.

```
┌──────────────────────────────────────────────────┐
│  tau_hat = (f_AB + f_BA) / (2*S)                 │
│                                                  │
│  Propagation delay is UNCONTAMINATED by CFO.     │
└──────────────────────────────────────────────────┘
```

**Difference:**
```
f_AB - f_BA = S*(tau + theta) + Delta_f - S*(tau - theta) + Delta_f
            = 2*S*theta + 2*Delta_f
```

```
┌──────────────────────────────────────────────────┐
│  (f_AB - f_BA) / (2*S) = theta + Delta_f / S    │
│                                                  │
│  Clock offset IS contaminated by CFO.            │
│  The naive V1 solver interprets Delta_f/S as     │
│  fictitious clock offset.                        │
└──────────────────────────────────────────────────┘
```

### A.7 Bias of the Existing V1 Solver Under Uncompensated CFO

If the existing `solve_twtt(fAB, fBA, S)` is applied without CFO correction:

```
tau_hat   = tau                    (correct — unbiased)
theta_hat = theta + Delta_f / S    (BIASED by Delta_f / S)
```

The timing bias from CFO is:

```
bias_theta = Delta_f / S    [seconds]
```

For the nominal slope S = 2.9982e13 Hz/s:

| Delta_f | bias_theta | Equivalent |
|---|---|---|
| 10 Hz | 0.3335 ps | Sub-ps |
| 100 Hz | 3.335 ps | ps-class |
| **299.82 Hz** | **10.000 ps** | **10-ps target (frozen key result)** |
| 300 Hz | 10.006 ps | ps-class |
| 1 kHz | 33.353 ps | Tens of ps |
| 3 kHz | 100.060 ps | Sub-ns |
| 10 kHz | 333.533 ps | Sub-ns |
| 30 kHz | 1.0006 ns | ns-class |
| 100 kHz | 3.3353 ns | ns-class |
| 300 kHz | 10.006 ns | Tens of ns |
| 1 MHz | 33.353 ns | Tens of ns |
| 10 MHz | 333.53 ns | Sub-us |

**Frozen key result:** 299.82 Hz residual CFO produces 10 ps equivalent epoch-offset bias under S = 2.9982e13 Hz/s.

**Key insight:** For a 10-ps timing objective, CFO must be known/compensated to better than ~300 Hz. Two independent crystal oscillators with ppm-class accuracy at 77 GHz produce MHz-class CFO, which creates nanosecond-to-microsecond timing bias. **CFO compensation is mandatory for meaningful clock-offset recovery.**

**Propagation delay** `tau` is always unbiased by static CFO under same-slope reciprocal measurements.

### A.8 Up/Down-Chirp CFO/Delay Separation (Roehr Lineage)

The Roehr 2007 approach uses **two slope directions** from a single directional observation. For a single A→B link with up-chirp (slope +S) and down-chirp (slope -S):

```
f_up   = S*(tau + theta) + Delta_f       (same as f_AB with +S)
f_down = -S*(tau + theta) + Delta_f      (same structure with -S)
```

Note: `f_down` uses slope `-S`, so the chirp-dependent term changes sign while `Delta_f` does not.

**Sum (CFO recovery):**
```
f_up + f_down = 2*Delta_f

Delta_f_hat = (f_up + f_down) / 2
```

**Difference (delay recovery):**
```
f_up - f_down = 2*S*(tau + theta)

(tau + theta)_hat = (f_up - f_down) / (2*S)
```

These are consistent with the Roehr/Vossiek/Gulden 2007 structure and with HANDBOOK Section 7 equations:

```
f_+ = Delta_f + S*tau
f_- = Delta_f - S*tau
Delta_f = (f_+ + f_-) / 2
tau     = (f_+ - f_-) / (2*S)
```

(The handbook uses simplified notation without `theta`; our derivation includes it.)

### A.9 Identifiability Analysis

**Question:** Can same-slope reciprocal measurements alone identify all three of `tau`, `theta`, and `Delta_f`?

From Section A.6:
```
f_AB + f_BA = 2*S*tau             → recovers tau
f_AB - f_BA = 2*S*theta + 2*Delta_f   → recovers (theta + Delta_f/S)
```

This is a system of **2 equations in 3 unknowns**. Same-slope reciprocal measurements cannot independently identify `theta` and `Delta_f`. They are aliased into a single observable `theta_eff = theta + Delta_f/S`.

**Resolution options:**
1. **Up/down chirps** (Roehr method): provides a third equation, fully resolves `Delta_f`.
2. **Calibration tone** (Saeed proposal): separate measurement of `Delta_f` before FMCW operation.
3. **External presynchronization**: reduce `Delta_f` below the bias tolerance.

### A.10 Implementation: CFO-Aware Link Simulation

Two implementations exist:

**Authoritative model** (`simulate_cfo_link_phased`): Constructs the analytic beat phase directly from station-specific phase functions. The beat signals are:

```
z_AB(t) = exp(j * (2*pi * f_AB * t + phi0_AB))
z_BA(t) = exp(j * (2*pi * f_BA * t + phi0_BA))
```

where `f_AB`, `f_BA` are the derived beat frequencies from A.5, and `phi0_AB`, `phi0_BA` are the constant phase terms:

```
phi0_AB = 2*pi*(f_B*theta + f_A*tau) + pi*S*(theta^2 - tau^2)
phi0_BA = 2*pi*f_B*(tau - theta) - pi*S*(tau - theta)^2
```

with `f_A = fc` (77 GHz nominal), `f_B = f_A + Delta_f`.

This is a carrier-referenced algebraic equivalent: it computes the exact analytic phase difference without constructing a sampled 77-GHz waveform. The constant phase terms are preserved for documentation completeness but do not affect the phase-slope frequency estimator.

**Post-hoc oracle** (`simulate_cfo_link`): Reuses V0/V1 `simulate_ideal_link` and applies CFO as a post-dechirp frequency shift:

```
link_AB = simulate_ideal_link(cfg, tau + theta);
beat_AB = link_AB.beat .* exp(j * 2*pi * Delta_f * t);  % +Delta_f for A->B

link_BA = simulate_ideal_link(cfg, tau - theta);
beat_BA = link_BA.beat .* exp(-j * 2*pi * Delta_f * t); % -Delta_f for B->A
```

The post-hoc approach produces identical beat frequencies because the V0/V1 beat phase is `2*pi*S*delta*t - pi*S*delta^2`, and adding `2*pi*Delta_f*t` yields `2*pi*(S*delta + Delta_f)*t + const` = `2*pi*f_AB*t + const`. Setting `Delta_f = 0` recovers V1 exactly.

Both implementations are cross-validated by `test_cfo_phased_oracle`.

---

## Part B — Calibration-Tone Presynchronization

### B.1 Physical Scenario

Before the FMCW exchange, one station (say A) broadcasts a **constant-frequency CW reference tone** at its carrier frequency `f_A` for a known duration `T_cal`.

Station B receives this tone and mixes it against its own local oscillator at `f_B`.

### B.2 Received Signal Model

**A transmits CW:** `s_cal(t) = exp(j * 2*pi * f_A * t)` (ignoring amplitude)

**B receives after delay tau:** `r_cal(t) = s_cal(t - tau) = exp(j * 2*pi * f_A * (t - tau))`

**B's LO:** `lo_B(t) = exp(j * 2*pi * f_B * (t + theta))` (using B's clock)

**Mixed signal (LO * conj(RX)):**
```
z_cal(t) = lo_B(t) * conj(r_cal(t))
         = exp(j * 2*pi * [f_B*(t + theta) - f_A*(t - tau)])
         = exp(j * 2*pi * [Delta_f * t + f_B*theta + f_A*tau])
```

The calibration beat is a **pure tone at frequency `Delta_f`** (plus a constant phase offset).

### B.3 CFO Estimation from Calibration Tone

Apply the same phase-slope estimator used in V0/V1:

```
Delta_f_hat = estimate_beat_phase_slope(z_cal, Fs).f_est
```

The constant phase `2*pi*(f_B*theta + f_A*tau)` does not affect the frequency estimate.

**Critical distinction:** The calibration tone measures `Delta_f` = static RF carrier-frequency offset. It does **not** measure:
- Reference-clock fractional-rate error `epsilon` (would appear as a slowly drifting `Delta_f(t)`)
- Clock epoch offset `theta` (appears only in constant phase, not frequency)
- ADC sample-rate error (would rescale the digital time axis)
- Chirp slope mismatch (not present during CW)

For V2a, we isolate **static RF CFO only**. All other offset mechanisms are out of scope.

### B.4 CFO Correction Procedure

After estimating `Delta_f_hat` from the calibration tone:

1. Apply CFO correction to the FMCW beat signals:
```
beat_AB_corrected = beat_AB .* exp(-j * 2*pi * Delta_f_hat * t);
beat_BA_corrected = beat_BA .* exp(+j * 2*pi * Delta_f_hat * t);
```

2. Estimate corrected beat frequencies:
```
f_AB_corrected = estimate_beat_phase_slope(beat_AB_corrected, Fs).f_est
f_BA_corrected = estimate_beat_phase_slope(beat_BA_corrected, Fs).f_est
```

3. Apply the existing V1 TWTT solver:
```
[tau_hat, theta_hat] = solve_twtt(f_AB_corrected, f_BA_corrected, S);
```

### B.5 Residual-CFO Timing Bias Table

If the calibration tone estimates `Delta_f` with residual error `epsilon_f = Delta_f - Delta_f_hat`, the corrected theta estimate has bias:

```
bias_theta = epsilon_f / S
```

For S = 2.9982e13 Hz/s = 29.982 MHz/us:

| Residual CFO (epsilon_f) | Timing bias | Assessment |
|---|---|---|
| 10 Hz | 0.3335 ps | Sub-ps |
| 100 Hz | 3.335 ps | ps-class |
| **299.82 Hz** | **10.000 ps** | **10-ps target (frozen key result)** |
| 300 Hz | 10.006 ps | ps-class |
| 1 kHz | 33.353 ps | Tens of ps — acceptable for 10-ps goal |
| 3 kHz | 100.060 ps | Sub-ns |
| 10 kHz | 333.533 ps | Sub-ns — marginally acceptable |

**These are simplified-model equivalences**, not measured AWR2944 performance. Actual calibration-tone accuracy depends on SNR, observation duration, tone stability, and multipath.

### B.6 Three-Way Comparison Specification

The V2a demo must independently compare:

**Method A — No CFO correction:**
- Apply V1 solver directly to CFO-contaminated beats.
- Expected: `tau_hat` correct, `theta_hat` biased by `Delta_f / S`.

**Method B — Calibration-tone correction:**
- Generate calibration tone, estimate `Delta_f_hat`, correct beats, then V1 solver.
- Expected: `tau_hat` and `theta_hat` both correct to numerical tolerance.

**Method C — Up/down FMCW CFO estimation:**
- Generate up-chirp and down-chirp A→B observations.
- `Delta_f_hat = (f_up + f_down) / 2`
- `delta_AB_hat = (f_up - f_down) / (2*S)`
- Expected: recovers `Delta_f` and effective delay independently.

**Do not assume Methods B and C are mathematically identical.** They use different observables:
- Method B measures `Delta_f` from a separate CW observation.
- Method C measures `Delta_f` from the frequency-domain structure of two chirp slopes.

In the ideal noise-free model they should produce identical `Delta_f` estimates. Under noise or nonidealities they may differ. The comparison is important for understanding which approach is more robust.

---

## Part C — Ideal Orthogonal Phase Coding

### C.1 Coded Chirp Definition

A coded chirp for station `i` is:

```
s_i(t) = s_FMCW(t) * c_i(t)
```

where `s_FMCW(t) = exp(j * pi * S * t^2)` is the common baseband chirp and

```
c_i(t) = exp(j * phi_c_i(t))
```

is the unit-modulus phase code for station `i`.

### C.2 Binary Phase Coding

For the initial demonstration, use **binary phase coding**:

```
c_i(t) in {-1, +1}
phi_c_i(t) in {0, pi}
```

The code value is constant over each **chip interval** of duration `T_chip`.

### C.3 Code Selection: Walsh-Hadamard Length 2

For the first aligned demonstration, use the **simplest deterministic orthogonal code pair** — the length-2 Walsh-Hadamard codes:

```
Code A = [+1, +1]    (all same)
Code B = [+1, -1]    (alternating)
```

**Why this choice:**
- Perfectly orthogonal: `sum(A .* B) = 0`.
- Requires no toolbox (just sign arrays).
- Length 2 allows clean division of the observation window into 2 chips.
- Pedagogically transparent.

**This is NOT claimed to be hardware-optimal.** Real deployments would use longer PN, Gold, or Zadoff-Chu sequences. This choice is sufficient for the first conceptual demonstration of coded node identification.

### C.4 Chip Timing

The observation window `Tobs = N/Fs` is divided into `L` equal chips:

```
T_chip = Tobs / L
N_chip = N / L        (samples per chip, must be integer)
```

For L = 2 and N = 256: `N_chip = 128`, `T_chip = 12.8 us`.

The code for station `i` is:

```
c_i[n] = code_i[floor(n / N_chip) + 1]     (n = 0, ..., N-1)
```

where `code_i` is the length-L code vector. This produces a piecewise-constant ±1 signal.

### C.5 Coded Waveform Generation

```
s_i[n] = s_FMCW[n] * c_i[n]
```

where `s_FMCW[n] = exp(j * pi * S * t[n]^2)` is the common baseband chirp. Since `c_i[n] = ±1`, the coded waveform is still unit-modulus.

### C.6 Propagation and Dechirp with Coded Signals

**Transmitted by station i, received at station j after delay delta:**

```
r_ij[n] = s_i(t[n] - delta) = s_FMCW(t[n] - delta) * c_i(t[n] - delta)
```

Note: the received code is `c_i(t - delta)`, **not** `c_i(t)`. The code is misaligned by the propagation delay.

**Dechirp at station j** (j's local LO is uncoded FMCW):

If station j uses an uncoded LO for dechirp:
```
z_ij[n] = s_FMCW(t[n]) * conj(r_ij[n])
        = s_FMCW(t[n]) * conj(s_FMCW(t[n] - delta)) * conj(c_i(t[n] - delta))
        = beat_uncoded[n] * conj(c_i(t[n] - delta))
```

The dechirped signal contains the usual beat tone **modulated by the conjugate of the delayed code**.

### C.7 Code Correlation / Despreading

To identify station `i` and extract its beat, correlate the dechirped signal against station `i`'s code:

**Normalized correlation for aligned case (delta ≈ 0):**
```
R_i = (1/N) * sum(z[n] * c_i[n])
```

For the aligned case where `c_i(t - delta) ≈ c_i(t)`:
- Correlating against the correct code: `R_i ≈ (1/N) * sum(beat * |c_i|^2) = mean(beat)` — recovers the beat.
- Correlating against the wrong code: `R_i ≈ (1/N) * sum(beat * c_j * c_i) ≈ 0` for orthogonal codes — rejects the interferer.

**Despreading operation:**
```
beat_decoded_i[n] = z[n] * c_i[n]
```

If the received code matches `c_i`, this removes the code modulation: `c_i * conj(c_i) = |c_i|^2 = 1`. The result is the uncoded beat.

If the received code is `c_j != c_i`, the product `c_j * c_i` scrambles the signal into a code-domain noise-like product, and its spectral energy is spread.

### C.8 Beat-Frequency Estimation After Decoding

After despreading:
```
beat_decoded_i = z .* c_i;           % element-wise code multiplication
f_hat_i = estimate_beat_phase_slope(beat_decoded_i, Fs).f_est;
```

For the correct code with aligned chips, `f_hat_i` should equal the uncoded beat frequency `S * delta` to numerical tolerance.

### C.9 Node Identification

Given a received composite signal from two simultaneous coded transmitters A and B:

```
z_composite[n] = alpha_A * beat_A[n] * conj(c_A(t[n] - delta_A))
              + alpha_B * beat_B[n] * conj(c_B(t[n] - delta_B))
```

where `alpha_A`, `alpha_B` are received amplitudes (possibly unequal).

**Despreading with code A:**
```
z_composite .* c_A ≈ alpha_A * beat_A + alpha_B * beat_B * c_B * c_A
```

For orthogonal codes, `c_B * c_A` produces a scrambled/spread signal, so the second term is spread across the spectrum while `alpha_A * beat_A` remains a concentrated tone. The spectral peak identifies station A and its beat frequency.

**First demonstration requirements:**
1. Two coded transmitters, both present simultaneously.
2. Unequal amplitudes: e.g., `alpha_A = 1.0`, `alpha_B = 0.3` (weak interferer).
3. Despreading with code A recovers beat_A; despreading with code B recovers beat_B.
4. FFT of despreaded signal shows clean tone; FFT of wrong-code despreaded signal shows spread energy.

### C.10 Code Misalignment Under Delay

When `delta != 0`, the received code is `c_i(t - delta)`. If `delta` is a significant fraction of `T_chip`, the received code no longer aligns with the local code template.

**Effect:** Correlating `z[n]` against `c_i[n]` (unshifted) when the received code is `c_i[n - n_delay]` produces degraded correlation. Near chip boundaries, the code value may flip, causing partial cancellation.

**Quantification:** For a delay `delta` that shifts the code by a fraction `delta / T_chip` of one chip:
- At `delta = 0`: perfect correlation (normalized output = 1.0).
- At `delta = T_chip / 2`: worst case — each chip's correlation is partially cancelled. For length-2 Walsh codes, correlation can drop to zero.

**Conceptual alignment correction:**

Given a known/estimated delay `delta_hat` from the FMCW beat frequency, generate the shifted code template:

```
c_i_shifted[n] = c_i(t[n] - delta_hat)
```

Then despread using the shifted template:
```
beat_decoded_i[n] = z[n] * c_i_shifted[n]
```

This is a **clean conceptual alignment** — it does NOT implement the full Uysal group-delay-filter receiver. It simply shifts the code template in time, which is exact in the ideal noiseless model with known delay.

### C.11 What a Faithful Uysal/Kumbul Implementation Would Require

The literature (UYSAL-2020a, KUMBUL-2022) describes a more sophisticated receiver chain:

1. **Group-delay filter:** A filter whose group delay equals `T_chip/2`, applied to the dechirped signal. This converts binary phase transitions into amplitude modulation while preserving the underlying beat tone.

2. **Envelope detection + code recovery:** The amplitude-modulated signal's envelope carries the code sequence. Cross-correlating the recovered code against known templates identifies the transmitter.

3. **Smoothed phase coding (Kumbul):** Instead of abrupt ±1 phase transitions, the code transitions are smoothed with a raised-cosine or similar shaping function. This reduces the spectral spreading caused by sharp transitions and keeps the post-dechirp signal within a narrower bandwidth, preserving the FMCW low-IF-bandwidth advantage.

4. **Baseband bandwidth implications:** Binary phase coding at `T_chip` chip rate requires post-dechirp bandwidth of at least `1/T_chip` to preserve the code transitions. For `T_chip = 12.8 us`, this is only ~78 kHz — manageable. For shorter chips (higher code rate), bandwidth grows and may exceed IF filter limits.

**V2b implements only the conceptual code-multiply/correlate/shift approach.** The group-delay filter and smoothed-code extensions are future work (V3+) and should not be implemented until the basic coded model is validated.

---

## Part D — AWR2944 Hardware Mapping

### D.1 Literature-Style Intra-Chirp PC-FMCW vs. AWR2944-Native BPM

**Literature-style intra-chirp PC-FMCW** (Uysal, Lampel, Kumbul):
- Phase code changes **within a single chirp** at the chip rate.
- Each chirp ramp carries multiple code chips.
- Requires fast phase modulation capability on the TX path during the ramp.

**AWR2944-native BPM (Binary Phase Modulation) / programmable TX phase:**
- The AWR2944 supports **per-chirp TX phase configuration** via the chirp profile.
- The TX phase shifter can apply a programmable phase offset to each chirp in a frame.
- This is used for TDM-MIMO: different TX antennas get different phase shifts on successive chirps.
- The phase change is applied **between chirps** (at the chirp boundary), not **within a chirp**.

### D.2 What Is Demonstrably Programmable (Per-Chirp)

From TI-CHIRP, TI-MIMO, and TI-CASCADE documentation:

- TX phase shifter: discrete phase steps (typically 5.625° resolution, i.e., 360°/64).
- Phase is set per chirp via the chirp profile configuration.
- Multiple chirps can be configured with different phase values in a sequence.
- This is the mechanism behind BPM-MIMO and TDM-MIMO schemes.

**Demonstrated capability:** A phase value can be programmed for each chirp in a frame. Different chirps in a burst can have different TX phases.

### D.3 What Is NOT Established About Fast-Time Phase Changes

**Not established from available documentation:**
- Arbitrary phase modulation **within a single chirp ramp** at rates faster than the chirp repetition rate.
- Sub-chirp code-chip phase switching during active sweep/ramp.
- Whether the phase shifter settling time permits intra-chirp transitions without corrupting the ramp.

The TRM describes the chirp generation pipeline (PLL, VCO, ramp generation) as producing a continuous frequency sweep. Phase modulation during the ramp is not described as a supported operating mode in the standard chirp profile configuration.

**Implication:** The simulation models intra-chirp phase coding as the literature describes it. Whether the AWR2944 can physically execute intra-chirp phase changes at the required chip rate is **not confirmed** from available documentation and would require lower-level mmWaveLink API investigation or TI guidance.

### D.4 AWR2944 CW Operation

**Available evidence:**
- The AWR2944 TRM and programming guides describe FMCW chirp generation as the primary operating mode.
- A "zero-slope" chirp (slope = 0) could conceptually produce CW, but this is not documented as a standard operating mode.
- Some TI devices support a "link test" or "continuous mode" via mmWaveLink API calls for factory testing/characterization, but this typically requires lower-level control, not the standard CLI/demo path.

**Implication for calibration tone (Part B):**
- Generating a CW calibration tone on the AWR2944 may require mmWaveLink-level control or a zero-slope chirp profile.
- This is a hardware-feasibility question, not a simulation constraint.
- The simulation models an ideal CW tone regardless of how the hardware would generate it.

### D.5 Per-Chirp Phase Coding as an Alternative

Instead of intra-chirp phase coding, a **per-chirp** coding approach is more clearly compatible with AWR2944:

- Each chirp in a burst gets a binary phase (+0° or +180°) via the TX phase shifter.
- The code sequence spans multiple chirps, not multiple chips within one chirp.
- This is conceptually the same as BPM-MIMO coding.

**Trade-off:** Per-chirp coding operates in slow time (across chirps) rather than fast time (within one chirp). It provides inter-chirp node identity but does not provide intra-chirp interference rejection in the same way as literature PC-FMCW.

V2b models intra-chirp coding because it is the dominant literature convention and conceptually cleaner. The per-chirp alternative is noted here as a hardware-compatible path for future exploration.

---

## Part E — Proposed Software Structure

### E.1 Design Principle

- **Preserve all V0/V1 functions and tests unchanged.**
- **New modules extend, never modify, validated code.**
- V2a (CFO) and V2b (coding) are independent branches that can be implemented and tested separately.

### E.2 New File Layout

```
10_SIMULATION_WORKSPACE/matlab/
|
|-- src/
|   |-- (existing V0/V1 files unchanged)
|   |
|   |-- % V2a: CFO
|   |-- apply_cfo.m                    % CFO frequency shift on beat signal
|   |-- generate_cal_tone.m            % CW calibration tone generation
|   |-- estimate_cfo_from_tone.m       % CFO estimation from cal tone
|   |-- correct_cfo.m                  % Apply CFO correction to beat
|   |-- simulate_cfo_link.m            % CFO-aware link (wraps simulate_ideal_link)
|   |-- solve_twtt_updown.m            % Up/down chirp CFO+delay solver
|   |
|   |-- % V2b: Phase Coding
|   |-- generate_code.m                % Walsh-Hadamard / orthogonal code generation
|   |-- generate_coded_chirp.m         % s_FMCW * c_i
|   |-- despread_code.m                % z .* c_i (normalized correlation)
|   |-- align_code.m                   % Shift code template by estimated delay
|   |-- code_correlation.m             % Compute normalized cross-correlation
|
|-- scripts/
|   |-- (existing demos unchanged)
|   |-- demo_v2a_cfo.m                 % CFO demo + 3-way comparison
|   |-- demo_v2b_coding.m             % Phase coding demo
|
|-- tests/
|   |-- (existing tests unchanged)
|   |-- test_cfo_basic.m               % CFO zero/analytic/stress tests
|   |-- test_cfo_twtt.m                % CFO effect on TWTT recovery
|   |-- test_cal_tone.m                % Calibration tone CFO recovery
|   |-- test_updown.m                  % Up/down chirp CFO separation
|   |-- test_coding_basic.m            % Code generation/correlation tests
|   |-- test_coding_twtt.m             % Coded TWTT recovery
|   |-- test_code_misalignment.m       % Misalignment degradation/recovery
```

### E.3 Function Contracts

#### `apply_cfo(beat, t, Delta_f, direction)`

**Purpose:** Apply carrier-frequency offset to a dechirped beat signal.

**Inputs:**
- `beat` — complex beat signal [Nx1]
- `t` — time vector [Nx1] [s]
- `Delta_f` — carrier-frequency offset [Hz] (= f_B - f_A)
- `direction` — string: `'AB'` or `'BA'`

**Output:** `beat_cfo` — CFO-shifted beat signal [Nx1]

**Implementation:**
```matlab
if strcmp(direction, 'AB')
    beat_cfo = beat .* exp(+j * 2*pi * Delta_f * t);
elseif strcmp(direction, 'BA')
    beat_cfo = beat .* exp(-j * 2*pi * Delta_f * t);
end
```

**Invariant:** `apply_cfo(beat, t, 0, 'AB')` returns `beat` unchanged.

---

#### `simulate_cfo_link(cfg, tau, theta, Delta_f)`

**Purpose:** Simulate both A→B and B→A links with CFO.

**Inputs:**
- `cfg` — configuration struct (from `make_default_params`)
- `tau` — one-way propagation delay [s]
- `theta` — relative clock epoch offset [s]
- `Delta_f` — carrier-frequency offset [Hz]

**Output:** Struct `result` with fields:
- `.link_AB` — A→B link struct (from `simulate_ideal_link` + CFO)
- `.link_BA` — B→A link struct (from `simulate_ideal_link` + CFO)
- `.beat_AB` — CFO-modified A→B beat [Nx1]
- `.beat_BA` — CFO-modified B→A beat [Nx1]
- `.f_AB_theory` — theoretical f_AB = S*(tau+theta) + Delta_f [Hz]
- `.f_BA_theory` — theoretical f_BA = S*(tau-theta) - Delta_f [Hz]

**Implementation:**
```matlab
link_AB = simulate_ideal_link(cfg, tau + theta);
link_BA = simulate_ideal_link(cfg, tau - theta);
t = link_AB.t;
result.beat_AB = apply_cfo(link_AB.beat, t, Delta_f, 'AB');
result.beat_BA = apply_cfo(link_BA.beat, t, Delta_f, 'BA');
result.f_AB_theory = cfg.S * (tau + theta) + Delta_f;
result.f_BA_theory = cfg.S * (tau - theta) - Delta_f;
% ... etc
```

---

#### `generate_cal_tone(t, Delta_f)`

**Purpose:** Generate ideal CW calibration tone at frequency `Delta_f`.

**Inputs:**
- `t` — time vector [Nx1] [s]
- `Delta_f` — frequency offset (= true CFO) [Hz]

**Output:** `z_cal` — complex tone [Nx1]

**Implementation:**
```matlab
z_cal = exp(j * 2*pi * Delta_f * t);
```

**Note:** In a full RF model, the calibration tone contains additional constant phase from `f_B*theta + f_A*tau`. For V2a frequency estimation, this constant does not affect the result and is omitted.

---

#### `estimate_cfo_from_tone(z_cal, Fs)`

**Purpose:** Estimate CFO from a calibration tone.

**Inputs:**
- `z_cal` — complex calibration tone [Nx1]
- `Fs` — sample rate [Hz]

**Output:** `Delta_f_hat` — estimated CFO [Hz]

**Implementation:** Delegates to `estimate_beat_phase_slope`:
```matlab
result = estimate_beat_phase_slope(z_cal, Fs);
Delta_f_hat = result.f_est;
```

---

#### `correct_cfo(beat, t, Delta_f_hat, direction)`

**Purpose:** Remove estimated CFO from a dechirped beat signal.

**Inputs:** Same as `apply_cfo` but with estimated `Delta_f_hat`.

**Implementation:**
```matlab
if strcmp(direction, 'AB')
    beat_corrected = beat .* exp(-j * 2*pi * Delta_f_hat * t);
elseif strcmp(direction, 'BA')
    beat_corrected = beat .* exp(+j * 2*pi * Delta_f_hat * t);
end
```

**Invariant:** `correct_cfo(apply_cfo(beat, t, Df, 'AB'), t, Df, 'AB') == beat`.

---

#### `solve_twtt_updown(f_up, f_down, S)`

**Purpose:** Recover CFO and effective delay from up/down chirp pair.

**Inputs:**
- `f_up` — beat frequency from up-chirp (+S) observation [Hz]
- `f_down` — beat frequency from down-chirp (-S) observation [Hz]
- `S` — chirp slope magnitude [Hz/s] (positive)

**Output:** `[Delta_f_hat, delta_hat]`

**Implementation:**
```matlab
Delta_f_hat = (f_up + f_down) / 2;
delta_hat   = (f_up - f_down) / (2 * S);
```

---

#### `generate_code(code_type, L)`

**Purpose:** Generate orthogonal binary phase code.

**Inputs:**
- `code_type` — string: `'A'` or `'B'`
- `L` — code length (default: 2)

**Output:** `code` — row vector of ±1 values, length L

**Implementation (L = 2, Walsh-Hadamard):**
```matlab
if strcmp(code_type, 'A')
    code = [+1, +1];
elseif strcmp(code_type, 'B')
    code = [+1, -1];
end
```

---

#### `generate_coded_chirp(t, S, code, L)`

**Purpose:** Generate a phase-coded FMCW chirp.

**Inputs:**
- `t` — time vector [Nx1] [s]
- `S` — chirp slope [Hz/s]
- `code` — code vector [1xL] of ±1 values
- `L` — code length

**Output:** `s_coded` — coded chirp [Nx1]

**Implementation:**
```matlab
N = length(t);
N_chip = N / L;   % must be integer
s_fmcw = fmcw_baseband(t, S);
c = zeros(N, 1);
for k = 1:L
    idx = (k-1)*N_chip + 1 : k*N_chip;
    c(idx) = code(k);
end
s_coded = s_fmcw .* c;
```

**Invariant:** For `code = [+1, +1, ..., +1]`, output equals `fmcw_baseband(t, S)`.

---

#### `despread_code(z, code, L, N)`

**Purpose:** Despread a received/dechirped signal using a code template.

**Inputs:**
- `z` — dechirped signal [Nx1]
- `code` — code vector [1xL]
- `L` — code length
- `N` — total samples

**Output:** `z_despread` — despreaded signal [Nx1]

**Implementation:**
```matlab
N_chip = N / L;
c = zeros(N, 1);
for k = 1:L
    idx = (k-1)*N_chip + 1 : k*N_chip;
    c(idx) = code(k);
end
z_despread = z .* c;
```

---

#### `align_code(code, L, N, Fs, delta)`

**Purpose:** Generate a time-shifted code template for alignment correction.

**Inputs:**
- `code` — code vector [1xL]
- `L` — code length
- `N` — total samples
- `Fs` — sample rate [Hz]
- `delta` — estimated delay [s]

**Output:** `c_shifted` — shifted code template [Nx1]

**Implementation:**
```matlab
T_chip = (N / Fs) / L;
N_chip = N / L;
t = (0:N-1).' / Fs;
t_shifted = t - delta;
c_shifted = zeros(N, 1);
for n = 1:N
    chip_idx = floor(t_shifted(n) / T_chip) + 1;
    chip_idx = max(1, min(L, chip_idx));   % clamp to valid range
    c_shifted(n) = code(chip_idx);
end
```

---

#### `code_correlation(z, code, L, N)`

**Purpose:** Compute normalized code correlation for node identification.

**Inputs:**
- `z` — dechirped signal [Nx1]
- `code` — code vector [1xL]
- `L` — code length
- `N` — total samples

**Output:** `R` — normalized scalar correlation

**Implementation:**
```matlab
z_despread = despread_code(z, code, L, N);
R = abs(sum(z_despread)) / N;
```

---

## Part F — Test Plan

### F.1 CFO Tests

| ID | Test | Injected condition | Expected result |
|---|---|---|---|
| **C01** | CFO disabled reproduces V1 | Delta_f = 0, tau = 5 ns, theta = 100 ps | tau_hat, theta_hat match V1 exactly |
| **C02** | Positive CFO, A→B beat | Delta_f = +100 kHz | f_AB = S*(tau+theta) + 100 kHz |
| **C03** | Positive CFO, B→A beat | Delta_f = +100 kHz | f_BA = S*(tau-theta) - 100 kHz |
| **C04** | Negative CFO | Delta_f = -100 kHz | Signs reverse correctly |
| **C05** | Zero delay with CFO | tau = 0, theta = 0, Delta_f = 50 kHz | f_AB = +50 kHz, f_BA = -50 kHz |
| **C06** | Analytical AB/BA beat signs | Multiple (tau, theta, Delta_f) | All match derived formulas |
| **C07** | Naive TWTT bias | Delta_f = 100 kHz, no correction | tau_hat correct, theta_hat biased by Delta_f/S |
| **C08** | Bias magnitude | Delta_f = 100 kHz | bias_theta = 100e3 / 2.9982e13 = 3.3353 ns |
| **C09** | Large CFO stress test | Delta_f = 10 MHz | theta_hat error = 333.53 ns |
| **C10** | CFO sum cancellation | Various Delta_f | f_AB + f_BA always = 2*S*tau |
| **C11** | Up/down CFO recovery | Delta_f = 100 kHz, up+down A→B | Delta_f_hat = 100 kHz exactly |
| **C12** | Up/down delay recovery | Same as C11 | delta_hat = tau + theta exactly |
| **C13** | Cal tone CFO recovery | Delta_f = 100 kHz | Delta_f_hat from tone = 100 kHz |
| **C14** | Cal tone negative CFO | Delta_f = -50 kHz | Delta_f_hat = -50 kHz |
| **C15** | Tone-corrected TWTT | Delta_f = 100 kHz, correct, solve | tau_hat = tau, theta_hat = theta |
| **C16** | Residual-CFO scaling | Delta_f sweep: 10, 100, 1k, 10k, 100k Hz | bias_theta matches Delta_f/S table |
| **C17** | CFO zero test (apply_cfo) | Delta_f = 0 | beat unchanged bit-for-bit |
| **C18** | CFO round-trip | Apply then correct | beat unchanged to tolerance |

### F.2 Phase Coding Tests

| ID | Test | Injected condition | Expected result |
|---|---|---|---|
| **P01** | Code normalization | Any code | All elements ±1 |
| **P02** | Code orthogonality | Walsh A, B | sum(A .* B) = 0 |
| **P03** | All-ones code = uncoded | code = [+1, +1] | Coded chirp = uncoded chirp |
| **P04** | Coding disabled reproduces uncoded FMCW | All-ones code, standard delay | beat matches V0/V1 exactly |
| **P05** | Aligned cross-correlation (correct code) | delta = 0, code A | R_A ≈ 1.0, R_B ≈ 0.0 |
| **P06** | Aligned cross-correlation (wrong code) | delta = 0, despread with B | R_B ≈ 0.0 |
| **P07** | Correct node identification | Two coded transmitters | Correct code yields higher correlation |
| **P08** | Unequal amplitudes | alpha_A = 1.0, alpha_B = 0.3 | Both nodes identified; beats recovered |
| **P09** | Decoded beat equals uncoded beat | Single coded TX, aligned | f_hat from decoded = S*delta |
| **P10** | Decoded TWTT preserves tau/theta | V1 with coding, both dirs | tau_hat = tau, theta_hat = theta |
| **P11** | Fractional code misalignment degrades naive | delta = T_chip/4 | Correlation degrades significantly |
| **P12** | Half-chip misalignment worst case | delta = T_chip/2 | For Walsh-2, correlation ≈ 0 |
| **P13** | Alignment correction restores decoding | delta = T_chip/4, use align_code | Correlation restored, beat recovered |
| **P14** | Zero delay preserves coding | delta = 0 | Perfect correlation, clean beat |
| **P15** | Code length validation | L not dividing N | Error or graceful rejection |

### F.3 Test Philosophy

Every physical mechanism has:
1. **Zero test:** disabled mechanism changes nothing (C01, C17, P03, P04, P14).
2. **Analytic test:** one simple case matches a closed-form prediction (C02-C06, C08, C10-C14, P02, P05, P06, P09).
3. **Stress/failure test:** large value produces the expected qualitative failure signature (C09, P11, P12).

### F.4 Tolerance Specification

| Quantity | Tolerance | Rationale |
|---|---|---|
| Beat frequency (CFO cases) | `abs(f_hat - f_theory) / abs(f_theory) < 1e-10` | Same as V0/V1 |
| CFO recovery (tone/updown) | `abs(Delta_f_hat - Delta_f) / abs(Delta_f) < 1e-10` | Pure tone in noise-free |
| Timing recovery after correction | `abs(tau_hat - tau) < 1e-14 s` | Same as V1 |
| Code correlation (correct, aligned) | `R > 0.99` | Near-unity |
| Code correlation (wrong, aligned) | `R < 0.01` | Near-zero |
| Decoded beat = uncoded beat | `max(abs(z_decoded - z_uncoded)) < 1e-10` | Sample-wise |

---

## Part G — Proposed Figures

### G.1 CFO Figures

**Figure 7 — TWTT Bias vs. Injected CFO**
- X-axis: Delta_f [kHz], log scale, from 0.01 to 1000 kHz
- Y-axis: theta_hat bias [ps]
- Two curves: (a) naive V1 solver (shows linear bias), (b) after calibration-tone correction (shows zero bias)
- Overlay: theoretical line `bias = Delta_f / S`
- Label: "Ideal noise-free model"

**Figure 8 — Before/After Calibration-Tone Correction**
- Three-panel figure for a representative CFO (e.g., Delta_f = 100 kHz):
  - (a) Beat spectra with CFO: f_AB and f_BA shifted by ±Delta_f
  - (b) Calibration tone spectrum: peak at Delta_f
  - (c) Corrected beat spectra: f_AB and f_BA match V1 positions
- Recovery summary box: injected/recovered tau, theta, Delta_f

**Figure 9 (Optional) — Up/Down CFO Comparison**
- Side-by-side comparison of calibration-tone and up/down recovery of Delta_f
- X-axis: injected Delta_f
- Y-axis: recovered Delta_f
- Both should lie on the identity line in the ideal model

### G.2 Phase Coding Figures

**Figure 10 — Code Correlation and Node Identity**
- Two-panel figure:
  - (a) Despreading with correct code: clean beat spectrum (dB)
  - (b) Despreading with wrong code: spread/suppressed energy
- Label: "Walsh-2, alpha_A = 1.0, alpha_B = 0.3"

**Figure 11 — Simultaneous Coded Signal Separation**
- Three panels:
  - (a) Composite received spectrum (both coded transmitters present)
  - (b) After despreading with code A: clean tone at f_A
  - (c) After despreading with code B: clean tone at f_B
- Unequal amplitude case (strong + weak)

**Figure 12 — Code-Misalignment Degradation and Recovery**
- X-axis: delay as fraction of T_chip
- Y-axis: normalized correlation
- Two curves: (a) naive unshifted correlation (degrades), (b) aligned correlation (restored)
- Mark T_chip/2 worst case

---

## Acceptance Criteria

### V2a (CFO) is accepted when:

1. All 18 CFO tests (C01–C18) pass.
2. Setting Delta_f = 0 reproduces V1 outputs bit-for-bit.
3. Derived AB/BA beat frequency signs are verified by simulation.
4. Calibration-tone CFO recovery matches injected Delta_f to tolerance.
5. Tone-corrected TWTT recovery matches injected tau and theta to V1 tolerance.
6. Up/down chirp recovery matches injected Delta_f and delta to tolerance.
7. Residual-CFO bias table matches the analytical prediction in Section A.7.
8. Three-way comparison (Methods A/B/C) executed and documented.
9. All existing V0/V1 tests still pass (regression).

### V2b (Phase Coding) is accepted when:

1. All 15 coding tests (P01–P15) pass.
2. All-ones code reproduces uncoded V0/V1 exactly.
3. Two coded transmitters at unequal amplitudes are correctly separated by code correlation.
4. Decoded beat frequency matches uncoded beat frequency to V0 tolerance.
5. Decoded TWTT preserves injected tau and theta to V1 tolerance.
6. Code misalignment degrades naive correlation.
7. Alignment correction using known delay restores correlation.
8. All existing V0/V1 tests still pass (regression).
9. No new toolbox dependencies introduced.

---

## Recommended Implementation Order

1. **V2a first, V2b second.** The simulation blueprint (BLUEPRINT §16, §18) explicitly states that CFO/independent-oscillator modeling is the next scientifically useful task after V1, and that phase coding should follow after the clock-offset algebra is validated with independent oscillators.

2. **Within V2a:**
   - (a) `apply_cfo` + `simulate_cfo_link` + tests C01–C10 (core CFO model)
   - (b) `generate_cal_tone` + `estimate_cfo_from_tone` + `correct_cfo` + tests C13–C18 (calibration tone)
   - (c) Up/down chirp support + `solve_twtt_updown` + tests C11–C12 (Roehr method)
   - (d) Three-way comparison demo + figures

3. **Within V2b:**
   - (a) `generate_code` + `generate_coded_chirp` + `despread_code` + tests P01–P09 (basic coding)
   - (b) Two-transmitter demo + node identification + test P07–P08 (node ID)
   - (c) `align_code` + misalignment tests P11–P13 (alignment)
   - (d) Coded TWTT test P10 + figures

---

## Unresolved Ambiguities

1. **CFO sign convention verification:** The derived signs `f_AB = S*(tau+theta) + Delta_f` and `f_BA = S*(tau-theta) - Delta_f` must be verified numerically by the first few tests. If the implementation produces opposite signs, the entire spec must be revisited. The derivation follows rigorously from the project's `z = LO * conj(RX)` convention, but the sign should be frozen in a unit test, not trusted on algebra alone.

2. **Calibration tone constant phase:** The V2a calibration tone model omits constant phase terms (f_B*theta + f_A*tau). These do not affect frequency estimation but would matter for phase-based estimation in future versions. Noted for V3+.

3. **Down-chirp slope sign:** The project's V0/V1 uses only positive slope S > 0. Down-chirp tests (C11, C12) require negative slope. The existing `fmcw_baseband` and `simulate_ideal_link` accept negative S algebraically, but this has not been validated by a V0/V1 test. A regression test for negative slope should be added.

4. **Code chip alignment at sample boundaries:** The code chip boundaries must align with sample boundaries (`N/L` must be integer). For non-integer ratios, the implementation should error clearly. This is a constraint, not a numerical ambiguity.

5. **AWR2944 intra-chirp phase modulation:** Not confirmed from available documentation. The simulation models it regardless, but hardware validation will require investigation.

---

## Conflicts Between Literature PC-FMCW and AWR2944

| Feature | Literature PC-FMCW | AWR2944 (documented) | Conflict? |
|---|---|---|---|
| Phase change location | Within chirp (fast time) | Between chirps (per-chirp TX phase) | **YES** |
| Phase resolution | Arbitrary (analog) | ~5.625° discrete steps | Minor |
| Code rate | Up to chip rate within chirp | Chirp repetition rate | **YES** |
| CW calibration tone | Arbitrary | Requires zero-slope profile or mmWaveLink | **Uncertain** |
| Baseband BW for coding | Increases with chip rate | Fixed IF/ADC bandwidth | Potential issue |

The simulation treats intra-chirp phase coding as the primary model, consistent with the literature. AWR2944 hardware realization may require per-chirp coding as an alternative. Both paths are noted; neither is excluded from the simulation at this stage.
