using Test, DataAPI

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

@testset "Between" begin

    for x in (1, :a), y in (1, :a)
        b = DataAPI.Between(x, y)
        @test b.first == x
        @test b.last == y
    end

    @test_throws MethodError DataAPI.Between(true, 1)
    @test_throws MethodError DataAPI.Between(:a, 0x01)

end

@testset "All" begin

    @test DataAPI.All().cols == ()
    @test DataAPI.All(1).cols == (1,)
    @test DataAPI.All([1,2,3], :a).cols == ([1, 2, 3], :a)

    a = DataAPI.All(DataAPI.All())
    @test length(a.cols) == 1
    @test a.cols[1] isa DataAPI.All
    @test a.cols[1].cols == ()

end

end # @testset "DataAPI"
