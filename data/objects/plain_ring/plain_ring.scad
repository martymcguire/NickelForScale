include <../../current_measurements.scad>

// units in micro-meters (um)
module plain_ring(){
  // scale mm measurement from config
  inner_diam = 1000 * measurement_1;

  thickness = 2000; // thickness of material
  height = 5000; // 0.5 cm

  outer_diam = inner_diam + thickness*2;

  difference(){
    cylinder(r=outer_diam/2, h=height);
    translate([0,0,-height*0.1]){
      cylinder(r=inner_diam/2, h=height*1.2);
    }
  }
}

scale(0.001) plain_ring();