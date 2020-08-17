#!/bin/bash
## add good working cells here
cells=(44-4 37-4a)

## create meshes 
for i in "${cells[@]}"; do
  mkdir -p TestCell/${i}.CNG
  python get_swc.py --name ${i}
  ${TRAVIS_BUILD_DIR}/travis_root/ug4/bin/ugshell -call "test_import_swc_and_regularize(\"${i}.CNG.swc\", \"8\", \"user\", 0, false, true)"
  ${TRAVIS_BUILD_DIR}/travis_root/ug4/bin/ugshell -call "test_import_swc_general_var_for_vr_var(\"new_strategy.swc\", false, 0.5, true, 8, 0, true, 1, \"identity\", \"-1\")" 
done
