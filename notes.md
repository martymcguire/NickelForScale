Friday, Nov. 19, 2010
=====================

* [Set up camera](http://camura.com/s/D73) and [macam](http://webcam-osx.sourceforge.net/)
* Installed [Processing OpenCV](http://ubaa.net/shared/processing/opencv/)
    * Install OpenCV framework 1.1 from dmg
    * Install processing lib to `~/Documents/Processing/libraries`

---

Amy put together a blobs app in Processing using somebody's blob tracking demo.

* Loads an image from the `data/` directory to pass to OpenCV
* Does thresholding using `THRESH_TOZERO_INV`
    * More on [thresholding](http://ubaa.net/shared/processing/opencv/opencv_threshold.html)

So... now we want to try to find a (rough) hand blob and crop out the rest of
the image, then re-threshold again to get a better polygon.

... this was easier than expected.

Came up with a crappy "complexity" metric using blob area divided by perimeter.
Looking at this value "emperically", it looks like Amy's hand is never less
"complex" than about "26".  So, we set a threshold for 20, and could reliably
find a hand blob ROI, once we adjusted the TOZERO threshold.

Some more screwing around was done and then we discovered the magic.

There's an `THRESH_OTSU` option which, when OR'd with the type of threshold
operation you are doing, ignores the threshold (and max?) value that you pass
in, in order to find an "optimal" value. [Yay Otsu](http://en.wikipedia.org/wiki/Otsu%27s_method)!

It does a better job with less complex areas, so what we do now is:

* Use pictures of a hand with a nickel on the back of the hand.
* Do one pass of optimal thresholding and blob finding to find the "complex"
hand blob.
* Using the hand blob's rectangle, set the ROI, reset the image pixels, and
re-threshold. This produces 2 blobs - a hand, and the nickel. You can tell
them apart by many things, but an easy one is that the nickel is a hole in the
hand blob. So "`blob.isHole == true`".

Now: [a wild github appears](https://github.com/martymcguire/NickelForScale)!!

Things to do next
* Find good models to parameterize
* Come up with hand measurements we can parameterize
* Come up with OpenSCAD params file format for export from Processing
* Pipeline this motherfucker in Processing
    * Choose a thing you want to make
    * Hand picture from webcam (done)
    * Get hand measurements and display them in a badass way (done)
    * Export measurements for OpenSCAD
    * Invoke openscad to make STL
    * Show orig and custom STL side-by-side
    * Fire up RepG and print.

---

Saturday, Nov. 20, 2010
=======================

OpenSCAD Party
--------------

* `data/`
    * `current_measurements.scad` - holds the current measurements
    * `objects/`
        * `<object-name>/`
            * `<object-name>.scad`
            * `<object-name>.stl` - example render
            * `measurements.txt` - labels (1 per line) of needed measurements

### Calling OpenSCAD w/ processing...

* Use `exec(String[])`
  * One arg per string.
  * Absolute paths.
  * Example:

			File scad_file = new File("/Users/rmcguire/Documents/Processing/RunOpenSCAD/data/objects/plain_ring/plain_ring.scad");
			File stl_file = new File("/Users/rmcguire/Documents/Processing/RunOpenSCAD/data/plain_ring.stl");
			String[] exec = {
				"/usr/bin/open","/Applications/OpenSCAD.app","--args",
				"-s",
				stl_file.getAbsolutePath(),
				scad_file.getAbsolutePath()
			};

			println(exec);
			exec(exec);

---

Badass Model Chooser
--------------------

* List all dirs in `objects/`.
* Load up `objects/<objName>/<objName>.stl` w/ [unlekkerlib](http://workshop.evolutionzone.com/unlekkerlib/)
    * CRITICAL MISS - OpenSCAD outputs ASCII STL, unlekker requires binary!
    * Perl to the rescue? [CAD::Format::STL](http://search.cpan.org/~ewilhelm/CAD-Format-STL-v0.2.1/lib/CAD/Format/STL.pm)
        * YES!

                #!/usr/bin/env perl
                require CAD::Format::STL;

                if($#ARGV != 1){
                  print "Usage: stl_ascii_to_bin.pl <INFILE> <OUTFILE>";
                  exit;
                }

                my $stl = CAD::Format::STL->new->load($ARGV[0]);
                $stl->save(binary => $ARGV[1]);
