using DelimitedFiles
using Statistics
using Plots

include("exact.jl")

A, B, C = indexGrid(100, 100, 100)

Lx = 5
Ly = 4
Lz = 3

N = 10

t = 0

F = modeFrequency.(A, B, C, Lx, Ly, Lz)

idx = sortperm(F[:])

f = F[idx[2:(N + 1)]]

for n in 1:length(f)
    writedlm("frequencies/f_$n.csv", f[n])
end

a = A[idx[2:(N + 1)]]
b = B[idx[2:(N + 1)]]
c = C[idx[2:(N + 1)]]

norms = zeros(N)

for d in 0:(N - 1)

    linedata = readdlm("export/data_$d.csv", ',')

    femSolution = real.(
        (Float64.(linedata[2:end, 1]) .+ im * Float64.(linedata[2:end, 2])) *
        exp(im * 2π * f[d + 1] * t)
    )

    x = Float64.(linedata[2:end, 3])
    y = Float64.(linedata[2:end, 4])
    z = Float64.(linedata[2:end, 5])

    exactSolution = mode.(
        x .+ 0.5 * Lx, y .+ 0.5 * Ly, z .+ 0.5 * Lz,
        a[d + 1], b[d + 1], c[d + 1],
        Lx, Ly, Lz
    ) * cospi(2 * f[d + 1] * t)

    me, ie = findmax(exactSolution)

    femSolution = femSolution * me / femSolution[ie]

    errorField = femSolution - exactSolution

    norms[d + 1] = sqrt(sum(abs2.(errorField)))

    dBError = 20.0 * log10.(abs.(femSolution ./ exactSolution))

    writedlm(
        "error/error_$d.csv",
        ["error_field" "dB_error_field" "x" "y" "z"; [errorField dBError x y z]],
        ','
    )

end

bar(
    1:N,
    norms,
    legend=false,
    framestyle=:box,
    xlabel="Mode frequency [Hz]",
    ylabel="Norm of the Error Field [Pa]",
    yscale=:log10,
    xticks=(1:N, round.(f, digits=3))
)
