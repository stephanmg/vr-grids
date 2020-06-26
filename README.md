# C2M2VR-Grids 
Grids for VR simulation and experiments.

<strong>Attention:</strong> Temporarily grids are stored [here](https://temple.app.box.com/folder/116445648846) and [there](https://temple.app.box.com/folder/116203752704). Repository structure will be cleaned up and obsolete folders and so forth will be removed during the next commit.

## Test
A temporary folder to put in cells for checking if they fullfill all prerequisites on the mesh quality. If the test cells pass the algorithmic quality checks and the visual quality checks in ProMesh and Unity as well, then these will be moved to the main virtual-reality project repository StreamingAssets folder found [over here](https://github.com/c2m2/virtual-reality/tree/development/Assets/StreamingAssets/NeuronalDynamics)

## Cells
Currently usable cells (no blowups and no refinements) which should be free from defects (These cells are replicated in the main VR project repository [here](https://github.com/c2m2/virtual-reality/tree/development/Assets/StreamingAssets/NeuronalDynamics)

## Full cell geometries
The same as *Cells* above but with blowups and refinements.

## Cylinders 
Cylinders with a length of 100 units, with *varying degree of grid resolution*, radius of cylinder is 1.

### Y-geometries (Obsolete)
Two way branches generated from SWC files.

## Deprecated (Obsolete)
A collection of previously used cells, which suffer from grid artifacts and other defects. 1d grid hierarchies
contained (Regularly refined 1d grids) and the corresponding 2d surface meshes. Test folder includes grids
used to debug mesh artifacts (Thin dendrites, Twists and False Face Orientation)

## Code
- `pipeline2new.sh` creates 1d refined meshes in HINES and 2d blown up meshes with spline subsampling (Will be renamed soon)
- `scale_dend.rb` scales SWC files but do not scale soma (Obsolete)
Scaling of dendrites (neurites and axons) is now incorporated in the grid generation algorithm
- `pipeline.sh` the main routine to create meshes in ug4. The file has to be used with a valid ug4 installation (Obsolete)
- `coarsen.sh` coarsens the 1d geometry
- `refine_var.sh` refines the 1d geometry and reorders to HINEs type
- `write_swc.pl` helper script (Obsolete)
