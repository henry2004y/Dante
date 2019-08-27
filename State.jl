module State

export set_init, update_state!, plotvar

using ..Parameters: Param, Rho_, Ux_, Uy_, Uz_, Bx_, By_, Bz_, P_, E_, U_, B_
using ..Parameters: γ
using ..Flux: FaceFlux

using PyPlot


function set_init(param::Param)

   FullSize = param.FullSize
   nVar = param.nVar

   state_GV = zeros(FullSize[1],FullSize[2],FullSize[3], nVar)

   density  = @view state_GV[:,:,:,Rho_]
   velocity = @view state_GV[:,:,:,U_]
   B        = @view state_GV[:,:,:,B_]
   pressure = @view state_GV[:,:,:,P_]

   nI,nJ,nK,nG = param.nI, param.nJ, param.nK, param.nG

   if param.IC == "contact discontinuity"
      density[1:floor(Int,nI/2),:,:] .= 2.0
      density[floor(Int,nI/2+1):end,:,:] .= 1.0

      velocity .= 0.0
      velocity .*= density
      pressure .= 1.0

   elseif param.IC == "density wave"
      density .= 1.0
      density[floor(Int,nI/2):floor(Int,nI/2),:,:] .= 2.0
      velocity[:,:,:,1] .= 1.0
      velocity .*= density
      pressure .= 0.01
   elseif param.IC == "shocktube"

   elseif param.IC == "square wave"
      density .= 1.0
      density[floor(Int,nI/2)-10:floor(Int,nI/2),:,:] .= 2.0
      velocity[:,:,:,1] .= 1.0
      velocity .*= density
      pressure .= 0.01
   elseif param.IC == "Riemann"
      # Make this into a separate function!
      if param.RiemannProblemType == 1
         println("Case 1: Sods problem")
         p   = [1.0, 0.1]
         u   = [0.0, 0.0]
         rho = [1.0, 0.125]
         tEnd, CFL = 0.1, 0.9 # I need to think of how to set this!!!
      elseif param.RiemannProblemType == 2
         println("Case 2: Left Expansion and right strong shock")
         p   = [1000.0, 0.1]
         u   = [0.0   , 0.0]
         rho = [3.0   , 2.0]
         tEnd, CFL = 0.02, 0.9
      elseif param.RiemannProblemType == 3
         println("Case 3: Right Expansion and left strong shock")
         p   = [7.0, 10.0]
         u   = [0.0, 0.0 ]
         rho = [1.0, 1.0 ]
         tEnd, CFL = 0.1, 0.9
      elseif param.RiemannProblemType == 4
         println("Case 4: Double Shock")
         p   = [450.0, 45.0  ]
         u   = [20.0 , -6.0  ]
         rho = [6.0  ,  6.0  ]
         tEnd, CFL = 0.01, 0.90
      elseif param.RiemannProblemType == 5
         println("Case 5: Double Expansion")
         p   = [40.0,  40.0 ]
         u   = [-2.0,  2.0  ]
         rho = [1.0 ,  2.5  ]
         tEnd, CFL = 0.03, 0.90
      elseif param.RiemannProblemType == 6
         println("Case 6: Cavitation")
         p   = [0.4 , 0.4]
         u   = [-2.0, 2.0]
         rho = [ 1.0, 1.0]
         tEnd, CFL = 0.1, 0.90
      elseif param.RiemannProblemType == 7
         println("Shocktube problem of G.A. Sod, JCP 27:1, 1978")
         p   = [1.0 , 0.1  ]
         u   = [0.75, 0.0  ]
         rho = [1.0 , 0.125]
         tEnd, CFL = 0.17, 0.90
      elseif param.RiemannProblemType == 8
         println("Lax test case: M. Arora and P.L. Roe: JCP 132:3-11, 1997")
         p   = [3.528, 0.571]
         u   = [0.698, 0    ]
         rho = [0.445, 0.5  ]
         tEnd, CFL = 0.15, 0.90
      elseif param.RiemannProblemType == 9
         println("Mach = 3 test case: M. Arora and P.L. Roe: JCP 132:3-11, 1997")
         p   = [10.333,  1.0  ]
         u   = [ 0.92 ,  3.55 ]
         rho = [3.857 ,  1.0  ]
         tEnd, CFL = 0.09, 0.90
      elseif param.RiemannProblemType == 10
         println("Shocktube problem with supersonic zone")
         p   = [1.0,  0.02]
         u   = [0.0,  0.00]
         rho = [1.0,  0.02]
         tEnd, CFL = 0.162, 0.90
      elseif param.RiemannProblemType == 11
         println("Contact discontinuity")
         p   = [0.5, 0.5]
         u   = [0.0, 0.0]
         rho = [1.0, 0.6]
         tEnd, CFL = 1.0, 0.90
      elseif param.RiemannProblemType == 12
         println("Stationary shock")
         p   = [ 1.0,  0.1 ]
         u   = [-2.0, -2.0 ]
         rho = [ 1.0, 0.125]
         tEnd, CFL = 0.1, 0.28
      else
         error("RiemannProblemType not known!")
      end
      # Print for Riemann Problems
      println("")
      println("density (L): $(rho[1])")
      println("velocity(L): $(u[1])")
      println("Pressure(L): $(p[1])")
      println("")
      println("density (R): $(rho[2])")
      println("velocity(R): $(u[2])")
      println("Pressure(R): $(p[2])")

      # Initial Condition for our 1D domain
      # Density
      density[1:floor(Int,nI/2)+nG,:,:] .= rho[1] # region 1
      density[floor(Int,nI/2+1)+nG:end,:,:] .= rho[2] # region 2
      # Velocity in x
      velocity[1:floor(Int,nI/2)+nG,:,:,1] .= u[1] # region 1
      velocity[floor(Int,nI/2+1)+nG:end,:,:,1] .= u[2] # region 2
      # Pressure
      pressure[1:floor(Int,nI/2)+nG,:,:] .= p[1] # region 1
      pressure[floor(Int,nI/2+1)+nG:end,:,:] .= p[2] # region 2

   else
      error("unknown initial condition type!")
   end

   return state_GV
end

"""Time-accurate version."""
function update_state!(param::Param, state_GV::Array{Float64,4}, dt::Float64,
   faceFlux::FaceFlux, source_GV::Array{Float64,4})

   Flux_XV = faceFlux.Flux_XV
   Flux_YV = faceFlux.Flux_YV
   Flux_ZV = faceFlux.Flux_ZV

   CellSize_D = param.CellSize_D
   iMin, iMax, jMin, jMax, kMin, kMax =
      param.iMin, param.iMax, param.jMin, param.jMax, param.kMin, param.kMax
   nVar = param.nVar
   nI,nJ,nK,nG = param.nI, param.nJ, param.nK, param.nG

   if param.TypeGrid == "Cartesian"
      # No need for volume and face if the grid is uniform Cartesian
      if !param.UseConservative
         @inbounds for iVar=1:nVar, k=1:nK, j=1:nJ, i=1:nI
            state_GV[i+nG,j+nG,k+nG,iVar] -= dt*( source_GV[i,j,k,iVar] +
            (Flux_XV[i+1,j,k,iVar] - Flux_XV[i,j,k,iVar])/CellSize_D[1] +
            (Flux_YV[i,j+1,k,iVar] - Flux_YV[i,j,k,iVar])/CellSize_D[2] +
            (Flux_ZV[i,j,k+1,iVar] - Flux_ZV[i,j,k,iVar])/CellSize_D[3])
         end
      else
         @inbounds for k=kMin:kMax, j=jMin:jMax, i=iMin:iMax
            u = state_GV[i,j,k,Ux_]^2 + state_GV[i,j,k,Uy_]^2 +
               state_GV[i,j,k,Uz_]^2
            b = state_GV[i,j,k,Bx_] + state_GV[i,j,k,By_] + state_GV[i,j,k,Bz_]

            state_GV[i,j,k,E_] = state_GV[i,j,k,P_]/(γ-1.0) +
               0.5/state_GV[i,j,k,Rho_]*u + 0.5*b
         end

         @inbounds for iVar=Rho_:Bz_, k=1:nK, j=1:nJ, i=1:nI
            state_GV[i+nG,j+nG,k+nG,iVar] -= dt*(source_GV[i,j,k,iVar] +
            (Flux_XV[i+1,j,k,iVar] - Flux_XV[i,j,k,iVar])/CellSize_D[1] +
            (Flux_YV[i,j+1,k,iVar] - Flux_YV[i,j,k,iVar])/CellSize_D[2] +
            (Flux_ZV[i,j,k+1,iVar] - Flux_ZV[i,j,k+1,iVar])/CellSize_D[3])
         end

         @inbounds for k=1:nK, j=1:nJ, i=1:nI
            u = state_GV[i+nG,j+nG,k+nG,Ux_]^2 + state_GV[i+nG,j+nG,k+nG,Uy_]^2 +
               state_GV[i+nG,j+nG,k+nG,Uz_]^2
            b = state_GV[i+nG,j+nG,k+nG,Bx_]^2 + state_GV[i+nG,j+nG,k+nG,By_]^2 +
               state_GV[i+nG,j+nG,k+nG,Bz_]^2

            state_GV[i+nG,j+nG,k+nG,E_] -= dt*(source_GV[i,j,k,E_] +
               (Flux_XV[i+1,j,k,E_] - Flux_XV[i,j,k,E_])/CellSize_D[1] +
               (Flux_YV[i,j+1,k,E_] - Flux_YV[i,j,k,E_])/CellSize_D[2] +
               (Flux_ZV[i,j,k+1,E_] - Flux_ZV[i,j,k,E_])/CellSize_D[3])

            state_GV[i+nG,j+nG,k+nG,P_] = (γ-1.0)*(state_GV[i+nG,j+nG,k+nG,E_] -
               0.5/state_GV[i+nG,j+nG,k+nG,Rho_]*u - 0.5*b)
         end
      end
   else
      # Need volume and face
      state_GV .= 0.0
   end

end

"""Local timestepping version. """
function update_state!(param::Param, state_GV::Array{Float64,4},
   dt::Array{Float64,3}, faceFlux::FaceFlux, source_GV::Array{Float64,4})

   Flux_XV = faceFlux.Flux_XV
   Flux_YV = faceFlux.Flux_YV
   Flux_ZV = faceFlux.Flux_ZV

   CellSize_D = param.CellSize_D
   iMin, iMax, jMin, jMax, kMin, kMax =
      param.iMin, param.iMax, param.jMin, param.jMax, param.kMin, param.kMax
   nVar = param.nVar
   nI,nJ,nK,nG = param.nI, param.nJ, param.nK, param.nG

   if param.TypeGrid == "Cartesian"
      # No need for volume and face if the grid is uniform Cartesian
      if !param.UseConservative
         @inbounds for iVar=1:nVar, k=1:nK, j=1:nJ, i=1:nI
            state_GV[i+nG,j+nG,k+nG,iVar] -= dt[i,j,k]*( source_GV[i,j,k,iVar] +
            (Flux_XV[i+1,j,k,iVar] - Flux_XV[i,j,k,iVar])/CellSize_D[1] +
            (Flux_YV[i,j+1,k,iVar] - Flux_YV[i,j,k,iVar])/CellSize_D[2] +
            (Flux_ZV[i,j,k+1,iVar] - Flux_ZV[i,j,k,iVar])/CellSize_D[3])
         end
      else
         @inbounds for k=kMin:kMax, j=jMin:jMax, i=iMin:iMax
            u = state_GV[i,j,k,Ux_]^2 + state_GV[i,j,k,Uy_]^2 +
               state_GV[i,j,k,Uz_]^2
            b = state_GV[i,j,k,Bx_] + state_GV[i,j,k,By_] + state_GV[i,j,k,Bz_]

            state_GV[i,j,k,E_] = state_GV[i,j,k,P_]/(γ-1.0) +
               0.5/state_GV[i,j,k,Rho_]*u + 0.5*b
         end

         @inbounds for iVar=Rho_:Bz_, k=1:nK, j=1:nJ, i=1:nI
            state_GV[i+nG,j+nG,k+nG,iVar] -= dt[i,j,k]*(source_GV[i,j,k,iVar] +
            (Flux_XV[i+1,j,k,iVar] - Flux_XV[i,j,k,iVar])/CellSize_D[1] +
            (Flux_YV[i,j+1,k,iVar] - Flux_YV[i,j,k,iVar])/CellSize_D[2] +
            (Flux_ZV[i,j,k+1,iVar] - Flux_ZV[i,j,k+1,iVar])/CellSize_D[3])
         end

         @inbounds for k=1:nK, j=1:nJ, i=1:nI
            u = state_GV[i+nG,j+nG,k+nG,Ux_]^2 + state_GV[i+nG,j+nG,k+nG,Uy_]^2 +
               state_GV[i+nG,j+nG,k+nG,Uz_]^2
            b = state_GV[i+nG,j+nG,k+nG,Bx_]^2 + state_GV[i+nG,j+nG,k+nG,By_]^2 +
               state_GV[i+nG,j+nG,k+nG,Bz_]^2

            state_GV[i+nG,j+nG,k+nG,E_] -= dt[i,j,k]*(source_GV[i,j,k,E_] +
               (Flux_XV[i+1,j,k,E_] - Flux_XV[i,j,k,E_])/CellSize_D[1] +
               (Flux_YV[i,j+1,k,E_] - Flux_YV[i,j,k,E_])/CellSize_D[2] +
               (Flux_ZV[i,j,k+1,E_] - Flux_ZV[i,j,k,E_])/CellSize_D[3])

            state_GV[i+nG,j+nG,k+nG,P_] = (γ-1.0)*(state_GV[i+nG,j+nG,k+nG,E_] -
               0.5/state_GV[i+nG,j+nG,k+nG,Rho_]*u - 0.5*b)
         end
      end
   else
      # Need volume and face
      state_GV .= 0.0
   end

end

function plotvar(param::Param, it::Int, state_GV::Array{Float64,4})

   # Now this only works for 1D x!
   iMin, iMax, jMin, jMax, kMin, kMax =
   param.iMin, param.iMax, param.jMin, param.jMax, param.kMin, param.kMax

   plotvar = param.PlotVar
   nG = param.nG

   if plotvar == "rho"
      var = @view state_GV[:,:,:,Rho_]
   elseif plotvar == "ux"
      var = @view state_GV[:,:,:,Ux_]
   elseif plotvar == "p"
      var = @view state_GV[:,:,:,P_]
   else
      error("unknown plotting varname!")
   end

   x = param.x[1+nG:end-nG]

   var = @view var[iMin:iMax,jMin:jMax,kMin:kMax] # Remove ghost cells

   var = dropdims(var; dims=(2,3))

   #figure()
   plot(x,var,marker=".")

   title("iStep=$(it)")
   legend(labels=[plotvar])
end

end
