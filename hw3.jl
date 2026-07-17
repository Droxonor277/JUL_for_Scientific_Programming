abstract type Species end

abstract type PlantSpecies <: Species end
abstract type Grass <: PlantSpecies end

abstract type AnimalSpecies <: Species end
abstract type Sheep <: AnimalSpecies end
abstract type Wolf <: AnimalSpecies end

abstract type Agent{S<:Species} end

# instead of Symbols we can use an Enum for the sex field
# using an Enum here makes things easier to extend in case you
# need more than just binary sexes and is also more explicit than
# just a boolean
@enum Sex female male

##########  World  #############################################################

mutable struct World{A<:Agent}
    agents::Dict{Int,A}
    max_id::Int
end

function World(agents::Vector{<:Agent})
    max_id = maximum(a.id for a in agents)
    World(Dict(a.id=>a for a in agents), max_id)
end

# optional: overload Base.show
function Base.show(io::IO, w::World)
    println(io, typeof(w))
    for (_,a) in w.agents
        println(io,"  $a")
    end
end


##########  Animals  ###########################################################

mutable struct Animal{A<:AnimalSpecies} <: Agent{A}
    const id::Int
    energy::Float64
    const Δenergy::Float64
    const reprprob::Float64
    const foodprob::Float64
    const sex::Sex
end

function (A::Type{<:AnimalSpecies})(id::Int,E::T,ΔE::T,pr::T,pf::T,s::Sex) where T
    Animal{A}(id,E,ΔE,pr,pf,s)
end

# get the per species defaults back
randsex() = rand(instances(Sex))
Sheep(id; E=4.0, ΔE=0.2, pr=0.8, pf=0.6, s=randsex()) = Sheep(id, E, ΔE, pr, pf, s)
Wolf(id; E=10.0, ΔE=8.0, pr=0.1, pf=0.2, s=randsex()) = Wolf(id, E, ΔE, pr, pf, s)


function Base.show(io::IO, a::Animal{A}) where {A<:AnimalSpecies}
    e = a.energy
    d = a.Δenergy
    pr = a.reprprob
    pf = a.foodprob
    s = a.sex == female ? "♀" : "♂"
    print(io, "$A$s #$(a.id) E=$e ΔE=$d pr=$pr pf=$pf")
end

# note that for new species we will only have to overload `show` on the
# abstract species/sex types like below!
Base.show(io::IO, ::Type{Sheep}) = print(io,"🐑")
Base.show(io::IO, ::Type{Wolf}) = print(io,"🐺")


##########  Plants  #############################################################

mutable struct Plant{P<:PlantSpecies} <: Agent{P}
    const id::Int
    size::Int
    const max_size::Int
end

# constructor for all Plant{<:PlantSpecies} callable as PlantSpecies(...)
(A::Type{<:PlantSpecies})(id, s, m) = Plant{A}(id,s,m)
(A::Type{<:PlantSpecies})(id, m) = (A::Type{<:PlantSpecies})(id,rand(1:m),m)

# default specific for Grass
Grass(id; max_size=10) = Grass(id, rand(1:max_size), max_size)

function Base.show(io::IO, p::Plant{P}) where P
    x = p.size/p.max_size * 100
    print(io,"$P  #$(p.id) $(round(Int,x))% grown")
end

Base.show(io::IO, ::Type{Grass}) = print(io,"🌿")

function eat!(sheep::Animal{Sheep}, grass::Plant{Grass}, w::World)
    sheep.energy += grass.size * sheep.Δenergy
    grass.size = 0
end

function reproduce!(a::Animal{A}, w::World) where A
    m = find_mate(a,w)
    if !isnothing(m)
        a.energy = a.energy / 2
        vals = [getproperty(a,n) for n in fieldnames(Animal) if n ∉ [:id, :sex]]
        new_id = w.max_id + 1
        ŝ = Animal{A}(new_id, vals..., randsex())
        w.agents[ŝ.id] = ŝ
        w.max_id = new_id
    end
end



##########  Counting agents  ####################################################

agent_count(p::Plant) = p.size / p.max_size
agent_count(::Animal) = 1
agent_count(as::Vector{<:Agent}) = sum(agent_count,as)

function agent_count(w::World)
    function op(d::Dict,a::Agent{S}) where S<:Species
        n = nameof(S)
        d[n] = haskey(d,n) ? d[n]+agent_count(a) : agent_count(a)
        return d
    end
    reduce(op, w.agents |> values, init=Dict{Symbol,Float64}())
end


##########  Food relationships  ################################################

# Default: nikdo nikoho nejí
eats(::Animal, ::Agent) = false

# Konkrétní vztahy
eats(::Animal{Sheep}, ::Plant{Grass}) = true
eats(::Animal{Wolf},  ::Animal{Sheep}) = true

function find_food(a::Animal, w::World)
    candidates = []  

    # Projdeme všechny agenty ve světě
    for ag in values(w.agents)
        if eats(a, ag)
            push!(candidates, ag)  
        end
    end

    # Pokud žádné jídlo nenašel
    if isempty(candidates)
        return nothing
    else
        # jinak náhodně vyber jednoho kandidáta
        return rand(candidates)
    end
end

##### ——— Callbacks & Closures ——— #####

function every_nth(f::Function, n::Int)
    @assert n > 0 "n musí být kladné"
    count = 0
    return function (args...; kwargs...)
        count += 1
        if count % n == 0
            return f(args...; kwargs...)
        else
            return nothing
        end
    end
end



#=
# Food
sheep = Sheep(1, pf=1.0)
world = World([Grass(2), sheep])
print(find_food(sheep, world) isa Plant{Grass})  # → true
=#

#=
# every_nth
w = World([Sheep(1), Grass(2), Wolf(3)])
logcb = every_nth(w->(@info agent_count(w)), 3)

logcb(w)  # 1. volání → nic
logcb(w)  # 2. volání → nic
logcb(w)  # 3. volání → zavolá @info agent_count(w)
=#