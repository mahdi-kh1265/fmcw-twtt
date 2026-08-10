function test_v1_two_way()
% TEST_V1_TWO_WAY  Tests T06-T09: symmetric, headline, sign reversal, algebra.
%
%   Tolerances from spec Section F.3:
%     |tau_hat   - tau|   < 1e-14 s
%     |theta_hat - theta| < 1e-14 s
%
%   T06-T08 use tau > |theta| so both effective delays are positive.
%   T09 is a nonphysical algebra/sign test of solve_twtt only.

    cfg = make_default_params();
    S  = cfg.S;
    Fs = cfg.Fs;

    % --- T06: Symmetric (theta = 0) ---
    tau = 5e-9;  theta = 0;
    link_AB = simulate_ideal_link(cfg, tau + theta);
    link_BA = simulate_ideal_link(cfg, tau - theta);
    est_AB  = estimate_beat_phase_slope(link_AB.beat, Fs);
    est_BA  = estimate_beat_phase_slope(link_BA.beat, Fs);
    [tau_hat, theta_hat] = solve_twtt(est_AB.f_est, est_BA.f_est, S);
    assert(abs(tau_hat - tau) < 1e-14, ...
        sprintf('T06 FAIL: tau error = %.2e s', tau_hat - tau));
    assert(abs(theta_hat) < 1e-14, ...
        sprintf('T06 FAIL: theta_hat = %.2e s, expected 0', theta_hat));

    % --- T07: Headline case (tau=5ns, theta=100ps) ---
    tau = 5e-9;  theta = 100e-12;
    link_AB = simulate_ideal_link(cfg, tau + theta);
    link_BA = simulate_ideal_link(cfg, tau - theta);
    est_AB  = estimate_beat_phase_slope(link_AB.beat, Fs);
    est_BA  = estimate_beat_phase_slope(link_BA.beat, Fs);
    [tau_hat, theta_hat] = solve_twtt(est_AB.f_est, est_BA.f_est, S);
    assert(abs(tau_hat - tau) < 1e-14, ...
        sprintf('T07 FAIL: tau error = %.2e s', tau_hat - tau));
    assert(abs(theta_hat - theta) < 1e-14, ...
        sprintf('T07 FAIL: theta error = %.2e s', theta_hat - theta));

    % --- T08: Sign reversal (theta = -100 ps) ---
    tau = 5e-9;  theta = -100e-12;
    link_AB = simulate_ideal_link(cfg, tau + theta);
    link_BA = simulate_ideal_link(cfg, tau - theta);
    est_AB  = estimate_beat_phase_slope(link_AB.beat, Fs);
    est_BA  = estimate_beat_phase_slope(link_BA.beat, Fs);
    [tau_hat, theta_hat] = solve_twtt(est_AB.f_est, est_BA.f_est, S);
    assert(abs(tau_hat - tau) < 1e-14, ...
        sprintf('T08 FAIL: tau error = %.2e s', tau_hat - tau));
    assert(abs(theta_hat - theta) < 1e-14, ...
        sprintf('T08 FAIL: theta error = %.2e s', theta_hat - theta));

    % --- T09: Nonphysical algebra test (tau=0, theta=100ps) ---
    % delta_BA = -theta < 0.  This is NOT a physical link configuration.
    % Tests solve_twtt sign convention only -- NOT run through waveform chain.
    tau = 0;  theta = 100e-12;
    fAB_theory = S * (tau + theta);
    fBA_theory = S * (tau - theta);
    [tau_hat, theta_hat] = solve_twtt(fAB_theory, fBA_theory, S);
    assert(abs(tau_hat - tau) < 1e-14, ...
        sprintf('T09 FAIL: tau_hat = %.2e s, expected 0', tau_hat));
    assert(abs(theta_hat - theta) < 1e-14, ...
        sprintf('T09 FAIL: theta error = %.2e s', theta_hat - theta));

    fprintf('  test_v1_two_way: T06-T09 PASSED\n');
end
