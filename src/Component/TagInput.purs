-- | Conduit has little functionality to warrant encapsulated state, but the tag input is one.
-- | This component manages a text input that supports key events to manage a list of tags on
-- | an article.
module Conduit.Component.TagInput where

import Prelude

import Conduit.Component.HTML.Utils (css)
import Data.Const (Const)
import Data.Maybe (Maybe(..))
import Data.Newtype (class Newtype, unwrap)
import Data.Set (Set)
import Data.Set as Set
import Effect.Class (class MonadEffect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Web.Event.Event (preventDefault)
import Web.UIEvent.KeyboardEvent (KeyboardEvent, code, toEvent)

data Action
  = HandleInput String
  | HandleKey KeyboardEvent
  | RemoveTag Tag

type State =
  { text :: String
  , tags :: Set Tag
  }

newtype Tag = Tag String

derive instance newtypeTag :: Newtype Tag _
derive instance eqTag :: Eq Tag
derive instance ordTag :: Ord Tag

data Message
  = TagAdded Tag (Set Tag)
  | TagRemoved Tag (Set Tag)

type Input = Set Tag

component :: forall m. MonadEffect m => H.Component HH.HTML (Const Void) Input Message m
component = H.mkComponent
  { initialState: \tags -> { tags: tags, text: "" }
  , render
  , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
  }
  where
  handleAction :: Action -> H.HalogenM State Action () Message m Unit
  handleAction = case _ of
    HandleInput str ->
      H.modify_ _ { text = str }

    HandleKey ev -> case code ev of
      "Enter" -> do
        H.liftEffect $ preventDefault (toEvent ev)
        st <- H.get
        when (st.text /= "") do
          newState <- H.modify _ { tags = Set.insert (Tag st.text) st.tags, text = "" }
          H.raise $ TagAdded (Tag st.text) newState.tags
      _ -> pure unit

    RemoveTag tag -> do
      st <- H.modify \s -> s { tags = Set.delete tag s.tags }
      H.raise $ TagRemoved tag st.tags

  render :: State -> H.ComponentHTML Action () m
  render { text, tags } =
    HH.fieldset
      [ css "form-group" ]
      [ HH.input
          [ css "form-control"
          , HP.type_ HP.InputText
          , HP.placeholder "Enter tags"
          , HP.value text
          , HE.onValueInput $ Just <<< HandleInput
          , HE.onKeyDown $ Just <<< HandleKey
          ]
      , HH.div
          [ css "tag-list" ]
          (map renderTag (Set.toUnfoldable tags))
      ]
    where
    renderTag tag =
      HH.span
        [ css "tag-default tag-pill" ]
        [ HH.i
          [ css "ion-close-round"
          , HE.onClick \_ -> Just $ RemoveTag tag
          ]
          [ ]
        , HH.text (unwrap tag)
        ]
