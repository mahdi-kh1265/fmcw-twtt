function test_fractional_delay()
% TEST_FRACTIONAL_DELAY  T10: multiple non-grid delays all recovered exactly.
%
%   Tolerance: |f_hat - S*delta| / (S*delta) < 1e-10 for each delay.

    cfg = make_default_params();
    S  = cfg.S;
    Fs = cfg.Fs;

    delays = [10e-12, 37e-12, 123.456e-12, 1.234e-9, 7.891e-9];

    for i = 1:length(delays)
        delta  = delays(i);
        link   = simulate_ideal_link(cfg, delta);
        est    = estimate_beat_phase_slope(link.beat, Fs);
        fb_exp = S * delta;
        rel_err = abs(est.f_est - fb_exp) / fb_exp;
        assert(rel_err < 1e-10, ...
            sprintf('T10 FAIL at delta=%.3e s: rel_err=%.2e (f=%.6f, exp=%.6f)', ...
            delta, rel_err, est.f_est, fb_exp));
    end

    fprintf('  test_fractional_delay: T10 PASSED\n');
end
