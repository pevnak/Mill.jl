import Base: show

include("segmented_mean.jl")
include("segmented_max.jl")
include("segmented_pnorm.jl")
include("segmented_lse.jl")

# backward compatibility for models trained on previous versions of Mill
_segmented_mean = segmented_mean
_segmented_max = segmented_max

const AGGF = [:segmented_max, :segmented_mean]
# generic code, for pnorm, situation is more complicated
for s in AGGF
    @eval $s(x::TrackedMatrix, args...) = Flux.Tracker.track($s, x, args...)
    @eval $s(x, bags, w::TrackedVector) = Flux.Tracker.track($s, x, bags, w)
    @eval $s(x::TrackedMatrix, bags, w::TrackedVector) = Flux.Tracker.track($s, x, bags, w)

    @eval $s(x::ArrayNode, args...) = mapdata(x -> $s(x, args...), x)

    @eval Flux.Tracker.@grad function $s(args...)
        $s(Flux.data.(args)...), Δ -> $(Symbol(string(s, "_back")))(Δ, args...)
    end
end

const ParamAgg = Union{PNorm, LSE}

struct Aggregation{F}
    fs::F
end
Flux.@treelike Aggregation

Aggregation(a::Union{Function, ParamAgg}) = Aggregation((a,))
(a::Aggregation)(args...) = vcat([f(args...) for f in a.fs]...)

# convenience definitions - nested Aggregations work, but call definitions directly to avoid overhead
# without parameters
SegmentedMax() = Aggregation(segmented_max)
SegmentedMean() = Aggregation(segmented_mean)
SegmentedMeanMax() = Aggregation((segmented_mean, segmented_max))
for s in [:SegmentedMax, :SegmentedMean, :SegmentedMeanMax]
    @eval $s(d::Int) = $s()
    @eval export $s
end

# with parameters
names = ["PNorm", "LSE", "Mean", "Max"]
fs = [:(PNorm(d)), :(LSE(d)), :segmented_mean, :segmented_max]
for idxs in powerset(collect(1:length(fs)))
    1 in idxs || 2 in idxs || continue
    @eval $(Symbol("Segmented", names[idxs]...))(d::Int) = Aggregation(tuple($(fs[idxs]...)))
    @eval export $(Symbol("Segmented", names[idxs]...))
end

function modelprint(io::IO, a::Aggregation; pad=[])
    paddedprint(io, "Aggregation($(join(a.fs, ", ")))\n")
end

function modelprint(io::IO, f; pad=[])
    paddedprint(io, "$f\n")
end