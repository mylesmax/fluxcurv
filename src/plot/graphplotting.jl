using CairoMakie, Printf, FileIO

function plotGraphs(voltages)
    fig = Figure(size= (6000, 3800), fontsize=95)
    figLayout = [fig[1,1], fig[1,2], fig[1,3], fig[2,1], fig[2,2], fig[2,3]]

    for (m, V)  ∈ enumerate(voltages)
        ax = CairoMakie.Axis(figLayout[m], title = "voltage $V")
        function r(x::Int64, y::Int64)
            e = Edge(x,y)
            α, β = rates[e]

            rate = exp(α + (β * tanh((V + args₁)/args₂)))

            rate > 0.2 ? (return rate) : (return 0)
        end

        gf = complete_digraph(n)


        edgelabeldict = Dict()
        for i in 1:n
            for j in 1:n
                i == j ? (edgelabeldict[(i, j)] = ""; continue) : nothing 
                rate = r(i,j)
                
                if rate == 0
                    rem_edge!(gf, Edge(i,j))
                else
                    edgelabeldict[(i, j)] = "r$i$j="*@sprintf("%.*g", 3, rate)
                end
            end
        end
        
        s=2
        @png begin
            background("grey10")
            sethue("pink")
            drawgraph(gf, layout=shell, vertexlabels = vertices(gf),
            edgelabels = edgelabeldict,
            edgecurvature=30*s,
            edgegaps= 20*s,
            edgelabelfontsizes=20,
            vertexlabelfontsizes=40,
            edgestrokeweights = 10,
            vertexshapesizes = (v) -> v ∈ (n̅) ? 25*s : 20*s,vertexfillcolors = (v) -> v ∈ (n̅) && colorant"lightgreen")
        end 400*s 400*s "res/pics/$m.png"

        image!(ax, rotr90(load("res/pics/$m.png")))

    end
    
    save("res/pics/composite.png", fig)
    fig
end

plotGraphs([-100 -15 -10 -8 0 10])