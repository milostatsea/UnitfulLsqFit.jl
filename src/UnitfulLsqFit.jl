module UnitfulLsqFit

using Unitful:
    AbstractQuantity, Unit, Units, NoDims, dimension, unit, ustrip, @u_str, @unit, register
import LsqFit: curve_fit, LsqFitResult
import Base: *

function __init__()
    return register(UnitfulLsqFit)
end

# One {{{
@unit one "" One 1 false
register(UnitfulLsqFit)
*(q::AbstractQuantity, ::Units{(Unit{:One,NoDims}(0, 1),),NoDims,nothing}) = q
function *(
    a::AbstractQuantity, b::T
) where {
    T<:AbstractQuantity{<:Number,NoDims,<:Units{(Unit{:One,NoDims}(0, 1),),NoDims,nothing}},
}
    return a * b.val
end
function *(
    b::T, a::AbstractQuantity
) where {
    T<:AbstractQuantity{<:Number,NoDims,<:Units{(Unit{:One,NoDims}(0, 1),),NoDims,nothing}},
}
    return b.val * a
end
# One }}}

function curve_fit(
    model,
    xdata::AbstractArray{<:AbstractQuantity},
    ydata::AbstractArray,
    p0::AbstractArray{<:AbstractQuantity};
    normalize=false,
    kwargs...,
)
    # unit check
    dimension(model(first(xdata), p0)...) === dimension(first(ydata)) ||
        error("Model and ydata dimensions incompatible")
    xunit = unit(first(xdata))
    yunit = unit(first(ydata))
    punits = unit.(p0)

    X = ustrip.(xunit, xdata)
    Y = ustrip.(yunit, ydata)
    P = ustrip.(punits, p0)

    auxmodel(x, p) = ustrip.(yunit, model(x .* xunit, p .* punits))
    auxfit = curve_fit(auxmodel, X, Y, P; kwargs...)

    return LsqFitResult(
        auxfit.param .* punits,
        auxfit.resid * yunit,
        auxfit.jacobian * yunit ./ reshape(punits, 1, :),
        auxfit.converged,
        auxfit.wt,
    )
end

# Orthogonals {{{
function curve_fit( # 1 0
    model,
    xdata::AbstractArray{<:AbstractQuantity},
    ydata::AbstractArray,
    p0::AbstractArray;
    kwargs...,
)
    return curve_fit(model, xdata, ydata * u"one", p0 * u"one"; kwargs...)
end

function curve_fit( # 0 1
    model,
    xdata::AbstractArray,
    ydata::AbstractArray,
    p0::AbstractArray{<:AbstractQuantity};
    kwargs...,
)
    return curve_fit(model, xdata * u"one", ydata * u"one", p0; kwargs...)
end
# functionality for weights
function curve_fit(
    model,
    xdata::AbstractArray{<:AbstractQuantity},
    ydata::AbstractArray,
    wt::AbstractMatrix,
    p0::AbstractArray{<:AbstractQuantity};
    normalize=false,
    kwargs...,
)
    # unit check
    dimension(model(first(xdata), p0)...) === dimension(first(ydata)) ||
        error("Model and ydata dimensions incompatible")
    xunit = unit(first(xdata))
    yunit = unit(first(ydata))
    punits = unit.(p0)

    X = ustrip.(xunit, xdata)
    Y = ustrip.(yunit, ydata)
    P = ustrip.(punits, p0)

    auxmodel(x, p) = ustrip.(yunit, model(x .* xunit, p .* punits))
    auxfit = curve_fit(auxmodel, X, Y, wt,P; kwargs...)

    return LsqFitResult(
        auxfit.param .* punits,
        auxfit.resid * yunit,
        auxfit.jacobian * yunit ./ reshape(punits, 1, :),
        auxfit.converged,
        auxfit.wt,
    )
end

# Orthogonals {{{
function curve_fit( # 1 0
    model,
    xdata::AbstractArray{<:AbstractQuantity},
    ydata::AbstractArray,
    wt,
    p0::AbstractArray;
    kwargs...,
)
    return curve_fit(model, xdata, ydata * u"one", wt,p0 * u"one"; kwargs...)
end

function curve_fit( # 0 1
    model,
    xdata::AbstractArray,
    ydata::AbstractArray,
    wt,
    p0::AbstractArray{<:AbstractQuantity};
    kwargs...,
)
    return curve_fit(model, xdata * u"one", ydata * u"one", wt,p0; kwargs...)
end


end
