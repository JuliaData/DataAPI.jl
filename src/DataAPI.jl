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
array types which already store a "hashed"-like representation of elements where comparison
can be much faster than the original scalar value, like pooled arrays.

This generic function is owned by DataAPI.jl itself, which is the sole provider of the
default definition.
"""
function refarray end
refarray(A::AbstractArray) = A

"""
    refvalue(A, x)

For the *original* array `A`, and a "ref value" `x` taken from `refarray(A)`, return the
appropriate *original* value.

By default, `refvalue(A, x)` returns `x` (since `refarray(A)` returns `A` by default).
This allows recovering an original array element after operating on the "ref values".

This generic function is owned by DataAPI.jl itself, which is the sole provider of the
default definition.
"""
function refvalue end
refvalue(A::AbstractArray, x) = x

"""
    nondatavaluetype(T)

For a type `T`, return the corresponding non-`DataValue` type, translating between
`Union{T, Missing}` and `DataValue{T}`.

For example, `nondatavaluetype(Int64)` returns `Int64`, while
`nondatavaluetype(DataValue{Int64})` returns `Union{Int64, Missing}`.

This generic function is owned by Tables.jl, which is the sole provider of the default
definition.
"""
function nondatavaluetype end

"""
    datavaluetype(T)

For a type `T`, return the corresponding `DataValue` type, translating between 
`Union{T, Missing}` and `DataValue{T}`.

For example, `datavaluetype(Int64)` returns `Int64`, while
`datavaluetype(Union{Int64, Missing})` returns `DataValue{Int64}`.

This generic function is owned by Tables.jl, which is the sole provider of the default
definition.
"""
function datavaluetype end

"""
    unwrap(x)

For a value `x`, potentially "unwrap" it from a `DataValue` or similar container.

This generic function is owned by Tables.jl, which is the sole provider of the default
definition.
"""
function unwrap end

"""
    describe(io::IO, x)

For an object `x`, print descriptive statistics to `io`.

This generic function is owned by StatsBase.jl, which is the sole provider of the default
definition.
"""
function describe end

end # module
