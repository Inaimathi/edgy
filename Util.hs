module Util ( iterateM_, putTwoUp
            , lengthI, sizeI, infI, descending
            , none) where

import Data.List (sortBy)
import Data.Map (Map, size)

descending :: Ord a => [a] -> [a]
descending = sortBy (flip compare)

lengthI :: [a] -> Integer
lengthI = toInteger . length

sizeI :: Map k v -> Integer
sizeI = toInteger . size

putTwoUp :: String -> String -> IO ()
putTwoUp strA strB = mapM_ (\(a, b) -> putStrLn $ concat [a, " + ", b])
               $ zip (lines strA) (lines strB)

iterateM_ :: Monad m => (a -> m a) -> a -> m b
iterateM_ f a = do res <- f a
                   iterateM_ f res

none :: [Bool] -> Bool
none = and . map not

infI :: Integer
infI = toInteger . round $ 1/0
