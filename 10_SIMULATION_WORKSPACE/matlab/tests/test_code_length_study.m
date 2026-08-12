function test_code_length_study()
% TEST_CODE_LENGTH_STUDY  Walsh code-length / chip-rate study.
%
%   Tests L = 2, 4, 8, 16 with fixed amplitude ratio alpha_A = 1.0,
%   alpha_B = 0.3. For each code length, reports:
%     - target spectral peak power [dB]
%     - residual cross-code leakage power [dB]
%     - post-despreading SIR [dB]
%     - suppression / isolation [dB]
%     - weak-node beat-frequency error
%
%   This is a controlled study; amplitude ratios are NOT cherry-picked.

    cfg = make_default_params();
    S   = cfg.S;
    Fs  = cfg.Fs;
    N   = cfg.N;
    t   = (0:N-1).' / Fs;

    delta_A = 3e-9;
    delta_B = 7e-9;
    alpha_A = 1.0;
    alpha_B = 0.3;

    f_A_true = S * delta_A;
    f_B_true = S * delta_B;

    L_values = [2, 4, 8, 16];

    fprintf('  test_code_length_study ...\n');
    fprintf('    alpha_A = %.1f, alpha_B = %.1f\n', alpha_A, alpha_B);
    fprintf('    delta_A = %.0f ns -> f_A = %.1f kHz\n', delta_A*1e9, f_A_true/1e3);
    fprintf('    delta_B = %.0f ns -> f_B = %.1f kHz\n', delta_B*1e9, f_B_true/1e3);
    fprintf('    %-4s  %-8s  %-10s  %-10s  %-10s  %-10s  %-10s  %-10s\n', ...
            'L', 'N_chip', 'P_A [dB]', 'P_B [dB]', 'Leak_A', 'Leak_B', 'SIR_B [dB]', 'f_B err');
    fprintf('    %s\n', repmat('-', 1, 80));

    lo = fmcw_baseband(t, S);

    for L_idx = 1:length(L_values)
        L = L_values(L_idx);
        N_chip = N / L;

        if mod(N, L) ~= 0
            fprintf('    L = %d: skipped (N not divisible)\n', L);
            continue;
        end

        % Generate codes for two stations (rows 1 and 2 of Hadamard matrix)
        code_A = generate_code('A', L);
        code_B = generate_code('B', L);

        % Verify orthogonality
        assert(sum(code_A .* code_B) == 0, ...
               'Codes A,B not orthogonal for L=%d', L);

        % Build received coded signals
        rx_fmcw_A = fmcw_delayed_baseband(t, S, delta_A);
        c_A_rx = align_code(code_A, L, N, Fs, delta_A);
        rx_coded_A = rx_fmcw_A .* c_A_rx;

        rx_fmcw_B = fmcw_delayed_baseband(t, S, delta_B);
        c_B_rx = align_code(code_B, L, N, Fs, delta_B);
        rx_coded_B = rx_fmcw_B .* c_B_rx;

        % Composite signal
        z_composite = lo .* conj(alpha_A * rx_coded_A + alpha_B * rx_coded_B);

        % Despread with code A (targeting station A)
        z_ds_A = z_composite .* c_A_rx;

        % Despread with code B (targeting station B)
        z_ds_B = z_composite .* c_B_rx;

        % Spectral analysis
        Z_A = fft(z_ds_A);
        Z_B = fft(z_ds_B);
        P_A = abs(Z_A).^2 / N;
        P_B = abs(Z_B).^2 / N;

        % Find peaks
        [peak_A, ~] = max(P_A(1:floor(N/2)));
        [peak_B, ~] = max(P_B(1:floor(N/2)));

        % Leakage: power at the "other" station's frequency bin
        % Find the bin nearest to the expected target frequency
        freq_axis = (0:N-1)' * Fs / N;
        [~, bin_A] = min(abs(freq_axis(1:floor(N/2)) - f_A_true));
        [~, bin_B] = min(abs(freq_axis(1:floor(N/2)) - f_B_true));

        % When despreading with code A, the target is station A (bin_A),
        % leakage from B appears at bin_B
        leak_at_B_in_A = P_A(bin_B);
        leak_at_A_in_B = P_B(bin_A);

        % SIR for weak station B: target peak vs leakage from A
        SIR_B = 10*log10(peak_B / (leak_at_A_in_B + 1e-30));

        % Beat frequency estimation
        f_A_hat = estimate_beat_phase_slope(z_ds_A, Fs).f_est;
        f_B_hat = estimate_beat_phase_slope(z_ds_B, Fs).f_est;

        f_A_err = abs(f_A_hat - f_A_true);
        f_B_err = abs(f_B_hat - f_B_true);

        fprintf('    %-4d  %-8d  %-10.1f  %-10.1f  %-10.1f  %-10.1f  %-10.1f  %-10.1f\n', ...
                L, N_chip, ...
                10*log10(peak_A + 1e-30), 10*log10(peak_B + 1e-30), ...
                10*log10(leak_at_B_in_A + 1e-30), 10*log10(leak_at_A_in_B + 1e-30), ...
                SIR_B, f_B_err);
    end

    fprintf('  test_code_length_study: COMPLETE (results above)\n');
end
