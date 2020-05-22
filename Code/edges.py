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
  print 'edges.py -i <inputfile>'
  sys.exit(2)

if not sys.argv[1:]:
  print 'edges.py -i <inputfile>'
  sys.exit(2)

inputfile = ""
for opt, arg in opts:
  if opt == '-h':
     print 'edges.py -i <inputfile>'
     sys.exit()
  elif opt in ("-i", "--ifile"):
    inputfile = arg
  else:
     print 'edges.py -i <inputfile>'
     sys.exit()

# acquire data
with open(inputfile, 'r') as file:
  next(file)
  data = [float(d) for d in file]
data_to_plot = np.array(data)
n = len(data)

# Create a figure instance
fig = plt.figure(1, figsize=(9, 6))

# Create an axes instance
ax = fig.add_subplot(111)

# Create the boxplot
bp = ax.boxplot([data_to_plot], 0, 'rD')
plt.xlabel("Edge")
plt.tick_params(
    axis='x',          # changes apply to the x-axis
    which='both',      # both major and minor ticks are affected
    bottom=False,      # ticks along the bottom edge are off
    top=False,         # ticks along the top edge are off
    labelbottom=False) # labels along the bottom edge are off
plt.ylabel("Length")
plt.suptitle("Edge length statistics: n = %i" % n)

x_coordinates=[-1,2]
y_coordinates=[4,4]
plt.plot(x_coordinates, y_coordinates)

ax.annotate('Chosen segment length',
            xy=(0.8, 0.45), xycoords='axes fraction',
            xytext=(0, 50), textcoords='offset pixels',
            horizontalalignment='center',
            verticalalignment='bottom',
            arrowprops=dict(facecolor='black', shrink=0.05))



# show plot
plt.show()
