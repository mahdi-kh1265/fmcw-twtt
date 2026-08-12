% demo_v2b_coding.m
% V2b: Phase-Coded FMCW demonstration.
%
% Generates:
%   figures/fig10_code_correlation       -- despreading correct vs wrong code
%   figures/fig11_coded_signal_separation -- two-transmitter separation
%   figures/fig12_code_misalignment      -- misalignment degradation/recovery
%
% Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section G.2

%% Setup
cfg = make_default_params();
sty = fig_style();
S   = cfg.S;
Fs  = cfg.Fs;
N   = cfg.N;
L   = 2;
t   = (0:N-1).' / Fs;
Tobs   = N / Fs;
T_chip = Tobs / L;
N_chip = N / L;

code_A = generate_code('A', L);
code_B = generate_code('B', L);

%% Output directory
script_dir = fileparts(mfilename('fullpath'));
fig_dir    = fullfile(script_dir, '..', 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

%% Print summary
fprintf('\n');
fprintf('====================================================\n');
fprintf('  FMCW V2b -- PHASE-CODED FMCW RESULT\n');
fprintf('====================================================\n');
fprintf('  Code type:         Walsh-Hadamard, L = %d\n', L);
fprintf('  Code A:            %s\n', mat2str(code_A));
fprintf('  Code B:            %s\n', mat2str(code_B));
fprintf('  T_chip:            %.1f us\n', T_chip * 1e6);
fprintf('  N_chip:            %d samples\n', N_chip);
fprintf('  Orthogonality:     sum(A.*B) = %d\n', sum(code_A .* code_B));
fprintf('  ----\n');

% Single coded transmitter test
delta_test = 5e-9;
s_tx_B = generate_coded_chirp(t, S, code_B, L);
lo = fmcw_baseband(t, S);

% Build received coded signal at small delay
s_rx_fmcw = fmcw_delayed_baseband(t, S, delta_test);
c_B_shifted = align_code(code_B, L, N, Fs, delta_test);
rx_coded = s_rx_fmcw .* c_B_shifted;
z_dechirp = lo .* conj(rx_coded);

% Despread with correct code
z_correct = z_dechirp .* c_B_shifted;
f_correct = estimate_beat_phase_slope(z_correct, Fs).f_est;

% Despread with wrong code — SIR metrics (not frequency)
c_A_shifted = align_code(code_A, L, N, Fs, delta_test);
z_wrong = z_dechirp .* c_A_shifted;

% SIR: spectral power at target vs residual
Z_correct = fft(z_correct);
Z_wrong   = fft(z_wrong);
P_correct = abs(Z_correct).^2 / N;
P_wrong   = abs(Z_wrong).^2 / N;
[peak_correct, ~] = max(P_correct(1:floor(N/2)));
[peak_wrong, ~]   = max(P_wrong(1:floor(N/2)));
suppression_dB = 10*log10(peak_correct / (peak_wrong + 1e-30));

fprintf('  Single coded TX (code B, delta = %.1f ns):\n', delta_test*1e9);
fprintf('    Correct code despread:  f = %.1f Hz (theory: %.1f Hz)\n', ...
        f_correct, S*delta_test);
fprintf('    Wrong code:             peak suppression = %.1f dB\n', suppression_dB);

% Two-transmitter test
delta_A = 3e-9;
delta_B = 7e-9;
alpha_A = 1.0;
alpha_B = 0.3;

s_rx_A = fmcw_delayed_baseband(t, S, delta_A);
c_A_at_rx = align_code(code_A, L, N, Fs, delta_A);
rx_coded_A = s_rx_A .* c_A_at_rx;

s_rx_B2 = fmcw_delayed_baseband(t, S, delta_B);
c_B_at_rx = align_code(code_B, L, N, Fs, delta_B);
rx_coded_B2 = s_rx_B2 .* c_B_at_rx;

z_composite = lo .* conj(alpha_A * rx_coded_A + alpha_B * rx_coded_B2);

z_ds_A = z_composite .* c_A_at_rx;
z_ds_B = z_composite .* c_B_at_rx;
f_A_hat = estimate_beat_phase_slope(z_ds_A, Fs).f_est;
f_B_hat = estimate_beat_phase_slope(z_ds_B, Fs).f_est;

% SIR metrics
Z_ds_A = fft(z_ds_A); P_ds_A = abs(Z_ds_A).^2 / N;
Z_ds_B = fft(z_ds_B); P_ds_B = abs(Z_ds_B).^2 / N;
freq_axis = (0:N-1)' * Fs / N;
[~, bin_A] = min(abs(freq_axis(1:floor(N/2)) - S*delta_A));
[~, bin_B] = min(abs(freq_axis(1:floor(N/2)) - S*delta_B));
SIR_A_dB = 10*log10(P_ds_A(bin_A) / (P_ds_A(bin_B) + 1e-30));
SIR_B_dB = 10*log10(P_ds_B(bin_B) / (P_ds_B(bin_A) + 1e-30));

fprintf('  ----\n');
fprintf('  Two coded transmitters (alpha_A=%.1f, alpha_B=%.1f):\n', alpha_A, alpha_B);
fprintf('    Code A despread:  f = %.1f Hz (theory: %.1f Hz), SIR = %.1f dB\n', ...
        f_A_hat, S*delta_A, SIR_A_dB);
f_B_err = abs(f_B_hat - S*delta_B);
fprintf('    Code B despread:  f = %.1f Hz (theory: %.1f Hz), SIR = %.1f dB\n', ...
        f_B_hat, S*delta_B, SIR_B_dB);
if f_B_err / (S*delta_B) > 0.01
    fprintf('    NOTE: Weak station B beat NOT cleanly recovered (L=2 limitation)\n');
end
fprintf('  ----\n');
fprintf('  NOTE: All results are from the ideal noise-free model.\n');
fprintf('====================================================\n\n');

%% ========== Figure 10: Code Correlation / Node Identity ==========
fig10 = figure('Position', sty.fig_wide, 'Color', 'w', 'Visible', 'off');

N_half = floor(N/2);
freq_kHz = (0:N_half)' * Fs / N / 1e3;

% Panel (a): Correct code despreading
subplot(2,1,1);
fft_correct = estimate_beat_fft(z_correct, Fs);
mag_correct_dB = 20*log10(fft_correct.spectrum_mag(1:N_half+1) / max(fft_correct.spectrum_mag) + 1e-30);
plot(freq_kHz, mag_correct_dB, '-', 'Color', sty.c_blue, 'LineWidth', sty.lw_data);
xlabel('Frequency [kHz]'); ylabel('|Z(f)| [dB]');
title('(a)  Despread with CORRECT code (B):  clean beat', 'FontSize', sty.fs_title);
xlim([0 500]); ylim([-60 5]);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

% Panel (b): Wrong code despreading
subplot(2,1,2);
fft_wrong = estimate_beat_fft(z_wrong, Fs);
mag_wrong_dB = 20*log10(fft_wrong.spectrum_mag(1:N_half+1) / max(fft_wrong.spectrum_mag) + 1e-30);
plot(freq_kHz, mag_wrong_dB, '-', 'Color', sty.c_red, 'LineWidth', sty.lw_data);
xlabel('Frequency [kHz]'); ylabel('|Z(f)| [dB]');
title('(b)  Despread with WRONG code (A):  energy spread/scrambled', 'FontSize', sty.fs_title);
xlim([0 500]); ylim([-60 5]);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

try
    sgtitle('Ideal noise-free model  |  Walsh-2 binary phase coding', ...
            'FontSize', sty.fs_subtitle, 'Color', sty.c_gray);
catch
    annotation('textbox', [0.15 0.94 0.7 0.05], ...
               'String', 'Ideal noise-free model  |  Walsh-2 binary phase coding', ...
               'FontSize', sty.fs_subtitle, 'Color', sty.c_gray, ...
               'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end

save_fig(fig10, fullfile(fig_dir, 'fig10_code_correlation'));
close(fig10);
fprintf('  Saved: figures/fig10_code_correlation.png\n');

%% ========== Figure 11: Two-Transmitter Signal Separation ==========
fig11 = figure('Position', sty.fig_tall, 'Color', 'w', 'Visible', 'off');

% Panel (a): Composite spectrum
subplot(3,1,1);
fft_comp = estimate_beat_fft(z_composite, Fs);
mag_comp_dB = 20*log10(fft_comp.spectrum_mag(1:N_half+1) / max(fft_comp.spectrum_mag) + 1e-30);
plot(freq_kHz, mag_comp_dB, '-', 'Color', sty.c_black, 'LineWidth', sty.lw_data);
xlabel('Frequency [kHz]'); ylabel('|Z(f)| [dB]');
title(sprintf('(a)  Composite: two coded TXs (\\alpha_A=%.1f, \\alpha_B=%.1f)', ...
      alpha_A, alpha_B), 'FontSize', sty.fs_title);
xlim([0 500]); ylim([-60 5]);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

% Panel (b): Despreaded with code A
subplot(3,1,2);
fft_dsA = estimate_beat_fft(z_ds_A, Fs);
mag_dsA_dB = 20*log10(fft_dsA.spectrum_mag(1:N_half+1) / max(fft_dsA.spectrum_mag) + 1e-30);
plot(freq_kHz, mag_dsA_dB, '-', 'Color', sty.c_blue, 'LineWidth', sty.lw_data); hold on;
xline(S*delta_A/1e3, '--', 'Color', sty.c_black, 'LineWidth', 0.6);
xlabel('Frequency [kHz]'); ylabel('|Z(f)| [dB]');
title(sprintf('(b)  Despread code A:  f = %.1f kHz (station A)', S*delta_A/1e3), ...
      'FontSize', sty.fs_title);
xlim([0 500]); ylim([-60 5]);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

% Panel (c): Despreaded with code B
subplot(3,1,3);
fft_dsB = estimate_beat_fft(z_ds_B, Fs);
mag_dsB_dB = 20*log10(fft_dsB.spectrum_mag(1:N_half+1) / max(fft_dsB.spectrum_mag) + 1e-30);
plot(freq_kHz, mag_dsB_dB, '-', 'Color', sty.c_red, 'LineWidth', sty.lw_data); hold on;
xline(S*delta_B/1e3, '--', 'Color', sty.c_black, 'LineWidth', 0.6);
xlabel('Frequency [kHz]'); ylabel('|Z(f)| [dB]');
title(sprintf('(c)  Despread code B:  f = %.1f kHz (station B)', S*delta_B/1e3), ...
      'FontSize', sty.fs_title);
xlim([0 500]); ylim([-60 5]);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

try
    sgtitle('Ideal noise-free model  |  Walsh-2 binary phase coding', ...
            'FontSize', sty.fs_subtitle, 'Color', sty.c_gray);
catch
    annotation('textbox', [0.15 0.94 0.7 0.05], ...
               'String', 'Ideal noise-free model  |  Walsh-2 binary phase coding', ...
               'FontSize', sty.fs_subtitle, 'Color', sty.c_gray, ...
               'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end

save_fig(fig11, fullfile(fig_dir, 'fig11_coded_signal_separation'));
close(fig11);
fprintf('  Saved: figures/fig11_coded_signal_separation.png\n');

%% ========== Figure 12: Code Misalignment Degradation/Recovery ==========
fig12 = figure('Position', sty.fig_wide, 'Color', 'w', 'Visible', 'off');

% Sweep the despreading code alignment error from 0 to T_chip
% For each alignment error, compute beat frequency estimation quality.
delta_base = 50e-9;  % small physical delay (f_beat within Nyquist)
f_beat_true = S * delta_base;

% Build received signal once
s_rx_base = fmcw_delayed_baseband(t, S, delta_base);
c_rx_true = align_code(code_B, L, N, Fs, delta_base);
rx_base = s_rx_base .* c_rx_true;
z_base = lo .* conj(rx_base);

% Sweep alignment offsets from 0 to T_chip
n_offsets = 50;
offset_frac = linspace(0, 1, n_offsets);
f_naive_sweep  = zeros(n_offsets, 1);
f_aligned_sweep = zeros(n_offsets, 1);

for k = 1:n_offsets
    % Despreading with code shifted by (delta_base + offset * T_chip)
    offset_s = offset_frac(k) * T_chip;

    % "Wrong" alignment: use offset code
    c_wrong_k = align_code(code_B, L, N, Fs, delta_base + offset_s);
    z_wrong_k = z_base .* c_wrong_k;
    f_naive_sweep(k) = estimate_beat_phase_slope(z_wrong_k, Fs).f_est;

    % "Correct" alignment: use true delay
    c_correct_k = align_code(code_B, L, N, Fs, delta_base);
    z_correct_k = z_base .* c_correct_k;
    f_aligned_sweep(k) = estimate_beat_phase_slope(z_correct_k, Fs).f_est;
end

% Compute relative frequency estimation error
err_naive  = abs(f_naive_sweep - f_beat_true) / f_beat_true;
err_aligned = abs(f_aligned_sweep - f_beat_true) / f_beat_true;

semilogy(offset_frac, err_naive, '-', 'Color', sty.c_red, 'LineWidth', sty.lw_data); hold on;
semilogy(offset_frac, err_aligned + 1e-18, '--', 'Color', sty.c_green, 'LineWidth', sty.lw_data);

xlabel('Alignment error  [fraction of T_{chip}]', 'FontSize', sty.fs_axis);
ylabel('|f_{est} - f_{true}| / f_{true}', 'FontSize', sty.fs_axis);
title('V2b:  Beat estimation error vs. code alignment offset', 'FontSize', sty.fs_title);
lg = legend('Misaligned code', 'Correctly aligned', 'Location', 'northwest');
set(lg, 'FontSize', sty.fs_legend);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

try
    sgtitle('Ideal noise-free model  |  Walsh-2, \\delta = 50 ns', ...
            'FontSize', sty.fs_subtitle, 'Color', sty.c_gray);
catch
    annotation('textbox', [0.15 0.94 0.7 0.05], ...
               'String', 'Ideal noise-free model  |  Walsh-2, delta = 50 ns', ...
               'FontSize', sty.fs_subtitle, 'Color', sty.c_gray, ...
               'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end

save_fig(fig12, fullfile(fig_dir, 'fig12_code_misalignment'));
close(fig12);
fprintf('  Saved: figures/fig12_code_misalignment.png\n');
