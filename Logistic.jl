module Logistic
    export LogisticRegression
    using StatsBase

    type LogisticRegression{T <: FloatingPoint} <: StatsBase.RegressionModel
        Xt::Matrix{T}
        y::Vector{T}
        wt::Vector{T}
        β::Vector{T}
        δβ::Vector{T}
        βnew::Vector{T}
        L::Matrix{T}
        XtWr::Vector{T}
        fit::Bool
    end

    function LogisticRegression{T<:FloatingPoint}(Xt::Matrix{T},y::Vector{T},wt::Vector{T})
        p,n = size(Xt)
        length(y) == n || throw(DimensionMismatch(""))
        length(wt) == 0 || length(wt) == n || throw(DimensionMismatch(""))
        LogisticRegression(Xt, y, wt, zeros(T,p), Array(T,p), Array(T,p),
                           Array(T,(p,p)),Array(T,p),false)
    end
    LogisticRegression{T<:FloatingPoint}(Xt::Matrix{T},y::Vector{T}) =
        LogisticRegression(Xt,y,Array(T,(0,)))

    function XtWXXtWr!{T<:FloatingPoint}(XtWX::Matrix{T},XtWr::Vector{T},
        Xt::Matrix{T},β::Vector{T},y::Vector{T},wt::Vector{T})
                         # check arguments
        p,n = size(Xt); r,s = size(XtWX)
        p == r == s == length(β) == length(XtWr) || throw(DimensionMismatch(""))
        n == length(y) || throw(DimensionMismatch(""))
                         # initialize output arrays and deviance
        fill!(XtWX,zero(T))
        fill!(XtWr,zero(T))
        dev = zero(T)
        haswts = length(wt) == n

        for i in 1:n
            η = zero(T)
            for j in 1:p
                η += Xt[j,i] * β[j]
            end
            μ = inv(one(T) + exp(-η))
            omμ = one(T) - μ
            yi = y[i]
            omyi = one(T) - yi
            wi = haswts ? wt[i] : one(T)
            dev += wi * (xlogy(yi,yi/μ) + xlogy(omyi,omyi/omμ))
            μη = μ * omμ
            W = wi * μη
            for j in 1:p
                for ii in j:p  # lower triangle of XtWX
                    XtWX[ii,j] += W*Xt[j,i]*Xt[ii,i]
                end
                XtWr[j] += wi*Xt[j,i]*(yi - μ)
            end
        end
        dev
    end

    Base.size(m::LogisticRegression) = size(m.Xt)

    XtWXXtWr!(m::LogisticRegression) = XtWXXtWr!(m.L, m.XtWr, m.Xt, m.βnew, m.y, m.wt)

    @doc "`fma!` performs a fused multiply and add in place" ->
    function fma!{T<:FloatingPoint}(dest::Array{T},s1::Array{T},f::T,s2::Array{T})
        (k = length(dest)) == length(s1) == length(s2) || throw(DimensionMismatch(""))
        @simd for i in 1:k
            @inbounds dest[i] = s1[i] + f*s2[i]
        end
        dest
    end

    function StatsBase.fit{T}(m::LogisticRegression{T};
                              verbose=false, # optional named arguments
                              minStepFac=convert(T,1.e-4),
                              convTol=convert(T,1.e-6))
        m.fit && return m

        p,n = size(m)
        cvg = false
        devold = XtWXXtWr!(m)
        A_ldiv_B!(cholfact!(m.L),copy!(m.δβ, m.XtWr))
        for i in 1:30
            f = 1.0
            for j in 1:p
                m.βnew[j] = m.β[j] + f * m.δβ[j]
            end
            dev = XtWXXtWr!(m)
            while dev > devold
                f /= convert(T,2.)
                f > minStepFac || error("step-halving failed at β = $(β)")
                fma!(m.βnew, m.β, f, m.δβ)
                dev = XtWXXtWr!(m)
            end
            copy!(m.β, m.βnew)
            crit = (devold - dev)/dev
            verbose && println("$i: $dev, $crit")
            if crit < convTol
                cvg = true
                break
            end
            devold = dev
            A_ldiv_B!(cholfact!(m.L),copy!(m.δβ, m.XtWr))
        end
        cvg || error("failure to converge in $maxIter iterations")
        m.fit = true
        m
    end

end
