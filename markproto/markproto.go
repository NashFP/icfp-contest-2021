package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"math"
	"math/rand"
	"os"
	"sort"
	"strconv"
	"time"
)

type Point struct {
	x, y int
}

type Edge struct {
	from, to int
}

type LineSegment struct {
	from, to Point
}

type PosePoint struct {
	fixed bool
	point Point
}

type PointAndIndex struct {
	index int
	point Point
}

type IndexAndDistance struct {
	index int
	distance int
}

type IndexAndPoints struct {
	index int
	points []Point
}

type JSONFigure struct {
	Edges [][]int
	Vertices [][]int
}

type JSONProblem struct {
	Hole [][]int
	Figure JSONFigure
	Epsilon int
}

type Figure struct {
	edges []Edge
	vertices []Point
}

type Problem struct {
	problemNumber int
	hole []Point
	figure Figure
	epsilon int
	e float64
}

type Solution struct {
	problem *Problem
	posePoints []PosePoint
	holeEdges []LineSegment
	neighbors map[int][]IndexAndDistance
	solved bool
	bestScore int
	bestPosePoints []PosePoint
}

type SaveSolution struct {
	Vertices [][]int `json:"vertices"`
}

var skip int

func intsToPoint(ints []int) Point {
	return Point {x: ints[0], y: ints[1]}
}

func makePoints(ints [][]int) []Point {
	points := make([]Point, len(ints))
	for i := 0; i < len(ints); i++ {
		points[i] = intsToPoint(ints[i])
	}
	return points
}

func intsToEdge(ints []int) Edge {
	return Edge {from: ints[0], to: ints[1]}
}

func makeEdges(ints [][]int) []Edge {
	edges := make([]Edge, len(ints))
	for i := 0; i < len(ints); i++ {
		edges[i] = intsToEdge(ints[i])
	}
	return edges
}

func LoadProblem(problemNumber string) Problem {
	filename := fmt.Sprintf("../problems/%s.json", problemNumber)
	content, err := ioutil.ReadFile(filename)

	if err != nil {
		log.Fatalf("Error opening file %s: %+v", filename, err)
	}

	var problem JSONProblem
	err = json.Unmarshal(content, &problem)
	if err != nil {
		log.Fatal("Error unmarshaling json", err)
	}

	return Problem {
		figure: Figure {
			edges: makeEdges(problem.Figure.Edges),
			vertices: makePoints(problem.Figure.Vertices),
		},
		hole: makePoints(problem.Hole),
		epsilon: problem.Epsilon,
		e: float64(problem.Epsilon) / 1000000.0,
	}
}

func getPointsInCircle(point Point, dist int, e float64) []Point {
	largestSegment := int(math.Sqrt(float64(dist)/2.0))

	startingPoints := []int{}
	for i := 0; i <= largestSegment; i++ {
		partner := int(math.Sqrt(float64(dist - i*i)))
		point_dist := partner * partner + i * i
		ratio := math.Abs(float64(point_dist) / float64(dist) - 1.0)
		if ratio <= e {
			startingPoints = append(startingPoints, i)
		}
	}

	pointsInCircle := []Point{}
	for _,p1 := range startingPoints {
		p2 := int(math.Sqrt(float64(dist - p1*p1)))

		pointsInCircle = append(pointsInCircle,
			Point{point.x-p1,point.y-p2},
			Point{point.x-p1,point.y+p2},
			Point{point.x+p1,point.y-p2},
			Point{point.x+p1,point.y+p2},
			Point{point.x-p2,point.y-p1},
			Point{point.x-p2,point.y+p1},
			Point{point.x+p2,point.y-p1},
			Point{point.x+p2,point.y+p1})
	}
	return pointsInCircle
}

func orientation(p Point, q Point, r Point) int {
	val := (q.y-p.y) * (r.x-q.x) - (q.x-p.x) * (r.y-q.y)
	if val == 0 {
		return 0
	} else if val > 0 {
		return 1
	} else {
		return 2
	}
}

func min(a int, b int) int { if (a < b) { return a } else { return b }}
func max(a int, b int) int { if (a > b) { return a } else { return b }}

func isPointOnLine(point Point, p1 Point, p2 Point) bool {
	if orientation(point, p1, p2) == 0 {
		return point.x >= min(p1.x,p2.x) && point.x <= max(p1.x,p2.x) &&
			   point.y >= min(p1.y,p2.y) && point.y <= max(p1.y,p2.y)
	} else {
		return false
	}
}

func isOnSegment(p, q, r Point) bool {
	return q.x <= max(p.x,r.x) && q.x >= min(p.x,r.x) && q.y <= max(p.y,r.y) && q.y >= min(p.y,r.y)
}

func intersects(p1, p2 LineSegment, allowColinear bool) bool {
	o1 := orientation(p1.from, p1.to, p2.from)
	o2 := orientation(p1.from, p1.to, p2.to)
	o3 := orientation(p2.from, p2.to, p1.from)
	o4 := orientation(p2.from, p2.to, p1.to)

	return o1 != o2 && o3 != o4 && (allowColinear ||
			(o1 != 0 && o2 != 0 && o3 != 0 && o4 != 0))
}

func isPointInPolygon(point Point, poly []LineSegment) bool {
	for _, p := range poly {
		if isPointOnLine(point, p.from, p.to) {
			return true
		}
	}
	c := false
	ray := LineSegment{from: point, to: Point{math.MaxInt32, point.y}}
	for _, p := range poly {
		if intersects(ray, p, true) {
			if p.from.y != point.y {
				c = !c
			}
		}
	}

	ray2 := LineSegment{from: point, to: Point{point.x, math.MaxInt32}}
	d := false
	for _, p := range poly {
		if intersects(ray2, p, true) {
			if p.from.y != point.y {
				d = !d
			}
		}
	}
	return c && d
}

func isLineInPolygon(line LineSegment, poly []LineSegment) bool {
	if !isPointInPolygon(line.from, poly) || !isPointInPolygon(line.to, poly) {
		return false
	}
	for _, p := range poly {
		if intersects(line, p, false) {
			return false
		}
	}
	return true
}

func makePosePoints(points []Point) []PosePoint {
	pp := make([]PosePoint, len(points))
	for i,p := range points {
		pp[i] = PosePoint{fixed: false, point: p}
	}
	return pp
}
func makeSolution(problem *Problem) *Solution {
	holeEdges := []LineSegment{}
	for i, h := range problem.hole {
		holeEdges = append(holeEdges, LineSegment{from: h, to: problem.hole[(i+1)%len(problem.hole)] })
	}

	neighbors := map[int][]IndexAndDistance{}
	for _, edge := range problem.figure.edges {
		fromPoint := problem.figure.vertices[edge.from]
		toPoint := problem.figure.vertices[edge.to]
		dist := squaredDistance(fromPoint, toPoint)

		n, ok := neighbors[edge.from]
		if !ok {
			n = []IndexAndDistance{}
		}
		n = append(n, IndexAndDistance{index: edge.to, distance: dist})
		neighbors[edge.from] = n

		n, ok = neighbors[edge.to]
		if !ok {
			n = []IndexAndDistance{}
		}
		n = append(n, IndexAndDistance{index: edge.from, distance: dist})
		neighbors[edge.to] = n
	}

	solution := Solution {
		problem: problem,
		posePoints: makePosePoints(problem.figure.vertices),
		neighbors: neighbors,
		holeEdges: holeEdges,
		solved: false,
		bestScore: math.MaxInt32,
		bestPosePoints: makePosePoints(problem.figure.vertices),
	}
	return &solution
}

func saveSolution(solution *Solution) {
	points := make([][]int, len(solution.posePoints))
	for i, pp := range solution.bestPosePoints {
		points[i] = []int{pp.point.x, pp.point.y}
	}
	saveSol := SaveSolution{ Vertices: points }
	saveSolBytes, err := json.Marshal(&saveSol)
	if err != nil {
		log.Fatal("Error marshaling solution", err)
	}

	err = ioutil.WriteFile(fmt.Sprintf("../solutions/%d.json", solution.problem.problemNumber),
		saveSolBytes, 0666)
	if err != nil {
		log.Fatal("Error writing solution", err)
	}
}

func fixPoint(vertexIndex int, point Point, solution *Solution) {
	solution.posePoints[vertexIndex] = PosePoint{fixed: true, point: point}
}

func unfixPoint(vertexIndex int, solution *Solution) {
	solution.posePoints[vertexIndex].fixed = false
}

func getFixedPointsWithIndices(solution *Solution) []PointAndIndex {
	points := []PointAndIndex{}
	for i, pp := range solution.posePoints {
		if pp.fixed {
			points = append(points, PointAndIndex{index: i, point: pp.point})
		}
	}
	return points
}

func computeScore(solution *Solution) {
	score := 0
	for _, holePoint := range solution.problem.hole {
		bestCandidate := squaredDistance(holePoint, solution.posePoints[0].point)
		for _, pp := range solution.posePoints {
			bestCandidate = min(bestCandidate, squaredDistance(holePoint, pp.point))
		}
		score += bestCandidate
	}
	if !solution.solved || score < solution.bestScore {
		solution.solved = true
		solution.bestScore = score
		bestPosePoints := make([]PosePoint,len(solution.posePoints))
		for i, pp := range solution.posePoints {
			bestPosePoints[i] = pp
		}
		solution.bestPosePoints = bestPosePoints
		fmt.Printf("Best score for problem %d is now %d\n", solution.problem.problemNumber, score)
		saveSolution(solution)
	}
}

func getUnfixedPointIndicesConnectedToFixedPoints(solution *Solution) []int {
	points := map[int]bool{}
	for _, edge := range solution.problem.figure.edges {
		fromFixed := solution.posePoints[edge.from].fixed
		toFixed := solution.posePoints[edge.to].fixed
		if fromFixed && !toFixed {
			points[edge.to] = true
		} else if toFixed && !fromFixed {
			points[edge.from] = true
		}
	}
	indices := []int{}
	for k,_ := range points {
		indices = append(indices, k)
	}
	return indices
}

func getPossibleFixedPointForUnfixedIndex(unfixedIndex int, solution *Solution) []Point {
	var allPoints map[Point]bool

	for _, pi := range solution.neighbors[unfixedIndex] {
		pp := solution.posePoints[pi.index]
		if !pp.fixed {
			continue
		}
    	pointSet := map[Point]bool{}
		points := getPointsInCircle(pp.point, pi.distance, solution.problem.e)
		for _, p := range points {
			if isLineInPolygon(LineSegment{from: pp.point, to: p}, solution.holeEdges) {
				pointSet[p] = true
			}
		}
//		fmt.Printf("Point set has %d points\n", len(pointSet))
		if allPoints == nil {
			allPoints = pointSet
		} else {
			newPointSet := map[Point]bool {}
			for k,_ := range pointSet {
				_,ok := allPoints[k]
				if ok {
					newPointSet[k] = true
				}
			}
			allPoints = newPointSet
		}
	}

	result := []Point{}
	for k,_ := range allPoints {
		result = append(result, k)
	}
	return result
}

func squaredDistance(p1, p2 Point) int {
	dx := p1.x-p2.x
	dy := p1.y-p2.y
	return dx*dx+dy*dy
}

func solve(solution *Solution) {
	fixPoints := computeInitialFixPoints(solution)
	firstFixedIndex := computeFirstFixIndex(solution)

	for i, fp := range fixPoints {
		fmt.Printf("Trying starting point %d of %d\n", i+1, len(fixPoints))
		fixPointAndSolve(firstFixedIndex, fp, solution)
	}
}

func getPointsInHole(hole []Point) []Point {
	minx := hole[0].x
	maxx := minx
	miny := hole[0].y
	maxy := miny

	for _, h := range hole {
		if h.x < minx {
			minx = h.x
		}
		if h.x > maxx {
			maxx = h.x
		}
		if h.y < miny {
			miny = h.y
		}
		if h.y > maxy {
			maxy = h.y
		}
	}

	points := []Point{}

	for x := minx; x <= maxx; x += skip {
		for y := miny; y <= maxy; y += skip {
			points = append(points, Point{x:x,y:y})
		}
	}
	fmt.Printf("%d points in hole\n", len(points))

	return points
}

func scramblePointList(points []Point) {
	for i := 0; i < len(points); i++ {
		newPos := rand.Intn(len(points))
		if newPos != i {
			points[i], points[newPos] = points[newPos], points[i]
		}
	}
}

func computeInitialFixPoints(solution *Solution) []Point {
	initialFixPoints := []Point{}
	for _, p := range getPointsInHole(solution.problem.hole) {
		if isPointInPolygon(p, solution.holeEdges) {
			initialFixPoints = append(initialFixPoints, p)
		}
	}
	scramblePointList(initialFixPoints)
	return initialFixPoints
}

func computeFirstFixIndex(solution *Solution) int {
	return rand.Intn(len(solution.problem.figure.vertices))
}

type IndexAndPointList []IndexAndPoints

func (ip IndexAndPointList) Len() int {
	return len(ip)
}

func (ip IndexAndPointList) Less(i,j int) bool {
	return len(ip[i].points) < len(ip[j].points)
}

func (ip IndexAndPointList) Swap(i,j int) {
	ip[i], ip[j] = ip[j], ip[i]
}

func rankUnfixedIndices(unfixed []int, solution *Solution) []IndexAndPoints {
	indexAndPoints := []IndexAndPoints{}
	for _, u := range unfixed {
//		fmt.Printf("Getting possible fixed points for unfixed index %d\n", u)
		points := getPossibleFixedPointForUnfixedIndex(u, solution)
//		fmt.Printf("Got %d points for unfixed index %d\n", len(points), u)
		indexAndPoints = append(indexAndPoints, IndexAndPoints{index: u, points: points})
	}

	sort.Sort(IndexAndPointList(indexAndPoints))

	return indexAndPoints
}

func fixPointAndSolve(fixIndex int, fixPointLoc Point, solution *Solution) {
//	fmt.Printf("Fixing point %d,%d at index %d\n", fixPointLoc.x, fixPointLoc.y, fixIndex)
	fixPoint(fixIndex, fixPointLoc, solution)
	defer unfixPoint(fixIndex, solution)

	unfixed := getUnfixedPointIndicesConnectedToFixedPoints(solution)
//	fmt.Printf("Unfixed size = %d\n", len(unfixed))
	if len(unfixed) == 0 {
		computeScore(solution)
		return
	}

	pointsToTry := rankUnfixedIndices(unfixed, solution)
	points := pointsToTry[0].points
//	fmt.Printf("pointsToTry[0] has %d points\n", len(points))
	if len(points) == 0 {
//		fmt.Printf("Backtracking\n")
		return
	}

	index := pointsToTry[0].index
	for _, p := range points {
		fixPointAndSolve(index, p, solution)
	}
//	fmt.Printf("Backtracking\n")
}

func main() {
	problemNumber := os.Args[1]
	skip = 5
	if len(os.Args) > 2 {
		skip, _ = strconv.Atoi(os.Args[2])
	}

	rand.Seed(time.Now().UnixNano())

	problem := LoadProblem(problemNumber)
	problem.problemNumber, _ = strconv.Atoi(problemNumber)

	fmt.Printf("Hole has %d points, Figure has %d edges and %d vertices\n",
		len(problem.hole), len(problem.figure.edges), len(problem.figure.vertices))

	solution := makeSolution(&problem)
	solve(solution)
	if solution.solved {
		fmt.Printf("Solved problem %d with score of %d\n", problem.problemNumber, solution.bestScore)
		saveSolution(solution)
	}
}
