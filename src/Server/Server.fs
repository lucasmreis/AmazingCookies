module Server

open Suave
open Suave.Filters
open Suave.Operators
open Suave.WebSocket

open Domain
open EventStore

open CommandApi
open EventSocket

let app store =
    choose [
        path "/websocket" >=> handShake (eventSocket store)
        POST >=> path "/command" >=> request(commandRequest store)
        ServerErrors.INTERNAL_ERROR "Sorry, route not valid!" ]


[<EntryPoint>]
let main argv =
    let Store = EventStore<string, ScoutEvent>()

    let cb ev =
        let all = Store.Get()
        printfn "-- EVENT: %A" ev
        printfn "-- ALL: %A" all

    Store.SaveEvent.Add(cb)

    startWebServer defaultConfig (app Store)
    0
