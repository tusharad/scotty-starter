module App.Database
    ( DbPool
    , initDbPool
    , runDb
    , pingDb
    ) where

import           App.Database.Migrations (runMigrations)
import           Data.Pool                (Pool, defaultPoolConfig, newPool,
                                           withResource)
import           Database.SQLite.Simple   (Connection, Only (..), close, open,
                                           query_)

-- | Connection pool for SQLite.
type DbPool = Pool Connection

-- | Initialize database pool and run pending migrations.
initDbPool :: FilePath -> IO DbPool
initDbPool dbPath = do
  let path = if dbPath == ":memory:"
               then "file:memdb?mode=memory&cache=shared"
               else dbPath
      poolCfg = defaultPoolConfig (open path) close 60 10
  pool <- newPool poolCfg
  withResource pool runMigrations
  pure pool

-- | Execute an action with a database connection from the pool.
runDb :: DbPool -> (Connection -> IO a) -> IO a
runDb = withResource

-- | Health check probe verifying database connectivity.
pingDb :: DbPool -> IO Bool
pingDb pool = withResource pool $ \conn -> do
  res <- query_ conn "SELECT 1;" :: IO [Only Int]
  pure (res == [Only 1])

