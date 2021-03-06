module Model ( Coord, minC, maxC, distance, midpoint, findContiguous, dropLeadingEmpties
             , allNeighbors, allNeighborsBy, vonNeumann, moore
             , BoundingBox(..), boxOf
             , Grid
               , showGrid, showCharGrid
               , islands, splitByVal, first, unsafeFirst, trim
               , fromCoords, Map.insert, Map.fromList, Map.toList, Map.size, Map.empty, Map.member) where
    
import Data.Maybe (fromJust)
import Data.List (nub, group, sort)
import Data.Map (Map)
import qualified Data.Map as Map

----- Coords
type Coord = (Integer, Integer)

minC :: Coord -> Coord -> Coord
minC (x, y) (x', y') = (min x x', min y y')

maxC :: Coord -> Coord -> Coord
maxC (x, y) (x', y') = (max x x', max y y')

distance :: Coord -> Coord -> Integer
distance (x, y) (x', y') = toInteger $ round . sqrt $ ((maxX - minX) ** 2) + ((maxY - minY) ** 2)
    where [minX, maxX, minY, maxY] = map fromIntegral [min x x', max x x', min y y', max y y']

midpoint :: Coord -> Coord -> Coord
midpoint (x, y) (x', y') = ((x+x') `div` 2, (y+y') `div` 2)

findContiguous :: Grid a -> [Coord] -> [Coord]
findContiguous m cs = recur cs []
    where recur [] acc       = reverse acc
          recur (c:rest) acc = case Map.lookup c m of
                                 Nothing -> recur [] acc
                                 Just _ -> recur rest $ c:acc

dropLeadingEmpties :: Eq a => Grid a -> [Coord] -> [Coord]
dropLeadingEmpties m cs = dropWhile ((==Nothing) . flip Map.lookup m) cs

moore :: Coord -> [Coord]
moore (x, y) = [(x+x', y+y') | x' <- [-1..1], y' <- [-1..1], (0,0) /= (x', y')]

vonNeumann :: Coord -> [Coord]
vonNeumann (x, y) = [(x+x', y+y') | x' <- [-1..1], y' <- [-1..1], abs x' /= abs y']

allNeighborsBy :: (Coord -> [Coord]) -> [Coord] -> [Coord]
allNeighborsBy fn = nub . concatMap fn

allNeighbors :: [Coord] -> [Coord]
allNeighbors = allNeighborsBy vonNeumann


----- Bounding Boxes
data BoundingBox = Box { boxTopLeft :: Coord, boxBottomRight :: Coord } deriving (Eq, Ord, Show, Read)

boxOf :: Grid a -> BoundingBox
boxOf m = if Map.null m
          then Box (0, 0) (0, 0)
          else Map.foldWithKey (\k _ (Box a b) -> Box (minC k a) (maxC k b)) (Box first first) m
              where first = fst . head $ Map.toList m

----- Grids
type Grid a = Map Coord a

fromCoords :: [Coord] -> Grid Bool
fromCoords = Map.fromList . map (\c -> (c, True))

unsafeFirst :: Grid a -> Coord
unsafeFirst grid = fst . head $ Map.toList grid

first :: Grid a -> Maybe Coord
first grid 
    | Map.size grid == 0 = Nothing
    | otherwise          = Just $ unsafeFirst grid

showCharGrid :: Grid Char -> String
showCharGrid m = unlines [ln y | y <- [minY..maxY]]
    where ln y = concat [ case Map.lookup (x, y) m of
                            Nothing -> " "
                            Just a -> [a] | x <- [minX..maxX]]
          (Box (minX, minY) (maxX, maxY)) = boxOf m

showGrid :: Show a => Grid a -> String
showGrid m = unlines [ln y | y <- [minY..maxY]]
    where ln y = concat [ case Map.lookup (x, y) m of
                            Nothing -> " "
                            Just a -> show a | x <- [minX..maxX]]
          (Box (minX, minY) (maxX, maxY)) = boxOf m

islands :: Grid a -> [Grid a]
islands grid 
    | Map.size grid == 0 = []
    | otherwise          = r : (islands $ Map.difference grid r)
                        where r = nextRegion grid

nextRegion :: Grid a -> Grid a
nextRegion m = recur [unsafeFirst m] m Map.empty
    where members grid cs = filter (flip Map.member grid) cs
          val c = fromJust $ Map.lookup c m
          recur [] _ acc = acc
          recur layer grid acc = let nextGrid = foldl (flip Map.delete) grid layer
                                     nextLayer = members nextGrid $ allNeighbors layer
                                 in recur nextLayer nextGrid $ foldl (\memo c -> Map.insert c (val c) memo) acc layer

splitByVal :: Ord a => Grid a -> [Grid a]
splitByVal m = map (\(k, v) -> Map.fromList $ zip v $ repeat k) $ splits
    where splits = Map.toList $ Map.foldWithKey split Map.empty m 
          split k v memo = Map.alter (ins k) v memo
          ins new (Just v) =  Just $ new:v
          ins new Nothing = Just [new]

trim :: Grid a -> Grid a
trim g = Map.fromList . next . map fst $ Map.toList g
    where next lst = map (\c -> (c, val c)) . map head . filter survive $ census lst
          census lst = group . sort $ concatMap moore lst 
          survive []     = False
          survive [_]    = False
          survive [_, _] = False
          survive (c:_)  = Map.member c g
          val c = fromJust $ Map.lookup c g
          
