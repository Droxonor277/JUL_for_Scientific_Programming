using Test

struct ODEProblem{F,T<:Tuple{Number,Number},U<:AbstractVector,P<:AbstractVector}
    f::F
    tspan::T
    u0::U
    θ::P
end

abstract type ODESolver end

struct Euler{T} <: ODESolver
    dt::T
end

function (solver::Euler)(prob::ODEProblem, u, t)
    f, θ, dt = prob.f, prob.θ, solver.dt
    (u + dt * f(u, θ), t + dt)
end

function solve(prob::ODEProblem, solver::ODESolver)
    t = prob.tspan[1]; u = prob.u0
    us = [u]; ts = [t]
    while t < prob.tspan[2]
        (u, t) = solver(prob, u, t)
        push!(us, u)
        push!(ts, t)
    end
    ts, reduce(hcat, us)
end


struct RK2{T} <: ODESolver
    dt::T
end

function (solver::RK2)(prob::ODEProblem, u, t)
    f, θ, dt = prob.f, prob.θ, solver.dt

    k1 = f(u, θ)              # slope at current point
    û  = u + dt * k1          # Euler guess
    k2 = f(û, θ)              # slope at the guess

    u_next = u + dt * (k1 + k2) / 2
    (u_next, t + dt)
end

