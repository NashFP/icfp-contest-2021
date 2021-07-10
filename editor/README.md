# Editor
This is a simple edit with a quirky user interface.

You can move the figure around the board with the arrow keys.
Shift-Right-click on a point sets a center of rotation, and then
use < and > to rotate counterclockwise and clockwise around that center.

Right-click on a point sets that as the primary point. If the primary
point is connected to exactly 2 other points, you can then hit 'f' to
reflect that point across the line formed by the 2 points it connects
to.

Right-click on a second point sets it as a secondary point. If the
primary and secondary points are connected by a segment, and each
connects to exactly 1 other segment, hitting 'f' will reflect both
points over the line formed by the other 2 points they connect to.
Also, if you have a primary and secondary point selected, and again
they are connected and each connect to just one other point, the 
< and > keys rotate the primary point around the other point it connects
to, and it will drag the secondary point along with it as long as
their line segments don't deform during the rotation.

Hitting 'q' will compress square figure into a single line segment.

Hitting 'S' will try to save the figure's vertices, although if
some of the edges are deformed and it can't come up with an adjustment
that works, it will edit. The solution file is just written as
"sol.json" in the current directory.

To run the program, make sure you have `stack` installed, and do:
```
stack run -- n
```
where n is the problem number. It will look in ../problems for the
problem file.
