#!/usr/bin/python
#
# Kicad OpenFixture Generator
#
# TinyLabs Inc
# 2016
# CC-BY-SA 4.0
#
# Takes two arguments:
# 1. pcb_th (mm) - PCB thickness
# 2. mat_th (mm) - Laser cut material thickness
#
# TODO - Add pad attributes to force testpoint and force ignoring test point
#        Default is all pads with no mask are test points.
#        Add args for:
#            MANDATORY: pcb_th and mat_th and output directory
#            OPTIONAL: pivot_d, screw_len
import sys
from pcbnew import *

class GenFixture:

    # Global pointer to brd object
    brd = None
    min_y = float ("inf")
    origin = [ float ("inf"), float ("inf") ]
    dims = [0, 0]
    test_points = []
    
    def __init__(self, brd):
        self.brd = brd

    def __exit__(self, type, value, traceback):
        pass

    def __str__(self):
        return "Fixture: origin=(%.02f,%.02f) dims=(%.02f,%.02f) min_y=%.02f" % (self.origin[0], self.origin[1],
                                                                                 self.dims[0], self.dims[1],
                                                                                 self.min_y)
    
    def Round(self, x, base=0.01):
        return round(base*round(x/base), 2)

    def PlotDXF(self, path):

        # Save auxillary origin
        aux_origin_save = self.brd.GetAuxOrigin ()

        # Set new aux origin to upper left side of board
        self.brd.SetAuxOrigin (wxPoint (self.origin[0], self.origin[1]))
        
        # Get pointers to controllers
        pctl = PLOT_CONTROLLER(self.brd)
        popt = pctl.GetPlotOptions()

        # Setup output directory
        popt.SetOutputDirectory(path)

        # Set some important plot options:
        popt.SetPlotFrameRef(False)
        popt.SetLineWidth(FromMM(0.1))
        popt.SetAutoScale(False)
        popt.SetScale(1)
        popt.SetMirror(False)
        popt.SetUseGerberAttributes(False)
        popt.SetExcludeEdgeLayer(False);
        popt.SetScale(1)
        popt.SetUseAuxOrigin(True)

        # This by gerbers only (also the name is truly horrid!)
        popt.SetSubtractMaskFromSilk(False)

        # Do the BRD edges in yellow
        popt.SetColor(YELLOW)

        # Open file
        pctl.OpenPlotfile("outline", PLOT_FORMAT_DXF, "Edges")
        pctl.SetLayer(Edge_Cuts)

        # Plot layer
        pctl.PlotLayer()

        # CLose plot
        pctl.ClosePlot()

        # Restore origin
        self.brd.SetAuxOrigin (aux_origin_save)

    def Generate(self, path):

        # Get origin and board dimensions
        fixture.GetOriginDimensions ()

        # Get test points
        fixture.GetTestPoints ()

        # Debug dump test points
        print fixture.GetTestPointStr ()
        
        # Plot DXF
        fixture.PlotDXF (path)

        # Call openscad to generate fixture
        
        
    def GetTestPointStr (self):
        tps = "["
        for tp in self.test_points:
            tps += "[%.02f,%.02f]," % (tp[0], tp[1])
        return (tps + "]")

    def GetTestPoints (self):

        # Iterate over all pads
        for m in self.brd.GetModules ():

            # Iterate over all pads
            for p in m.Pads ():
                    
                # Check that there is no paste and it's on front copper layer
                if ((p.IsOnLayer (F_Paste) == False) and (p.IsOnLayer (F_Cu) == True) and (p.GetAttribute () == PAD_SMD)):

                    # Print position
                    tp = ToMM (p.GetPosition ())

                    # Round x and y
                    x = self.Round(tp[0] - self.origin[0])
                    y = self.Round(tp[1] - self.origin[1])
                    #print "tp = (%f, %f)" % (x,y)
                    
                    # Check if less than min
                    if y < self.min_y:
                        self.min_y = y
                    
                    # Save coordinates of pad
                    self.test_points.append ([x, y])
    
    def GetOriginDimensions(self):
        if (self.brd is None):
            return None

        # Init max variables
        max_x = 0
        max_y = 0

        # Get all drawings
        for line in self.brd.GetDrawings ():

            # Check that it's in the outline layer
            if line.GetLayerName () == 'Edge.Cuts':

                # Get bounding box
                bb = line.GetBoundingBox ()
                x = ToMM (bb.GetX ())
                y = ToMM (bb.GetY ())

                # Debug
                #print "(%f, %f)" % (x, y)
                
                # Min x/y will be origin
                if x < self.origin[0]:
                    self.origin[0] = self.Round (x)
                if y < self.origin[1]:
                    self.origin[1] = self.Round (y)

                # Max x.y will be dimensions
                if x > max_x:
                    max_x = x
                if y > max_y:
                    max_y = y

        # Calculate dimensions
        self.dims[0] = self.Round (max_x - self.origin[0])
        self.dims[1] = self.Round (max_y - self.origin[1])
        
if __name__ == '__main__':

    # Validate arguments
    if (len (sys.argv) != 2):
        print "%s <boardname.kicad_pcb>" % sys.argv[0]
        sys.exit (-1)

    # Load up the board file
    brd = LoadBoard (sys.argv[1])

    # Create a fixture generator
    fixture = GenFixture (brd)

    # Generate fixture
    fixture.Generate ("./")
    print fixture
