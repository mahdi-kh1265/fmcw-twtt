function test_cfo_bias_regression()
% TEST_CFO_BIAS_REGRESSION  Regression tests for CFO-to-timing-bias mapping.
%
%   C19: Verify frozen key result:
%       299.82 Hz residual CFO <-> 10 ps equivalent epoch-offset bias
%   C26: Verify 100 kHz -> 3.3353 ns
%   C27: Verify 300 kHz -> 10.006 ns
%   C28: Phase-derived calibration tone agrees with oracle
%   C29: Phase-derived cal tone with zero CFO -> f_est ~ 0

    cfg = make_default_params();
    S   = cfg.S;
    Fs  = cfg.Fs;
    N   = cfg.N;
    t   = (0:N-1).' / Fs;

    tau   = 5e-9;
    theta = 100e-12;

    abs_tol_s = 1e-14;
    rel_tol   = 1e-10;

    fprintf('  test_cfo_bias_regression ...\n');

    %% C19: Frozen key result — 299.82 Hz -> 10 ps bias
    Df_10ps = S * 10e-12;  % = 299.82 Hz
    expected_Df = 299.82;
    assert(abs(Df_10ps - expected_Df) / expected_Df < 1e-4, ...
           'C19: S * 10 ps != 299.82 Hz');

    % Verify via simulation
    res = simulate_cfo_link_phased(cfg, tau, theta, Df_10ps);
    f_AB = estimate_beat_phase_slope(res.beat_AB, Fs).f_est;
    f_BA = estimate_beat_phase_slope(res.beat_BA, Fs).f_est;
    [~, theta_hat] = solve_twtt(f_AB, f_BA, S);
    bias = abs(theta_hat - theta);
    assert(abs(bias - 10e-12) < abs_tol_s + rel_tol * 10e-12, ...
           'C19: bias at 299.82 Hz = %.4e s, expected 10 ps', bias);
    fprintf('    C19 PASS: 299.82 Hz -> %.4f ps bias (10 ps target)\n', bias*1e12);

    %% C26: 100 kHz -> 3.3353 ns bias
    Df_100k = 100e3;
    expected_bias_100k = Df_100k / S;  % = 3.3353e-9 s = 3.3353 ns
    res_100k = simulate_cfo_link_phased(cfg, tau, theta, Df_100k);
    f_AB_100k = estimate_beat_phase_slope(res_100k.beat_AB, Fs).f_est;
    f_BA_100k = estimate_beat_phase_slope(res_100k.beat_BA, Fs).f_est;
    [~, theta_hat_100k] = solve_twtt(f_AB_100k, f_BA_100k, S);
    bias_100k = abs(theta_hat_100k - theta);
    assert(abs(bias_100k - expected_bias_100k) / expected_bias_100k < rel_tol, ...
           'C26: bias at 100 kHz = %.4e s, expected %.4e s', bias_100k, expected_bias_100k);
    fprintf('    C26 PASS: 100 kHz -> %.4f ns bias\n', bias_100k*1e9);

    %% C27: 300 kHz -> 10.006 ns bias (NOT 10 ps)
    Df_300k = 300e3;
    expected_bias_300k = Df_300k / S;  % = 1.0006e-8 s = 10.006 ns
    res_300k = simulate_cfo_link_phased(cfg, tau, theta, Df_300k);
    f_AB_300k = estimate_beat_phase_slope(res_300k.beat_AB, Fs).f_est;
    f_BA_300k = estimate_beat_phase_slope(res_300k.beat_BA, Fs).f_est;
    [~, theta_hat_300k] = solve_twtt(f_AB_300k, f_BA_300k, S);
    bias_300k = abs(theta_hat_300k - theta);
    assert(abs(bias_300k - expected_bias_300k) / expected_bias_300k < rel_tol, ...
           'C27: bias at 300 kHz = %.4e s, expected %.4e s', bias_300k, expected_bias_300k);
    fprintf('    C27 PASS: 300 kHz -> %.4f ns bias\n', bias_300k*1e9);

    %% C28: Phase-derived cal tone agrees with oracle
    Df_test = 100e3;
    z_oracle = generate_cal_tone(t, Df_test);
    z_phased = generate_cal_tone_phased(t, Df_test, tau, theta, cfg.fc);
    Df_oracle = estimate_cfo_from_tone(z_oracle, Fs);
    Df_phased = estimate_cfo_from_tone(z_phased, Fs);
    assert(abs(Df_oracle - Df_phased) / abs(Df_test) < rel_tol, ...
           'C28: oracle/phased cal tone frequency mismatch');
    assert(abs(Df_phased - Df_test) / abs(Df_test) < rel_tol, ...
           'C28: phased cal tone recovery mismatch');
    fprintf('    C28 PASS: Phased cal tone agrees with oracle (Df = %.1f kHz)\n', ...
            Df_phased / 1e3);

    %% C29: Zero CFO -> f_est ~ 0 for phase-derived cal tone
    z_zero = generate_cal_tone_phased(t, 0, tau, theta, cfg.fc);
    Df_zero = estimate_cfo_from_tone(z_zero, Fs);
    assert(abs(Df_zero) < 1, ...
           'C29: zero-CFO phased cal tone should give ~0 Hz, got %.2f', Df_zero);
    fprintf('    C29 PASS: Zero CFO phased cal tone -> %.2e Hz\n', Df_zero);

    fprintf('  test_cfo_bias_regression: ALL PASS\n');
end
