{-# LANGUAGE OverloadedStrings #-}

module Controllers.Home
    ( home
    , login
    ) where

import           Control.Monad.IO.Unlift (MonadUnliftIO)
import           Views.Home              (homeView)
import qualified Web.Scotty.Trans        as S

home :: MonadUnliftIO m => S.ScottyT m ()
home = S.get "/" homeView

login :: MonadUnliftIO m => S.ScottyT m ()
login = S.get "/login" $ S.html "login"
