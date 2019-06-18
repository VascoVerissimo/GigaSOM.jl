#fix the seed
Random.seed!(1)

p = addprocs(2)
@everywhere using DistributedArrays
@everywhere using GigaSOM

# only use lineage_markers for clustering
(lineage_markers,)= getMarkers(panel)
cc = map(Symbol, lineage_markers)
df_som = daf.fcstable[:,cc]

# concatenate the dataset for performance testing
n = 0
for i in 1:n
    global df_som
    df_som = vcat(df_som, df_som)
end

@testset "Test Data conversion" begin
    @testset "Function convertTrainingData" begin
        x = GigaSOM.convertTrainingData(df_som)
        @test typeof(x) == Array{Float32, 2}
    end

    @testset "Function distMatrix" begin
        # initialise the codes with random samples
        xdim = 10
        ydim = 10
        x = GigaSOM.convertTrainingData(df_som)
        codes = GigaSOM.x[rand(1:size(x,1), xdim * ydim),:]
        @test size(codes) == (100, 10)
        @test typeof(codes) == Array{Float32, 2}
        grid = GigaSOM.gridRectangular(xdim, ydim)
        @test size(grid) == (100, 2)
        @test typeof(grid) == Array{Float32, 2}
        dm = GigaSOM.distMatrix(grid, false)
        @test size(dm) == (100, 100)
        @test typeof(dm) == Array{Float32, 2}
    end

    @testset "gaussianKernel" begin
        y = GigaSOM.gaussianKernel(Float32(10.0), Float32(6.0))
        @test typeof(y) == Float32
    end
end

#PARALLEL

som2 = initGigaSOM(df_som, 10, 10)

@testset "GigaSOM initialisation" begin
    @testset "Type test" begin
        @test typeof(som2) == GigaSOM.Som
        @test som2.toroidal == false
        @test typeof(som2.grid) == Array{Float32,2}
    end
    @testset "Dimensions Test" begin
        @test size(som2.codes) == (100,10)
        @test som2.xdim == 10
        @test som2.ydim == 10
        @test som2.numCodes == 100
    end

end

@time som2 = trainGigaSOM(som2, df_som, epochs = 2)

mywinners = mapToGigaSOM(som2, df_som)
CSV.write("cell_clustering_som.csv", mywinners)

@time mywinners = mapToGigaSOM(som2, df_som)

codes = som2.codes
@test size(codes) == (100,10)

df_codes = DataFrame(codes)
names!(df_codes, Symbol.(som2.colNames))
CSV.write(genDataPath*"/parallel_df_codes.csv", df_codes)
CSV.write(genDataPath*"/parallel_mywinners.csv", mywinners)


#TEST PARALLEL

#create new refData if necessary
# CSV.write(refDataPath*"/ref_parallel_df_codes.csv", df_codes)
# CSV.write(refDataPath*"/ref_parallel_mywinners.csv", mywinners)


#preparing parallel for testing
ref_parallel_df_codes = CSV.File(refDataPath*"/ref_parallel_df_codes.csv") |> DataFrame
ref_paralel_mywinners = CSV.File(refDataPath*"/ref_parallel_mywinners.csv") |> DataFrame
parallel_df_codes = CSV.File(genDataPath*"/parallel_df_codes.csv") |> DataFrame
parallel_df_codes_test = first(parallel_df_codes, 10)
parallel_mywinners = CSV.File(genDataPath*"/parallel_mywinners.csv") |> DataFrame
parallel_mywinners_test = first(parallel_mywinners, 10)

#test parallel
@testset "refData_parallel" begin
    for (i, j) in zip(parallel_df_codes_test[:,1], ref_parallel_df_codes[:,1])
        test_parallel_df = @test isapprox(i, j; atol = 0.001)
        return test_parallel_df
    end
    @test ref_parallel_mywinners == parallel_mywinners_test
end
