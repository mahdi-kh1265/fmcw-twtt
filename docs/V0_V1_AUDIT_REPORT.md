# V0/V1 Adversarial Audit Report

**Baseline commit:** `adb2370` — "V0/V1: ideal FMCW timing simulation — all 13 tests pass"
**Audit date:** 2026-08-10
**Audit/fix commit:** `1ef6fcb` — "V0/V1: audit fixes and reproducibility documentation"
**Verdict:** PASS WITH FIXES

---

## 1. Audit Scope

Adversarial publication-style audit of the V0/V1 ideal FMCW timing simulation.

**Audited against:** `docs/V0_V1_IMPLEMENTATION_SPEC.md` (Sections A–I).

**Mathematical cross-references consulted:**
- FMCW_TWTT_Mathematical_Handbook
- AWR2944_FMCW_TWTT_MATLAB_Simulation_Blueprint
- "A Versatile FMCW Radar System Simulator for Millimeter-Wave Applications"
- "Method for High Precision Radar Distance Measurement and Synchronization of Wireless Units"
- "Coherent Full-Duplex Double-Sided Two-Way Ranging and Velocity Measurement Between Separate Incoherent Radio Units"

**What was NOT audited (out of scope for V0/V1):**
noise, Monte Carlo, CFO, skew, slope mismatch, phase noise, chirp nonlinearity, multipath, calibration, phase coding, hardware ingestion.

---

## 2. Mathematical Invariants Checked

| Invariant | Status |
|---|---|
| `s(t) = exp(j*pi*S*t^2)` | ✓ Correct |
| `r(t) = exp(j*pi*S*(t-delta)^2)` | ✓ Correct |
| `z(t) = s(t).*conj(r(t)) = exp(j*(2*pi*S*delta*t - pi*S*delta^2))` | ✓ Correct |
| `f_b = S*delta` (sign, units) | ✓ Correct |
| No `round(delta*Fs)`, `floor(delta*Fs)`, `circshift` in delay path | ✓ Verified |
| No monostatic `2R/c` in cross-link model | ✓ Not present |
| Clock convention: `T_A(t) = t`, `T_B(t) = t + theta` | ✓ Correct |
| `delta_AB = tau + theta`, `delta_BA = tau - theta` | ✓ Derived correctly |
| `tau_hat = (f_AB + f_BA) / (2*S)` | ✓ Correct |
| `theta_hat = (f_AB - f_BA) / (2*S)` | ✓ Correct |
| LS phase-slope: `phi[n] = m*n + b`, `f_est = m*Fs/(2*pi)` | ✓ Correct |
| LS normal equations (closed-form `Sn`, `Sn2`) | ✓ Verified |
| Phase increment per sample well below pi | ✓ 0.096 rad/sample |
| V1 reuses `simulate_ideal_link` exactly twice | ✓ No duplicated signal chain |
| `Tobs = N/Fs` not confused with `Tc` | ✓ Documentation clear |
| Conjugation order matches spec A.6 | ✓ `z = tx .* conj(rx)` |

---

## 3. Independent Headline Oracle

Independently computed in Python (not using any project helper function):

| Quantity | Formula | Expected | Implementation |
|---|---|---|---|
| S × tau | 2.9982e13 × 5e-9 | 149,910.0 Hz | 149,910.0 Hz ✓ |
| S × theta | 2.9982e13 × 100e-12 | 2,998.2 Hz | 2,998.2 Hz ✓ |
| f_AB | S × (tau + theta) | 152,908.2 Hz | 152,908.2 Hz ✓ |
| f_BA | S × (tau - theta) | 146,911.8 Hz | 146,911.8 Hz ✓ |
| f_AB − f_BA | 2 × S × theta | 5,996.4 Hz | 5,996.4 Hz ✓ |
| Fs/N | 10e6/256 | 39,062.5 Hz | 39,062.5 Hz ✓ |
| FFT bin (AB) | f_AB / df | 3.914 → bin 4 → 156,250 Hz | 156,250.0 Hz ✓ |
| FFT bin (BA) | f_BA / df | 3.761 → bin 4 → 156,250 Hz | 156,250.0 Hz ✓ |

Both directional records map to the same nearest DFT bin, confirming the nearest-bin estimator cannot resolve the ~5,996.4 Hz AB/BA difference.

---

## 4. Implementation Checks

| Check | Status |
|---|---|
| All source functions match spec B.5 contracts | ✓ |
| Column vectors throughout | ✓ |
| No toolbox dependencies | ✓ |
| No globals or persistent state | ✓ |
| SI units only | ✓ |
| `run_all.m` derives paths from `mfilename('fullpath')` | ✓ |
| `run_all.m` runs tests first, aborts on failure | ✓ |
| `run_all.m` regenerates all outputs from clean state | ✓ Verified by deleting outputs and re-running |
| `sgtitle` / `exportgraphics` guarded with try-catch | ✓ |
| `xline` compatible MATLAB R2018b+ / Octave 6+ | ✓ |
| No Octave-only syntax (`pkg load`, `endfunction`) | ✓ |
| No absolute/machine-specific paths in committed code | ✓ |
| Figure IDEAL/noise-free labels present | ✓ |
| No hardware-performance implications in outputs | ✓ |

---

## 5. Test Results

All 13 individual tests (5 test groups) pass under GNU Octave 11.3.0:

| Group | Tests | Status |
|---|---|---|
| `test_v0_single_link` | T01–T05 | PASS |
| `test_v1_two_way` | T06–T09 | PASS |
| `test_fractional_delay` | T10 | PASS |
| `test_sign_convention` | T11–T12 | PASS |
| `test_waveform_closedform` | T13 | PASS |

**Circularity check:** No test uses the function under test to generate expected values. All oracles are inline `S*delta` or independently constructed closed-form expressions.

**Tolerance check:** All tolerances match spec F.3. No loosened tolerances.

**Spec-deferred tests (F.5):** Amplitude invariance (V2), initial-phase invariance (V3), negative slope (V2) are correctly absent — spec explicitly defers them.

---

## 6. Findings

### F1 — Floating-point closure labeling (documentation fix)

**Issue:** The morning summary and console output displayed ~1e-21 s error residuals without identifying them as IEEE 754 floating-point closure of the ideal deterministic model.

**Risk:** A reader could misinterpret sub-femtosecond residuals as claimed physical timing precision.

**Fix:** Added "(floating-point closure)" or "(floating-point closure, not physical precision)" annotations to all error output lines and summary table rows. Expanded the disclaimer in Section 9 of the morning summary.

### F2 — Missing raw FFT estimates in V1 output (completeness fix)

**Issue:** V1 console output did not print the raw nearest-bin FFT estimates for A→B and B→A directions. The spec's FFT resolution analysis (D.3) emphasizes that both map to the same bin, but this was not made concrete in the demo output.

**Fix:** Added raw FFT peak estimates for both directions to V1 console output, with explicit note that both map to the same DFT bin. Stated clearly that these are two separate directional observations. Added FFT values to the morning summary table.

### F3 — README runtime claim (accuracy fix)

**Issue:** README stated "MATLAB (tested R2020b+)" but MATLAB has never executed this code. MATLAB R2025a encountered licensing error 5201.

**Fix:** Changed to: "MATLAB-compatible source. Runtime verified in GNU Octave 11.3.0. Native MATLAB runtime execution pending."

### F4 — Hardcoded test count in runner (minor robustness fix)

**Issue:** `run_all_tests.m` hardcoded "(13 individual tests)" in the display string.

**Fix:** Changed to dynamic group count: `"%d test groups"` using `length(tests)`.

### F5 — Missing FFT resolution note in morning summary (completeness fix)

**Issue:** The morning summary did not include the FFT resolution analysis from spec D.3, which is a key educational point about why nearest-bin FFT cannot recover the ~5,996.4 Hz directional difference.

**Fix:** Added Section 6a "FFT Resolution Note" to the generated summary.

---

## 7. Fixes Made

| File | Change |
|---|---|
| `scripts/demo_v1_two_way.m` | F1: floating-point closure labels in console and summary |
| `scripts/demo_v1_two_way.m` | F2: raw FFT AB/BA estimates in console and summary |
| `scripts/demo_v1_two_way.m` | F5: FFT resolution note in summary Section 6a |
| `scripts/demo_v1_two_way.m` | F6-terminology: "relative clock epoch offset" |
| `scripts/demo_v1_two_way.m` | F7-model: "ideal analytic complex-baseband FMCW truth model" |
| `scripts/demo_v1_two_way.m` | F7-model: intentionally absent effects list |
| `scripts/demo_v1_two_way.m` | F9-disclaimer: expanded with floating-point closure note |
| `scripts/demo_v0_single_link.m` | F1: floating-point closure label |
| `README.md` | F3: accurate runtime status |
| `README.md` | F6: professional terminology |
| `README.md` | F7: model status description |
| `tests/run_all_tests.m` | F4: dynamic test group count |
| `results/reproducibility_manifest.txt` | New: full reproducibility record |
| `docs/V0_V1_AUDIT_REPORT.md` | New: permanent audit provenance |

**No mathematical, algorithmic, or test-logic changes were made.** All fixes are documentation, labeling, and completeness improvements.

---

## 8. Runtime Validation Status

**MATLAB-compatible implementation; runtime verified in GNU Octave 11.3.0; MATLAB execution still pending.**

- GNU Octave 11.3.0 (aarch64-apple-darwin25.4.0): `run_all.m` completes successfully from clean state.
- MATLAB R2025a: licensing error 5201; no project code has been executed under MATLAB.
- Static MATLAB compatibility audit: no Octave-only syntax, no Octave-only functions, MATLAB-only calls (`exportgraphics`, `sgtitle`) guarded with try-catch.

---

## 9. Known V0/V1 Limitations

These are by design, not defects:

1. The phase-slope estimator achieves double-precision closure only because the model is ideal and deterministic. This does NOT imply unlimited precision once noise or nonidealities are introduced.
2. The nearest-bin FFT estimator cannot resolve the ~5,996.4 Hz directional difference for the headline parameters. This is expected; the FFT is a diagnostic estimator only.
3. V0/V1 does not model: receiver noise, ADC quantization, carrier-frequency offset, clock-rate skew, phase noise, chirp nonlinearity, multipath, asymmetric group delay, calibration uncertainty, or slope mismatch.
4. `theta` represents a constant relative clock epoch offset. It does not model oscillator frequency/rate offset.

---

## 10. Audit/Fix Commit

**Commit hash:** `1ef6fcb`
**Commit message:** `V0/V1: audit fixes and reproducibility documentation`
