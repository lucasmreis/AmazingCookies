module Dashboard exposing (..)

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
    div []
        [ div [ totalCardStyle ] [ totalView model.totalCookies ]
        , div [ horizontalGridStyle ]
            [ div [ scoutsColumnStyle ] (List.map viewScout (Dict.toList model.scouts))
            , div [ logColumnStyle ]
                [ div [ logTitleStyle ] [ text "Log:" ]
                , div [] (List.map viewEvent model.events)
                ]
            ]
        ]


totalView totalCookies =
    div [ horizontalGridStyle ]
        [ div [ totalNumberStyle ] [ text (toString totalCookies) ]
        , div [ totalCaptionStyle ] [ text "Cookies Sold" ]
        ]


viewEvent : Scout.EventModel -> Html Msg
viewEvent event =
    div [ logMessageStyle ] [ text ("> " ++ (Scout.eventToString event)) ]


viewScout scout =
    div [ stateStyle (snd scout) ] [ text (Scout.stateToString (fst scout) (snd scout)) ]


horizontalGridStyle =
    style [ ( "display", "flex" ) ]


totalCardStyle =
    style
        [ ( "font-family", "-apple-system, system, sans-serif" )
        , ( "font-size", "3em" )
        , ( "margin", "20px" )
        ]


logMessageStyle =
    style
        [ ( "font-size", "1em" )
        , ( "color", "rgba(0,0,0,0.5)" )
        , ( "margin", "20px" )
        ]


stateColor : Scout.StateModel -> ( String, String )
stateColor state =
    case state of
        Scout.Walking ->
            ( "background-color", "rgba(39, 174, 96,1.0)" )

        Scout.Visiting ->
            ( "background-color", "rgba(243, 156, 18,1.0)" )

        Scout.HavingFun ->
            ( "background-color", "rgba(189, 195, 199,1.0)" )


stateStyle state =
    style
        [ ( "font-family", "-apple-system, system, sans-serif" )
        , ( "font-size", "1.5em" )
        , ( "margin", "0px 20px 20px" )
        , ( "padding", "20px" )
        , ( "color", "rgba(0,0,0,0.5)" )
        , (stateColor state)
        ]


totalNumberStyle =
    style
        [ ( "padding", "10px 20px" )
        , ( "color", "white" )
        , ( "background-color", "rgba(41, 128, 185,1.0)" )
        ]


totalCaptionStyle =
    style [ ( "padding", "10px" ) ]


scoutsColumnStyle =
    style [ ( "width", "400px" ) ]


logTitleStyle =
    style
        [ ( "font-family", "-apple-system, system, sans-serif" )
        , ( "font-size", "1.5em" )
        , ( "color", "rgba(0,0,0,0.5)" )
        , ( "padding", "20px" )
        ]


logColumnStyle =
    style
        [ ( "width", "400px" )
        , ( "font-family", "-apple-system, system, sans-serif" )
        , ( "background-color", "rgba(0,0,0,0.2)" )
        ]
