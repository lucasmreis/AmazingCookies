module Main exposing (..)

import Dict
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (style)
import WebSocket
import Scout


main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


scoutEventsServer : String
scoutEventsServer =
    "ws://localhost:8083/websocket"



-- MODEL


type alias Model =
    { totalCookies : Int
    , scouts : Dict.Dict String Scout.StateModel
    , events : List Scout.EventModel
    }


init : ( Model, Cmd Msg )
init =
    ( Model 0 Dict.empty [], Cmd.none )



-- UPDATE


type Msg
    = EventReceived String


maybeUpdateCookies : Maybe Scout.EventModel -> Model -> Model
maybeUpdateCookies maybeEvent model =
    case maybeEvent of
        Just ev ->
            case ev.event of
                Scout.Sold n ->
                    { model
                        | totalCookies = model.totalCookies + n
                        , events = ev :: model.events
                    }

                _ ->
                    { model | events = ev :: model.events }

        Nothing ->
            model


updateScouts : Maybe Scout.EventModel -> Model -> Model
updateScouts maybeEvent model =
    case maybeEvent of
        Just ev ->
            { model | scouts = Dict.insert ev.name (Scout.stateAfter ev.event) model.scouts }

        Nothing ->
            model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EventReceived eventString ->
            let
                maybeEvent =
                    Scout.decodeEvent eventString

                newModel =
                    model
                        |> maybeUpdateCookies maybeEvent
                        |> updateScouts maybeEvent
            in
                ( newModel, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    WebSocket.listen scoutEventsServer EventReceived



-- VIEW


view : Model -> Html Msg
view model =
    div [ gridStyle ]
        [ div []
            [ div [ totalCardStyle ] [ text ("Cookies sold: " ++ (toString model.totalCookies)) ]
            , div [] (List.map viewScout (Dict.toList model.scouts))
            ]
        , div [] (List.map viewEvent model.events)
        ]


viewEvent : Scout.EventModel -> Html Msg
viewEvent event =
    div [ logMessageStyle ] [ text (Scout.eventToString event) ]


viewScout scout =
    div [ stateStyle ] [ text (Scout.stateToString (fst scout) (snd scout)) ]


gridStyle =
    style [ ( "display", "flex" ) ]


totalCardStyle =
    style
        [ ( "font-family", "-apple-system, system, sans-serif" )
        , ( "font-size", "2em" )
        , ( "margin", "20px" )
        , ( "width", "400px" )
        ]


logMessageStyle =
    style
        [ ( "font-family", "-apple-system, system, sans-serif" )
        , ( "font-size", "1em" )
        , ( "color", "rgba(0,0,0,0.5)" )
        , ( "margin", "20px" )
        ]


stateStyle =
    style
        [ ( "font-family", "-apple-system, system, sans-serif" )
        , ( "font-size", "1.5em" )
        , ( "color", "rgba(0,0,0,0.5)" )
        , ( "margin", "20px" )
        ]
