
import numpy as np
import matplotlib.pyplot as plt

filenames = {
	"u0": "data/u0.dat",
	"uf": "output/uf.dat",
	"v0": "data/v0.dat",
	"vf": "output/vf.dat"
}

dataU0 = np.loadtxt(filenames["u0"])
dataUf = np.loadtxt(filenames["uf"])
dataV0 = np.loadtxt(filenames["v0"])
dataVf = np.loadtxt(filenames["vf"])

x = np.linspace(0, 1, len(dataUf[0]))
y = np.linspace(0, 1, len(dataUf))
X, Y = np.meshgrid(x, y)

plotTitles = {
	"u0": "Concentration of U at initial time",
	"uf": "Concentration of U at final time",
	"v0": "Concentration of V at initial time",
	"vf": "Concentration of V at final time"
}
plotLabels = {
	"u": "Concentration U",
	"v": "Concentration V"
}

plt.figure(figsize=(14, 12))
for i, (data, key) in enumerate(zip([dataU0, dataUf, dataV0, dataVf],
									["u0", "uf", "v0", "vf"])):
	plt.subplot(2, 2, i + 1)
	plt.contourf(X, Y, data, cmap='viridis')
	plt.colorbar(label=plotLabels[key[0]])
	plt.title(plotTitles[key])
	plt.xlabel('x Coordinate')
	plt.ylabel('y Coordinate')

plt.tight_layout()
plt.savefig('u_v_input_output.png')
