function style = fig_style()
% FIG_STYLE  Consistent publication-quality figure style tokens.
%
%   style = fig_style()
%
%   Returns a struct of line widths, font sizes, colors, and marker
%   conventions used by all V0/V1 figure scripts.

    % --- Font sizes ---
    style.fs_title    = 11;
    style.fs_subtitle = 9;
    style.fs_axis     = 10;
    style.fs_tick     = 9;
    style.fs_legend   = 8.5;
    style.fs_annot    = 8;

    % --- Line widths ---
    style.lw_data     = 1.4;
    style.lw_theory   = 1.0;
    style.lw_grid     = 0.4;

    % --- Marker sizes ---
    style.ms_data     = 5;
    style.ms_accent   = 7;

    % --- Colors (restrained scientific palette) ---
    style.c_blue      = [0.00 0.30 0.70];   % TX / A->B
    style.c_red       = [0.80 0.15 0.15];   % RX / B->A
    style.c_black     = [0.15 0.15 0.15];   % theory / reference
    style.c_green     = [0.00 0.55 0.25];   % phase-slope estimator
    style.c_gray      = [0.50 0.50 0.50];   % secondary
    style.c_ltgray    = [0.85 0.85 0.85];   % grid

    % --- Figure sizes [pixels] ---
    style.fig_wide    = [80 80 720 480];     % standard landscape
    style.fig_tall    = [80 80 720 580];     % taller for 3-panel

    % --- Font family ---
    style.fontname    = 'Helvetica';

end
