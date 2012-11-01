module Main where

import System (getArgs)
import Assembler (writeAssembledFile)

main :: IO()
main = do
    x <- getArgs
    writeAssembledFile $ head x