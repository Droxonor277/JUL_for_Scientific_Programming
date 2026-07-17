using Base.Threads

function thread_conv1d(x, w)
    n = length(x)
    m = length(w)
    
    # Výstup bude kratší (valid convolution without padding)
    out_len = n - m + 1
    
    # Předalokace výstupního pole
    # Používáme eltype(x), aby to fungovalo pro Float64 i jiné typy
    y = zeros(eltype(x), out_len)
    
    # Konvoluce je matematicky definovaná s otočeným jádrem.
    # Pokud bychom neotočili, počítali bychom korelaci.
    w_rev = reverse(w)
    
    # Paralelizace vnější smyčky
    Threads.@threads for i in 1:out_len
        # Výpočet skalárního součinu pro posunuté okno
        s = zero(eltype(x))
        for j in 1:m
            # x[i + j - 1] odpovídá posunu okna po signálu
            # w_rev[j] odpovídá prvkům otočeného jádra
            s += x[i + j - 1] * w_rev[j]
        end
        y[i] = s
    end
    
    return y
end