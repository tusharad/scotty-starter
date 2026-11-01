module Main (main) where

import           App                (runApp)
import           Data.Maybe         (fromMaybe)
import           System.Environment (lookupEnv)
import           Text.Read          (readMaybe)

main :: IO ()
main = do
  portEnv <- lookupEnv "PORT"
  let port = fromMaybe 3000 (portEnv >>= readMaybe)
  runApp port
