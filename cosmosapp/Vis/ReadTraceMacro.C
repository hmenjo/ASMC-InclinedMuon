#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <algorithm>
#include "TCanvas.h"
#include "TView.h"
#include "TPolyLine3D.h"
#include "TStopwatch.h"

/*PID and Color map for particles
  1   0    gamma
  2   1    potitron
  2   2    electron
  3   3    mu+
  3   4    mu-
  6   5    nucleon
  4,5 6    pion,kaon
  >6  7    all others
*/
using namespace std;

const Color_t colmap[] = {kCyan,kRed,kYellow,kBlue,kBlue,
			  kMagenta,kGreen,kOrange};
const Int_t NPOINT = 100000;   // Muximum # of point
const Double_t Eth_em=1.e-2; // GeV for EM
const Double_t Eth_mu=2.0; // GeV for mu
const Double_t Eth_h=0.3; // GeV for hadron
const Double_t ETHRE[] = {100., Eth_em, Eth_em, Eth_mu, Eth_h, Eth_h, Eth_h, 100.};  // Kinetic energy threshold in GeV

Double_t ViewRange[3][2];

Int_t UpdateViewRange(bool *first, Double_t x, Double_t y, Double_t z)
{
  if (*first){
    ViewRange[0][0]=x;
    ViewRange[0][1]=x;
    ViewRange[1][0]=y;
    ViewRange[1][1]=y;
    ViewRange[2][0]=z;
    ViewRange[2][1]=z;
    *first=false;
  }
  else{
    ViewRange[0][0]=min(ViewRange[0][0],x);
    ViewRange[0][1]=max(ViewRange[0][1],x);
    ViewRange[1][0]=min(ViewRange[1][0],y);
    ViewRange[1][1]=max(ViewRange[1][1],y);
    ViewRange[2][0]=min(ViewRange[2][0],z);
    ViewRange[2][1]=max(ViewRange[2][1],z);
  }
  return 0;
}

void usage(){
  cout << "Color map:" <<endl;
  //  cout << " Cyan    gamma" << endl;;
  cout << " Red     positron" << endl;;
  cout << " Yellow  electron" << endl;;
  cout << " Blue    muon" << endl;;
  cout << " Magenta Nucleon" << endl;;
  cout << " Green   pion or kaon" << endl;;
  cout << " White   nucleus" << endl;;
  //  cout << " Orange  others" << endl;;
}

void ReadTraceMacro(string filename="../trace1", bool autoscale=false){
  ifstream dataFile(filename);
  if(!dataFile){
    cout << "cannot open file. "<< filename << endl;
    return;
  }

  TStopwatch sw;

  //gStyle->SetCanvasPreferGL(kTRUE);

  TCanvas *sky;
  TPolyLine3D *pl;

  sky=(TCanvas*)gROOT->FindObject("sky");
  if (sky) {
    while((pl=(TPolyLine3D*)gROOT->FindObject("TPolyLine3D"))!=nullptr)
      delete pl;
    sky->Clear();
  } else {
    sky = new TCanvas("sky","Airshower",0,0,600,800);
  }
  sky->SetFillColor(kBlack);
  TView *view = TView::CreateView(2,0,0);
  bool first=true;

  string line;
  Double_t x[NPOINT],y[NPOINT],z[NPOINT],ke[NPOINT];
  Int_t i=0,id=-10000,q=0;

  sw.Start();
  
  while(getline(dataFile,line)){
    if(line.length()>7 && i<NPOINT){
      istringstream iss(line);
      iss >> x[i] >> y[i] >> z[i] >> id >> ke[i] >> q;
      if ( autoscale && ((id>=2 && id<=6) || id==9) )
	UpdateViewRange(&first,x[i],y[i],z[i]);

      //if ( x[i]>10000 || x[i]<-10000 || y[i]>10000 || y[i]<-10000 || z[i]>100000) continue;
      i++;
    }else{
      if(i!=0){
	if(id<=9 && ke[0]>ETHRE[id]){
	  switch (id) { 
	  case 1: // Gamma
	    //pl = new TPolyLine3D(i, x, y, z);
	    //pl->SetLineColor(colmap[0]);
	    //pl->Draw();
	    break;
	  case 2: // Positron or Eelctron
	    pl = new TPolyLine3D(i, x, y, z);
	    if(q>0) pl->SetLineColor(colmap[1]);
	    else pl->SetLineColor(colmap[2]);
	    pl->Draw();
	    break;
	  case 3: // Muon
	    pl = new TPolyLine3D(i, x, y, z);
	    pl->SetLineColor(colmap[3]);
	    pl->Draw();
	    break;
	  case 4: // Pion
	  case 5: // Kaon
	    pl = new TPolyLine3D(i, x, y, z);
	    pl->SetLineColor(colmap[6]);
	    pl->Draw();
	    break;
	  case 6: // Nucleon
	    
	    if(q==0) break;
		       
	    pl = new TPolyLine3D(i, x, y, z);
	    pl->SetLineColor(colmap[5]);
	    pl->Draw();
	    break;
	  case 9: // nucleus
	    pl = new TPolyLine3D(i, x, y, z);
	    pl->SetLineColor(kWhite);
	    pl->Draw();
	    break;
	  default:
	    break;
	  }
	}
      }
      i=0;
    }
    
  }
  sw.Stop();
  sw.Print();
  if (autoscale)
    view->SetRange(ViewRange[0][0],ViewRange[1][0],ViewRange[2][0],
		   ViewRange[0][1],ViewRange[1][1],ViewRange[2][1]);
  else
    view->SetRange(0,0,0,50000,50000,100000);
  usage();

    cout << endl
         << "Notice: Threshold energy for each particle is set high to save drawing time." << endl << endl
         << "Select [View]-[View With]-[OpenGL] in the ROOT menu for a fast visualization."
         << endl;
}

