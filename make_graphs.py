from cProfile import label
import math
from os import times
import re
from tokenize import group
from matplotlib import pyplot as plt
from matplotlib.ticker import FormatStrFormatter
from numpy import size
import numpy as np

file = open("strong_scalability.txt", "r")
lines = file.readlines()

y_time = []
x_process = []
sizes = []
data = []

for line in lines:
    result = re.search(r"(\d+.\d+), with (\d+) processors, (\d+)", line)
    y_time.append(float(result.group(1)))
    x_process.append(int(result.group(2)))
    if int(result.group(3)) not in sizes: sizes.append(int(result.group(3)))

print(y_time)
print(x_process)
print(sizes)

X = []
Y = []
i = 0


fig, ax = plt.subplots(figsize=(8,16))
fig.tight_layout()

ax.yaxis.set_major_formatter(FormatStrFormatter('%.1f'))
plt.yticks(np.arange(0.0, 300.0, 15.0))

for size in sizes:
    x_i = x_process[i*8: (i*8)+8]
    y_i = y_time[i*8: (i*8)+8]
    
    plt.plot(x_i, y_i, label = f"{size}x{size}")
    i+=1

plt.legend(title="Matrix Size")
plt.ylabel('Time in sec')
plt.xlabel('Num of process')
plt.grid(True)
plt.show()




