#!/usr/bin/julia

# Autor: Krzysztof Tałałaj
println("loading JuMP")
using JuMP
println("loading GLPK solver")
using GLPK
using JSON
using LinearAlgebra

data = JSON.parsefile("ex4.json")
model = Model(GLPK.Optimizer)

m = data["length"]
n = data["height"]
k = data["distance"]
containers = data["containers"]
println(containers)

# Rozmieszczenie kamer x i oświetlenie danego pola y
@variables(model,begin
        x[i in 1:m, j in 1:n], Bin
        y[i in 1:m,j in 1:n] end)

# Kamery nie mogą być na kontenerach
@constraint(model, [i in 1:m, j in 1:n; ([i, j] in values(containers))], x[i, j] == 0)

# Kontenery muszą być oświetlone
@constraint(model, [i in 1:m, j in 1:n; ([i, j] in values(containers))], y[i, j] >= 1)

# Oświetlenie danego pola jest liczbą kamer go pilnujących
@constraint(model, [i in 1:m, j in 1:n; ([i, j] in values(containers))],
    y[i, j] == sum(x[a, j] for a in max(i-k,1):min(i+k,m))
            + sum(x[i, b] for b in max(j-k,1):min(j+k,n)) - x[i, j])

# Minimalizujemy liczbę kamer
@objective(model, Min, sum(x[i, j] for i in 1:m, j in 1:n))

optimize!(model)

println("\n\nMODEL:\n", model)
println("\nRESULTS:")
println(solution_summary(model))
for i in 1:m, j in 1:n
    if (value(x[i, j]) > 0)
        println("[", i, ", ", j, "]")
    end
end

# [2, 1], [2, 3], [3, 2], [4, 3]
# _ x _ o _
# _ o x _ _
# _ x _ x _
# _ _ _ _ _

# +[5, 4]
# _ x _ _ _
# _ o x _ _
# _ x _ x o
# _ _ _ _ x