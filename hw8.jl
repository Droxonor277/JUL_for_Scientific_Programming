using Test

mutable struct TrackedReal{T<:Real}
    data::T
    grad::Union{Nothing,T}
    children::Dict
    name::String
end

# Helper na vytvoreni tracked cisla
track(x::Real, name="") = TrackedReal(x, nothing, Dict(), name)

function Base.show(io::IO, x::TrackedReal)
    # jen jednoduchy vypis
    tag = isempty(x.name) ? "(tracked)" : "(tracked $(x.name))"
    print(io, "$(x.data) $tag")
end

function accum!(x::TrackedReal)
    if isnothing(x.grad)
        # scitani gradientu od deti
        s = 0.0
        for (child, weight) in x.children
            s += weight * accum!(child)
        end
        x.grad = s
    end
    return x.grad
end

# --- Operatory ---

function Base.:*(a::TrackedReal, b::TrackedReal)
    res = track(a.data * b.data, "*")
    a.children[res] = b.data
    b.children[res] = a.data
    res
end

function Base.:+(a::TrackedReal{T}, b::TrackedReal{T}) where T
    res = track(a.data + b.data, "+")
    a.children[res] = one(T)
    b.children[res] = one(T)
    res
end

function Base.sin(x::TrackedReal)
    res = track(sin(x.data), "sin")
    x.children[res] = cos(x.data)
    res
end

# Deleni
function Base.:/(a::TrackedReal, b::TrackedReal)
    res = track(a.data / b.data, "/")
    a.children[res] = 1 / b.data
    b.children[res] = -a.data / (b.data^2)
    return res
end

function Base.:/(a::TrackedReal, b::Real)
    res = track(a.data / b, "/")
    a.children[res] = 1 / b
    return res
end

function Base.:/(a::Real, b::TrackedReal)
    res = track(a / b.data, "/")
    b.children[res] = -a / (b.data^2)
    return res
end

# Scitani s konstantou
function Base.:+(a::TrackedReal, b::Real)
    res = track(a.data + b, "+")
    a.children[res] = 1.0
    return res
end

function Base.:+(a::Real, b::TrackedReal)
    res = track(a + b.data, "+")
    b.children[res] = 1.0
    return res
end

# --- Gradient a main logika ---

function gradient(f, args::Real...)
    vars = track.(args)
    y = f(vars...)
    y.grad = 1.0
    accum!.(vars)
end


#=
# Babylon
babysqrt(x, t=(1+x)/2, n=10) = n==0 ? t : babysqrt(x, (t+x/t)/2, n-1)

# --- Testy ---

@testset "Domaci ukol AD" begin
    
    @testset "Zakladni operace (+, /)" begin
        # scitani konstanty
        g, = gradient(x -> x + 5.0, 10.0)
        @test g ≈ 1.0
        
        g2, = gradient(x -> 5.0 + x, 10.0)
        @test g2 ≈ 1.0

        # deleni tracked/tracked
        x, y = 6.0, 3.0
        gx, gy = gradient((a, b) -> a / b, x, y)
        @test gx ≈ 1.0 / y
        @test gy ≈ -x / (y^2)

        # deleni s konstantou
        g3, = gradient(a -> a / 2.0, 10.0)
        @test g3 ≈ 0.5

        c = 10.0
        val = 2.0
        g4, = gradient(a -> c / a, val)
        @test g4 ≈ -c / (val^2)
    end

    @testset "Babylon sqrt" begin
        val = 2.0
        res_grad, = gradient(babysqrt, val)
        analytic = 1 / (2 * sqrt(val))
        
        println("Vysledek: $res_grad, Ocekavano: $analytic")
        @test res_grad ≈ analytic atol=1e-8
    end

end


using Test

# Pokud máš definice v jiném souboru, odkomentuj následující řádek:
# include("hw.jl")

@testset "Homework 08: Reverse AD Rules" begin

    @testset "1. Sčítání s konstantami (Addition with constants)" begin
        # Funkce: f(x) = x + 5
        # Derivace: f'(x) = 1
        val, = gradient(x -> x + 5.0, 10.0)
        @test val ≈ 1.0
        
        # Funkce: f(x) = 5 + x
        # Derivace: f'(x) = 1
        val, = gradient(x -> 5.0 + x, 10.0)
        @test val ≈ 1.0
    end

    @testset "2. Dělení (Division)" begin
        # A) Tracked / Tracked
        # Funkce: f(x, y) = x / y
        # Derivace podle x: 1/y
        # Derivace podle y: -x/y^2
        x_val, y_val = 6.0, 3.0
        gx, gy = gradient((x, y) -> x / y, x_val, y_val)
        
        @test gx ≈ 1.0 / y_val          # 1/3
        @test gy ≈ -x_val / (y_val^2)   # -6/9 = -2/3

        # B) Tracked / Constant
        # Funkce: f(x) = x / 2
        # Derivace: 1/2
        val, = gradient(x -> x / 2.0, 10.0)
        @test val ≈ 0.5

        # C) Constant / Tracked
        # Funkce: f(x) = 10 / x
        # Derivace: -10 / x^2
        c = 10.0
        x_in = 2.0
        val, = gradient(x -> c / x, x_in)
        @test val ≈ -c / (x_in^2)       # -10 / 4 = -2.5
    end

    @testset "3. Komplexní test (Babylonská odmocnina)" begin
        # Ověření podle zadání
        # Derivace sqrt(x) je 1 / (2 * sqrt(x))
        
        target_x = 2.0
        computed_grad, = gradient(babysqrt, target_x)
        analytical_grad = 1 / (2 * sqrt(target_x))

        println("Babysqrt grad: $computed_grad vs Analytical: $analytical_grad")
        
        # Používáme přibližnou rovnost (≈), protože iterativní 
        # metoda nebude mít přesnost na poslední bit.
        @test computed_grad ≈ analytical_grad atol=1e-8
    end

end

=#