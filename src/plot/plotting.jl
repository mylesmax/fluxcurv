using ExponentialUtilities, DelimitedFiles, Colors
using MakieThemes, Makie
using LaTeXStrings, MathTeXEngine
using CairoMakie: Label
# using GLMakie
include("../proto/protocolBlocks.jl")
include("../proto/protocols.jl")
include("markov.jl")
include("objective.jl")

openStateIndex = 1;
dt = 1;

"""
PLOTTING
"""

function plotall(f; params::Vector{Float64} = vec(readdlm("trainedSaves/Previous/newmodel.txt")), title::String = "unknown")
    updateRates!(params)
    scalingfactor = 1

    !@isdefined(f) ? f= Figure(size=(1600,800),fontsize=8 ./scalingfactor) : nothing
    if @isdefined(f)
        empty!(f)
    end

    CairoMakie.set_theme!(ggthemr(:fresh))

    titleLayout = GridLayout(f[0,1:4])
    Label(titleLayout[1, 1], title, fontsize=16 ./scalingfactor, font="TeX Gyre Heros Bold Makie")
    rowgap!(titleLayout, 0)

    """
    SSI
    """
    ax1 = CairoMakie.Axis(f[1,1], title = "Steady State Inactivation", xlabel="Voltage (mV)", ylabel = L"\frac{I}{I_{\mathrm{max}}}", ylabelrotation=2π,xticklabelrotation=π/4, xticks= [-100, -75, -50])
    ssiRange = readdlm("INaHEK/"*WTinac["source"])[:, 1]
    ssiPred= zeros(length(ssiRange[1]:5:ssiRange[end]))
    try
        ssiPred = SSI(WTinac, Q, range = ssiRange[1]:5:ssiRange[end])
    catch
        ssiPred= zeros(length(ssiRange[1]:5:ssiRange[end]))
    end
    ssiTrue = readdlm("INaHEK/"*WTinac["source"])[:, 2]
    ssiMSC = readdlm("INaHEK/"*WTinac["source"])[:, 3]


    CairoMakie.scatterlines!(ax1, ssiRange[1]:5:ssiRange[end], ssiPred, linewidth=3 ./scalingfactor, color=:black, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Simulated")
    CairoMakie.scatterlines!(ax1, ssiRange, ssiTrue, linewidth=3 ./scalingfactor, linestyle=:dot,color=:green, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Real")
    CairoMakie.errorbars!(ssiRange,ssiTrue,ssiMSC,whiskerwidth = 10 ./scalingfactor, color=:green)
    # axislegend(ax1, position=:lb, backgroundcolor=(:white, 1))

    """
    ACTIVATION
    """
    ax2 = CairoMakie.Axis(f[1,2], title = "Activation", xlabel="Voltage (mV)", ylabel = L"\frac{I}{I_{\mathrm{max}}}", ylabelrotation=2π,xticklabelrotation=π/4, xticks= [-40, -30, -20, -10, 0, 10, 20])

    actRange = readdlm("INaHEK/"*WTgv["source"])[:, 1]
    actPred= zeros(length(actRange[1]:5:actRange[end]))
    try
        actPred = activation(WTgv, Q, range = actRange[1]:5:actRange[end])
    catch
        actPred= zeros(length(actRange[1]:5:actRange[end]))
    end
    actTrue = readdlm("INaHEK/"*WTgv["source"])[:, 2]
    actMSC = readdlm("INaHEK/"*WTgv["source"])[:, 3]

    CairoMakie.scatterlines!(ax2, actRange[1]:5:actRange[end], actPred, linewidth=3 ./scalingfactor, color=:black, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Simulated")
    CairoMakie.scatterlines!(ax2, actRange, actTrue, linewidth=3 ./scalingfactor,linestyle=:dot, color=:green, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Real")
    CairoMakie.errorbars!(actRange,actTrue,actMSC,whiskerwidth = 10 ./scalingfactor, color=:green)
    # axislegend(ax2, position=:rb, backgroundcolor=(:white, 1))

    """
    RECOVERY
    """
    ax3 = CairoMakie.Axis(
        f[2,1],
        title = "Recovery",
        xlabel = "Duration Step (ms, Log Scale)",
        ylabel = L"\frac{I}{I_{\mathrm{max}}}",
        ylabelrotation = 2π,
        xticklabelrotation = π/4,
        xscale = log10,
        xtickformat = values -> [rich("10", superscript(" $(Float64(log10(value)))")) for value in values],
        xminorticksvisible = true,
        xminorgridvisible = true,
        xminorticks = IntervalsBetween(5)
    )
    
    recRange = readdlm("INaHEK/"*WTrecovery["source"])[:, 1]
    recPred= zeros(length(recRange[1]:5:recRange[end]))
    try
        recPred = recovery(WTrecovery, Q, trange = recRange[1]:5:recRange[end])
    catch
        recPred= zeros(length(recRange[1]:5:recRange[end]))
    end
    
    recTrue = readdlm("INaHEK/"*WTrecovery["source"])[:, 2]
    recMSC = readdlm("INaHEK/"*WTrecovery["source"])[:, 3]

    CairoMakie.scatterlines!(ax3, recRange[1]:5:recRange[end], recPred, linewidth=3 ./scalingfactor, color=:black, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Simulated")
    CairoMakie.scatterlines!(ax3, recRange, recTrue, linewidth=3 ./scalingfactor,linestyle=:dot, color=:green, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Real")
    CairoMakie.errorbars!(recRange,recTrue,recMSC,whiskerwidth = 10 ./scalingfactor, color=:green)
    # axislegend(ax3, position=:rb, backgroundcolor=(:white, 1))

    """
    RECOVERY UDB
    """
    ax4 = CairoMakie.Axis(
        f[2,2],
        title = "Recovery from UDB",
        xlabel = "Duration Step (ms, Log Scale)",
        ylabel = L"\frac{I}{I_{\mathrm{max}}}",
        ylabelrotation = 2π,
        xticklabelrotation = π/4,
        xscale = log10,
        xtickformat = values -> [rich("10", superscript(" $(Float64(log10(value)))")) for value in values],
        xminorticksvisible = true,
        xminorgridvisible = true,
        xminorticks = IntervalsBetween(5)
    )
    RUDBRange = readdlm("INaHEK/"*WTRUDB["source"])[:, 1]
    RUDBPred= zeros(length(RUDBRange))
    try
        RUDBPred = recoveryUDB(WTRUDB, Q)
    catch
        RUDBPred= zeros(length(RUDBRange))
    end
    RUDBTrue = readdlm("INaHEK/"*WTRUDB["source"])[:, 2]
    RUDBMSC = readdlm("INaHEK/"*WTRUDB["source"])[:, 3]

    CairoMakie.scatterlines!(ax4, RUDBRange, RUDBPred, linewidth=3 ./scalingfactor, color=:black, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Simulated")
    CairoMakie.scatterlines!(ax4, RUDBRange, RUDBTrue, linewidth=3 ./scalingfactor, linestyle=:dot,color=:green, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1, label="Real")
    CairoMakie.errorbars!(RUDBRange,RUDBTrue,RUDBMSC,whiskerwidth = 10 ./scalingfactor, color=:green)
    # axislegend(ax4, position=:rb, backgroundcolor=(:white, 1))
    
    """
    MAXPO
    """
    ax5 = CairoMakie.Axis(f[1,3], title = "MaxPO", xlabel="Voltage (mV)", ylabel = L"\frac{I}{I_{\mathrm{max}}}", ylabelrotation=2π,xticklabelrotation=π/4, xticks= [-20, -15, -10, -5, 0])
    
    maxPORange = readdlm("INaHEK/"*WTmaxpo["source"])[:, 1]
    maxPOPred= zeros(length(maxPORange[1]:5:maxPORange[end]))
    try
        maxPOPred = maxpo(WTmaxpo, Q, range = maxPORange[1]:5:maxPORange[end])
    
    catch
        maxPOPred= zeros(length(maxPORange[1]:5:maxPORange[end]))
    end
    maxPOTrue = readdlm("INaHEK/"*WTmaxpo["source"])[:, 2]
    maxPOMSC = readdlm("INaHEK/"*WTmaxpo["source"])[:, 3]

    CairoMakie.scatterlines!(ax5, maxPORange[1]:5:maxPORange[end], maxPOPred, linewidth=3 ./scalingfactor, color=:black, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Simulated")
    CairoMakie.scatterlines!(ax5, maxPORange, maxPOTrue, linewidth=3 ./scalingfactor, linestyle=:dot,color=:green, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Real")
    CairoMakie.errorbars!(maxPORange,maxPOTrue,maxPOMSC,whiskerwidth = 10 ./scalingfactor, color=:green)
    # axislegend(ax5, position=:rb, backgroundcolor=(:white, 1))

    """
    FALL
    """
    ax6 = CairoMakie.Axis(f[2,3], title = "Fall", ylabel="τ (ms/100)", xlabel = "Voltage (mV)", xticklabelrotation=π/4, xticks =[-20, -10, 0, 10, 20])
    
    fallRange = readdlm("INaHEK/"*WTfall["source"])[:, 1]
    fallPred= zeros(length(-20:1:20))
    try
        fallPred = fall(WTfall, Q, range = -20:1:20)
    catch
        fallPred= zeros(length(-20:1:20))
    end
    fallTrue = readdlm("INaHEK/"*WTfall["source"])[:, 2]
    fallMSC = readdlm("INaHEK/"*WTfall["source"])[:, 3]

    CairoMakie.scatterlines!(ax6, -20:1:20, fallPred, linewidth=3 ./scalingfactor, color=:black, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Simulated")
    CairoMakie.scatterlines!(ax6, fallRange, fallTrue, linewidth=3 ./scalingfactor, linestyle=:dot,color=:green, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Real")
    CairoMakie.errorbars!(fallRange,fallTrue,fallMSC,whiskerwidth = 10 ./scalingfactor, color=:green)
    # axislegend(ax6, position=:rt, backgroundcolor=(:white, 1))
    
    """
    time to peak
    """
    ax7 = CairoMakie.Axis(f[1,4], title = "Time to Peak", ylabel="Time to Peak (ms)", xlabel = "Voltage (mV)", xticklabelrotation=π/4, xticks = [-15, -10, -5])
    
    ttpRange = [-10]
    ttpPred= [0]
    try
        ttpPred = ttpeak(Q)
    catch
        ttpPred= [0]
    end
    ttpTrue = [1]
    ttpMSC = [0.1]

    CairoMakie.scatterlines!(ax7, [-10], [1], linewidth=3 ./scalingfactor, color=:black, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Simulated")
    CairoMakie.scatterlines!(ax7, ttpRange, ttpTrue, linewidth=3 ./scalingfactor, linestyle=:dot,color=:green, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Real")
    CairoMakie.errorbars!(ttpRange,ttpTrue,ttpMSC,whiskerwidth = 10 ./scalingfactor, color=:green)
    # axislegend(ax7, position=:rt, backgroundcolor=(:white, 1))

    legend = Legend(f[2, 4], ax1, "Legend", framevisible=false, labelsize=8 ./ scalingfactor)

    f
end

#= 
wustlPSO10 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso10.yml")
plotall(params = wustlPSO10["curParams"])
length(wustlPSO10["iterations"])

wustlPSO7 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso7.yml")
plotall(params = wustlPSO7["curParams"])
length(wustlPSO7["iterations"])

wustlPSO11 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso11.yml")
f = plotall(params = wustlPSO11["curParams"])
length(wustlPSO11["iterations"])
# save("pso11-mar31.png", f)
# writedlm("trainedSaves/modelMar31-744pm.txt",wustlPSO11["curParams"])

wustlPSO15 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso15.yml")
plotall(params = wustlPSO15["curParams"])
length(wustlPSO15["iterations"])

wustlPSO9 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso9.yml")
plotall(params = wustlPSO9["curParams"])
length(wustlPSO9["iterations"])

wustlPSO13 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso13.yml")
f = plotall(params = wustlPSO13["curParams"])
length(wustlPSO13["iterations"])
# save("pso13-mar31.png", f)

wustlPSO17 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso17.yml")
plotall(params = wustlPSO17["curParams"])
length(wustlPSO17["iterations"])

#upgrs
# pso14SaveForJon = wustlPSO14["curParams"]
# plotall(params = pso14SaveForJon)
wustlPSO14 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso14.yml")
plotall(params = wustlPSO14["curParams"])
wustlPSO14["iterations"][end]
# writedlm("trainedSaves/modelApr1-803am.txt",wustlPSO14["curParams"])
length(wustlPSO14["iterations"])

wustlPSO20 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso20.yml")
plotall(params = wustlPSO20["curParams"])
length(wustlPSO20["iterations"])
# writedlm("trainedSaves/modelApr1-1206am.txt",wustlPSO20["curParams"])

wustlPSO7NEXT = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso3/pso7.yml")
plotall(params = wustlPSO7NEXT["curParams"])
length(wustlPSO7NEXT["iterations"])
=#
 f=  Figure(size=(1200,800))
plotall(f, params=params)

function psoCurves()
    function convTimes(inp::String)
        dateFormat = "e, u d, Y at HH:MM:SS"
        starttime = replace(inp, r"\s(AM|PM)$" => "")
        return DateTime(starttime, dateFormat)
    end
    function psoParams(inp::Dict{Any,Any}; val=false::Bool)
        curve = Float64[]
        dates = Float64[]
        initialDate = convTimes(inp["starttime"])

        for it ∈ inp["iterations"]
            push!(dates, Dates.value(convTimes(it["endtime"])-initialDate))
            val ? push!(curve, it["validation"]) : push!(curve, it["loss"])
        end

        return (dates./ 60000, curve)
    end
    function findElapsedTime(inp::Dict{Any,Any})
        times = []
        for (i, it) ∈ enumerate(inp["iterations"])
            (i == 1) ? (prev = inp["starttime"]) : (prev = inp["iterations"][i-1]["endtime"])
            push!(times, Dates.value(convTimes(it["endtime"])-convTimes(prev)))
        end

        return round(sum(times)/(60000*length(times)),digits=2) #minutes
    end

    CairoMakie.set_theme!(ggthemr(:fresh))

    wustlPSO10 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso10.yml")
    wustlPSO7 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso7.yml")
    wustlPSO11 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso11.yml")
    wustlPSO15 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso15.yml")
    wustlPSO9 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso9.yml")
    wustlPSO13 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso13.yml")
    wustlPSO17 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso17.yml")
    wustlPSO14 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso14.yml")
    wustlPSO20 = YAML.load_file("/Volumes/m.max/Desktop/Silva Lab/markovSimpleNa/trainedSaves/pso2/pso20.yml")


    f = Figure(size=(1400,600), fontsize=8)

    ax = CairoMakie.Axis(
        f[1,1],
        yscale = log10,
        # xscale=log2,
        title = "Training Curves (10^3 PSO + 10^2 Nelder Mead)",
        xlabel = "Time from Start (minutes)",
        ylabel = "Objective Loss (Huber)",
        titlefont = :bold,
        titlesize = 20,
        xlabelsize = 18,
        ylabelsize = 18,
        yminorticksvisible = true,
        yminorgridvisible = true,
        ytickformat = values -> [rich("10", superscript(" $(Float64(log10(value)))")) for value in values],
        yminorticks = IntervalsBetween(5)
    )

    # lines!(ax, psoParams(wustlPSO10)...,linewidth=5, color=:black, marker=:circle, markercolor=:white, markersize=15, strokecolor=:black, strokewidth=2, label="10 Particles\nAverage Iteration: $(findElapsedTime(wustlPSO10)) min")
    scatterlines!(ax, psoParams(wustlPSO7)...,linewidth=5, color=:blue, marker=:circle, markercolor=:white, markersize=5, strokecolor=:black, strokewidth=1, label="7 Particles\nAverage Iteration: $(findElapsedTime(wustlPSO7)) min")
    scatterlines!(ax, psoParams(wustlPSO11)...,linewidth=5, color=:green, marker=:circle, markercolor=:white, markersize=5, strokecolor=:black, strokewidth=1, label="11 Particles\nAverage Iteration: $(findElapsedTime(wustlPSO11)) min")
    scatterlines!(ax, psoParams(wustlPSO15)...,linewidth=5, color=:brown, marker=:circle, markercolor=:white, markersize=5, strokecolor=:black, strokewidth=1, label="15 Particles\nAverage Iteration: $(findElapsedTime(wustlPSO15)) min")
    scatterlines!(ax, psoParams(wustlPSO9)...,linewidth=5, color=:red, marker=:circle, markercolor=:white, markersize=5, strokecolor=:black, strokewidth=1, label="9 Particles\nAverage Iteration: $(findElapsedTime(wustlPSO9)) min")
    scatterlines!(ax, psoParams(wustlPSO13)...,linewidth=5, color=:orange, marker=:circle, markercolor=:white, markersize=5, strokecolor=:black, strokewidth=1, label="13 Particles\nAverage Iteration: $(findElapsedTime(wustlPSO13)) min")
    scatterlines!(ax, psoParams(wustlPSO17)...,linewidth=5, color=:gray, marker=:circle, markercolor=:white, markersize=5, strokecolor=:black, strokewidth=1, label="17 Particles\nAverage Iteration: $(findElapsedTime(wustlPSO17)) min")
    scatterlines!(ax, psoParams(wustlPSO14)...,linewidth=5, color=:aquamarine, marker=:circle, markercolor=:white, markersize=5, strokecolor=:black, strokewidth=1, label="14 Particles\nAverage Iteration: $(findElapsedTime(wustlPSO14)) min")
    scatterlines!(ax, psoParams(wustlPSO20)...,linewidth=5, color=:magenta, marker=:circle, markercolor=:white, markersize=5, strokecolor=:black, strokewidth=1, label="20 Particles\nAverage Iteration: $(findElapsedTime(wustlPSO20)) min")

    ax2 = CairoMakie.Axis(
        f[1,2],
        yscale = log10,
        # xscale=log2,
        title="Validation Curves (10^3 PSO + 10^2 Nelder Mead)",
        xlabel="Time from Start (minutes)",
        ylabel = "Objective Loss (Huber)",
        titlefont = :bold,
        titlesize = 20,
        xlabelsize = 18,
        ylabelsize = 18,
        yminorticksvisible = true,
        yminorgridvisible = true,
        ytickformat = values -> [rich("10", superscript(" $(Float64(log10(value)))")) for value in values],
        yminorticks = IntervalsBetween(5)
    )
    ylims!(ax2, (10^-3,10^-1))
    
    # lines!(ax2, psoParams(wustlPSO10, val=true)...,linewidth=1, color=:black, marker=:circle, markercolor=:white, markersize=15, strokecolor=:black, strokewidth=2, label="10 Particles (VALIDATION)")
    lines!(ax2, psoParams(wustlPSO7, val=true)...,linewidth=2.5, color=:blue, marker=:circle, markercolor=:white, markersize=15, strokecolor=:black, strokewidth=2, label="7 Particles (VALIDATION)")
    lines!(ax2, psoParams(wustlPSO11, val=true)...,linewidth=2.5, color=:green, marker=:circle, markercolor=:white, markersize=15, strokecolor=:black, strokewidth=2, label="11 Particles (VALIDATION)")
    lines!(ax2, psoParams(wustlPSO15, val=true)...,linewidth=2.5, color=:brown, marker=:circle, markercolor=:white, markersize=15, strokecolor=:black, strokewidth=2, label="15 Particles (VALIDATION)")
    lines!(ax2, psoParams(wustlPSO9, val=true)...,linewidth=2.5, color=:red, marker=:circle, markercolor=:white, markersize=15, strokecolor=:black, strokewidth=2, label="9 Particles (VALIDATION)")
    lines!(ax2, psoParams(wustlPSO13, val=true)...,linewidth=2.5, color=:orange, marker=:circle, markercolor=:white, markersize=15, strokecolor=:black, strokewidth=2, label="13 Particles (VALIDATION)")
    lines!(ax2, psoParams(wustlPSO17, val=true)...,linewidth=2.5, color=:gray, marker=:circle, markercolor=:white, markersize=15, strokecolor=:black, strokewidth=2, label="17 Particles (VALIDATION)")
    lines!(ax2, psoParams(wustlPSO14, val=true)...,linewidth=2.5, color=:aquamarine, marker=:circle, markercolor=:white, markersize=15, strokecolor=:black, strokewidth=2, label="14 Particles (VALIDATION)")
    lines!(ax2, psoParams(wustlPSO20, val=true)...,linewidth=2.5, color=:magenta, marker=:circle, markercolor=:white, markersize=15, strokecolor=:black, strokewidth=2, label="20 Particles (VALIDATION)")

    f[1,3] = Legend(f, ax, "Particle Count",position=:rt, backgroundcolor=(:white, 0.8), patchsize=(80.0f0,70.0f0))
    f
end

# f = psoCurves()
# save("psocurves.png",f)