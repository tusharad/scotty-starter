{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module App.Api.Posts
    ( Post (..)
    , CreatePostRequest (..)
    , postsRoutes
    ) where

import           App.Context               (AppM, AppRoute)
import           Control.Monad.IO.Class    (liftIO)
import           Data.Aeson                (FromJSON, ToJSON)
import           Data.IORef                (IORef, atomicModifyIORef', newIORef,
                                            readIORef)
import           Data.Text                 (Text)
import qualified Data.Text                 as T
import           GHC.Generics              (Generic)
import           Network.HTTP.Types.Status (status200, status201, status404)
import           System.IO.Unsafe          (unsafePerformIO)
import qualified Web.Scotty.Trans          as S

data Post = Post
  { postId    :: !Int
  , postTitle :: !Text
  } deriving (Show, Eq, Generic)

instance ToJSON Post
instance FromJSON Post

data CreatePostRequest = CreatePostRequest
  { title :: !Text
  } deriving (Show, Eq, Generic)

instance ToJSON CreatePostRequest
instance FromJSON CreatePostRequest

-- | In-memory initial sample store for posts
{-# NOINLINE postsStore #-}
postsStore :: IORef [Post]
postsStore = unsafePerformIO $ newIORef
  [ Post 1 "Getting Started with Scotty 0.30"
  , Post 2 "Haskell in Production: Warp & WAI"
  , Post 3 "Type-Safe Routing and Middleware"
  ]

postsRoutes :: AppRoute
postsRoutes = do
  -- Legacy backwards-compatible single post route
  S.get "/post" $ do
    allPosts <- liftIO $ readIORef postsStore
    case allPosts of
      (p:_) -> S.json p
      []    -> do
        S.status status404
        S.json ("No posts found" :: Text)

  -- GET /api/posts?q=query
  S.get "/api/posts" $ do
    mQuery <- S.queryParamMaybe "q"
    allPosts <- liftIO $ readIORef postsStore
    let filtered = case mQuery of
          Nothing -> allPosts
          Just q  -> filter (\p -> T.toLower q `T.isInfixOf` T.toLower (postTitle p)) allPosts
    S.status status200
    S.json filtered

  -- GET /api/posts/:id (Modern pathParam)
  S.get "/api/posts/:id" $ do
    pid <- S.pathParam "id" :: S.ActionT AppM Int
    allPosts <- liftIO $ readIORef postsStore
    case filter (\p -> postId p == pid) allPosts of
      (p:_) -> do
        S.status status200
        S.json p
      []    -> do
        S.status status404
        S.json ("Post not found" :: Text)

  -- POST /api/posts (Modern JSON body parsing)
  S.post "/api/posts" $ do
    req <- S.jsonData
    newPost <- liftIO $ atomicModifyIORef' postsStore $ \posts ->
      let nextId = 1 + foldr (max . postId) 0 posts
          created = Post nextId (title req)
      in (posts ++ [created], created)
    S.status status201
    S.json newPost

