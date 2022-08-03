using Test, DataAPI

const ≅ = isequal

# For `levels` tests
struct TestArray{T} <: AbstractVector{T}
    x::Vector{T}
end
Base.size(x::TestArray) = size(x.x)
Base.getindex(x::TestArray, i) = x.x[i]
DataAPI.levels(x::TestArray) = reverse(DataAPI.levels(x.x))

# An example implementation of metadata
# For simplicity Int col indexing is not implemented
# and no checking if col is a column of a table is performed

struct TestMeta
    table::Dict{String, Any}
    col::Dict{Symbol, Dict{String, Any}}

    TestMeta() = new(Dict{String, Any}(), Dict{Symbol, Dict{String, Any}}())
end

function DataAPI.metadata(x::TestMeta, key::AbstractString; style::Bool=false)
    return style ? x.table[key] : x.table[key][1]
end

DataAPI.metadatakeys(x::TestMeta) = keys(x.table)

function DataAPI.metadata!(x::TestMeta, key::AbstractString, value; style)
    x.table[key] = (value, style)
    return x
end

function DataAPI.metadata!(x::TestMeta, key::AbstractString, value; style)
    x.table[key] = (value, style)
    return x
end

DataAPI.deletemetadata!(x::TestMeta, key::AbstractString) = delete!(x.table, key)
DataAPI.deletemetadata!(x::TestMeta) = empty!(x.table)

function DataAPI.colmetadata(x::TestMeta, col::Symbol, key::AbstractString; style::Bool=false)
    return style ? x.col[col][key] : x.col[col][key][1]
end

function DataAPI.colmetadatakeys(x::TestMeta, col::Symbol)
    haskey(x.col, col) && return keys(x.col[col])
    return ()
end

function DataAPI.colmetadatakeys(x::TestMeta)
    isempty(x.col) && return ()
    return (col => keys(x.col[col]) for col in keys(x.col))
end

function DataAPI.colmetadata!(x::TestMeta, col::Symbol, key::AbstractString, value; style)
    if haskey(x.col, col)
        x.col[col][key] = (value, style)
    else
        x.col[col] = Dict{Any, Any}(key => (value, style))
    end
    return x
end

function DataAPI.deletecolmetadata!(x::TestMeta, col::Symbol, key::AbstractString)
    if haskey(x.col, col)
        delete!(x.col[col], key)
    else
        throw(ArgumentError("column $col not found"))
    end
    return x
end

function DataAPI.deletecolmetadata!(x::TestMeta, col::Symbol)
    if haskey(x.col, col)
        delete!(x.col, col)
    else
        throw(ArgumentError("column $col not found"))
    end
    return x
end

DataAPI.deletecolmetadata!(x::TestMeta) = empty!(x.col)

@testset "DataAPI" begin

@testset "defaultarray" begin

    @test DataAPI.defaultarray(Int64, 1) == Vector{Int64}
    @test DataAPI.defaultarray(Vector{Int64}, 1) == Vector{Vector{Int64}}
    @test DataAPI.defaultarray(String, 2) == Matrix{String}

end

@testset "refarray" begin

    A = Int64[]
    @test DataAPI.refarray(A) === A
    A = String[]
    @test DataAPI.refarray(A) === A

end

@testset "refvalue" begin

    A = Int64[1, 2, 3]
    R = DataAPI.refarray(A)
    @test DataAPI.refvalue(A, R[1]) === R[1]

end

@testset "levels" begin

    @test @inferred(DataAPI.levels(1:1)) ==
        @inferred(DataAPI.levels([1])) ==
        @inferred(DataAPI.levels([1, missing])) ==
        @inferred(DataAPI.levels([missing, 1])) ==
        [1]
    @test @inferred(DataAPI.levels(2:-1:1)) ==
        @inferred(DataAPI.levels([2, 1])) ==
        @inferred(DataAPI.levels(Any[2, 1])) ==
        @inferred(DataAPI.levels([2, missing, 1])) ==
        [1, 2]
    @test DataAPI.levels([missing, "a", "c", missing, "b"]) == ["a", "b", "c"]
    @test DataAPI.levels([Complex(0, 1), Complex(1, 0), missing]) ==
        [Complex(0, 1), Complex(1, 0)]
    @test typeof(DataAPI.levels([1])) ===
        typeof(DataAPI.levels([1, missing])) ===
        Vector{Int}
    @test typeof(DataAPI.levels(["a"])) ===
        typeof(DataAPI.levels(["a", missing])) ===
        Vector{String}
    @test typeof(DataAPI.levels(Real[1])) ===
        typeof(DataAPI.levels(Union{Real,Missing}[1, missing])) ===
        Vector{Real}
    @test typeof(DataAPI.levels(trues(1))) === Vector{Bool}
    @test isempty(DataAPI.levels([missing]))
    @test isempty(DataAPI.levels([]))

    levels_missing(x) = DataAPI.levels(x, skipmissing=false)
    @test @inferred(levels_missing(1:1)) ≅
        @inferred(levels_missing([1])) ≅
        [1]
    if VERSION >= v"1.6.0"
        @test @inferred(levels_missing([1, missing])) ≅
            @inferred(levels_missing([missing, 1])) ≅
            [1, missing]
    else
        @test levels_missing([1, missing]) ≅
            levels_missing([missing, 1]) ≅
            [1, missing]
    end
    @test @inferred(levels_missing(2:-1:1)) ≅
        @inferred(levels_missing([2, 1])) ≅
        [1, 2]
    @test @inferred(levels_missing(Any[2, 1])) ≅
        [1, 2]
    @test DataAPI.levels([2, missing, 1], skipmissing=false) ≅
        [1, 2, missing]
    @test DataAPI.levels([missing, "a", "c", missing, "b"], skipmissing=false) ≅
        ["a", "b", "c", missing]
    @test DataAPI.levels([Complex(0, 1), Complex(1, 0), missing], skipmissing=false) ≅
        [Complex(0, 1), Complex(1, 0), missing]
    @test typeof(DataAPI.levels([1], skipmissing=false)) === Vector{Int}
    @test typeof(DataAPI.levels([1, missing], skipmissing=false)) ===
        Vector{Union{Int, Missing}}
    @test typeof(DataAPI.levels(["a"], skipmissing=false)) === Vector{String}
    @test typeof(DataAPI.levels(["a", missing], skipmissing=false)) ===
        Vector{Union{String, Missing}}
    @test typeof(DataAPI.levels(Real[1], skipmissing=false)) === Vector{Real}
    @test typeof(DataAPI.levels(Union{Real,Missing}[1, missing], skipmissing=false)) ===
        Vector{Union{Real, Missing}}
    @test typeof(DataAPI.levels(trues(1), skipmissing=false)) === Vector{Bool}
    @test DataAPI.levels([missing], skipmissing=false) ≅ [missing]
    @test DataAPI.levels([missing], skipmissing=false) isa Vector{Missing}
    @test typeof(DataAPI.levels(Union{Int,Missing}[missing], skipmissing=false)) ===
        Vector{Union{Int,Missing}}
    @test isempty(DataAPI.levels([], skipmissing=false))
    @test typeof(DataAPI.levels(Int[], skipmissing=false)) === Vector{Int}

    # Backward compatibility test:
    # check that an array type which implements a `levels` method
    # which does not accept keyword arguments works thanks to fallbacks
    @test DataAPI.levels(TestArray([1, 2])) ==
        DataAPI.levels(TestArray([1, 2]), skipmissing=true) ==
        DataAPI.levels(TestArray([1, 2]), skipmissing=false) == [2, 1]
    @test DataAPI.levels(TestArray([1, 2])) isa Vector{Int}
    @test DataAPI.levels(TestArray([1, 2]), skipmissing=true) isa Vector{Int}
    @test DataAPI.levels(TestArray([1, 2]), skipmissing=false) isa Vector{Int}
    @test DataAPI.levels(TestArray([missing, 1, 2])) ==
        DataAPI.levels(TestArray([missing, 1, 2]), skipmissing=true) == [2, 1]
    @test DataAPI.levels(TestArray([missing, 1, 2]), skipmissing=false) ≅
        [2, 1, missing]
    @test DataAPI.levels(TestArray([missing, 1, 2])) isa Vector{Int}
    @test DataAPI.levels(TestArray([missing, 1, 2]), skipmissing=true) isa
        Vector{Int}
    @test DataAPI.levels(TestArray([missing, 1, 2]), skipmissing=false) isa
        Vector{Union{Int, Missing}}
end

@testset "Between" begin

    for x in (1, :a, "a"), y in (1, :a, "a")
        b = DataAPI.Between(x, y)
        @test b.first == (x isa Int ? x : Symbol(x))
        @test b.last == (y isa Int ? y : Symbol(y))

        @test (b .=> sum) ===
            (DataAPI.BroadcastedSelector(DataAPI.Between(x, y)) => sum)
        @test (b .=> [sum, float]) ==
            (Ref(DataAPI.BroadcastedSelector(DataAPI.Between(x, y))) .=> [sum, float])
    end

    @test_throws MethodError DataAPI.Between(true, 1)
    @test_throws MethodError DataAPI.Between(:a, 0x01)

end

@testset "All and Cols" begin

    for v in (DataAPI.All, DataAPI.Cols)
        @test v().cols == ()
        @test v(1).cols == (1,)
        @test v([1,2,3], :a).cols == ([1, 2, 3], :a)

        a = v(v())
        @test length(a.cols) == 1
        @test a.cols[1] isa v
        @test a.cols[1].cols == ()

        @test (v() .=> sum) ===
            (DataAPI.BroadcastedSelector(v()) => sum)
        @test (v(:a) .=> sum) ===
            (DataAPI.BroadcastedSelector(v(:a)) => sum)
        @test (v((1,2,3), :b) .=> sum) ===
            (DataAPI.BroadcastedSelector(v((1,2,3), :b)) => sum)
        @test (v() .=> [sum, float]) ==
            (Ref(DataAPI.BroadcastedSelector(v())) .=> [sum, float])
    end

end

@testset "unwrap" begin
    @test DataAPI.unwrap(1) === 1
    @test DataAPI.unwrap(missing) === missing
end

@testset "metadata" begin
    @test_throws ArgumentError DataAPI.metadata!(1, "a", 10, style=:none)
    @test_throws ArgumentError DataAPI.deletemetadata!(1, "a")
    @test_throws ArgumentError DataAPI.deletemetadata!(1)
    @test_throws ArgumentError DataAPI.metadata(1, "a")
    @test_throws ArgumentError DataAPI.metadata(1, "a", style=true)
    @test DataAPI.metadatakeys(1) == ()

    @test_throws ArgumentError DataAPI.colmetadata!(1, :col, "a", 10, style=:none)
    @test_throws ArgumentError DataAPI.deletecolmetadata!(1, :col, "a")
    @test_throws ArgumentError DataAPI.deletecolmetadata!(1, :col)
    @test_throws ArgumentError DataAPI.deletecolmetadata!(1)
    @test_throws ArgumentError DataAPI.colmetadata(1, :col, "a")
    @test_throws ArgumentError DataAPI.colmetadata(1, :col, "a", style=true)
    @test_throws ArgumentError DataAPI.colmetadata!(1, 1, "a", 10, style=:none)
    @test_throws ArgumentError DataAPI.colmetadata(1, 1, "a")
    @test_throws ArgumentError DataAPI.colmetadata(1, 1, "a", style=true)
    @test DataAPI.colmetadatakeys(1, :col) == ()
    @test DataAPI.colmetadatakeys(1, 1) == ()
    @test DataAPI.colmetadatakeys(1) == ()

    tm = TestMeta()
    @test isempty(DataAPI.metadatakeys(tm))
    @test DataAPI.metadata!(tm, "a", "100", style=:note) == tm
    @test collect(DataAPI.metadatakeys(tm)) == ["a"]
    @test_throws KeyError DataAPI.metadata(tm, "b")
    @test_throws KeyError DataAPI.metadata(tm, "b", style=true)
    @test DataAPI.metadata(tm, "a") == "100"
    @test DataAPI.metadata(tm, "a", style=true) == ("100", :note)
    DataAPI.deletemetadata!(tm, "a")
    @test isempty(DataAPI.metadatakeys(tm))
    @test DataAPI.metadata!(tm, "a", "100", style=:note) == tm
    DataAPI.deletemetadata!(tm)
    @test isempty(DataAPI.metadatakeys(tm))

    @test DataAPI.colmetadatakeys(tm) == ()
    @test DataAPI.colmetadatakeys(tm, :col) == ()
    @test DataAPI.colmetadata!(tm, :col, "a", "100", style=:note) == tm
    @test [k => collect(v) for  (k, v) in DataAPI.colmetadatakeys(tm)] == [:col => ["a"]]
    @test collect(DataAPI.colmetadatakeys(tm, :col)) == ["a"]
    @test_throws KeyError DataAPI.colmetadata(tm, :col, "b")
    @test_throws KeyError DataAPI.colmetadata(tm, :col, "b", style=true)
    @test_throws KeyError DataAPI.colmetadata(tm, :col2, "a")
    @test_throws KeyError DataAPI.colmetadata(tm, :col2, "a", style=true)
    @test DataAPI.colmetadata(tm, :col, "a") == "100"
    @test DataAPI.colmetadata(tm, :col, "a", style=true) == ("100", :note)
    @test DataAPI.deletecolmetadata!(tm, :col, "a")
    @test DataAPI.colmetadatakeys(tm, :col) == ()
    @test DataAPI.colmetadata!(tm, :col, "a", "100", style=:note) == tm
    @test DataAPI.deletecolmetadata!(tm, :col)
    @test DataAPI.colmetadatakeys(tm, :col) == ()
    @test DataAPI.colmetadata!(tm, :col, "a", "100", style=:note) == tm
    @test DataAPI.deletecolmetadata!(tm)
    @test DataAPI.colmetadatakeys(tm) == ()
end

end # @testset "DataAPI"
