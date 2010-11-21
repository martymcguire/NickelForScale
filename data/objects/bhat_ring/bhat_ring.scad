include <../../current_measurements.scad>

// scale mm measurement from config
inner_diam = 1000 * measurement_1;
height = 5000; // 1 cm
thickness = 2000; // thickness of material

// units in micro-meters (um)
module bhat_ring(){

  outer_diam = inner_diam + thickness*2;

  difference(){
    union(){
      cylinder(r=outer_diam/2, h=height);
      translate([0,outer_diam/2.1,0]) hat();
    }
    translate([0,0,-height*0.1]){
      cylinder(r=inner_diam/2, h=height*1.2);
    }
  }
}

module hat() {
  hat_w = inner_diam;
  hat_h = inner_diam * 0.8;
  rim_r = 0.18;
  translate([-hat_w/2,0,0]){
    union(){
      cube([hat_w,hat_h/6,height]);
      translate([hat_w*rim_r,0,0]){
        cube([hat_w*(1-2*rim_r),hat_h,height]);
      }
    }
  }
}

scale(0.001) bhat_ring();
