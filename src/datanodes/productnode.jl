struct ProductNode{T,C} <: AbstractProductNode
    data::T
    metadata::C

    function ProductNode{T,C}(data::T, metadata::C) where {T, C}
        @assert length(data) >= 1 && all(x -> nobs(x) == nobs(data[1]), data)
        new(data, metadata)
    end
end

ProductNode(data::T) where {T} = ProductNode{T, Nothing}(data, nothing)
ProductNode(data::T, metadata::C) where {T, C} = ProductNode{T, C}(data, metadata)

@deprecate TreeNode(data) ProductNode(data)
@deprecate TreeNode(data, metadata) ProductNode(data, metadata)

Flux.@functor ProductNode

mapdata(f, x::ProductNode) = ProductNode(map(i -> mapdata(f, i), x.data), x.metadata)

Base.ndims(x::AbstractProductNode) = Colon()
LearnBase.nobs(a::AbstractProductNode) = nobs(a.data[1], ObsDim.Last)
LearnBase.nobs(a::AbstractProductNode, ::Type{ObsDim.Last}) = nobs(a)

function reduce(::typeof(catobs), as::Vector{T}) where {T <: ProductNode}
    data = _cattrees([x.data for x in as])
    metadata = reduce(catobs, [a.metadata for a in as])
    ProductNode(data, metadata)
end

Base.getindex(x::ProductNode, i::VecOrRange) = ProductNode(subset(x.data, i), subset(x.metadata, i))