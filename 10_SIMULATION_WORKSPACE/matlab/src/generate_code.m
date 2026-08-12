function code = generate_code(code_type, L)
% GENERATE_CODE  Generate orthogonal binary phase code.
%
%   code = generate_code(code_type, L)
%
%   Returns a row vector of +/-1 values forming one row of a Walsh-Hadamard
%   matrix built by the Sylvester construction.
%
%   Supported lengths: L = 2, 4, 8, 16 (powers of 2, L <= 16).
%
%   code_type selects the code:
%     'A' -> row 1 (all +1)
%     'B' -> row 2
%     Numeric index k -> row k  (1 <= k <= L)
%
%   For L = 2:
%       Code A = [+1, +1]    (row 1)
%       Code B = [+1, -1]    (row 2)
%
%   For any L, all rows are mutually orthogonal: sum(H(i,:).*H(j,:)) = 0
%   for i != j, and sum(H(i,:).*H(i,:)) = L.
%
%   Inputs:  code_type  String 'A','B' or numeric row index 1..L
%            L          Code length (default: 2). Must be power of 2, <= 16.
%   Output:  code       Row vector of +/-1 values, length L
%
%   N (total samples) must be divisible by L. Caller is responsible.
%
%   Invariant: code 'A' (row 1) = [+1, +1, ..., +1] for any L.
%
%   Reference: docs/CFO_PHASE_CODING_IMPLEMENTATION_SPEC.md, Section C.3

    if nargin < 2
        L = 2;
    end

    % Validate L is a power of 2 and <= 16
    valid_L = [2, 4, 8, 16];
    if ~ismember(L, valid_L)
        error('generate_code:unsupportedLength', ...
              'L must be 2, 4, 8, or 16. Got L = %d.', L);
    end

    % Build Hadamard matrix via Sylvester construction
    H = [1];
    while size(H, 1) < L
        H = [H, H; H, -H];
    end

    % Resolve code_type to row index
    if ischar(code_type)
        if strcmp(code_type, 'A')
            row_idx = 1;
        elseif strcmp(code_type, 'B')
            row_idx = 2;
        else
            error('generate_code:badType', ...
                  'code_type must be ''A'', ''B'', or numeric index. Got ''%s''.', code_type);
        end
    elseif isnumeric(code_type)
        row_idx = code_type;
        if row_idx < 1 || row_idx > L
            error('generate_code:badIndex', ...
                  'Numeric code_type must be 1..%d. Got %d.', L, row_idx);
        end
    else
        error('generate_code:badType', 'code_type must be string or numeric.');
    end

    code = H(row_idx, :);

end
