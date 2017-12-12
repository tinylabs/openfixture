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
#   Args - Path to store
#          --layer <F.Cu|B.Cu>
#
#        Default is all pads with no paste mask are test points.
#        Add args for:
#            MANDATORY: pcb_th and mat_th and output directory
#            OPTIONAL: pivot_d, screw_len
import os
import sys
import argparse
from pcbnew import *

# Defaults
DEFAULT_PCB_TH = 1.6
DEFAULT_SCREW_D = 3.0
DEFAULT_SCREW_LEN = 14

# Generate fixture class
class GenFixture:

    # Layers
    layer = F_Cu
    paste = F_Paste
    ignore_layer = Eco1_User
    force_layer = Eco2_User

    # Will be true if we're working on back points
    mirror = False

    # Fixture parameters
    mat_th = 0
    pcb_th = DEFAULT_PCB_TH
    screw_len = DEFAULT_SCREW_LEN
    screw_d = DEFAULT_SCREW_D

    # Global pointer to brd object
    brd = None

    # Path to generated dxf
    dxf_path = None
    prj_name = None

    # Optional arguments
    rev = None
    washer_th=None
    nut_f2f=None
    nut_c2c=None
    nut_th=None
    pivot_d=None
    border=None

    # Board dimensions
    min_y = float ("inf")
    origin = [ float ("inf"), float ("inf") ]
    dims = [0, 0]
    test_points = []
    
    def __init__(self, prj_name, brd, mat_th):
        self.prj_name = prj_name
        self.brd = brd
        self.mat_th = float (mat_th)
        
    def __exit__(self, type, value, traceback):
        pass

    def __str__(self):
        return "Fixture: origin=(%.02f,%.02f) dims=(%.02f,%.02f) min_y=%.02f" % (self.origin[0],
                                                                                 self.origin[1],
                                                                                 self.dims[0],
                                                                                 self.dims[1],
                                                                                 self.min_y)

    def SetOptional(self, rev=None, washer_th=None, nut_f2f=None, nut_c2c=None, nut_th=None,
                    pivot_d=None, border=None, logosize=(50,50)):
        self.rev = rev
        self.washer_th = washer_th
        self.nut_f2f = nut_f2f
        self.nut_c2c = nut_c2c
        self.nut_th = nut_th
        self.pivot_d = pivot_d
        self.border = border
        self.logosize = logosize


    def SetParams(self, pcb_th, screw_len, screw_d):
        if pcb_th is not None:
            self.pcb_th = float (pcb_th)
        if screw_len is not None:
            self.screw_len = float (screw_len)
        if screw_d is not None:
            self.screw_d = float (screw_d)

    def SetLayers(self, layer=-1, ilayer=-1, flayer=-1):
        if layer != -1:
            self.layer = layer
        if ilayer != -1:
            self.ignore_layer = ilayer
        if flayer != -1:
            self.force_layer = flayer

        # Setup paste layer
        if (self.layer == F_Cu):
            self.paste = F_Paste
        else:
            self.paste = B_Paste
            self.mirror = True

    def Round(self, x, base=0.01):
        return round(base*round(x/base), 2)

    def PlotDXF(self, path):

        # Save auxillary origin
        aux_origin_save = self.brd.GetAuxOrigin ()

        # Set new aux origin to upper left side of board
        self.brd.SetAuxOrigin (wxPoint (FromMM(self.origin[0]), FromMM(self.origin[1])))
        
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
        popt.SetMirror(self.mirror)
        popt.SetUseGerberAttributes(False)
        popt.SetExcludeEdgeLayer(False);

        # Use auxillary origin
        popt.SetUseAuxOrigin(True)

        # This by gerbers only (also the name is truly horrid!)
        popt.SetSubtractMaskFromSilk(False)

        # Do the BRD edges in black
        popt.SetColor(BLACK)

        # Open file
        pctl.SetLayer(Edge_Cuts)
        pctl.OpenPlotfile("outline", PLOT_FORMAT_DXF, "Edges")

        # Plot layer
        pctl.PlotLayer()

        # CLose plot
        pctl.ClosePlot()

        # Restore origin
        self.brd.SetAuxOrigin (aux_origin_save)

    def Generate(self, path):

        # Get origin and board dimensions
        self.GetOriginDimensions ()

        # Get test points
        self.GetTestPoints ()

        # Plot DXF
        self.PlotDXF (path)

        # Get revision
        if self.rev is None:
            self.rev = "rev.%s" % self.brd.GetTitleBlock().GetRevision ()
            if self.rev == "":
                self.rev = "rev.0"

        # Call openscad to generate fixture
        args = "-D\'test_points=%s\'" % self.GetTestPointStr () 
        args += " -D\'tp_min_y=%.02f\'" % self.min_y
        args += " -D\'mat_th=%.02f\'" % self.mat_th
        args += " -D\'pcb_th=%.02f\'" % self.pcb_th
        args += " -D\'pcb_x=%.02f\'" % self.dims[0]
        args += " -D\'pcb_y=%.02f\'" % self.dims[1]
        args += " -D\'pcb_outline=\"%s\"\'" % (path + "/" + self.prj_name + "-outline.dxf")
        args += " -D\'screw_thr_len=%.02f\'" % self.screw_len
        args += " -D\'screw_d=%.02f\'" % self.screw_d
        args += " -D\'logo_w=%s\'" % self.logosize[0]
        args += " -D\'logo_h=%s\'" % self.logosize[1]

        # Set optional args
        if self.rev != None:
            args += " -D\'rev=\"%s\"\'" % self.rev
        if self.washer_th != None:
            args += " -D\'washer_th=%.02f\'" % float (self.washer_th)
        if self.nut_f2f != None:
            args += " -D\'nut_od_f2f=%.02f\'" % float (self.nut_f2f)
        if self.nut_c2c != None:
            args += " -D\'nut_od_c2c=%.02f\'" % float (self.nut_c2c)
        if self.nut_th != None:
            args += " -D\'nut_th=%.02f\'" % float (self.nut_th)
        if self.pivot_d != None:
            args += " -D\'pivot_d=%.02f\'" % float (self.pivot_d)
        if self.border != None:
            args += " -D\'border=%.02f\'" % float (self.border)

        # Create output file name
        dxfout = path + "/" + self.prj_name + "-fixture.dxf"
        pngout = path + "/" + self.prj_name + "-fixture.png"
        testout= path + "/" + self.prj_name + "-test.dxf"

        # This will take a while, print something
        print "Generating Fixture..."
        
        # Create test part
        os.system ("openscad %s -D\'mode=\"testcut\"\' -o %s openfixture.scad" % (args, testout))
        
        # Create rendering
        os.system ("openscad %s -D\'mode=\"3dmodel\"\' --render -o %s openfixture.scad" % (args, pngout))
      
        # Create laser cuttable fixture
        os.system ("openscad %s -D\'mode=\"lasercut\"\' -o %s openfixture.scad" % (args, dxfout))

        # Print output
        print "Fixture generated: %s" % dxfout

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
                if (p.IsOnLayer (self.layer) == True):

                    # Are we forcing this pad?
                    if (p.IsOnLayer (self.force_layer) == True):
                        pass
                    
                    #else check ignore cases
                    elif ((p.IsOnLayer (self.ignore_layer) == True) or
                          (p.IsOnLayer (self.paste) == True) or
                          (p.GetAttribute () != PAD_SMD)):
                        continue
                                             
                    # Print position
                    tp = ToMM (p.GetPosition ())

                    # Round x and y, invert x if mirrored
                    if self.mirror is False:
                        x = self.Round(tp[0] - self.origin[0])
                    else:
                        x = self.dims[0] - (self.Round(tp[0] - self.origin[0]))
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

    # Create parser
    parser = argparse.ArgumentParser ()

    # Add required arguments
    parser.add_argument ('--board', help='<board_name.kicad_pcb>', required=True)
    parser.add_argument ('--mat_th', help='material thickness (mm)', required=True)
    parser.add_argument ('--out', help='output directory', required=True)
    
    # Add optional arguments
    parser.add_argument ('--pcb_th', help='pcb thickness (mm)')
    parser.add_argument ('--screw_len', help='Assembly screw thread length (default = 16mm)')
    parser.add_argument ('--screw_d', help='Assembly screw diameter (default=3mm)')
    parser.add_argument ('--layer', help='F.Cu | B.Cu')
    parser.add_argument ('--flayer', help='Eco1.User | Eco2.User')
    parser.add_argument ('--ilayer', help='Eco1.User | Eco2.User')
    parser.add_argument ('--rev', help='Override revisiosn')
    parser.add_argument ('--washer_th', help='Washer thickness for hinge')
    parser.add_argument ('--nut_f2f', help='hex nut flat to flat (mm)')
    parser.add_argument ('--nut_c2c', help='hex nut corner to corner (mm)')
    parser.add_argument ('--nut_th', help='hex nut thickness (mm)')
    parser.add_argument ('--pivot_d', help='Pivot diameter (mm)')
    parser.add_argument ('--border', help='Board (ledge) under pcb (mm)')
    parser.add_argument ('--logo-w', help='Set logo width, mm', default=50)
    parser.add_argument ('--logo-h', help='Set logo height, mm', default=50)


    # Get args
    args = parser.parse_args ()

    # Convert path to absolute
    out_dir = os.path.abspath (args.out)

    # If output directory doesn't exist create it
    if not os.path.exists (out_dir):
        os.makedirs (out_dir)

    # Load up the board file
    brd = LoadBoard (args.board)

    # Extract project name
    prj_name = os.path.splitext (os.path.basename (args.board))[0]
    
    # Save internal parameters
    layer = brd.GetLayerID (args.layer)
    flayer = brd.GetLayerID (args.flayer)
    ilayer = brd.GetLayerID (args.ilayer)

    # Check for pcb thickness
    if args.pcb_th is None:
        args.pcb_th = "1.6"

    # Create a fixture generator
    fixture = GenFixture (prj_name, brd, args.mat_th)

    # Set parameters
    fixture.SetParams (args.pcb_th, args.screw_len, args.screw_d);

    # Setup layers
    fixture.SetLayers (layer=layer, flayer=flayer, ilayer=ilayer)

    # Set optional arguments
    fixture.SetOptional (rev=args.rev,
                         washer_th=args.washer_th,
                         nut_f2f=args.nut_f2f,
                         nut_c2c=args.nut_c2c,
                         nut_th=args.nut_th,
                         pivot_d=args.pivot_d,
                         border=args.border,
                         logosize=(args.logo_w, args.logo_h))

    # Generate fixture
    fixture.Generate (out_dir)
    # print fixture
