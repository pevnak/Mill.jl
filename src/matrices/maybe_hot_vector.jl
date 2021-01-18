struct MaybeHotVector{T, U, V} <: AbstractVector{V}
    i::T
    l::U

    MaybeHotVector(i::T, l::U) where {T <: Integer, U <: Integer} = new{T, U, Bool}(i, l)
    MaybeHotVector(i::T, l::U) where {T <: Missing, U <: Integer} = new{T, U, Missing}(i, l)
end

Base.size(x::MaybeHotVector) = (x.l,)
Base.length(x::MaybeHotVector) = x.l
Base.getindex(x::MaybeHotVector, i::Integer) = (@boundscheck checkbounds(x, i); x.i == i)
Base.getindex(x::MaybeHotVector, ::Colon) = MaybeHotVector(x.i, x.l)

Base.hcat(xs::MaybeHotVector...) = reduce(hcat, collect(xs))
function Base.reduce(::typeof(hcat), xs::Vector{<:MaybeHotVector})
    reduce(hcat, MaybeHotMatrix.(xs))
end

reduce(::typeof(catobs), as::Vector{<:MaybeHotVector}) = reduce(hcat, as)

A::AbstractMatrix * b::MaybeHotVector = (_check_mul(A, b); _mul(A, b))
Zygote.@adjoint A::AbstractMatrix * b::MaybeHotVector = (_check_mul(A, b); Zygote.pullback(_mul, A, b))

_mul(A::AbstractMatrix, b::MaybeHotVector{Missing}) = fill(missing, size(A, 1))
_mul(A::AbstractMatrix, b::MaybeHotVector{<:Integer}) = A[:, b.i]

Flux.onehot(x::MaybeHotVector{<:Integer}) = onehot(x.i, 1:x.l)

maybehot(::Missing, labels) = MaybeHotVector(missing, length(labels))
function maybehot(l, labels)
    i = findfirst(isequal(l), labels)
    isnothing(i) && ArgumentError("Value $l not in labels $labels") |> throw
    MaybeHotVector(i, length(labels))
end

Base.hash(x::MaybeHotVector, h::UInt) = hash((x.i, x.l), h)
(x1::MaybeHotVector == x2::MaybeHotVector) = x1.i == x2.i && x1.l == x2.l
isequal(x1::MaybeHotVector, x2::MaybeHotVector) = isequal(x1.i, x2.i) && x1.l == x2.l