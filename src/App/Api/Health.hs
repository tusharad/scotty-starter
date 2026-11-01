{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Api.Health
    ( healthRoutes
    , HealthStatus (..)
    , ReadinessStatus (..)
    ) where

import           App.Config                 (Config (..))
import           App.Context                (AppContext (..), AppRoute)
import           App.Database               (pingDb)
import           Control.Monad.IO.Class     (liftIO)
import           Control.Monad.Trans.Class  (lift)
import           Control.Monad.Trans.Reader (ask)
import           Data.Aeson                 (ToJSON (..), object, (.=))
import qualified Data.Aeson.Key             as Key
import           Data.Text                  (Text)
import qualified Data.Text                  as T
import           Data.Time.Clock            (diffUTCTime, getCurrentTime)
import           GHC.Generics               (Generic)
import           Network.HTTP.Types.Status  (status200, status503)
import qualified Web.Scotty.Trans           as S

data HealthStatus = HealthStatus
  { hsStatus    :: !Text
  , hsUptimeSec :: !Double
  , hsEnv       :: !Text
  , hsVersion   :: !Text
  } deriving (Show, Generic)

instance ToJSON HealthStatus where
  toJSON hs = object
    [ "status"     .= hsStatus hs
    , "uptime_sec" .= hsUptimeSec hs
    , "env"        .= hsEnv hs
    , "version"    .= hsVersion hs
    ]

data ReadinessStatus = ReadinessStatus
  { rsStatus :: !Text
  , rsChecks :: ![(Text, Text)]
  } deriving (Show, Generic)

instance ToJSON ReadinessStatus where
  toJSON rs = object
    [ "status" .= rsStatus rs
    , "checks" .= object (map (\(k, v) -> Key.fromText k .= v) (rsChecks rs))
    ]

healthRoutes :: AppRoute
healthRoutes = do
  S.get "/healthz" $ do
    ctx <- lift ask
    now <- liftIO getCurrentTime
    let uptime = realToFrac (diffUTCTime now (ctxStartTime ctx)) :: Double
        envStr = T.pack . show $ cfgEnv (ctxConfig ctx)
    S.status status200
    S.json $ HealthStatus "pass" uptime envStr "0.2.0.0"

  S.get "/readyz" $ do
    ctx <- lift ask
    dbOk <- liftIO $ pingDb (ctxDbPool ctx)
    let checks = [ ("app", "ok")
                 , ("database", if dbOk then "ok" else "error")
                 ]
    if dbOk
      then do
        S.status status200
        S.json $ ReadinessStatus "ready" checks
      else do
        S.status status503
        S.json $ ReadinessStatus "unavailable" checks
