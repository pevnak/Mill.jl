using Test
using Mill
using Mill: nobs, mapdata
using Mill: BagConv, convsum, bagconv, legacy_bagconv, _convshift, ∇wbagconv, ∇xbagconv, ∇convsum
using Mill: ngrams, countngrams
using Mill: p_map, inv_p_map, r_map, inv_r_map, _bagnorm
using Mill: Maybe

using Mill: gradtest, gradf

using Base.Iterators: partition, product
using Base: CodeUnits

using Documenter
using Flux
using Flux: onehot, onehotbatch
using Random
using Combinatorics
using SparseArrays
using PooledArrays
using DataFrames
using HierarchicalUtils
using StableRNGs

using BenchmarkTools: @btime

areequal(x) = true
areequal(x, y, zs...) = isequal(x, y) && areequal(y, zs...)

rng = StableRNG(25)

const BAGS = [
      length2bags([1, 2, 3]),
      length2bags([4, 1, 1]),
      length2bags([2, 2, 2])
]

const BAGS2 = [
        length2bags(ones(Int, 10)),
        length2bags(2 .* ones(Int, 5)),
        length2bags([5, 5]),
        length2bags([10]),
        length2bags([3, 4, 3]),
        AlignedBags([1:3, 0:-1, 0:-1, 4:7, 0:-1, 8:10]),
        AlignedBags([0:-1, 1:5, 0:-1, 0:-1, 0:-1, 6:10]),
        ScatteredBags([collect(1:3), collect(7:10), collect(4:6)]),
        ScatteredBags([collect(7:10), Int[], collect(1:3), Int[], collect(4:6), Int[]]),
        ScatteredBags([Int[], collect(1:10), Int[]]),
]

const BAGS3 = [
         (AlignedBags([1:2, 3:4, 0:-1]),
          ScatteredBags([[2, 3, 4], [1], Int[]]),
          AlignedBags([1:4, 0:-1, 5:8, 0:-1])),
         (AlignedBags([0:-1, 1:2, 3:4]),
          ScatteredBags([[1], [2], [3, 4]]),
          AlignedBags([0:-1, 1:7, 0:-1, 8:8])),
         (AlignedBags([0:-1, 0:-1, 1:2, 3:4]),
          ScatteredBags([[2, 4], Int[], [3, 1], Int[]]),
          AlignedBags([1:1, 2:2, 0:-1, 3:8])),
         (AlignedBags([0:-1, 1:2, 3:4, 0:-1]),
          ScatteredBags([Int[], [1, 3], [2, 4], Int[]]),
          AlignedBags([0:-1, 1:2, 3:6, 7:8]))
        ]

function Mill.unpack2mill(ds::LazyNode{:Sentence})
    s = split.(ds.data, " ")
    x = NGramMatrix(reduce(vcat, s))
    BagNode(ArrayNode(x), Mill.length2bags(length.(s)))
end

nonparam_aggregations(t::Type,d ) = Aggregation(
        SegmentedSum(randn(rng, t, d)),
        SegmentedMean(randn(rng, t, d)),
        SegmentedMax(randn(rng, t, d)),
        meanmax_aggregation(t, d))

param_aggregations(t::Type, d) = Aggregation(
        SegmentedPNorm(randn(rng, t, d), randn(rng, t, d), randn(rng, t, d)),
        SegmentedLSE(randn(rng, t, d), randn(rng, t, d)),
        summeanmaxpnormlse_aggregation(t, d))

all_aggregations(t::Type, d) = Aggregation((nonparam_aggregations(t, d), param_aggregations(t, d)))

@testset "Doctests" begin
    DocMeta.setdocmeta!(Mill, :DocTestSetup, quote
        using Mill, Flux, Random, SparseArrays, Setfield, HierarchicalUtils
    end; recursive=true)
    doctest(Mill)
end

for test_f in readdir(".")
    (endswith(test_f, ".jl") && test_f != "runtests.jl") || continue
    include(test_f)
end
