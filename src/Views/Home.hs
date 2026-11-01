{-# LANGUAGE OverloadedStrings #-}

module Views.Home (homeView) where

import           Client.CSS                  (layoutCss)
import           Control.Monad.IO.Class      (MonadIO)
import           Data.Text.Lazy              (toStrict)
import           Prelude                     hiding (div, head, id)
import           Text.Blaze.Html             (Html)
import           Text.Blaze.Html5            (a, body, button,
                                              dataAttribute, div, docTypeHtml,
                                              h1, head, li, link, meta, p,
                                              script, style, title, ul, (!))
import           Text.Blaze.Html5.Attributes (charset, class_, content, href,
                                              httpEquiv, id, media, name, rel,
                                              src, type_)
import           Views.Utils                 (blaze, pet)
import qualified Web.Scotty.Trans            as S

layout :: Html -> Html -> Html
layout t b = docTypeHtml $ do
  head $ do
    title t
    meta ! charset "utf-8"
    meta ! httpEquiv "X-UA-Compatible" ! content "IE=edge"
    meta ! name "viewport" ! content "width=device-width, initial-scale=1"
    meta ! name "description" ! content "Scotty Starter Application"
    link ! href "//netdna.bootstrapcdn.com/bootstrap/3.0.0/css/bootstrap.min.css" ! rel "stylesheet" ! media "screen"
    style $ pet $ toStrict layoutCss
  body $ do
    navBar >> b
    script ! src "//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js" $ mempty
    script ! src "//netdna.bootstrapcdn.com/bootstrap/3.0.0/js/bootstrap.min.js" $ mempty

homeView :: MonadIO m => S.ActionT m ()
homeView = blaze $ layout "Scotty Starter" $ do
  div ! class_ "container" $ do
    div ! class_ "jumbotron" $ do
      h1 "Scotty Starter"
      p "Welcome to the Scotty Starter template, powered by Scotty and modern GHC."
      p $ do
        a ! class_ "btn btn-lg btn-primary" ! id "fb" ! href "/healthz" $ "Health Check"
        a ! class_ "btn btn-lg btn-danger" ! id "gmail" ! href "/api/posts" $ "API Posts"

navBar :: Html
navBar = div ! class_ "navbar navbar-default navbar-static-top" $ div ! class_ "container" $ do
  div ! class_ "navbar-header" $ do
    button ! type_ "button"
           ! class_ "navbar-toggle" ! dataAttribute "toggle" "collapse" ! dataAttribute "target" ".navbar-collapse" $ do
      a ! class_ "navbar-brand" ! href "#" $ "λ"
  div ! class_ "navbar-collapse collapse" $ ul ! class_ "nav navbar-nav" $ do
    li ! class_ "active" $ a ! href "/" $ "Home"
    li $ a ! href "/api/posts" $ "Posts API"
    li $ a ! href "/healthz" $ "Health"
    li $ a ! href "/login" $ "Login"
