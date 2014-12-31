const RHOME = chomp(readall(`R RHOME`))

ENV["LD_LIBRARY_PATH"] =
    "/usr/lib/R/lib:/usr/lib/x86_64-linux-gnu:/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/amd64/server"
ENV["R_HOME"] = RHOME
ENV["R_DOC_DIR"] = "/usr/share/R/doc"
ENV["R_INCLUDE_DIR"] ="/usr/share/R/include"
ENV["R_SHARE_DIR"] = "/usr/share/R/share"

const libR = joinpath(RHOME,"lib","libR.so")

# R internal name for a pointer to a symbolic expression (SEXPREC) structure
# For the time being we will make it Ptr{Void}.  Later we can create an SEXPREC
# type
typealias SEXP Ptr{Void}

@doc """Initialize an embedded R. Sample usage: initR(["Rembed","--silent"])""" ->
function initR(argv::Vector{ASCIIString})
    i = ccall((:Rf_initEmbeddedR,libR),Cint,(Cint,Ptr{Ptr{Uint8}}),
              length(argv),argv)
    i > 0 ? i : error("Failure to initialize embedded R")
end

@doc "return the first element of an SEXP as an Cint (i.e. Int32)" ->
asInteger(s::SEXP) = ccall((:Rf_asInteger,libR),Cint,(SEXP,),s)

@doc "return the first element of an SEXP as a Bool" ->
asLogical(s::SEXP) = ccall((:Rf_asLogical,libR),Bool,(SEXP,),s)

@doc "return the first element of an SEXP as a Cdouble (i.e. Float64)" ->
asReal(s::SEXP) = ccall((:Rf_asReal,libR),Cdouble,(SEXP,),s)

@doc "Symbol lookup for R, installing the symbol if necessary" ->
install(nm::ASCIIString) = ccall((:Rf_install,libR),SEXP,(Ptr{Uint8},),nm)

## predicates applied to an SEXP
for sym in (:isArray,:isComplex,:isEnvironment,:isExpression,:isFactor,
            :isFrame,:isFree,:isFunction,:isInteger,:isLanguage,:isList,
            :isLogical,:isSymbol,:isMatrix,:isNewList,:isNull,:isNumeric,
            :isNumber,:isObject,:isOrdered,:isPairList,:isPrimitive,
            :isReal,:isS4,:isString,:isTs,:isUnordered,:isUnsorted,
            :isUserBinop,:isValidString,:isValidStringF,:isVector,
            :isVectorAtomic,:isVectorizable,:isVectorList)
    @eval $sym(s::SEXP) = ccall(($(string("Rf_",sym)),libR),Bool,(SEXP,),s)
end

Base.length(s::SEXP) = ccall((:Rf_length,libR),Cint,(SEXP,),s)

@doc "Create a string SEXP of length 1" ->
mkString(st::ASCIIString) = ccall((:Rf_mkString,libR),SEXP,(Ptr{Uint8},),st)

@doc "print the value of an SEXP"->
printValue(sexp::SEXP) = ccall((:Rf_PrintValue,libR),Void,(SEXP,),sexp)

@doc "Create an integer SEXP of length 1" ->
scalarInteger(i::Integer) = ccall((:Rf_ScalarInteger,libR),SEXP,(Cint,),i)

@doc "Create a logical SEXP of length 1" ->
scalarLogical(i::Integer) = ccall((:Rf_ScalarLogical,libR),SEXP,(Cint,),i)

@doc "Create a REAL SEXP of length 1"->
scalarReal(x::Real) = ccall((:Rf_ScalarReal,libR),SEXP,(Cdouble,),x)

@doc "Create a 0-argument function call from a symbol"->
lang1(sexp::SEXP) = ccall((:Rf_lang1,libR),SEXP,(SEXP,),sexp)

@doc "Create a 1-argument function call from a symbol and the argument"->
lang2(sxp1::SEXP,sxp2::SEXP) =
    ccall((:Rf_lang2,libR),SEXP,(SEXP,SEXP),sxp1,sxp2)

@doc "Create a 2-argument function call from a symbol and the arguments"->
lang3(sxp1::SEXP,sxp2::SEXP,sxp3::SEXP) =
    ccall((:Rf_lang3,libR),SEXP,(SEXP,SEXP,SEXP),sxp1,sxp2,sxp3)

getOptionWidth() = ccall((:Rf_GetOptionWidth,libR),Cint,())

getOptionDigits() = ccall((:Rf_GetOptionDigits,libR),Cint,())

allocS4Object() = ccall((:Rf_allocS4Object,libR),SEXP,())

@doc "Protect an SEXP from garbage collection"->
protect(s::SEXP) = ccall((:Rf_protect,libR),SEXP,(SEXP,),s)

@doc "Pop k elements off the protection stack"->
unprotect(k::Integer) = ccall((:Rf_unprotect,libR),Void,(Cint,),k)

@doc "unprotect an SEXP"->
unprotect(s::SEXP) = ccall((:Rf_unprotect_ptr,libR),Void,(SEXP,),s)

