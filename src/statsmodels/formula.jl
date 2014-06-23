# Formulas for representing and working with linear-model-type expressions
# Original by Harlan D. Harris.  Later modifications by John Myles White
# and Douglas M. Bates.

## Formulas are written with a ~ and parsed as a call to @~
## In Julia the & operator is used for an interaction.  What would be written
## in R as y ~ a + b + a:b is written :(y ~ a + b + a&b) in Julia.
## The equivalent R expression, y ~ a*b, is the same in Julia

## The lhs of a one-sided formula is 'nothing'
## The rhs of a formula can be 1

type Formula
    lhs::Union(Symbol, Expr, Nothing)
    rhs::Union(Symbol, Expr, Integer)
end

macro ~(lhs, rhs)
    ex = Expr(:call,
              :Formula,
              Base.Meta.quot(lhs),
              Base.Meta.quot(rhs))
    return ex
end

type Terms
    terms::Vector
    eterms::Set                       # evaluation terms
    lhs::Union(Symbol, Expr, Nothing)
end

type ModelFrame
    df::AbstractDataFrame
    terms::Terms
    msng::BitArray
end

type ModelMatrix{T <: Union(Float32, Float64)}
    m::Matrix{T}
    assign::Vector{Int}
end

Base.size(mm::ModelMatrix) = size(mm.m)
Base.size(mm::ModelMatrix, dim...) = size(mm.m, dim...)

Base.show(io::IO, f::Formula) =
    print(io,
          string("Formula: ",
                 f.lhs == nothing ? "" : f.lhs, " ~ ", f.rhs))

## Check if an expression is a call to a particular symbol or is in a set or vector of symbols
iscall(ex::Expr,s::Symbol) = ex.head == :call && ex.args[1] == s
iscall(ex::Expr,s::Set)    = ex.head == :call && in(ex.args[1],s)
iscall(ex::Expr,s::Vector) = ex.head == :call && in(ex.args[1],s)
iscall(ex,      s)         = false

## Return, as a vector of symbols, the names of all the variables in
## an expression or a formula
function allvars(ex::Expr)
    ex.head == :call || error("Non-call expression encountered")
    [[allvars(a) for a in ex.args[2:end]]...]
end
allvars(f::Formula) = unique(vcat(allvars(f.rhs), allvars(f.lhs)))
allvars(s::Symbol) = [s]
allvars(v::Any) = Array(Symbol, 0)

immutable Subsets{T}  # an iterator giving the subsets of elements of a vector
    nsub::Uint
    v::AbstractVector{T}
end
function Subsets(v::AbstractVector)
    lv = length(v)
    lv ≥ 8 * sizeof(lv) && error("length(v) is too large for Subsets")
    Subsets(uint(1)<<lv,v)
end
Base.length(ss::Subsets) = ss.nsub

Base.start(ss::Subsets) = uint(0)
function Base.next{T}(ss::Subsets{T},state) 
    vv = T[]
    j = state
    for el in ss.v
        bool(j & 1) && push!(vv,el)
        j >>>= 1
    end
    (vv,state+one(Uint))
end
Base.done(ss::Subsets,state) = state ≥ ss.nsub

## Expand calls to * within any of the arguments of the special operators
function xpndmlt(ex)
    iscall(ex,[:+, :-, :*, :/, :&, :|, :^]) || return ex
    a1 = ex.args[1]
    ex = Expr(:call,a1,[xpndmlt(t) for t in ex.args[2:end]]...)  # recursive application
    a1 == :* || return ex
    sumands = {}
    for s in Subsets(ex.args[2:end])
        len = length(s)
        len == 1 && push!(sumands,s[1])
        len > 1 && push!(sumands,Expr(:call,:&,s...))
    end
    Expr(:call,:+,sumands...)
end

cargs(aa,s::Symbol) = vcat({iscall(a,s) ? cargs(a.args[2:end],s) : {a} for a in aa}...)
## Condense calls like :(+(a,+(b,c))) to :(+(a,b,c))
function condense(ex,s::Symbol)
    iscall(ex,s) || return ex
    Expr(:call,s,cargs(ex.args[2:end],s)...)
end

getterms(ex) = iscall(ex,:+) ? ex.args[2:end] : [ex]

## order of an interaction
ord(ex::Expr) = iscall(ex,:&) ? length(ex.args)-1 : (iscall(ex,:|) ? typemax(1) : 1)
ord(s::Symbol) = 1
ord(x::Number) = 0
## evaluation terms - the (filtered) arguments for :& and :|, otherwise the term itself
function evt(ex::Expr,s::Set)
    iscall(ex,[:&,:|,:+,:/]) || return push!(s,ex)
    for a in ex.args[2:end]
        evt(a,s)
    end
    s
end
evt(x::Number,S::Set) = push!(S,x)
evt(s::Symbol,S::Set) = push!(S,s)

ordterms(rhs) = rhs[sortperm([ord(t) for t in rhs])]

function Terms(f::Formula)
    rhs = condense(xpndmlt(f.rhs),:+)
    eterms = evt(rhs,Set())             # the set of evaluation terms
    noint = in(0,eterms)                # at present just use 0 + for suppressing intercept
    forceint = in(1,eterms)
    noint && forceint && error("Contradictory indicators 0 + and 1 + in formula")
    noint || push!(eterms,1)
    terms = ordterms(getterms(rhs))
    Terms(ordterms(getterms(rhs)), eterms, f.lhs)
end

## Default NA handler.  Others can be added as keyword arguments
function na_omit(df::DataFrame)
    cc = complete_cases(df)
    df[cc,:], cc
end

## Trim the pool field of da to only those levels that occur in the refs
function dropUnusedLevels!(da::PooledDataArray)
    rr = da.refs
    uu = unique(rr)
    length(uu) == length(da.pool) && return da
    T = eltype(rr)
    su = sort!(uu)
    dict = Dict(su, one(T):convert(T,length(uu)))
    da.refs = [dict[x] for x in rr]
    da.pool = da.pool[uu]
    da
end
dropUnusedLevels!(x) = x

function ModelFrame(f::Formula, d::AbstractDataFrame)
    trms = Terms(f)
    df, msng = na_omit(DataFrame(map(x -> d[x], trms.eterms)))
    names!(df, convert(Vector{Symbol}, map(string, trms.eterms)))
    for c in eachcol(df) dropUnusedLevels!(c[2]) end
    ModelFrame(df, trms, msng)
end
ModelFrame(ex::Expr, d::AbstractDataFrame) = ModelFrame(Formula(ex), d)

function model_response(mf::ModelFrame)
    mf.terms.response || error("Model formula one-sided")
    convert(Array, mf.df[bool(mf.terms.factors[:,1])][:,1])
end

function contr_treatment(n::Integer, contrasts::Bool, sparse::Bool, base::Integer)
    if n < 2 error("not enought degrees of freedom to define contrasts") end
    contr = sparse ? speye(n) : eye(n) .== 1.
    if !contrasts return contr end
    if !(1 <= base <= n) error("base = $base is not allowed for n = $n") end
    contr[:,vcat(1:(base-1),(base+1):end)]
end
contr_treatment(n::Integer,contrasts::Bool,sparse::Bool) = contr_treatment(n,contrasts,sparse,1)
contr_treatment(n::Integer,contrasts::Bool) = contr_treatment(n,contrasts,false,1)
contr_treatment(n::Integer) = contr_treatment(n,true,false,1)
cols(v::PooledDataVector) = contr_treatment(length(v.pool))[v.refs,:]
cols(v::DataVector) = reshape(float64(v.data), (length(v),1))
cols(v::Vector) = float64(v)

function isfe(ex::Expr)                 # true for fixed-effects terms
    if ex.head != :call error("Non-call expression encountered") end
    ex.args[1] != :|
end
isfe(a) = true

## Utility to determine all combinations of indices from vector sizes
## returns a matrix of size length(v)×prod(v).  Sort of like expand.grid in R.
function allcomb(v::Vector)
    inds = {}
    tot = prod(v)
    each = 1
    for el in v
        push!(inds, rep([1:el], div(tot,el*each), each)')
        each *= el
    end
    vcat(inds...)
end

## Expand the columns in an interaction term
## The argument is a vector of matrices
function expandcols(trms::Vector)
    trms = [float64(t) for t in trms]
    (l = length(trms)) == 1 && return trms[1]
    l1 = size(trms[1],1)
    all([size(t,1) == l1 for t in trms[2:end]]) ||
        error("size(t,1) must match for all t in trms")
    inds = allcomb([size(t,2) for t in trms])
    hcat([reduce(.*,{a[:,j] for (a,j) in zip(trms,inds[:,jj])}) for jj in 1:size(inds,2)]...)
end

nc(trms::Vector) = prod([size(t,2) for t in trms])

function ModelMatrix(mf::ModelFrame)
    trms = mf.terms
    aa = {{ones(size(mf.df,1),int(trms.intercept))}}
    asgn = zeros(Int, (int(trms.intercept)))
    fetrms = bool(map(isfe, trms.terms))
    if trms.response unshift!(fetrms,false) end
    ff = trms.factors[:,fetrms]
    ## need to be cautious here to avoid evaluating cols for a factor with many levels
    ## if the factor doesn't occur in the fetrms
    rows = vec(bool(sum(ff,[2])))
    ff = ff[rows,:]
    cc = [cols(x[2]) for x in eachcol(mf.df[:,rows])]
    for j in 1:size(ff,2)
        trm = cc[bool(ff[:,j])]
        push!(aa, trm)
        asgn = vcat(asgn, fill(j, nc(trm)))
    end
    ModelMatrix{Float64}(hcat([expandcols(t) for t in aa]...), asgn)
end

termnames(term::Symbol, col) = [string(term)]
function termnames(term::Symbol, col::PooledDataArray)
    levs = levels(col)
    [string(term, " - ", levs[i]) for i in 2:length(levs)]
end

function coefnames(fr::ModelFrame)
    if fr.terms.intercept
        vnames = UTF8String["(Intercept)"]
    else
        vnames = UTF8String[]
    end
    # Need to only include active levels
    for term in fr.terms.terms
        if isa(term, Expr)
            if term.head == :call && term.args[1] == :&
                a = term.args[2]
                b = term.args[3]
                for lev1 in termnames(a, fr.df[a]), lev2 in termnames(b, fr.df[b])
                    push!(vnames, string(lev1, " & ", lev2))
                end
            else
                error("unrecognized term $term")
            end
        else
            append!(vnames, termnames(term, fr.df[term]))
        end
    end
    return vnames
end
