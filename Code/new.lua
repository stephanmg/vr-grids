-- ug init
ug_load_script("ug_util.lua")
ug_load_script("util/load_balancing_util.lua")
InitUG(3, AlgebraType("CPU", 1))

-- load domain
dom = Domain()
dom:create_additional_subset_handler("projSH")
--LoadDomain(dom, "imported_y_structure.ugx")
--LoadDomain(dom, "cylinder3.ugx")
--LoadDomain(dom, "cylinder4.ugx") -- with fix edge orientation
LoadDomain(dom, "after_selecting_boundary_elements_with_projector.ugx")

-- refine axial
numRefinements = 1
axialMarker = NeuriteAxialRefinementMarker(dom)
refiner = HangingNodeDomainRefiner(dom)
axialMarker:mark(refiner)
refiner:refine()
--[[
axialMarker:mark(refiner)
refiner:refine()
axialMarker:mark(refiner)
refiner:refine()
axialMarker:mark(refiner)
refiner:refine()
axialMarker:mark(refiner)
refiner:refine()
--]]
AddMappingAttachmentHandlerToGrid(dom)

-- save 3d grid hierarchy
SaveGridHierarchyTransformed(dom:grid(), dom:subset_handler(), "refined_" .. numRefinements .. ".ugx", 3.0)
-- save coarse and refined 3d grid levels as 1d meshes
Write3dMeshTo1d(dom, 1)
