{-# LANGUAGE OverloadedStrings #-}

module App
    ( app
    , scottyApp'
    , runApp
    ) where

import           Controllers.Home                     (home, login, post)
import           Network.Wai                          (Application)
import           Network.Wai.Middleware.RequestLogger (logStdoutDev)
import           Network.Wai.Middleware.Static        (addBase, noDots,
                                                        staticPolicy, (>->))
import           Web.Scotty                           (ScottyM, middleware,
                                                        scotty, scottyApp)

-- | The core Scotty application specification (middleware + routes).
app :: ScottyM ()
app = do
  middleware $ staticPolicy (noDots >-> addBase "static/images")
  middleware logStdoutDev
  home
  login
  post

-- | Convert the Scotty application into a WAI Application (for tests and embedding).
scottyApp' :: IO Application
scottyApp' = scottyApp app

-- | Run the application on a given port.
runApp :: Int -> IO ()
runApp port = scotty port app

