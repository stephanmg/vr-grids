# C2M2VR-Grids 
Grid generation scripts for creating VR-ready Unity mesh bundles in the .vrn format. The .vrn archive will include 1d and 3d meshes and refinements as well as inflations.
To retrieve 1D morphologies in the SWC format stored in publicly available database for neuronal morphologies at 
[NeuroMorpho](http://neuromorpho.org) refer to the [neuromorpho wrapper](https://github.com/NeuroBox3D/neuromorpho/).

<strong>Attention:</strong> Temporarily generated grids are stored
 [here](https://temple.app.box.com/folder/116445648846) (Comparison of additional points in between branching points or not) and 
[there](https://temple.app.box.com/folder/116203752704) (Full cell geometries with blown up meshes, HINES ordering and 1d grid hierarchies with spline (sub)-sampling)
until a more convenient location in a Cloud storage has been decided by the team.

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/716dbe2190f14dd1a636aaddeefb18ce)](https://app.codacy.com/manual/stephan_5/vr-grids?utm_source=github.com&utm_medium=referral&utm_content=stephanmg/vr-grids&utm_campaign=Badge_Grade_Dashboard)
[![Build Status Linux](https://travis-ci.org/stephanmg/vr-grids.svg?branch=development)](https://travis-ci.org/stephanmg/vr-grids)
[![Build Status OSX](https://travis-ci.org/stephanmg/vr-grids.svg?branch=development)](https://travis-ci.org/stephanmg/vr-grids)
[![Build status Windows](https://ci.appveyor.com/api/projects/status/5h2sb2s05auy13uc?svg=true)](https://ci.appveyor.com/project/stephanmg/vr-grids)
[![License: LGPL v3](https://img.shields.io/badge/License-LGPL%20v3-blue.svg)](https://www.gnu.org/licenses/lgpl-3.0)

## HOWTO generate grids

### Prerequisites
- Git
- Python
- Bash, see WSL or Cygwin for Windows
- ug4, see [ughub](https://github.com/ug4/ughub) 
- neuro_collection plugin , see [NeuroBox3D](https://github.com/NeuroBox/neuro_collection)

- vr-grids, see [vr-grids](https://github.com/stephanmg/vr-grids) 
- neuromorpho (optional), see [neuromorpho](https://github.com/NeuroBox3D/neuromorpho)

### Installation instructions

Attention: Windows users need a valid installation of Bash, i.e. either activate WSL or install Cygwin on Windows to run the grid generation routines!

1. Clone the `ughub` repository from the location above: `https://github.com/ug4/ughub.git` to install ug4.

Then follow precisely the installation instructions for *ug4* [here](https://github.com/ug4/ughub) in the README for your operating system (OS).

2. Install additional mesh generation plugin (neuro_collection):

Follow the installation instructions [here](https://github.com/ug4/ughub) to install the additional *neuro_collection* plugin required for mesh generation via:
`ughub install neuro_collection`

3. Rebuild ug4 with the *neuro_collection* plugin enabled:
`cmake -Dneuro_collection=ON
make
`

4. Acquire the VR mesh generation pipeline scripts: 

Clone the vr-grids repository from [here](https://github.com/stephanmg/vr-grids).
Navigate to the folder `Code/Scripts/` and use the script `pipeline.sh`.

5. (Optinal) use the neuromorpho REST API wrapper to download morphologiges from the NeuroMorpho.org database.

Clone the repository at https://github.com/NeuroBox3D/neuromorpho

Follow installation instructions in the repository's README above

6. Invoke the VR pipeline script to generate a mesh via:

`pipeline_vr.sh -i <INPUT_PATTERN> -o <OUTPUT_FOLDER>``

Note that `-i <INPUT_PATTERN>` specifies a SWC file name or a file glob of SWC files and `-o <OUTPUT_FOLDER>` is the output folder for generated meshes. 
In the output folder given by the `-o` parameter, also the **VRN** bundle for Unity will be stored with the same name as the input file except for the file extension is changed to `.vrn`.

### Usage 

1. Either retrieve manually a file from NeuroMorpho.org or use the *NeuroMorpho.org* REST API wrapper:

`python get_swc.py --name 44-4`

This will retrieve the file 44-4 from *NeuroMorpho.org* database which will subsequently be used in mesh generation.

Currently a VRL-Studio project is developed and found [here](https://github.com/c2m2/VRL-VRN-Generator) to allow the user to interactively and visually bundle meshes.

2. Use the `pipeline_vr.sh` scripts to create geometries

#### Example
`pipeline_vr.sh -i <INPUT_PATTERN> -o <OUTPUT_FOLDER> -s1 <SEGMENT_LENGTH_1D> [-c <BUNDLE>]
			 [-s2 <SEGMENT_LENGTH_3D>] [-c1 <CREATE_1D>] [-c3 <CREATE_3D>] [-d <DEBUG>] [-q <QUIET>]
			 [-m1 <METHOD_1D>] [-m2 <METHOD_3D>] [-a <REMOVE_ATTACHMENTS>] [-v <FOR_VR>]
			 [-p <PRE_SMOOTH>] [-r <REFINEMENT>] [-f <FORCE_SPLIT_EDGE>] [-b <INFLATE_MESH>]`

Basic usage (Single input file and output to NewCell folder):
`./pipeline_vr.sh -i 44-4.CNG_original.swc -o NewCell/`

Note, that the option `-a false` removes the attachments for visualization in ProMesh 
and writes additional meshes with the suffix *_wo_attachments*:
`./pipeline_vr.sh -i 44-4.CNG_original.swc -o NewCell/ -a false`

Note that the option `-c true` will only bundle the meshes into a *.vrn* file.
`./pipeline_vr.sh -i 44-4.CNG_original.swc -o NewCell/ -c true`

Extended usage:
`./pipeline_vr.sh -i 37-4a.original.swc -o NewCells/ -s1 "-1"  -s2 -1 -c1 true -c3 true -m1 min -m2 identity -a true -p true -r true -f false -b false -v true`

This will output the 1d regularization, 1d refinements, blown up meshes in HINES format 
with and without attachment data to the provided folder NewCells (Folder must not 
exist before) The regularization will be done with minimum edge length between 
branching points unless the user specifies an alternative edge length themself
for regularization.

Usually it suffices to keep the default parameters (Which are shown above explicitly) and invoke the following to achieve the same as above.


#### Database and cell requirements
Cells will be packaged into a *.vrn* file if and only if all geometries pass the automatic geometry consistency checks.

The 1D cells (SWC) respectively the cell topologies from *NeuroMorpho.org* need to fulfill the following conditions:
1. Cells need to be acyclic, i.e. cycles are neuroanatomically not meaningful and thus disallowed
2. Bifurcations >= 4 branches are not allowed

If any of these conditions are violated the user will be issued an error message during mesh generation.

## Test
A temporary folder to put in cells for checking if they fullfill all prerequisites on the mesh quality.
 If the test cells pass the algorithmic quality checks and the visual quality checks in ProMesh and Unity as well, 
then these will be moved to the main virtual-reality project repository StreamingAssets folder found
 [over here](https://github.com/c2m2/virtual-reality/tree/development/Assets/StreamingAssets/NeuronalDynamics)
Defective cells will be stored in the folder *Defective Cells* as a backup.

Fully working cells can be added to the CI pipeline script test (Travis/Appveyor) to ensure these still work in later revisions of the grid generation.

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
