function [y, meta] = apply_group_delay_filter(x, Fs, S, opts)
% APPLY_GROUP_DELAY_FILTER  Applies the code-alignment group-delay filter.
%
%   [y, meta] = apply_group_delay_filter(x, Fs, S)
%   [y, meta] = apply_group_delay_filter(x, Fs, S, opts)
%
%   This function applies the exact literature group-delay filter:
%       H(f) = exp(+1j * pi * f^2 / S)
%   using the project's frozen signal and Fourier conventions.
%
%   Inputs:
%       x    - Complex dechirped time-domain record [Nx1]
%       Fs   - Sample rate [Hz]
%       S    - Chirp slope [Hz/s]
%       opts - (Optional) struct with configuration fields:
%              .use_padding - If true, uses zero-padding >= 4*N for
%                             validation (default: false, circular filter).
%
%   Outputs:
%       y    - Filtered complex time-domain record [Nx1]
%       meta - Diagnostic metadata struct:
%              .f_signed - Signed frequency vector [length(H)x1]
%              .H        - Filter frequency response [length(H)x1]
%              .padded   - Boolean indicating if zero-padding was used
%
%   Reference: docs/PC_FMCW_RECEIVER_THEORY_AND_NEXT_STEP.md (Stage-1)

    if nargin < 4
        opts = struct();
    end
    if ~isfield(opts, 'use_padding')
        opts.use_padding = false;
    end

    x = x(:);
    N_orig = length(x);

    if opts.use_padding
        % Pad to at least 4*N_orig to avoid circular wrap artifacts
        N_pad = 4 * N_orig;
        % Force even length for simple frequency vector construction
        if mod(N_pad, 2) ~= 0
            N_pad = N_pad + 1;
        end
        x_pad = [x; zeros(N_pad - N_orig, 1)];
        N = N_pad;
        X = fft(x_pad);
    else
        % Circular filter (production path)
        N = N_orig;
        if mod(N, 2) ~= 0
            error('apply_group_delay_filter:odd_length', 'Input length must be even.');
        end
        X = fft(x);
    end

    % Construct signed frequency vector in MATLAB natural FFT order
    % For even N: [0, 1, ..., N/2-1, -N/2, ..., -1] * Fs/N
    f_signed = [0:N/2-1, -N/2:-1].' * (Fs / N);

    % Construct group-delay filter: H(f) = exp(+j*pi*f^2/S)
    H = exp(1j * pi * f_signed.^2 / S);

    % Apply filter in frequency domain
    Y = X .* H;

    % Inverse FFT
    y_full = ifft(Y);

    if opts.use_padding
        % Extract the valid interior region (discard padding)
        y = y_full(1:N_orig);
    else
        y = y_full;
    end

    meta.f_signed = f_signed;
    meta.H = H;
    meta.padded = opts.use_padding;
end
