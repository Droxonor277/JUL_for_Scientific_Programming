using LinearAlgebra

"""
    circlemat(n)

Return the n×n “circle” matrix A with ones on the super- and sub-diagonals
and wrap-around ones at (n,1) and (1,n).
"""
function circlemat(n::Integer)

    "Make matrix A with size n"

    [ ((i == j-1 && j > 1) || (i == n && j == 1) ||
       (i == j+1 && j < n) || (i == 1 && j == n)) ? 1 : 0
      for i in 1:n, j in 1:n ] 
end

# scalar version (original polynomial)
f(x::Number) = 1 + x + x^2 + x^3

# the polynomial evaluation
function f(x::AbstractMatrix)

    "Make the polynomial evaluation matrix A to compute  I + A + A^2 + A^3 and retur solution"

    n, m = size(x)
    @assert n == m "x must be square"

    S = zeros(eltype(x), n, n)          # accumulator
    P = Matrix{eltype(x)}(I, n, n)      # current power (starts as I)

    for _ in 0:3                         # add I, A, A^2, A^3
        S .+= P
        P = P * x
    end
    return S
end

# --- evaluate at A(10) ---
#A = circlemat(9)
#F = f(A)          # this is I + A + A^2 + A^3 at A = A(10) = 10x10 size
#display(A); #display(F)
