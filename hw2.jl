



abstract type Agent end
abstract type Animal <: Agent end
abstract type Plant <: Agent end

mutable struct Grass <: Plant
    const id::Int
    size::Int
    const max_size::Int
end

mutable struct Sheep <: Animal
    const id::Int
    energy::Float64
    const Δenergy::Float64
    const reprprob::Float64
    const foodprob::Float64
end


mutable struct Wolf <: Animal
    const id::Int
    energy::Float64
    const Δenergy::Float64
    const reprprob::Float64
    const foodprob::Float64
end


struct World
    agents::Vector{Agent}
end

# Pro zvířata vždy 1
agent_count(a::Animal) = 1.0

# Pro rostliny velikost / max velikost
agent_count(p::Plant) = p.size / p.max_size

# agent_count pro vektor agentů
agent_count(agents::Vector{<:Agent}) = sum(agent_count(a) for a in agents)

# agent_count pro svět
function agent_count(world::World)
    
    """
        průběžně sčítáme dle skutečně přítomných agentů a vracíme počet
    """
    
    totals = Dict{Symbol, Real}()
    for a in world.agents
        s = nameof(typeof(a))
        totals[s] = get(totals, s, 0) + agent_count(a)
    end

    # vynutíme pořadí pro výpis
    order = [:Wolf, :Grass, :Sheep]
    result = Dict{Symbol, Real}()

    for s in order
        if haskey(totals, s)
            result[s] = totals[s]
        end
    end

    # případné další typy (pokud existují) přidej nakonec
    for (s, v) in totals
        if !(s in order)
            result[s] = v
        end
    end
    return result
end





"""
# === Testy podle zadání ===
grass1 = Grass(1,5,5)
grass2 = Grass(2,1,5)
sheep = Sheep(3,10.0,5.0,1.0,1.0)
wolf = Wolf(4,20.0,10.0,1.0,1.0)

println(agent_count(grass1))             # 1.0
println(agent_count([grass1, grass2]))   # 1.2
world = World([grass1, grass2, sheep, wolf])
agent_count(world)             # Dict(:Grass => 1.2, :Sheep => 1.0, :Wolf => 1.0)
"""