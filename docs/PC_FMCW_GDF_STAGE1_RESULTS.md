# Group-Delay Filter (GDF) Stage-1 Results

## Methodology

This document summarizes the decisive validation of the Stage-1 literature-style group-delay filter for fast-time Phase-Coded FMCW (PC-FMCW). The task evaluated two distinct physical questions:

1. **Q1 (Mechanism):** Does the quadratic group-delay filter `H(f) = exp(+j*pi*f^2/S)` actually realign the delayed fast-time phase-code envelope under our specific frozen FMCW convention?
2. **Q2 (Separation):** If Q1 is verified, does that realignment materially improve simultaneous strong/weak Walsh-coded node separation using simple despreading?

### Filter Equation and Padding Method
The filter was implemented along a zero-padded, reference-safe path (`N_pad = 4096`) to eliminate circular wrap artifacts (which caused ~3.4% RMS discrepancy in full-record unpadded evaluation).

## Q1: Envelope Alignment Mechanism
**Verdict: PASS WITH DISPERSION**

To overcome the sub-sample evaluation insensitivity of the physical `7 ns` delay, a delay-sensitivity sweep (`delta = 7, 50, 100, 150 ns`) was conducted using a 16-chip code. The results demonstrate that the group-delay filter systematically moves the alignment preference away from the delayed code and towards the unshifted code across both full-record and transition-focused metrics. 

However, because the quadratic phase filter is applied across a wide 10 MHz bandwidth, the sharp rectangular transitions of the phase code suffer from noticeable dispersion. This dispersion prevents perfect whole-record correlation recovery (`rho_after_unshifted < 1.0`), but the mechanism unequivocally operates in the mathematically predicted direction.

*(Analytic testing confirmed `exp(+j*2*pi*nu*f_b/S)` perfectly cancels the code-delay phase `exp(-j*2*pi*nu*delta)`).*

## Q2: Simultaneous Node Separation
**Verdict: FAIL**

Having confirmed the GDF envelope realignment mechanism, we tested the realizable multi-node case: a strong node A (`alpha_A=1.0`) and a weak node B (`alpha_B=0.3`). A zero-padded spectral detector (`Nfft=16384`) evaluated the peak structures.

To establish final recovery, the receiver must satisfy two independent constraints:
1. **Spectral Prominence:** `SIR_dB >= 0 dB` (classified as DETECTED)
2. **Frequency Accuracy:** The detected peak must lie within `0.5 * Delta_f_native` (`19531.25 Hz`) of the theoretical beat frequency (classified as FREQUENCY_RECOVERED).

**Code Length Study Results:**
| L  | Naive SIR | GDF SIR | Spectral Class | Freq. Error | Freq. Recovered | Final Recovery |
|----|-----------|---------|----------------|-------------|-----------------|----------------|
| 2  | -1.82 dB  | -1.81 dB| AMBIGUOUS      | 78.0 kHz    | NO              | NO             |
| 4  | -0.10 dB  | -0.10 dB| AMBIGUOUS      | 46.9 kHz    | NO              | NO             |
| 8  |  9.81 dB  |  9.73 dB| DETECTED       | 31.8 kHz    | NO              | NO             |
| 16 | -6.21 dB  | -7.23 dB| MASKED         |  2.5 kHz    | YES             | NO             |

*Crucial Observations:*
- At **L=8**, the spectral structure is prominent (`+9.73 dB`), but it is a shifted artifact biased by ~31.8 kHz. Frequency recovery fails.
- At **L=16**, the correct frequency is localized (`2.5 kHz` error, well within the 19.5 kHz tolerance), but the side-lobe interference is so severe that the peak is MASKED (`-7.23 dB`).

**Conclusion**

Under the tested ideal/noise-free parameters, the current padded-GDF + Walsh despreading + simple spectral-detection receiver did not simultaneously provide sufficient spectral prominence and accurate weak-node beat recovery for any tested L = 2,4,8,16. The continuous time-domain phase rotation of the interfering chirp's beat signal spectrally spreads the Walsh code energy, overwhelming the weak node. This result establishes the strict limitations of the current simple linear despreading/detection architecture.
