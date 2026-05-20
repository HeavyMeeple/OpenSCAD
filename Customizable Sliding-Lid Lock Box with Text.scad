include <BOSL2/std.scad>
$fn=100;

/* [Size Settings] */
// Inner Height (actual inner space = Height - bottom_wall - wall)
Height=30;
// Inner Width (actual inner space = Width - wall*2)
Width=58.8;
// Inner Length (actual inner space = Length - wall*2)
Length=90.5;
// Side and top wall thickness
wall=2;
// Bottom wall thickness (can differ from side wall)
bottom_wall=1;

/* [Compartment Settings] */
// Number of columns — dividers along the length axis (max 4)
Cols=1;
// Number of rows — dividers along the width axis (max 4)
Rows=1;
// Partition wall thickness in mm (independent of outer wall)
partition_wall=1.2;
// Partition height as a fraction of usable inner height (0.0–1.0).
// Keep below 1.0 so the lid can slide over the partitions.
PartitionHeightRatio=0.85;

/* [Column Sizes (proportional)] */
// Proportional width of column 1. Set all to 0 for equal columns.
Col1=0;
// Proportional width of column 2 (ignored if Cols < 2)
Col2=0;
// Proportional width of column 3 (ignored if Cols < 3)
Col3=0;
// Proportional width of column 4 (ignored if Cols < 4)
Col4=0;

/* [Row Sizes (proportional)] */
// Proportional depth of row 1. Set all to 0 for equal rows.
Row1=0;
// Proportional depth of row 2 (ignored if Rows < 2)
Row2=0;
// Proportional depth of row 3 (ignored if Rows < 3)
Row3=0;
// Proportional depth of row 4 (ignored if Rows < 4)
Row4=0;

/* [Text Settings] */
LidText="Credit Cards";
Text_size=9;
// Two layers at 0.2 mm per layer
TextHeight=0.4;
FontName = "Harmony OS Sans SC"; // [Anton, Archive Black, Asap, Bangers, Black Han Sans, Bubblegum Sans, Bungee, Change One, Chewy, Concert One, Fruktur, Gochi Hand, Griffy, Harmony OS Sans SC, Inter, Item, Jockey One, Jungle Fever, Kanit, Kavoon, Komikazoom, Lato, Lilita One, Lora, Luckiest Guy, Merriweather Sans, Mitr, Montserrat, Nanum Pen Script, Noto Sans SC, Nunito, Open Sans, Oswald, Palanquin Dark, Passion One, Patrick Hand, Paytone One, Permanent Marker, Playfair Display, Plus Jakarta Sans, Poetesen, Poppins, Rakkas, Raleway, Roboto, Rowdies, Rubik, Russo One, Saira Stencil One, Shrikhand, Source Sans 3, Squada One, Titan One, Ubuntu Sans, Work Sans]
// Font weight / style — affects stroke thickness of the text
FontStyle = "Regular"; // [Regular, Bold, Italic, Bold Italic]
// If not engraved, text is shown in red — pause print here to change filament color
Engraved=false;
// Show text on lid (set false to hide text when using a pattern)
ShowText=true;

/* [Lid Pattern] */
// Decoration pattern on the lid surface
LidPattern=0; // [0:None, 1:Grid, 2:Horizontal Lines, 3:Vertical Lines, 4:Honeycomb]
// Spacing between pattern lines (mm)
PatternSpacing=10;
// Pattern line width (mm)
PatternLineWidth=0.8;
// Pattern line height (mm)
PatternHeight=0.4;

/* [Honeycomb Settings] */
// Hexagon cell circumradius (center to vertex) in mm
HoneycombSize=5;
// Wall thickness between honeycomb cells in mm
HoneycombWall=1.2;

/* [Advanced Settings] */
RoundingOnTopOnly=true;
// Bottom edge rounding radius in mm (0 = sharp corners)
BottomRounding=5;
// Snap bump for a tight close — set 0 for none
lockSize=1;
// Cap undercut; must be less than wall
capCut=1;
// Larger value = looser lid fit
clearance=0.4;
handleCutSize=10;
handleCutDeep=20;

// ── Derived dimensions ────────────────────────────────────
inner_L = Length - wall*2;
inner_W = Width  - wall*2;
// Usable interior height below the lid track
inner_H = Height - bottom_wall - wall;

// ── Helper functions ──────────────────────────────────────

// Clamp value to [0, n-1] range as index safety
function _v(v, i) = (i < len(v)) ? v[i] : 0;

// Build a size vector from individual Col/Row params (only first n entries)
function _make_sv(a,b,c,d, n) = [for(i=[0:n-1]) [a,b,c,d][i]];

// Normalise n proportional values so compartments fill 'total' mm,
// leaving room for (n-1) partition walls of thickness pw.
// Returns absolute mm sizes for each compartment.
function _norm_sizes(a,b,c,d, n, total, pw) =
    let(
        vals  = _make_sv(a,b,c,d, n),
        raw_s = sum(vals),
        avail = total - (n-1)*pw,       // space left after walls
        eq    = avail / n               // fallback: equal split
    ) (raw_s <= 0)
        ? [for(i=[0:n-1]) eq]           // all-zero → equal
        : [for(v=vals) v * avail / raw_s];

// Centre position of divider i (0-indexed) along a given axis.
// sizes[] = absolute compartment sizes, pw = partition wall thickness,
// start   = left/bottom edge of the inner cavity on that axis.
function _div_pos(sizes, pw, start, i) =
    start + sum([for(j=[0:i]) sizes[j]]) + i*pw + pw/2;

// ── Modules ───────────────────────────────────────────────

module body(){
    translate([0,0,Height/2])
    difference(){
        if(RoundingOnTopOnly){
            if(BottomRounding > 0){
                intersection(){
                    cuboid([Length,Width,Height], rounding=wall, edges=TOP);
                    cuboid([Length,Width,Height], rounding=BottomRounding, edges=BOTTOM);
                }
            } else {
                cuboid([Length,Width,Height], rounding=wall, edges=TOP);
            }
        } else {
            cuboid([Length,Width,Height], rounding=wall);
        }
        // Inner cavity — bottom thickness is exactly bottom_wall
        // cavity center in local coords = bottom_wall/2 (gives bottom at z=bottom_wall absolute)
        translate([0, 0, bottom_wall/2 + 0.01])
        cuboid([inner_L, inner_W, Height - bottom_wall]);
    }
}

module partitions(){
    pw          = partition_wall;
    partition_h = inner_H * PartitionHeightRatio;
    partition_z = bottom_wall + partition_h / 2;

    // Column dividers — walls parallel to Y axis, spaced along X (length)
    if(Cols > 1){
        col_s = _norm_sizes(Col1,Col2,Col3,Col4, Cols, inner_L, pw);
        for(i = [0 : Cols-2]){
            cx = _div_pos(col_s, pw, -inner_L/2, i);
            translate([cx, 0, partition_z])
            cuboid([pw, inner_W, partition_h]);
        }
    }

    // Row dividers — walls parallel to X axis, spaced along Y (width)
    if(Rows > 1){
        row_s = _norm_sizes(Row1,Row2,Row3,Row4, Rows, inner_W, pw);
        for(i = [0 : Rows-2]){
            cy = _div_pos(row_s, pw, -inner_W/2, i);
            translate([0, cy, partition_z])
            cuboid([inner_L, pw, partition_h]);
        }
    }
}

module lid_honeycomb(){
    r    = HoneycombSize;
    w    = HoneycombWall;
    // effective tiling radius keeps gap between flat sides = w
    er   = r + w / sqrt(3);
    dx   = er * sqrt(3);   // horizontal center-to-center
    dy   = er * 1.5;       // vertical center-to-center
    usable_l = inner_L - wall;
    usable_w = inner_W;
    base_z   = wall - PatternHeight/2 + 0.01;
    cols_n   = ceil(usable_l / dx) + 2;
    rows_n   = ceil(usable_w / dy) + 2;
    for(col = [-cols_n : cols_n]){
        offset_y = (abs(col) % 2 == 1) ? dy/2 : 0;
        for(row = [-rows_n : rows_n]){
            x = col * dx;
            y = row * dy + offset_y;
            if(abs(x) <= usable_l/2 + r && abs(y) <= usable_w/2 + r)
                translate([x, y, base_z])
                rotate([0, 0, 30])
                cylinder(r=r, h=PatternHeight, center=true, $fn=6);
        }
    }
}

module lid_pattern(){
    usable_l = inner_L - wall;   // stay inside the cap boundary
    usable_w = inner_W;
    base_z   = wall - PatternHeight/2 + 0.01;

    // Horizontal lines (LidPattern 1 or 2)
    if(LidPattern == 1 || LidPattern == 2){
        for(y = [-usable_w/2 : PatternSpacing : usable_w/2]){
            translate([0, y, base_z])
            cuboid([usable_l, PatternLineWidth, PatternHeight]);
        }
    }
    // Vertical lines (LidPattern 1 or 3)
    if(LidPattern == 1 || LidPattern == 3){
        for(x = [-usable_l/2 : PatternSpacing : usable_l/2]){
            translate([x, 0, base_z])
            cuboid([PatternLineWidth, usable_w, PatternHeight]);
        }
    }
    // Honeycomb (LidPattern 4)
    if(LidPattern == 4) lid_honeycomb();
}

module showtext(){
    translate([0,0,wall-TextHeight/2+0.01])
        if(!Engraved){
           color([1,0,0])
           linear_extrude(height=TextHeight, center=true)
            text(LidText, size=Text_size, font=str(FontName, ":style=", FontStyle), halign="center", valign="center");
        }else{
            linear_extrude(height=TextHeight, center=true)
            text(LidText, size=Text_size, font=str(FontName, ":style=", FontStyle), halign="center", valign="center");
        }
}

module cap(forcut=true){
    translate([capCut/2,0,0])
    top_half(s=1000)
    cuboid([Length-capCut, Width-capCut*2, wall*2], chamfer=wall);

    translate([Length/2-wall,0,0])
    right_half(s=1000)
    top_half(s=1000)
    cuboid([wall*2, Width+(forcut?10:0), wall*2], rounding=wall);

    if(lockSize>0){
        translate([Length/2-wall*2, 0, lockSize/2])
        cuboid([lockSize, Width-wall, lockSize], rounding=lockSize/2);
    }

    if(!forcut){
        // Lid decoration pattern
        if(LidPattern > 0) lid_pattern();
        // Text — always shown when LidPattern=0, optional when pattern is active
        if(LidPattern == 0 || ShowText) showtext();
    }
}

// ── Main render ───────────────────────────────────────────

// Box body with partitions, minus the lid-track slot
difference(){
    union(){
        body();
        partitions();
    }
    translate([0,0,Height-wall])
    scale([(Length+clearance)/Length, (Width+clearance)/Width, (wall/2+clearance)/wall*2])
    cap();
}

// Lid (printed next to the box)
translate([0, Width+1, 0])
difference(){
    cap(false);
    translate([Length/2-wall*2, 0, wall])
    left_half(s=1000)
    bottom_half(s=1000)
    scale([1,1,handleCutDeep/handleCutSize])
    sphere(d=handleCutSize);
    if(LidPattern == 0 || ShowText) showtext();
}
