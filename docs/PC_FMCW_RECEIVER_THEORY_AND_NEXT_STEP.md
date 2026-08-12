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

The receiver dechirps using our frozen convention `z = LO .* conj(RX)`:

```
z(t) = s_LO(t) * conj(r(t))
```

where `s_LO(t) = exp(j*pi*S*t^2)`. Expanding for real +/-1 codes (conj(c_i) = c_i):

```
z(t) = alpha_A * beat_A(t) * c_A(t - delta_A)
     + alpha_B * beat_B(t) * c_B(t - delta_B)
```

where the uncoded beat signal is:

```
beat_i(t) = exp(j*pi*S*t^2) * conj(exp(j*pi*S*(t-delta_i)^2))
          = exp(j*pi*S*[t^2 - (t-delta_i)^2])
          = exp(j*2*pi*S*delta_i*t - j*pi*S*delta_i^2)
          = exp(j*2*pi*f_i*t + j*phi_0_i)
```

with `f_i = +S*delta_i` (positive beat frequency) and `phi_0_i = -pi*S*delta_i^2`.

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
I(t) = alpha_A * exp(j*2*pi*f_A*t + j*phi_0_A) * c_A(t - delta_A) * c_B(t - delta_B)
```

The cross-code product `c_A(t - delta_A) * c_B(t - delta_B)` is evaluated at each sample t, weighted by the beat-frequency complex exponential `exp(j*2*pi*f_A*t)`.

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

Even at L=16, the beat rotates by 52 degrees per chip. The weighted orthogonality sum is significantly corrupted at every code length tested in V2b.

For station B (delta_B = 7 ns, f_B = 209,874 Hz):

| L | T_chip (us) | Delta_phi (rad) | Delta_phi (deg) |
|---|---|---|---|
| 2 | 12.8 | 16.88 | 967 |
| 4 | 6.4 | 8.44 | 484 |
| 8 | 3.2 | 4.22 | 242 |
| 16 | 1.6 | 2.11 | 121 |

### 2.3 Why SIR Improves but Beat Recovery Fails

Increasing L improves SIR because the cross-code product distributes interference across more spectral bins. However, the interference is not spread into incoherent noise; it is phase-modulated at the beat frequency, producing structured residual energy concentrated near f_A +/- k/T_chip.

This structured interference corrupts the phase-slope estimator's least-squares fit, even when the spectral peak at f_B is correctly located.

### 2.4 Code Delay Misalignment (Secondary Effect)

For delta_A = 3 ns and delta_B = 7 ns, the differential delay is 4 ns. With T_chip = 12.8 us (L=2), the misalignment is 4 ns / 12.8 us = 3.1e-4 chips. This is negligible. **The primary failure mechanism is beat-frequency phase rotation, not code misalignment.**

### 2.5 Root Cause Summary

> The simple chip-rate despreader fails because after dechirping, the beat frequency imposes a fast-rotating complex exponential that breaks the code orthogonality sum at the chip level. This is a receiver architecture limitation, not a code-family limitation. Any binary code family would exhibit the same failure under these conditions.

---

## 3. Literature Receiver Equations

### 3.1 Uysal (2020) Group-Delay Filter Receiver

Reference: F. Uysal, "Phase-Coded FMCW Automotive Radar: System Design and Interference Mitigation," IEEE Trans. Vehicular Technology, 2020.

After dechirping, the beat signal carries the phase code delayed by the target delay delta:

```
z(t) = beat(t) * c(t - delta)
```

The beat frequency f_b = S*delta maps delay to frequency. Different targets at different delays produce beat signals at different frequencies, each carrying the same code but shifted by different amounts. The code misalignment is frequency-dependent: delta = f_b / S.

Uysal proposes a group-delay filter H_gd(f) that applies a frequency-dependent delay to realign all copies of the code to a common time reference, enabling code removal/despreading after filtering.

### 3.2 Kumbul (2022) Smoothed PC-FMCW

Reference: U. Kumbul et al., "Smoothed Phase-Coded FMCW: Waveform Properties and Transceiver Architecture," IEEE Trans. Aerospace and Electronic Systems, 2022.

Kumbul identifies that the group-delay filter introduces a quadratic phase across the code bandwidth, which disperses the rectangular code waveform. The proposed solutions are:

1. Transmit smoothed codes: replace abrupt +/-1 transitions with Gaussian-smoothed transitions.
2. Pre-compensate dispersion: apply quadratic phase pre-distortion to the transmitted code.

This confirms that group-delay filter dispersion is a recognized engineering concern, not a negligible effect. See Section 4.6 for quantitative analysis in our system.

### 3.3 Lampel (2020) System-Level Synchronization

Reference: F. Lampel et al., "System Level Synchronization of Phase-Coded FMCW Automotive Radars for RadCom," EuCAP, 2020.

Lampel addresses time-of-arrival estimation for coarse synchronization of PC-FMCW systems. Confirms the group-delay filter as the standard receiver component for code recovery.

---

## 4. Group-Delay Filter Derivation in Our Convention

### 4.1 Signal Model

Our frozen convention: `z = LO .* conj(RX)`.

For a single coded transmitter at delay delta, the dechirped signal is:

```
z(t) = exp(j*2*pi*f_b*t + j*phi_0) * c(t - delta)
```

where f_b = +S*delta and phi_0 = -pi*S*delta^2.

### 4.2 Fourier Transform (MATLAB Convention)

Using the MATLAB Fourier convention `X(f) = integral x(t) exp(-j*2*pi*f*t) dt`:

Let w(t) = c(t - delta). By the time-shift theorem:

```
W(f) = C(f) * exp(-j*2*pi*f*delta)
```

where C(f) = FT{c(t)}.

The dechirped signal `z(t) = A * exp(j*2*pi*f_b*t) * w(t)` (where A = exp(j*phi_0)) has transform:

```
Z(f) = A * W(f - f_b)                                [frequency-shift theorem]
     = A * C(f - f_b) * exp(-j*2*pi*(f - f_b)*delta)
```

### 4.3 Substituting delta = f_b / S

Since delta = f_b / S:

```
Z(f) = A * C(f - f_b) * exp(-j*2*pi*(f - f_b)*f_b/S)
```

Let nu = f - f_b (offset from beat frequency). The spectrum near f_b is:

```
Z(f_b + nu) = A * C(nu) * exp(-j*2*pi*nu*f_b/S)
```

The factor `exp(-j*2*pi*nu*f_b/S)` is the code-delay phase. It is LINEAR in nu (producing a time shift of the code spectrum) and LINEAR in f_b (the shift depends on beat frequency).

### 4.4 Required Filter

We need a filter H(f) such that after application, the linear-in-nu code-delay phase is cancelled for every beat frequency f_b simultaneously.

After filtering:

```
Z_filtered(f_b + nu) = A * C(nu) * exp(-j*2*pi*nu*f_b/S) * H(f_b + nu)
```

Write H(f) = exp(j*Phi(f)). Near f = f_b + nu, expand Phi(f_b + nu) in powers of nu:

```
Phi(f_b + nu) = Phi(f_b) + Phi'(f_b)*nu + (1/2)*Phi''(f_b)*nu^2 + ...
```

The linear-in-nu contribution from H is `Phi'(f_b)*nu`. To cancel the code-delay phase `-2*pi*nu*f_b/S`, we need:

```
Phi'(f_b) = +2*pi*f_b/S      for all f_b
```

Integrating with respect to f:

```
Phi(f) = +pi*f^2/S + C_0
```

Therefore:

```
H(f) = exp(+j*pi*f^2/S)                  [FROZEN]
```

(The additive constant C_0 produces a global phase; it does not affect code alignment or frequency estimation.)

### 4.5 Group Delay

```
tau_g(f) = -(1/(2*pi)) * d(angle(H))/df
         = -(1/(2*pi)) * d(+pi*f^2/S)/df
         = -(1/(2*pi)) * (2*pi*f/S)
         = -f/S
```

The group delay is NEGATIVE for positive f. This means the filter ADVANCES positive-frequency components. A beat at frequency f_b is advanced by f_b/S = delta in time, which compensates the code delay.

Since tau_g(f) = -f/S is non-causal (negative for f > 0), this filter cannot be implemented as a real-time analog filter. However, it is straightforward to implement digitally via FFT-multiply-IFFT, where causality is not required.

### 4.5.1 Optional Bulk Delay

An arbitrary constant delay tau_0 can be added without changing code alignment:

```
H(f) = exp(+j*pi*f^2/S) * exp(-j*2*pi*f*tau_0)
```

This gives:

```
tau_g(f) = tau_0 - f/S
```

All codes are shifted by the same tau_0, so chip boundaries remain mutually aligned after despreading. Choosing tau_0 >= f_max/S makes the effective group delay non-negative everywhere, if needed for physical interpretation. The FFT-based implementation does not require this.

### 4.6 Residual Quadratic Phase (Code Dispersion)

After filtering, the residual phase at offset nu from the beat frequency is:

```
residual phase = +(pi*nu^2/S)
```

This is a quadratic phase across the code bandwidth. In the time domain, it disperses the code waveform.

The code bandwidth is approximately `BW_code ~ 1/T_chip`. The differential group delay across the code bandwidth is:

```
Delta_tau_code = |tau_g(f_b + BW_code/2) - tau_g(f_b - BW_code/2)| = BW_code / S
```

For S = 29.982e12 Hz/s:

| L | T_chip | BW_code = 1/T_chip | Delta_tau_code = BW_code/S | In ns |
|---|---|---|---|---|
| 2 | 12.8 us | 78.125 kHz | 2.606e-9 s | 2.606 ns |
| 4 | 6.4 us | 156.25 kHz | 5.212e-9 s | 5.212 ns |
| 8 | 3.2 us | 312.50 kHz | 10.42e-9 s | 10.42 ns |
| 16 | 1.6 us | 625.00 kHz | 20.85e-9 s | 20.85 ns |

At Fs = 10 MHz (sample period = 100 ns):

| L | Delta_tau_code (ns) | Fraction of sample period | Fraction of T_chip |
|---|---|---|---|
| 2 | 2.606 | 0.026 | 2.04e-4 |
| 4 | 5.212 | 0.052 | 8.14e-4 |
| 8 | 10.42 | 0.104 | 3.26e-3 |
| 16 | 20.85 | 0.209 | 1.30e-2 |

For L=2, the dispersion is 2.6% of one sample period and 0.02% of T_chip — small but measurable. For L=16, the dispersion is 20.9% of one sample period and 1.3% of T_chip. The dispersion does NOT alias (it is sub-sample) but it distorts the code transition shape in the digital domain.

The first implementation uses rectangular codes and does NOT pre-compensate this dispersion. This is an intentionally uncompensated Stage-1 experiment. The dispersion must be measured, not assumed negligible. If it degrades code separation, Kumbul-style smoothing becomes necessary for Stage 2.

---

## 5. What the Filter Fixes and What It Does NOT Fix

### 5.1 After Filtering: Corrected Composite Signal

After applying H(f) = exp(+j*pi*f^2/S) to the dechirped composite signal:

```
z_filtered(t) = alpha_A * exp(j*2*pi*f_A*t + j*psi_A) * c_A_disp(t)
              + alpha_B * exp(j*2*pi*f_B*t + j*psi_B) * c_B_disp(t)
```

where psi_A, psi_B are deterministic phase constants (from phi_0 and the filter's constant term at each f_b), and c_i_disp(t) denotes the code waveform after group-delay filtering, which includes the residual quadratic phase dispersion from Section 4.6.

In the ideal narrow-code-bandwidth limit (dispersion negligible), c_i_disp(t) -> c_i(t).

### 5.2 Despreading with c_B(t) After Filtering

```
z_B(t) = z_filtered(t) * c_B(t)
       = alpha_B * exp(j*2*pi*f_B*t + j*psi_B) * c_B_disp(t) * c_B(t)     [desired]
       + alpha_A * exp(j*2*pi*f_A*t + j*psi_A) * c_A_disp(t) * c_B(t)     [interferer]
```

**Desired term:** If dispersion is negligible, c_B_disp(t) * c_B(t) = |c_B|^2 = 1 and the desired term is a clean tone at f_B.

**Interferer term:** c_A_disp(t) * c_B(t) is a +/-1 switching sequence with aligned chip boundaries (both codes are referenced to t=0 after filtering). This sequence modulates the interfering beat, producing:

```
I_filtered(t) = alpha_A * exp(j*2*pi*f_A*t) * c_AB(t)
```

where c_AB(t) = c_A(t) * c_B(t) is a +/-1 sequence.

### 5.3 What the Filter Fixes

1. Code alignment: all codes are referenced to t=0, not to their individual delays.
2. The cross-code product c_AB(t) now has aligned chip boundaries.
3. The despreading code c_B(t) can be applied WITHOUT knowledge of individual delays.

### 5.4 What the Filter Does NOT Fix

The interfering term I_filtered(t) = alpha_A * exp(j*2*pi*f_A*t) * c_AB(t) is NOT eliminated. Aligning the codes enables proper chip-level orthogonality, but the orthogonality operates on a code-domain sum, not on the instantaneous product.

In the spectral domain, the interferer is a tone at f_A modulated by the +/-1 sequence c_AB(t). This spreads the interference from a single spectral line at f_A into L spectral lines at f_A + k/T_chip (k = 0, ..., L-1 modulo the DFT structure). The spreading provides a processing gain of approximately L in power.

The post-despreading SIR at the desired bin f_B (assuming f_B does not coincide with an interference sidelobe) is approximately:

```
SIR_B ~ (alpha_B^2 * L) / alpha_A^2     [if the L spread bins do not overlap f_B]
```

For alpha_A = 1.0, alpha_B = 0.3:

| L | SIR_B (linear) | SIR_B (dB) |
|---|---|---|
| 2 | 0.18 | -7.4 |
| 4 | 0.36 | -4.4 |
| 8 | 0.72 | -1.4 |
| 16 | 1.44 | +1.6 |
| 32 | 2.88 | +4.6 |
| 64 | 5.76 | +7.6 |
| 128 | 11.52 | +10.6 |

At L=2, the interference dominates the desired signal by 7.4 dB. At L=16, SIR is barely positive. **Clean weak-node recovery at alpha_B/alpha_A = 0.3 requires either large L (> 32) or a spectral estimator that can tolerate moderate interference.**

This is the fundamental processing-gain constraint of code-domain multi-access. The group-delay filter enables it to work properly; it does not circumvent the power budget.

---

## 6. Estimator Analysis

### 6.1 The Phase-Slope Estimator

`estimate_beat_phase_slope` fits a linear phase model phi[n] = m*n + b to the unwrapped instantaneous phase of the input. This is optimal for a single complex sinusoid in noise.

When the input contains a desired tone plus structured interference (a code-modulated beat), the unwrapped phase is NOT linear. The +/-1 code transitions introduce pi-radian phase jumps. The LS fit averages over these jumps, producing a biased frequency estimate whose error depends on the interference structure, not only on its power.

### 6.2 Comparison of Receiver/Estimator Combinations

**A. Naive despreading + phase-slope estimator** (current V2b):
- Codes misaligned by different delays -> poor orthogonality.
- Residual interference corrupts the phase fit.
- Both code misalignment AND phase rotation degrade the estimate.
- **Result:** Frequency estimate corrupted even when spectral peak is identifiable.

**B. Naive despreading + spectral peak estimator (FFT peak detection):**
- Same code misalignment problem as A.
- But the spectral peak may still be identifiable if desired/interference peaks are separated.
- Frequency accuracy limited to FFT bin width (Fs/N = 39.06 kHz) without interpolation.
- **Result:** May correctly locate f_B spectrally, even when phase-slope fails.

**C. Group-delay filter + despreading + spectral peak estimator:**
- Codes properly aligned after filtering.
- Cross-code interference spread across L bins.
- Spectral peak at f_B detectable if SIR > 0 dB at the f_B bin.
- Frequency accuracy limited to FFT bin width without interpolation.
- **Result:** Correct peak detection for L >= ~16 at our amplitude ratio. Coarse frequency estimate.

**D. Group-delay filter + despreading + phase-slope estimator:**
- Same filtering and despreading as C.
- Phase-slope fit on the despread signal, which contains a desired tone plus L spread interference lines.
- The phase-slope estimator is sensitive to the interference structure.
- Works well only when SIR >> 0 dB (i.e., the desired tone dominates the signal).
- **Result:** Accurate f_B only when SIR is high enough that the interference is negligible to the phase fit. This may require L >> 16 at our amplitude ratio.

### 6.3 Recommendation

The next implementation must distinguish receiver failure from estimator failure:

1. Report both spectral peak frequency and phase-slope frequency.
2. Report SIR at the desired bin.
3. Use spectral peak detection as the primary estimator for the multi-node case.
4. Reserve phase-slope estimation for the single-node and high-SIR regimes where it is valid.

Do not apply the phase-slope estimator directly to a composite despread signal and interpret its failure as a coding failure.

---

## 7. Chip Rate / Code Length Analysis

### 7.1 Phase Rotation Analysis

The beat phase rotation per chip for station A (f_A = 89,946 Hz) was tabulated in Section 2.2. Naive despreading succeeds when Delta_phi_chip << pi, requiring T_chip << 1/(2*f_A).

### 7.2 Sampled-Time Constraints for Code Length

The actual constraints on L are:

1. **Chip representation:** Each chip requires at least N_chip = N/L samples. At N_chip = 1 (L = N = 256), the code is a single sample per chip, which is the Nyquist limit for representing the code waveform. Practically, N_chip >= 4 is preferred for clean rectangular transitions. But frequency estimation uses the full N-sample observation, not per-chip sub-records.

2. **Code bandwidth:** BW_code ~ 1/T_chip. This must not exceed Fs/2 = 5 MHz to avoid code aliasing. T_chip >= 200 ns -> L <= T_obs / 200e-9 = 128. All values L = 2, 4, ..., 128 satisfy this constraint.

3. **Transition timing:** For rectangular codes sampled at Fs, chip transitions occur exactly at sample boundaries when N is divisible by L. This is satisfied for all power-of-2 L up to L = 256.

4. **Finite record length:** The DFT frequency resolution is Fs/N = 39.06 kHz. Beat frequencies must be resolvable at this resolution. This is independent of L.

5. **Group-delay filter dispersion:** Increases with L per Section 4.6. At L=16, dispersion is 20.9% of one sample period. At L=128, dispersion would be 1.67 sample periods — comparable to one full sample, requiring careful treatment.

### 7.3 Code Length and Naive Despreading

L=32 (8 samples/chip) is testable. Frequency estimation is performed over all 256 samples, not within each chip. The prior statement that L=32 is "marginal for frequency estimation" was incorrect; 8 samples per chip is adequate for code representation, and frequency estimation operates on the full record.

### 7.4 Conclusions (Limited to Demonstrated Range)

Within the V2b-tested range L = 2, 4, 8, 16:
- SIR increases with L (approximately +5 dB per doubling).
- Weak-node beat recovery by the phase-slope estimator fails at all tested L values.

For L = 32, 64, 128: not yet tested. Analytic estimates suggest:
- Naive despreading SIR may become adequate at L >= 32 for spectral peak detection (SIR > 0 dB).
- Phase-slope estimation may require L >= 64 or higher.
- Group-delay filter dispersion becomes non-negligible at L >= 16.

These must be verified numerically, not assumed.

---

## 8. Proposed Minimal Next Simulation

### 8.1 Architecture

```
Composite received signal
    |
    v
Dechirp (existing V0/V1 model: z = LO .* conj(RX))
    |
    v
Group-delay filter:  H(f) = exp(+j*pi*f^2/S)        [POSITIVE sign]
    |
    v
Despread with unshifted code c_i(t)   [aligned at t=0]
    |
    v
Spectral peak detection (primary) + phase-slope estimation (diagnostic)
```

### 8.2 Preserved Constraints

- Analytic complex-baseband FMCW (existing fmcw_baseband, fmcw_delayed_baseband)
- Continuous fractional delay (no sample-rate quantization)
- Current V0/V1 truth model frozen
- Rectangular binary phase codes (Walsh-Hadamard)
- No AWGN, CFO, clock skew, or phase noise
- Same test scenarios: alpha_A = 1.0, alpha_B = 0.3, delta_A = 3 ns, delta_B = 7 ns

### 8.3 FFT Implementation Convention

#### 8.3.1 Signed Frequency Vector (MATLAB FFT Natural Order)

The N-point DFT assigns bin k to frequency f[k] = k*Fs/N for k = 0, ..., N-1. Bins k > N/2 represent negative frequencies. The signed frequency vector in MATLAB FFT natural order is:

```matlab
f_signed = (0:N-1).' * Fs / N;
f_signed(f_signed > Fs/2) = f_signed(f_signed > Fs/2) - Fs;
```

Equivalently:

```matlab
f_signed = [0:N/2-1, -N/2:-1].' * Fs / N;
```

For N = 256, Fs = 10 MHz: f_signed ranges from 0 to +4.961 MHz (bins 0-127), then -5.000 MHz to -39.06 kHz (bins 128-255).

#### 8.3.2 Filter Evaluation

The group-delay filter is evaluated at signed frequencies:

```matlab
H = exp(+1j * pi * f_signed.^2 / S);
```

Since f^2 is symmetric (f^2 = (-f)^2), the filter phase is the same for positive and negative frequencies. The group delay tau_g(f) = -f/S is antisymmetric: positive frequencies are advanced, negative frequencies are delayed. This is the correct physical behavior for an all-pass dispersive filter.

#### 8.3.3 Circular vs Linear Filtering

The FFT-multiply-IFFT operation implements circular convolution. Wrap-around artifacts occur when the filter's impulse response duration exceeds the guard region.

The maximum differential group delay across the band is:

```
|tau_g(Fs/2) - tau_g(0)| = Fs/(2*S) = 5e6/(2*29.982e12) = 83.4 ns
```

This is 0.834 sample periods at Fs = 10 MHz.

For N = 256, this means the filter spreads the signal by less than 1 sample at the edges. Circular filtering introduces wrap-around affecting at most 1-2 samples at the boundaries.

**Implementation choice:** Use circular filtering (direct FFT-multiply-IFFT) without zero-padding. Crop the first and last `N_guard = ceil(Fs/(2*S) * Fs) + 1 = 2` samples from the filtered output if edge effects are observed. Verify numerically that the cropped region does not affect the estimator.

If edge effects prove significant, the fallback is:
1. Zero-pad the dechirped signal from N to N_pad = 2*N = 512.
2. Apply the filter at length N_pad.
3. Discard the guard region and retain the central N samples.

The implementation must report whether zero-padding was used and whether the crop region affected the result.

#### 8.3.4 fftshift / ifftshift

Not required. The filter H is constructed directly in FFT natural order using f_signed. The input and output of fft/ifft are in natural order throughout. No fftshift or ifftshift operations are used.

### 8.4 Expected Outcome

After group-delay filtering and despreading:

- **Single coded node:** Desired beat recovered exactly (limited by filter dispersion, which is sub-percent for L <= 16).
- **Two coded nodes, equal amplitude:** Both beats recovered via spectral peak detection. The wrong-code interference is spread across L bins, providing ~10*log10(L) dB processing gain.
- **Strong/weak case (alpha_A=1.0, alpha_B=0.3):** Recovery of f_B depends on L and estimator. At L=2, SIR_B ~ -7.4 dB — the weak node is unlikely to be recovered by any estimator. At L=16, SIR_B ~ +1.6 dB — marginal. At L >= 32, SIR_B > 4 dB — spectral peak detection should succeed.

### 8.5 Key Question This Answers

> Does the group-delay filter + spectral estimator recover both beats from the alpha_A = 1.0, alpha_B = 0.3 composite signal, and at what code length?

---

## 9. Staged Roadmap

### 9.1 Stage 1: Group-Delay Filter (Recommended Next Step)

H(f) = exp(+j*pi*f^2/S) is a fixed, target-independent filter depending only on S. It is NOT an oracle: it uses no knowledge of individual target delays.

After filtering, despreading uses unshifted code c_i(t). No delay estimation is required.

This is the cleanest first test because it avoids the circularity of delay-dependent despreading.

### 9.2 Stage 2: Code-Length Sweep With Filter

Test L = 2, 4, 8, 16 (and optionally 32, 64) with the group-delay filter. For each L, report:
- Spectral peak frequency and SIR at the desired bin.
- Phase-slope estimate and residual RMS.
- Dispersion metric: compare c_i_disp(t) against c_i(t).

### 9.3 Stage 3: Dispersion Compensation (If Required)

If Stage 1/2 shows dispersion-limited performance at longer codes, implement Kumbul-style smoothing or quadratic-phase pre-compensation.

### 9.4 Stage 4: Acquisition

Extend to the case where the receiver does not know which codes are present. Search over candidate codes using the group-delay filter + despreading + spectral peak detection.

---

## 10. Walsh / Code-Family Assessment

Walsh-Hadamard codes remain suitable for the next experiment:

1. They provide exact zero cross-correlation at zero lag (chip-aligned, equal-weight sum).
2. The group-delay filter restores the zero-lag condition by realigning codes.
3. The literature (Uysal, Kumbul, Lampel) uses Walsh/Hadamard or equivalent structured codes.
4. The current V2b failure is caused by receiver architecture, not by the code family.

A different code family (Gold, Zadoff-Chu) would be needed only if:
- The system required partial-correlation robustness without a group-delay filter.
- Chip boundaries were asynchronous.

Neither applies. Keep Walsh-Hadamard.

---

## 11. AWR2944 Intra-Chirp Coding Feasibility

### 11.1 Documented Capabilities

From TI primary documentation (TRM RevD, Chirp Programming Guide, TI-MIMO App Note):

- The AWR2944 supports a per-chirp TX phase shifter with 6-bit resolution (5.625-degree steps, 64 settings).
- Phase values are configured per chirp in the chirp sequence, applied at the chirp boundary per the documented ramp location.
- This is the mechanism used for BPM-MIMO and TDM-MIMO.
- Up to 512 unique chirp configurations are supported.

### 11.2 What Is NOT Established

From available primary TI documentation:
- Arbitrary phase modulation within a single chirp ramp at sub-chirp rates is not described as a supported operating mode.
- Phase shifter settling time during an active sweep is not documented.
- Whether the rlSetAdvChirpCfg API permits intra-chirp phase updates is not established.

The PLL-based chirp generator produces a continuous frequency sweep. Phase modulation during the ramp is not described in the standard chirp profile configuration.

### 11.3 Conclusion

**No current primary-source proof exists for arbitrary intra-chirp phase switching on the AWR2944.** The simulation models intra-chirp coding per the literature convention. Whether the AWR2944 can physically execute this is unresolved and would require lower-level mmWaveLink API investigation or direct TI guidance.

### 11.4 Per-Chirp (Slow-Time) Coding

Per-chirp coding (applying a binary phase across chirps, not within a single chirp) is a candidate hardware-compatible future branch. It is NOT proven equivalent to literature fast-time PC-FMCW:

- It operates in slow time (Doppler domain), not fast time (range domain).
- The group-delay filter concept does not directly apply.
- Different processing is required (slow-time code correlation after range-FFT).

This is a feasibility question for future investigation, not a current modeling task.

---

## 12. Acceptance Tests for Future Implementation

### 12.1 Single Coded Node

| ID | Test | Expected | Rationale |
|---|---|---|---|
| G01 | Single coded TX, filter + despread with correct code | f_hat matches S*delta. Rel err determined by filter dispersion; report numerically. | Verifies basic filter + despread chain. |
| G02 | Single coded TX, no filter, despread with correct delay-aligned code | f_hat = S*delta, rel_err < 1e-10 | Regression to current V2b P09. |
| G03 | All-ones code with filter applied to single uncoded beat | Same beat frequency, same magnitude. Filter adds deterministic phase: report angle(z_filtered(t)) - angle(z_unfiltered(t)) and verify it matches the expected quadratic-phase profile. | NOT a sample-by-sample identity test. |

### 12.2 Two Equal-Amplitude Coded Nodes

| ID | Test | Expected | Rationale |
|---|---|---|---|
| G04 | Equal amplitude, filter + despread A, spectral peak | Spectral peak at bin nearest S*delta_A. | Primary estimator. |
| G05 | Equal amplitude, filter + despread B, spectral peak | Spectral peak at bin nearest S*delta_B. | Primary estimator. |
| G06 | Wrong-code SIR after filter | Desired-bin power / wrong-code leakage power > 10*log10(L) - 3 dB (minimum expected processing gain). | Processing-gain verification. |

### 12.3 Strong/Weak Separation (Critical)

| ID | Test | Expected | Rationale |
|---|---|---|---|
| G07 | alpha_A=1.0, alpha_B=0.3, filter + despread A, spectral peak | Peak at S*delta_A bin. Report SIR. | Strong node should always be detectable. |
| G08 | alpha_A=1.0, alpha_B=0.3, filter + despread B, spectral peak | Report: (a) whether peak at S*delta_B is detectable above noise floor; (b) SIR at f_B bin; (c) spectral peak f_hat vs truth. Do NOT require sub-Hz accuracy unless SIR > 10 dB. | Honest report. Failure at low L is expected. |
| G09 | SIR comparison: filter vs no-filter | Report both. Filter SIR should equal or exceed no-filter SIR for every L. | Quantifies filter benefit. |

### 12.4 Code Alignment Verification

| ID | Test | Expected | Rationale |
|---|---|---|---|
| G10 | Single TX: filter + unshifted code gives same f_hat as no-filter + shifted code | f_hat agreement within 1 Hz. | Verifies code realignment equivalence. |
| G11 | Single TX: no filter + deliberately wrong shift -> degradation | f_err > 1% | Current V2b behavior. |

### 12.5 TWTT Integration

| ID | Test | Expected | Rationale |
|---|---|---|---|
| G12 | Coded TWTT with filter: tau and theta recovery | Report tau_err and theta_err. Accuracy depends on SIR and code length; do not require 1e-14 s unless SIR > 20 dB. | Honest TWTT test. |
| G13 | Coded TWTT without filter: regression | Same results as current V2b implementation. | No regression. |

### 12.6 Regression

| ID | Test | Expected | Rationale |
|---|---|---|---|
| G14 | All V0/V1 tests unchanged | 13 tests pass | Frozen baseline. |
| G15 | All V2a CFO tests unchanged | Existing pass count maintained | No regression. |

### 12.7 No Oracle Dependency

| ID | Test | Expected | Rationale |
|---|---|---|---|
| G16 | Group-delay filter constructed using only S | Filter H = exp(+j*pi*f^2/S). No delta in construction. | Structural check. |
| G17 | Despreading uses c_i(t) at t=0 after filter, not c_i(t - delta) | Code template is unshifted. | No oracle delay. |

### 12.8 Dispersion Diagnostic

| ID | Test | Expected | Rationale |
|---|---|---|---|
| G18 | Measure code waveform after filter for L = 2, 4, 8, 16 | Report: max deviation of |c_disp(t)| from 1.0; transition width in samples. | Quantifies dispersion. |

### 12.9 Acceptance Threshold Philosophy

Acceptance thresholds test the MECHANISM (code alignment, spectral spreading, SIR improvement), not floating-point closure. Tests that combine the filter with a multi-node composite signal should report honest SIR and frequency error rather than imposing arbitrary sub-Hz accuracy that may not be achievable at low SIR.

For single-node tests where the signal is a pure tone (no interference), 1e-10 relative frequency accuracy is justified by the phase-slope estimator on N=256 double-precision samples. For multi-node tests, accuracy is limited by SIR and must be derived from the measured interference level.

---

## 13. Unresolved Questions

1. **Dispersion impact:** The residual quadratic phase (Section 4.6) is measurable but its effect on code orthogonality and despreading quality must be determined numerically. At L=16, dispersion is 20.9% of one sample period — this may or may not degrade the cross-code product.

2. **Processing gain sufficiency:** At alpha_B/alpha_A = 0.3, the required SIR for reliable spectral peak detection is approximately 3-6 dB. This requires L >= 16-32 with the group-delay filter. Whether L=16 (our current maximum well-tested length) is sufficient depends on the specific spectral structure of the cross-code interference at the f_B bin.

3. **Spectral structure of cross-code interference:** The spread interference has discrete spectral lines, not uniformly distributed noise. If one of the L spread lines happens to fall near f_B, the local SIR at f_B could be much worse than the average. The locations of the spread lines depend on f_A, T_chip, and the code structure. This must be analyzed case-by-case.

4. **Circular filtering edge effects:** The filter's maximum differential delay is 0.834 sample periods. Empirical verification is needed to determine whether 1-2 guard samples are sufficient.

5. **Per-chirp coding model:** Not addressed in this document. Requires separate analysis with slow-time signal model.
