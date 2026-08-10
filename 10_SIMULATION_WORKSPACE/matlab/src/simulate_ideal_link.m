function link = simulate_ideal_link(cfg, delta)
% SIMULATE_IDEAL_LINK  Authoritative V0 single-link signal chain.
%
%   link = simulate_ideal_link(cfg, delta)
%
%   This is the single reusable ideal-link API. All V0 and V1 processing
%   must flow through this function.
%
%   V0 calls this once.
%   V1 calls this exactly twice:
%       link_AB = simulate_ideal_link(cfg, tau + theta);
%       link_BA = simulate_ideal_link(cfg, tau - theta);
%
%   No signal-chain logic is duplicated outside this function.
%
%   Inputs:
%       cfg    Configuration struct from make_default_params()
%       delta  One-way effective delay [s]
%
%   Output:
%       link   Struct with fields:
%         .t          Time vector (0:N-1)'/Fs [s]
%         .tx         Baseband TX chirp [complex Nx1]
%         .rx         Baseband delayed RX chirp [complex Nx1]
%         .beat       Dechirped beat signal [complex Nx1]
%         .fb_theory  Theoretical beat frequency S*delta [Hz]
%         .delta      Injected delay (echo) [s]
%         .cfg        Configuration struct (echo)
%
%   Reference: docs/V0_V1_IMPLEMENTATION_SPEC.md, Section B.6

    % Time vector
    link.t = (0:cfg.N-1).' / cfg.Fs;

    % Generate baseband chirps
    link.tx = fmcw_baseband(link.t, cfg.S);
    link.rx = fmcw_delayed_baseband(link.t, cfg.S, delta);

    % Dechirp: z = tx .* conj(rx)
    link.beat = dechirp_signal(link.tx, link.rx);

    % Truth metadata
    link.fb_theory = cfg.S * delta;
    link.delta     = delta;
    link.cfg       = cfg;

end
