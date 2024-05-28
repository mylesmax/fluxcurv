using CairoMakie, Printf, FileIO

function plotGraphs(voltages, out, n, n̅)
    rates = Dict{Graphs.SimpleGraphs.SimpleEdge, Tuple{Float64, Float64,Float64}}(Edge(i::Int64, j::Int64) => (0,0,0) for i in 1:n, j in 1:n if i != j for idx in (2 * (i - 1) * (n - 1) + 2 * (j - 1) + 1):(2 * (i - 1) * (n - 1) + 2 * (j - 1) + 2))
    params = vec(readdlm(out))

    idx::Int = 1
    for e in sort(collect(keys(rates)))::Vector{Graphs.SimpleGraphs.SimpleEdge}
        rates[e] = (params[idx], params[idx + 1], params[idx + 2])::Tuple{Float64,Float64,Float64}
        idx += 3
    end
    
    
    fig = Figure(size= (6000, 3800), fontsize=95)
    figLayout = [fig[1,1], fig[1,2], fig[1,3], fig[2,1], fig[2,2], fig[2,3]]
    loss = consolidatedLoss(params)
    titleLayout = GridLayout(fig[0,1:3])
    Label(titleLayout[1, 1], "loss = $loss", fontsize=100, font="TeX Gyre Heros Bold Makie")
    rowgap!(titleLayout, 0)

    for (m, V)  ∈ enumerate(voltages)
        ax = CairoMakie.Axis(figLayout[m], title = "voltage $V")
        function r(x::Int64, y::Int64)
            e = Edge(x,y)
            α, β, γ = rates[e]
    
            rate::Float64 = min(abs(γ), (max(0, α + β*V)))
    
            return rate
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
        
        s=2 #scaling factor

        if !isdir("res/pics/n=$n-$loss")
            mkpath("res/pics/n=$n-$loss")
        end

        @png begin
            background("grey10")
            sethue("pink")
            drawgraph(gf, layout=shell, vertexlabels = vertices(gf),
            edgelabels = edgelabeldict,
            edgecurvature=30*s,
            edgegaps= 20*s,
            edgelabelfontsizes=20,
            vertexlabelfontsizes=40,
            edgestrokeweights = 5,
            vertexshapesizes = (v) -> v ∈ (n̅) ? 15*s : 10*s,vertexfillcolors = (v) -> v ∈ (n̅) && colorant"lightgreen")
        end 400*s 400*s "res/pics/n=$n-$loss/$m.png"

        image!(ax, rotr90(FileIO.load("res/pics/n=$n-$loss/$m.png")))
        hidedecorations!(ax)
        hidespines!(ax)  
    end
    
    FileIO.save("res/pics/n=$n-$loss/composite.png", fig)
    fig
end

plotGraphs([-100 -15 -10 -8 0 10], "out8.txt", 8, 1)

plotGraphs([-100 -15 -10 -8 0 10], "models/good7State.txt", 7, 1)