# Load and transform
# build the general workflow to have the data ready

#=
using FCSFiles for loading
as this function is only the basic parsing of the binary
FCS, we need to see what functionality is missing and
extend this in the original package
=#

#create genData and data folder and change dir to dataPath
cwd = pwd()
if occursin("jenkins", homedir()) || "TRAVIS" in keys(ENV)
    genDataPath = mktempdir()
    dataPath = mktempdir()
else
    if !occursin("test", cwd)
        cd("test")
        cwd = pwd()
    end
    dataFolders = ["genData", "data"]
    for dir in dataFolders
        if !isdir(dir)
            mkdir(dir)
        end
    end
    genDataPath = cwd*"/genData"
    dataPath = cwd*"/data"
end

refDataPath = cwd*"/refData"
cd(dataPath)

# fetch the required data for testing and download the zip archive and unzip it
dataFiles = ["PBMC8_metadata.xlsx", "PBMC8_panel.xlsx", "PBMC8_fcs_files.zip"]
for f in dataFiles
    if !isfile(f)
        download("http://imlspenticton.uzh.ch/robinson_lab/cytofWorkflow/"*f, f)
        if occursin(".zip", f)
            run(`unzip PBMC8_fcs_files.zip`)
        end
    else
    end
end

md = DataFrame(XLSX.readtable("PBMC8_metadata.xlsx", "Sheet1")...)
panel = DataFrame(XLSX.readtable("PBMC8_panel.xlsx", "Sheet1")...)
panel[:Isotope] = map(string, panel[:Isotope])
panel[:Metal] = map(string, panel[:Metal])
panel[:Antigen] = map(string, panel[:Antigen])
panel.Metal[1]=""
insertcols!(panel,4,:fcs_colname => map((x,y,z)->x.*"(".*y.*z.*")".*"Dd",panel[:Antigen],panel[:Metal],panel[:Isotope]))
print(panel.fcs_colname)

lineage_markers, functional_markers = getMarkers(panel)

fcs_raw = readFlowset(md.file_name)
cleannames!(fcs_raw)

# subset the data
# transform the data
# create daFrame file
daf = create_daFrame(fcs_raw, md, panel)

# change the directory back to the current directory
cd(cwd)

CSV.write(genDataPath*"/daf.csv", daf.fcstable)

#test cleannames
@testset "cleannames" begin
    for i in eachindex(lineage_markers)
            test_clean = @test !in("-",i)
            return test_clean
    end

    for i in eachindex(functional_markers)
            test_clean = @test !in("-",i)
            return test_clean
    end

    for (k,v) in fcs_raw
        colnames = names(v)
        for i in eachindex(colnames)
            test_clean = @test !in("-",i)
            return test_clean
        end
    end
end
