module Main where

import System.Environment
import Problem
import Gui

main :: IO ()
main = do
  args <- getArgs
  let problemNumber = (read $ args !! 0) :: Integer
  putStrLn $ "Problem number "++(show problemNumber)
  problem <- loadProblem problemNumber
  runApp problem
