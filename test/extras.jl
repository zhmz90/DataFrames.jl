module DataFramesExtras
	using Base.Test
	using DataFrames
	using DataArrays

	##########
	## paste
	##########

	@assert paste(["a", "b"], "X", [1:2]) == ["aX1", "bX2"]
	@assert paste(["a", "b"], "X", [1:4]) == ["aX1", "bX2", "aX3", "bX4"]
end
