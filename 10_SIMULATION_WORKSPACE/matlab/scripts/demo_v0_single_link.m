% demo_v0_single_link.m
% V0: Ideal single-link FMCW delay-to-beat demonstration.
%
% Generates:
%   figures/fig01_v0_single_link.png  -- delay-to-frequency conversion
%   figures/fig03_delay_linearity.png -- delay linearity sweep
%
% Reference: docs/V0_V1_IMPLEMENTATION_SPEC.md, Sections B, D, G

%% Setup
cfg   = make_default_params();
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
fprintf('  Delay error:            %.2e s\n',           abs(delta_hat - delta));
fprintf('  Phase-fit residual:     %.2e rad\n',         phase_res.residual_rms);
fprintf('  NOTE: FFT peak != truth (nearest-bin limitation)\n');
fprintf('====================================================\n\n');

%% Output directory
script_dir = fileparts(mfilename('fullpath'));
fig_dir    = fullfile(script_dir, '..', 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

%% ========== Figure 1: Delay-to-Frequency Conversion ==========
fig1 = figure('Position', [100 100 800 600], 'Color', 'w', 'Visible', 'off');

% --- Top: chirp geometry ---
subplot(2,1,1);
t_us    = link.t * 1e6;
f_tx_kHz = cfg.S * link.t / 1e3;
f_rx_kHz = cfg.S * (link.t - delta) / 1e3;

plot(t_us, f_tx_kHz, 'b-', 'LineWidth', 1.5); hold on;
plot(t_us, f_rx_kHz, 'r--', 'LineWidth', 1.5);

% Annotate frequency gap at midpoint
mid = round(cfg.N/2);
ylo = f_rx_kHz(mid);  yhi = f_tx_kHz(mid);
plot([t_us(mid) t_us(mid)], [ylo yhi], 'k-', 'LineWidth', 1.2);
text(t_us(mid) + 0.8, (ylo+yhi)/2, ...
     sprintf('S\\cdot\\delta = %.1f kHz', link.fb_theory/1e3), ...
     'FontSize', 10, 'VerticalAlignment', 'middle');

xlabel('Time [\mus]', 'FontSize', 11);
ylabel('Baseband frequency [kHz]', 'FontSize', 11);
title(sprintf('FMCW Chirp Geometry:  \\delta = %.1f ns,  S = %.3f MHz/\\mus', ...
      delta*1e9, cfg.S/1e12), 'FontSize', 12);
legend('TX chirp', 'RX chirp (delayed)', 'Location', 'northwest');
grid on; set(gca, 'FontSize', 10);

% --- Bottom: beat spectrum ---
subplot(2,1,2);
N_half   = floor(cfg.N/2);
freq_kHz = fft_res.freq_axis(1:N_half+1) / 1e3;
mag_dB   = 20*log10(fft_res.spectrum_mag(1:N_half+1) / ...
           max(fft_res.spectrum_mag) + 1e-30);

plot(freq_kHz, mag_dB, 'b-', 'LineWidth', 1); hold on;
xline(link.fb_theory/1e3, 'k--', 'LineWidth', 1.2);
plot(fft_res.f_peak/1e3, 0, 'rv', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
plot(phase_res.f_est/1e3, 0, 'g^', 'MarkerSize', 10, 'MarkerFaceColor', [0 0.7 0]);

xlabel('Frequency [kHz]', 'FontSize', 11);
ylabel('Magnitude [dB]', 'FontSize', 11);
title('Dechirped Beat Spectrum', 'FontSize', 12);
legend('|FFT(z)|', ...
       sprintf('Theory: %.1f kHz', link.fb_theory/1e3), ...
       sprintf('FFT peak: %.1f kHz', fft_res.f_peak/1e3), ...
       sprintf('Phase-slope: %.3f kHz', phase_res.f_est/1e3), ...
       'Location', 'northeast');
xlim([0 freq_kHz(end)]);
ylim([-60 5]);
grid on; set(gca, 'FontSize', 10);

% Annotation
dim = [0.53 0.02 0.44 0.20];
str = {sprintf('Injected \\delta: %.3f ns', delta*1e9), ...
       sprintf('Theoretical f_b: %.3f kHz', link.fb_theory/1e3), ...
       sprintf('Phase-slope est: %.6f kHz', phase_res.f_est/1e3), ...
       sprintf('Recovered \\delta: %.9f ns', delta_hat*1e9), ...
       sprintf('FFT bin spacing: %.3f kHz', fft_res.df/1e3), ...
       'IDEAL -- noise-free, matched oscillators'};
annotation('textbox', dim, 'String', str, 'FontSize', 8, ...
           'BackgroundColor', [1 1 0.92], 'EdgeColor', [0.5 0.5 0.5], ...
           'FitBoxToText', 'on');

print(fig1, fullfile(fig_dir, 'fig01_v0_single_link.png'), '-dpng', '-r300');
try exportgraphics(fig1, fullfile(fig_dir, 'fig01_v0_single_link.pdf'), ...
                   'ContentType', 'vector'); catch, end
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

fig3 = figure('Position', [100 100 800 500], 'Color', 'w', 'Visible', 'off');

subplot(2,1,1);
loglog(delays*1e9, f_theo_arr/1e3, 'b-', 'LineWidth', 1.5); hold on;
loglog(delays*1e9, f_est_arr/1e3, 'ro', 'MarkerSize', 6);
xlabel('Injected delay [ns]', 'FontSize', 11);
ylabel('Beat frequency [kHz]', 'FontSize', 11);
title('V0 Delay Linearity: f_b = S \cdot \delta   (IDEAL -- noise-free)', ...
      'FontSize', 12);
legend('Theory: S\cdot\delta', 'Phase-slope estimate', 'Location', 'northwest');
grid on; set(gca, 'FontSize', 10);

subplot(2,1,2);
residual_Hz = f_est_arr - f_theo_arr;
semilogx(delays*1e9, residual_Hz, 'ko-', 'MarkerSize', 5, 'LineWidth', 1);
xlabel('Injected delay [ns]', 'FontSize', 11);
ylabel('Residual  f_{est} - S\cdot\delta  [Hz]', 'FontSize', 11);
title('Estimation Residual', 'FontSize', 12);
grid on; set(gca, 'FontSize', 10);

print(fig3, fullfile(fig_dir, 'fig03_delay_linearity.png'), '-dpng', '-r300');
try exportgraphics(fig3, fullfile(fig_dir, 'fig03_delay_linearity.pdf'), ...
                   'ContentType', 'vector'); catch, end
close(fig3);
fprintf('  Saved: figures/fig03_delay_linearity.png\n');
