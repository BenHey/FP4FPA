# this script installs all required packages to run DICEinJulia.jl
using Pkg
println("Installation of required packages")
Pkg.update()
if ! in("IJulia",keys(Pkg.installed())) Pkg.add("IJulia") end
if ! in("Revise",keys(Pkg.installed())) Pkg.add("Revise") end
if ! in("Plots",keys(Pkg.installed())) Pkg.add("Plots") end
if ! in("YAML",keys(Pkg.installed())) Pkg.add("YAML") end
if ! in("DataFrames",keys(Pkg.installed())) Pkg.add("DataFrames") end
if ! in("IterTools",keys(Pkg.installed())) Pkg.add("IterTools") end
if ! in("JLD2",keys(Pkg.installed())) Pkg.add("JLD2") end
if ! in("FileIO",keys(Pkg.installed())) Pkg.add("FileIO") end
if ! in("Combinatorics",keys(Pkg.installed())) Pkg.add("Combinatorics") end
if ! in("ProgressMeter",keys(Pkg.installed())) Pkg.add("ProgressMeter") end
if ! in("Revise",keys(Pkg.installed())) Pkg.add("Revise") end
if ! in("StatsBase",keys(Pkg.installed())) Pkg.add("StatsBase") end
if ! in("LaTeXStrings",keys(Pkg.installed())) Pkg.add("LaTeXStrings") end
if ! in("ArgParse",keys(Pkg.installed())) Pkg.add("ArgParse") end
if ! in("FilePathsBase",keys(Pkg.installed())) Pkg.add("FilePathsBase") end
if ! in("FileIO",keys(Pkg.installed())) Pkg.add("FileIO") end
@warn("Packages installed!")



