# Full geometries

- 11: From the Smith archive, dendrites intersect at soma. Naive treatment by wrapping around a slightly larger soma sphere.
- 12\_a, 13, 14, 15: Regular cells which do not overlap at soma start.

Each cell mentioned above (11, 12\_a, 13, 14 and 15) has a 1d representation (1d graph containing vertices and edges only) and a 2d surface representation (Containing triangles, edges and vertices).
For each cell the 1d representation has been refined regularly four times. Each refinement divides each edge by introducing an additional vertex at the middle of the edge, thus creating two smaller edges and discards the original edge.

In addition, each 2d surface mesh has been inflated by the factor 2 or 4. Inflation means, that the radii of the neurites (dendrites and axons are representated as piecewise cylinders
and approximated by ring-polygons accordingly) have been scaled with the factor 2 or 4, i.e. radii are doubled or quadrupled.
