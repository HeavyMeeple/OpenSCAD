// cardnest.scad — Parametric Card Nest Organizer
// Original parametric code.  All units: mm.
//
// Parts generated:
//   1. Tray  — hex-floor box with optional dividers and grip ridges
//   2. Lid   — snap-fit lid with pull tab (one per compartment)
//   3. Labels — embossed label strips with index tab
//   4. Panel  — decorative flat hex tile

$fn = 48;

// ── Parameters ───────────────────────────────────────────────────

/* [Tray] */
box_w   = 98;    // outer width  (X, mm)
box_l   = 150;   // outer length (Y, mm)
box_h   = 50;    // outer height (Z, mm)
wall_t  = 1.5;   // wall thickness (mm)
floor_t = 2;     // floor thickness (mm)

/* [Compartments] */
num_dividers = 1;  // interior dividers along the length

/* [Hex Floor] */
hex_r   = 5;     // hex circumradius (mm)
hex_gap = 1.5;   // solid wall between adjacent hexagons (mm)

/* [Grip Ridges] */
ridges     = true;   // raised fin ridges on one long wall exterior
ridge_w    = 2;      // fin width  (mm)
ridge_h    = 1.5;    // fin protrusion (mm)
ridge_step = 4;      // fin centre-to-centre pitch (mm)

/* [Lid] */
make_lid      = true;
lid_clearance = 0.2;  // fit clearance per side (mm)
lid_t         = 2;    // lid thickness (mm)

/* [Label Strips] */
make_labels  = true;
label_count  = 3;        // how many strips to generate (max 3)
label_text_1 = "Deck 1";
label_text_2 = "Deck 2";
label_text_3 = "Deck 3";

/* [Hex Panel] */
make_panel   = false;
panel_text   = "Card Nest";
panel_t      = 2.4;   // panel thickness (mm)
panel_border = 4;     // solid border around hex area (mm)

// ── Hex grid (2D) ────────────────────────────────────────────────
// Pointy-top hexagons, tiled to fill w × l, centred at origin.
// Gap between any two adjacent hexagon edges = hex_gap.

_hp = sqrt(3) * hex_r + hex_gap;   // horizontal pitch (within-row)
_vp = _hp * sqrt(3) / 2;           // vertical pitch   (between rows)

module hex_grid(w, l) {
    nc = ceil(w / _hp) + 2;
    nr = ceil(l / _vp) + 2;
    intersection() {
        square([w, l], center = true);
        for (row = [-nr : nr]) {
            xoff = (row % 2 != 0) ? _hp / 2 : 0;
            for (col = [-nc : nc])
                translate([col * _hp + xoff, row * _vp])
                    rotate([0, 0, 30]) circle(r = hex_r, $fn = 6);
        }
    }
}

// ── Tray ─────────────────────────────────────────────────────────
_iw = box_w - 2 * wall_t;   // inner width
_il = box_l - 2 * wall_t;   // inner length

module tray() {
    difference() {
        union() {
            cube([box_w, box_l, box_h]);

            // raised grip ridges on the Y = box_l exterior face
            if (ridges)
                for (x = [ridge_w / 2 : ridge_step : box_w - ridge_w / 2])
                    translate([x - ridge_w / 2, box_l, 0])
                        cube([ridge_w, ridge_h, box_h]);
        }

        // hollow interior (open top)
        translate([wall_t, wall_t, floor_t])
            cube([_iw, _il, box_h]);

        // hex cut-outs through the floor
        translate([box_w / 2, box_l / 2, 0])
            linear_extrude(floor_t + 0.01)
                hex_grid(_iw - 2, _il - 2);
    }

    // interior dividers
    if (num_dividers > 0) {
        _step = _il / (num_dividers + 1);
        for (i = [1 : num_dividers])
            translate([wall_t,
                       wall_t + i * _step - wall_t / 2,
                       floor_t])
                cube([_iw, wall_t, box_h - floor_t]);
    }
}

// ── Lid (centred at origin) ───────────────────────────────────────
_lw = _iw - 2 * lid_clearance;
_ll = _il / (num_dividers + 1) - 2 * lid_clearance;

module lid() {
    tab_w = 14;
    tab_d = 5;
    union() {
        cube([_lw, _ll, lid_t], center = true);
        // rounded pull tab along one short edge
        translate([0, _ll / 2 + tab_d / 2, 0])
            hull() {
                cube([tab_w, 0.01, lid_t], center = true);
                translate([0, tab_d * 0.9, 0])
                    cylinder(h = lid_t, r = tab_w / 4, center = true);
            }
    }
}

// ── Label strip (centred at origin) ──────────────────────────────
_lab_w  = 45;
_lab_h  = 10;
_lab_t  = 1.2;
_tab_ht = 5;

module label_strip(txt) {
    difference() {
        union() {
            cube([_lab_w, _lab_h, _lab_t], center = true);
            // small index tab above the strip
            translate([0, _lab_h / 2 + _tab_ht / 2, 0])
                cube([_lab_w * 0.35, _tab_ht, _lab_t], center = true);
        }
        // debossed text
        translate([0, 0, _lab_t / 2 - 0.3])
            linear_extrude(0.4)
                text(txt, size = 5,
                     font = "Liberation Sans:style=Bold",
                     halign = "center", valign = "center");
    }
}

// ── Hex panel (centred at origin) ────────────────────────────────
_pw = box_w - 2 * wall_t;
_pl = box_l - 2 * wall_t;

module hex_panel() {
    difference() {
        cube([_pw, _pl, panel_t], center = true);
        linear_extrude(panel_t + 0.01, center = true)
            hex_grid(_pw - 2 * panel_border, _pl - 2 * panel_border);
    }
    // raised text on top face
    translate([0, 0, panel_t / 2])
        linear_extrude(0.6)
            text(panel_text, size = 12,
                 font = "Liberation Sans:style=Bold",
                 halign = "center", valign = "center");
}

// ── Print layout ─────────────────────────────────────────────────
// Tray at origin
tray();

// Lids arranged to the right of the tray
if (make_lid) {
    for (i = [0 : num_dividers])
        translate([box_w + 20 + i * (_lw + 10),
                   box_l / 2,
                   lid_t / 2])
            lid();
}

// Label strips below the tray
if (make_labels) {
    _texts = [label_text_1, label_text_2, label_text_3];
    for (i = [0 : min(label_count, 3) - 1])
        translate([_lab_w / 2 + 5,
                   -((_lab_h + _tab_ht) + 8) * (i + 1),
                   _lab_t / 2])
            label_strip(_texts[i]);
}

// Hex panel above the tray
if (make_panel)
    translate([box_w / 2, box_l + 25, panel_t / 2])
        hex_panel();
