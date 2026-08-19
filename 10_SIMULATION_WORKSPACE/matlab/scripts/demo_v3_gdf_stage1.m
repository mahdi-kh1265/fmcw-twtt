% demo_v3_gdf_stage1.m
% V3: Group-Delay Filter (GDF) Stage-1 demonstration.
%
% Generates:
%   figures/fig13_single_node_alignment.png
%   figures/fig14_two_node_spectra.png
%   figures/fig15_estimator_ablation.png
%   figures/fig16_code_length_study.png
%
% Reference: docs/PC_FMCW_RECEIVER_THEORY_AND_NEXT_STEP.md (Stage-1)

%% Setup
cfg = make_default_params();
sty = fig_style();
S   = cfg.S;
Fs  = cfg.Fs;
N   = cfg.N;
L_default = 2;
t   = (0:N-1).' / Fs;

script_dir = fileparts(mfilename('fullpath'));
fig_dir    = fullfile(script_dir, '..', 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

fprintf('\n====================================================\n');
fprintf('  FMCW GDF STAGE-1 -- GROUP-DELAY FILTER DEMO\n');
fprintf('====================================================\n\n');

%% ========== Single-Node Alignment (Figure 13) ==========
delta_A = 3e-9;
f_A = S * delta_A;
code_A = generate_code('A', L_default);

% Uncoded LO
lo = fmcw_baseband(t, S);

% Single delayed coded node
s_rx_A = fmcw_delayed_baseband(t, S, delta_A) .* align_code(code_A, L_default, N, Fs, delta_A);
z_A_coded = lo .* conj(s_rx_A);

% Filtered
z_A_filt = apply_group_delay_filter(z_A_coded, Fs, S);

% Despread with unshifted code A
c_A_unshifted = align_code(code_A, L_default, N, Fs, 0);
z_A_ds_naive = z_A_coded .* c_A_unshifted;
z_A_ds_filt = z_A_filt .* c_A_unshifted;

% Spectra
N_half = floor(N/2);
freq_kHz = (0:N_half)' * Fs / N / 1e3;
fft_naive_A = estimate_beat_fft(z_A_ds_naive, Fs);
fft_filt_A = estimate_beat_fft(z_A_ds_filt, Fs);
mag_naive_A_dB = 20*log10(fft_naive_A.spectrum_mag(1:N_half+1) / max(fft_filt_A.spectrum_mag) + 1e-30);
mag_filt_A_dB = 20*log10(fft_filt_A.spectrum_mag(1:N_half+1) / max(fft_filt_A.spectrum_mag) + 1e-30);

fig13 = figure('Position', sty.fig_wide, 'Color', 'w', 'Visible', 'off');
subplot(2,1,1);
plot(freq_kHz, mag_naive_A_dB, '-', 'Color', sty.c_red, 'LineWidth', sty.lw_data); hold on;
xline(f_A/1e3, '--', 'Color', sty.c_black, 'LineWidth', 0.6);
xlabel('Frequency [kHz]'); ylabel('|Z(f)| [dB]');
title('(a) Naive Receiver: Despread with unshifted code (misaligned)', 'FontSize', sty.fs_title);
xlim([0 500]); ylim([-60 5]);
set(gca, 'FontSize', sty.fs_tick); grid on; set(gca, 'GridAlpha', 0.25);

subplot(2,1,2);
plot(freq_kHz, mag_filt_A_dB, '-', 'Color', sty.c_green, 'LineWidth', sty.lw_data); hold on;
xline(f_A/1e3, '--', 'Color', sty.c_black, 'LineWidth', 0.6);
xlabel('Frequency [kHz]'); ylabel('|Z(f)| [dB]');
title('(b) GDF Receiver: Despread with unshifted code (aligned)', 'FontSize', sty.fs_title);
xlim([0 500]); ylim([-60 5]);
set(gca, 'FontSize', sty.fs_tick); grid on; set(gca, 'GridAlpha', 0.25);

try
    sgtitle('FIG 13: Single-Node Code Alignment (IDEAL / NOISE-FREE FAST-TIME PC-FMCW CONCEPT)', ...
            'FontSize', sty.fs_subtitle, 'Color', sty.c_gray);
catch
    annotation('textbox', [0.15 0.94 0.7 0.05], ...
               'String', 'FIG 13: Single-Node Code Alignment (IDEAL / NOISE-FREE FAST-TIME PC-FMCW CONCEPT)', ...
               'FontSize', sty.fs_subtitle, 'Color', sty.c_gray, ...
               'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end
save_fig(fig13, fullfile(fig_dir, 'fig13_single_node_alignment'));
close(fig13);
fprintf('  Saved: figures/fig13_single_node_alignment.png\n');


%% ========== Strong/Weak Two-Node Despread Spectra (Figure 14) ==========
delta_B = 7e-9;
f_B = S * delta_B;
code_B = generate_code('B', L_default);

alpha_A = 1.0;
alpha_B = 0.3;

s_rx_B = fmcw_delayed_baseband(t, S, delta_B) .* align_code(code_B, L_default, N, Fs, delta_B);
z_comp_sw = lo .* conj(alpha_A * s_rx_A + alpha_B * s_rx_B);

% Naive despread for B
c_B_shifted = align_code(code_B, L_default, N, Fs, delta_B);
z_sw_dsB_naive = z_comp_sw .* c_B_shifted;

% GDF despread for B
z_comp_sw_filt = apply_group_delay_filter(z_comp_sw, Fs, S);
c_B_unshifted = align_code(code_B, L_default, N, Fs, 0);
z_sw_dsB_filt = z_comp_sw_filt .* c_B_unshifted;

fft_naive_B = estimate_beat_fft(z_sw_dsB_naive, Fs);
fft_filt_B = estimate_beat_fft(z_sw_dsB_filt, Fs);

% Normalize both to same peak for visual comparison
mag_naive_B_dB = 20*log10(fft_naive_B.spectrum_mag(1:N_half+1) / max(fft_naive_B.spectrum_mag) + 1e-30);
mag_filt_B_dB = 20*log10(fft_filt_B.spectrum_mag(1:N_half+1) / max(fft_filt_B.spectrum_mag) + 1e-30);

fig14 = figure('Position', sty.fig_wide, 'Color', 'w', 'Visible', 'off');
subplot(2,1,1);
plot(freq_kHz, mag_naive_B_dB, '-', 'Color', sty.c_red, 'LineWidth', sty.lw_data); hold on;
xline(f_B/1e3, '--', 'Color', sty.c_black, 'LineWidth', 0.6);
xlabel('Frequency [kHz]'); ylabel('|Z(f)| [dB]');
title(sprintf('(a) Naive Receiver (Code B), \\alpha_A=%.1f, \\alpha_B=%.1f', alpha_A, alpha_B), 'FontSize', sty.fs_title);
xlim([0 500]); ylim([-60 5]);
set(gca, 'FontSize', sty.fs_tick); grid on; set(gca, 'GridAlpha', 0.25);

subplot(2,1,2);
plot(freq_kHz, mag_filt_B_dB, '-', 'Color', sty.c_green, 'LineWidth', sty.lw_data); hold on;
xline(f_B/1e3, '--', 'Color', sty.c_black, 'LineWidth', 0.6);
xlabel('Frequency [kHz]'); ylabel('|Z(f)| [dB]');
title('(b) GDF Receiver (Code B)', 'FontSize', sty.fs_title);
xlim([0 500]); ylim([-60 5]);
set(gca, 'FontSize', sty.fs_tick); grid on; set(gca, 'GridAlpha', 0.25);

try
    sgtitle('FIG 14: Strong/Weak Two-Node Spectra (IDEAL / NOISE-FREE FAST-TIME PC-FMCW CONCEPT)', ...
            'FontSize', sty.fs_subtitle, 'Color', sty.c_gray);
catch
    annotation('textbox', [0.15 0.94 0.7 0.05], ...
               'String', 'FIG 14: Strong/Weak Two-Node Spectra (IDEAL / NOISE-FREE FAST-TIME PC-FMCW CONCEPT)', ...
               'FontSize', sty.fs_subtitle, 'Color', sty.c_gray, ...
               'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end
save_fig(fig14, fullfile(fig_dir, 'fig14_two_node_spectra'));
close(fig14);
fprintf('  Saved: figures/fig14_two_node_spectra.png\n');


%% ========== Estimator-Ablation Comparison (Figure 15 & Table) ==========
% A. Naive + PS
ps_naive = estimate_beat_phase_slope(z_sw_dsB_naive, Fs);
err_naive_ps = abs(ps_naive.f_est - f_B);
% B. Naive + FFT
err_naive_fft = abs(fft_naive_B.f_peak - f_B);
% C. GDF + FFT
err_gdf_fft = abs(fft_filt_B.f_peak - f_B);
% D. GDF + PS
ps_gdf = estimate_beat_phase_slope(z_sw_dsB_filt, Fs);
err_gdf_ps = abs(ps_gdf.f_est - f_B);

fprintf('\n--- Estimator-Ablation Comparison (Weak Node B, L=2) ---\n');
fprintf('  A. Naive despreading + Phase-Slope    : Error = %10.2f Hz\n', err_naive_ps);
fprintf('  B. Naive despreading + Spectral Peak  : Error = %10.2f Hz\n', err_naive_fft);
fprintf('  C. GDF despreading   + Spectral Peak  : Error = %10.2f Hz\n', err_gdf_fft);
fprintf('  D. GDF despreading   + Phase-Slope    : Error = %10.2f Hz\n', err_gdf_ps);

fig15 = figure('Position', sty.fig_wide, 'Color', 'w', 'Visible', 'off');
bar_data = [err_naive_ps, err_naive_fft, err_gdf_fft, err_gdf_ps];
bar_labels = {'Naive+PS', 'Naive+FFT', 'GDF+FFT', 'GDF+PS'};
b = bar(bar_data, 'FaceColor', sty.c_blue);
set(gca, 'XTick', 1:4, 'XTickLabel', bar_labels);
set(gca, 'YScale', 'log');
ylabel('Frequency Error [Hz]');
title('FIG 15: Estimator Ablation (IDEAL / NOISE-FREE FAST-TIME PC-FMCW CONCEPT)', 'FontSize', sty.fs_title);
set(gca, 'FontSize', sty.fs_tick); grid on; set(gca, 'GridAlpha', 0.25);
yline(Fs/N, '--', 'FFT Bin Width', 'Color', sty.c_gray, 'LabelHorizontalAlignment', 'left');
save_fig(fig15, fullfile(fig_dir, 'fig15_estimator_ablation'));
close(fig15);
fprintf('  Saved: figures/fig15_estimator_ablation.png\n');


%% ========== Code Length Study (Figure 16 & Table) ==========
L_vals = [2, 4, 8, 16];
SIR_naive = zeros(length(L_vals), 1);
SIR_gdf   = zeros(length(L_vals), 1);
err_naive = zeros(length(L_vals), 1);
err_gdf   = zeros(length(L_vals), 1);
dispersion_ns = zeros(length(L_vals), 1);

fprintf('\n--- Code Length Study & Dispersion Diagnostic ---\n');
fprintf('  %-4s  %-10s  %-10s  %-10s  %-10s  %-10s\n', 'L', 'Disp [ns]', 'SIR_N [dB]', 'SIR_G [dB]', 'Err_N [Hz]', 'Err_G [Hz]');
fprintf('  %s\n', repmat('-', 1, 65));

for idx = 1:length(L_vals)
    L = L_vals(idx);
    c_A = generate_code('A', L);
    c_B = generate_code('B', L);
    
    rxA = fmcw_delayed_baseband(t, S, delta_A) .* align_code(c_A, L, N, Fs, delta_A);
    rxB = fmcw_delayed_baseband(t, S, delta_B) .* align_code(c_B, L, N, Fs, delta_B);
    
    z_comp = lo .* conj(alpha_A * rxA + alpha_B * rxB);
    z_comp_filt = apply_group_delay_filter(z_comp, Fs, S);
    
    % Naive
    c_B_shift = align_code(c_B, L, N, Fs, delta_B);
    z_n = z_comp .* c_B_shift;
    
    % GDF
    c_B_un = align_code(c_B, L, N, Fs, 0);
    z_g = z_comp_filt .* c_B_un;
    
    fft_n = estimate_beat_fft(z_n, Fs);
    fft_g = estimate_beat_fft(z_g, Fs);
    
    P_n = fft_n.spectrum_mag.^2 / N;
    P_g = fft_g.spectrum_mag.^2 / N;
    
    bin_A = round(f_A / (Fs/N)) + 1;
    bin_B = round(f_B / (Fs/N)) + 1;
    
    SIR_naive(idx) = 10*log10(P_n(bin_B) / (P_n(bin_A) + 1e-30));
    SIR_gdf(idx)   = 10*log10(P_g(bin_B) / (P_g(bin_A) + 1e-30));
    
    err_naive(idx) = abs(fft_n.f_peak - f_B);
    err_gdf(idx)   = abs(fft_g.f_peak - f_B);
    
    % Dispersion Diagnostic
    bw_code = 1 / (N / (Fs * L));
    disp_ns = (bw_code / S) * 1e9;
    dispersion_ns(idx) = disp_ns;
    
    fprintf('  %-4d  %-10.2f  %-10.1f  %-10.1f  %-10.2f  %-10.2f\n', ...
            L, disp_ns, SIR_naive(idx), SIR_gdf(idx), err_naive(idx), err_gdf(idx));
end

fig16 = figure('Position', sty.fig_wide, 'Color', 'w', 'Visible', 'off');
subplot(1,2,1);
plot(L_vals, SIR_naive, '-o', 'Color', sty.c_red, 'LineWidth', sty.lw_data); hold on;
plot(L_vals, SIR_gdf, '-o', 'Color', sty.c_green, 'LineWidth', sty.lw_data);
xlabel('Code Length (L)'); ylabel('Post-Despreading SIR [dB]');
legend('Naive Receiver', 'GDF Receiver', 'Location', 'northwest');
title('SIR vs Code Length', 'FontSize', sty.fs_title);
set(gca, 'FontSize', sty.fs_tick); grid on; set(gca, 'GridAlpha', 0.25);

subplot(1,2,2);
plot(L_vals, err_naive, '-o', 'Color', sty.c_red, 'LineWidth', sty.lw_data); hold on;
plot(L_vals, err_gdf, '-o', 'Color', sty.c_green, 'LineWidth', sty.lw_data);
set(gca, 'YScale', 'log');
xlabel('Code Length (L)'); ylabel('Frequency Error [Hz]');
legend('Naive Receiver', 'GDF Receiver', 'Location', 'northeast');
title('Error vs Code Length', 'FontSize', sty.fs_title);
set(gca, 'FontSize', sty.fs_tick); grid on; set(gca, 'GridAlpha', 0.25);

try
    sgtitle('FIG 16: Code Length Sweep (IDEAL / NOISE-FREE FAST-TIME PC-FMCW CONCEPT)', ...
            'FontSize', sty.fs_subtitle, 'Color', sty.c_gray);
catch
    annotation('textbox', [0.15 0.94 0.7 0.05], ...
               'String', 'FIG 16: Code Length Sweep (IDEAL / NOISE-FREE FAST-TIME PC-FMCW CONCEPT)', ...
               'FontSize', sty.fs_subtitle, 'Color', sty.c_gray, ...
               'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end
save_fig(fig16, fullfile(fig_dir, 'fig16_code_length_study'));
close(fig16);
fprintf('\n  Saved: figures/fig16_code_length_study.png\n');

fprintf('\n====================================================\n');
fprintf('  DEMO COMPLETE\n');
fprintf('====================================================\n\n');
