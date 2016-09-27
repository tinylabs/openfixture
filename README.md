# OpenFixture

## Goal
The motivation of OpenFixture was to make a parametric fixturing system that could take mostly (maybe fully) generated inputs from kicad and produce a test fixture with minimal effort.

Currently the inputs needed are:
  *Exported DXF of PCB outline
  *xy coordinates of all test point centers
  *xy dimensions of pcb (openscad cannot get this from DXF for some reason)

The resulting output is:
  *A 3D model of the test fixture for visualization
  *A 2D DXF that can be directly lasercut for assembly

## Future
I think it should be possible to integrate directly into kicad. Ideally having a File->Export Fixture. This should be possible using the python scripting to iterate through all pads looking for some attribute that identifies it as a test pad. After gathering xy coordinates and generating DXF from Edge.Cuts layer, openscad can be called from the command line to generate the laser cuttable DXF file and even a 3D rendering to display.

## Preparation
Currently as it stands there is a manual process to provide the necessary inputs to generate the fixture.
  1. In kicad pcbnew place the 'auxillary origin in the top left corner of your pcb.
  2. Gather all the relative xy coordinates by moving your crosshair cursor to the center of each pad. Write these down.
  3. Write down the bounding box x and y dimensions for pcb.
  4. Click on File->Plot
     Select DXF as plot format
     Choose output directory
     Under layers select Edge.Cuts only
     For options only select 'Use auxillary axis as origin'
     Click 'Plot'
  5. Load openscad and open openfixture.scad
  6. Enter the test point coordinates from step 2 into 'test_points' array.
  7. Look through the test point array and find minimum y value. Set tp_min_y to this value.
  8. Enter path to DXF file form step 4 into pcb_outline.
  9. Enter x,y dimensions from 3 into pcb_x, pcb_y and active_area_x, active_area_y
  10. Enter pcb thickness into pcb_th
  11. Enter material thickness as 'acr_th'
  12. Uncomment 3d_model () or lasercut () and hit F6 to generate!
  13. For lasercut click File->Export->Export as DXF.
  

## Hardware
  *All that is needed is M3 (14mm) screws or larger and lasercut parts
  *I use nylon bushings in the main pivot with m3 screws for a smoother joint but this is optional 

## Assembly
TODO - Will be writing detailed assembly instructions on http://tinylabs.io/openfixture

## Dependencies
  *Newer version of openscad >= 2015.03-1
  *kicad

## Documentation
TODO

## Known Issues
  *When loading the fonts file a new small window opens in Ubuntu. Seems innocuous but still annoying

## License
Creative Commons (CC BY-SA 4.0)

## Contributors
  *Elliot Buller - Tiny Labs Inc

Please email with any pull requests on new features
elliot@tinylabs.io