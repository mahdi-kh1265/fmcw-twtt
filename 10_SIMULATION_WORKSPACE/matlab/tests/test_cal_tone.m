function test_cal_tone()
% TEST_CAL_TONE  Calibration tone tests C13-C15.
%
%   Validates that:
%     - CFO is recovered from calibration tone (C13)
%     - Negative CFO is recovered from tone (C14)
%     - Tone-corrected TWTT recovers tau and theta exactly (C15)
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section F.1

    cfg = make_default_params();
    S   = cfg.S;
    Fs  = cfg.Fs;
    t   = (0:cfg.N-1).' / Fs;

    rel_tol   = 1e-10;
    abs_tol_s = 1e-14;

    tau   = 5e-9;
    theta = 100e-12;

    fprintf('  test_cal_tone ...\n');

    %% C13: Positive CFO recovery from tone
    Df = 100e3;
    z_cal = generate_cal_tone(t, Df);
    Df_hat = estimate_cfo_from_tone(z_cal, Fs);
    assert(abs(Df_hat - Df) / abs(Df) < rel_tol, ...
           'C13: CFO recovery mismatch: got %.6f, expected %.6f Hz', Df_hat, Df);
    fprintf('    C13 PASS: Positive CFO from tone = %.1f kHz\n', Df_hat/1e3);

    %% C14: Negative CFO recovery from tone
    Df_neg = -50e3;
    z_cal_neg = generate_cal_tone(t, Df_neg);
    Df_hat_neg = estimate_cfo_from_tone(z_cal_neg, Fs);
    assert(abs(Df_hat_neg - Df_neg) / abs(Df_neg) < rel_tol, ...
           'C14: Negative CFO recovery mismatch');
    fprintf('    C14 PASS: Negative CFO from tone = %.1f kHz\n', Df_hat_neg/1e3);

    %% C15: Tone-corrected TWTT recovers tau and theta
    Df = 100e3;
    res = simulate_cfo_link(cfg, tau, theta, Df);

    % Estimate CFO from tone
    z_cal = generate_cal_tone(t, Df);
    Df_hat = estimate_cfo_from_tone(z_cal, Fs);

    % Correct beats
    beat_AB_corr = correct_cfo(res.beat_AB, t, Df_hat, 'AB');
    beat_BA_corr = correct_cfo(res.beat_BA, t, Df_hat, 'BA');

    % Estimate corrected beat frequencies
    f_AB_corr = estimate_beat_phase_slope(beat_AB_corr, Fs).f_est;
    f_BA_corr = estimate_beat_phase_slope(beat_BA_corr, Fs).f_est;

    % Solve TWTT with corrected beats
    [tau_hat, theta_hat] = solve_twtt(f_AB_corr, f_BA_corr, S);

    assert(abs(tau_hat - tau) < abs_tol_s, ...
           'C15: corrected tau mismatch: error = %.2e s', abs(tau_hat - tau));
    assert(abs(theta_hat - theta) < abs_tol_s, ...
           'C15: corrected theta mismatch: error = %.2e s', abs(theta_hat - theta));
    fprintf('    C15 PASS: Tone-corrected TWTT: tau_err = %.1e s, theta_err = %.1e s\n', ...
            abs(tau_hat - tau), abs(theta_hat - theta));

    fprintf('  test_cal_tone: ALL PASS\n');
end
