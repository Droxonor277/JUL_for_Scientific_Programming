using Test
using Ecosystem

@testset "Wolf" begin
 
    wolf = Wolf(10; pf=1.0)

    sheep = Animal{:Sheep}()
    world = World(Dict(1 => wolf, 2 => sheep))

    eat!(wolf, sheep, world)

    @test length(world.agents) == 1
    @test haskey(world.agents, wolf.id)
end
