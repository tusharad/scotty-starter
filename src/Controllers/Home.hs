{-# LANGUAGE OverloadedStrings #-}

module Controllers.Home
    ( homeRoutes
    , home
    , login
    ) where

import           App.Api.Posts               (Post (..))
import           App.Context                 (AppContext (..), AppM, AppRoute)
import           App.Database                (runDb)
import           Control.Monad.IO.Class      (liftIO)
import           Control.Monad.IO.Unlift     (MonadUnliftIO)
import           Control.Monad.Trans.Class   (lift)
import           Control.Monad.Trans.Reader  (ask)
import           Data.IORef                  (IORef, atomicModifyIORef',
                                              newIORef)
import           Data.Text                   (Text)
import           Database.SQLite.Simple      (Only (..), changes, execute,
                                              lastInsertRowId, query, query_)
import           Network.HTTP.Types.Status   (status200, status201, status404)
import           System.IO.Unsafe            (unsafePerformIO)
import           Views.Home                  (homeView)
import           Views.Pages.Posts           (counterCard, postCard, postsList)
import           Views.Utils                 (blaze)
import qualified Web.Scotty.Trans            as S

{-# NOINLINE globalCounter #-}
globalCounter :: IORef Int
globalCounter = unsafePerformIO $ newIORef 0

-- | Home and HTMX partial routes.
homeRoutes :: AppRoute
homeRoutes = do
  -- Main Homepage with Initial Posts
  S.get "/" $ do
    ctx <- lift ask
    posts <- liftIO $ runDb (ctxDbPool ctx) $ \conn ->
      query_ conn "SELECT id, title FROM posts ORDER BY id DESC;" :: IO [Post]
    homeView posts

  -- HTMX: Live Search Partial
  S.get "/partials/posts/search" $ do
    ctx <- lift ask
    mQuery <- S.queryParamMaybe "q" :: S.ActionT AppM (Maybe Text)
    posts <- liftIO $ runDb (ctxDbPool ctx) $ \conn -> case mQuery of
      Just q  -> query conn "SELECT id, title FROM posts WHERE title LIKE ? ORDER BY id DESC;" (Only ("%" <> q <> "%"))
      Nothing -> query_ conn "SELECT id, title FROM posts ORDER BY id DESC;"
    blaze $ postsList (posts :: [Post])

  -- HTMX: Inline Post Creation Partial
  S.post "/partials/posts" $ do
    ctx <- lift ask
    postTitleText <- S.formParam "title" :: S.ActionT AppM Text
    newPost <- liftIO $ runDb (ctxDbPool ctx) $ \conn -> do
      execute conn "INSERT INTO posts (title) VALUES (?);" (Only postTitleText)
      rowId <- lastInsertRowId conn
      pure $ Post (fromIntegral rowId) postTitleText
    S.status status201
    blaze $ postCard newPost

  -- HTMX: Inline Post Deletion Partial
  S.delete "/partials/posts/:id" $ do
    ctx <- lift ask
    pid <- S.pathParam "id" :: S.ActionT AppM Int
    deleted <- liftIO $ runDb (ctxDbPool ctx) $ \conn -> do
      execute conn "DELETE FROM posts WHERE id = ?;" (Only pid)
      c <- changes conn
      pure (c > 0)
    if deleted
      then do
        S.status status200
        S.raw ""
      else do
        S.status status404
        S.text "Post not found"

  -- HTMX: Click Counter Partial
  S.post "/partials/counter" $ do
    newCount <- liftIO $ atomicModifyIORef' globalCounter $ \c -> (c + 1, c + 1)
    blaze $ counterCard newCount

  -- Simple Login route
  S.get "/login" $ S.html "login"

-- | Legacy aliases for backward compatibility
home :: AppRoute
home = homeRoutes

login :: MonadUnliftIO m => S.ScottyT m ()
login = S.get "/login" $ S.html "login"
