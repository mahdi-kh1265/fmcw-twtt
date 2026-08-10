function test_v0_single_link()
% TEST_V0_SINGLE_LINK  Tests T01-T05: zero, known, sub-bin, ps, half-sample delays.
%
%   Tolerances from spec Section F.3:
%     delta = 0:  |f_hat| < 1e-6 Hz
%     delta > 0:  |f_hat - S*delta| / (S*delta) < 1e-10

    cfg = make_default_params();
    S  = cfg.S;
    Fs = cfg.Fs;

    % --- T01: Zero delay ---
    link = simulate_ideal_link(cfg, 0);
    est  = estimate_beat_phase_slope(link.beat, Fs);
    assert(abs(est.f_est) < 1e-6, ...
        sprintf('T01 FAIL: f_hat = %.6e Hz, expected ~0', est.f_est));

    % --- T02: Nanosecond delay (5 ns) ---
    delta = 5e-9;
    link  = simulate_ideal_link(cfg, delta);
    est   = estimate_beat_phase_slope(link.beat, Fs);
    fb_exp = S * delta;
    rel_err = abs(est.f_est - fb_exp) / fb_exp;
    assert(rel_err < 1e-10, ...
        sprintf('T02 FAIL: rel_err=%.2e  (f_hat=%.6f, expected=%.6f)', ...
        rel_err, est.f_est, fb_exp));

    % --- T03: Sub-bin delay (100 ps) ---
    delta = 100e-12;
    link  = simulate_ideal_link(cfg, delta);
    est   = estimate_beat_phase_slope(link.beat, Fs);
    fb_exp = S * delta;
    rel_err = abs(est.f_est - fb_exp) / fb_exp;
    assert(rel_err < 1e-10, ...
        sprintf('T03 FAIL: rel_err=%.2e  (f_hat=%.6f, expected=%.6f)', ...
        rel_err, est.f_est, fb_exp));

    % --- T04: Picosecond delay (10 ps) ---
    delta = 10e-12;
    link  = simulate_ideal_link(cfg, delta);
    est   = estimate_beat_phase_slope(link.beat, Fs);
    fb_exp = S * delta;
    rel_err = abs(est.f_est - fb_exp) / fb_exp;
    assert(rel_err < 1e-10, ...
        sprintf('T04 FAIL: rel_err=%.2e  (f_hat=%.6f, expected=%.6f)', ...
        rel_err, est.f_est, fb_exp));

    % --- T05: Half-sample delay (50 ns) ---
    delta = 0.5 / Fs;
    link  = simulate_ideal_link(cfg, delta);
    est   = estimate_beat_phase_slope(link.beat, Fs);
    fb_exp = S * delta;
    rel_err = abs(est.f_est - fb_exp) / fb_exp;
    assert(rel_err < 1e-10, ...
        sprintf('T05 FAIL: rel_err=%.2e  (f_hat=%.6f, expected=%.6f)', ...
        rel_err, est.f_est, fb_exp));

    fprintf('  test_v0_single_link: T01-T05 PASSED\n');
end
