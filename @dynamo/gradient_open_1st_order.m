function [grad] = gradient_open_1st_order(self, control_mask)
% Gradient of error_open by first order approximation.

% dP_k/d_u \approx (-B_u * dt_k) * P_k
% Exact if G_k commutes with B_u.

% Mask which Hs, Us, & Ls we need for this calculation
% (it's more efficient to do so before we ask for the current_value, since then get_current_value's call to cache_refresh
% will be most efficient as it knows of all calculations needed at once, and not piece-meal).

slot_mask = any(control_mask, 2);
self.cache.H_needed_now(slot_mask) = true; % H_{slot}
self.cache.U_needed_now([false; slot_mask]) = true;  % U_{slot+1}
self.cache.L_needed_now([false; slot_mask]) = true;  % L_{slot+1}

self.cache_refresh();

% tau as last column of controls
tau_c = size(control_mask, 2);

grad = zeros(nnz(control_mask), 1);
[Ts, Cs] = ind2sub(size(control_mask), find(control_mask));
for z = 1:length(Ts)
    t = Ts(z);
    c = Cs(z);

    % compute everything using just U{t+1}, L{t+1} and H{t}:

    temp = abs(self.seq.tau(t)) * norm(self.cache.H{t});
    if temp > 1
        self.gradient_warn(t, c, temp);
    end

    X_n = self.cache.L{t+1} * self.cache.U{t+1};
    temp = X_n - self.system.X_final;
    
    if c == tau_c
        % exact
        temp = -self.seq.tau_deriv(t) * inprod(temp, self.cache.L{t+1} * self.cache.H{t} * self.cache.U{t+1});
    else
        % approximate
        temp = -self.seq.tau(t) * self.seq.fields_deriv(t, c) * inprod(temp, self.cache.L{t+1} * self.system.B{c} * self.cache.U{t+1});
    end
    grad(z) = real(temp);
end

% normalization
grad = (2 / self.system.norm2) * grad;
end
