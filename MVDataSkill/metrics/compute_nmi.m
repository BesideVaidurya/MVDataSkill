function [nmi, clust_ent] = compute_nmi(T, H)
%COMPUTE_NMI Normalized mutual information and clustering entropy.

T = T(:);
H = H(:);
N = length(T);
classes = unique(T);
clusters = unique(H);
num_class = length(classes);
num_clust = length(clusters);

D = zeros(1, num_class);
for j = 1:num_class
    index_class = (T == classes(j));
    D(j) = sum(index_class);
end

mi = 0;
B = zeros(1, num_clust);
avgent = 0;
for i = 1:num_clust
    index_clust = (H == clusters(i));
    B(i) = sum(index_clust);
    for j = 1:num_class
        index_class = (T == classes(j));
        Aij = sum(index_class .* index_clust);
        if Aij ~= 0
            miarr = Aij / N * log2(N * Aij / (B(i) * D(j)));
            avgent = avgent - (B(i) / N) * (Aij / B(i)) * log2(Aij / B(i));
        else
            miarr = 0;
        end
        mi = mi + miarr;
    end
end

class_ent = 0;
for i = 1:num_class
    class_ent = class_ent + D(i) / N * log2(N / D(i));
end

clust_ent = 0;
for i = 1:num_clust
    clust_ent = clust_ent + B(i) / N * log2(N / B(i));
end

if (clust_ent + class_ent) == 0
    nmi = 0;
else
    nmi = 2 * mi / (clust_ent + class_ent);
end

% Keep avgent computed for parity with the original implementation.
if isnan(avgent) %#ok<ISNAN>
    avgent = 0;
end
end
