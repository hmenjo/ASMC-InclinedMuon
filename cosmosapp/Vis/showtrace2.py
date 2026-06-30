#! /usr/bin/python

from pyqtgraph.Qt import QtCore, QtGui
import pyqtgraph.opengl as gl
import pyqtgraph as pg
import numpy as np

#
Eth_em=1.0e-2  # GeV for EM
Eth_mu=2.0     # GeV for mu
Eth_h=0.3      # GeV for hadron
ETHRE=[100, Eth_em, Eth_em, Eth_mu, Eth_h, Eth_h, Eth_h, 100]
colmap=["c","r","y","b","b", "m","g","w"]

# initialize
x=[]
y=[]
z=[]

app = QtGui.QApplication([])
wd = gl.GLViewWidget()
wd.opts['distance'] = 50000
wd.show()
wd.setWindowTitle('Air shower')

def plottrace(filename):
    with open(filename,'r') as f:
        for line in f:
            if len(line.strip())>0:
                w=line.split()
                if len(w)==7:
                    x.append(float(w[0]))
                    y.append(float(w[1]))
                    z.append(float(w[2]))
                    id=int(w[3])
                    ke=float(w[4])
                    q=int(w[5])
            else:
                if len(x)>1:
                    if id<=6 and ke>ETHRE[id]:
                        pts = np.vstack([x,y,z]).transpose()
                        if id==1: #gamma
                            pass
                        elif id==2: #positron or electron
                            plt = gl.GLLinePlotItem(pos=pts, color=pg.glColor(colmap[id]))
                            wd.addItem(plt)
                        elif id==3: # muon
                            plt = gl.GLLinePlotItem(pos=pts, color=pg.glColor(colmap[id]))
                            wd.addItem(plt)                            
                        elif id==4 or id==5: #Pion, Kaon
                            plt = gl.GLLinePlotItem(pos=pts, color=pg.glColor(colmap[6]))
                            wd.addItem(plt)                            
                        elif id==6 and q!=0: #nucleon
                            plt = gl.GLLinePlotItem(pos=pts, color=pg.glColor(colmap[5]))
                            wd.addItem(plt)                            
                        elif id==9: #nucleus
                            plt = gl.GLLinePlotItem(pos=pts, color=pg.glColor('white'))
                            wd.addItem(plt)                            
                x.clear()
                y.clear()
                z.clear()

if __name__ == "__main__":
    import sys

    if len(sys.argv)>1:
        filename=sys.argv[1]
    else:
        filename="trace1"

    plottrace(filename)
    if (sys.flags.interactive != 1) or not hasattr(QtCore, 'PYQT_VERSION'):
        QtGui.QApplication.instance().exec_()
