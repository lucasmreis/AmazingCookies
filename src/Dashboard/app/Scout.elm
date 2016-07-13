module Scout exposing (..)

import Json.Decode exposing (Decoder, decodeString, succeed, string, list, int, maybe, (:=))
import Json.Decode.Extra exposing ((|:))


-- EVENT


type Event
    = DayStarted
    | HouseVisited
    | Sold Int
    | DayFinished


type alias EventModel =
    { name : String
    , event : Event
    }


type alias EventJson =
    { event : String
    , name : String
    , quantity : Maybe Int
    }


decoder : Decoder EventJson
decoder =
    succeed EventJson
        |: ("event" := string)
        |: ("name" := string)
        |: (maybe ("quantity" := int))


jsonToEvent : EventJson -> Maybe EventModel
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


decodeEvent : String -> Maybe EventModel
decodeEvent str =
    case (decodeString decoder str) of
        Ok event ->
            jsonToEvent event

        _ ->
            Nothing


eventToString : EventModel -> String
eventToString model =
    case model.event of
        DayStarted ->
            model.name ++ " just started the day."

        HouseVisited ->
            model.name ++ " visited a house."

        Sold n ->
            model.name ++ " just sold " ++ (toString n) ++ " cookies!"

        DayFinished ->
            model.name ++ " is going to have some fun now!"



-- STATE


type StateModel
    = Walking
    | Visiting
    | HavingFun


stateAfter : Event -> StateModel
stateAfter event =
    case event of
        DayStarted ->
            Walking

        HouseVisited ->
            Visiting

        Sold _ ->
            Walking

        DayFinished ->
            HavingFun


stateToString : String -> StateModel -> String
stateToString name state =
    case state of
        Walking ->
            name ++ " is walking"

        Visiting ->
            name ++ " is visiting a house"

        HavingFun ->
            name ++ " is having fun"
