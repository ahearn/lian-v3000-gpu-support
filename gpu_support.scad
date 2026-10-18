// =====================================================================
//  Floor-standing support for three water-blocked GPUs
//  Lian Li V3000 PLUS (Standard layout) + ASRock TRX40 Creator
//  Supported cards in case slots 1/3/5; an unsupported 2.5-slot air-cooled card in slot 7
//
//  Material: PETG. Three part types:
//    rail    - screws to the main-compartment floor through the vent/rad
//              plate's glass-side flange holes (stock screw holes, longer screws), has an
//              M4 T-nut channel so the post can slide front/back
//    column  - upright post standing outboard (glass side) of all cards
//    finger  - one per supported card, bolts to the post through vertical slots
//              that run most of its height, reaches under the block
//
//  ALL GEOMETRY IS IN CASE COORDINATES taken from Lian Li's STEP model:
//    X = width  (+X toward motherboard tray, glass at X = -135.5)
//    Y = up     (main-compartment floor sheet top = 189.2)
//    Z = depth  (+Z toward front, PCIe brackets at Z ~ -306)
//  The `part` selector below re-orients each part for printing.
// =====================================================================

part = "assembly"; // [assembly, parts_in_case, gpus, rail, column, finger1, finger2, finger3, plate]

/* ---------------- things to measure / tune ---------------- */
block_drop     = 13.5;  // block bottom face below PCIe connector/PCB centre (user measured)
pcb_offset     = 6.0;   // PCB centre above slot-cover centre (PCIe CEM envelope; verify)
pad_t          = 2.0;   // rubber/felt pad stuck on each finger top
col_z          = -120;  // post centre, front/back. Block far end ~ -66, terminal ahead of that
finger_reach   = 0.5;   // fingers reach this fraction of the way from card outer edge to motherboard
len_gpu        = 240;   // supported cards: bracket outer face -> far end of water block
len_low        = 330;   // lower (unsupported) card, clearance check only
h_gpu          = 140;   // card height incl. block (connector edge -> top edge)
h_low          = 140;

/* ---------------- case geometry (from STEP) ---------------- */
floor_y   = 189.2;   // floor sheet top, glass-side strip X -129.3..-109.5
flange_y  = 190.2;   // vent/rad plate outer flange top, X -109.5..-94.3
mesh_y    = 192.2;   // vent plate raised hex mesh, X > -94.3
flange_x0 = -109.5;
mesh_x0   = -94.3;
anchor_x  = -104.5;            // line of holes along the vent plate's glass-side flange
// every flange hole under the rail: [Z, has raised collar]. The stock M3 vent-plate
// screws are at -268.5 and -115; the rest serve other case layouts.
flange_holes = [[-283.5, true], [-268.5, false], [-115.0, false], [-105.5, true], [-96.0, false]];
bracket_z = -306;              // outer face of PCIe brackets
card_x0   = 77;                // card edge-connector bottom
mobo_x    = 80.1;              // motherboard component surface
// case slot-cover centre heights, slots 1..8 (20.32 pitch)
slot_c = [362.9, 342.6, 322.3, 301.9, 281.6, 261.3, 241.0, 220.7];
gpu_slots = [1, 3, 5];         // supported (water-blocked) cards
slot_low  = 7;                 // lower air-cooled card

function pcb_y(s)      = slot_c[s-1] + pcb_offset;
function block_bot(s)  = pcb_y(s) - block_drop;
function back_top(s)   = pcb_y(s) + 0.8 + 5;   // backplate top (estimate)

/* ---------------- support dimensions ---------------- */
col_w      = 26;      // Z width of post and fingers
bolt_dz    = 6.5;     // the two M4 bolts per finger sit at col_z +/- bolt_dz
foot_w     = 60;      // Z width of the foot
foot_bolt_dz = 22;    // foot bolts sit outboard of the post so they stay reachable

rail_x0    = -128;  rail_x1 = -97;  step_x = -110;   // mesh ramps up from X -96
rail_z0    = -290;  rail_z1 = -55;   // rear end clears the PCIe slot frame at Z -295.5
rail_top   = 199.2;
tslot_x    = -120;
nut_w      = 7.9;     // M4 nut 7.0 AF + sliding clearance
ch_skin    = 1.6;
ch_h       = 5.0;

foot_t     = 8;
foot_x0    = rail_x0;
toe_x1     = -84;     // stays clear of rad screw heads in the X -79 slots
mem_x0     = rail_x0; mem_x1 = rail_x0 + 14;  // post at the glass edge of the foot, 14 thick
foot_bolt_x = tslot_x;

root_x0    = mem_x1;  root_x1 = root_x0 + 12;
card_outer_x = card_x0 - h_gpu;
finger_tip_x = card_outer_x + finger_reach * (mobo_x - card_outer_x);
arm_t      = 12;
root_above = 12;
nut_af     = 7.45;    // M4 nut pocket across flats (snug slip fit; 7.2 was too tight)
nut_depth  = 3.8;

function arm_top(i) = block_bot(gpu_slots[i]) - pad_t;
function bolt_y(i)  = arm_top(i) + root_above/2;
col_top = bolt_y(0) + root_above/2 + 10;
gusset_h = 22;
// one pair of long slots runs most of the post height; any finger can sit anywhere along them
slot_y0 = rail_top + foot_t + gusset_h + 4;
slot_y1 = col_top - 6;

$fn = 40;

/* ---------------- helpers ---------------- */
module xcyl(d, h, fn=32) rotate([0,90,0]) cylinder(d=d, h=h, $fn=fn);
module ycyl(d, h, fn=32) rotate([-90,0,0]) cylinder(d=d, h=h, $fn=fn);
// hex with vertices toward +/-Z (prints well with Z up)
module xhex(af, h) rotate([0,90,0]) rotate([0,0,0]) cylinder(d=af/cos(30), h=h, $fn=6);

/* ---------------- rail ---------------- */
module rail() {
    L = rail_z1 - rail_z0;
    difference() {
        union() {
            translate([rail_x0, floor_y, rail_z0]) cube([step_x - rail_x0, rail_top - floor_y, L]);
            translate([step_x, flange_y + 0.1, rail_z0]) cube([rail_x1 - step_x, rail_top - flange_y - 0.1, L]);
        }
        // M4 T-nut channel, open at both ends
        translate([tslot_x - nut_w/2, floor_y + ch_skin, rail_z0 - 1]) cube([nut_w, ch_h, L + 2]);
        translate([tslot_x - 2.3, floor_y + ch_skin + 1, rail_z0 + 8]) cube([4.6, 20, L - 16]);
        // a counterbored M3 hole over every flange hole; pockets clear the raised collars
        for (h = flange_holes) translate([anchor_x, 0, h[0]]) {
            translate([0, flange_y - 1, 0]) ycyl(3.4, 20);
            translate([0, rail_top - 4, 0]) ycyl(6.8, 10);
            if (h[1]) translate([0, flange_y - 1, 0]) ycyl(6.4, 2.6);
        }
        // chamfer top edges
        for (x = [rail_x0, rail_x1]) translate([x, rail_top, rail_z0 - 1])
            rotate([0,0,45]) cube([2, 2, L + 2], center=false);
    }
}

/* ---------------- column ---------------- */
module column() {
    z0  = col_z - col_w/2;
    fz0 = col_z - foot_w/2;
    ft  = rail_top + foot_t;
    difference() {
        union() {
            translate([foot_x0, rail_top, fz0]) cube([toe_x1 - foot_x0, foot_t, foot_w]);
            // toe drops past the rail edge onto the mesh; 45 deg underside so it
            // prints without support (the post prints standing on its glass-side face)
            translate([0, 0, fz0]) linear_extrude(foot_w)
                polygon([[rail_x1 + 0.5, rail_top + 0.01],
                         [rail_x1 + 0.5 + (rail_top - mesh_y), mesh_y],
                         [toe_x1, mesh_y], [toe_x1, rail_top + 0.01]]);
            translate([mem_x0, rail_top, z0]) cube([mem_x1 - mem_x0, col_top - rail_top, col_w]);
            // gusset on the compression (+X) side
            translate([0, 0, z0]) linear_extrude(col_w)
                polygon([[mem_x1 - 0.01, ft - 0.01], [toe_x1, ft - 0.01], [mem_x1 - 0.01, ft + gusset_h]]);
        }
        // foot bolts into rail T-nuts
        for (dz = [-foot_bolt_dz, foot_bolt_dz])
            translate([foot_bolt_x, rail_top - 1, col_z + dz]) ycyl(4.5, foot_t + 2);
        // long finger slots
        for (dz = [-bolt_dz, bolt_dz])
            hull() for (y = [slot_y0, slot_y1])
                translate([mem_x0 - 1, y, col_z + dz]) xcyl(4.5, mem_x1 - mem_x0 + 2);
        // tick marks on the glass-side face beside the slots: every 5 mm, long every 10 mm
        for (y = [slot_y0 : 5 : slot_y1])
            let (long = (round(y - slot_y0) % 10) == 0)
            translate([mem_x0 - 0.01, y - 0.4, col_z + col_w/2 - (long ? 3.5 : 2)])
                cube([0.8, 0.8, 4]);
    }
}

/* ---------------- finger ---------------- */
module finger(i) {
    top = arm_top(i);
    bot = top - arm_t;
    by  = bolt_y(i);
    z0  = col_z - col_w/2;
    difference() {
        union() {
            translate([root_x0, bot, z0]) cube([root_x1 - root_x0, top + root_above - bot, col_w]);
            // arm, lower outer edge chamfered toward the tip
            translate([0, 0, z0]) linear_extrude(col_w)
                polygon([[root_x1 - 0.01, bot], [finger_tip_x - 6, bot],
                         [finger_tip_x, bot + 4], [finger_tip_x, top],
                         [root_x1 - 0.01, top]]);
            // fillet arm-to-root
            translate([0, 0, z0]) linear_extrude(col_w)
                polygon([[root_x1 - 0.01, top - 0.01], [root_x1 + 5, top - 0.01], [root_x1 - 0.01, top + 5]]);
        }
        for (dz = [-bolt_dz, bolt_dz]) {
            translate([root_x0 - 1, by, col_z + dz]) xcyl(4.5, 30);
            translate([root_x1 - nut_depth, by, col_z + dz]) xhex(nut_af, nut_depth + 1);
        }
        // finger number, engraved on the top (+Z) face
        translate([root_x0 + 6, by - 4, z0 + col_w - 0.6])
            linear_extrude(1) text(str(i + 1), size = 7, halign = "center", font = "Liberation Sans:style=Bold");
    }
}

/* ---------------- GPU envelopes (reference only) ---------------- */
module gpu_supported(s) {
    color([0.2, 0.6, 0.2, 0.35])
        translate([card_x0 - h_gpu, block_bot(s), bracket_z])
            cube([h_gpu, back_top(s) - block_bot(s), len_gpu]);
}
module gpu_lower() {
    top = back_top(slot_low);
    bottom = slot_c[slot_low-1] + 10.16 - 2.5*20.32;
    color([0.2, 0.3, 0.8, 0.35])
        translate([card_x0 - h_low, bottom, bracket_z]) cube([h_low, top - bottom, len_low]);
}
// multi-GPU terminal at the far end of the blocks (assumed 35 mm deep keep-out)
module terminal() {
    color([0.9, 0.5, 0.1, 0.35])
        translate([-30, block_bot(gpu_slots[2]) - 2, bracket_z + len_gpu - 35])
            cube([60, pcb_y(gpu_slots[0]) - block_bot(gpu_slots[2]) + 2, 50]);
}
module case_ref() {
    color([0.6,0.6,0.6]) {
        translate([-129.3, floor_y - 1.2, -310]) cube([258.6, 1.2, 620]);
        translate([flange_x0, floor_y, -310.5]) cube([208, 1, 410]);
        translate([mesh_x0, flange_y, -289]) cube([155.6, 2, 367]);
    }
    // glass panel at X = -135.5 (not drawn)
    color([0.5,0.5,0.5,0.4]) translate([80.1, 229, -306]) cube([1.6, 305, 244]);     // ATX board
}

module support_in_case() {
    color("orange") rail();
    color("gold") column();
    for (i = [0:2]) color([1, 0.4 + i*0.15, 0.1]) finger(i);
}

/* ---------------- print orientations ---------------- */
// rail: printed upside down (flat top face on the bed)
module rail_print()   translate([-rail_x0, 0, rail_top]) rotate([-90, 0, 0]) translate([0,0,0]) rail();
// column: printed standing on its glass-side (-X) face so the long slots are
// vertical (no bridging) and the post's bending stresses run along the layers
module column_print() translate([col_z + foot_w/2, -mesh_y, -foot_x0]) rotate([0, -90, 0]) column();
// fingers: printed on their side (XY profile on the bed)
module finger_print(i) translate([-root_x0, -(arm_top(i) - arm_t), -(col_z - col_w/2)]) finger(i);

if (part == "assembly") {
    rotate([90, 0, 0]) {   // show with case Y as up
        support_in_case();
        for (s = gpu_slots) gpu_supported(s);
        gpu_lower();
        terminal();
        case_ref();
    }
} else if (part == "parts_in_case") {
    support_in_case();
} else if (part == "gpus") {
    for (s = gpu_slots) gpu_supported(s);
    gpu_lower();
    terminal();
} else if (part == "rail")    rail_print();
else if (part == "column")    column_print();
else if (part == "finger1")   finger_print(0);
else if (part == "finger2")   finger_print(1);
else if (part == "finger3")   finger_print(2);
else if (part == "plate") {   // everything laid out for one print
    // ~225 x 225 mm footprint
    translate([rail_z1 - rail_z0, 0, 0]) rotate([0, 0, 90]) translate([0, -rail_z0, 0]) rail_print();
    translate([0, 40, 0]) column_print();
    for (i = [0:2]) translate([68, 40 + i*30, 0]) finger_print(i);
}

// echo key numbers for checking
echo(str("block bottoms Y: ", [for (s = gpu_slots) block_bot(s)]));
echo(str("finger arm tops Y: ", [for (i = [0:2]) arm_top(i)]));
echo(str("gap under each block (block bottom - next card top): ",
    [block_bot(1) - back_top(3), block_bot(3) - back_top(5), block_bot(5) - back_top(7)]));
echo(str("column top Y: ", col_top, "  slot bolt-centre range Y: ", slot_y0, "..", slot_y1));
echo(str("finger travel (down/up from nominal): ",
    [for (i = [0:2]) [slot_y0 - bolt_y(i), slot_y1 - bolt_y(i)]]));
echo(str("finger tip X: ", finger_tip_x, "  reach under block: ", finger_tip_x - card_outer_x, "  arm length: ", finger_tip_x - root_x1));
