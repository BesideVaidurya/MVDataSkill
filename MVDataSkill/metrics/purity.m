function [ACC, MIhat, Purity] = purity(Y, predY)
%PURITY Return ACC, NMI and purity for clustering labels.
result = Clustering8Measure(Y, predY);
ACC = result(1);
MIhat = result(2);
Purity = result(3);
end
