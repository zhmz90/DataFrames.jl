module DataFramesOperators
    using Base.Test
    using DataFrames, DataArrays

    # Unary operators on DataFrame's should be equivalent to elementwise
    # application of those same operators
    df = DataFrame(quote
                       A = [1, 2, 3, 4]
                       B = [1.0, pi, pi, e]
                   end)
    for f in map(eval, DataArrays.numeric_unary_operators)
        for i in 1:nrow(df)
            for j in 1:ncol(df)
                @assert f(df)[i, j] == f(df[i, j])
            end
        end
    end
    df = DataFrame(quote
                       A = [true, false, true, false]
                   end)
    for f in map(eval, DataArrays.logical_unary_operators)
        for i in 1:nrow(df)
            for j in 1:ncol(df)
                @assert f(df)[i, j] == f(df[i, j])
            end
        end
    end

    # Elementary functions on DataFrames's
    N = 5
    df = DataFrame(quote
                       A = dataones($(N))
                       B = dataones($(N))
                   end)
    for f in map(eval, DataArrays.elementary_functions)
        for i in 1:nrow(df)
            for j in 1:ncol(df)
                  @assert f(df)[i, j] == f(df[i, j])
            end
        end
    end

    # Broadcasting operations between NA's and DataFrames's
    N = 5
    df = DataFrame(quote
                       A = dataones($(N))
                       B = dataones($(N))
                   end)
    for f in map(eval, DataArrays.arithmetic_operators)
        for i in 1:nrow(df)
            for j in 1:ncol(df)
                @assert isna(f(df, NA)[i, j])
                @assert isna(f(NA, df)[i, j])
            end
        end
    end

    # Broadcasting operations between scalars and DataFrames's
    N = 5
    df = DataFrame(quote
                       A = dataones($(N))
                       B = dataones($(N))
                   end)
    for f in map(eval, DataArrays.arithmetic_operators)
        for i in 1:nrow(df)
            for j in 1:ncol(df)
                @assert f(df, 1)[i, j] == f(df[i, j], 1)
                @assert f(1, df)[i, j] == f(1, df[i, j])
            end
        end
    end

    # Binary operations on pairs of DataFrame's
    # TODO: Test in the presence of in-operable types like Strings
    N = 5
    df = DataFrame(quote
                       A = dataones($(N))
                       B = dataones($(N))
                   end)
    for f in map(eval, DataArrays.array_arithmetic_operators)
        for i in 1:nrow(df)
            for j in 1:ncol(df)
                @assert isna(f(df, df)[i, j]) && isna(df[i, j]) ||
                        f(df, df)[i, j] == f(df[i, j], df[i, j])
            end
        end
    end

    # TODO: Columnar operators on DataFrame's

    # Boolean operators on DataFrames's
    N = 5
    df = DataFrame(quote
                       A = datafalses($(N))
                   end)
    @assert any(df) == false
    @assert any(!df) == true
    @assert all(df) == false
    @assert all(!df) == true

    df = DataFrame(quote
                       A = datafalses($(N))
                   end)
    df[3, 1] = true
    @assert any(df) == true
    @assert all(df) == false

    df = DataFrame(quote
                       A = datafalses($(N))
                   end)
    df[2, 1] = NA
    df[3, 1] = true
    @assert any(df) == true
    @assert all(df) == false

    df = DataFrame(quote
                       A = datafalses($(N))
                   end)
    df[2, 1] = NA
    @assert isna(any(df))
    @assert all(df) == false

    df = DataFrame(quote
                     A = datafalses($(N))
                   end)
    df[1, 1] = NA
    @assert isna(any(df))
    @assert isna(all(df))

    # Is this a genuine special case?
    @assert isna(NA ^ 2.0)

    #
    # Equality tests
    #

    dv = DataVector[1, NA]
    df = DataFrame({dv})
    alt_df = DataFrame({alt_dv})

    # @assert isna(df == df) # SHOULD RAISE ERROR
    # @assert isna(df != df) # SHOULD RAISE ERROR

    @assert isequal(df, df)

    @assert !isequal(dv, alt_dv)
    @assert !isequal(pdv, alt_pdv)
    @assert !isequal(df, alt_df)

    @assert isequal(DataFrame({dv}) .== DataFrame({dv}), DataFrame({DataVector[true, NA]}))

    @assert all(isna(NA .== df))
    @assert all(isna(df .== NA))
end
