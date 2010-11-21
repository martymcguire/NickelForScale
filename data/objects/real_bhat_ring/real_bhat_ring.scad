include <../../current_measurements.scad>

// scale mm measurement from config
inner_diam = 1000 * measurement_1;
height = 5000; // 1 cm1
thickness = 2900; // thickness of material

// units in micro-meters (um)
module real_bhat_ring(){

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
  brim_w = inner_diam;
  body_w = brim_w * 0.75;
  body_h = 20000;
  union(){
    translate([0,thickness*0.5,0]){
//      scale(1000)
//        import_stl("B-bin.stl",convexity=5);
      scale([30000,30000,1000]){
        translate([-0.2,0.015,0]) linear_extrude(file = "B.dxf", height=5, convexity = 10);
      }
      translate([-brim_w/2,-thickness*0.75,0]) cube([brim_w,thickness,height]);
      translate([-body_w/2,0,0]) cube([body_w,body_h,height*0.5]);
    }
  }
}

scale(0.001) real_bhat_ring();
