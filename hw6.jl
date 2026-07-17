

# je to jednoliterový identifikátor
is1letter(sym::Symbol) = (s = String(sym); length(s) == 1 && isletter(s[1]))

# univerzální průchod, který plní tři množiny znaků, které se mohou vyskytovat ve výrazu
function _collect(ex, all::Set{Symbol}, callheads::Set{Symbol}, lhs::Set{Symbol})
    if ex isa Symbol
        is1letter(ex) && push!(all, ex)
        return
    
    elseif ex isa Expr
        if ex.head == :(=)
            
            if ex.args[1] isa Symbol && is1letter(ex.args[1])
                push!(lhs, ex.args[1])
            end
           
            # pravé strany procházíme dál
            for a in ex.args[2:end]
                _collect(a, all, callheads, lhs)
            end
            
            return 
        elseif ex.head == :call
            
            f = ex.args[1]
            if f isa Symbol && is1letter(f)
                push!(callheads, f)   # funkční jméno ignorujeme ve výsledku
            end
            
            # pravé strany procházíme dál
            for a in ex.args[2:end]
                _collect(a, all, callheads, lhs)
            end
            return
        end
        
        # ostatní výrazy – běžná rekurze
        for a in ex.args
            _collect(a, all, callheads, lhs)
        end
    end
end

function find_variables(ex)
    all = Set{Symbol}(); callheads = Set{Symbol}(); lhs = Set{Symbol}()
    _collect(ex, all, callheads, lhs)
    res = setdiff(union(all, lhs), callheads)
    sort!(collect(res))
end

#=
# --- Testovací příklady ---

# Příklad ze zadání 1
expr1 = :(x + 2*y^z - c*x)
println("Test 1: ", find_variables(expr1))  # Očekáváno: [:c, :x, :y, :z]

# Příklad ze zadání 2 (Přiřazení)
expr2 = :(r = x*x)
println("Test 2: ", find_variables(expr2))  # Očekáváno: [:r, :x]

# Příklad ze zadání 3 (Volání funkce)
expr3 = :(f(x))
println("Test 3: ", find_variables(expr3))  # Očekáváno: [:x]

# Složitější test
expr4 = :(A = f(b) + g(c, d) - E)
println("Test 4: ", find_variables(expr4))  # Očekáváno: [:A, :E, :b, :c, :d]

# Test s víceznakovými proměnnými (měly by být ignorovány)
expr5 = :(long_var = k + 5 * another)
println("Test 5: ", find_variables(expr5))  # Očekáváno: [:k]
=#