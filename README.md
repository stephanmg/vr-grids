# C2M2VR-Grids 
Grids for VR simulation and experiments.

# TODO
Note that mesh artifacts might still arise in two cases:
- Grid generation algorithm's render vector and very sharp kinks in geometries (The latter can be manually resolved)
- Unity seems to have trouble visualizing very thin neurites (blow up geometries work) or the thin meshes are defective

## New cells
- Current cells which can be used within the Unity project.

### Y-geometries
- Simple Y-branching geometries

### Full neuron geometries
- Full neuron geometries with 1d and 2d geometries as well as refinements of the 1d mesh

### Cylinders
- Cylinders with a length of 100 units, with *varying degree of grid resolution*, radius of cylinder is 1.

## Old cells
- A collection of old cells which might be defective in some way and are used to improve grid generation algorithm.
Some of them might be still generated with the interpolating grid generation algorithm: Cells 1, 2 and 3.

### Grid hierarchy
- Test 1d cell in 2d surface cell with some refinements. 1d refinements are contained within the 2d surface mesh.

### Test
- Cells to debug mesh artifacts (Thin dendrites, Twists, Face orientation)

## Code
- `scale_dend.rb` scales SWC files but do not scale soma. Alternatively a blow-up factor parameter is introduced in the
underlying ug4 grid generation algorithm to allow to blow up dendrites (neurites and axons, but not soma).

# Grid generation pipeline 
All points written down here which are not automatized so far will be added to the ug4 grid generation algorithm.
- (Scale SWC file with *scale_dend.rb*)
- Refine SWC grid with ug4 (*refine_swc_grid(...)*)
- Create surfaces meshes from SWC file, and, this writes the new SWC file within the 2d surface
- Save as OBJ files or UGX files
- Fix face orientation with ProMesh (Will be incorporated into pipeline)
