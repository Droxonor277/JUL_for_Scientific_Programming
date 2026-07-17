#include("C:/Code/Ecosystem.jl")
# Předpokládáme, že Ecosystem a související typy jsou dostupné (dle zadání)
#include("C:/Code/Ecosystem.jl") 


##########################
# 1) default_config(::Type)
##########################

# — konkrétní defaulty pro species z příkladu —
default_config(::Type{Grass}) = (max_size = 10,)                         # rostliny
default_config(::Type{Sheep}) = (E = 4.0,  ΔE = 0.2, pr = 0.8, pf = 0.6) # zvířata
default_config(::Type{Wolf})  = (E = 10.0, ΔE = 8.0, pr = 0.1, pf = 0.2)

#############################################
# 2) _add_agents – generátor nových agentů
#############################################

# Pomocná konstrukce vektoru správného (byť abstraktního) typu:
const _AgentVec = Vector{Agent}

# Varianta s obecným druhem (rostliny + zvířata s náhodným pohlavím)
function _add_agents(max_id::Int, count::Int, species::Type{<:Species})
    if count < 0
        throw(ArgumentError("count must be ≥ 0, got $count"))
    end
    agents = _AgentVec()
    count == 0 && return agents

    if species <: PlantSpecies
        cfg = default_config(species)
        for i in 1:count
            id = max_id + i
            p = species(id, cfg.max_size)     # náhodná velikost
            p.size = p.max_size                # plně vzrostlé
            push!(agents, p)
        end
    elseif species <: AnimalSpecies
        cfg = default_config(species)
        for i in 1:count
            id  = max_id + i
            sex = rand(instances(Sex))
            a = species(id, cfg.E, cfg.ΔE, cfg.pr, cfg.pf, sex)
            push!(agents, a)
        end
    else
        error("Unsupported species type: $(species)")
    end
    return agents
end

# Varianta pro zvířata se zadaným pohlavím
function _add_agents(max_id::Int, count::Int, species::Type{<:AnimalSpecies}, sex::Sex)
    if count < 0
        throw(ArgumentError("count must be ≥ 0, got $count"))
    end
    agents = _AgentVec()
    count == 0 && return agents

    cfg = default_config(species)
    for i in 1:count
        id = max_id + i
        a  = species(id, cfg.E, cfg.ΔE, cfg.pr, cfg.pf, sex)
        push!(agents, a)
    end
    return agents
end


#########################################################
# 3) _ecosystem(ex) – parser bloku a generátor světa
#########################################################

"""
    _ecosystem(ex::Expr) -> Expr

Zpracuje blok ve tvaru:

begin
    @add N Species [sex]
    ...
end

a vrátí kód, který vytvoří `World` se zkonstruovanými agenty.
`@add` zde není skutečný makro symbol – pouze syntaktický marker,
který rozpoznáme v AST (Expr(:macrocall, Symbol("@add"), ...)).
"""
function _ecosystem(ex::Expr)
    if ex.head !== :block
        return Expr(:block, :(throw(ArgumentError("@ecosystem: expected `begin ... end` block"))))
    end

    # hygienické unikátní názvy – NEpřepíšou proměnné uživatele
    _as  = gensym(:agents)
    _mid = gensym(:max_id)

    out = Expr(:block)
    push!(out.args, :($_as = $_AgentVec()))
    push!(out.args, :($_mid = 0))

    _clean_args(args::Vector) = [a for (i,a) in enumerate(args) if i ≥ 3 && !(a isa LineNumberNode)]

    processed = 0
    for st in ex.args
        if st isa LineNumberNode
            continue
        end
        if !(st isa Expr && st.head === :macrocall && st.args[1] === Symbol("@add"))
            return Expr(:block, :(throw(ArgumentError("@ecosystem: only `@add` statements are allowed"))))
        end

        addargs = _clean_args(st.args)
        if length(addargs) < 2
            return Expr(:block, :(throw(ArgumentError("@add: missing arguments (need: count, species[, sex])"))))
        elseif length(addargs) > 3
            return Expr(:block, :(throw(ArgumentError("@add: too many arguments"))))
        end

        n_ex       = addargs[1]
        species_ex = addargs[2]
        if length(addargs) == 3
            sex_ex = addargs[3]
            push!(out.args, :(append!($_as, _add_agents($_mid, $n_ex, $(species_ex), $(sex_ex)))))
        else
            push!(out.args, :(append!($_as, _add_agents($_mid, $n_ex, $(species_ex)))))
        end
        push!(out.args, :($_mid += $n_ex))
        processed += 1
    end

    if processed == 0
        return Expr(:block, :(throw(ArgumentError("@ecosystem: empty block"))))
    end

    push!(out.args, :(World(collect($_as))))
    return out
end



############################
# Uživatelské makro @ecosystem
############################

"""
    @ecosystem begin
        @add N Sheep female
        @add M Grass
        @add K Wolf
    end

Vytvoří a vrátí `World` s příslušnými agenty.
"""
macro ecosystem(ex)
    esc(_ecosystem(ex))
end
