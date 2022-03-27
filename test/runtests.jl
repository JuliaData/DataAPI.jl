using Test, DataAPI

const ≅ = isequal

# For `levels` tests
struct TestArray{T} <: AbstractVector{T}
    x::Vector{T}
end
Base.size(x::TestArray) = size(x.x)
Base.getindex(x::TestArray, i) = x.x[i]
DataAPI.levels(x::TestArray) = reverse(DataAPI.levels(x.x))

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

end # @testset "DataAPI"
