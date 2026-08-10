function save_fig(fig, base_path)
% SAVE_FIG  Export figure as high-resolution PNG and vector PDF.
%
%   save_fig(fig, base_path)
%
%   Saves:  base_path.png  (300 dpi)
%           base_path.pdf  (vector, if exportgraphics available)

    print(fig, [base_path '.png'], '-dpng', '-r300');
    try
        exportgraphics(fig, [base_path '.pdf'], 'ContentType', 'vector');
    catch
        % exportgraphics unavailable (Octave / older MATLAB)
    end

end
