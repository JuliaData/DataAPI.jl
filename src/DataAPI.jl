module DataAPI

"""
    defaultarray(T, N)

For a given element type `T` and number of dimensions `N`, return the appropriate array
type.

The default definition returns `Array{T, N}`. This function is useful for custom types that
have a more efficient vectorized representation (usually using SOA optimizations).

This generic function is owned by DataAPI.jl itself, which is the sole provider of the
default definition.
"""
function defaultarray end
defaultarray(::Type{T}, N) where {T} = Array{T, N}

"""
    refarray(A::AbstractArray)

For a given array `A`, potentially return an optimized "ref array" representation of the
original array, which can allow for faster comparison and sorting.

The default definition just returns the input array. This function is useful for custom
array types which already store a "hashed"-like representation of elements where testing
equality or permuting elements in place can be much faster than the original scalar value,
like pooled arrays.

This generic function is owned by DataAPI.jl itself, which is the sole provider of the
default definition.
"""
function refarray end
refarray(A::AbstractArray) = A

"""
    refvalue(A, x)

For the *original* array `A`, and a "ref value" `x` taken from `refarray(A)`, return the
appropriate *original* value. `refvalue(A, refarray(A)[I...])` must be equal to `A[I...]`.

By default, `refvalue(A, x)` returns `x` (since `refarray(A)` returns `A` by default).
This allows recovering an original array element after operating on the "ref values".

This generic function is owned by DataAPI.jl itself, which is the sole provider of the
default definition.
"""
function refvalue end
refvalue(A::AbstractArray, x) = x

"""
    refpool(A)

Whenever available, return an indexable object `pool` such that, given the *original* array `A` and
a "ref value" `x` taken from `refarray(A)`, `pool[x]` is the appropriate *original* value. Return
`nothing` if such object is not available.

By default, `refpool(A)` returns `nothing`.

If `refpool(A)` is not `nothing`, then `refpool(A)[refarray(A)[I...]]`
must be equal to (according to `isequal`) and of the same type as `A[I...]`,
and the object returned by `refpool(A)` must implement the iteration and
indexing interfaces as well as the `length`, `eachindex`, `keys`, `values`, `pairs`,
`firstindex`, `lastindex`, and `eltype` functions
in accordance with the `AbstractArray` interface.

This generic function is owned by DataAPI.jl itself, which is the sole provider of the
default definition.
"""
function refpool end
refpool(A::AbstractArray) = nothing

"""
    describe(io::IO, x)

For an object `x`, print descriptive statistics to `io`.

This generic function is owned by StatsBase.jl, which is the sole provider of the default
definition.
"""
function describe end

"""
    levels(x)

Return a vector of unique values which occur or could occur in collection `x`,
omitting `missing` even if present. Values are returned in the preferred order
for the collection, with the result of [`sort`](@ref) as a default.
If the collection is not sortable then the order of levels is unspecified.

Contrary to [`unique`](@ref), this function may return values which do not
actually occur in the data, and does not preserve their order of appearance in `x`.
"""
function levels(x)
    T = Base.nonmissingtype(eltype(x))
    levs = convert(AbstractArray{T}, filter!(!ismissing, unique(x)))
    try
        sort!(levs)
    catch
    end
    levs
end

"""
    Between(first, last)

Select the columns between `first` and `last` from a table.
"""
struct Between{T1 <: Union{Int, Symbol}, T2 <: Union{Int, Symbol}}
    first::T1
    last::T2
end

Between(x::AbstractString, y::AbstractString) = Between(Symbol(x), Symbol(y))
Between(x::Union{Int, Symbol}, y::AbstractString) = Between(x, Symbol(y))
Between(x::AbstractString, y::Union{Int, Symbol}) = Between(Symbol(x), y)

"""
    All(cols...)

Select the union of the selections in `cols`. If `cols == ()`, select all columns.
"""
struct All{T<:Tuple}
    cols::T
    All(args...) = new{typeof(args)}(args)
end

"""
    Cols(cols...)

Select the union of the selections in `cols`. If `cols == ()`, select no columns.
"""
struct Cols{T<:Tuple}
    cols::T
    Cols(args...) = new{typeof(args)}(args)
end

end # module
