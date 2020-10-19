[status,fCA_path] = system(sprintf("find /gpfs01/share/HearingMRI -type d -name 'fMRI_Connectivity_Analysis'"));
fCA_path = fCA_path(1:end-1);
addpath(genpath(fCA_path)); % genpath adds path of files in folders
clear status

figPath = '/gpfs01/share/HearingMRI/fMRI_Connectivity_Analysis/ConnecAnalysis_Out/figures/526n90y';

load('netmats_526n90y.mat')
load('comparisons_526n90y.mat')
netmatArrL = [who('LH_netmat*')];
corrArrL = [who('LH_corr_*')];

netmatArrR = [who('RH_netmat*')];
corrArrR = [who('RH_corr_*')];

if length(netmatArrL) == length(corrArrL)
    for i = 1 : length(netmatArrL)
        netmats = eval(netmatArrL{i}); p_corrected = eval(corrArrL{i});
        ncon = 1;
        view = 1;
        
        cols=size(netmats,2);
        parcels=sqrt(size(p_corrected,2));
        rtCols=sqrt(cols);
        RndRc=round(rtCols);
        
        gridNet=reshape(p_corrected(1,:),RndRc,RndRc);
        [gridNeti,gridNetj]=find(gridNet==max(gridNet(:)));
        if parcels == 180
            node1 = dummyL.label{gridNeti(1)};
            node2 = dummyL.label{gridNetj(1)};
            str = sprintf(strcat('For %s: optimal corrected p=%.5f at edge between nodes %s', ...
                ' and %s\n'),corrArrL{i}, 1-max(gridNet(:)),  node1, node2);
            disp(str)
        else
            node1 = dummyL.label{roiIndices(gridNeti(1))};
            node2 = dummyL.label{roiIndices(gridNetj(1))};
            str = sprintf(strcat('For %s: optimal corrected p=%.5f at edge between nodes %s', ...
                ' and %s\n'), corrArrL{i}, 1-max(gridNet(:)),  node1, node2);
            disp(str)
            
        end
        h = figure(i);
        imagesc(gridNet.*(triu(gridNet,1)>0.95) + tril(gridNet));  % delete non-significant entries above the diag
        colormap('jet');
        colorbar;
        
        
        
        title(sprintf(strcat('For %s: optimal corrected p=%.5f at edge between nodes %s', ...
            ' and %s'), corrArrL{i}, 1-max(gridNet(:)),  node1, node2), 'Interpreter', 'none');
        
        
        yyaxis right
        ylabel("1 - p value")
        xlabel("All results corrected for multiple comparisons")
        saveFigure(h,sprintf('%s/%s_526n90y.png',figPath, corrArrL{i}));
    end
else
    disp(strcat('Number of netmats does not equal the number of p_corrected', ...
        ' correlations.'))
end

if length(netmatArrR) == length(corrArrR)
    for i = 1 : length(netmatArrR)
        netmats = eval(netmatArrR{i}); p_corrected = eval(corrArrR{i});
        ncon = 1;
        view = 1;
        
        cols=size(netmats,2);
        parcels=sqrt(size(p_corrected,2));
        rtCols=sqrt(cols);
        RndRc=round(rtCols);
        
        gridNet=reshape(p_corrected(1,:),RndRc,RndRc);
        [gridNeti,gridNetj]=find(gridNet==max(gridNet(:)));
        if parcels == 180
            node1 = dummyR.label{gridNeti(1)};
            node2 = dummyR.label{gridNetj(1)};
            str = sprintf(strcat('For %s: optimal corrected p=%.5f at edge between nodes %s', ...
                ' and %s\n'),corrArrR{i}, 1-max(gridNet(:)),  node1, node2);
            disp(str)
        else
            node1 = dummyR.label{roiIndices(gridNeti(1))};
            node2 = dummyR.label{roiIndices(gridNetj(1))};
            str = sprintf(strcat('For %s: optimal corrected p=%.5f at edge between nodes %s', ...
                ' and %s\n'), corrArrR{i}, 1-max(gridNet(:)),  node1, node2);
            disp(str)
            
        end
        h = figure(i);
        imagesc(gridNet.*(triu(gridNet,1)>0.95) + tril(gridNet));  % delete non-significant entries above the diag
        colormap('jet');
        colorbar;
        
        
        
        title(sprintf(strcat('For %s: optimal corrected p=%.5f at edge between nodes %s', ...
            ' and %s'), corrArrR{i}, 1-max(gridNet(:)),  node1, node2), 'Interpreter', 'none');
        
        
        yyaxis right
        ylabel("1 - p value")
        xlabel("All results corrected for multiple comparisons")
        saveFigure(h,sprintf('%s/%s_526n90y.png',figPath, corrArrR{i}));
    end
else
    disp(strcat('Number of netmats does not equal the number of p_corrected', ...
        ' correlations.'))
end