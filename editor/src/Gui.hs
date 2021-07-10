module Gui where

import Problem
import Debug.Trace
import Problem as P
import Graphics.Gloss
import Graphics.Gloss.Interface.IO.Game
import Data.Aeson
import qualified Data.ByteString.Lazy as B

data Editing = Editing
  { center :: Maybe P.Point
  , movePoint :: Maybe Int
  , followPoint :: Maybe Int }
  
data World = World
  { problem :: Problem
  , edgeLengths :: [Integer]
  , workingVertices :: [(Float,Float)]
  , editing :: Editing }

pointChanges = [ (-1,-1), (0,-1), (1,-1), (-1,0), (0,0), (1,0), (-1,1), (0,1), (1,1)]

pointToInt (xf,yf) = (round xf :: Int, round yf :: Int)

replaceNth n newVal l =
  (take n l) ++ (newVal : []) ++ (drop (n+1) l)

filterIntercepts :: (Int,Int) -> (Int,Int) -> (Int,Int) -> Int
filterIntercepts (ix,iy) (ix1,iy1) (ix2,iy2) =
  let x = fromIntegral ix
      y = fromIntegral iy
      x1 = fromIntegral ix1
      y1 = fromIntegral iy1
      x2 = fromIntegral ix2
      y2 = fromIntegral iy2 in
  if y > (min y1 y2) && y <= (max y1 y2) && x <= (max x1 x2) then
    if y1 /= y2 then
      let xinters = (y-y1)*(x2-x1)/(y2-y1)+x1 in
        if x1 == x2 || x <= xinters then
          1
        else
          0
    else
      0
  else
    0
  
pointInPolygon (x,y) hole =
  let result = (foldl (+) 0 (zipWith (filterIntercepts (x,y)) hole ((tail hole) ++ ((head hole) : [])))) `mod` 2 == 1 in
    trace ((show (x,y))++" in "++(show hole)++" returns "++(show result)) result
  
badLengths :: [Edge] -> [Integer] -> [(Int,Int)] -> Int -> [Edge] -> Int -> ([Edge],Int)
badLengths [] _ _ _ acc badnessAcc = (acc, badnessAcc)
badLengths ((Edge from to):edgeRest) (edgeLen:edgeLenRest) workingVertices epsilon acc badnessAcc =
  let (x1,y1) = workingVertices !! from
      (x2,y2) = workingVertices !! to
      e = (fromIntegral epsilon) / 1000000.0
      d = ((x2-x1)*(x2-x1)+(y2-y1)*(y2-y1))      
      badness = abs (d - (fromIntegral edgeLen)) in
    if abs ((fromIntegral d) / (fromIntegral edgeLen) - 1.0) >= e then
      badLengths edgeRest edgeLenRest workingVertices epsilon ((Edge from to):acc) (badnessAcc + badness) 
    else
      badLengths edgeRest edgeLenRest workingVertices epsilon acc badnessAcc

tryAdjustToInDirection :: Edge -> [Edge] -> [Integer] -> [(Int,Int)] -> Int -> [(Int,Int)] -> (Int,Int) -> Int -> [(Int,Int)] -> (Int, [(Int,Int)])
tryAdjustToInDirection (Edge f t) edges edgeLengths workingVertices epsilon hole (dx,dy) bestBadness bestVertices =
 let (tox,toy) = workingVertices !! t
     newToVertex = (tox+dx,toy+dy)
     newToWorkingVertices = replaceNth t newToVertex workingVertices
     (_,toBadness) = badLengths edges edgeLengths newToWorkingVertices epsilon [] 0 in
     if (pointInPolygon (tox,toy) hole) && toBadness < bestBadness then
       (toBadness, newToWorkingVertices)
     else
       (bestBadness, bestVertices)

tryAdjustFromInDirection :: Edge -> [Edge] -> [Integer] -> [(Int,Int)] -> Int -> [(Int,Int)] -> (Int,Int) -> Int -> [(Int,Int)] -> (Int, [(Int,Int)])
tryAdjustFromInDirection (Edge f t) edges edgeLengths workingVertices epsilon hole (dx,dy) bestBadness bestVertices =
   foldl adjustAndCompare (bestBadness,bestVertices) pointChanges
     where
       (fromx,fromy) = workingVertices !! f
       newFromVertex = (fromx+dx,fromy+dy)
       newFromWorkingVertices = replaceNth f newFromVertex workingVertices
       adjustAndCompare (oldBadness,oldVertices) dir =
         let (newBadness,newVertices) = tryAdjustToInDirection (Edge f t) edges edgeLengths
                                          newFromWorkingVertices
                                          epsilon hole dir oldBadness oldVertices in
           if (pointInPolygon (fromx,fromy) hole) && (newBadness < oldBadness) then
             (newBadness,newVertices)
           else
             (oldBadness,oldVertices)
     
tryAdjustEdge :: Edge -> [Edge] -> [Integer] -> [(Int,Int)] -> Int -> [(Int,Int)] -> Int -> [(Int,Int)] -> (Int, [(Int,Int)])
tryAdjustEdge edge edges edgeLengths workingVertices epsilon hole bestBadness bestVertices =
  foldl adjustAndCompare (bestBadness,bestVertices) pointChanges
  where
    adjustAndCompare (oldBadness,oldVertices) dir =
      let (newBadness,newVertices) = tryAdjustFromInDirection edge edges edgeLengths workingVertices
                                       epsilon hole dir oldBadness oldVertices in
        if (newBadness < oldBadness) then
          (newBadness,newVertices)
        else
          (oldBadness,oldVertices)

tryAdjustEdges badEdges edges edgeLengths workingVertices epsilon hole bestBadness bestVertices =
  foldl adjustAndCompare (bestBadness,bestVertices) badEdges
  where
    adjustAndCompare (oldBadness,oldVertices) edge =
      let (newBadness,newVertices) = tryAdjustEdge edge edges edgeLengths workingVertices epsilon hole
                                       oldBadness oldVertices in
        if newBadness < oldBadness then
          (newBadness,newVertices)
        else
          (oldBadness,oldVertices)
          
fixBad edges edgeLengths workingVertices epsilon hole =
  let (bad,totalBadness) = badLengths edges edgeLengths workingVertices epsilon [] 0
      (newBadness,newVertices) = tryAdjustEdges edges edges edgeLengths workingVertices epsilon hole
                                   totalBadness workingVertices in
    trace ("newBadness = " ++ (show newBadness)) $
    if totalBadness == 0 then
      newVertices
    else if newBadness < totalBadness then
      fixBad edges edgeLengths newVertices epsilon hole
    else
      error "Unable to correct edge lengths"
  
saveWorld world@(World (Problem hole (Figure edges vertices) epsilon) edgeLengths workingVertices _) = do
  let intVertices = map pointToInt workingVertices
  let holeInt = map (\p -> (fromIntegral $ x p, fromIntegral $ y p)) hole
  let fixedVertices = fixBad edges edgeLengths intVertices epsilon holeInt
  putStrLn "Writing solution"
  B.writeFile "sol.json" $ encode $ Solution fixedVertices
  return ()

squareDist (Point x1 y1) (Point x2 y2) =
  (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)

squareDistFloat (x1,y1) (x2,y2) =
  (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)
  
computeEdgeLengths :: Problem -> [Integer]
computeEdgeLengths (Problem _ (Figure edges vertices) _) =
  map getLength edges
  where
    getLength (Edge v1 v2) = squareDist (vertices !! v1) (vertices !! v2)


displayXToFloat xf = (xf + 500.0) / 2.0
floatXToPoint xf = round $ displayXToFloat xf

displayYToFloat yf = (yf + 0.0) / (-2.0)
floatYToPoint yf = round $ displayYToFloat yf

pointToDisplay (x,y) =
  (2.0 * x - 500, (-2.0) * y - 0)
  
pointToDisplayFloat :: P.Point -> (Float,Float)
pointToDisplayFloat (P.Point x y) = (fromIntegral (2 * x) - 500, fromIntegral (-2 * y) - 0)

drawHole hole =
  Color black $ Line $ map pointToDisplayFloat (hole ++ ((head hole) : []))

drawEdge vertices (Edge v1 v2) =
  Line [pointToDisplay (vertices !! v1), pointToDisplay (vertices !! v2)]
  
drawFigure edges vertices =
  Color blue $ Pictures $ map (drawEdge vertices) edges

drawVertex p =
  let (x,y) = pointToDisplay p in
    translate x y $ Color red $ circleSolid 4.0
  
drawVertices vertices =
  Pictures $ map drawVertex vertices
  
drawCenter Nothing = Blank
drawCenter (Just p) =
  let (xf,yf) = pointToDisplayFloat p in
    translate xf yf $ Color magenta $ circle 4.0

drawMovePoint Nothing _ = blank
drawMovePoint (Just mp) workingVertices =
  let (xf,yf) = pointToDisplay (workingVertices !! mp) in
    translate xf yf $ Color green $ circleSolid 4.0

drawFollowPoint Nothing _ = blank
drawFollowPoint (Just fp) workingVertices =
  let (xf,yf) = pointToDisplay (workingVertices !! fp) in
    translate xf yf $ Color magenta $ circleSolid 4.0
    
pointToFloat (P.Point x y) = (fromIntegral x, fromIntegral y)

worldToPic :: World -> IO Picture
worldToPic (World (Problem hole (Figure edges vertices) _) edgeLengths workingVertices
            (Editing center movePoint followPoint)) =
  return $ Pictures [drawHole hole, drawFigure edges workingVertices, drawVertices workingVertices, drawCenter center, drawMovePoint movePoint workingVertices, drawFollowPoint followPoint workingVertices]

checkFixed x y v fp =
  if squareDistFloat (x,y) v < 12 then
    not fp
  else
    fp
  
toggleFixed x y verts fixedPoints =
  zipWith (checkFixed x y) verts fixedPoints

rotatePoint cx cy dir (x,y) =
  let xf = x - cx
      yf = y - cy
      r = pi * dir / 180.0
      newx = xf * cos(r) - yf * sin(r)
      newy = xf * sin(r) + yf * cos(r) in
    ((cx+newx), (cy+newy))
            
getFixedCenter mp fp ((Edge from to):edgeRest) (edgeLen:edgeLenRest) =
  if (from == mp) && (to /= fp) then
    (to,edgeLen)
  else if (to == mp) && (from /= fp) then
    (from,edgeLen)
  else
    getFixedCenter mp fp edgeRest edgeLenRest

hasVertex mp (Edge from to) =
  (from == mp) || (to == mp)

getOppositeVertex mp (Edge from to) =
  if from == mp then
    to
  else
    from
  
getLinkedLen mp fp ((Edge from to):edgeRest) (edgeLen:edgeLenRest) =
  if (from == mp) && (to == fp) then
    edgeLen
  else if (from == fp) && (to == mp) then
    edgeLen
  else
    getLinkedLen mp fp edgeRest edgeLenRest

dist x1 y1 x2 y2 = sqrt ((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2))

computeFollow (mcx,mcy) mlen (fcx,fcy) flen (folx,foly) oldMoving =
  let dx = fcx - mcx
      dy = fcy - mcy
      mr = sqrt $ fromIntegral mlen
      fr = sqrt $ fromIntegral flen
      d = sqrt (dx*dx+dy*dy)
      dvx = dx / d
      dvy = dy / d
      a = (mr*mr - fr*fr + d * d) / (2.0 * d)
      px = mcx + a * dvx
      py = mcy + a * dvy in
    if mr*mr < a*a then
      ((folx,foly), oldMoving)
    else      
      let h = sqrt (mr*mr - a * a)
          fx1 = px + h * dvy
          fy1 = py - h * dvx
          fx2 = px - h * dvy
          fy2 = py + h * dvx in
      if (dist folx foly fx1 fy1) < (dist folx foly fx2 fy2) then
        ((fx1,fy1), (mcx,mcy))
      else
        ((fx2,fy2), (mcx,mcy))
      
  
rotateLeft world@(World _ _ _ (Editing Nothing Nothing Nothing))  = world
rotateLeft world@(World _ _ _ (Editing Nothing (Just v) Nothing)) = world
rotateLeft world@(World (Problem hole (Figure edges vertices) _) edgeLengths workingVertices
                        (Editing _ (Just mp) (Just fp))) =
   let moving = workingVertices !! mp
       following = workingVertices !! fp
       (mc,mlen) = (getFixedCenter mp fp edges edgeLengths)
       (mcx,mcy) = workingVertices !! mc
       (fc,flen) = (getFixedCenter fp mp edges edgeLengths)
       (fcx,fcy) = workingVertices !! fc
       linkedLen = getLinkedLen fp mp edges edgeLengths
       newMoving = rotatePoint mcx mcy (-5.0) moving
       (newFollowing,adjNewMoving) = computeFollow newMoving linkedLen (fcx,fcy) flen following moving in
     world { workingVertices = replaceNth mp adjNewMoving (replaceNth fp newFollowing workingVertices) }
                 
rotateLeft world@(World (Problem hole (Figure edges vertices) _) edgeLengths workingVertices
                        (Editing (Just (P.Point cx cy)) _ _)) =
  world { workingVertices = map (rotatePoint (fromIntegral cx) (fromIntegral cy) (-5.0)) workingVertices }

rotateRight world@(World _ _ _ (Editing Nothing Nothing Nothing))  = world
rotateRight world@(World _ _ _ (Editing Nothing (Just v) Nothing)) = world
rotateRight world@(World (Problem hole (Figure edges vertices) _) edgeLengths workingVertices
                         (Editing _ (Just mp) (Just fp))) =
   let moving = workingVertices !! mp
       following = workingVertices !! fp
       (mc,mlen) = getFixedCenter mp fp edges edgeLengths
       (mcx,mcy) = workingVertices !! mc
       (fc,flen) = getFixedCenter fp mp edges edgeLengths
       (fcx,fcy) = workingVertices !! fc
       linkedLen = getLinkedLen fp mp edges edgeLengths
       newMoving = rotatePoint mcx mcy (5.0) moving
       (newFollowing,adjNewMoving) = computeFollow newMoving linkedLen (fcx,fcy) flen following moving in
     world { workingVertices = replaceNth mp adjNewMoving (replaceNth fp newFollowing workingVertices) }
rotateRight world@(World (Problem hole (Figure edges vertices) _) edgeLengths workingVertices
                         (Editing (Just (P.Point cx cy)) _ _ )) =
  world { workingVertices = map (rotatePoint (fromIntegral cx) (fromIntegral cy) (5.0)) workingVertices }

reflectPointOverLine :: Float -> Float -> Float -> Float -> Float -> Float -> (Float,Float)
reflectPointOverLine px py x1 y1 x2 y2 =
  if y1 == y2 then
    (px, py + (2.0 * (y1 - py)))
  else if x1 == x2 then
    (px + 2.0 * (x1 - px), py)
  else
         let m = (y2-y1) / (x2-x1)
             t = y1 - m * x1
             ms = (-1.0) / m
             ts = py - px * ms
             lx = (ts - t) / (m - ms)
             ly = m * lx + t in
           (lx-(px-lx),ly-(py-ly))
        
flipPoints world@(World _ _ _ (Editing Nothing Nothing Nothing)) = world
flipPoints world@(World (Problem _ (Figure edges _) _) edgeLengths workingVertices
                 (Editing _ (Just mp) Nothing)) =
  let adjacentVertexEdges = filter (hasVertex mp) edges
      (x,y) = workingVertices !! mp
      [p1p,p2p] = map (getOppositeVertex mp) adjacentVertexEdges
      (x1,y1) = workingVertices !! p1p
      (x2,y2) = workingVertices !! p2p
      newp1 = reflectPointOverLine x y x1 y1 x2 y2 in
    world { workingVertices = replaceNth mp newp1 workingVertices,
            editing = Editing Nothing Nothing Nothing}      
flipPoints world@(World (Problem _ (Figure edges _) _) edgeLengths workingVertices
                 (Editing _ (Just mp) (Just fp))) =
  let (px1,py1) = workingVertices !! mp
      (px2,py2) = workingVertices !! fp
      (mc,_) = getFixedCenter mp fp edges edgeLengths
      (x1,y1) = workingVertices !! mc
      (fc,_) = getFixedCenter fp mp edges edgeLengths
      (x2,y2) = workingVertices !! fc
      newp1 = reflectPointOverLine px1 py1 x1 y1 x2 y2
      newp2 = reflectPointOverLine px2 py2 x1 y1 x2 y2 in
    world { workingVertices = replaceNth mp newp1 (replaceNth fp newp2 workingVertices),
            editing = Editing Nothing Nothing Nothing}      

containsVertex v (Edge f t) = f == v || t == v
  
followChain _ [_] = []
followChain startPos edges =
  let (Edge f t) = head $ filter (containsVertex startPos) edges
      edgeRest = filter (not . (containsVertex startPos)) edges in
    if f == startPos then
      t : followChain t edgeRest
    else
      f : followChain f edgeRest          
  
collapseSquare world@(World (Problem _ (Figure edges _) _) edgeLengths workingVertices _) =
  if (length edges) /= 4 then
    world
  else
    let ((Edge f1 t1) : edgeRest) = edges
        pointOrder = f1 : t1 : followChain t1 edgeRest in
      trace ("Point order = "++(show pointOrder)) $
      world { workingVertices = replaceNth (pointOrder !! 2) (workingVertices !! (pointOrder !! 0)) $
            replaceNth (pointOrder !! 3) (workingVertices !! (pointOrder !! 1)) workingVertices }
        
translatePointXY (xtrans,ytrans) (x,y) = (x+xtrans,y+ytrans)

translateXY trans vertices = map (translatePointXY trans) vertices

vertIndex x y [] n = Nothing
vertIndex x y ((vx,vy):vrest) n =
  let dx = (x - vx)
      dy = (y - vy) in
    if dx*dx + dy*dy < 12 then
      Just n
    else
      vertIndex x y vrest (n + 1)
  
toggleCenter Nothing x y =
  Just (P.Point x y)

toggleCenter (Just (P.Point cx cy)) xf yf =
  let dxf = xf - fromIntegral cx
      dyf = yf - fromIntegral cy in
      if dxf*dxf + dyf*dyf < 12 then
        Nothing
      else
        Just (P.Point xf yf)

toggleEditing ed@(Editing _ Nothing Nothing) xf yf verts =
  ed { movePoint = vertIndex xf yf verts 0 }
toggleEditing ed@(Editing _ _ Nothing) xf yf verts =
    ed { followPoint = vertIndex xf yf verts 0 }
toggleEditing ed _ _ _ = ed

eventHandler :: Event -> World -> IO World
eventHandler (EventKey (MouseButton RightButton) Up (Modifiers Up Up Up) (xf, yf)) world =
  let x = displayXToFloat xf
      y = displayYToFloat yf
      verts = workingVertices world
      ed = editing world in
    return $ world {editing = toggleEditing ed x y verts }
    
eventHandler (EventKey (MouseButton RightButton) Up (Modifiers Down Up Up) (xf, yf)) world =
  let x = floatXToPoint xf
      y = floatYToPoint yf in
  return $ world { editing = (editing world) { center =  toggleCenter (center (editing world)) x y } }  
eventHandler (EventKey (Char '<') Up _ (xf, yf)) world =
  return $ rotateLeft world
eventHandler (EventKey (Char '>') Up _ (xf, yf)) world =
  return $ rotateRight world
eventHandler (EventKey (Char 'c') Up _ (xf, yf)) world =
  return $ world {editing = Editing Nothing Nothing Nothing}
eventHandler (EventKey (Char 'S') Up _ (xf, yf)) world = do
  saved <- saveWorld world
  return world
eventHandler (EventKey (Char 'f') Up _ (xf, yf)) world = do
  return $ flipPoints world
eventHandler (EventKey (Char 'q') Up _ (xy, yf)) world = do
  return $ collapseSquare world
eventHandler (EventKey (SpecialKey KeyLeft) Up _ (xf, yf)) world =
  return $ world { workingVertices = translateXY (-1.0,0.0) (workingVertices world) }
eventHandler (EventKey (SpecialKey KeyRight) Up _ (xf, yf)) world =
  return $ world { workingVertices = translateXY (1.0,0.0) (workingVertices world) }
eventHandler (EventKey (SpecialKey KeyUp) Up _ (xf, yf)) world =
  return $ world { workingVertices = translateXY (0.0,-1.0) (workingVertices world) }
eventHandler (EventKey (SpecialKey KeyDown) Up _ (xf, yf)) world =
  return $ world { workingVertices = translateXY (0.0,1.0) (workingVertices world) }
eventHandler _ world = return world
    

iterateWorld :: Float -> World -> IO World
iterateWorld _ world = return world

runApp :: Maybe Problem -> IO ()
runApp (Just problem@(Problem _ (Figure _ vertices) _)) = do
  let startWorld = World problem (computeEdgeLengths problem)
                         (map pointToFloat vertices)
                         (Editing Nothing Nothing Nothing)
                   in
    playIO (InWindow "NashFP Problem Editor" (1200, 800) (10, 10)) white 1 startWorld
         worldToPic eventHandler iterateWorld

runApp Nothing = do
  putStrLn "Couldn't load problem"
  return ()
