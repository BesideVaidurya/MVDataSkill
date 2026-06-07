function ACC = Accuracy(C, gt)
%ACCURACY Clustering accuracy after best label mapping.
result = Clustering8Measure(gt, C);
ACC = result(1);
end
