{-# LANGUAGE OverloadedStrings #-}

module Controllers.Home
    ( homeRoutes
    ) where

import           App.Context                 (AppM, AppRoute)
import qualified App.Database.Queries        as Q
import           Control.Monad.IO.Class      (liftIO)
import           Control.Monad.Trans.Class   (lift)
import           Control.Monad.Trans.Reader  (ask)
import           Data.IORef                  (IORef, atomicModifyIORef',
                                              newIORef)
import           Data.Text                   (Text)
import           Network.HTTP.Types.Status   (status200, status201, status404)
import           System.IO.Unsafe            (unsafePerformIO)
import           Views.Home                  (homeView)
import           Views.Pages.Posts           (counterCard, postCard, postsList)
import           Views.Utils                 (blaze)
import qualified Web.Scotty.Trans            as S

{-# NOINLINE globalCounter #-}
globalCounter :: IORef Int
globalCounter = unsafePerformIO $ newIORef 0

-- | Home and HTMX hypermedia partial routes.
homeRoutes :: AppRoute
homeRoutes = do
  -- Main Homepage with Initial Posts
  S.get "/" $ do
    ctx <- lift ask
    posts <- liftIO $ Q.listPosts ctx
    homeView posts

  -- HTMX: Live Search Partial
  S.get "/partials/posts/search" $ do
    ctx <- lift ask
    mQuery <- S.queryParamMaybe "q" :: S.ActionT AppM (Maybe Text)
    posts <- liftIO $ maybe (Q.listPosts ctx) (Q.searchPosts ctx) mQuery
    blaze $ postsList posts

  -- HTMX: Inline Post Creation Partial
  S.post "/partials/posts" $ do
    ctx <- lift ask
    postTitleText <- S.formParam "title" :: S.ActionT AppM Text
    newPost <- liftIO $ Q.createPost ctx postTitleText
    S.status status201
    blaze $ postCard newPost

  -- HTMX: Inline Post Deletion Partial
  S.delete "/partials/posts/:id" $ do
    ctx <- lift ask
    pid <- S.pathParam "id" :: S.ActionT AppM Int
    deleted <- liftIO $ Q.deletePost ctx pid
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
