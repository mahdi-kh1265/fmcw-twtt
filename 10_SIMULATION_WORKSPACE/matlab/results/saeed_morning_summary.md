# FMCW Two-Way Time Transfer -- V0/V1 Simulation Results

**Date:** 2026-08-10
**Model:** Ideal analytic complex-baseband FMCW truth model
**Status:** IDEAL / NOISE-FREE simulation only

---

## 1. Objective

Demonstrate that FMCW dechirping converts sub-nanosecond propagation delay
and picosecond relative clock epoch offset into easily estimated low-frequency
beats, and that two-way sum/difference algebra recovers both quantities exactly
under ideal conditions.

## 2. V0 Single-Link Result

| Quantity | Value |
|---|---|
| Injected delay | 5.000 ns |
| Theoretical f_b | 149910.0 Hz |
| Phase-slope estimate | 149910.0 Hz |
| FFT nearest-bin estimate | 156250.0 Hz |
| Recovered delay | 5.000000000 ns |
| Delay error | 9.6e-22 s (floating-point closure, not physical precision) |

## 3. V1 Two-Way Result

In V1, "theta" denotes the **relative clock epoch offset** between stations.
It does not model oscillator rate/frequency offset or clock skew.

The A->B and B->A beat frequencies are obtained from **two separate directional
dechirp observations**, not by resolving two simultaneous tones in a single
spectrum.

| Quantity | Value |
|---|---|
| Injected tau | 5.000 ns |
| Injected theta (clock epoch offset) | 100.0 ps |
| Phase-slope f_AB | 152908.2 Hz |
| Phase-slope f_BA | 146911.8 Hz |
| FFT nearest-bin f_AB | 156250.0 Hz |
| FFT nearest-bin f_BA | 156250.0 Hz |
| f_AB - f_BA | 5996.4 Hz |
| Recovered tau | 5.000000000 ns |
| Recovered theta | 100.000 ps |
| tau error | 1.2e-21 s (floating-point closure, not physical precision) |
| theta error | 3.0e-22 s (floating-point closure, not physical precision) |

## 4. Model Assumptions and Intentionally Absent Effects

V0/V1 is an **ideal analytic complex-baseband FMCW truth model**.
It is not a full radar simulation, hardware digital twin, or realistic
AWR2944 precision model.

The following effects are **intentionally absent** from V0/V1:

- Receiver noise / SNR (no additive noise; infinite SNR)
- ADC quantization
- Independent carrier-frequency offset
- Clock-rate error / skew (theta is a constant epoch offset only)
- Phase noise
- Chirp nonlinearity
- Multipath
- Asymmetric hardware / group delay
- Calibration uncertainty
- Slope mismatch between stations
- Reciprocal propagation is assumed (same tau in both directions)
- Analytic (not integer-sample) delay model

## 5. Numerical Parameters

| Parameter | Value |
|---|---|
| Chirp slope S | 29.982 MHz/us = 2.9982e+13 Hz/s |
| Sample rate Fs | 10 MHz |
| Samples N | 256 |
| Observation time Tobs | 25.6 us |
| FFT bin spacing | 39.0625 kHz |

## 6. Equations

```
Baseband chirp:   s(t) = exp(j * pi * S * t^2)
Dechirp:          z(t) = s(t) .* conj(r(t))
Beat frequency:   f_b  = S * delta

Clock model (theta = relative clock epoch offset):
  T_A(t) = t
  T_B(t) = t + theta    (positive theta => B ahead of A)

Effective delays:
  delta_AB = tau + theta
  delta_BA = tau - theta

Recovery:
  tau_hat   = (f_AB + f_BA) / (2*S)
  theta_hat = (f_AB - f_BA) / (2*S)
```

## 6a. FFT Resolution Note

For the headline parameters (N=256, Fs=10 MHz), the FFT bin spacing is
39062.5 Hz. The nearest-bin FFT estimator maps both ideal directional records
to the same raw DFT bin and therefore cannot recover the ~5996.4 Hz directional
beat-frequency difference.

The phase-slope (LS) estimator operates on each separate complex record and
recovers the underlying off-bin frequency exactly in this ideal noise-free model.

Zero-padding interpolates the displayed spectrum; it does not increase physical
observation time or add information.

## 7. Figures

- `figures/fig01_v0_single_link.png` -- V0 delay-to-frequency conversion
- `figures/fig02_v1_two_way.png` -- V1 two-way timing summary
- `figures/fig03_delay_linearity.png` -- Delay linearity sweep
- `figures/fig04_theta_recovery.png` -- Clock-offset recovery sweep

## 8. Next Steps

1. **V2 -- AWGN:** Add noise to quantify estimator precision vs SNR.
2. **V3 -- Independent oscillator effects:** Carrier-frequency offset,
   clock skew, slope mismatch.
3. **Estimator comparison:** FFT, phase-slope, CZT under noise.
4. **AWR2944 parameter mapping:** Map hardware chirp profile to simulation config.
5. **Hardware characterization:** Second AWR2944 board for two-way measurements.

## 9. Disclaimer

> **These results are from an IDEAL, NOISE-FREE simulation.** They demonstrate
> mathematical correctness of the ideal analytic complex-baseband FMCW timing
> model, NOT achievable hardware performance. 10-ps accuracy on real AWR2944
> hardware has NOT been demonstrated and requires additional modeling and
> measurement. The sub-femtosecond error residuals reported above reflect
> IEEE 754 double-precision floating-point closure of the ideal deterministic
> model, not physical timing precision.
