module App.Context
    ( AppContext (..)
    , AppM
    , AppAction
    , AppRoute
    , initContext
    , runAppM
    ) where

import           App.Config                  (Config (..))
import           App.Database                (DbPool, initDbPool)
import           Control.Monad.Trans.Reader  (ReaderT, runReaderT)
import           Data.Time.Clock             (UTCTime, getCurrentTime)
import           Web.Scotty.Internal.Types   (ActionT, ScottyT)

-- | Global runtime application context.
data AppContext = AppContext
  { ctxConfig    :: !Config
  , ctxStartTime :: !UTCTime
  , ctxDbPool    :: !DbPool
  }

-- | The application monad stack, providing ReaderT AppContext over IO.
type AppM = ReaderT AppContext IO

-- | Scotty action monad operating over AppM.
type AppAction a = ActionT AppM a

-- | Scotty routing monad operating over AppM.
type AppRoute = ScottyT AppM ()

-- | Initialize application context given configuration.
initContext :: Config -> IO AppContext
initContext cfg = do
  now  <- getCurrentTime
  pool <- initDbPool (cfgDatabasePath cfg)
  pure AppContext
    { ctxConfig    = cfg
    , ctxStartTime = now
    , ctxDbPool    = pool
    }

-- | Natural transformation to run AppM actions in IO.
runAppM :: AppContext -> AppM a -> IO a
runAppM = flip runReaderT
