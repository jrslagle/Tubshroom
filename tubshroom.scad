// Global resolution
//$fs = 0.1;  // Don't generate smaller facets than 0.1 mm
//$fa = 5;    // Don't generate larger angles than 5 degrees
$fn = 50;   // Subdivide arcs into 50 facets

// All dimensions are in millimeters;

// Drain parameters
drain_inner_diameter = 41; // the diameter of the vertical shaft
drain_outer_diameter = 72; // the outer edge of the metal collar
drain_depth = 31.5; // from bottom to brim

// Drain catch parameters
wall_thickness = 2.5; // for canopy, trunk, and base

// Canopy
brim_clearance = 15; // vertical clearance between brim and drain collar
brim_sag = 5; // sag from the top of the canopy to its brim
brim_overbite = 0; // amount brim extends over drain_outer_diameter
vent_type = "biohazard"; // biohazard, button_holes, power_on, aperture_science
vent_core_scale = 0.9; // the vent diameter will be this percent of core_diameter

// Trunk
core_diameter = 25; // inner diameter of the trunk
holes_around = 10; // drain holes circumscribing the trunk
holes_tall = 5;
hole_cage_ratio = 0.75; // 0.75 means 75% hole, 25% trunk horizontally

// Main geometry

// CANOPY
apex_height = drain_depth+brim_clearance+wall_thickness+brim_sag;
canopy_diameter = drain_outer_diameter + brim_overbite*2;
vent_diameter = core_diameter * vent_core_scale;
canopy(apex_height, canopy_diameter, brim_sag, wall_thickness, vent_diameter);

// TRUNK
trunk_height = apex_height-wall_thickness;
trunk(wall_thickness, trunk_height, core_diameter, holes_around, holes_tall, hole_cage_ratio);

// BOTTOM
bottom(wall_thickness, core_diameter, drain_inner_diameter);

module canopy(apex_height, diameter, sag, thickness, vent_diameter) {
    // The vertical radius of this dome cap.
    R = (pow((diameter/2),2)+pow(sag,2))/(2*sag);
    
    // The coordinate R pivots on.
    origin_Z = -(R - apex_height);
    
    difference() {
        rotate_extrude(convexity=1) {
            // union a circle on the brim.
            intersection() {
                translate([0,origin_Z,0]) {
                    difference() {    
                        circle(r=R);
                        circle(r=R-thickness);
                    }
                }
                // The width of the following triangle.
                Y = ((diameter/2)*R)/(R-sag);
                // triangle that sections this ring
                polygon( points=[
                    [0,origin_Z],
                    [0,apex_height],
                    [Y,apex_height]
                ] );
            }
        }
        
        translate([0,0,apex_height-sag-thickness]) {
            linear_extrude(height=sag+thickness) {
                biohazard(vent_diameter);
            }
        }
    }
}

module biohazard(diameter) {
    // set all component diameters
    outer_claw = 0.55 * diameter;
    inner_claw = 0.40 * diameter;
    outer_ring = 0.50 * diameter;
    center_hole= 0.11 * diameter;
    claw_gap   = 0.01 * diameter;
    stroke     = 0.7; // should be a multiple of the printer's nozzle diameter since this determines the bridge to the inner parts.
    
    rotate([0,0,-90])
    difference() {
        union () {
            // the outer claws
            difference() {
                flower(diameter,3,outer_claw);
                flower(diameter,3,inner_claw);
            }
            // the central ring
            difference() {
                circle(d=outer_ring);
                circle(d=inner_claw);
            }
        }
        
        // the outline between claws and ring
        difference() {
            flower(diameter + claw_gap, 3, inner_claw + claw_gap);
            flower(diameter+ claw_gap-stroke,3,inner_claw-stroke);
        }
        
        // the radial gaps in the center
        spacing = 360/3;
        reach = diameter/2 - inner_claw + stroke;
        for(angle = [spacing:spacing:360]) {
            rotate([0,0,angle]) translate([reach/2,0,0])
                square([reach,stroke], center=true);
        }
        
        // the central hole
        circle(d=center_hole);
    }
}

module flower(flower_dia,petals,petal_dia) {
    spacing = 360 / petals;
    petal_center = flower_dia/2 - petal_dia/2;
    
    for(angle = [spacing:spacing:360]) {
        rotate([0,0,angle]) translate([petal_center,0,0])
            circle(d=petal_dia);
    }
}

module trunk(wall_thickness, trunk_height, core_diameter, holes_around, holes_tall, hole_cage_ratio) {
    
    difference() {
        linear_extrude(height=trunk_height,convexity=2) {
            difference() {
                circle(d=core_diameter+wall_thickness*2);
                circle(d=core_diameter);
            }
        }
        
        h_spacing = 360 / holes_around;
        
        hole_diameter = (hole_cage_ratio*3.14*core_diameter)/holes_around;
        
        v_spacing = (trunk_height-wall_thickness*2) / holes_tall;
        
        distance = core_diameter/2-wall_thickness/3;
        
        for(angle = [h_spacing:h_spacing:360]) {
            for(tier = [v_spacing:v_spacing:trunk_height]) {
                
                rotate([0,90,angle])
                translate([-tier,0,distance])
                linear_extrude(height=wall_thickness*2) {
                    circle(d=hole_diameter);
                }
            }
        }
    }
}

module bottom(wall_thickness, core_diameter, drain_inner_diameter) {
    
    trunk_radius = core_diameter/2 + wall_thickness;
    drain_clearance = 1;
    outer_radius = drain_inner_diameter/2-drain_clearance;
    knurl = drain_inner_diameter/2-drain_clearance-wall_thickness;
    
    difference() {
        rotate_extrude(convexity=2) {
            union() {
                polygon(points = [
                    [trunk_radius,0],
                    [knurl,0],
                    [outer_radius,wall_thickness],
                    [trunk_radius,wall_thickness]]);
                
                intersection() {
                    polygon(points = [
                        [knurl,0],
                        [outer_radius,0],
                        [outer_radius,wall_thickness],
                        [knurl,wall_thickness]]);
            
                    translate([drain_inner_diameter/2-drain_clearance-wall_thickness,wall_thickness])
                    circle(r=wall_thickness);
                }
            }
        }
        
        // holes!
        linear_extrude(convexity=2) {
            flower(
                (trunk_radius+wall_thickness)*2,
                30,
                wall_thickness);
        }
    }
}

// todo:
// finish trunk module
// add bottom

// make biohazard tutorial