load("hdf5.jl")
import HDF5Mod.*
import HDF5Mod


type HDF5GroupDF <: AbstractDataFrame
    # DataFrame stored as an HDF5 Group.
    # Each column is a Dataset.
    # For now, this is read only (no assign, insert, or append).
    grp::HDF5Group
    # TODO - a constructor that checks that the entries in the group
    # all have the appropriate lengths.
end

index(d::HDF5GroupDF) = Index(names(d.grp)) 
# Should we store an index in the HDF5GroupDF?
# Now, we just compute it on the fly.


# The following returns a reference to the HDF5Dataset with the vector
# data.
ref(df::HDF5GroupDF, c::Integer) = HDF5Dataset(HDF5Mod.h5o_open_by_idx(df.grp, ".", HDF5Mod.H5_INDEX_UNKNOWN, HDF5Mod.H5_ITER_INC, c - 1, HDF5Mod.H5P_DEFAULT), df.grp.file)

# The following methods return a DataFrame.
ref(df::HDF5GroupDF, c::Vector{Int}) = DataFrame({df[i][:] for i in c}, convert(Vector{ByteString}, colnames(df)[c]))
ref(df::HDF5GroupDF, r, c::Vector{Int}) = DataFrame({df[i][r] for i in c}, convert(Vector{ByteString}, colnames(df)[c]))


fn = "test/data/test.h5"
fidr = h5open(fn)
dfidr = fidr["df"]

df = HDF5GroupDF(dfidr)

# WORKS
df[1]
df["x"]
df[:,1]
df[1:3,1]
df[2:end,1]
df[1:3,"x"]
df[[1,2]] 
df[["x","y"]] 
df[[true,false]]
df[1:3,[1,2]]
df[1:3,["x","y"]]
df[1:3,:]
df[1:3,1:2]
df[1:3,2:end]
df[1:3,[true,false]]
df[:]
df[1:2]
df[2:end]

# FAILS
## df[[1,2,3],1] # HDF5 array index must be range or integer
## df[df["x"][:] .== 1,2] # index must be range or integer




type HDF5TableDF <: AbstractDataFrame
    # DataFrame stored as an HDF5 Table.
    # For now, this is read only (no assign, insert, or append).
    dset::HDF5Dataset
    # TODO - a constructor that checks that the Dataset is a suitable
    # table.
end

index(d::HDF5TableDF) = Index(names(d.dset)) 
# Should we store an index in the HDF5GroupDF?
# Now, we just compute it on the fly.

     
## Notes on the Table approach:
##
##   - dtbl[1] more naturally returns the whole array, not just a
##     reference. With HDF5GroupDFs or DataFrames, indexing on a
##     column is inexpensive.
##
##   - Until Julia's C interface improves to support structures, there
##     isn't a very good fit between DataFrames and HDF5 Tables.
##     Tables are vectors of structs, and DataFrames are parallel vectors.
