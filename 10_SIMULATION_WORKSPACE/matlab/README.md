# FMCW / TWTT V0/V1 Simulation

## Overview

Ideal analytic complex-baseband FMCW truth model for two-way time transfer (TWTT) research.

- **V0:** Single-link delay-to-beat-frequency truth model
- **V1:** Reciprocal two-way timing — two V0 links recovering propagation delay and relative clock epoch offset

All V0/V1 results are **IDEAL and NOISE-FREE**. They demonstrate mathematical correctness of the ideal FMCW timing model, not achievable hardware performance. This is not a full radar simulation, hardware digital twin, or realistic AWR2944 precision model.

## Quick Start

```matlab
>> run_all
```

This runs all 13 unit tests, then both demos, generating all figures and the morning summary report. Works from a clean MATLAB/Octave session — no manual path setup required.

## Structure

```
matlab/
  run_all.m              % Master entry point
  src/                   % Core simulation functions (8 files)
  tests/                 % Unit tests T01-T13 (5 files + runner)
  scripts/               % Demo scripts and figure generation
  figures/               % Generated output (PNG + optional PDF)
  results/               % Generated reports and data
```

## Key Functions

| Function | Purpose |
|---|---|
| `simulate_ideal_link(cfg, delta)` | Authoritative V0 link: chirp → delay → dechirp |
| `estimate_beat_phase_slope(beat, Fs)` | Primary estimator: LS phase-slope fit |
| `estimate_beat_fft(beat, Fs)` | Diagnostic only: FFT peak detection |
| `solve_twtt(fAB, fBA, S)` | TWTT algebra: sum/difference recovery |

## Sign Convention

```
T_A(t) = t              (Station A clock = physical time)
T_B(t) = t + theta      (positive theta => B clock ahead of A)
                         (theta = relative clock epoch offset)

delta_AB = tau + theta   (A transmits, B receives)
delta_BA = tau - theta   (B transmits, A receives)

tau_hat   = (f_AB + f_BA) / (2*S)
theta_hat = (f_AB - f_BA) / (2*S)
```

## Specification

See `docs/V0_V1_IMPLEMENTATION_SPEC.md` for the complete binding specification.

## Runtime Status

- **MATLAB-compatible source.** No toolbox dependencies (no Signal Processing Toolbox, no Phased Array Toolbox).
- **Runtime verified in GNU Octave 11.3.0.** All 13 tests pass; all outputs regenerate from clean state.
- **Native MATLAB runtime execution pending.** MATLAB R2025a could not obtain a license on the development machine (error 5201). MATLAB execution has not been verified.
