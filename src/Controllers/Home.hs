{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE OverloadedStrings #-}

module Controllers.Home
    ( home
    , login
    , post
    ) where

import           Data.Aeson   (ToJSON)
import           Data.Text    (Text)
import           GHC.Generics (Generic)
import           Views.Home   (homeView)
import           Web.Scotty   (ScottyM, get, html, json)

home :: ScottyM ()
home = get "/" homeView

login :: ScottyM ()
login = get "/login" $ html "login"

{-
  Example data structure to demonstrate JSON serialization
-}
data Post = Post
  { postId    :: Int
  , postTitle :: Text
  } deriving (Show, Generic)

instance ToJSON Post

post :: ScottyM ()
post = get "/post" $ json $ Post 1 "Hello from Scotty 0.30!"
