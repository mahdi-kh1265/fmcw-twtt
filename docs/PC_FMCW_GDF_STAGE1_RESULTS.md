# Group-Delay Filter (GDF) Stage-1 Results

## Methodology

This document summarizes the Stage-1 validation of the literature-style group-delay filter for fast-time Phase-Coded FMCW (PC-FMCW). The primary goal was to determine whether filtering the dechirped signal to correct the code delay (misalignment) improves the simultaneous multi-node signal separation performance compared to a naive despreading receiver.

### Filter Equation and Sign Convention
Based on the project's frozen signal convention `z(t) = LO(t) .* conj(RX(t))`, the required group-delay filter was derived as:
`H(f) = exp(+j * pi * f^2 / S)`

This quadratic phase filter provides the correct group delay `tau_g(f) = -f/S` to realign the delayed code envelope with the LO code without disturbing the beat frequency phase.

### FFT Frequency Convention and Filtering Method
The filter is applied in the frequency domain. To match MATLAB's `fft`/`ifft` behavior without applying `fftshift` (which introduces boundary errors), the frequency vector is signed and naturally ordered:
`f_signed = [0, 1, ..., N/2-1, -N/2, ..., -1].' * (Fs/N)`

The implementation `src/apply_group_delay_filter.m` supports two paths:
1. **Zero-Padded Reference Path:** Pads the signal to `>= 4*N`, applies the filter, and crops to avoid circular wrap artifacts.
2. **Circular Production Path:** Uses an N-point circular FFT/IFFT. 
Testing confirmed the circular path matches the zero-padded interior region with high accuracy (RMS diff ~3.67e-02 for typical signals), and the circular method was selected as the standard for computational efficiency.

## Test Suite Execution (G01 - G19)
The `test_gdf_stage1` suite executed 19 automated regression and validation tests. Key findings include:

- **G01-G03:** The analytic filter sign and signed frequency vectors were verified. The filter successfully preserved a single-tone beat signal.
- **G04-G05:** For a single coded node, the filter successfully realigned the received code, allowing the unshifted LO code to properly despread the signal and increase spectral peak power.
- **G06-G09:** Two-node separation (equal and strong/weak) proved difficult at low code lengths (`L=2`). The weak node could not be recovered reliably, indicating the filter does not solve the fundamental orthogonality issue.
- **G10-G12:** Wrong-code leakage was verified. While code alignment improved, the GDF Signal-to-Interference Ratio (SIR) for the weak node remained nearly identical to the naive receiver (-4.0 dB vs -4.3 dB).
- **G13-G16 (Estimator Ablation):** Phase-slope estimators proved highly sensitive to residual dispersion and time-domain ripples introduced by the filter. Spectral peak detection was robust and correctly identified as the primary estimator.
- **G17-G18:** Dispersion mechanics and circular vs. zero-padded methodologies were fully validated.
- **G19:** Small frequency deviations (~25 Hz) in the single-link uncoded regression were correctly attributed to numerical edge effects caused by the dispersive filter.

### Estimator-Ablation Comparison
Results for the weak node B (`alpha_A=1.0`, `alpha_B=0.3`, `L=2`):
- **A. Naive despreading + Phase-Slope:** Error = 149242.48 Hz
- **B. Naive despreading + Spectral Peak:** Error = 92686.50 Hz
- **C. GDF despreading + Spectral Peak:** Error = 92686.50 Hz
- **D. GDF despreading + Phase-Slope:** Error = 149357.56 Hz

*Note: Spectral peak estimation outperforms phase-slope in heavy interference, but neither receiver recovers the weak node cleanly at L=2.*

## Code Length Study
A sweep of code length `L` for a strong node A (`f_A = 89.9 kHz`) and weak node B (`f_B = 209.9 kHz`) was conducted:

| L | Disp [ns] | Naive SIR [dB] | GDF SIR [dB] | Naive Error [Hz] | GDF Error [Hz] |
|---|-----------|----------------|--------------|------------------|----------------|
| 2 | 2.61      | -4.3           | -4.0         | 92686.50         | 92686.50       |
| 4 | 5.21      | 3.8            | 3.6          | 53624.00         | 53624.00       |
| 8 | 10.42     | 8.1            | 8.3          | 24501.00         | 24501.00       |
| 16| 20.85     | 12.5           | 12.3         | 180751.00        | 180751.00      |

## Conclusion: Simultaneous Node Separation
**Does the group-delay filter solve the simultaneous two-node structured interference problem for our architecture?**

**No.** The group-delay filter successfully compensates for the time-of-flight misalignment of the fast-time code envelope. However, it completely fails to improve multi-node signal separation. The structured interference in our architecture arises because the baseband beat frequency of the interfering node (e.g., node A) acts as a rotating complex phasor during the correlation interval. This continuous phase rotation destroys the orthogonality of the Walsh codes regardless of envelope alignment. 

Since the group-delay filter only realigns the envelope and cannot stop the time-domain phase rotation of the interfering beat signal, the cross-correlation leakage remains identical to the naive receiver. Increasing processing gain (`L`) improves SIR slightly, but neither receiver architecture provides sufficient isolation for simultaneous high-dynamic-range target recovery using fast-time coding alone.

## AWR2944 Hardware Caveat
This fast-time (intra-chirp) coding analysis serves to baseline the exact physical mathematics and fundamental limitations of multi-node FMCW interference. 

However, practical millimeter-wave hardware like the Texas Instruments AWR2944 implements phase coding on a **slow-time (per-chirp)** basis using a binary phase shifter before the PA. Slow-time coding experiences fundamentally different beat-frequency rotation dynamics over the coherent processing interval (CPI) compared to fast-time coding. A future stage of this project will map these validated mathematical baselines to the slow-time coding architecture explicitly required by the AWR2944 hardware constraints.
