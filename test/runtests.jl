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

@testset "generic functions" begin

    @test length(methods(DataAPI.nondatavaluetype)) == 0
    @test length(methods(DataAPI.datavaluetype)) == 0
    @test length(methods(DataAPI.unwrap)) == 0
    @test length(methods(DataAPI.describe)) == 0

end

end # @testset "DataAPI"
