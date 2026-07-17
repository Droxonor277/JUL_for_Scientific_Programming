using LinearAlgebra
using Printf
using BenchmarkTools  
#using Plots           


function _polynomial(a, x)
    accumulator = a[end] * one(x)
    for i in length(a)-1:-1:1
        accumulator = accumulator * x + a[i]
    end
    accumulator  
end

# definition of polynom
struct Polynom{C}
    coefficients::C
    Polynom(coefficients::CC) where CC = coefficients[end] == 0 ? throw(ArgumentError("Coefficient of the highest exponent cannot be zero.")) : new{CC}(coefficients)
end

# based on https://github.com/JuliaMath/Polynomials.jl
function from_roots(roots::AbstractVector{T}; aₙ = one(T)) where {T}
    n = length(roots)
    c = zeros(T, n+1)
    c[1] = one(T)
    for j = 1:n
        for i = j:-1:1
            c[i+1] = c[i+1]-roots[j]*c[i]
        end
    end
    return Polynom(aₙ.*reverse(c))
end

(p::Polynom)(x) = _polynomial(p.coefficients, x)
degree(p::Polynom) = length(p.coefficients) - 1

function _derivativeof(p::Polynom)
    n = degree(p)
    n > 1 ? Polynom([(i - 1)*p.coefficients[i] for i in 2:n+1]) : error("Low degree of a polynomial.")
end
LinearAlgebra.adjoint(p::Polynom) = _derivativeof(p)

function Base.show(io::IO, p::Polynom)
    n = degree(p)
    a = reverse(p.coefficients)
    for (i, c) in enumerate(a[1:end-1])
        if (c != 0)
            c < 0 && print(io, " - ")
            c > 0 && i > 1 && print(io, " + ")
            print(io, "$(abs(c))x^$(n - i + 1)")
        end
    end
    c = a[end]
    c > 0 && print(io, " + $(c)")
    c < 0 && print(io, " - $(abs(c))")
end

# default optimization parameters
# Tyto globální proměnné už nebudou mít vliv na `find_root`
# atol = 1e-12
# maxiter = 100
# stepsize = 0.95

# definition of optimization methods
abstract type RootFindingMethod end
struct Newton <: RootFindingMethod end
struct Secant <: RootFindingMethod end
struct Bisection <: RootFindingMethod end

init!(::Bisection, p, a, b) = sign(p(a)) != sign(p(b)) ? (a, b) : throw(ArgumentError("Signs at both ends are the same."))
init!(::RootFindingMethod, p, a, b) = (a, b)

@inline function step!(::Newton, poly::Polynom, xᵢ::Tuple{T,T}, step_size::T) where {T<:Real}
    x, x̃ = xᵢ
    dp = poly'                    # derivative polynomial (same coefficient type)
    return (x̃, x̃ - step_size * poly(x̃) / dp(x̃)) :: Tuple{T,T}
end

@inline function step!(::Secant, poly::Polynom, xᵢ::Tuple{T,T}, step_size::T) where {T<:Real}
    x, x̃ = xᵢ
    dpx = (poly(x) - poly(x̃)) / (x - x̃)
    return (x̃, x̃ - step_size * poly(x̃) / dpx) :: Tuple{T,T}
end

@inline function step!(::Bisection, poly::Polynom, xᵢ::Tuple{T,T}, step_size::T) where {T<:Real}
    x, x̃ = xᵢ
    midpoint = (x + x̃) / T(2)
    if sign(poly(midpoint)) == sign(poly(x̃))
        x̃ = midpoint
    else
        x  = midpoint
    end
    return (x, x̃) :: Tuple{T,T}
end

# --- init! stays the same, but it now feeds a Tuple{T,T} into step! ---
init!(::Bisection, poly::Polynom, a, b) =
    sign(poly(a)) != sign(poly(b)) ? (a, b) :
    throw(ArgumentError("Signs at both ends are the same."))
init!(::RootFindingMethod, poly::Polynom, a, b) = (a, b)

# --- find_root: parametric on T, keep all scalars in T, avoid widening ---

function find_root(poly::Polynom,
                   rfm::R = Newton(),
                   a::T = T(-5),
                   b::T = T(5),
                   max_iter::Int = 100,
                   step_size::T = T(0.95),
                   tol::T = T(1e-12)) where {R<:RootFindingMethod, T<:Real}

    x, x̃ = init!(rfm, poly, a, b)           # Tuple{T,T}
    @inbounds for _ in 1:max_iter
        x, x̃ = step!(rfm, poly, (x, x̃), step_size)  # stays Tuple{T,T}
        val = poly(x̃) :: T
        if abs(val) < tol
            return x̃
        end
    end
    return x̃
end

#=
# =================================================================
# ČÁST 1: POVINNÝ ÚKOL (Benchmark)
# =================================================================
println("--- 🚀 Ověření povinného úkolu (Benchmark) ---")

# Polynom ze zadání
p = from_roots([-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0])

# Parametry ze zadání
atol_hw = 1e-12
maxiter_hw = 100
stepsize_hw = 0.95

# Cíl: < 50µs
println("Bisection (cíl < 50µs):")
@btime find_root($p, $(Bisection()), -5.0, 5.0, $maxiter_hw, $stepsize_hw, $atol_hw)

println("Newton (cíl < 50µs):")
@btime find_root($p, $(Newton()), -5.0, 5.0, $maxiter_hw, $stepsize_hw, $atol_hw)

println("Secant (cíl < 50µs):")
@btime find_root($p, $(Secant()), -5.0, 5.0, $maxiter_hw, $stepsize_hw, $atol_hw)

# Ověření typové stability (můžete si odkomentovat a spustit v REPL)
println("\n--- Kontrola typové stability ---")
@code_warntype find_root(p, Bisection(), -5.0, 5.0, maxiter_hw, stepsize_hw, atol_hw)
@code_warntype find_root(p, Newton(), -5.0, 5.0, maxiter_hw, stepsize_hw, atol_hw)
@code_warntype find_root(p, Secant(), -5.0, 5.0, maxiter_hw, stepsize_hw, atol_hw)
=#
#=
# =================================================================
# ČÁST 2: DOBROVOLNÝ ÚKOL (Vizualizace)
# =================================================================
println("\n--- 📈 Generování grafů pro dobrovolný úkol ---")

"""
Nová funkce pro DOBROVOLNÝ úkol.
Je téměř stejná jako `find_root`, ale vrací pole s historií aproximací.
Toto je záměrně "pomalá" verze, protože alokuje paměť v každé iteraci.
"""
function find_root_with_history(p::Polynom, rfm::RootFindingMethod, a=-5.0, b=5.0, max_iter=100, step_size=0.95, tol=1e-12)
    x, x̃ = init!(rfm, p, a, b)
    history = [x̃] # Uložíme startovní bod
    
    for i in 1:max_iter
        x, x̃ = step!(rfm, p, (x, x̃), step_size)
        push!(history, x̃) # Sbíráme historii
        
        val = p(x̃)
        abs(val) < tol && return x̃, history
    end
    return x̃, history
end

"""
Pomocná funkce, která vygeneruje jeden graf pro jednu metodu.
"""
function plot_convergence(p::Polynom, rfm::RootFindingMethod, a, b, title_str, color)
    # 1. Vykreslíme polynom
    xs = -5:0.01:5
    ys = p.(xs)
    plt = plot(xs, ys, label="p(x)", title=title_str, legend=:topleft, color=:black)
    hline!([0.0], color=:black, ls=:dash, label=nothing)

    # 2. Získáme historii iterací
    # Omezíme počet iterací na 20, aby byl graf přehledný
    root, history = find_root_with_history(p, rfm, a, b, 20, stepsize_hw, atol_hw)
    
    # 3. Vykreslíme kroky
    yl = ylims(plt) # Získáme rozsah osy Y
    
    # Tečky na ose X
    scatter!(history, zeros(length(history)), 
             label="Aproximace ", 
             color=color, markersize=4)
    
    # Svislé tečkované čáry
    for x_k in history
        plot!([x_k, x_k], [yl[1], yl[2]], 
              label=nothing, 
              color=color, 
              ls=:dot, 
              alpha=0.6)
    end
    
    return plt
end

# Vygenerujeme 3 samostatné grafy
plt_bisection = plot_convergence(p, Bisection(), 2.1, 4.0, "Bisection (hledá kořen x=3)", :red)
plt_newton = plot_convergence(p, Newton(), 0.6, 1.4, "Newton (hledá kořen x=1)", :green)
plt_secant = plot_convergence(p, Secant(), -2.5, -1.5, "Secant (hledá kořen x=-2)", :blue)

# Spojíme je do jednoho a uložíme
final_plot = plot(plt_bisection, plt_newton, plt_secant, layout=(3, 1), size=(800, 1200))
savefig(final_plot, "homework5_plot.png")

println("Grafy uloženy do souboru 'homework5_plot.png'.")
println("--- Hotovo ---")

=#