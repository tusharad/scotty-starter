module Main (main) where

import qualified AppSpec
import           Test.Hspec

main :: IO ()
main = hspec $ do
  describe "Scotty Starter Application" AppSpec.spec

