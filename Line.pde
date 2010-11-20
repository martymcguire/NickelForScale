class Line {
  Point p1;
  Point p2;
  
  public Line(){
    p1 = new Point(0,0);
    p2 = new Point(0,0);
  }
  public Line(Point _p1, Point _p2){
    this();
    p1.x = _p1.x;
    p1.y = _p1.y;
    p2.x = _p2.x;
    p2.y = _p2.y;
  }
  
  // True if my p1 and p2 are the same as l's p1 and p2, or if my p1 is l's p2 and my p2 is l's p1.
  public boolean equals(Line l){
    return (  ((p1.x == l.p1.x) && (p1.y == l.p1.y) && (p2.x == l.p2.x) && (p2.y == l.p2.y))
            || ((p1.x == l.p2.x) && (p1.y == l.p2.y) && (p2.x == l.p1.x) && (p2.y == l.p1.y)));
  }
  
  public double length(){
    return p1.distance(p2);
  }
}
