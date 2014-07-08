using GLM,RDatasets,ProfileView

ls = dataset("datasets","LifeCycleSavings")
m1 = lm(SR ~ Pop15 + Pop75 + DPI + DDPI, ls)
function boot2!(betas::Matrix, sigmas::Vector, m::LinearModel)
    qrd = m.pp.qr
    n,p = size(qrd)
    size(betas,2) == length(sigmas) && size(betas,1) == p || throw(DimensionMismatch(""))
    qmat = qrd[:Q]
    rmat = Triangular(qrd[:R],:U)
    df = float(n-p)
    d = IsoNormal(m.rr.mu, scale(m))
    y = Array(Float64,n)
    for j in 1:length(sigmas)
        Base.Ac_mul_B!(qmat,rand!(d,y))
        Base.A_ldiv_B!(rmat,copy!(sub(betas,:,j),sub(y,1:p)))
        sigmas[j] = sqrt(Base.sumabs2(sub(y,(p+1):n))/df)
    end
    betas, sigmas
end

function boot2(m::LinearModel, nsim::Integer)
    boot(Array(Float64,(size(m.pp.qr,2),nsim)),Array(Float64,nsim),m)
end

using ArrayViews
function boot3!(betas::Matrix, sigmas::Vector, m::LinearModel)
    qrd = m.pp.qr
    n,p = size(qrd)
    size(betas,2) == length(sigmas) && size(betas,1) == p || throw(DimensionMismatch(""))
    qmat = qrd[:Q]
    rmat = Triangular(qrd[:R],:U)
    df = float(n-p)
    d = IsoNormal(m.rr.mu, scale(m))
    y = Array(Float64,n)
    for j in 1:length(sigmas)
        Base.Ac_mul_B!(qmat,rand!(d,y))
        Base.A_ldiv_B!(rmat,copy!(view(betas,:,j),view(y,1:p)))
        sigmas[j] = sqrt(Base.sumabs2(view(y,(p+1):n))/df)
    end
    betas, sigmas
end
function boot3(m::LinearModel, nsim::Integer)
    boot3!(Array(Float64,(size(m.pp.qr,2),nsim)),Array(Float64,nsim),m)
end

betas = zeros(5,100_000)
sigmas = zeros(100_000)
boot3!(zeros(5,1), zeros(1), m1.model)  # force compilation

srand(1234321); gc()
@profile boot3!(betas, sigmas, m1.model)
