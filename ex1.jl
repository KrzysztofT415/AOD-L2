#!/usr/bin/julia

# Autor: Krzysztof Tałałaj
println("loading JuMP")
using JuMP
println("loading GLPK solver")
using GLPK
using JSON

data = JSON.parsefile("ex1.json")
model = Model(GLPK.Optimizer)

suppliers = keys(data["supply"])
clients = keys(data["demand"])

# Zakupiona ilość paliwa nie może być ujemna
@variable(model, x[clients, suppliers] >= 0)

# Samoloty potrzebują dokładną ilość paliwa
@constraint(model, [client in clients], sum(x[client, :]) == data["demand"][client])

# Dostawcy paliwa mają limit sprzedaży
@constraint(model, [supplier in suppliers], sum(x[:, supplier]) <= data["supply"][supplier])

# Minimalizujemy koszt dostarczenia paliwa
price(client::String, supplier::String) = data["prices"]["$(client) <= $(supplier)"]
@objective(model, Min, sum(price(client, supplier) * x[client, supplier] for client in clients, supplier in suppliers))

optimize!(model)

println("\n\nMODEL:\n", model)
println("\nRESULTS:")
println(solution_summary(model))
for client in clients, supplier in suppliers
    if (value(x[client, supplier]) > 0.0)
        println(client, " <- ", supplier, ": ", value(x[client, supplier]))
    end
end