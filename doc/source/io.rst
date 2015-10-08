Importing and Exporting (I/O)
==============

Importing data from tabular data files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To read data from a CSV-like file, use the ``readtable`` function::

    df = readtable("data.csv")

    df = readtable("data.tsv")

    df = readtable("data.wsv")

    df = readtable("data.txt", separator = '\t')

    df = readtable("data.txt", header = false)

``readtable`` requires that you specify the path of the file that you would
like to read as a ``UTF8String``. It supports many additional keyword arguments:
these are documented in the section on advanced I/O operations.

Exporting data to a tabular data file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To write data to a CSV file, use the ``writetable`` function::

    df = DataFrame(A = 1:10)

    writetable("output.csv", df)

    writetable("output.dat", df, separator = ',', header = false)

    writetable("output.dat", df, quotemark = '\'', separator = ',')

    writetable("output.dat", df, header = false)

``writetable`` requires the following arguments:

- ``filename::AbstractString`` -- The path of the file that you wish to write to.
- ``df::DataFrame`` -- The DataFrame you wish to write to disk.

Additional advanced options are documented below.

Advanced Options for Reading CSV Files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``readtable`` accepts the following optional keyword arguments:

- ``header::Bool`` -- Use the information from the file's header line to
  determine column names. Defaults to ``true``.
- ``separator::Char`` -- Assume that fields are split by the ``separator`` character.
  If not specified, it will be guessed from the filename: ``.csv`` defaults to
  ``','``, ``.tsv`` defaults to ``'\t'``, ``.wsv`` defaults to ``' '``.
- ``quotemark::Vector{Char}`` -- Assume that fields contained inside of two
  ``quotemark`` characters are quoted, which disables processing of separators and
  linebreaks. Set to ``Char[]`` to disable this feature and slightly improve
  performance. Defaults to ``['"']``.
- ``decimal::Char`` -- Assume that the decimal place in numbers is written using
  the ``decimal`` character. Defaults to ``'.'``.
- ``nastrings::Vector{ASCIIString}`` -- Translate any of the strings into this
  vector into an ``NA``. Defaults to ``["", "NA"]``.
- ``truestrings::Vector{ASCIIString}`` -- Translate any of the strings into
  this vector into a Boolean ``true``. Defaults to ``["T", "t", "TRUE", "true"]``.
- ``falsestrings::Vector{ASCIIString}`` -- Translate any of the strings into
  this vector into a Boolean ``true``. Defaults to ``["F", "f", "FALSE", "false"]``.
- ``makefactors::Bool`` -- Convert string columns into ``PooledDataVector``'s
  for use as factors. Defaults to ``false``.
- ``nrows::Int`` -- Read only ``nrows`` from the file. Defaults to ``-1``, which
  indicates that the entire file should be read.
- ``names::Vector{Symbol}`` -- Use the values in this array as the names
  for all columns instead of or in lieu of the names in the file's header. Defaults to ``[]``, which indicates that the header should be used if present or that numeric names should be invented if there is no header.
- ``eltypes::Vector{DataType}`` -- Specify the types of all columns. Defaults to ``[]``.
- ``allowcomments::Bool`` -- Ignore all text inside comments. Defaults to ``false``.
- ``commentmark::Char`` -- Specify the character that starts comments. Defaults
  to ``'#'``.
- ``ignorepadding::Bool`` -- Ignore all whitespace on left and right sides of a
  field. Defaults to ``true``.
- ``skipstart::Int`` -- Specify the number of initial rows to skip. Defaults
  to ``0``.
- ``skiprows::Vector{Int}`` -- Specify the indices of lines in the input to
  ignore. Defaults to ``[]``.
- ``skipblanks::Bool`` -- Skip any blank lines in input. Defaults to ``true``.
- ``encoding::Symbol`` -- Specify the file's encoding as either ``:utf8`` or
  ``:latin1``. Defaults to ``:utf8``.

Advanced Options for Writing CSV Files
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``writetable`` accepts the following optional keyword arguments:

- ``separator::Char`` -- The separator character that you would like to use.
  Defaults to the output of ``getseparator(filename)``, which uses commas for
  files that end in ``.csv``, tabs for files that end in ``.tsv`` and a single
  space for files that end in ``.wsv``.
- ``quotemark::Char`` -- The character used to delimit string fields. Defaults
  to ``'"'``.
- ``header::Bool`` -- Should the file contain a header that specifies the column
  names from ``df``. Defaults to ``true``.
