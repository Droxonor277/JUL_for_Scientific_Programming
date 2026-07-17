using Test
using Ecosystem

@testset "Sheep" begin
    
    sheep = Sheep(1; pf=1.0)

    grass = Plant{:Grass}(size = 1)
    world = World(Dict(1 => sheep, 2 => grass))
    
    eat!(sheep, grass, world)

    @test grass.size == 0
end
