{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

module Problem where

import Data.Aeson (ToJSON(..), FromJSON(..), Value(..), (.:), (.=), object, decode, Array, Value)
import Data.Aeson.Types (prependFailure, typeMismatch)
import Data.Text (Text)
import qualified Data.ByteString.Lazy as B
import GHC.Generics

data Point = Point {
  x :: Integer,
  y :: Integer } deriving (Show, Eq, Ord, Generic)

data Edge = Edge {
  from :: Int,
  to :: Int } deriving (Show, Eq, Ord, Generic)

data Figure = Figure {
  edges :: [Edge],
  vertices :: [Point] } deriving (Show, Eq, Ord, Generic)

data Problem = Problem
  { hole :: [Point],
    figure :: Figure,
    epsilon:: Int} deriving (Show, Eq, Ord, Generic)
    
data Solution = Solution
  { vertices :: [(Int,Int)] } deriving (Show, Eq, Ord, Generic)

instance FromJSON Point where
  parseJSON jsn = do
    [x,y] <- parseJSON jsn
    return $ Point x y

instance FromJSON Edge where
  parseJSON jsn = do
    [from,to] <- parseJSON jsn
    return $ Edge from to

instance FromJSON Figure where
  parseJSON (Object v) = do
    edges <- v .: "edges"
    vertices <- v .: "vertices"
    return $ Figure edges vertices

instance FromJSON Problem where
  parseJSON (Object v) = do
    hole <- v .: "hole"
    figure <- v .: "figure"
    epsilon <- v .: "epsilon"
    return $ Problem hole figure epsilon

--instance ToJSON Point where
--  toJSON (Point x y) =
--    Array $ V.fromList [I x,I y]
instance ToJSON Point
    
--instance ToJSON Solution where
--  toJSON (Solution vertices) =
--    object [ "vertices" .= vertices ]
instance ToJSON Solution
    
  
loadProblem :: Integer -> IO (Maybe Problem)
loadProblem n = do
  let filename = "../problems/" ++ (show n) ++ ".json"  
  fileData <- B.readFile filename
  putStrLn $ "Loaded file "++filename
  return $ decode fileData
  
    
    
