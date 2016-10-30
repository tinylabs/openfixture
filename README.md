# OpenFixture

![Alt text](/../images/screencap.png?raw=true "")
![Alt text](/../images/laser_dxf.png?raw=true "")
![Alt text](/../images/sample.jpg?raw=true "")

## Goal
The motivation of OpenFixture was to make a parametric fixturing system that could take fully generated inputs from kicad and produce a test fixture with minimal effort. The easiest way to use it is through the kicad python scripting interface.

## Parameters
For most projects (if using the standard BOM) the only parameters you'll need to set are mat_th and pcb_th. Something like the following should be sufficient:
  * ./GenFixture.py --board [path to board.kicad_pcb] --mat_th [thickness in mm] --pcb_th [thickness in mm] --out board-fixture

usage: GenFixture.py [-h] --board BOARD --mat_th MAT_TH --out OUT
                     [--pcb_th PCB_TH] [--screw_len SCREW_LEN]
                     [--screw_d SCREW_D] [--layer LAYER] [--flayer FLAYER]
                     [--ilayer ILAYER]

optional arguments:
  -h, --help            show this help message and exit
  --board BOARD         <board_name.kicad_pcb>
  --mat_th MAT_TH       material thickness (mm)
  --out OUT             output directory
  --pcb_th PCB_TH       pcb thickness (mm)
  --screw_len SCREW_LEN  Assembly screw thread length (default = 14mm)
  --screw_d SCREW_D     Assembly screw diameter (default=M3)
  --layer LAYER         F.Cu | B.Cu
  --flayer FLAYER       Eco1.User | Eco2.User
  --ilayer ILAYER       Eco1.User | Eco2.User
					    
The resulting output is:
  * A 3D model of the test fixture for visualization
  * A 2D DXF that can be directly lasercut for assembly

## Hardware
  * All that is needed is M3 (14mm+) screws, M3 hex nuts, and lasercut parts
  * I use nylon bushings in the main pivot with m3 screws for a smoother joint but this is optional 

## Documentation
http://tinylabs.io/openfixture

## BOM
http://tinylabs.io/openfixture-bom

## Kicad export
http://tinylabs.io/openfixture-kicad-export

## Assembly
More info including detailed assembly instructions at http://tinylabs.io/openfixture-assembly

## Dependencies
  * Newer version of openscad >= 2015.03-1
  * kicad or other EDA software. Please email me if you have instructions for other packages so I can add them.

## Known Issues
  * When loading the fonts file a new small window opens in Ubuntu. Seems innocuous but still annoying [Only seen on ubuntu 14.04]

## License
Creative Commons (CC BY-SA 4.0)

## Contributors
  * Elliot Buller - Tiny Labs Inc

Please email with any pull requests or new feature requests
elliot@tinylabs.io
