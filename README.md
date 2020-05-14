# C2M2VR-Grids 
Grids for VR simulation and experiments.

## Cells
Currently usable cells which should be free from defects

### Y-geometries
Simple Y-branching geometries

### Full geometries
Full neuron geometries with 1d and 2d geometries as well as refinements of the 1d mesh with the current VR grid generation methods.
For a more detailed description of the full geometries see the corresponding *README.md* in the folder

### Cylinders
Cylinders with a length of 100 units, with *varying degree of grid resolution*, radius of cylinder is 1.

## Deprecated
A collection of previously used cells, which suffer from grid artifacts and other defects. 1d grid hierarchies
contained (Regularly refined 1d grids) and the corresponding 2d surface meshes. Test folder includes grids
used to debug mesh artifacts (Thin dendrites, Twists and False Face Orientation)

## Code
- `scale_dend.rb` scales SWC files but do not scale soma.
Scaling of dendrites (neurites and axons) is now incorporated in the grid generation algorithm
- `pipeline.sh` the main routine to create meshes in ug4
The file has to be used with a valid ug4 installation
