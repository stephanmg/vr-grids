#!/usr/bin/env python
import matplotlib.pylab as plt
import scipy.sparse as sparse
import numpy as np
from mpl_toolkits.axes_grid1.inset_locator import zoomed_inset_axes
from mpl_toolkits.axes_grid1.inset_locator import mark_inset
import getopt
import sys

try:
  opts, args = getopt.getopt(sys.argv[1:],"hi:o:",["ifile="])
except getopt.GetoptError:
  print 'sparse.py -i <inputfile>'
  sys.exit(2)

if not sys.argv[1:]:
  print 'sparse.py -i <inputfile>'
  sys.exit(2)

inputfile = ""
for opt, arg in opts:
  if opt == '-h':
     print 'test.py -i <inputfile>'
     sys.exit()
  elif opt in ("-i", "--ifile"):
    inputfile = arg
  else:
     print 'test.py -i <inputfile>'
     sys.exit()


cols = 0
#with open('matrixJames.txt', 'r') as file:
with open(inputfile, 'r') as file:
    data = file.read()

data = data.rstrip(";")
rows=data.count(";")
#print(data)

A = np.matrix(data) + np.eye(rows+1)
plt.spy(A)
fig, ax = plt.subplots(figsize=(3,3))
ax.spy(A, markersize=5)

detail = (A[1:50][...,1:50])
plt.xlabel("#Columns " + str(rows))
plt.ylabel("#Rows "  + str(rows))
plt.xticks(np.arange(0, rows, 100.0))
plt.yticks(np.arange(0, rows, 100.0))
plt.suptitle("1st refinement (DFS-strategy)")

 # location for the zoomed portion 
sub_axes = plt.axes([.5, .5, .3,.3]) 
# plot the zoomed portion
sub_axes.spy(detail, markersize=2)
# show plot
plt.show()
