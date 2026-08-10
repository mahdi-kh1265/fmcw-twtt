% demo_v0_single_link.m
% V0: Ideal single-link FMCW delay-to-beat demonstration.
%
% Generates:
%   figures/fig01_v0_single_link  -- delay-to-frequency conversion
%   figures/fig03_delay_linearity -- delay linearity sweep
%
% Reference: docs/V0_V1_IMPLEMENTATION_SPEC.md, Sections B, D, G

%% Setup
cfg   = make_default_params();
sty   = fig_style();
delta = 5e-9;   % 5 ns headline delay
Tobs  = cfg.N / cfg.Fs;

%% Run ideal link
link = simulate_ideal_link(cfg, delta);

%% Estimate beat frequency
fft_res   = estimate_beat_fft(link.beat, cfg.Fs);
phase_res = estimate_beat_phase_slope(link.beat, cfg.Fs);
delta_hat = phase_res.f_est / cfg.S;

%% Print V0 results
fprintf('\n');
fprintf('====================================================\n');
fprintf('  FMCW V0 -- IDEAL SINGLE-LINK RESULT\n');
fprintf('====================================================\n');
fprintf('  Slope S:                %.3f MHz/us\n',     cfg.S / 1e12);
fprintf('  Sample rate Fs:         %.0f MHz\n',         cfg.Fs / 1e6);
fprintf('  Samples N:              %d\n',               cfg.N);
fprintf('  Observation time Tobs:  %.1f us\n',          Tobs * 1e6);
fprintf('  FFT bin spacing:        %.4f kHz\n',         fft_res.df / 1e3);
fprintf('  ----\n');
fprintf('  Injected delay:         %.3f ns\n',          delta * 1e9);
fprintf('  Theoretical f_b:        %.1f Hz\n',          link.fb_theory);
fprintf('  Phase-slope estimate:   %.1f Hz\n',          phase_res.f_est);
fprintf('  FFT peak estimate:      %.1f Hz\n',          fft_res.f_peak);
fprintf('  Recovered delay:        %.9f ns\n',          delta_hat * 1e9);
fprintf('  Delay error:            %.2e s  (floating-point closure)\n',  abs(delta_hat - delta));
fprintf('  Phase-fit residual:     %.2e rad\n',         phase_res.residual_rms);
fprintf('  NOTE: FFT peak != truth (nearest-bin limitation)\n');
fprintf('====================================================\n\n');

%% Output directory
script_dir = fileparts(mfilename('fullpath'));
fig_dir    = fullfile(script_dir, '..', 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

%% ========== Figure 1: Single-Link Delay-to-Beat ==========
fig1 = figure('Position', sty.fig_tall, 'Color', 'w', 'Visible', 'off');

t_us     = link.t * 1e6;
f_tx_MHz = cfg.S * link.t / 1e6;
f_rx_MHz = cfg.S * (link.t - delta) / 1e6;

% --- Panel (a): full chirp geometry ---
ax1 = subplot(3,1,1);
plot(t_us, f_tx_MHz, '-', 'Color', sty.c_blue, 'LineWidth', sty.lw_data); hold on;
plot(t_us, f_rx_MHz, '--', 'Color', sty.c_red,  'LineWidth', sty.lw_data);
xlabel('Time [\mus]'); ylabel('Frequency [MHz]');
title(sprintf('(a)  Baseband chirp geometry:  S = %.3f MHz/\\mus,  \\delta = %.1f ns', ...
      cfg.S/1e12, delta*1e9), 'FontSize', sty.fs_title);
lg = legend('TX  s(t)', 'RX  r(t\!-\!\delta)', 'Location', 'northwest');
set(lg, 'FontSize', sty.fs_legend);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

% --- Panel (b): zoomed inset showing frequency gap ---
ax2 = subplot(3,1,2);
% Zoom to a ~2 us window near the center where gap is visible
t_center = Tobs/2;
t_win    = 1.5e-6;  % 1.5 us half-window
mask     = (link.t >= t_center - t_win) & (link.t <= t_center + t_win);
t_z      = link.t(mask) * 1e6;
ftx_z    = cfg.S * link.t(mask) / 1e6;
frx_z    = cfg.S * (link.t(mask) - delta) / 1e6;

plot(t_z, ftx_z, '-',  'Color', sty.c_blue, 'LineWidth', sty.lw_data); hold on;
plot(t_z, frx_z, '--', 'Color', sty.c_red,  'LineWidth', sty.lw_data);

% Double arrow at midpoint
mid_idx = round(sum(mask)/2);
t_mid   = link.t(find(mask, 1) + mid_idx - 1) * 1e6;
y_lo    = cfg.S * (link.t(find(mask, 1) + mid_idx - 1) - delta) / 1e6;
y_hi    = cfg.S * link.t(find(mask, 1) + mid_idx - 1) / 1e6;
plot([t_mid t_mid], [y_lo y_hi], '-', 'Color', sty.c_black, 'LineWidth', 1.0);
plot(t_mid, y_lo, 'v', 'Color', sty.c_black, 'MarkerSize', 4, 'MarkerFaceColor', sty.c_black);
plot(t_mid, y_hi, '^', 'Color', sty.c_black, 'MarkerSize', 4, 'MarkerFaceColor', sty.c_black);
text(t_mid + 0.15, (y_lo+y_hi)/2, ...
     sprintf('S\\cdot\\delta = %.1f kHz', link.fb_theory/1e3), ...
     'FontSize', sty.fs_annot, 'VerticalAlignment', 'middle');

xlabel('Time [\mus]'); ylabel('Frequency [MHz]');
title('(b)  Zoomed view: TX/RX frequency separation', 'FontSize', sty.fs_title);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

% --- Panel (c): beat spectrum (zoomed around beat) ---
ax3 = subplot(3,1,3);
N_half   = floor(cfg.N/2);
freq_kHz = fft_res.freq_axis(1:N_half+1) / 1e3;
mag_dB   = 20*log10(fft_res.spectrum_mag(1:N_half+1) / ...
           max(fft_res.spectrum_mag) + 1e-30);

plot(freq_kHz, mag_dB, '-', 'Color', sty.c_blue, 'LineWidth', sty.lw_data); hold on;

% Theory line
xline(link.fb_theory/1e3, '--', 'Color', sty.c_black, 'LineWidth', sty.lw_theory);

% FFT peak marker
plot(fft_res.f_peak/1e3, 0, 'v', 'Color', sty.c_red, ...
     'MarkerSize', sty.ms_accent, 'MarkerFaceColor', sty.c_red);

% Phase-slope marker
plot(phase_res.f_est/1e3, 0, '^', 'Color', sty.c_green, ...
     'MarkerSize', sty.ms_accent, 'MarkerFaceColor', sty.c_green);

xlabel('Frequency [kHz]'); ylabel('|Z(f)| [dB]');
title('(c)  Dechirped beat spectrum', 'FontSize', sty.fs_title);
lg = legend('|FFT(z)|', ...
       sprintf('Theory: %.1f kHz', link.fb_theory/1e3), ...
       sprintf('FFT peak: %.1f kHz', fft_res.f_peak/1e3), ...
       sprintf('Phase-slope: %.3f kHz', phase_res.f_est/1e3), ...
       'Location', 'northeast');
set(lg, 'FontSize', sty.fs_legend);
xlim([0 500]);  % zoom to 0-500 kHz
ylim([-60 5]);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

% Subtitle with parameters
try
    sgtitle(sprintf('Ideal noise-free model   |   \\Deltaf_{bin} = %.1f kHz', ...
            fft_res.df/1e3), 'FontSize', sty.fs_subtitle, 'Color', sty.c_gray);
catch
    annotation('textbox', [0.25 0.94 0.5 0.05], ...
               'String', sprintf('Ideal noise-free model  |  df_bin = %.1f kHz', fft_res.df/1e3), ...
               'FontSize', sty.fs_subtitle, 'Color', sty.c_gray, ...
               'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end

save_fig(fig1, fullfile(fig_dir, 'fig01_v0_single_link'));
close(fig1);
fprintf('  Saved: figures/fig01_v0_single_link.png\n');

%% ========== Figure 3: Delay Linearity Sweep ==========
delays     = logspace(log10(10e-12), log10(100e-9), 20);
f_est_arr  = zeros(size(delays));
f_theo_arr = zeros(size(delays));

for i = 1:length(delays)
    lnk = simulate_ideal_link(cfg, delays(i));
    est = estimate_beat_phase_slope(lnk.beat, cfg.Fs);
    f_est_arr(i)  = est.f_est;
    f_theo_arr(i) = lnk.fb_theory;
end

fig3 = figure('Position', sty.fig_wide, 'Color', 'w', 'Visible', 'off');

subplot(2,1,1);
loglog(delays*1e9, f_theo_arr/1e3, '-', 'Color', sty.c_blue, 'LineWidth', sty.lw_data); hold on;
loglog(delays*1e9, f_est_arr/1e3, 'o', 'Color', sty.c_red, ...
       'MarkerSize', sty.ms_data, 'LineWidth', 1.0);
xlabel('Injected delay [ns]'); ylabel('Beat frequency [kHz]');
title('(a)  Delay linearity:  f_b = S \cdot \delta', 'FontSize', sty.fs_title);
lg = legend('Theory: S\cdot\delta', 'Phase-slope estimate', 'Location', 'northwest');
set(lg, 'FontSize', sty.fs_legend);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

subplot(2,1,2);
residual_Hz = f_est_arr - f_theo_arr;
semilogx(delays*1e9, residual_Hz, 'o-', 'Color', sty.c_black, ...
         'MarkerSize', 4, 'LineWidth', 1.0); hold on;
yline(0, '-', 'Color', sty.c_ltgray, 'LineWidth', 0.8);
xlabel('Injected delay [ns]');
ylabel('f_{est} - S\cdot\delta  [Hz]');
title('(b)  Ideal-model numerical closure', 'FontSize', sty.fs_title);
set(gca, 'FontSize', sty.fs_tick); grid on;
set(gca, 'GridAlpha', 0.25);

% Annotation
text(0.98, 0.05, 'Floating-point scale; not physical timing precision', ...
     'Units', 'normalized', 'HorizontalAlignment', 'right', ...
     'FontSize', sty.fs_annot, 'FontAngle', 'italic', 'Color', sty.c_gray);

try
    sgtitle('Ideal noise-free model', 'FontSize', sty.fs_subtitle, 'Color', sty.c_gray);
catch
    annotation('textbox', [0.25 0.94 0.5 0.05], ...
               'String', 'Ideal noise-free model', ...
               'FontSize', sty.fs_subtitle, 'Color', sty.c_gray, ...
               'HorizontalAlignment', 'center', 'EdgeColor', 'none');
end

save_fig(fig3, fullfile(fig_dir, 'fig03_delay_linearity'));
close(fig3);
fprintf('  Saved: figures/fig03_delay_linearity.png\n');
