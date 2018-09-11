__precompile__()
module Mill
using JSON
using Flux
using Adapt
using MLDataPattern

const COLORS = [:blue, :red, :green, :yellow, :cyan, :magenta]

function paddedprint(io, s...; color=:default, pad=[])
    for (c, p) in pad
        print_with_color(c, io, p)
    end
    print_with_color(color, io, s...)
end

const Bags = Vector{UnitRange{Int64}}
const VecOrRange = Union{UnitRange{Int},AbstractVector{Int}}
const MillFunction = Union{Flux.Dense, Flux.Chain, Function}

include("util.jl")
include("datanode.jl")
include("modelnode.jl")
include("aggregation/aggregation.jl")

export AbstractNode, AbstractTreeNode, AbstractBagNode
export ArrayNode, BagNode, WeightedBagNode, TreeNode
export MillModel, ArrayModel, BagModel, ProductModel

end
