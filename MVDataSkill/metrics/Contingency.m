function Cont = Contingency(Mem1, Mem2)
%CONTINGENCY Form contingency matrix for two clustering vectors.

Mem1 = Mem1(:);
Mem2 = Mem2(:);
if nargin < 2 || min(size(Mem1)) > 1 || min(size(Mem2)) > 1
    error('Contingency: Requires two vector arguments.');
end

Mem1 = relabel_to_one(Mem1);
Mem2 = relabel_to_one(Mem2);
Cont = zeros(max(Mem1), max(Mem2));
for i = 1:length(Mem1)
    Cont(Mem1(i), Mem2(i)) = Cont(Mem1(i), Mem2(i)) + 1;
end
end

function y = relabel_to_one(y)
u = unique(y);
y2 = zeros(size(y));
for i = 1:numel(u)
    y2(y == u(i)) = i;
end
y = y2;
end
