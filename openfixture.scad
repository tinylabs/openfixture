/**
 *  OpenFixture - The goal is to have a turnkey pcb fixturing solution
 *  as long as you have access to a laser cutter or laser cutting service.
 *
 *  The input is:
 *   1. (x, y) work area that is >= pcb size
 *   2. (x, y) cooridates of test point centers
 *   3. dxf of pcb outline aligned with (0,0) on the top left.
 *   4. Material parameters: acrylic thickness, kerf, etc
 *
 *  The output is a dxf containing all the parts (minus M3 hardware)
 *  to assemble the fixture.
 *
 *  Creative Commons Licensed  (CC BY-SA 4.0)
 *  Tiny Labs
 *  2016
 */
use <glaser-stencil-d.ttf>
FONTNAME = "Glaser Stencil D";

//
// PCB input
//
// Test points
test_points = [[23.22,25.85],[19.72,22.28],[3.95,25.77],[7.52,22.27],[13.60,13.70],[13.55,18.70],[13.55,34.90],[13.60,29.90],];

// Used below to calculate distance from hinge to nearest point based on min
// contact angle... Ideally we want it as close to 90 degrees as possible
// All you have to know is look through 'y' column above and set to lowest val
tp_min_y = 13.7;

// DXF outline of pcb
pcb_outline = "./rfid_fob-outline.dxf";
logo = "./logo.dxf";

// PCB revision
rev = "rev.0";

// Should be close to actual pcb dimensions... Used for support structure only so not critical
pcb_x = 27.14;
pcb_y = 45;
pcb_support_border = 2;

logo_w = 50;
logo_h = 50;

// Work area of PCB
// Must be >= PCB size
// If you make this as big as any of the PCBs you work 
// with you could then reuse the base and just swap the
// head and carriers based on the pcb you're using. 
work_area_x = pcb_x;
work_area_y = pcb_y;

// Thickness of pcb
pcb_th = 1.6;  // Standard PCB size

//
// End PCB input
//

// Correction offset
// These are final adjustments relative to the board carrier.
// Usually these aren't needed but can be used to tweak alignment
tp_correction_offset_x = 0.0;
tp_correction_offset_y = 0.0;

// Uncomment for alignment check, can be a quick sanity check to
// make sure everything lines up.
//projection (cut = false) alignment_check ();
mode = "3dmodel";
//mode = "lasercut";
//mode = "validate";
//mode = "testcut";
//mode = "none";

// Uncomment for laser cuttable dxf
if (mode == "lasercut") projection (cut = false) lasercut ();
if (mode == "3dmodel") 3d_model ();
if (mode == "validate") validate_testpoints (pcb_outline);
if (mode == "testcut") projection (cut = false) testcut ();

// Smothness function for circles
$fn = 15;

// All measurements in mm
// Material parameters
mat_th = 3.0;

// Kerf adjustment
kerf = 0.125;

// Space between laser parts
laser_pad = 2;

// Screw radius (we want this tight to avoid play)
// This should work for M3 hardware
// Just the threads, not including head
// Should be no less than 12
screw_thr_len = 16;
screw_d = 3.0;
screw_r = screw_d / 2;

// Uncomment to use normal M3 screw for pivot
// We need pivot_d tight for precise alignment
pivot_d = screw_d - 0.1;
// Uncomment to use bushing in pivot
//pivot_d = 5.12;
pivot_r = pivot_d / 2;

// Pivot support, 3mm on either side 
pivot_support_d = pivot_d + 6;
pivot_support_r = pivot_support_d / 2;

// Metric M3 hex nut dimensions
// f2f = flat to flat
nut_od_f2f = 5.45;
nut_od_c2c = 6;
nut_th = 2.25;

// Option to add nylon washer on latching mechanism for smoother
// operation - disabled by default
washer_th = 0;
//washer_th = 1;

// Pogo pin receptable dimensions
// I use the 2 part pogos with replaceable pins. Its a lifer save when a 
// pin breaks. Undersized so they can be carefully drilled out using #50
// drill bit for better precision. If you have access to a nicer laser you 
// can size these exactly
pogo_r = 1.5 / 2;

// Uncompressed length from receptacle
pogo_uncompressed_length = 8;
pogo_compression = 1;

// Locking tab parameters
tab_width = 3 * mat_th;
tab_length = 4 * mat_th + washer_th;

// Stop tab
stop_tab_y = 2 * mat_th;

//
// DO NOT EDIT BELOW... unless you feel like it ;-)
//
// Calculate min distance to hinge with a constraint on
// the angle of the pogo pin when it meets compression with the board.
// a = compression
// c = active_y_offset + pivot_support_r
// cos (min_angle) = a^2 / (2ca)
min_angle = 89.5;

// Calculate active_y_back_offset
active_y_back_offset = (pow (pogo_compression, 2) / (cos (min_angle) * 2 * pogo_compression)) - pivot_support_r - tp_min_y;

// Active area parameters
active_x_offset = 2 * mat_th + nut_od_f2f + 2;
active_y_offset = 2 * mat_th + nut_od_f2f + 2;

// Head dimensions
head_x = work_area_x + 2 * active_x_offset;
head_y = work_area_y + active_y_offset + active_y_back_offset;
head_z = screw_thr_len - nut_th;

// Base dimensions
base_x = head_x + 2 * mat_th;
base_y = head_y + pivot_support_d;
base_z = screw_thr_len + 3 * mat_th;
base_pivot_offset = pivot_support_r + 
                    (pogo_uncompressed_length - pogo_compression) -
                    (mat_th - pcb_th);

// To account for capture nut overhang
nut_pad = (nut_od_c2c - mat_th) / 2;

// Derived latch dimensions
latch_z_offset = (base_z * (2 / 3) + base_pivot_offset - pivot_r) / 2;
support_x = base_x / 12 + 2 * mat_th;
latch_support_y = base_z * (2 / 3) + base_pivot_offset - pivot_support_r - 2 * mat_th;
//
// MODULES
//
module tnut_female (n, length = screw_thr_len)
{
    // How much grip material
    tnut_grip = 4;
    
    // Pad for screw
    pad = 0.4;
    screw_len_pad = 1;
    
    // Screw hole
    translate ([0, -screw_r - pad/2, 0])
    cube ([length + screw_len_pad, screw_d + pad, mat_th]);
    
    // Make space for nut
    translate ([mat_th * n + tnut_grip, -nut_od_f2f/2, 0])
    cube ([nut_th, nut_od_f2f, mat_th]);
}

module tnut_hole ()
{
    pad = 0.1;
    cylinder (r = screw_r + pad, h = mat_th, $fn = 20);
}

module tng_n (length, cnt)
{
    tng_y = (length / cnt);
    
    translate ([0, -length / 2, 0])
    union () {
        for (i = [0 : 2 : cnt - 1]) {
            translate ([0, i * tng_y, 0])
            cube ([mat_th, tng_y, mat_th]);
        }
    }
}

module tng_p (length, cnt)
{
    tng_y = length / cnt;
    
    translate ([0, -length / 2, 0])
    union () {
        for (i = [1 : 2 : cnt - 1]) {
            translate ([0, i * tng_y, 0])
            cube ([mat_th, tng_y, mat_th]);
        }
    }
}

module nut_hole ()
{
    pad = 0.05;
    cylinder (r = nut_od_c2c/2 + pad, h = mat_th, $fn = 6);
}

module testcut ()
{
    y = 30;
    off = 3 * mat_th + laser_pad;
    
    difference () {
        union () {
            cube ([3 * mat_th, y, mat_th]);
        
            translate ([off, 0, 0])
            cube ([screw_thr_len + 2 * mat_th, y - 2 * mat_th, mat_th]);
        }
        // Remove tng slot
        translate ([mat_th, y/2, 0])
        tng_n (y - 2 * mat_th, 3);
        
        // Remove tnut hole
        translate ([mat_th * 3/2, y/2, 0])
        tnut_hole ();
        
        // Remove tng from male side
        translate ([off, y/2 - mat_th, 0])
        tng_p (y - 2 * mat_th, 3); 
        
        // Remove tnut
        translate ([off, y/2 - mat_th, 0])
        tnut_female (1);
        
        // Remove nut hole
        translate ([off + nut_od_c2c / 2 + screw_thr_len - mat_th, nut_od_f2f / 2 + 2, 0])
        nut_hole ();
    }
}

module head_side ()
{
    x = head_z;
    y = head_y;
    r = pivot_support_r;
    
    difference () {
        union () {
            hull () {
                translate ([0, y, 0])
                cube ([x, 0.01, mat_th]);
                
                // Add pivot point
                translate ([r, y + pivot_support_r, 0])
                cylinder (r = pivot_support_r, h = mat_th, $fn = 20);
            }
            cube ([x, y, mat_th]);
        }
            
        // Remove pivot
        translate ([r, y + r, 0])
        cylinder (r = pivot_r, h = mat_th, $fn = 20);
        
        // Remove slots
        translate ([0, y / 2, 0])
        tng_n (y, 3);
        translate ([x - mat_th, y / 2, 0])
        tng_n (y, 3);
        
        // Remove lincoln log slots
        translate ([0, mat_th, 0])
        cube ([x / 2, mat_th, mat_th]);
        translate ([0, y - 3 * mat_th, 0])
        cube ([x / 2, mat_th, mat_th]);
    }
}

module head_front_back ()
{
    x = head_x;
    y = head_z;
    
    difference () {
        cube ([x, y, mat_th]);
        
        // Remove grooves
        translate ([x / 2, 0, 0])
        rotate ([0, 0, 90])
        tng_n (x, 3);
        translate ([x / 2, y - mat_th, 0])
        rotate ([0, 0, 90])
        tng_n (x, 3);
        
        // Remove assembly slots
        translate ([mat_th, y / 2, 0])
        cube ([mat_th, y / 2, mat_th]);
        translate ([x - 2 * mat_th, y / 2, 0])
        cube ([mat_th, y / 2, mat_th]);
    }
}

module lock_tab ()
{
    translate ([-tab_length/2, 0, 0])
    cube ([tab_length, tab_width, mat_th]);
    translate ([-tab_length/2, tab_width/2, 0])
    cylinder (r = tab_width / 2, h = mat_th, $fn = 20);
}

module head_base ()
{
    nut_offset = 2 * mat_th + screw_r;
    
    difference () {
        
        union () {
            // Common base
            head_base_common ();

            // Add lock tabs
            translate ([0, head_y / 12 - tab_width / 2, 0])
            lock_tab ();
            translate ([head_x, head_y / 12 - tab_width / 2, 0])
            mirror ([1, 0, 0])
            lock_tab ();
        }

        // Remove back cutout
        translate ([2 * mat_th, head_y - mat_th, 0])
        cube ([head_x - 4 * mat_th, mat_th, mat_th]);

        // Remove holes for hex nuts
        translate ([nut_offset, nut_offset, 0])
        tnut_hole ();
        translate ([head_x - nut_offset, nut_offset, 0])
        tnut_hole ();
        // Offset these +1 mat_th to allow cutout for swivel
        translate ([nut_offset, head_y - nut_offset - mat_th, 0])
        tnut_hole ();
        translate ([head_x - nut_offset, head_y - nut_offset - mat_th, 0])
        tnut_hole ();
        
        // Take 1/3 mouse bit out of front of tabs
        translate ([-2 * mat_th - washer_th, head_y / 12 - tab_width / 2, 0])
        cube ([mat_th, tab_width / 3, mat_th]);
        translate ([head_x + mat_th + washer_th, head_y / 12 - tab_width / 2, 0])
        cube ([mat_th, tab_width / 3, mat_th]);

        // Add revision backwards and upside down
        translate ([head_x / 2, head_y - 25, 0])
        linear_extrude (height = mat_th)
        rotate ([0, 0, 180])
        mirror ([1, 0, 0])
        text (rev, font = FONTNAME, halign = "center", valign = "center", size = 6);
    }
}

module logo () {
    linear_extrude (height = mat_th)
    translate ([-logo_w / 2, -logo_h / 2, 0])
    import (logo);
}

module head_top ()
{
    hole_offset = 2 * mat_th + screw_r;
    pad = 0.1;
    
    difference () {
        
        // Common base
        head_base_common ();
        
        // Remove holes for hex nuts
        translate ([hole_offset, hole_offset, 0])
        cylinder (r = screw_r + pad, h = mat_th);
        translate ([hole_offset, head_y - hole_offset - mat_th, 0])
        cylinder (r = screw_r + pad, h = mat_th);
        translate ([head_x - hole_offset, head_y - hole_offset - mat_th, 0])
        cylinder (r = screw_r + pad, h = mat_th);
        translate ([head_x - hole_offset, hole_offset, 0])
        cylinder (r = screw_r + pad, h = mat_th);

        // Add osh logo
        translate ([head_x / 2, head_y - 30, 0])
        logo ();
        
        // Remove cable relief holes
        translate ([mat_th * 3 + screw_d, head_y - (5 * mat_th) - screw_r, 0])
        tnut_hole ();
        translate ([head_x - (mat_th * 3 + screw_d), head_y - (5 * mat_th) - screw_r, 0])
        tnut_hole ();
    }
}

module cable_retention ()
{
    x = head_x - 2 * (mat_th * 3 + screw_d);
    difference () {
        
        hull () {
            cylinder (r=screw_d, h=mat_th);
            translate ([x, 0, 0])
            cylinder (r=screw_d, h=mat_th);            
        }
        
        // Remove holes
        tnut_hole ();
        translate ([x, 0, 0])
        tnut_hole ();
    }
}

module head_base_common ()
{
    difference () {
        
        // Base cube
        cube ([head_x, head_y, mat_th]);
                
        // Remove slots
        translate ([mat_th, head_y / 2, 0])
        tng_p (head_y, 3);
        translate ([head_x - 2 * mat_th, head_y / 2, 0])
        tng_p (head_y, 3);
        translate ([head_x / 2, head_y - 3 * mat_th, 0])
        rotate ([0, 0, 90])
        tng_p (head_x + mat_th, 3);
        translate ([head_x / 2, mat_th, 0])        
        rotate ([0, 0, 90])
        tng_p (head_x + mat_th, 3);
        
        // Calc (x,y) origin = (0, 0)
        origin_x = active_x_offset;
        origin_y = active_x_offset + work_area_y;
    
        // Loop over test points
        for ( i = [0 : len (test_points) - 1] ) {
        
            // Drop pins for test points
            translate ([origin_x + test_points[i][0], origin_y - test_points[i][1], 0])
            cylinder (r = pogo_r, h = mat_th);
        }
    }
}
module latch_support ()
{
    x = base_x + 2 * mat_th + 2 * washer_th;
    y = latch_support_y;
    
    difference () {
        cube ([x, y, mat_th]);
        
        // Remove tng
        translate ([0, y / 2, 0])
        tng_p (y, 3);
        translate ([x - mat_th, y / 2, 0])
        tng_p (y, 3);
        
        // Remove tnut captures
        translate ([0, y/2, 0])
        tnut_female (1);
        translate ([x, y/2, 0])
        rotate ([0, 0, 180])
        tnut_female (1);
    }
}

module latch ()
{    
    pad = tab_width / 12;
    y = base_z * (2 / 3) + base_pivot_offset - pivot_support_r;
    difference () {
  
        hull () {
            cylinder (r = tab_width / 2, h = mat_th, $fn = 20);
            translate ([0, y + screw_d, 0])
            cylinder (r = tab_width / 2, h = mat_th, $fn = 20);

            // Cross support
            translate ([-screw_d - support_x, 0, 0])
            cube ([support_x, y, mat_th]);
        }
        
       // Remove screw hole
       cylinder (r = screw_r, h = mat_th, $fn = 20);
       
       // Remove slot
       translate ([-screw_r, y, 0])
       cube ([(3 * tab_width) / 4, mat_th + pad, mat_th]);
       
       // Remove tng
       translate ([-support_x - nut_pad, y / 2, 0])
       tng_n (y - 2 * mat_th, 3);
       
       // Remove support hole
       translate ([-support_x + mat_th / 2 - nut_pad, y / 2, 0])
       tnut_hole ();
    }
}
module base_side ()
{
    x = base_z;
    y = base_y;
    
    difference () {
        union () {
            cube ([x, y, mat_th]);
            
            // Add pivot structure
            hull () {
                translate ([x + base_pivot_offset, y - pivot_support_d / 2, 0])
                cylinder (r = pivot_support_d / 2, h = mat_th, $fn = 20);
                translate ([0, y - pivot_support_d, 0])
                cube ([1, pivot_support_d, mat_th]);
            }
        }
        
        // Remove pivot hole
        translate ([x + base_pivot_offset, y - pivot_support_d / 2, 0])
        cylinder (r = pivot_r, h = mat_th, $fn = 20);

        // Remove carrier slots
        translate ([x - mat_th, head_y / 2, 0])
        tng_p (head_y, 7);
        translate ([x - 2 * mat_th, head_y / 2, 0])
        tng_p (head_y, 7);
        
        // Remove tnut slot
        translate ([x, head_y / 2, 0])
        rotate ([0, 0, 180])
        tnut_female (2);
        
        // Offset from bottom
        support_offset = 2 * mat_th;
        
        // Cross bar support
        translate ([support_offset, head_y / 6, 0])
        mirror ([0, 1, 0])
        tng_n (head_y / 3, 2);
        translate ([support_offset + mat_th / 2, head_y / 12, 0])
        tnut_hole ();
        
        // Second cross bar support
        translate ([support_offset, head_y - (head_y / 6 + mat_th), 0])
        tng_n (head_y / 3, 3);
        translate ([support_offset + mat_th / 2, head_y - (head_y / 6 + mat_th), 0])
        tnut_hole ();
        
        // Back support
        translate ([x / 2 + mat_th, y - pivot_support_d / 2 - (mat_th / 2), 0])
        rotate ([0, 0, 90])
        tng_n (x, 3);
        translate ([x / 2 + mat_th, y - pivot_support_d / 2, 0])        
        tnut_hole ();
    }
}

module base_front_support ()
{
    x = base_x;
    y = head_y/3;
    
    difference () {
        // Base cube
        cube ([x, y, mat_th]);
        
        // Remove slots
        translate ([0, y / 2, 0])
        mirror ([0, 1, 0])
        tng_p (y, 2);
        translate ([x - mat_th, y / 2, 0])
        mirror ([0, 1, 0])
        tng_p (y, 2);
        
        // Remove female tnuts
        translate ([0, y / 4, 0])
        tnut_female (1, length = screw_thr_len - mat_th);
        translate ([x, y / 4, 0])
        rotate ([0, 0, 180])
        tnut_female (1, length = screw_thr_len - mat_th);
    }
}

module base_support (length)
{
    x = base_x;
    y = length;
    
    difference () {
        // Base cube
        cube ([x, y, mat_th]);
        
        // Remove slots
        translate ([0, y / 2, 0])
        tng_p (y, 3);
        translate ([x - mat_th, y / 2, 0])
        tng_p (y, 3);
        
        // Remove female tnuts
        translate ([0, y / 2, 0])
        tnut_female (1);
        translate ([x, y / 2, 0])
        rotate ([0, 0, 180])
        tnut_female (1);
    }
}

module base_back_support ()
{
    difference () {
        union () {
            base_support (base_z);
        
            // Add additional support to receive pivot screw and nut
            translate ([3 * mat_th, base_z, 0])
           cube ([base_x - 6 * mat_th, base_pivot_offset + mat_th + 1.5, mat_th]);
        }
        
        // Remove tnut supports
        translate ([0, base_z + base_pivot_offset - mat_th, 0])
        tnut_female (3);

        // Remove tnut supports
        translate ([base_x, base_z + base_pivot_offset - mat_th, 0])
        rotate ([0, 0, 180])
        tnut_female (3);
    }
}

module spacer ()
{
    difference () {
        cylinder (r = pivot_support_r, h = mat_th, $fn = 20);
        cylinder (r = pivot_r, h = mat_th, $fn = 20);
    }
}

module carrier (dxf_filename, pcb_x, pcb_y, border)
{
    x = base_x;
    y = head_y;
    
    // Calculate scale factors
    scale_x = 1 - ((2 * border) / pcb_x);
    scale_y = 1 - ((2 * border) / pcb_y);

    difference () {
        cube ([x, y, mat_th]);
        
        // Get scale_offset
        sx_offset = (pcb_x - (pcb_x * scale_x)) / 2;
        sy_offset = (pcb_y - (pcb_y * scale_y)) / 2;

        // Import dxf, extrude and translate
        translate ([mat_th + active_x_offset + tp_correction_offset_x, 
                   work_area_y + active_y_offset + tp_correction_offset_y, 0])
        translate ([sx_offset, -sy_offset, 0])
        hull () {
            linear_extrude (height = mat_th)
            scale ([scale_x, scale_y, 1])
            import (dxf_filename);
        }
        
        // Remove slots
        translate ([0, y/2, 0])
        tng_n (y, 7);
        translate ([x - mat_th, y/2, 0])
        tng_n (y, 7);
        
        // Remove holes
        translate ([mat_th / 2, y / 2, 0])
        tnut_hole ();
        translate ([x - mat_th / 2, y / 2, 0])
        tnut_hole ();
        
        // Add revision ID, also allows to determine which side is top
        translate ([x / 2, y - 25, 0])
        linear_extrude (height = mat_th)
        text (rev, font = FONTNAME, halign = "center", valign = "center", size = 6);
    }
}

//
// 3D renderings of assembly
//
module 3d_head ()
{
    head_top_offset = head_z - mat_th;
    
    head_base ();
    translate ([2 * mat_th, 0, 0])
    rotate ([0, -90, 0])
    head_side ();
    translate ([head_x - mat_th, 0, 0])
    rotate ([0, -90, 0])
    head_side ();
    translate ([0, 0, head_top_offset])
    head_top ();
    translate ([0, head_y - 2 * mat_th, 0])
    rotate ([90, 0, 0])
    head_front_back ();
    translate ([0, 2 * mat_th, 0])
    rotate ([90, 0, 0])
    head_front_back ();
    translate ([mat_th * 3 + screw_d, head_y - (5 * mat_th) - screw_r, head_top_offset + mat_th + 1])
    cable_retention ();
}

module 3d_base () {
    // Base sides
    rotate ([0, -90, 0])
    base_side ();
    translate ([head_x + mat_th, 0, 0])
    rotate ([0, -90, 0])
    base_side ();
    
    // Supports
    translate ([-mat_th, 0, 2 * mat_th])
    base_front_support ();
    translate ([-mat_th, head_y - (head_y / 3) - mat_th, 2 * mat_th])
    base_support (head_y / 3);
    translate ([-mat_th, base_y - pivot_support_r + mat_th/2, mat_th])
    rotate ([90, 0, 0])
    base_back_support ();
    
    // Add spacers
    translate ([0, base_y - pivot_support_r, base_z + base_pivot_offset])
    rotate ([0, 90, 0])
    spacer ();
    translate ([base_x - 3 * mat_th, base_y - pivot_support_r, base_z + base_pivot_offset])
    rotate ([0, 90, 0])
    spacer ();
    
    // Add carrier blank and carrier
    translate ([-mat_th, 0, base_z - (2 * mat_th)])
    carrier (pcb_outline, pcb_x, pcb_y, pcb_support_border);
    translate ([-mat_th, 0, base_z - mat_th])
    carrier (pcb_outline, pcb_x, pcb_y, 0);
}

module 3d_latch () {
    // Add latches
    translate ([-mat_th * 2 - washer_th, 0, 0])
    rotate ([0, 90, 0])
    latch ();
    translate ([base_x - mat_th + washer_th, 0, 0])
    rotate ([0, 90, 0])
    latch ();
    translate ([-2 * mat_th - washer_th, latch_z_offset / 4, support_x - mat_th + nut_pad])
    latch_support ();    
}

module 3d_model () {
    translate ([0, 0, base_z + base_pivot_offset - pivot_support_r])
    translate ([0, head_y + pivot_support_r, pivot_support_r])
    rotate ([-8, 0, 0])
    translate ([0, -head_y - pivot_support_r, -pivot_support_r])
    3d_head ();
    3d_base ();
    translate ([0, head_y / 12, base_z / 3])
    rotate([120, 0, 0])
    3d_latch ();
}

module validate_testpoints (dxf_filename)
{
    hull () {
        linear_extrude (height = mat_th)
        import (dxf_filename);
    }
    // Loop over test points
    for ( i = [0 : len (test_points) - 1] ) {
    
        // Drop pins for test points
        color ([1, 0, 0])
        translate ([test_points[i][0], -test_points[i][1], 0])
        cylinder (r = pogo_r, h = mat_th);
    }
}

module lasercut ()
{
    // Add carrier panels
    carrier (pcb_outline, pcb_x, pcb_y, pcb_support_border);
    xoffset1 = base_x + laser_pad;
    translate ([xoffset1, 0, 0])
    carrier (pcb_outline, pcb_x, pcb_y, -0.05);
    
    // Add head top
    xoffset2 = xoffset1 + base_x + laser_pad;
    translate ([xoffset2, 0, 0])
    head_top ();

    // Add head base, flip to take advantage of kerf securing nuts
    xoffset3 = xoffset2 + 2 * head_x + tab_length + laser_pad;
    translate ([xoffset3, 0, 0])
    mirror ([1, 0, 0])
    head_base ();
    
    // Add base sides
    xoffset4 = xoffset3 + tab_length + laser_pad;
    translate ([xoffset4, 0, 0])
    base_side ();
    xoffset5 = xoffset4 + 2 * base_z + base_pivot_offset + pivot_support_r + laser_pad;
    translate ([xoffset5, base_y, 0])
    rotate ([0, 0, 180])
    base_side ();
    
    // Add spacer in center
    xoffset6 = xoffset4 + (2 * base_z + base_pivot_offset) / 2 + laser_pad;
    yoffset1 = 2 * pivot_support_d + laser_pad;
    translate ([xoffset6, yoffset1, 0])
    spacer ();
    yoffset2 = yoffset1 + pivot_support_d + laser_pad;
    translate ([xoffset6, yoffset2, 0])
    spacer ();

    // Add base supports
    xoffset7 = xoffset6 + base_z + base_pivot_offset + laser_pad;
    translate ([xoffset7, 0, 0])
    base_front_support ();
    yoffset3 = head_y / 3 + laser_pad;
    translate ([xoffset7, yoffset3, 0])
    base_support (head_y / 3);
    yoffset4 = yoffset3 + head_y / 3 + laser_pad;
    translate ([xoffset7, yoffset4, 0])
    base_back_support ();

    // Add head sides
    xoffset8 = xoffset7 + base_x + laser_pad;
    translate ([xoffset8, 0, 0])
    head_side ();
    xoffset9 = xoffset8 + head_z + laser_pad;
    translate ([xoffset9, 0, 0])
    head_side ();
    
    // Add front latch support
    xoffset10 = xoffset9 + head_z + laser_pad;
    translate ([xoffset10, 0, 0])
    latch_support ();
 
    // Add head front/back
    yoffset5 = latch_support_y + laser_pad;
    translate ([xoffset10, yoffset5, 0])
    head_front_back ();
    yoffset6 = yoffset5 + head_z + laser_pad;
    translate ([xoffset10, yoffset6, 0])
    head_front_back ();

    // Add cable retention
    yoffset7 = yoffset6 + head_z + laser_pad + screw_d;
    translate ([xoffset10 + screw_d, yoffset7, 0])
    cable_retention ();

    // Add latches
    xoffset11 = xoffset10 + screw_d + support_x + laser_pad;
    //yoffset8 = yoffset7 + base_z + screw_d + laser_pad;
    yoffset8 = yoffset7 + screw_d + tab_width / 2 + laser_pad;
    translate ([xoffset11, yoffset8, 0])
    latch ();
    xoffset12 = xoffset11 + screw_d + support_x + tab_width / 2 + laser_pad;
    translate ([xoffset12, yoffset8, 0])
    latch ();
}
