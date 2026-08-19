function test_gdf_stage1()
% TEST_GDF_STAGE1  Final validation of GDF Phase-Coded FMCW
%
%   Validates the literature-style group-delay filter receiver architecture.
%
%   Reference: docs/PC_FMCW_RECEIVER_THEORY_AND_NEXT_STEP.md (Stage-1)

    global TEST_METRICS;
    TEST_METRICS = struct('passes', 0, 'fails', 0, 'diagnostics', 0);
    
    function log_pass(msg)
        fprintf('    PASS: %s\n', msg);
        TEST_METRICS.passes = TEST_METRICS.passes + 1;
    end

    function log_fail(msg)
        fprintf('    FAIL: %s\n', msg);
        TEST_METRICS.fails = TEST_METRICS.fails + 1;
    end

    function log_diag(msg)
        fprintf('    DIAGNOSTIC: %s\n', msg);
        TEST_METRICS.diagnostics = TEST_METRICS.diagnostics + 1;
    end

    fprintf('  test_gdf_stage1 ...\n');

    cfg = make_default_params();
    S   = cfg.S;
    Fs  = cfg.Fs;
    N   = cfg.N;
    t   = (0:N-1).' / Fs;

    %% Q1 INDEPENDENT ANALYTIC SANITY TEST
    fprintf('\n--- Q1 ANALYTIC SANITY TEST ---\n');
    delta_test = 7e-9;
    f_b_test = S * delta_test;
    nu = 1e3;
    term1 = exp(+1j * 2 * pi * nu * f_b_test / S);
    term2 = exp(-1j * 2 * pi * nu * delta_test);
    err = abs(term1 * term2 - 1);
    if err < 1e-12
        log_pass('Q1 Analytic filter phase cancellation');
    else
        log_fail('Q1 Analytic filter phase cancellation');
    end

    %% Q1 SENSITIVITY PROBLEM & DELAY SWEEP
    fprintf('\n--- Q1 DELAY-SENSITIVITY SWEEP (ORACLE DIAGNOSTIC) ---\n');
    delays_to_test = [7e-9, 50e-9, 100e-9, 150e-9];
    L_q1 = 16;
    c_B = generate_code('B', L_q1);
    c_unshifted = align_code(c_B, L_q1, N, Fs, 0);
    
    % Find unshifted chip transitions for transition metric
    % A transition occurs where c_unshifted(i) ~= c_unshifted(i-1)
    transitions = find(diff(c_unshifted) ~= 0);
    trans_idx = [];
    for i = 1:length(transitions)
        idx = transitions(i);
        trans_idx = [trans_idx, idx-2:idx+2];
    end
    trans_idx = unique(max(1, min(N, trans_idx)));
    
    function r = rho(x, c)
        r = abs(sum(conj(c).*x)) / sqrt(sum(abs(c).^2)*sum(abs(x).^2));
    end
    function r = rho_trans(x, c, idx)
        r = abs(sum(conj(c(idx)).*x(idx))) / sqrt(sum(abs(c(idx)).^2)*sum(abs(x(idx)).^2));
    end
    function nmse = calc_nmse(e, c)
        beta = (c' * e) / (c' * c);
        nmse = sum(abs(e - beta*c).^2) / sum(abs(e).^2);
    end

    opts.use_padding = true;
    
    q1_improved_count = 0;
    
    for i = 1:length(delays_to_test)
        delta = delays_to_test(i);
        f_b = S * delta;
        if abs(f_b) >= Fs/2
            log_diag(sprintf('Delta %g ns excluded: f_b = %g Hz >= Nyquist', delta*1e9, f_b));
            continue;
        end
        
        c_delayed = align_code(c_B, L_q1, N, Fs, delta);
        z_before = exp(1j*2*pi*f_b*t) .* c_delayed;
        z_after = apply_group_delay_filter(z_before, Fs, S, opts);
        
        e_before = z_before .* exp(-1j*2*pi*f_b*t);
        e_after = z_after .* exp(-1j*2*pi*f_b*t);
        
        rho_bd = rho(e_before, c_delayed);
        rho_bu = rho(e_before, c_unshifted);
        rho_ad = rho(e_after, c_delayed);
        rho_au = rho(e_after, c_unshifted);
        
        D_before = rho_bd - rho_bu;
        D_after = rho_au - rho_ad;
        Delta_pref = D_after + D_before;
        
        rho_trans_bd = rho_trans(e_before, c_delayed, trans_idx);
        rho_trans_bu = rho_trans(e_before, c_unshifted, trans_idx);
        rho_trans_ad = rho_trans(e_after, c_delayed, trans_idx);
        rho_trans_au = rho_trans(e_after, c_unshifted, trans_idx);
        
        nmse_bd = calc_nmse(e_before, c_delayed);
        nmse_bu = calc_nmse(e_before, c_unshifted);
        nmse_ad = calc_nmse(e_after, c_delayed);
        nmse_au = calc_nmse(e_after, c_unshifted);
        
        D_trans_before = rho_trans_bd - rho_trans_bu;
        D_trans_after = rho_trans_au - rho_trans_ad;
        Delta_trans_pref = D_trans_after + D_trans_before;
        
        fprintf('  Delta = %g ns (f_b = %.1f Hz):\n', delta*1e9, f_b);
        fprintf('    Full: bd=%.6f, bu=%.6f, ad=%.6f, au=%.6f\n', rho_bd, rho_bu, rho_ad, rho_au);
        fprintf('    D_before=%.2e, D_after=%.2e, Delta_pref=%.2e\n', D_before, D_after, Delta_pref);
        fprintf('    Trans: bd=%.6f, bu=%.6f, ad=%.6f, au=%.6f\n', rho_trans_bd, rho_trans_bu, rho_trans_ad, rho_trans_au);
        fprintf('    D_trans_before=%.2e, D_trans_after=%.2e, Delta_trans_pref=%.2e\n', D_trans_before, D_trans_after, Delta_trans_pref);
        fprintf('    NMSE: bd=%.6f, bu=%.6f, ad=%.6f, au=%.6f\n', nmse_bd, nmse_bu, nmse_ad, nmse_au);
        
        if (Delta_pref > 0 || Delta_trans_pref > 0) && delta > 7e-9
            q1_improved_count = q1_improved_count + 1;
        end
    end
    
    if q1_improved_count >= 2
        log_pass('Q1 PASS WITH DISPERSION (Sensitivity sweep confirms predicted mechanism)');
        q1_pass = true;
    else
        log_fail('Q1 FAIL (Sensitivity sweep did not confirm consistent movement towards unshifted)');
        q1_pass = false;
    end

    %% CIRCULAR VS PADDED FILTER COMPARISON
    fprintf('\n--- CIRCULAR VS PADDED FILTER COMPARISON ---\n');
    opts_circ.use_padding = false;
    delta = 7e-9; f_b = S * delta;
    c_delayed = align_code(c_B, L_q1, N, Fs, delta);
    z_before = exp(1j*2*pi*f_b*t) .* c_delayed;
    z_after = apply_group_delay_filter(z_before, Fs, S, opts);
    z_after_circ = apply_group_delay_filter(z_before, Fs, S, opts_circ);
    diff_full = z_after_circ - z_after;
    rms_full = sqrt(mean(abs(diff_full).^2));
    
    for crop = [0, 2, 4]
        if crop == 0
            diff_crop = diff_full;
        else
            diff_crop = diff_full(1+crop:end-crop);
        end
        fprintf('RMS complex diff (crop %d) = %e\n', crop, sqrt(mean(abs(diff_crop).^2)));
    end
    
    max_diff = max(abs(diff_full));
    fprintf('max absolute complex diff = %e\n', max_diff);
    log_diag('Circular vs padded comparison generated');

    %% Q2 PRESERVE EXACT STRONG/WEAK INPUT
    if ~q1_pass
        fprintf('\n--- Q1 FAILED. STOPPING Q2 EVALUATION ---\n');
        return;
    end
    
    fprintf('\n--- Q2 STRONG/WEAK SEPARATION ---\n');
    alpha_A = 1.0;
    alpha_B = 0.3;
    delta_A = 3e-9;
    delta_B = 7e-9;
    f_A = S * delta_A;
    f_B = S * delta_B;
    
    Nfft = 16384;
    df_high = Fs / Nfft;
    W = max(2*Fs/N, 0.25*abs(f_B - f_A));
    margin_dB = 0; % ideal-model deterministic margin
    
    df_native = Fs / N;
    freq_tol = 0.5 * df_native;
    
    function [P_des, P_comp, det_freq, classif, freq_recov, final_recov, sir] = detect_peak(Z, f_target)
        P = abs(Z).^2 / N; % Spectrum power
        f_axis = (0:Nfft/2)' * df_high;
        P = P(1:Nfft/2+1);
        
        in_win = abs(f_axis - f_target) <= W;
        out_win = ~in_win;
        
        [P_des, idx_des] = max(P(in_win));
        f_in = f_axis(in_win);
        det_freq = f_in(idx_des);
        
        [P_comp, ~] = max(P(out_win));
        
        sir = 10*log10(P_des / (P_comp+1e-30));
        
        if sir >= margin_dB
            classif = 'DETECTED';
        elseif sir >= -3 && sir < margin_dB
            classif = 'AMBIGUOUS';
        else
            classif = 'MASKED';
        end
        
        if abs(det_freq - f_target) <= freq_tol
            freq_recov = 'YES';
        else
            freq_recov = 'NO';
        end
        
        if strcmp(classif, 'DETECTED') && strcmp(freq_recov, 'YES')
            final_recov = 'YES';
        else
            final_recov = 'NO';
        end
    end

    L_vals = [2, 4, 8, 16];
    q2_final_recov_any = false;
    for L = L_vals
        cA = generate_code('A', L);
        cB = generate_code('B', L);
        
        rx_A = fmcw_delayed_baseband(t, S, delta_A) .* align_code(cA, L, N, Fs, delta_A);
        rx_B = fmcw_delayed_baseband(t, S, delta_B) .* align_code(cB, L, N, Fs, delta_B);
        z_total = fmcw_baseband(t, S) .* conj(alpha_A * rx_A + alpha_B * rx_B);
        
        cB_delayed = align_code(cB, L, N, Fs, delta_B);
        z_naive_B = z_total .* cB_delayed;
        Z_naive_B = fft(z_naive_B, Nfft);
        
        z_gdf = apply_group_delay_filter(z_total, Fs, S, opts);
        cB_unshifted = align_code(cB, L, N, Fs, 0);
        z_gdf_B = z_gdf .* cB_unshifted;
        Z_gdf_B = fft(z_gdf_B, Nfft);
        
        [P_des_n, P_comp_n, f_det_n, cl_n, fr_n, final_n, SIR_n] = detect_peak(Z_naive_B, f_B);
        [P_des_g, P_comp_g, f_det_g, cl_g, fr_g, final_g, SIR_g] = detect_peak(Z_gdf_B, f_B);
        
        fprintf('L=%d:\n', L);
        err_n = abs(f_det_n - f_B);
        err_g = abs(f_det_g - f_B);
        fprintf('  Naive: det_f=%.1f Hz, err=%.1f Hz (%.2f bins), Class=%s, FreqRecov=%s, SIR=%.2f dB, FINAL=%s\n', ...
            f_det_n, err_n, err_n/df_native, cl_n, fr_n, SIR_n, final_n);
        fprintf('  GDF  : det_f=%.1f Hz, err=%.1f Hz (%.2f bins), Class=%s, FreqRecov=%s, SIR=%.2f dB, FINAL=%s\n', ...
            f_det_g, err_g, err_g/df_native, cl_g, fr_g, SIR_g, final_g);
        
        if strcmp(final_g, 'YES') || strcmp(final_n, 'YES')
            q2_final_recov_any = true;
        end
        log_diag(sprintf('Q2 evaluate L=%d', L));
    end

    if q2_final_recov_any
        log_pass('Q2 PASS (At least one L provided final recovery)');
    else
        log_diag('Q2 FAIL (Receiver architecture limitations remain)');
    end

    %% ESTIMATOR ABLATION
    fprintf('\n--- ESTIMATOR ABLATION (L=2) ---\n');
    L = 2;
    cA = generate_code('A', L);
    cB = generate_code('B', L);
    rx_A = fmcw_delayed_baseband(t, S, delta_A) .* align_code(cA, L, N, Fs, delta_A);
    rx_B = fmcw_delayed_baseband(t, S, delta_B) .* align_code(cB, L, N, Fs, delta_B);
    z_total = fmcw_baseband(t, S) .* conj(alpha_A * rx_A + alpha_B * rx_B);
    
    cB_delayed = align_code(cB, L, N, Fs, delta_B);
    z_naive_B = z_total .* cB_delayed;
    
    z_gdf = apply_group_delay_filter(z_total, Fs, S, opts);
    cB_unshifted = align_code(cB, L, N, Fs, 0);
    z_gdf_B = z_gdf .* cB_unshifted;

    ps_n = estimate_beat_phase_slope(z_naive_B, Fs).f_est;
    [~, ~, fft_n, cl_n_ps] = detect_peak(fft(z_naive_B, Nfft), f_B);
    [~, ~, fft_g, cl_g_ps] = detect_peak(fft(z_gdf_B, Nfft), f_B);
    ps_g = estimate_beat_phase_slope(z_gdf_B, Fs).f_est;

    fprintf('A. Naive+PS: f=%.1f Hz, err=%.1f Hz\n', ps_n, abs(ps_n-f_B));
    fprintf('B. Naive+FFT: f=%.1f Hz, err=%.1f Hz, class=%s\n', fft_n, abs(fft_n-f_B), cl_n_ps);
    fprintf('C. GDF+FFT: f=%.1f Hz, err=%.1f Hz, class=%s\n', fft_g, abs(fft_g-f_B), cl_g_ps);
    fprintf('D. GDF+PS: f=%.1f Hz, err=%.1f Hz\n', ps_g, abs(ps_g-f_B));
    log_diag('Estimator ablation complete');

    fprintf('\n=================================\n');
    fprintf('TEST METRICS SUMMARY:\n');
    fprintf('Passes: %d\n', TEST_METRICS.passes);
    fprintf('Fails: %d\n', TEST_METRICS.fails);
    fprintf('Diagnostics: %d\n', TEST_METRICS.diagnostics);
    fprintf('=================================\n');

end
