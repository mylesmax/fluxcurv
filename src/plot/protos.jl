using ExponentialUtilities, DelimitedFiles, Colors
using MakieThemes, Makie
using CairoMakie

"""
PLOTTING
"""

function plotall(f, params, n, n̅)
    a = consolidatedLoss(params, returnforPlotting=true)
    weightedAvg, y_activation, y_inactivation, y_recovery, y_recoveryUDB, y_MAXPO, y_TTP, y_FALL, ŷ_activation, ŷ_inactivation, ŷ_recovery, ŷ_recoveryUDB, ŷ_MAXPO, ŷ_TTP, ŷ_FALL = a

    dt = 1e-4
    title::String = "n=$n , n̅=$n̅ , total model loss = $(weightedAvg)"
    
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
    
    ssiRange = vec([-110.0  -100.0   -80.0   -70.0   -60.0   -40.0])
    CairoMakie.scatterlines!(ax1, ssiRange, ŷ_inactivation, linewidth=3 ./scalingfactor, color=:black, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Simulated")
    CairoMakie.scatterlines!(ax1, ssiRange, y_inactivation, linewidth=3 ./scalingfactor, linestyle=:dot,color=:green, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Real")
    CairoMakie.errorbars!(ssiRange,y_inactivation,vec([0.01  0.01  0.01  0.02  0.03  0.01]),whiskerwidth = 10 ./scalingfactor, color=:green)
    f
    # axislegend(ax1, position=:lb, backgroundcolor=(:white, 1))

    """
    ACTIVATION
    """
    ax2 = CairoMakie.Axis(f[1,2], title = "Activation", xlabel="Voltage (mV)", ylabel = L"\frac{I}{I_{\mathrm{max}}}", ylabelrotation=2π,xticklabelrotation=π/4, xticks= [-40, -30, -20, -10, 0, 10, 20])

    actRange = vec([-43.27  -39.5  -34.95  -29.57  -19.2  -13.5   -8.95   -4.05    5.74   16.25   20.76])
    
    actMSC = vec([0.01  0.01  0.02  0.02  0.05  0.03  0.02  0.02  0.01  0.01  0.01])

    CairoMakie.scatterlines!(ax2, actRange, ŷ_activation, linewidth=3 ./scalingfactor, color=:black, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Simulated")
    CairoMakie.scatterlines!(ax2, actRange, y_activation, linewidth=3 ./scalingfactor,linestyle=:dot, color=:green, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Real")
    CairoMakie.errorbars!(actRange,y_activation,actMSC,whiskerwidth = 10 ./scalingfactor, color=:green)
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
    
    recRange = vec([0.5    6.0    8.9   11.9   20.6   29.8   58.0   87.7  120.6  208.2])
    
    recMSC = vec([0.02  0.03  0.04  0.02  0.01  0.01  0.01  0.01  0.01  0.01])

    CairoMakie.scatterlines!(ax3, recRange, ŷ_recovery, linewidth=3 ./scalingfactor, color=:black, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Simulated")
    CairoMakie.scatterlines!(ax3, recRange, y_recovery, linewidth=3 ./scalingfactor,linestyle=:dot, color=:green, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Real")
    CairoMakie.errorbars!(recRange,y_recovery,recMSC,whiskerwidth = 10 ./scalingfactor, color=:green)
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
    RUDBRange = vec([0.49     1.0     8.89    29.8   298.0   904.0  2980.0  8890.0])
    
    RUDBMSC = vec([0.01  0.01  0.05  0.05  0.02  0.02  0.01  0.01])

    CairoMakie.scatterlines!(ax4, RUDBRange, ŷ_recoveryUDB, linewidth=3 ./scalingfactor, color=:black, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Simulated")
    CairoMakie.scatterlines!(ax4, RUDBRange, y_recoveryUDB, linewidth=3 ./scalingfactor, linestyle=:dot,color=:green, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1, label="Real")
    CairoMakie.errorbars!(RUDBRange,y_recoveryUDB,RUDBMSC,whiskerwidth = 10 ./scalingfactor, color=:green)
    # axislegend(ax4, position=:rb, backgroundcolor=(:white, 1))
    
    """
    MAXPO
    """
    ax5 = CairoMakie.Axis(f[1,3], title = "MaxPO", xlabel="Voltage (mV)", ylabel = L"\frac{I}{I_{\mathrm{max}}}", ylabelrotation=2π,xticklabelrotation=π/4, xticks= [-20, -15, -10, -5, 0])
    
    maxPORange = vec([-20.0  -10.0    0.0])
    
    maxPOMSC = vec([0.05  0.05  0.05])

    CairoMakie.scatterlines!(ax5, maxPORange, ŷ_MAXPO, linewidth=3 ./scalingfactor, color=:black, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Simulated")
    CairoMakie.scatterlines!(ax5, maxPORange, y_MAXPO, linewidth=3 ./scalingfactor, linestyle=:dot,color=:green, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Real")
    CairoMakie.errorbars!(maxPORange,y_MAXPO,maxPOMSC,whiskerwidth = 10 ./scalingfactor, color=:green)
    # axislegend(ax5, position=:rb, backgroundcolor=(:white, 1))

    """
    FALL
    """
    ax6 = CairoMakie.Axis(f[2,3], title = "Fall", ylabel="τ (ms/100)", xlabel = "Voltage (mV)", xticklabelrotation=π/4, xticks =[-20, -10, 0, 10, 20])
    
    fallRange = vec([20.0   15.0   10.0    5.0   -5.0  -10.0  -15.0])
    
    fallMSC = vec([0.01  0.01  0.02  0.02  0.03  0.03  0.03])

    CairoMakie.scatterlines!(ax6, fallRange, ŷ_FALL, linewidth=3 ./scalingfactor, color=:black, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Simulated")
    CairoMakie.scatterlines!(ax6, fallRange, y_FALL, linewidth=3 ./scalingfactor, linestyle=:dot,color=:green, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Real")
    CairoMakie.errorbars!(fallRange,y_FALL,fallMSC,whiskerwidth = 10 ./scalingfactor, color=:green)
    # axislegend(ax6, position=:rt, backgroundcolor=(:white, 1))
    
    """
    time to peak
    """
    ax7 = CairoMakie.Axis(f[1,4], title = "Time to Peak", ylabel="Time to Peak (ms)", xlabel = "Voltage (mV)", xticklabelrotation=π/4, xticks = [-15, -10, -5])
    
    ttpRange = [-10]
    ttpMSC = [0.1]

    CairoMakie.scatterlines!(ax7, [-10], ŷ_TTP, linewidth=3 ./scalingfactor, color=:black, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Simulated")
    CairoMakie.scatterlines!(ax7, ttpRange, y_TTP, linewidth=3 ./scalingfactor, linestyle=:dot,color=:green, marker=:circle, markercolor=:white, markersize=10 ./scalingfactor, strokecolor=:black, strokewidth=1 ./scalingfactor, label="Real")
    CairoMakie.errorbars!(ttpRange,y_TTP,ttpMSC,whiskerwidth = 10 ./scalingfactor, color=:green)
    # axislegend(ax7, position=:rt, backgroundcolor=(:white, 1))

    legend = Legend(f[2, 4], ax1, "Legend", framevisible=false, labelsize=8 ./ scalingfactor)

    f
end

f =  Figure(size=(1200,800))
plotall(f, vec(readdlm("out8.txt")), 8 , 1)

plotall(f, vec(readdlm("models/good7State.txt")), 7 , 1)
