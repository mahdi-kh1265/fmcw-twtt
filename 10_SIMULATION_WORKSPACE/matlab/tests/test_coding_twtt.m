function test_coding_twtt()
% TEST_CODING_TWTT  Coded TWTT recovery test P10.
%
%   Validates that coded two-way processing with aligned despreading
%   preserves the injected tau and theta to V1 tolerance.
%
%   Circularity mitigation: in addition to the TWTT end-to-end check,
%   each direction's beat frequency is verified independently against
%   the analytic oracle f_expected = S * delta (which does NOT depend
%   on align_code or any coded helper).
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section F.2

    cfg = make_default_params();
    S   = cfg.S;
    Fs  = cfg.Fs;
    N   = cfg.N;
    L   = 2;
    t   = (0:N-1).' / Fs;

    tau   = 5e-9;
    theta = 100e-12;
    abs_tol_s = 1e-14;
    rel_tol   = 1e-10;

    code_A = generate_code('A', L);
    code_B = generate_code('B', L);

    fprintf('  test_coding_twtt ...\n');

    %% P10: Coded TWTT preserves tau and theta
    delta_AB = tau + theta;
    delta_BA = tau - theta;

    % Independent analytic oracle (no coded helpers used)
    f_AB_expected = S * delta_AB;
    f_BA_expected = S * delta_BA;

    lo = fmcw_baseband(t, S);

    % ---- A->B direction ----
    % A transmits with code_A, arrives at B delayed by delta_AB.
    rx_fmcw_AB = fmcw_delayed_baseband(t, S, delta_AB);
    c_A_at_rx  = align_code(code_A, L, N, Fs, delta_AB);
    rx_coded_AB = rx_fmcw_AB .* c_A_at_rx;

    % B dechirps with uncoded LO, then despreads with aligned code A
    z_AB = lo .* conj(rx_coded_AB);
    z_AB_despread = z_AB .* c_A_at_rx;

    f_AB = estimate_beat_phase_slope(z_AB_despread, Fs).f_est;

    % Independent oracle check (breaks circularity)
    assert(abs(f_AB - f_AB_expected) / abs(f_AB_expected) < rel_tol, ...
           'P10: coded A->B f = %.4f Hz, oracle = %.4f Hz', f_AB, f_AB_expected);

    % ---- B->A direction ----
    rx_fmcw_BA = fmcw_delayed_baseband(t, S, delta_BA);
    c_B_at_rx  = align_code(code_B, L, N, Fs, delta_BA);
    rx_coded_BA = rx_fmcw_BA .* c_B_at_rx;

    z_BA = lo .* conj(rx_coded_BA);
    z_BA_despread = z_BA .* c_B_at_rx;

    f_BA = estimate_beat_phase_slope(z_BA_despread, Fs).f_est;

    % Independent oracle check (breaks circularity)
    assert(abs(f_BA - f_BA_expected) / abs(f_BA_expected) < rel_tol, ...
           'P10: coded B->A f = %.4f Hz, oracle = %.4f Hz', f_BA, f_BA_expected);

    % ---- Solve TWTT ----
    [tau_hat, theta_hat] = solve_twtt(f_AB, f_BA, S);

    assert(abs(tau_hat - tau) < abs_tol_s, ...
           'P10: coded TWTT tau error = %.2e s', abs(tau_hat - tau));
    assert(abs(theta_hat - theta) < abs_tol_s, ...
           'P10: coded TWTT theta error = %.2e s', abs(theta_hat - theta));

    fprintf('    P10 PASS: Coded TWTT: f_AB oracle err = %.1e, f_BA oracle err = %.1e\n', ...
            abs(f_AB - f_AB_expected), abs(f_BA - f_BA_expected));
    fprintf('              tau_err = %.1e s, theta_err = %.1e s\n', ...
            abs(tau_hat - tau), abs(theta_hat - theta));

    fprintf('  test_coding_twtt: ALL PASS\n');
end

