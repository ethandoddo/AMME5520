% Matlab Grader Week 4 Learner template

tspan = [5,0]; % solve backwards in time from t=5
pf = 1; % VT = xT^2 means pT=1 ; note: working backwards from the end, hence pf

% set system: xdot = ax + bu ; J = Σ(qx^2 + ru^2)
a = 1;
b = 1;
q = 1;
r = 1;

%% Solve for p
options = odeset('MaxStep',0.3);
[t,p] = ode45(@(t,p) dpdt(p,a,b,q,r), tspan, pf,options);

p = flip(p); % flip to chronological order
t = flip(t);

%% Simulate results
dt=(t(end)-t(1))/length(t);
x(1)=5; % initial position

for i=1:length(t)
    u = -(b/r)*p(i)*x(i);
    xdot = a*x(i)+b*u;
    x(i+1) = x(i) + xdot*dt;
end



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pdot = dpdt(p,a,b,q,r)
    pdot = -2*a*p + (b^2/r)*p^2 - q;
end
