# PC-FMCW Receiver Theory and Next Step

## 1. Current Receiver Equations

### 1.1 Transmitted Signal

Station i transmits a phase-coded FMCW chirp in complex baseband:

```
s_i(t) = exp(j*pi*S*t^2) * c_i(t)
```

where `c_i(t)` is a piecewise-constant binary phase code with `L` chips of duration `T_chip = T_obs / L`, and `c_i(t) in {+1, -1}` for all `t`.

### 1.2 Received Composite Signal

At the receiver, the composite signal from two coded transmitters A and B, each with different delays delta_A, delta_B and received amplitudes alpha_A, alpha_B, is:

```
r(t) = alpha_A * s_FMCW(t - delta_A) * c_A(t - delta_A)
     + alpha_B * s_FMCW(t - delta_B) * c_B(t - delta_B)
```

### 1.3 Dechirp (Stretch Processing)

The receiver dechirps with an uncoded local chirp `s_LO(t) = exp(j*pi*S*t^2)`:

```
z(t) = s_LO(t) * conj(r(t))
     = alpha_A * beat_A(t) * conj(c_A(t - delta_A))
     + alpha_B * beat_B(t) * conj(c_B(t - delta_B))
```

where `beat_i(t) = exp(j*2*pi*S*delta_i*t - j*pi*S*delta_i^2)` is the uncoded FMCW beat signal at frequency `f_i = S*delta_i`.

For real +/-1 codes, `conj(c_i) = c_i`, so:

```
z(t) = alpha_A * beat_A(t) * c_A(t - delta_A)
     + alpha_B * beat_B(t) * c_B(t - delta_B)
```

### 1.4 Current Despreading Operation

The current receiver despreads with the delay-aligned code template `c_B(t - delta_B)`:

```
z_B(t) = z(t) * c_B(t - delta_B)
       = alpha_A * beat_A(t) * c_A(t - delta_A) * c_B(t - delta_B)    [interferer]
       + alpha_B * beat_B(t) * c_B(t - delta_B) * c_B(t - delta_B)    [desired]
       = alpha_A * beat_A(t) * c_A(t - delta_A) * c_B(t - delta_B)
       + alpha_B * beat_B(t)                                           [since |c_B|^2 = 1]
```

### 1.5 Key Observation

The desired term `alpha_B * beat_B(t)` is a clean tone at `f_B = S*delta_B`. The interfering term is:

```
I(t) = alpha_A * beat_A(t) * c_A(t - delta_A) * c_B(t - delta_B)
     = alpha_A * exp(j*2*pi*f_A*t + phi_A) * c_A(t - delta_A) * c_B(t - delta_B)
```

The current receiver applies the despreading code aligned to delta_B, while the interfering code c_A arrives aligned to delta_A. The cross-code product `c_A(t - delta_A) * c_B(t - delta_B)` is NOT a simple global inner product -- it is evaluated at each sample t, weighted by the beat-frequency complex exponential `exp(j*2*pi*f_A*t)`.

---

## 2. Mathematical Explanation of the Observed Failure

### 2.1 Why sum(c_A[k]*c_B[k]) = 0 Does Not Guarantee Cancellation

The Walsh-Hadamard orthogonality relation

```
sum_{k=1}^{L} c_A[k] * c_B[k] = 0
```

guarantees cancellation of the interferer ONLY if the interfering signal is constant within each chip and the codes are perfectly aligned. In our system, the interfering beat signal is `exp(j*2*pi*f_A*t)`, which rotates in phase continuously.

Consider the despreading integral over the full observation:

```
integral_0^{T_obs} I(t) dt = alpha_A * sum_{k=1}^{L} c_A[k]*c_B[k] * integral_{(k-1)*T_chip}^{k*T_chip} exp(j*2*pi*f_A*t) dt
```

The integral within each chip is:

```
integral_{(k-1)*T_chip}^{k*T_chip} exp(j*2*pi*f_A*t) dt = T_chip * sinc(f_A*T_chip) * exp(j*2*pi*f_A*(k-0.5)*T_chip)
```

The code orthogonality sum becomes:

```
sum_k c_A[k]*c_B[k] * exp(j*2*pi*f_A*(k-0.5)*T_chip) != 0   in general
```

This is a WEIGHTED orthogonality sum where each term carries a complex phase factor that depends on the beat frequency. The Walsh orthogonality holds when the weights are all equal (i.e., f_A = 0 or f_A*T_chip << 1), but BREAKS when the beat-frequency phase rotation accumulates significantly over T_chip.

### 2.2 Beat Phase Rotation Per Chip

The critical parameter is the phase accumulated by the interfering beat within one chip:

```
Delta_phi_chip = 2*pi * f_A * T_chip
```

For the current simulation parameters:

| Parameter | Value |
|---|---|
| S | 29.982e12 Hz/s |
| delta_A | 3 ns |
| f_A = S*delta_A | 89,946 Hz |
| T_obs | 25.6 us |

| L | T_chip | f_A*T_chip | Delta_phi (rad) | Delta_phi (deg) |
|---|---|---|---|---|
| 2 | 12.8 us | 1.1513 | 7.233 | 414 |
| 4 | 6.4 us | 0.5757 | 3.617 | 207 |
| 8 | 3.2 us | 0.2878 | 1.808 | 104 |
| 16 | 1.6 us | 0.1439 | 0.904 | 52 |

Even at L=16, the beat rotates by 52 degrees per chip -- nearly a full quadrant. The weighted orthogonality sum is significantly corrupted at every code length we tested.

### 2.3 Why SIR Improves but Beat Recovery Fails

Increasing L improves SIR because the cross-code product `c_A[k]*c_B[k]` distributes the interference across more spectral bins. However, each bin still carries correlated interference because the phase weighting is systematic, not random.

The interference is not "spread into noise" -- it is phase-modulated at the beat frequency. The resulting residual interfering spectrum has discrete structure concentrated near f_A, f_A +/- 1/T_chip, and harmonics. This structured interference is sufficient to corrupt the phase-slope estimator's least-squares fit, even when the spectral peak at f_B is correct.

### 2.4 Additional Failure Mechanism: Code Delay Misalignment

In the two-transmitter case, the cross-code product `c_A(t - delta_A) * c_B(t - delta_B)` involves codes shifted by DIFFERENT delays. When delta_A != delta_B, the chip boundaries of c_A and c_B no longer align, further degrading the orthogonality.

For delta_A = 3 ns and delta_B = 7 ns, the differential delay is 4 ns. With T_chip = 12.8 us (L=2), the misalignment is 4 ns / 12.8 us = 3.1e-4 chips -- negligible. **Therefore, the primary failure mechanism is beat-frequency phase rotation, not code misalignment.**

### 2.5 Root Cause Summary

> **The simple chip-rate despreader fails because it treats the dechirped signal as if the code modulation is the dominant spectral feature.** In reality, after dechirping, the beat frequency imposes a fast-rotating complex exponential that is NOT separable from the code modulation by simple element-wise multiplication. The code orthogonality sum is broken by the frequency-dependent phase weighting.
>
> This is not a limitation of Walsh codes -- it is a limitation of the **receiver architecture**. Any binary code family would exhibit the same failure under these conditions. The literature addresses this by inserting a **group-delay filter** before despreading.

---

## 3. Literature Receiver Equations

### 3.1 Uysal (2020) Group-Delay Filter Receiver

Reference: F. Uysal, "Phase-Coded FMCW Automotive Radar: System Design and Interference Mitigation," IEEE Trans. Vehicular Technology, 2020.

#### 3.1.1 Problem Statement

After dechirping a PC-FMCW signal, the beat signal carries the phase code delayed by the target's round-trip time tau:

```
z(t) = beat(t) * c(t - tau)
```

The beat frequency f_b = S*tau maps range to frequency. Different targets at different ranges produce beat signals at different frequencies, each carrying the same code but shifted by different amounts. The code misalignment is frequency-dependent.

#### 3.1.2 Key Insight

The dechirping operation converts a time delay tau into a beat frequency f_b = S*tau. Therefore:

```
tau = f_b / S
```

The code delay is tau, so the code misalignment is:

```
code delay = f_b / S
```

This relationship is the foundation of the group-delay filter: the filter applies a frequency-dependent delay equal to f/S to each frequency component of the dechirped signal.

#### 3.1.3 Group-Delay Filter Transfer Function

The group-delay filter H_gd(f) has:

- Modulus: |H_gd(f)| = 1 (all-pass)
- Group delay: tau_gd(f) = f / S (in our notation; in Uysal notation: tau_gd(f) = T*f / B = f / alpha)
- Phase response: angle(H_gd(f)) = -pi*f^2 / S

The phase response is obtained by integrating the group delay:

```
angle(H_gd(f)) = -2*pi * integral tau_gd(f') df' = -2*pi * integral (f'/S) df' = -pi*f^2/S
```

This is a dispersive all-pass filter (chirp-like phase response).

#### 3.1.4 What the Filter Does

For a beat signal at frequency f_b:

1. The dechirped signal `z(t) = exp(j*2*pi*f_b*t) * c(t - f_b/S)` has the code delayed by f_b/S.
2. The group-delay filter delays the frequency component at f_b by f_b/S in time.
3. After filtering, the beat signal becomes `z_filtered(t) = exp(j*2*pi*f_b*t + phi(f_b)) * c(t - f_b/S + f_b/S)` = `exp(j*2*pi*f_b*t + phi(f_b)) * c(t)`.
4. The code is now aligned at t=0 regardless of the beat frequency.

After group-delay filtering, all targets' codes are realigned, and simple code multiplication/despreading restores orthogonality.

#### 3.1.5 After Group-Delay Filtering + Despreading

```
z_filtered(t) * c_desired(t) = desired beat + orthogonally coded interferers
```

The orthogonality condition `sum c_i[k]*c_j[k] = 0` now holds because the codes are all aligned to t=0 and the weighting phases have been compensated by the filter's frequency-dependent delay.

### 3.2 Kumbul (2022) Smoothed PC-FMCW

Reference: U. Kumbul et al., "Smoothed Phase-Coded FMCW: Waveform Properties and Transceiver Architecture," IEEE Trans. Aerospace and Electronic Systems, 2022.

Kumbul identifies that the group-delay filter itself introduces dispersion that distorts the code shape, especially for binary phase transitions. The proposed solution is:

1. Transmit smoothed codes: Replace abrupt +/-1 transitions with Gaussian-smoothed transitions.
2. Pre-compensate dispersion: Apply quadratic phase pre-distortion to the transmitted code so that after group-delay filtering at the receiver, the code is undistorted.

For our immediate purposes (ideal rectangular codes, no noise, analytic model), the Kumbul smoothing extensions are NOT required. The group-delay filter alone is sufficient in the ideal case because dispersion effects are small when the code rate is much lower than the chirp bandwidth.

### 3.3 Lampel (2020) System-Level Synchronization

Reference: F. Lampel et al., "System Level Synchronization of Phase-Coded FMCW Automotive Radars for RadCom," EuCAP, 2020.

Lampel addresses the system-level synchronization problem: how to detect and synchronize to a PC-FMCW signal from an unsynchronized transmitter. This involves:

- Time-of-arrival estimation for coarse synchronization.
- Group-delay filtered processing for code recovery.

This paper confirms the group-delay filter as the standard receiver component but focuses on acquisition rather than steady-state decoding.

---

## 4. Group-Delay / Delay-Compensation Derivation

### 4.1 Derivation in Our Notation

In our project notation:

| Literature | Our notation |
|---|---|
| alpha = B/T (chirp rate) | S (Hz/s) |
| tau (round-trip delay) | delta (one-way delay) |
| f_b = alpha*tau | f_b = S*delta |
| T (chirp duration) | T_obs |

The group-delay filter operates on the dechirped signal z(t):

#### Step 1: Input Signal

The dechirped signal from a single coded transmitter at delay delta:

```
z(t) = exp(j*2*pi*S*delta*t - j*pi*S*delta^2) * c(t - delta)
     = exp(j*2*pi*f_b*t + phi_0) * c(t - delta)
```

where f_b = S*delta and phi_0 = -pi*S*delta^2.

#### Step 2: Key Relationship

The delay delta appearing in the code `c(t - delta)` is related to the beat frequency by:

```
delta = f_b / S
```

This means: the code delay equals the beat frequency divided by the chirp slope. A target at a higher beat frequency has a larger code delay.

#### Step 3: Group-Delay Filter Application

The filter H_gd(f) = exp(-j*pi*f^2/S) has group delay tau_gd(f) = f/S.

Applied in the frequency domain:

```
Z_filtered(f) = Z(f) * exp(-j*pi*f^2/S)
```

In the time domain, this is equivalent to convolving z(t) with the chirp kernel h(t) = exp(j*pi*S*t^2) (up to normalization).

#### Step 4: Effect on Beat + Code

For a beat component at frequency f_b, the filter delays it by f_b/S = delta. The code, which was shifted by -delta in the dechirped signal, receives an additional shift of +delta from the filter, returning it to alignment at t=0.

After filtering:

```
z_filtered(t) = exp(j*2*pi*f_b*t + phi_filtered) * c(t)
```

The code is realigned. phi_filtered contains additional phase terms from the filter but does not affect code alignment or beat-frequency estimation.

#### Step 5: Despreading After Filter

```
z_decoded(t) = z_filtered(t) * c_desired(t)
             = exp(j*2*pi*f_b*t + phi_filtered) * c(t) * c_desired(t)
```

For the correct code: `c(t) * c_desired(t) = |c|^2 = 1` -> clean beat tone.
For a wrong code: `c_other(t) * c_desired(t)` -> orthogonal scrambling -> spread spectrum.

### 4.2 Why This Preserves FMCW Stretch Processing

The group-delay filter is an all-pass filter in the beat-signal bandwidth (the low-IF band after dechirping). It does not affect the amplitude spectrum of the beat signals. Each target/transmitter's beat tone passes through unchanged in magnitude; only the phase is modified to realign the codes.

The FMCW range-frequency mapping f_b = S*delta remains intact. The beat frequency still encodes the delay. The only change is that the code modulation is removed.

---

## 5. Walsh / Code-Family Assessment

### 5.1 Separating Code-Family Limitation from Receiver-Architecture Limitation

**Is the failure caused by Walsh codes being a poor code family?**

No. The failure occurs because the simple despreader does not compensate for the frequency-dependent code delay. Any binary code family (Walsh, Gold, Kasami, m-sequence) would exhibit the same failure under these conditions, because the root cause is the beat-frequency phase rotation breaking the chip-level orthogonality sum.

**Walsh codes are acceptable for the ideal receiver study** because:

1. They provide exact zero cross-correlation at zero lag (chip-aligned, zero beat offset).
2. They are deterministic and easy to construct at any power-of-2 length.
3. The group-delay filter restores the zero-lag condition by realigning the codes.
4. The literature (Uysal, Kumbul, Lampel) all use Walsh/Hadamard or similar structured codes.

### 5.2 When Would a Code Family Change Be Necessary?

A different code family would be needed if:

- The system required good partial-correlation properties (robustness to timing uncertainty without a group-delay filter). Gold codes or Zadoff-Chu sequences would be superior here.
- The system operated with asynchronous transmitters where chip boundaries are unknown.

Neither applies to our scenario.

**Recommendation:** Keep Walsh-Hadamard for the next experiment. The code family is not the limitation.

---

## 6. Chip Rate / Code Length Analysis

### 6.1 Phase Rotation Analysis

For the current simulation parameters, the beat phase rotation per chip is:

```
Delta_phi_chip = 2*pi * f_b * T_chip = 2*pi * (S*delta) * (T_obs/L) = 2*pi * S * delta * T_obs / L
```

Substituting S = 29.982e12 Hz/s, T_obs = 25.6 us:

For station A (delta_A = 3 ns, f_A = 89,946 Hz):

| L | T_chip (us) | Delta_phi (rad) | Delta_phi (deg) | Assessment |
|---|---|---|---|---|
| 2 | 12.8 | 7.23 | 414 | > full cycle -- catastrophic |
| 4 | 6.4 | 3.62 | 207 | > half cycle -- severe |
| 8 | 3.2 | 1.81 | 104 | ~ quarter cycle -- significant |
| 16 | 1.6 | 0.904 | 52 | ~ 1/7 cycle -- moderate |
| 32 | 0.8 | 0.452 | 26 | not testable (N=256, L=32, N_chip=8) |
| 128 | 0.2 | 0.113 | 6.5 | not testable (N_chip=2) |

For station B (delta_B = 7 ns, f_B = 209,874 Hz):

| L | T_chip (us) | Delta_phi (rad) | Delta_phi (deg) |
|---|---|---|---|
| 2 | 12.8 | 16.88 | 967 |
| 4 | 6.4 | 8.44 | 484 |
| 8 | 3.2 | 4.22 | 242 |
| 16 | 1.6 | 2.11 | 121 |

### 6.2 When Would Naive Despreading Work?

Naive despreading (without group-delay compensation) would succeed when Delta_phi_chip << pi, i.e., when the beat phase rotation within a chip is negligible. This requires:

```
f_b * T_chip << 0.5   ->   T_chip << 1/(2*f_b)
```

For f_A = 89.9 kHz: T_chip << 5.6 us -> need L >> T_obs/5.6us ~ 4.6 -> roughly L >= 16 or higher.

For f_B = 209.9 kHz: T_chip << 2.4 us -> need L >> T_obs/2.4us ~ 10.7 -> roughly L >= 32 or higher.

But at L=32 with N=256, we get only 8 samples per chip -- marginal for frequency estimation within each chip. And at L=128, only 2 samples per chip -- essentially unusable.

### 6.3 Conclusion

**Increasing code length within the current observation window cannot solve the problem.** The beat frequencies are too high relative to the available T_obs for chip-rate despreading to work without delay compensation. The group-delay filter is the correct solution.

---

## 7. Proposed Minimal Next Simulation

### 7.1 Architecture

The minimum receiver that can test whether delay compensation solves the separation failure:

```
Composite received signal
    |
    v
Dechirp (existing V0/V1 model)
    |
    v
Group-delay filter:  H_gd(f) = exp(-j*pi*f^2/S)
    |
    v
Despread with aligned code c_i(t)  [aligned at t=0, NOT shifted]
    |
    v
Beat frequency estimation (existing phase-slope estimator)
```

### 7.2 Preserved Constraints

- Analytic complex-baseband FMCW (existing fmcw_baseband, fmcw_delayed_baseband)
- Continuous fractional delay (no sample-rate quantization)
- Current V0/V1 truth model frozen
- Rectangular binary phase codes (Walsh-Hadamard)
- No AWGN, CFO, clock skew, or phase noise
- Same test scenarios: alpha_A = 1.0, alpha_B = 0.3, delta_A = 3 ns, delta_B = 7 ns

### 7.3 Implementation: Group-Delay Filter

In the frequency domain, the filter is trivially applied:

```matlab
Z = fft(z_dechirped);
f = (0:N-1)' * Fs / N;   % frequency axis
H_gd = exp(-1j * pi * f.^2 / S);
z_filtered = ifft(Z .* H_gd);
```

This is a single FFT-multiply-IFFT operation. No iterative optimization or parameter tuning.

### 7.4 Expected Outcome

After group-delay filtering:
- All codes are realigned to t = 0.
- Despreading with c_B(t) (unshifted) should cleanly isolate station B's beat.
- The cross-code product c_A(t)*c_B(t) restores Walsh orthogonality.
- f_B_hat approximately equals S*delta_B with sub-Hz accuracy (same as V0/V1 single-link).

### 7.5 Key Question This Answers

> Can a delay-aware PC-FMCW receiver recover both beats from the alpha_A = 1.0, alpha_B = 0.3 composite signal?

If yes: the receiver architecture was the limitation, not the code or the physics.
If no: additional investigation needed (dispersion effects, edge effects, code-length dependence of the filter).

---

## 8. Staged Oracle -> Estimated-Delay -> Acquisition Roadmap

### 8.1 Stage 1: Group-Delay Filter (Recommended Next Step)

The group-delay filter H_gd(f) = exp(-j*pi*f^2/S) does NOT require knowledge of the true delay. It is a fixed, target-independent filter that depends only on the chirp slope S. This is a critical distinction:

> **The group-delay filter is NOT an oracle.** It is a fixed filter applied to the dechirped signal before despreading. It does not use knowledge of individual target delays.

The despreading code template c_i(t) is applied at t=0 (unshifted), because the filter has already compensated for the frequency-dependent code delay.

**Stage 1 implementation does not require delay estimation.** This is the cleanest first test.

### 8.2 Stage 2: Estimated-Delay Receiver (Without Group-Delay Filter)

An alternative to the group-delay filter: estimate delta from the beat frequency (e.g., FFT peak detection), then construct a delay-shifted code template c_i(t - delta_hat) for despreading. This is essentially what the current V2b align_code does.

This approach has a circularity problem in the multi-transmitter case: you need to know which beat belongs to which transmitter before you can estimate its delay, but you need the delay to despread the code to identify the transmitter.

The group-delay filter avoids this circularity entirely.

### 8.3 Stage 3: Joint Acquisition

For a practical system, the receiver must:

1. Apply the group-delay filter (fixed, known S).
2. Despread with each candidate code.
3. Detect peaks in the despreaded spectrum.
4. Associate peaks with transmitter identities.

This is standard matched-filter detection. No joint optimization is needed in the ideal case.

---

## 9. AWR2944 Intra-Chirp Coding Feasibility

### 9.1 Literature PC-FMCW: Intra-Chirp Phase Transitions

The literature (Uysal, Kumbul, Lampel) assumes multiple phase transitions within a single chirp ramp. A chirp of duration T is divided into L chips, each with an independent binary phase value. The phase transitions occur at rates of 1/T_chip, which can be MHz-class.

### 9.2 AWR2944 Capability: Per-Chirp Phase Only

From TI documentation (TRM RevD, Chirp Programming Guide, MIMO Radar App Note):

- The AWR2944 supports a per-chirp TX phase shifter with 6-bit resolution (5.625 deg steps).
- Phase values are configured per chirp in the chirp sequence, applied at chirp boundaries.
- This is the mechanism used for BPM-MIMO and TDM-MIMO.
- Phase changes during an active chirp ramp are NOT documented as a supported operating mode.
- The PLL-based chirp generator produces a continuous frequency sweep; interrupting it with phase transitions could corrupt the ramp.

### 9.3 What Is NOT Established

Not confirmed from available TI documentation:
- Arbitrary phase modulation within a single chirp ramp at sub-chirp rates.
- Phase shifter settling time during an active sweep.
- Whether the rlSetAdvChirpCfg API permits intra-chirp phase updates.

Explicit constraint: The AWR2944 phase shifter reconfiguration requires firmware-level command processing with latencies of ~500 us, which is longer than typical chirp durations (10-100 us). **Intra-chirp phase coding at chip rates of MHz is not feasible on the AWR2944 as documented.**

### 9.4 Per-Chirp (Slow-Time) Coded Alternative

A hardware-compatible alternative:

- Apply a binary phase code across chirps rather than within a single chirp.
- Each chirp in a burst gets a phase of 0 deg or 180 deg via the TX phase shifter.
- The code sequence spans L chirps, not L chips within one chirp.
- This is conceptually identical to BPM-MIMO and is fully supported.

Trade-off: Per-chirp coding operates in slow time. It provides inter-chirp node identity (Doppler-domain separation) but does NOT provide intra-chirp interference rejection in fast time (range domain). A different set of processing is required (slow-time code correlation after range-FFT, rather than fast-time group-delay filtering).

### 9.5 Summary

| Feature | Literature PC-FMCW | AWR2944 |
|---|---|---|
| Coding domain | Fast time (intra-chirp) | Slow time (per-chirp) |
| Phase transitions per chirp | L (many) | 1 (chirp boundary only) |
| Group-delay filter applicable | Yes | Not applicable (slow-time coding) |
| Separation mechanism | Range-domain despreading | Doppler-domain despreading |
| TI documentation confirms | N/A | Yes (BPM-MIMO) |

**The simulation models intra-chirp coding per the literature. Mapping to AWR2944 hardware requires a per-chirp coded alternative, which is a separate modeling branch (future work).**

---

## 10. Acceptance Tests for Future Implementation

### 10.1 Single Coded Node

| ID | Test | Expected |
|---|---|---|
| G01 | Single coded TX, group-delay filter + despread with correct code | f_hat = S*delta to rel_err < 1e-10 |
| G02 | Single coded TX, no filter, despread with correct aligned code | f_hat = S*delta (same as current V2b P09) |
| G03 | Coding disabled (all-ones code) with filter | Reproduces uncoded V0/V1 beat |

### 10.2 Two Equal-Amplitude Coded Nodes

| ID | Test | Expected |
|---|---|---|
| G04 | Two coded TXs, equal amplitude, filter + despread A | f_A_hat = S*delta_A, rel_err < 1e-10 |
| G05 | Two coded TXs, equal amplitude, filter + despread B | f_B_hat = S*delta_B, rel_err < 1e-10 |
| G06 | Wrong-code leakage power after filter | Should be > 20 dB below correct |

### 10.3 Strong/Weak Separation (Critical)

| ID | Test | Expected |
|---|---|---|
| G07 | alpha_A=1.0, alpha_B=0.3, filter + despread A | f_A_hat = S*delta_A, rel_err < 1e-10 |
| G08 | alpha_A=1.0, alpha_B=0.3, filter + despread B | f_B_hat = S*delta_B, rel_err < 1e-6 (weak node) |
| G09 | SIR after despreading with filter vs without filter | Filter SIR >> no-filter SIR |

### 10.4 Code Misalignment and Delay Compensation

| ID | Test | Expected |
|---|---|---|
| G10 | Filter + unshifted code template gives correct beat | Verifies filter realigns codes |
| G11 | No filter + shifted code template vs filter + unshifted | Both produce same f_hat |
| G12 | Deliberate wrong shift (no filter) causes degradation | Expected per current V2b results |

### 10.5 TWTT Integration

| ID | Test | Expected |
|---|---|---|
| G13 | Coded TWTT with filter: tau and theta recovery | tau_err < 1e-14 s, theta_err < 1e-14 s |
| G14 | Coded TWTT without filter: regression to current V2b | Same results as current implementation |

### 10.6 Regression

| ID | Test | Expected |
|---|---|---|
| G15 | All V0/V1 tests unchanged | 13 tests pass |
| G16 | All V2a CFO tests unchanged | Existing pass count maintained |
| G17 | filter(code=all-ones) = identity on uncoded beat | Regression to V0/V1 |

### 10.7 No Oracle Dependency

| ID | Test | Expected |
|---|---|---|
| G18 | Group-delay filter uses only S (not true delta) | Filter construction independent of target |
| G19 | Despreading uses unshifted code c_i(t) after filter | No oracle delay knowledge |

> **IMPORTANT:** Do NOT weaken acceptance thresholds for G07/G08. If the group-delay filter does not recover the weak-node beat at alpha_B = 0.3, that is a genuine finding and must be reported honestly.

---

## 11. Unresolved Questions

1. **Edge effects:** The group-delay filter may introduce transient artifacts at the start/end of the observation window. How significant are these for N=256?

2. **Filter fidelity at low sample count:** With N=256 samples and Fs=10 MHz, the frequency resolution is 39 kHz. The filter's quadratic phase varies as pi*f^2/S. At f = Fs/2 = 5 MHz, the phase is pi*(5e6)^2/(29.982e12) = 2.62 rad. The filter should be well-behaved, but edge cases need numerical verification.

3. **Dispersion of code transitions:** The group-delay filter disperses the code waveform (Kumbul's concern). For rectangular codes with T_chip = 12.8 us (L=2), the code bandwidth is ~78 kHz, and the differential group delay across this bandwidth is 78e3/S = 2.6 ps -- negligible. For L=16, code bandwidth is ~625 kHz, differential group delay is ~21 ps -- still negligible at our sample rate.

4. **Frequency axis convention:** The FFT frequency axis wraps at Fs. The group-delay filter phase must handle negative frequencies correctly (typically by using the wrapped frequency axis or applying the filter symmetrically).

5. **Per-chirp coding for AWR2944:** What is the minimum model for slow-time coded FMCW that preserves some of the multi-user separation benefits? This is a separate analysis.
