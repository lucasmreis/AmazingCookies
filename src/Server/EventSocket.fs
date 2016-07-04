module EventSocket
    open Suave
    open Suave.WebSocket
    open Suave.Sockets.Control
    open Chiron

    open System.Text

    open Domain
    open EventStore

    let simpleEventJson name eventString =
        Map.ofList
            [ "name", String name
              "event", String eventString ]
            |> Object

    let soldEventJson name quantity =
        Map.ofList
            [ "name", String name
              "event", String "Sold"
              "quantity", Number (decimal quantity) ]
            |> Object

    let eventToJson (ev: string * ScoutEvent) =
        match ev with
        | name, DayStarted -> simpleEventJson name "DayStarted"
        | name, HouseVisited -> simpleEventJson name "HouseVisited"
        | name, Sold n -> soldEventJson name n
        | name, DayFinished -> simpleEventJson name "DayFinished"

    let eventSocket (store: EventStore<string, ScoutEvent>) (webSocket : WebSocket) ctx =
        let cb ev =
            let data =
                ev
                |> eventToJson
                |> Json.format
                |> Encoding.ASCII.GetBytes
            webSocket.send Opcode.Text data true |> Async.Ignore |> Async.Start

        let subscription = store.SaveEvent.Subscribe(cb)

        socket {
            let loop = ref true
            while !loop do
                let! msg = webSocket.read()
                match msg with
                | (Ping, _, _) -> do! webSocket.send Pong [||] true
                | (Close, _, _) ->
                    do! webSocket.send Close [||] true
                    subscription.Dispose()
                    loop := false
                | _ -> ()
            }