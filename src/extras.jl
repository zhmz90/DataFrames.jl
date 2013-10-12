const letters = convert(Vector{ASCIIString}, split("abcdefghijklmnopqrstuvwxyz", ""))
const LETTERS = convert(Vector{ASCIIString}, split("ABCDEFGHIJKLMNOPQRSTUVWXYZ", ""))

# Like string(s), but preserves Vector{String} and converts
# Vector{Any} to Vector{String}.
_vstring{T <: String}(s::T) = s
_vstring{T <: String}(s::AbstractVector{T}) = s
_vstring(s::AbstractVector) = String[_vstring(x) for x in s]
_vstring(s::Any) = string(s)
vcatstring(x) = vcat(_vstring(x))

function paste(s...)
    s = map(vcatstring, {s...})
    sa = {s...}
    N = max(length, sa)
    res = fill("", N)
    for i in 1:length(sa)
        Ni = length(sa[i])
        k = 1
        for j = 1:N
            res[j] = string(res[j], sa[i][k])
            if k == Ni   # This recycles array elements.
                k = 1
            else
                k += 1
            end
        end
    end
    res
end

function paste_columns(d::AbstractDataFrame, sep)
    res = fill("", nrow(d))
    for j in 1:ncol(d)
        for i in 1:nrow(d)
            res[i] *= string(d[i,j])
            if j != ncol(d)
                res[i] *= sep
            end
        end
    end
    res
end

paste_columns(d::AbstractDataFrame) = paste_columns(d, "_")
