/* This file is part of the Marching Cubes GPU based algorithm based on 
 * Paul Bourke's tabulation approach to marching cubes
 * http://paulbourke.net/geometry/polygonise/
 *
 *
 * We model cubes with 8 vertices labelled as below
 *
 *
 *            3--------(7)---------7
 *           /|                   /|
 *          / |                  / |
 *         /  |                 /  |
 *       (2)  |               (A)  |
 *       /    |               /    |
 *      /    (3)             /    (B)
 *     /      |             /      |
 *    2------+--(6)--------6       |
      |       |            |       |
 *    |       0------(4)---|-------4
 *    |      /             |      /
 *   (1)    /             (9)    /
 *    |    /               |    /
 *    |  (0)               |  (8)
 *    |  /                 |  /
 *    | /                  | /
 *    |/                   |/
 *    1---------(5)--------5
 *
 * where X axis is horizontal, +ve to right
 *       Y axis is vertical, +ve upwards
 *       Z axis is into page, +ve towards front
 *
 * 0: ( x, y,   z   )  4: ( x+1, y,   z   )
 * 1: ( x, y,   z+1 )  5: ( x+1, y,   z+1 )
 * 2: ( x, y+1, z+1 )  6: ( x+1, y+1, z   )
 * 3: ( x, y+1, z   )  7: ( x+1, y+1, z+1 )
 *
 * There are 12 edges, 0 - 11 where each edge connectes two vertices as follows:
 *
 *
 * 0: 0, 1       1: 1, 2       2: 2, 3       3:  3, 0
 * 4: 0, 4       5: 1, 5       6: 2, 6       7:  3, 7
 * 8: 4, 5       9: 5, 6       A: 6, 7       B:  7, 4
 */

/**
  * The Triangle Table specifies, for each type of cube, how to connect the vertices generated by interscting the 
  * cubes edges, into triangles.
  * For each cube there is a list of vertex indices for up to 5 triangles. The list is terminated by a -1
  * The vertex indices refer to the intersections found on each of the 12 edges of the cube so they may be 0 to 11
  */
__constant__
int TRIANGLE_TABLE[256][16] = {

	// Pattern 0 - None under
    { -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0000 0000            (no intersects)

	// Pattern 1 - single vertex inside
    {  0,  4,  3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0000 0001   0        (vertex 0 only)
    {  0,  1,  5, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0000 0010   1        (vertex 1 only)
    {  1,  2,  6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0000 0100   2        (vertex 2 only)
    {  2,  3,  7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0000 1000   3        (vertex 3 only)
    {  4,  8, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0001 0000   4        (vertex 4 only)
    {  5,  9,  8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0010 0000   5        (vertex 5 only)
    {  6, 10,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0100 0000   6        (vertex 6 only)
    {  7, 11, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1000 0000   7 	      (vertex 7 only)

	// Pattern 2 - single edge inside
    {  1,  5,  3,  3,  5,  4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0000 0011   0, 1     (edge 0)
    {  0,  2,  5,  5,  2,  6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0000 0110   1, 2     (edge 1)
    {  1,  3,  6,  6,  3,  7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0000 1100   2, 3     (edge 2)
    {  0,  4,  2,  2,  4,  7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0000 1001   0, 3     (edge 3)
    {  0,  8,  3,  3,  8, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0001 0001   0, 4     (edge 4)
    {  0,  1,  8,  8,  1,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0010 0010   1, 5     (edge 5)
    {  1,  2,  9,  9,  2, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0100 0100   2, 6     (edge 6)
    {  2,  3, 10, 10,  3, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1000 1000   3, 7     (edge 7)
    {  4,  5, 11, 11,  5,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0011 0000   4, 5     (edge 8)
    {  5,  6,  8,  8,  6, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0110 0000   5, 6     (edge 9)
    {  6,  7,  9,  9,  7, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1100 0000   6, 7     (edge 10)
    {  4,  8,  7,  7,  8, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1001 0000   4, 7     (edge 11)

    // Pattern 3 - opposing triangles on the same face
    {  0,  4,  3,  1,  2,  6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0000 0101   0, 2     (2 tri)
    {  0,  4,  3,  5,  9,  8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0010 0001   0, 5     (2 tri)
    {  0,  4,  3,  7, 11, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1000 0001   0, 7	  (2 tri)
    {  0,  1,  5,  2,  3,  7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0000 1010   1, 3     (2 tri)
    {  0,  1,  5,  4,  8, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0001 0010   1, 4     (2 tri)
    {  0,  1,  5,  6, 10,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0100 0010   1, 6     (2 tri)
    {  1,  2,  6,  5,  9,  8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0010 0100   2, 5     (2 tri)
    {  1,  2,  6,  7, 11, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1000 0100   2, 7     (2 tri)
    {  2,  3,  7,  4,  8, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0001 1000   3, 4     (2 tri)
    {  2,  3,  7,  6, 10,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0100 1000   3, 6     (2 tri)
    {  4,  8, 11,  6, 10,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0101 0000   4, 6     (2 tri)
    {  5,  9,  8,  7, 11, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1010 0000   5, 7     (2 tri)

    // Pattern 4 - Diagonally opposite triangles (4)
    {  0,  4,  3,  6, 10,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0100 0001   0, 6     (2 diag tris)
    {  0,  1,  5,  7, 11, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1000 0010   1, 7     (2 diag tris)
    {  2,  3,  7,  5,  9,  8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0010 1000   3, 5     (2 diag tris)
    {  1,  2,  6,  4,  8, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0001 0100   2, 4     (2 diag tris)

    // Pattern 5 - 3 corners of a face (24)
    {  4,  6,  5,  4,  3,  6,  6,  3,  2, -1, -1, -1, -1, -1, -1, -1},       //  0000 0111   0,1,2    (3 on a face)
    {  5,  7,  6,  5,  0,  7,  7,  0,  3, -1, -1, -1, -1, -1, -1, -1},       //  0000 1110   1,2,3    (3 on a face)
    {  6,  4,  7,  6,  1,  4,  4,  1,  0, -1, -1, -1, -1, -1, -1, -1},       //  0000 1101   2,3,0    (3 on a face)
    {  7,  5,  4,  7,  2,  5,  5,  2,  1, -1, -1, -1, -1, -1, -1, -1},       //  0000 1011   3,0,1    (3 on a face)

    {  0, 10,  8,  0,  1, 10, 10,  1,  6, -1, -1, -1, -1, -1, -1, -1},       //  0110 0010   1,5,6    (3 on a face)
    {  8,  2, 10,  8,  5,  2,  2,  5,  1, -1, -1, -1, -1, -1, -1, -1},       //  0110 0100   5,6,2    (3 on a face)
    { 10,  0,  2, 10,  9,  0,  0,  9,  5, -1, -1, -1, -1, -1, -1, -1},       //  0100 0110   6,2,1    (3 on a face)
    {  2,  8,  0,  2,  6,  8,  8,  6,  9, -1, -1, -1, -1, -1, -1, -1},       //  0010 0110   2,1,5    (3 on a face)

    {  5,  7,  4,  5,  9,  7,  7,  9, 10, -1, -1, -1, -1, -1, -1, -1},       //  1011 0000   5,4,7    (3 on a face)
    {  4,  6,  7,  4,  8,  6,  6,  8,  9, -1, -1, -1, -1, -1, -1, -1},       //  1101 0000   4,7,6    (3 on a face)
    {  7,  5,  6,  7, 11,  5,  5, 11,  8, -1, -1, -1, -1, -1, -1, -1},       //  1110 0000   7,6,5    (3 on a face)
    {  6,  4,  5,  6, 10,  4,  4, 10, 11, -1, -1, -1, -1, -1, -1, -1},       //  0111 0000   6,5,4    (3 on a face)

    {  8,  2,  0,  8, 11,  2,  2, 11,  7, -1, -1, -1, -1, -1, -1, -1},       //  0001 1001   4,0,3    (3 on a face)
    {  0, 10,  2,  0,  4, 10, 10,  4, 11, -1, -1, -1, -1, -1, -1, -1},       //  1000 1001   0,3,7    (3 on a face)
    {  2,  8, 10,  2,  3,  8,  8,  3,  4, -1, -1, -1, -1, -1, -1, -1},       //  1001 1000   3,7,4    (3 on a face)
    { 10,  0,  8, 10,  7,  0,  0,  7,  3, -1, -1, -1, -1, -1, -1, -1},       //  1001 0001   7,4,0    (3 on a face)

    {  1, 11,  9,  1,  2, 11, 11,  2,  7, -1, -1, -1, -1, -1, -1, -1},       //  1100 0100   2,6,7    (3 on a face)
    {  9,  3, 11,  9,  6,  3,  3,  6,  2, -1, -1, -1, -1, -1, -1, -1},       //  1100 1000   6,7,3    (3 on a face)
    { 11,  1,  3, 11, 10,  1,  1, 10,  6, -1, -1, -1, -1, -1, -1, -1},       //  1000 1100   7,3,2    (3 on a face)
    {  3,  9,  1,  3,  7,  9,  9,  7, 10, -1, -1, -1, -1, -1, -1, -1},       //  0100 1100   3,2,6    (3 on a face)

    {  3,  9, 11,  3,  0,  9,  9,  0,  5, -1, -1, -1, -1, -1, -1, -1},       //  0011 0001   0,4,5    (3 on a face)
    { 11,  1,  9, 11,  4,  1,  1,  4,  0, -1, -1, -1, -1, -1, -1, -1},       //  0011 0010   4,5,1    (3 on a face)
    {  9,  3,  1,  9,  8,  3,  3,  8,  4, -1, -1, -1, -1, -1, -1, -1},       //  0010 0011   5,1,0    (3 on a face)
    {  1, 11,  3,  1,  5, 11, 11,  5,  8, -1, -1, -1, -1, -1, -1, -1},       //  0001 0011   1,0,4    (3 on a face)

    // Pattern 6 - isolated edge plus triangle
    {  1,  5,  3,  3,  5,  4,  6, 10,  9, -1, -1, -1, -1, -1, -1, -1},       //  0100 0011   0, 1, 6  (edge 0 + 6)
    {  1,  5,  3,  3,  5,  4,  7, 11, 10, -1, -1, -1, -1, -1, -1, -1},       //  1000 0011   0, 1, 7  (edge 0 + 7)
    {  0,  8,  3,  3,  8, 11,  1,  2,  6, -1, -1, -1, -1, -1, -1, -1},       //  0001 0101   0, 2, 4  (edge 4 + 2)
    {  1,  2,  9,  9,  2, 10,  0,  4,  3, -1, -1, -1, -1, -1, -1, -1},       //  0100 0101   0, 2, 6  (edge 6 + 0)
    {  0,  4,  2,  2,  4,  7,  5,  9,  8, -1, -1, -1, -1, -1, -1, -1},       //  0010 1001   0, 3, 5  (edge 3 + 5)
    {  0,  4,  2,  2,  4,  7,  6, 10,  9, -1, -1, -1, -1, -1, -1, -1},       //  0100 1001   0, 3, 6  (edge 3 + 6)
    {  0,  8,  3,  3,  8, 11,  6, 10,  9, -1, -1, -1, -1, -1, -1, -1},       //  0101 0001   0, 4, 6  (edge 4 + 6)
    {  5,  6,  8,  8,  6, 10,  0,  4,  3, -1, -1, -1, -1, -1, -1, -1},       //  0110 0001   0, 5, 6  (edge 9 + 0)
    {  6,  7,  9,  9,  7, 11,  0,  4,  3, -1, -1, -1, -1, -1, -1, -1},       //  1100 0001   0, 6, 7  (edge 10 + 0)
    {  0,  2,  5,  5,  2,  6,  4,  8, 11, -1, -1, -1, -1, -1, -1, -1},       //  0001 0110   1, 2, 4  (edge 1 + 4)
    {  0,  2,  5,  5,  2,  6,  7, 11, 10, -1, -1, -1, -1, -1, -1, -1},       //  1000 0110   1, 2, 7  (edge 1 + 7)
    {  2,  3, 10, 10,  3, 11,  0,  1,  5, -1, -1, -1, -1, -1, -1, -1},       //  1000 1010   1, 3, 7  (edge 7 + 1)
    {  4,  8,  7,  7,  8, 10,  0,  1,  5, -1, -1, -1, -1, -1, -1, -1},       //  1001 0010   1, 4, 7  (edge 11 + 1)
    {  0,  1,  8,  8,  1,  9,  2,  3,  7, -1, -1, -1, -1, -1, -1, -1},       //  0010 1010   1, 5, 3  (edge 5 + 3)
    {  0,  1,  8,  8,  1,  9,  5,  9,  8, -1, -1, -1, -1, -1, -1, -1},       //  1010 0010   1, 5, 7  (edge 5 + 7)
    {  6,  7,  9,  9,  7, 11,  0,  1,  5, -1, -1, -1, -1, -1, -1, -1},       //  1100 0010   1, 6, 7  (edge 10 + 1)
    {  1,  3,  6,  6,  3,  7,  4,  8, 11, -1, -1, -1, -1, -1, -1, -1},       //  0001 1100   2, 3, 4  (edge 2 + 4)
    {  1,  3,  6,  6,  3,  7,  5,  9,  8, -1, -1, -1, -1, -1, -1, -1},       //  0010 1100   2, 3, 5  (edge 2 + 5)
    {  1,  2,  9,  9,  2, 10,  4,  8, 11, -1, -1, -1, -1, -1, -1, -1},       //  0101 0100   2, 4, 6  (edge 6 + 4)
    {  4,  5,  9,  4,  9, 11,  1,  2,  6, -1, -1, -1, -1, -1, -1, -1},       //  0011 0100   2, 4, 5  (edge 8 + 2)
    {  4,  8,  7,  7,  8, 10,  1,  2,  6, -1, -1, -1, -1, -1, -1, -1},       //  1001 0100   2, 4, 7  (edge 11 + 2)
    {  4,  5,  9,  4,  9, 11,  2,  3,  7, -1, -1, -1, -1, -1, -1, -1},       //  0011 1000   3, 4, 5  (edge 8 + 3)
    {  5,  6,  8,  8,  6, 10,  2,  3,  7, -1, -1, -1, -1, -1, -1, -1},       //  0110 1000   3, 5, 6  (edge 9 + 3)
    {  2,  3, 10, 10,  3, 11,  5,  9,  8, -1, -1, -1, -1, -1, -1, -1},       //  1010 1000   3, 5, 7  (edge 7 + 5)

    // Pattern 7 - two corners and diagonally opposite corner
    {  0,  4,  3,  1,  2,  6,  5,  9,  8, -1, -1, -1, -1, -1, -1, -1},       //  0010 0101   0, 2, 5  (3 tri)
    {  0,  1,  5,  6, 10,  9,  4,  8, 11, -1, -1, -1, -1, -1, -1, -1},       //  0101 0010   1, 6, 4  (3 tri)
    {  5,  9,  8,  7, 11, 10,  0,  4,  3, -1, -1, -1, -1, -1, -1, -1},       //  1010 0001   5, 7, 0  (3 tri)
    {  4,  8, 11,  2,  3,  7,  0,  1,  5, -1, -1, -1, -1, -1, -1, -1},       //  0001 1010   4, 3, 1  (3 tri)

    {  0,  4,  3,  1,  2,  6,  7, 11, 10, -1, -1, -1, -1, -1, -1, -1},       //  1000 0101   0, 2, 7  (3 tri)
    {  0,  1,  5,  6, 10,  9,  2,  3,  7, -1, -1, -1, -1, -1, -1, -1},       //  0100 1010   1, 6, 3  (3 tri)
    {  5,  9,  8,  7, 11, 10,  1,  2,  6, -1, -1, -1, -1, -1, -1, -1},       //  1010 0100   5, 7, 2  (3 tri)
    {  4,  8, 11,  2,  3,  7,  6, 10,  9, -1, -1, -1, -1, -1, -1, -1},       //  0101 1000   4, 3, 6  (3 tri)


    // Pattern 8 - Bisector (3)
    {  4,  7,  5,  5,  7,  6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0000 1111   0,1,2,3  (bisect)
    {  0,  8,  2,  2,  8, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1001 1001   0,3,4,7  (bisect)
    {  1,  9,  3,  3,  9, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0011 0011   0,1,4,5  (bisect)

    // Pattern 9 - Hexagonal (corner vertex plus three neighbours) (8)
    {  1,  7,  2,  1,  5,  7,  7,  5, 11,  5, 11,  8, -1, -1, -1, -1},       //  0001 1011   0,1,3,4  (hexagon)
    {  9,  2,  6,  9,  8,  2,  2,  8,  3,  8,  3,  4, -1, -1, -1, -1},       //  0010 0111   0,1,2,5  (hexagon)
    {  3, 10,  7,  3,  0, 10, 10,  0,  9,  0,  9,  5, -1, -1, -1, -1},       //  1011 0001   0,4,5,7  (hexagon)
    { 11,  0,  4, 11, 10,  0,  0, 10,  1, 10,  1,  6, -1, -1, -1, -1},       //  1000 1101   0,2,3,7  (hexagon)


    // Pattern 10 - Two planes diagonally opposite (3)
    {  1,  5,  3,  3,  5,  4,  6,  7,  9,  9,  7, 11, -1, -1, -1, -1},       //  1100 0011   0,1,6,7  (edges 0, 10)
    {  0,  4,  2,  2,  4,  7,  5,  6,  8,  8,  6, 10, -1, -1, -1, -1},       //  0110 1001   0,3,5,6  (edges 3, 9)
    {  0,  8,  3,  3,  8, 11,  1,  2,  9,  9,  2, 10, -1, -1, -1, -1},       //  0101 0101   0,2,4,6  (edges 4, 6)


    // Pattern 11 - Four points, two perpendicular edges (12)
    { 11,  9,  4,  4,  9,  2,  2,  4,  0,  9,  6,  2, -1, -1, -1, -1},       //  0011 0110   1,2,4,5  (perp edges l : 1,8)
    {  9,  1,  8,  8,  1,  7,  7,  8,  4,  1,  2,  7, -1, -1, -1, -1},       //  0010 1011   0,1,5,3  (perp edges l : 3,5)
    {  8,  0, 11, 11,  0,  6,  6, 11,  7,  0,  1,  6, -1, -1, -1, -1},       //  0001 1101   0,2,3,4  (perp edges l : 2,4)
    { 11,  3, 10, 10,  3,  5,  5, 10,  6,  3,  0,  5, -1, -1, -1, -1},       //  1000 1110   1,2,3,7  (perp edges l : 1,7)
    { 10,  2,  9,  9,  2,  4,  4,  9,  5,  2,  3,  4, -1, -1, -1, -1},       //  0100 0111   0,1,2,6  (perp edges l : 0,6)
    {  1,  3,  5,  5,  3, 10, 10,  5,  8,  3,  7, 10, -1, -1, -1, -1},       //  1001 0011   0,1,4,7  (perp edges l : 0,11)
    {  0,  2,  4,  4,  2,  9,  9,  4, 11,  2,  6,  9, -1, -1, -1, -1},       //  1100 1001   0,3,6,7  (perp edges l : 3,10)
    {  3,  1,  7,  7,  1,  8,  8,  7, 10,  1,  5,  8, -1, -1, -1, -1},       //  0110 1100   2,3,5,6  (perp edges l : 2,9)
    {  3, 11,  0,  0, 11,  6,  6,  0,  5, 11, 10,  6, -1, -1, -1, -1},       //  0111 0001   0,4,5,6  (perp edges l : 4,9)
    {  2, 10,  3,  3, 10,  5,  5,  3,  4, 10,  9,  5, -1, -1, -1, -1},       //  1011 1000   3,4,5,7  (perp edges l : 7,8)
    {  1,  9,  2,  2,  9,  4,  4,  2,  7,  9,  8,  4, -1, -1, -1, -1},       //  1101 0100   2,4,6,7  (perp edges l : 6,11)
    {  0,  8,  1,  1,  8,  7,  7,  1,  6,  8, 11,  7, -1, -1, -1, -1},       //  1110 0010   1,5,6,7  (perp edges l : 5,10)
 

    // Pattern 12- 3 in a plane plus opposing corner
    {  4,  5,  6,  4,  6,  3,  6,  3,  2,  7, 11, 10, -1, -1, -1, -1},       //  1000 0111   0,1,2,7  (3 on a face + 1)
    {  5,  6,  7,  5,  7,  0,  7,  0,  3,  4,  8, 11, -1, -1, -1, -1},       //  0001 1110   1,2,3,4  (3 on a face + 1)
    {  6,  7,  4,  6,  4,  1,  4,  1,  0,  5,  9,  8, -1, -1, -1, -1},       //  0010 1101   2,3,0,5  (3 on a face + 1)
    {  7,  4,  5,  7,  5,  2,  5,  2,  1,  6, 10,  9, -1, -1, -1, -1},       //  0100 1011   3,0,1,6  (3 on a face + 1)

    {  0,  8, 10,  0, 10,  1, 10,  1,  6,  2,  3,  7, -1, -1, -1, -1},       //  0110 1010   1,5,6,3  (3 on a face + 1)
    {  8, 10,  2,  8,  2,  5,  2,  5,  1,  0,  3,  4, -1, -1, -1, -1},       //  0110 0101   5,6,2,0  (3 on a face + 1)
    { 10,  2,  0, 10,  0,  9,  0,  9,  5,  4,  8, 11, -1, -1, -1, -1},       //  0101 0110   6,2,1,4  (3 on a face + 1)
    {  2,  0,  8,  2,  8,  6,  8,  6,  9,  7, 11, 10, -1, -1, -1, -1},       //  1010 0110   2,1,5,7  (3 on a face + 1)

    {  5,  4,  7,  5,  7,  9,  7,  9, 10,  1,  2,  6, -1, -1, -1, -1},       //  1011 0100   5,4,7,2  (3 on a face + 1)
    {  4,  7,  6,  4,  6,  8,  6,  8,  9,  0,  5,  1, -1, -1, -1, -1},       //  1101 0010   4,7,6,1  (3 on a face + 1)
    {  7,  6,  5,  7,  5, 11,  5, 11,  8,  0,  4,  3, -1, -1, -1, -1},       //  1110 0001   7,6,5,0  (3 on a face + 1)
    {  6,  5,  4,  6,  4, 10,  4, 10, 11,  2,  3,  7, -1, -1, -1, -1},       //  0111 1000   6,5,4,3  (3 on a face + 1)

    {  8,  0,  2,  8,  2, 11,  2, 11,  7,  6, 10,  9, -1, -1, -1, -1},       //  0101 1001   4,0,3,6  (3 on a face + 1)
    {  0,  2, 10,  0, 10,  4, 10,  4, 11,  5,  9,  8, -1, -1, -1, -1},       //  1010 1001   0,3,7,5  (3 on a face + 1)
    {  2, 10,  8,  2,  8,  3,  8,  3,  4,  0,  1,  5, -1, -1, -1, -1},       //  1001 1010   3,7,4,1  (3 on a face + 1)
    { 10,  8,  0, 10,  0,  7,  0,  7,  3,  1,  2,  6, -1, -1, -1, -1},       //  1001 0101   7,4,0,2  (3 on a face + 1)

    {  1,  9, 11,  1, 11,  2, 11,  2,  7,  0,  4,  3, -1, -1, -1, -1},       //  1100 0101   2,6,7,0  (3 on a face + 1)
    {  9, 11,  3,  9,  3,  6,  3,  6,  2,  0,  1,  5, -1, -1, -1, -1},       //  1100 1010   6,7,3,1  (3 on a face + 1)
    { 11,  3,  1, 11,  1, 10,  1, 10,  6,  5,  9,  8, -1, -1, -1, -1},       //  1010 1100   7,3,2,5  (3 on a face + 1)
    {  3,  1,  9,  3,  9,  7,  9,  7, 10,  4,  8, 11, -1, -1, -1, -1},       //  0101 1100   3,2,6,4  (3 on a face + 1)

    {  3, 11,  9,  3,  9,  0,  9,  0,  5,  1,  2,  6, -1, -1, -1, -1},       //  0011 0101   0,4,5,2  (3 on a face + 1)
    { 11,  9,  1, 11,  1,  4,  1,  4,  0,  2,  3,  7, -1, -1, -1, -1},       //  0011 1010   4,5,1,3  (3 on a face + 1)
    {  9,  1,  3,  9,  3,  8,  3,  8,  4,  7, 11, 10, -1, -1, -1, -1},       //  1010 0011   5,1,0,7  (3 on a face + 1)
    {  1,  3, 11,  1, 11,  5, 11,  5,  8,  6, 10,  9, -1, -1, -1, -1},       //  0101 0011   1,0,4,6  (3 on a face + 1)


    // Pattern 13 - Four corners in two diagonal opposites (2)
    {  9,  4,  3,  5,  9,  8,  1,  2,  6,  7, 11, 10, -1, -1, -1, -1},       //  1010 0101   0,5,2,7  (diagonal opposite corners)
    {  0,  1,  5,  4,  8, 11,  2,  3,  7,  6, 10,  9, -1, -1, -1, -1},       //  0101 1010   1,4,3,6  (diagonal opposite corners)


    // +----------------------------------------------------------------------------------------------------------------------------+
    // |                                                                                                                            |
    // |            Symmetry                                                                                                        |
    // |                                                                                                                            |
    // +----------------------------------------------------------------------------------------------------------------------------+

    // Pattern 20 - 4 points two perp edges
    {  1,  9,  0,  0,  9,  7,  7,  0,  4,  9, 10,  7, -1, -1, -1, -1},       //  1011 0010   1,4,5,7  (perp edges r : 5,11)
    {  0,  8,  3,  3,  8,  6,  6,  3,  7,  8,  9,  6, -1, -1, -1, -1},       //  1101 0001   0,4,6,7  (perp edges r : 4,10)
    {  3, 11,  2,  2, 11,  5,  5,  2,  6, 11,  8,  5, -1, -1, -1, -1},       //  1110 1000   3,5,6,7  (perp edges r : 7,9)
    {  2, 10,  1,  1, 10,  4,  4,  1,  5, 10,  7,  4, -1, -1, -1, -1},       //  0111 0100   2,4,5,6  (perp edges r : 6,8)
    {  9, 11,  5,  5, 11,  2,  2,  5,  0, 11,  7,  2, -1, -1, -1, -1},       //  0011 1001   0,3,4,5  (perp edges r : 3,8)
    {  8, 10,  4,  4, 10,  1,  1,  4,  3, 10,  6,  1, -1, -1, -1, -1},       //  1001 1100   2,3,4,7  (perp edges r : 2,8)
    { 11,  9,  7,  7,  9,  0,  0,  7,  2,  9,  5,  0, -1, -1, -1, -1},       //  1100 0110   1,2,6,7  (perp edges r : 1,10)
    { 11,  3,  8,  8,  3,  6,  6,  8,  5,  3,  2,  6, -1, -1, -1, -1},       //  0001 0111   0,1,2,4  (perp edges r : 1,4)
    { 10,  2, 11, 11,  2,  5,  5, 11,  4,  2,  1,  5, -1, -1, -1, -1},       //  1000 1011   0,1,3,7  (perp edges r : 0,7)
    {  9,  1, 10, 10,  1,  4,  4, 10,  7,  1,  0,  4, -1, -1, -1, -1},       //  0100 1101   0,2,3,6  (perp edges r : 3,6)
    {  8,  0,  9,  9,  0,  7,  7,  9,  6,  0,  3,  7, -1, -1, -1, -1},       //  0010 1110   1,2,3,5  (perp edges r : 2,5)
    {  3,  1,  4,  4,  1, 10, 10,  4,  8,  1,  6, 10, -1, -1, -1, -1},       //  0110 0011   0,1,5,6  (perp edges r : 0,9)

	// Pattern - 21 -Two planes diagonally opposite (3)
    {  0,  1,  8,  8,  1,  9,  2,  3, 10, 10,  3, 11, -1, -1, -1, -1},       //  1010 1010   1,3,5,7  (edges 5, 7 out)
    {  1,  3,  6,  6,  3,  7,  4,  5,  9,  4,  9, 11, -1, -1, -1, -1},       //  0011 1100   2,3,4,5  (edges 2, 8 out)
    {  0,  2,  5,  5,  2,  6,  4,  8,  7,  7,  8, 10, -1, -1, -1, -1},       //  1001 0110   1,2,4,7  (edges 1, 11 out)
    
    
    // Pattern 22  - Hexagonal (corner vertex plus three neighbours) (8)
    {  1,  8,  5,  1,  2,  8,  8,  2, 11,  2, 11,  7, -1, -1, -1, -1},       //  1110 0100   6,5,2,7  (hexagon)
    {  9,  4,  8,  9,  6,  4,  4,  6,  3,  6,  3,  2, -1, -1, -1, -1},       //  1101 1000   7,6,4,3  (hexagon)
	{  3,  5,  0,  3,  7,  5,  5,  7,  9,  7,  9, 10, -1, -1, -1, -1},       //  0100 1110   2,1,3,6  (hexagon)
    { 11,  6, 10, 11,  4,  6,  6,  4,  1,  4,  1,  0, -1, -1, -1, -1},       //  0111 0010   1,4,5,6  (hexagon)

    // Pattern 23  - Bisector (3) out
    {  4,  5,  7,  7,  5,  6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1111 0000   4,5,6,7  (bisect out)
    {  0,  2,  8,  8,  2, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0110 0110   1,2,5,6  (bisect out)
    {  1,  3,  9,  9,  3, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1100 1100   2,3,6,7  (bisect out)

    // Pattern 24  - two corners and diagonally opposite corner
    {  0,  3,  4,  1,  6,  2,  5,  8,  9, -1, -1, -1, -1, -1, -1, -1},       //  1101 1010   1,3,4,6,7  (3 tri out)
    {  0,  5,  1,  6,  9, 10,  4, 11,  8, -1, -1, -1, -1, -1, -1, -1},       //  1010 1101   0,2,3,5,7  (3 tri out)
    {  5,  8,  9,  7, 10, 11,  0,  3,  4, -1, -1, -1, -1, -1, -1, -1},       //  0101 1110   1,2,3,4,6  (3 tri out)
    {  4, 11,  8,  2,  7,  3,  0,  5,  1, -1, -1, -1, -1, -1, -1, -1},       //  1110 0101   0,2,5,6,7  (3 tri out)
    {  0,  3,  4,  1,  6,  2,  7, 10, 11, -1, -1, -1, -1, -1, -1, -1},       //  0111 1010   1,3,4,5,6  (3 tri out)
    {  0,  5,  1,  6,  9, 10,  2,  7,  3, -1, -1, -1, -1, -1, -1, -1},       //  1011 0101   0,2,4,5,7  (3 tri out)
    {  5,  8,  9,  7, 10, 11,  1,  6,  2, -1, -1, -1, -1, -1, -1, -1},       //  0101 1011   0,1,3,4,6  (3 tri out)
    {  4, 11,  8,  2,  7,  3,  6,  9, 10, -1, -1, -1, -1, -1, -1, -1},       //  1010 0111   0,1,2,5,7  (3 tri out)

    // Pattern 25 - Edge plus triangle out
    {  1,  3,  5,  5,  3,  4,  6,  9, 10, -1, -1, -1, -1, -1, -1, -1},       //  1011 1100   2,3,4,5,7  (edge 0 + 6 out)
    {  1,  3,  5,  5,  3,  4,  7, 10, 11, -1, -1, -1, -1, -1, -1, -1},       //  0111 1100   2,3,4,5,6  (edge 0 + 7 out)
    {  0,  5,  2,  2,  5,  6,  4, 11,  8, -1, -1, -1, -1, -1, -1, -1},       //  1110 1001   0,3,5,6,7  (edge 1 + 4 out)
    {  0,  5,  2,  2,  5,  6,  7, 10, 11, -1, -1, -1, -1, -1, -1, -1},       //  0111 1001   0,3,4,5,6  (edge 1 + 7 out)
    {  1,  6,  3,  3,  6,  7,  4, 11,  8, -1, -1, -1, -1, -1, -1, -1},       //  1110 0011   0,1,5,6,7  (edge 2 + 4 out)
    {  1,  6,  3,  3,  6,  7,  5,  8,  9, -1, -1, -1, -1, -1, -1, -1},       //  1101 0011   0,1,4,6,7  (edge 2 + 5 out)
    {  0,  2,  4,  4,  2,  7,  5,  8,  9, -1, -1, -1, -1, -1, -1, -1},       //  1101 0110   1,2,4,6,7  (edge 3 + 5 out)
    {  0,  2,  4,  4,  2,  7,  6,  9, 10, -1, -1, -1, -1, -1, -1, -1},       //  1011 0110   1,2,4,5,7  (edge 3 + 6 out)
    {  0,  3,  8,  8,  3, 11,  1,  6,  2, -1, -1, -1, -1, -1, -1, -1},       //  1110 1010   1,3,5,6,7  (edge 4 + 2 out)
    {  0,  3,  8,  8,  3, 11,  6,  9, 10, -1, -1, -1, -1, -1, -1, -1},       //  1010 1110   1,2,3,5,7  (edge 4 + 6 out)
    {  0,  8,  1,  1,  8,  9,  2,  7,  3, -1, -1, -1, -1, -1, -1, -1},       //  1101 0101   0,2,4,6,7  (edge 5 + 3 out)
    {  0,  8,  1,  1,  8,  9,  5,  8,  9, -1, -1, -1, -1, -1, -1, -1},       //  0101 1101   0,2,3,4,6  (edge 5 + 7 out)
    {  1,  9,  2,  2,  9, 10,  0,  3,  4, -1, -1, -1, -1, -1, -1, -1},       //  1011 1010   1,3,4,5,7  (edge 6 + 0 out)
    {  1,  9,  2,  2,  9, 10,  4, 11,  8, -1, -1, -1, -1, -1, -1, -1},       //  1010 1011   0,1,3,5,7  (edge 6 + 4 out)
    {  2, 10,  3,  3, 10, 11,  0,  5,  1, -1, -1, -1, -1, -1, -1, -1},       //  0111 0101   0,2,4,5,6  (edge 7 + 1 out)
    {  2, 10,  3,  3, 10, 11,  5,  8,  9, -1, -1, -1, -1, -1, -1, -1},       //  0101 0111   0,1,2,4,6  (edge 7 + 5 out)
    {  4, 11,  5,  5, 11,  9,  1,  6,  2, -1, -1, -1, -1, -1, -1, -1},       //  1100 1011   0,1,3,6,7  (edge 8 + 2 out)
    {  4, 11,  5,  5, 11,  9,  2,  7,  3, -1, -1, -1, -1, -1, -1, -1},       //  1100 0111   0,1,2,6,7  (edge 8 + 3 out)
    {  5,  8,  6,  6,  8, 10,  0,  3,  4, -1, -1, -1, -1, -1, -1, -1},       //  1001 1110   1,2,3,4,7  (edge 9 + 0 out)
    {  5,  8,  6,  6,  8, 10,  2,  7,  3, -1, -1, -1, -1, -1, -1, -1},       //  1001 0111   0,1,2,4,7  (edge 9 + 3 out)
    {  6,  9,  7,  7,  9, 11,  0,  3,  4, -1, -1, -1, -1, -1, -1, -1},       //  0011 1110   1,2,3,4,5  (edge 10 + 0 out)
    {  6,  9,  7,  7,  9, 11,  0,  5,  1, -1, -1, -1, -1, -1, -1, -1},       //  0011 1101   0,2,3,4,5  (edge 10 + 1 out)
    {  4,  7,  8,  8,  7, 10,  0,  5,  1, -1, -1, -1, -1, -1, -1, -1},       //  0110 1101   0,2,3,5,6  (edge 11 + 1 out)
    {  4,  7,  8,  8,  7, 10,  1,  6,  2, -1, -1, -1, -1, -1, -1, -1},       //  0110 1011   0,1,3,5,6  (edge 11 + 2 out)

    // Pattern 26  - 3 corners of a face (24)
    {  4,  5,  6,  4,  6,  3,  6,  2,  3, -1, -1, -1, -1, -1, -1, -1},       //  1111 1000   3,4,5,6,7  (3 on a face out)
    {  5,  6,  7,  5,  7,  0,  7,  3,  0, -1, -1, -1, -1, -1, -1, -1},       //  1111 0001   0,4,5,6,7  (3 on a face out)
    {  6,  7,  4,  6,  4,  1,  4,  0,  1, -1, -1, -1, -1, -1, -1, -1},       //  1111 0010   1,4,5,6,7  (3 on a face out)
    {  7,  4,  5,  7,  5,  2,  5,  1,  2, -1, -1, -1, -1, -1, -1, -1},       //  1111 0100   2,4,5,6,7  (3 on a face out)

    {  0,  8, 10,  0, 10,  1, 10,  6,  1, -1, -1, -1, -1, -1, -1, -1},       //  1001 1101   0,2,3,4,7  (3 on a face out)
    {  8, 10,  2,  8,  2,  5,  2,  1,  5, -1, -1, -1, -1, -1, -1, -1},       //  1001 1011   0,1,3,4,7  (3 on a face out)
    { 10,  2,  0, 10,  0,  9,  0,  5,  9, -1, -1, -1, -1, -1, -1, -1},       //  1011 1001   0,3,4,5,7  (3 on a face out)
    {  2,  0,  8,  2,  8,  6,  8,  9,  6, -1, -1, -1, -1, -1, -1, -1},       //  1101 1001   0,3,4,6,7  (3 on a face out)

    {  5,  4,  7,  5,  7,  9,  7, 10,  9, -1, -1, -1, -1, -1, -1, -1},       //  0100 1111   0,1,2,3,6  (3 on a face out)
    {  4,  7,  6,  4,  6,  8,  6,  9,  8, -1, -1, -1, -1, -1, -1, -1},       //  0010 1111   0,1,2,3,5  (3 on a face out)
    {  7,  6,  5,  7,  5, 11,  5,  8, 11, -1, -1, -1, -1, -1, -1, -1},       //  0001 1111   0,1,2,3,4  (3 on a face out)
    {  6,  5,  4,  6,  4, 10,  4, 11, 10, -1, -1, -1, -1, -1, -1, -1},       //  1000 1111   0,1,2,3,7  (3 on a face out)

    {  8,  0,  2,  8,  2, 11,  2,  7, 11, -1, -1, -1, -1, -1, -1, -1},       //  1110 0110   1,2,5,6,7  (3 on a face out)
    {  0,  2, 10,  0, 10,  4, 10, 11,  4, -1, -1, -1, -1, -1, -1, -1},       //  0111 0110   1,2,4,5,6  (3 on a face out)
    {  2, 10,  8,  2,  8,  3,  8,  4,  3, -1, -1, -1, -1, -1, -1, -1},       //  0110 0111   0,1,2,5,6  (3 on a face out)
    { 10,  8,  0, 10,  0,  7,  0,  3,  7, -1, -1, -1, -1, -1, -1, -1},       //  0110 1110   1,2,3,5,6  (3 on a face out)

    {  1,  9, 11,  1, 11,  2, 11,  7,  2, -1, -1, -1, -1, -1, -1, -1},       //  0011 1011   0,1,3,4,5  (3 on a face out)
    {  9, 11,  3,  9,  3,  6,  3,  2,  6, -1, -1, -1, -1, -1, -1, -1},       //  0011 0111   0,1,2,4,5  (3 on a face out)
    { 11,  3,  1, 11,  1, 10,  1,  6, 10, -1, -1, -1, -1, -1, -1, -1},       //  0111 0011   0,1,4,5,6  (3 on a face out)
    {  3,  1,  9,  3,  9,  7,  9, 10,  7, -1, -1, -1, -1, -1, -1, -1},       //  1011 0011   0,1,4,5,7  (3 on a face out)

    {  3, 11,  9,  3,  9,  0,  9,  5,  0, -1, -1, -1, -1, -1, -1, -1},       //  1100 1110   1,2,3,6,7  (3 on a face out)
    { 11,  9,  1, 11,  1,  4,  1,  0,  4, -1, -1, -1, -1, -1, -1, -1},       //  1100 1101   0,2,3,6,7  (3 on a face out)
    {  9,  1,  3,  9,  3,  8,  3,  4,  8, -1, -1, -1, -1, -1, -1, -1},       //  1101 1100   2,3,4,6,7  (3 on a face out)
    {  1,  3, 11,  1, 11,  5, 11,  8,  5, -1, -1, -1, -1, -1, -1, -1},       //  1110 1100   2,3,5,6,7  (3 on a face out)

    // Pattern 27 - Diagonally oppoisite triangles out
    {  0,  3,  4,  6,  9, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1011 1110   1,2,3,4,5,7     (2 diag tris out)
    {  0,  5,  1,  7, 10, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0111 1101   0,2,3,4,5,6     (2 diag tris out)
    {  2,  7,  3,  5,  8,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1101 0111   0,1,2,4,6,7     (2 diag tris out)
    {  1,  6,  2,  4, 11,  8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1110 1011   0,1,3,5,6,7     (2 diag tris out)


    // Pttern 28 - opposing triangles on the same face
    {  0,  3,  4,  1,  6,  2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1111 1010   1,3,4,5,6,7     (2 tri out)
    {  0,  3,  4,  5,  8,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1101 1110   1,2,3,4,6,7     (2 tri out)
    {  0,  3,  4,  7, 10, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0111 1110   1,2,3,4,5,6     (2 tri out)
    {  0,  5,  1,  2,  7,  3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1111 0101   0,2,4,5,6,7     (2 tri out)
    {  0,  5,  1,  4, 11,  8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1110 1101   0,2,3,5,6,7     (2 tri out)
    {  0,  5,  1,  6,  9, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1011 1101   0,2,3,4,5,7     (2 tri out)
    {  1,  6,  2,  5,  8,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1101 1011   0,1,3,4,6,7     (2 tri out)
    {  1,  6,  2,  7, 10, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0111 1011   0,1,3,4,5,6     (2 tri out)
    {  2,  7,  3,  4, 11,  8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1110 0111   0,1,2,5,6,7     (2 tri out)
    {  2,  7,  3,  6,  9, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1011 0111   0,1,2,4,5,7     (2 tri out)
    {  4, 11,  8,  6,  9, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1010 1111   0,1,2,3,5,7     (2 tri out)
    {  5,  8,  9,  7, 10, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0101 1111   0,1,2,3,4,6     (2 tri out)


    // Pattern 29 - One edge out
    {  1,  3,  5,  5,  3,  4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1111 1100   2,3,4,5,6,7     (edge 0 out)
    {  0,  5,  2,  2,  5,  6, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1111 1001   0,3,4,5,6,7     (edge 1 out)
    {  1,  6,  3,  3,  6,  7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1111 0011   0,1,4,5,6,7     (edge 2 out)
    {  0,  2,  4,  4,  2,  7, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1111 0110   1,2,4,5,6,7     (edge 3 out)
    {  0,  3,  8,  8,  3, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1110 1110   1,2,3,5,6,7     (edge 4 out)
    {  0,  8,  1,  1,  8,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1101 1101   0,2,3,4,6,7     (edge 5 out)
    {  1,  9,  2,  2,  9, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1011 1011   0,1,3,4,5,7     (edge 6 out)
    {  2, 10,  3,  3, 10, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0111 0111   0,1,2,4,5,6     (edge 7 out)
    {  4, 11,  5,  5, 11,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1100 1111   0,1,2,3,6,7     (edge 8 out)
    {  5,  8,  6,  6,  8, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1001 1111   0,1,2,3,4,7     (edge 9 out)
    {  6,  9,  7,  7,  9, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0011 1111   0,1,2,3,4,5     (edge 10 out)
    {  4,  7,  8,  8,  7, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0110 1111   0,1,2,3,5,6     (edge 11 out)

    // Pattern 30 - One out
    {  0,  3,  4, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1111 1110   1,2,3,4,5,6,7 (vertex 0 out)
    {  0,  5,  1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1111 1101   0,2,3,4,5,6,7 (vertex 1 out)
    {  1,  6,  2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1111 1011   0,1,3,4,5,6,7 (vertex 2 out)
    {  2,  7,  3, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1111 0111   0,1,2,4,5,6,7 (vertex 3 out)
    {  4, 11,  8, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1110 1111   0,1,2,3,5,6,7 (vertex 4 out)
    {  5,  8,  9, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1101 1111   0,1,2,3,4,6,7 (vertex 5 out)
    {  6,  9, 10, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  1011 1111   0,1,2,3,4,5,7 (vertex 6 out)
    {  7, 10, 11, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},       //  0111 1111   0,1,2,3,4,5,6 (vertex 7 out)


    // Pattern 31 - All under
    {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1},        //  1111 1111 
};