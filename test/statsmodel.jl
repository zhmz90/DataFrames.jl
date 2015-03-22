module TestStatsModels
using DataFrames
using Base.Test

# Tests for statsmodel.jl

# A dummy RegressionModel type
immutable DummyMod <: RegressionModel
    x::Matrix
    y::Vector
end

## dumb fit method: just copy the x and y input over
StatsBase.fit(::Type{DummyMod}, x::Matrix, y::Vector) = DummyMod(x, y)
StatsBase.model_response(mod::DummyMod) = mod.y

## Test fitting
d = DataFrame()
d[:y] = [1:4;]
d[:x1] = [5:8;]
d[:x2] = [9:12;]
d[:x3] = [13:16;]
d[:x4] = [17:20;]

f = y ~ x1 * x2
m = fit(DummyMod, f, d)
@test model_response(m) == d[:y]

## test prediction method
## vanilla
StatsBase.predict(mod::DummyMod) = mod.y
@test predict(m) == d[:y]

## new data from matrix
StatsBase.predict(mod::DummyMod, newX::Matrix) = sum(mod.x, 2)
mm = ModelMatrix(ModelFrame(f, d))
@test predict(m, mm.m) == sum(mm.m, 2)

## new data from DataFrame (via ModelMatrix)
@test predict(m, d) == predict(m, mm.m)

## test copying of names from Terms to CoefTable
## dumb coeftable: just prints the first four rows of the model (x) matrix
StatsBase.coeftable(mod::DummyMod) =
    CoefTable(transpose(mod.x),
              ["row $n" for n in 1:min(4,size(mod.x,1))],
              ["" for n in 1:size(mod.x,2)],
              0)
ct = coeftable(m)
@test ct.rownms == ["(Intercept)", "x1", "x2", "x1 & x2"]

## show after coeftable is defined
@show m

## Another dummy model type to test fall-through show method
immutable DummyModTwo <: RegressionModel
    msg::String
end

StatsBase.fit(::Type{DummyModTwo}, ::Matrix, ::Vector) = DummyModTwo("hello!")
Base.show(io::IO, m::DummyModTwo) = println(io, m.msg)

m2 = fit(DummyModTwo, f, d)
@show m2

end
