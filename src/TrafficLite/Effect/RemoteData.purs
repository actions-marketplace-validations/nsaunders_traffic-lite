module TrafficLite.Effect.RemoteData
  ( class MonadRemoteData
  , fetchClones
  , fetchViews
  ) where

import Prelude

import Affjax.Node (defaultRequest, request)
import Affjax.Node as Affjax
import Affjax.RequestHeader (RequestHeader(..))
import Affjax.ResponseFormat as ResponseFormat
import Affjax.StatusCode (StatusCode(..))
import Control.Monad.Error.Class (class MonadThrow, throwError)
import Control.Monad.Reader.Class (class MonadAsk, ask)
import Data.Argonaut (decodeJson, getField, printJsonDecodeError)
import Data.Argonaut.Decode.Decoders (decodeJObject)
import Data.Array (sortWith, takeEnd)
import Data.Bifoldable (bifold)
import Data.Bifunctor (bimap)
import Data.Either (either)
import Data.MediaType (MediaType(..))
import Effect.Aff.Class (class MonadAff, liftAff)
import TrafficLite.Control.Monad.UpdateM (UpdateM)
import TrafficLite.Data.Error (Error(..))
import TrafficLite.Data.Error as TrafficLite
import TrafficLite.Data.Metric (CountRep, TimestampRep)
import Type.Row (type (+))

class MonadRemoteData (m :: Type -> Type) where
  fetchClones :: m (Array { | TimestampRep + CountRep + () })
  fetchViews :: m (Array { | TimestampRep + CountRep + () })

fetchCounts
  :: forall m r
   . MonadAff m
  => MonadAsk { repo :: String, token :: String | r } m
  => MonadThrow TrafficLite.Error m
  => String
  -> m (Array { | TimestampRep + CountRep + () })
fetchCounts metricType = do

  { token, repo } <- ask

  let

    url = "https://api.github.com/repos/" <> repo <> "/traffic/" <> metricType

    headers =
      [ Accept $ MediaType "application/vnd.github+json"
      , RequestHeader "Authorization" ("Bearer " <> token)
      , RequestHeader "X-GitHub-Api-Version" "2022-11-28"
      ]

    config =
      defaultRequest
        { url = url, headers = headers, responseFormat = ResponseFormat.json }

  { status: StatusCode statusCode, body } <-
    either (throwError <<< FetchError <<< Affjax.printError) pure
      =<< liftAff (request config)

  case statusCode of

    200 ->
      either
        (throwError <<< TypeError <<< printJsonDecodeError)
        (pure <<< takeEnd 13 <<< sortWith _.timestamp)
        (decodeJson =<< flip getField metricType =<< decodeJson body)

    unexpectedStatusCode ->
      let
        msg =
          (decodeJObject body >>= flip getField "message")
            # bimap
                (\_ -> "with no message.")
                (\m -> "with message: " <> m)
            # bifold
      in
        throwError
          $ FetchError
          $ "Unexpected " <> show unexpectedStatusCode <> " response " <> msg

instance MonadRemoteData UpdateM where
  fetchClones = fetchCounts "clones"
  fetchViews = fetchCounts "views"
