#!/usr/bin/julia

# Autor: Krzysztof Tałałaj
println("loading JuMP")
using JuMP
println("loading GLPK solver")
using GLPK
using JSON

data = JSON.parsefile("ex3.json")
model = Model(GLPK.Optimizer)

districts = keys(data["districts"])
shifts = keys(data["shifts"])

# Wysłana liczba radiowozów w danej dzielnicy i zmianie musi mieścić się między granicami
getMin(shift::String, district::String) = data["orders"]["$(shift), $(district)"]["min"]
getMax(shift::String, district::String) = data["orders"]["$(shift), $(district)"]["max"]
@variable(model, getMin(shift, district) <= x[shift in shifts, district in districts] <= getMax(shift, district))

# Ograniczenie na minimum dla danej zmiany
@constraint(model, [shift in shifts], sum(x[shift, :]) >= data["shifts"][shift])

# Ograniczenie na minimum dla danej dzielnicy
@constraint(model, [district in districts], sum(x[:, district]) >= data["districts"][district])

# Minimalizujemy liczbę radiowozów
@objective(model, Min, sum(x[shitf, district] for shitf in shifts, district in districts))

optimize!(model)

println("\n\nMODEL:\n", model)
println("\nRESULTS:")
println(solution_summary(model))
for shitf in shifts, district in districts
    println("(", shitf, ", ", district, "): ", value(x[shitf, district]))
end