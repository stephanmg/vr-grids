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
import os

usage = lambda: "edges.py -i [--ifile] INPUT_FILE -a [--annotate] ANNOTATE"

try:
  opts, args = getopt.getopt(sys.argv[1:],"hi:a",["help", "ifile=", "annotate"])
except getopt.GetoptError:
  print usage()
  sys.exit(2)

if not sys.argv[1:]:
  print usage()
  sys.exit(0)

annotate=False
inputfile = ""
edgeFile = ""
for opt, arg in opts:
  if opt == '-h':
     print usage()
     sys.exit(0)
  elif opt in ("-i", "--ifile"):
    inputfile = arg
  elif opt in ("-a", "--annotate"):
    annotate=True
  else:
     print usage()
     sys.exit(1)


if not inputfile:
  print usage()
  sys.exit(2)

filename = os.path.splitext(inputfile)[0]
edgeFile = filename[0:-4] + "_edge_length.csv"
myStr = ""
with open(edgeFile, 'r') as file:
    myStr = file.read().replace('\n', '')

desired = np.array([float(d) for d in myStr.split(",")])
desired = np.max(desired, axis=0)
# filename = os.path.splitext(inputfile)[0]

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

# highest point
hi = desired

# color map
cmap = cm.get_cmap('Pastel1')

# Create a figure instance
fig = plt.figure(1, figsize=(16, 8))

# Create an axes instance
ax = fig.add_subplot(111)
ax.set_ylim([np.min(data)-0.25,hi+0.25])

# Create the boxplot
bp = ax.boxplot([data_to_plot], 0, 'rD')

# set colors
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
plt.suptitle("Cell: (%s) %s" % ("Regularized" if annotate else "Original", filename[0:-4]))
plt.title("Edge length statistics: n = %i (mean: %f / std. dev.: %f / outliers: %i)" % (n, mean, sd, outliers))

if annotate:
  x_coordinates=[-1,4]
  y_coordinates=[hi, hi]
  plt.plot(x_coordinates, y_coordinates,color=cmap(0))

plt.grid(True)

if annotate:
  ax.annotate('Automatically determined segment length (%f [arclength])' % hi,
            xy=(0.8, 0.835), xycoords='axes fraction', # was 0.715 # was 0.815
            xytext=(0, 50), textcoords='offset pixels',
            horizontalalignment='center',
            verticalalignment='bottom',
            arrowprops=dict(facecolor='black', shrink=0.05))


fig.savefig("%s_boxplot.png" % filename, dpi=300)
fig = plt.figure(2, figsize=(16,8))
ax = fig.add_subplot(111)

binwidth=0.2
if not annotate:
  binwidth=0.75

bins=np.arange(0, max(data) + binwidth, binwidth)
arr=plt.hist(data, bins=bins)
plt.xticks(arr[1])

# for item in arr[2]:
#  item.set_height(item.get_height()/sum(arr[0]))

for i in range(len(bins)-1):
  plt.text(arr[1][i],arr[0][i],int(arr[0][i]), fontsize=10, weight='bold')
  arr[2][i].set_facecolor(cmap(50))
  # plt.text(arr[1][i],arr[0][i]/sum(arr[0]),int(arr[0][i]), fontsize=10)

# add a 'best fit' line
# y = mlab.normpdf( bins, np.mean(data), np.std(data))
# l = plt.plot(bins, y, 'r--', linewidth=5)
plt.grid(True)

# plot
plt.title("Edge length statistics: n = %i (mean: %f / std. dev.: %f / outliers: %i)" % (n, mean, sd, outliers))
plt.suptitle("Cell: (%s) %s" % ("Regularized" if annotate else "Original", filename[0:-4]))
plt.ylabel("Count")
plt.xlabel("Edge length [µm]")
fig.savefig("%s_hist.png" % filename, dpi=300)
plt.show()
