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

@testset "nondatavaluetype" begin

    @test DataAPI.nondatavaluetype(Int64) == Int64
    @test DataAPI.nondatavaluetype(Union{}) == Union{}

end

@testset "datavaluetype" begin

    @test DataAPI.datavaluetype(Int64) == Int64
    @test DataAPI.datavaluetype(Union{}) == Union{}

end

@testset "unwrap" begin

    @test DataAPI.unwrap(1) == 1

end

end # @testset "DataAPI"
