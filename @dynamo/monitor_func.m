function stop = monitor_func(self, x, optimValues, state)
% Executed once every iteration during optimization, decides if we should stop here.

stop = false;
wt = (now() - self.opt.wall_start) * 24*60*60; % elapsed time in seconds
ct = cputime() - self.opt.cpu_start;


drawnow(); % flush drawing events and callbacks (incl. user interrupts)

% check for stop signal from the UI
% TODO this is where we would check for Ctrl-C if MATLAB supported it...
if self.opt.stop
    self.opt.term_reason = 'User interrupt';
    stop = true;
end


%% Plot the sequence every now and then

% Refresh the UI figure.
if ~isempty(self.opt.ui_fig) && self.opt.plot_interval && mod(self.opt.N_iter, self.opt.plot_interval) == 0
    self.ui_refresh(false, optimValues.fval);
end


%% Check termination conditions

% TODO some of these are already present in optimValues...
self.opt.N_iter = self.opt.N_iter + 1;

if self.opt.N_eval >= self.opt.term_cond.max_loop_count
    self.opt.term_reason = 'Loop count limit reached';
    stop = true;
end

if wt >= self.opt.term_cond.max_wall_time
    self.opt.term_reason = 'Wall time limit reached';
    stop = true;
end

if ct >= self.opt.term_cond.max_cputime
    self.opt.term_reason = 'CPU time limit reached';
    stop = true;
end

if self.opt.last_grad_norm <= self.opt.term_cond.min_gradient_norm
    self.opt.term_reason = 'Minimal gradient norm reached';
    stop = true;
end

% have we reached our goal?
if optimValues.fval <= self.opt.term_cond.error_goal
    self.opt.term_reason = 'Goal achieved';
    stop = true;
end


%% Stats collector part

self.stats.error(end+1) = optimValues.fval;
self.stats.wall_time(end+1) = wt;
self.stats.cpu_time(end+1)  = ct;
self.stats.integral(end+1,:) = self.seq.integral();
%self.stats.fluence(end+1)    = self.seq.fluence(self.system.M);
end
