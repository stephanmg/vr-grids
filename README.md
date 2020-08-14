# C2M2VR-Grids 
Tools and grid generation scripts for creating VR-ready Unity meshes from neuron 
morphologies stored in SWC format in a  publicly available database of neuronal 
morphologies at [NeuroMorpho](http://neuromorpho.org).

<strong>Attention:</strong> Temporarily grids are stored
 [here](https://temple.app.box.com/folder/116445648846) (Comparison of additional
 points in between branching points or not) and 
[there](https://temple.app.box.com/folder/116203752704) (Full cell geometries 
with blown up meshes, HINES ordering and 1d grid hierarchies with spline (sub)-sampling)

[![Build Status Linux](https://travis-ci.org/stephanmg/vr-grids.svg?branch=development)](https://travis-ci.org/stephanmg/vr-grids)
[![Build Status OSX](https://travis-ci.org/stephanmg/vr-grids.svg?branch=development)](https://travis-ci.org/stephanmg/vr-grids)
[![Build status Windows](https://ci.appveyor.com/api/projects/status/5h2sb2s05auy13uc?svg=true)](https://ci.appveyor.com/project/stephanmg/vr-grids)


## HOWTO generate grids

### Prerequisites
Follow installation instructions for *ug4* from [here](https://github.com/ug4/ughub) 
with the plugin *neuro_collection* installed and enabled from [there](https://github.com/NeuroBox/neuro_collection).
For Windows installations a working WSL or Cygwin environment is required to 
run the VR pipeline script (Sh/Bash) only. Currently a platform independent 
VRL-Studio project is developed and found [here](https://github.com/c2m2/VRL-VRN-Generator).

Optional is the installation of the NeuroMorpho.org REST API from [here](https://github.com/NeuroBox3D/neuromorpho)
to retrieve `SWC` files from the database:

`python get_swc.py --name 44-4`

(This will retrieve the file 44-4 from *NeuroMorpho.Org* database to be used in mesh generation.


### Database and cell requirements
Cells will be packaged in a *.vrn* file if passes all automatic geometry checks. 
Cells from *NeuroMorpho.org* need to be acyclic (Physiologically not meaningful!) and should not contain four fold
branching or more or root branches at the soma. (Both conditions are checked during grid generation and an 
appropriate error message is printed)  Inflated geometries might look "clunky" 
at branching points, depending on the inflation factor and the success of the 
branching point optimization is not always guaranteed (Newton-alike optimization)
The user will be warned and no grid will be generated at all if the checks do not pass.

### Usage

`pipeline_vr.sh -i <INPUT_PATTERN> -o <OUTPUT_FOLDER> -s1 <SEGMENT_LENGTH_1D>
			 [-s2 <SEGMENT_LENGTH_3D>] [-c1 <CREATE_1D>] [-c3 <CREATE_3D>] [-d <DEBUG>] [-q <QUIET>]
			 [-m1 <METHOD_1D>] [-m2 <METHOD_3D>] [-a <REMOVE_ATTACHMENTS>] [-v <FOR_VR>]
			 [-p <PRE_SMOOTH>] [-r <REFINEMENT>] [-f <FORCE_SPLIT_EDGE>] [-b <INFLATE_MESH>]`

Basic usage (Single input file and output to NewCell folder):

`./pipeline_vr.sh -i 44-4.CNG_original.swc -o NewCell/`

Note, that the option `-a false` removes the attachments for visualization in ProMesh 
and writes additional meshes with the suffix *_wo_attachments*.

`./pipeline_vr.sh -i 44-4.CNG_original.swc -o NewCell/ -a false`


Extended usage:

`./pipeline_vr.sh -i 37-4a.original.swc -o NewCells/ -s1 "-1"  -s2 -1 -c1 true -c3 true -m1 min -m2 identity -a true -p true -r true -f false -b false -v true`

This will output the 1d regularization, 1d refinements, blown up meshes in HINES format 
with and without attachment data to the provided folder NewCells (Folder must not 
exist before) The regularization will be done with minimum edge length between 
branching points unless the user specifies an alternative edge length themself
for regularization.

Usually it suffices to keep the default parameters (Which are shown above explicitly) and invoke the following to achieve the same as above:

## Test
A temporary folder to put in cells for checking if they fullfill all prerequisites on the mesh quality.
 If the test cells pass the algorithmic quality checks and the visual quality checks in ProMesh and Unity as well, 
then these will be moved to the main virtual-reality project repository StreamingAssets folder found
 [over here](https://github.com/c2m2/virtual-reality/tree/development/Assets/StreamingAssets/NeuronalDynamics)
Defective cells will be stored in the folder *Defective Cells* as a backup.

## Cells 
Currently usable cells (no blowups and no refinements) which should be free from defects
 (These cells are replicated in the main VR project repository 
[here](https://github.com/c2m2/virtual-reality/tree/development/Assets/StreamingAssets/NeuronalDynamics)

## Full Cells (with Blowups and Refinements)
The same as *Cells* above but with blowups and refinements found in *Full Cells*.

## Cylinders 
Cylinders with a length of 100 units, with *varying degree of grid resolution*, radius of cylinder is 1.

### Y-geometries
Two way branches generated from SWC files.

## Defective cells
A collection of previously used cells, which suffer from grid artifacts and other defects. 1d grid hierarchies
contained (Regularly refined 1d grids) and the corresponding 2d surface meshes. Test folder includes grids
used to debug mesh artifacts (Thin dendrites, Twists and False Face Orientation)

## Code
- `pipeline_vr.sh`: The main grid generation pipeline. Generates a hierarchy of 1D
 and 2D surface meshes and inflated 2D surface meshes. HINES ordering of the graph
is ensured. Refinements are generated by sub-sampling the splines defined on the 
points of the original 1D SWC geometry in prescribed arclength by the user or as
the minimum distance between branching points leading to regularized or quasi 
uniform edge length distribution.
- `coarsen.sh`: Grid coarsening based on the 1D SWC mesh without using splines
- `sparse.py`: Matplotlib script to visualize sparsity pattern of 1D graphs
- `edges.py`: Creates plots of edge length statistics (boxplots and histograms)
of the original and regularized 1D meshes.
- `remove_attachments.sh`: Removes attachments if they might not be readable by ProMesh

[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)
