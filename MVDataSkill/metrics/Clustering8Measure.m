function result = Clustering8Measure(Y, predY)
%CLUSTERING8MEASURE Return ACC, NMI, Purity, Fscore, Precision, Recall, ARI, Entropy.

Y = double(Y(:));
predY = double(predY(:));
if numel(Y) ~= numel(predY)
    error('Clustering8Measure: label lengths must match.');
end

Y = relabel_to_one(Y);
predY = relabel_to_one(predY);

[ACC, mappedPred] = clustering_accuracy(Y, predY);
[nmi, Entropy] = compute_nmi(Y, predY);
Purity = clustering_purity(Y, predY);
[Fscore, Precision, Recall] = compute_f(Y, predY);
ARI = RandIndex(Y, predY);

result = [ACC nmi Purity Fscore Precision Recall ARI Entropy];
end

function y = relabel_to_one(y)
u = unique(y);
y2 = zeros(size(y));
for i = 1:numel(u)
    y2(y == u(i)) = i;
end
y = y2;
end

function [acc, mappedPred] = clustering_accuracy(Y, predY)
classNum = max(max(Y), max(predY));
confusion = zeros(classNum, classNum);
for i = 1:classNum
    for j = 1:classNum
        confusion(i, j) = sum(Y == i & predY == j);
    end
end

assignment = hungarian_max(confusion);
mappedPred = zeros(size(predY));
for j = 1:numel(assignment)
    if assignment(j) > 0
        mappedPred(predY == j) = assignment(j);
    end
end
acc = sum(Y == mappedPred) / numel(Y);
end

function purityValue = clustering_purity(Y, predY)
clusters = unique(predY);
correctNum = 0;
for i = 1:numel(clusters)
    members = Y(predY == clusters(i));
    if ~isempty(members)
        correctNum = correctNum + max(hist(members, 1:max(Y)));
    end
end
purityValue = correctNum / numel(predY);
end

function assignment = hungarian_max(weight)
%HUNGARIAN_MAX Maximize column-to-row assignment for a square weight matrix.
% assignment(col) = row.

n = size(weight, 1);
cost = max(weight(:)) - weight;
u = zeros(n + 1, 1);
v = zeros(n + 1, 1);
p = zeros(n + 1, 1);
way = zeros(n + 1, 1);

for i = 1:n
    p(1) = i;
    j0 = 1;
    minv = inf(n + 1, 1);
    used = false(n + 1, 1);
    way(:) = 0;
    while true
        used(j0) = true;
        i0 = p(j0);
        delta = inf;
        j1 = 1;
        for j = 2:n + 1
            if ~used(j)
                cur = cost(i0, j - 1) - u(i0) - v(j);
                if cur < minv(j)
                    minv(j) = cur;
                    way(j) = j0;
                end
                if minv(j) < delta
                    delta = minv(j);
                    j1 = j;
                end
            end
        end
        for j = 1:n + 1
            if used(j)
                u(p(j)) = u(p(j)) + delta;
                v(j) = v(j) - delta;
            else
                minv(j) = minv(j) - delta;
            end
        end
        j0 = j1;
        if p(j0) == 0
            break;
        end
    end
    while true
        j1 = way(j0);
        p(j0) = p(j1);
        j0 = j1;
        if j0 == 1
            break;
        end
    end
end

assignment = zeros(1, n);
for j = 2:n + 1
    if p(j) > 0
        assignment(j - 1) = p(j);
    end
end
end
