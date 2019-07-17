
cd(cwd)
checkDir()

#fix the seed
Random.seed!(1)

if nprocs() <= 2
    p = addprocs(2)
end
@everywhere using DistributedArrays
@everywhere using GigaSOM
@everywhere using Distances


# only use lineageMarkers for clustering
(lineageMarkers,)= getMarkers(panel)
cc = map(Symbol, lineageMarkers)
dfSom = daf.fcstable[:,cc]

# concatenate the dataset for performance testing

n = [0,5,3,1,2,1]
for i in n
    if i == 0
        som2 = initGigaSOM(dfSom, 10, 10)
        s = nrow(dfSom)
        print("DATA SIZE: ", s, " rows\n")
        @time som2 = trainGigaSOM(som2, dfSom, epochs = 10, r = 6.0)
    else
        for j in 1:i
            global dfSom
            dfSom = vcat(dfSom, dfSom)
        end
        som2 = initGigaSOM(dfSom, 10, 10)
        s = nrow(dfSom)
        print("DATA SIZE: ", s, " rows\n")
        @time som2 = trainGigaSOM(som2, dfSom, epochs = 10, r = 6.0)
    end
end

cd(cwd)
