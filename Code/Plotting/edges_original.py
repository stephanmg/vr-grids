#!/usr/bin/env python
import matplotlib.pylab as plt
import scipy.sparse as sparse
import matplotlib.mlab as mlab
import matplotlib.cm as cm
import numpy as np
from mpl_toolkits.axes_grid1.inset_locator import zoomed_inset_axes
from mpl_toolkits.axes_grid1.inset_locator import mark_inset
import getopt
import sys
import math

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

sd = np.std(data)
mean = np.mean(data)
outliers_above = reduce(lambda count, i: count + ( ((i > mean+3*sd) == True)), data, 0)
outliers_below = reduce(lambda count, i: count + ( ((i-3*sd > mean) == True)), data, 0)
outliers = outliers_above + outliers_below

# color map
cmap = cm.get_cmap('Pastel1')

# Create a figure instance
fig = plt.figure(1, figsize=(9, 6))

# Create an axes instance
ax = fig.add_subplot(111)

# Create the boxplot
bp = ax.boxplot([data_to_plot], 0, 'rD')

for _, line_list in bp.items():
    for line in line_list:
        line.set_color(cmap(50))

plt.xlabel("Edge")
plt.tick_params(
    axis='x',          # changes apply to the x-axis
    which='both',      # both major and minor ticks are affected
    bottom=False,      # ticks along the bottom edge are off
    top=False,         # ticks along the top edge are off
    labelbottom=False) # labels along the bottom edge are off
plt.ylabel("Edge length [µm]")
plt.title("Edge length statistics: n = %i (mean: %f / std. dev.: %f / outliers: %i)" % (n, mean, sd, outliers))
plt.suptitle("Cell: (%s) %s" % ("Original",filename[0:-4]))

x_coordinates=[-1,2]
y_coordinates=[2,2]
plt.plot(x_coordinates, y_coordinates,color=cmap(0))
plt.grid(True)

fig = plt.figure(2, figsize=(9,6))
ax = fig.add_subplot(111)

binwidth=0.2
bins=np.arange(0, max(data) + binwidth, binwidth)
arr=plt.hist(data, bins=bins)
plt.xticks(arr[1])

#for item in arr[2]:
#  item.set_height(item.get_height()/sum(arr[0]))

for i in range(len(bins)-1):
  plt.text(arr[1][i],arr[0][i],int(arr[0][i]), fontsize=10, weight='bold')
  arr[2][i].set_facecolor(cmap(50))
  #plt.text(arr[1][i],arr[0][i]/sum(arr[0]),int(arr[0][i]), fontsize=10)

# add a 'best fit' line
#y = mlab.normpdf( bins, np.mean(data), np.std(data))
#l = plt.plot(bins, y, 'r--', linewidth=5)
plt.grid(True)

plt.title("Edge length statistics: n = %i (mean: %f / std. dev.: %f / outliers: %i)" % (n, mean, sd, outliers))
plt.suptitle("Cell: (%s) %s" % ("Original",filename[0:-4]))
plt.ylabel("Count")
plt.xlabel("Edge length [µm]")
plt.show()
