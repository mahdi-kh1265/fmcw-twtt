# Group-Delay Filter (GDF) Stage-1 Results

## Methodology

This document summarizes the decisive validation of the Stage-1 literature-style group-delay filter for fast-time Phase-Coded FMCW (PC-FMCW). The task evaluated two distinct physical questions:

1. **Q1 (Mechanism):** Does the quadratic group-delay filter `H(f) = exp(+j*pi*f^2/S)` actually realign the delayed fast-time phase-code envelope under our specific frozen FMCW convention?
2. **Q2 (Separation):** If Q1 is verified, does that realignment materially improve simultaneous strong/weak Walsh-coded node separation using simple despreading?

### Filter Equation and Padding Method
The filter was implemented along a zero-padded, reference-safe path (`N_pad = 4096`) to eliminate circular wrap artifacts (which caused ~3.4% RMS discrepancy in full-record unpadded evaluation).

## Q1: Envelope Alignment Mechanism
**Verdict: PASS WITH DISPERSION**

By derotating the fast-time beat frequency oracle-style, we directly observed the continuous envelope. The GDF successfully shifted the envelope correlation toward the unshifted code (`rho` went from 0.9921 to 0.9936) and away from the delayed code (1.0000 down to 0.9970). However, because the filter is applied across a wide 10 MHz bandwidth, the sharp rectangular transitions of the phase code suffer from noticeable dispersion. This dispersion prevents perfect crossover, but the mechanism unequivocally operates in the mathematically predicted direction. 

*(Analytic testing confirmed `exp(+j*2*pi*nu*f_b/S)` perfectly cancels the code-delay phase `exp(-j*2*pi*nu*delta)`).*

## Q2: Simultaneous Node Separation
**Verdict: FAIL**

Having confirmed the GDF envelope realignment mechanism, we tested the realizable multi-node case: a strong node A (`alpha_A=1.0`) and a weak node B (`alpha_B=0.3`). 
A zero-padded spectral detector (`Nfft=16384`) evaluated the peak structures free of coarse N=256 grid quantization errors.

**Code Length Study Results:**
| L  | Naive SIR_B | GDF SIR_B | Classification |
|----|-------------|-----------|----------------|
| 2  | -1.82 dB    | -1.81 dB  | AMBIGUOUS      |
| 4  | -0.10 dB    | -0.10 dB  | AMBIGUOUS      |
| 8  |  9.81 dB    |  9.73 dB  | DETECTED       |
| 16 | -6.21 dB    | -7.23 dB  | MASKED         |

*(Note: At L=16, the main lobe of the desired peak becomes so narrow that interference side-lobes dominate the detection window, pushing it back into MASKED).*

**Does the group-delay filter solve the simultaneous two-node structured interference problem for our architecture?**

**No.** Under the tested parameters, the GDF performs its intended code-alignment operation, but GDF + simple Walsh despreading/spectral detection remains insufficient for the strong/weak case. The continuous time-domain phase rotation of the interfering chirp's beat signal spectrally spreads the Walsh code energy across the band. This interference dominates the weak node's signal. The result does not establish the impossibility of fast-time PC-FMCW generally, but proves that the current simple receiver architecture cannot achieve the necessary isolation.

## AWR2944 Hardware Caveat
The next step is to evaluate slow-time (per-chirp) coding. Unlike fast-time coding, slow-time coding experiences fundamentally different beat-frequency rotation dynamics over the coherent processing interval (CPI). This will map the validated mathematical baselines to the exact architecture required by practical AWR2944 millimeter-wave hardware.
