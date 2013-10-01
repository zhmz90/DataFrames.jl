using Base.Test
using DataFrames

module DataFramesTabulation
	# @assert isequal(xtab([1, 2, 2, 2, 3]), xtab([1, 2, 3],[1, 3, 1]))
	@assert isequal(xtabs([1, 2, 2, 2, 3]), [2 => 3, 3 => 1, 1 => 1])
end
