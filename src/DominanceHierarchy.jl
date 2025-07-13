module DominanceHierarchy

using Graphs, MetaGraphsNext, TikzGraphs, TikzPictures
using DataStructures

import Base: getindex, isless, ==, length, isequal, hash

export PB, SPB, SignedPartition, Partition, build_hierarchy, plot_hierarchy, manual_output_to_tex

abstract type AbstractPartition end

include("signed_partition.jl")
include("partition.jl")
include("hierarchy.jl")
include("tikz_utils.jl")

end
