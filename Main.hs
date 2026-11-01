module Main (main) where

import           Controllers.Home                     (home, login, post)
import           Data.Maybe                           (fromMaybe)
import           Network.Wai.Middleware.RequestLogger (logStdoutDev)
import           Network.Wai.Middleware.Static        (addBase, noDots,
                                                        staticPolicy, (>->))
import           System.Environment                   (lookupEnv)
import           Text.Read                            (readMaybe)
import           Web.Scotty                           (middleware, scotty)

main :: IO ()
main = do
  portEnv <- lookupEnv "PORT"
  let port = fromMaybe 3000 (portEnv >>= readMaybe)
  scotty port $ do
    middleware $ staticPolicy (noDots >-> addBase "static/images") -- for favicon.ico
    middleware logStdoutDev
    home
    login
    post
