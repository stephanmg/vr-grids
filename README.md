# C2M2VR-Grids 
Grids for VR simulation and experiments.

<strong>Attention:</strong> Temporarily grids are stored [here](https://temple.app.box.com/folder/116445648846) and [there](https://temple.app.box.com/folder/116203752704). Repository structure will be cleaned up and obsolete folders and so forth will be removed during the next commit, also scripts which are deprecated are removed then.

## HOWTO generate grids
Using the provided `pipeline2.new.sh` script one can take a SWC file from the *NeuroMorpho* database and call it by:

`./pipeline2new.sh -i 37-4a.original.swc -o NewCells/ -s1 "-1"  -s2 -1 -c1 true -c3 true -m1 min -m2 identity -a true -p true -r true -f false -b false`

This will output the 1d regularization, 1d refinements, blown up meshes in HINES format with and without attachment data to the provided folder NewCells. The regularization will be done with minimum edge length between branching points.

Usually it suffices to keep the default parameters (Which are shown above explicitly) and invoke the following to achieve the same as above:

`./pipeline2new.sh -i 37-4a.CNG_original.swc -o NewCells/ -s1 -1`

### Usage
`pipeline2new.sh -i <INPUT_PATTERN> -o <OUTPUT_FOLDER> -s1 <SEGMENT_LENGTH_1D>
			 [-s2 <SEGMENT_LENGTH_3D>] [-c1 <CREATE_1D>] [-c3 <CREATE_3D>]
			 [-m1 <METHOD_1D>] [-m2 <METHOD_3D>] [-a <REMOVE_ATTACHMENTS>]
			 [-p <PRE_SMOOTH>] [-r <REFINEMENT>] [-f <FORCE_SPLIT_EDGE>] [-b <INFLATE_MESH>]`

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
- `edge length.sh` scripts to provide automatically calcaulated segment length to plotting routines
` edges.py` matplotlib plotting routines for edge length comparison in mesh regularization
