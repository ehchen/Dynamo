function [C, labels] = control_ops(dim, ctrl)
% Returns a cell vector of local control operators.
%  [C, labels] = control_ops(dim, ctrl)
%
%  dim is the system dimension vector.
%  ctrl is a string consisting of tokens separated with commas.
%
%  Each token consists of an optional numerical prefix denoting the
%  subsystems to which it applies, followed by a string of local
%  operator specifiers.
%
%  The prefix can be either 'a:b' denoting a range, or 'a' denoting a single subsystem.
%  If there is no prefix, the token applies to all subsystems.
%
%  The allowed operator specifiers are the following chars:
%    'x', 'y' and 'z'  generators of unitary rotations
%    'd'               dephasing (unital)
%    'i'               isotropic depolarization (unital)
%    'a'               amplitude damping towards the |0> state
%
%  Example:
%    The function call
%
%        C = control_ops([2 2 2], 'xy,3d')
%
%    returns a total of 7 control operators for a three-qubit system:
%    X and Y rotations for every qubit, plus dephasing for the third one.

% TODO Explain normalization, non-qubits...
    
% Ville Bergholm 2011-2012


% for qubits
X = [0 1; 1 0];
Y = [0 -1i; 1i 0];
Z = [1 0; 0 -1];
SP = [0 1; 0 0];

% number of subsystems
n = length(dim);

C = {};
labels = {};


%% parse the ctrl string

% next token
[token, ctrl] = strtok(ctrl, ',');
while ~isempty(token)
    % where should we apply it?
    [a, count, err, next] = sscanf(token, '%d:%d');
    if count == 2
        % range of subsystems
        systems = a(1):a(2);
    elseif count == 1
        % single subsystem
        systems = a;
    else
        % all subsystems
        systems = 1:n;        
    end

    % lowercase and unique the rest
    token = unique(lower(token(next:end)));
    r = length(token);
    
    % loop over subsystems
    for k = systems
        Ia = speye(prod(dim(1:k-1)));
        Ib = speye(prod(dim(k+1:end)));
        J = angular_momentum(dim(k));

        % loop over the operator specifications
        for j=1:r
            switch token(j)
              case {'x', 'y', 'z'}
                temp = token(j) - 'x' + 1; % MATLAB indexing
                C{end+1} = mkron(Ia, J{temp}, Ib);
                labels{end+1} = sprintf('%c_%d', upper(token(j)), k);
              
              case 'a'
                if dim(k) ~= 2
                    error('Ampdamp not yet defined for non-qubits.')
                end
                C{end+1} = superop_lindblad({mkron(Ia, SP, Ib)});
                labels{end+1} = sprintf('A_%d', k);

              case 'b'
                if dim(k) ~= 2
                    error('Bit flip not yet defined for non-qubits.')
                end
                C{end+1} = superop_lindblad({mkron(Ia, X/2, Ib)});
                labels{end+1} = sprintf('Dx_%d', k);                
                
              case 'd'
                if dim(k) ~= 2
                    error('Dephasing not yet defined for non-qubits.')
                end
                C{end+1} = superop_lindblad({mkron(Ia, Z/2, Ib)});
                labels{end+1} = sprintf('Dz_%d', k);

              case 'i'
                if dim(k) ~= 2
                    error('Isotropic depolarization not yet defined for non-qubits.')
                end
                C{end+1} = superop_lindblad({mkron(Ia, X/2, Ib),mkron(Ia, Y/2, Ib),mkron(Ia, Z/2, Ib)});
                labels{end+1} = sprintf('I_%d', k);

              otherwise
                error('Unknown operator specifier "%c".', token(j))
            end
        end
    end
    
    % next token
    [token, ctrl] = strtok(ctrl, ',');
end
end
