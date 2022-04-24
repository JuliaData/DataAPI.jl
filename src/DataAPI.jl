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
    invrefpool(A)

Whenever available, return an indexable object such that given an array `A`
for which `refpool(A)` is not `nothing`:

* for any valid index `x` into `refpool(A)`, `invrefpool(A)[refpool(A)[x]]` is equal to `x`
  (according to `isequal`) and of the same type as `x`;
* for any valid index `ix` into `invrefpool(A)` , `refpool(A)[invrefpool(A)[ix]]` is equal to `ix`
  (according to `isequal`) and of the same type as `ix`.

Additionally it is required that for `invrefpool(A)` the following methods are defined:

* `Base.haskey`: allowing to check if `ix` is a valid index into it.
* `Base.get`: allowing to get a value from it or a passed default value if it is not present.

By default, `invrefpool(A)` returns `nothing`.

If `invrefpool(A)` is not `nothing`, then `refpool(A)` also must not be `nothing`.

This generic function is owned by DataAPI.jl itself, which is the sole provider of the
default definition.
"""
function invrefpool end
invrefpool(A::AbstractArray) = nothing

"""
    describe(io::IO, x)

For an object `x`, print descriptive statistics to `io`.

This generic function is owned by StatsBase.jl, which is the sole provider of the default
definition.
"""
function describe end

# Sentinel type needed to make `levels` inferrable
struct _Default end

"""
    levels(x; skipmissing=true)

Return a vector of unique values which occur or could occur in collection `x`.
`missing` values are skipped unless `skipmissing=false` is passed.

Values are returned in the preferred order for the collection,
with the result of [`sort`](@ref) as a default.
If the collection is not sortable then the order of levels is unspecified.

Contrary to [`unique`](@ref), this function may return values which do not
actually occur in the data, and does not preserve their order of appearance in `x`.
"""
@inline levels(x; skipmissing::Union{Bool, _Default}=_Default()) =
    skipmissing isa _Default || skipmissing ?
        _levels_skipmissing(x) : _levels_missing(x)

# The `which` check is here for backward compatibility:
# if a type implements a custom `levels` method but does not support
# keyword arguments, `levels(x, skipmissing=true/false)` will dispatch
# to the fallback methods here, and we take care of calling that custom method
function _levels_skipmissing(x)
    if which(DataAPI.levels, Tuple{typeof(x)}) === which(DataAPI.levels, Tuple{Any})
        T = Base.nonmissingtype(eltype(x))
        u = unique(x)
        # unique returns its input with copying for ranges
        # (and possibly for other types guaranteed to hold unique values)
        nmu = (u isa AbstractRange || u === x || Base.mightalias(u, x)) ?
            filter(!ismissing, u) : filter!(!ismissing, u)
        levs = convert(AbstractArray{T}, nmu)
        try
            sort!(levs)
        catch
        end
        return levs
    else
        return levels(x)
    end
end

function _levels_missing(x)
    if which(DataAPI.levels, Tuple{typeof(x)}) === which(DataAPI.levels, Tuple{Any})
        u = convert(AbstractArray{eltype(x)}, unique(x))
        # unique returns its input with copying for ranges
        # (and possibly for other types guaranteed to hold unique values)
        levs = (x isa AbstractRange || u === x || Base.mightalias(u, x)) ?
            Base.copymutable(u) : u
        try
            sort!(levs)
        catch
        end
        return levs
    # This is a suboptimal fallback since it does a second pass over the data
    elseif any(ismissing, x)
        return [levels(x); missing]
    else
        return convert(AbstractArray{eltype(x)}, levels(x))
    end
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
    function All(args...)
        if !isempty(args)
            Base.depwarn("All(args...) is deprecated, use Cols(args...) instead", :All)
        end
        return new{typeof(args)}(args)
    end
end

"""
    Cols(cols...)
    Cols(f::Function)

Select the union of the selections in `cols`. If `cols == ()`, select no columns.

If the only positional argument is a `Function` `f` then select the columns whose
names passed to the `f` predicate as strings return `true`.
"""
struct Cols{T<:Tuple}
    cols::T
    Cols(args...) = new{typeof(args)}(args)
end

"""
    BroadcastedSelector(selector)

Wrapper type around a `Between`, `All` or `Cols` indicating that
an operation should be applied to each column included by the wrapped selector.

# Examples
```jldoctest
julia> using DataAPI

julia> DataAPI.Between(:a, :e) .=> sin
DataAPI.BroadcastedSelector{DataAPI.Between{Symbol, Symbol}}(DataAPI.Between{Symbol, Symbol}(:a, :e)) => sin

julia> DataAPI.Cols(r"x") .=> [sum, prod]
2-element Vector{Pair{DataAPI.BroadcastedSelector{DataAPI.Cols{Tuple{Regex}}}, _A} where _A}:
 DataAPI.BroadcastedSelector{DataAPI.Cols{Tuple{Regex}}}(DataAPI.Cols{Tuple{Regex}}((r"x",))) => sum
 DataAPI.BroadcastedSelector{DataAPI.Cols{Tuple{Regex}}}(DataAPI.Cols{Tuple{Regex}}((r"x",))) => prod
```
"""
struct BroadcastedSelector{T}
    sel::T
    BroadcastedSelector(sel) = new{typeof(sel)}(sel)
end

Base.Broadcast.broadcastable(x::Between) = Ref(BroadcastedSelector(x))
Base.Broadcast.broadcastable(x::All) = Ref(BroadcastedSelector(x))
Base.Broadcast.broadcastable(x::Cols) = Ref(BroadcastedSelector(x))

"""
    unwrap(x)

For a given scalar argument `x`, potentially "unwrap" it to return the base wrapped value.
Useful as a generic API for wrapper types when the original value is needed.

The default definition just returns `x` itself, i.e. no unwrapping is performned.

This generic function is owned by DataAPI.jl itself, which is the sole provider of the
default definition.
"""
function unwrap end
unwrap(x) = x

# The database-style join methods for tabular data type.
# The common interface is `*join(x, y; ...)` and use the keyword arguments
# for the join criteria.
# See the design of DataFrames.jl also.
function innerjoin end
function outerjoin end
function rightjoin end
function leftjoin end
function semijoin end
function antijoin end
function crossjoin end

"""
    nrow(t)

Return the number of rows of table `t`.
"""
function nrow end

"""
    ncol(t)

Return the number of columns of table `t`.
"""
function ncol end

"""
    allcombinations(sink, ...)

Create table from all combinations of values in passed arguments
using a `sink` function to materialize the table.
"""
function allcombinations end

end # module
