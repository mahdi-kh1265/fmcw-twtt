# Next engineering step

Build **Simulation V0/V1** in MATLAB as a source-validated analytic/baseband truth model. Do not begin with phase-coded FMCW or a full RF front-end.

Minimum V0:
1. Parameter struct with `f0`, `B`, `Tc`, `S=B/Tc`, `Fs`, observation interval, propagation delay `tau`, clock offset `theta`.
2. Complex chirp phase generated analytically.
3. Fractional delay applied analytically in phase/time, not integer sample shifting.
4. Ideal dechirp and theoretical beat `fb = S*tau_eff`.
5. FFT view for intuition plus a phase-slope/least-squares beat estimator so sub-bin delay is possible.
6. Unit tests for zero delay, known delay, sign conventions, and scaling.

V1 adds reciprocal A-to-B and B-to-A channels with the ideal two-way equations. Only after V1 passes should clock skew/CFO, slope mismatch, noise, phase noise, nonlinearity, group delay, and coded FMCW be enabled one at a time.
