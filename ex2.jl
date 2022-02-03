#!/usr/bin/julia

# Autor: Krzysztof Tałałaj
println("loading JuMP")
using JuMP
println("loading GLPK solver")
using GLPK
using JSON
using LinearAlgebra

data = JSON.parsefile("ex2.json")
model = Model(GLPK.Optimizer)

size = data["vertices"]
start = data["start"]
finish = data["finish"]
timeout = data["timeout"]

time = zeros(Int8, (size, size))
cost = zeros(Int8, (size, size))

for road in keys(data["roads"])
    time[parse(Int, road[1]), parse(Int, road[end])] = data["roads"][road]["t"]
    cost[parse(Int, road[1]), parse(Int, road[end])] = data["roads"][road]["c"]
end

# Zmienne przepływu w grafie
@variable(model, 0 <= x[1:size, 1:size] <= 1)

# Brak przejścia skutkuje brakiem przepływu
function hasKey(x::Int, y::Int)
    try
        data["roads"]["$(x) -> $(y)"]
        return true
    catch err return false end
end
@constraint(model, [i = 1:size, j = 1:size; !hasKey(i, j)], x[i, j] == 0)

# Flow w punkcie startowym jest równy 1
@constraint(model, sum(x[start, :]) - sum(x[:, start]) == 1)

# Flow w punkcie końcowym jest równy -1
@constraint(model, sum(x[finish, :]) - sum(x[:, finish]) == -1)

# Flow w pozostałych punktach jest równy 0
@constraint(model, [i = 1:size; i != start && i != finish], sum(x[i, :]) == sum(x[:, i]))

# Ścieżka nie może przekraczać maksymalnego czasu
@constraint(model, LinearAlgebra.dot(time, x) <= timeout)

# Minimalizujemy koszt ścieżki
@objective(model, Min, LinearAlgebra.dot(cost, x))

optimize!(model)

println("\n\nMODEL:\n", model)
println("\nRESULTS:")
println(solution_summary(model))
for i = 1:size, j = 1:size
    if (value(x[i, j]) == 1.0)
        println(i, " -> ", j)
    end
end
println("time: ", LinearAlgebra.dot(time, value.(x)))
println(value.(x))

# 300 -> c: 37
# 150 -> c: 258