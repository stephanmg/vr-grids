# C2M2VR-Grids 
Grids for VR simulation and experiments.

# TODO
Note that mesh artifacts might still arise in two cases:
- Grid generation algorithm's render vector and very sharp kinks in geometries (The latter can be manually resolved)
- Unity seems to have trouble visualizing very thin neurites (blow up geometries work)

## Cylinders
Cylinders with a length of 100 units, with *varying degree of grid resolution*, radius of cylinder is 1.

## Cells
Cells with *varying diameters*, scaled by a factor of 1:10, 1:100, 1:1000.
Currently two cells, CA1 Pyramidal (CA1) and Calretinin (CR).

## Grid hierarchy
1d cell in 2d surface cell with some refinements. 1d refinements are contained within the 2d surface mesh.

## Y-geometries
Simple Y-branching geometries to debug mesh artifacts.

## Test
Test geoemtries to debug mesh artifacts (Full 2d surface / neuron geometries)

## Code
`scale_dend.rb` scales SWC files but do not scale soma. Alternatively a blow-up factor parameter is introduced in the
underlying ug4 grid generation algorithm to allow to blow up dendrites (neurites and axons, but not soma).

# Pipeline 
All points written down here which are not automatized so far will be added to the ug4 grid generation algorithm.
- (Scale SWC file with *scale_dend.rb*)
- Refine SWC grid with ug4 (*refine_swc_grid(...)*)
- Create surfaces meshes from SWC file, and, this writes the new SWC file within the 2d surface
- Save as OBJ files or UGX files
- Fix face orientation with ProMesh (Will be incorporated into pipeline)
