#! /usr/bin/python

import sys
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

#
Eth_em=1.0e-2  # GeV for EM
Eth_mu=2.0     # GeV for mu
Eth_h=0.3      # GeV for hadron
ETHRE=[100, Eth_em, Eth_em, Eth_mu, Eth_h, Eth_h, Eth_h, 100]
colmap=["cyan","red","yellow","blue","blue", "magenta","green","orange"]

# initialize
x=[]
y=[]
z=[]

def showtrace(filename):
    fig = plt.figure('Air shower',facecolor='black',figsize=(6,6))
    ax = fig.add_subplot(111, projection='3d', fc='black')
    ax.tick_params(axis='x', colors='w')
    ax.tick_params(axis='y', colors='w')
    ax.tick_params(axis='z', colors='w')
    #ax.xaxis.label.set_color('w')
    #ax.yaxis.label.set_color('w')
    #ax.zaxis.label.set_color('w')
    ax.set_xlim(-50000,50000)
    ax.set_ylim(-50000,50000)
    ax.set_zlim(0,100000)

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
                        if id==1: #gamma
                            pass
                        elif id==2: #positron or electron
                            ax.plot(x,y,z,color=colmap[id])
                        elif id==3: # muon
                            ax.plot(x,y,z,color=colmap[id])
                        elif id==4 or id==5: #Pion, Kaon
                            ax.plot(x,y,z,color=colmap[6])
                        elif id==6 and q!=0: #nucleon
                            ax.plot(x,y,z,color=colmap[5])
                        elif id==9: # nucleus
                            ax.plot(x,y,z,color='white')
                x.clear()
                y.clear()
                z.clear()
        plt.show()

if __name__ == "__main__":
    if len(sys.argv)>1:
        filename=sys.argv[1]
    else:
        filename="trace1"

    showtrace(filename)
    
