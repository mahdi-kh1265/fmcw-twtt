# FMCW Two-Way Time Transfer -- V0/V1 Simulation Results

**Date:** 2026-08-10
**Status:** IDEAL / NOISE-FREE simulation only

---

## 1. Objective

Demonstrate that FMCW dechirping converts sub-nanosecond propagation delay
and picosecond clock offset into easily estimated low-frequency beats, and
that two-way sum/difference algebra recovers both quantities exactly under
ideal conditions.

## 2. V0 Single-Link Result

| Quantity | Value |
|---|---|
| Injected delay | 5.000 ns |
| Theoretical f_b | 149910.0 Hz |
| Estimated f_b | 149910.0 Hz |
| Recovered delay | 5.000000000 ns |
| Delay error | 9.6e-22 s |

## 3. V1 Two-Way Result

| Quantity | Value |
|---|---|
| Injected tau | 5.000 ns |
| Injected theta | 100.0 ps |
| Estimated f_AB | 152908.2 Hz |
| Estimated f_BA | 146911.8 Hz |
| f_AB - f_BA | 5996.4 Hz |
| Recovered tau | 5.000000000 ns |
| Recovered theta | 100.000 ps |
| tau error | 1.2e-21 s |
| theta error | 3.0e-22 s |

## 4. Model Assumptions

All V0/V1 results assume:

- Identical chirp slopes at both stations (no slope mismatch)
- Zero carrier-frequency offset (no independent oscillator drift)
- Zero clock skew (constant theta, no time-varying drift)
- Zero phase noise
- No additive noise (infinite SNR)
- No ADC quantization effects
- No multipath
- No TX/RX group-delay asymmetry
- Reciprocal propagation path (same tau in both directions)
- No chirp ramp nonlinearity
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

Clock model:
  T_A(t) = t
  T_B(t) = t + theta    (positive theta => B ahead of A)

Effective delays:
  delta_AB = tau + theta
  delta_BA = tau - theta

Recovery:
  tau_hat   = (f_AB + f_BA) / (2*S)
  theta_hat = (f_AB - f_BA) / (2*S)
```

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
> mathematical correctness of the FMCW timing model, NOT achievable hardware
> performance. 10-ps accuracy on real AWR2944 hardware has NOT been demonstrated
> and requires additional modeling and measurement.
