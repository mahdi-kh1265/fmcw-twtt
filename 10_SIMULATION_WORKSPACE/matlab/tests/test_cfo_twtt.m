function test_cfo_twtt()
% TEST_CFO_TWTT  CFO TWTT bias tests C07-C09, C16.
%
%   Validates that:
%     - Naive TWTT solver produces correct tau but biased theta (C07)
%     - Bias magnitude matches Delta_f/S (C08)
%     - Large CFO produces proportionally large bias (C09)
%     - Residual-CFO sweep matches bias table (C16)
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section F.1

    cfg = make_default_params();
    S   = cfg.S;
    Fs  = cfg.Fs;

    tau   = 5e-9;
    theta = 100e-12;

    rel_tol   = 1e-10;
    abs_tol_s = 1e-14;

    fprintf('  test_cfo_twtt ...\n');

    %% C07: Naive TWTT bias — tau correct, theta biased
    Df = 100e3;
    res = simulate_cfo_link(cfg, tau, theta, Df);
    f_AB = estimate_beat_phase_slope(res.beat_AB, Fs).f_est;
    f_BA = estimate_beat_phase_slope(res.beat_BA, Fs).f_est;

    [tau_hat, theta_hat] = solve_twtt(f_AB, f_BA, S);

    % tau should be correct (CFO cancels in sum)
    assert(abs(tau_hat - tau) < abs_tol_s, ...
           'C07: tau_hat should be unbiased, error = %.2e s', abs(tau_hat - tau));

    % theta should be biased by Delta_f / S
    expected_theta_hat = theta + Df / S;
    assert(abs(theta_hat - expected_theta_hat) / abs(expected_theta_hat) < rel_tol, ...
           'C07: theta_hat should be theta + Df/S');
    fprintf('    C07 PASS: Naive TWTT: tau correct, theta biased\n');

    %% C08: Bias magnitude = Df / S
    bias = theta_hat - theta;
    expected_bias = Df / S;
    assert(abs(bias - expected_bias) / abs(expected_bias) < rel_tol, ...
           'C08: bias = %.4e s, expected = %.4e s', bias, expected_bias);
    fprintf('    C08 PASS: Bias magnitude = Delta_f / S = %.4f ps\n', ...
            expected_bias * 1e12);

    %% C09: Large CFO stress test
    % Note: CFO must keep f_AB and |f_BA| below Fs/2 = 5 MHz to avoid
    % aliasing in the phase-slope estimator. Baseline beats are ~150 kHz,
    % so max safe CFO is ~4.85 MHz. Use 1 MHz for clear margin.
    Df_large = 1e6;  % 1 MHz
    res_large = simulate_cfo_link(cfg, tau, theta, Df_large);
    f_AB_L = estimate_beat_phase_slope(res_large.beat_AB, Fs).f_est;
    f_BA_L = estimate_beat_phase_slope(res_large.beat_BA, Fs).f_est;
    [tau_hat_L, theta_hat_L] = solve_twtt(f_AB_L, f_BA_L, S);

    assert(abs(tau_hat_L - tau) < abs_tol_s, ...
           'C09: tau still correct under 1 MHz CFO');
    expected_bias_L = Df_large / S;
    bias_L = theta_hat_L - theta;
    assert(abs(bias_L - expected_bias_L) / abs(expected_bias_L) < rel_tol, ...
           'C09: large CFO bias mismatch');
    fprintf('    C09 PASS: 1 MHz CFO -> %.1f ps bias (tau still correct)\n', ...
            expected_bias_L * 1e12);

    %% C16: Residual-CFO scaling sweep
    Df_sweep = [10, 100, 1e3, 10e3, 100e3];
    for k = 1:length(Df_sweep)
        Df_k  = Df_sweep(k);
        res_k = simulate_cfo_link(cfg, tau, theta, Df_k);
        fAB_k = estimate_beat_phase_slope(res_k.beat_AB, Fs).f_est;
        fBA_k = estimate_beat_phase_slope(res_k.beat_BA, Fs).f_est;
        [~, theta_hat_k] = solve_twtt(fAB_k, fBA_k, S);
        bias_k = theta_hat_k - theta;
        expected_k = Df_k / S;
        % Use absolute tolerance for bias (sub-femtosecond values at small Df)
        assert(abs(bias_k - expected_k) < abs_tol_s + rel_tol * abs(expected_k), ...
               'C16: bias mismatch at Df = %.0f Hz: got %.4e, expected %.4e', ...
               Df_k, bias_k, expected_k);
    end
    fprintf('    C16 PASS: Residual-CFO scaling (%d values)\n', length(Df_sweep));

    fprintf('  test_cfo_twtt: ALL PASS\n');
end
