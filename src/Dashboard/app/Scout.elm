module Scout exposing (..)

import Json.Decode exposing (Decoder, decodeString, succeed, string, list, int, maybe, (:=))
import Json.Decode.Extra exposing ((|:))


type Event
    = DayStarted
    | HouseVisited
    | Sold Int
    | DayFinished


type alias Model =
    { name : String
    , event : Event
    }


type alias JsonEvent =
    { event : String
    , name : String
    , quantity : Maybe Int
    }


decoder : Decoder JsonEvent
decoder =
    succeed JsonEvent
        |: ("event" := string)
        |: ("name" := string)
        |: (maybe ("quantity" := int))


jsonToEvent : JsonEvent -> Maybe Model
jsonToEvent json =
    let
        { event, name, quantity } =
            json
    in
        case ( event, quantity ) of
            ( "DayStarted", _ ) ->
                Just { name = name, event = DayStarted }

            ( "HouseVisited", _ ) ->
                Just { name = name, event = HouseVisited }

            ( "Sold", Just q ) ->
                Just { name = name, event = Sold q }

            ( "DayFinished", _ ) ->
                Just { name = name, event = DayFinished }

            ( _, _ ) ->
                Nothing


decodeEvent : String -> Maybe Model
decodeEvent str =
    case (decodeString decoder str) of
        Ok event ->
            jsonToEvent event

        _ ->
            Nothing

eventToString : Model -> String
eventToString model =
    model.name ++ ": " ++ (toString model.event)