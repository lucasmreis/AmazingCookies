module Server

open Suave
open Suave.Filters
open Suave.Operators
open Suave.Successful
open Suave.RequestErrors
open FSharp.Data

open Domain
open EventStore

type Name = string

type ScoutStore = EventStore<Name, ScoutEvent>

let toString x = sprintf "%A" x

let execute (store: ScoutStore) name cmd =
    let state =
        name
        |> store.Get
        |> scoutApplyList HavingFun

    match scoutExecute state cmd with
    | Ok events ->
        store.Save(name, events)
        let newState = scoutApplyList state events
        OK (toString newState)
    | Bad err ->
        UNPROCESSABLE_ENTITY (toString err)

let getBody req =
    req.rawForm |> System.Text.Encoding.UTF8.GetString

type Simple = JsonProvider<""" { "type":"StartDay", "name":"Ana Maria", "quantity":123 } """>

let commandRequest store req =
    let json = req |> getBody |> Simple.Parse
    let command =
        match json.Type with
        | "StartDay" -> Some StartDay
        | "VisitHouse" -> Some VisitHouse
        | "Sell" -> Some (Sell json.Quantity)
        | "HaveFun" -> Some HaveFun
        | _ -> None
    match command with
    | Some cmd -> execute store json.Name cmd
    | None -> BAD_REQUEST ("Command not valid: " + json.Type)

let app store =
    choose [
        POST >=> path "/command/" >=> request(commandRequest store)
        POST >=> path "/query/" >=> request(fun r -> OK (r |> getBody |> store.Get |> (scoutApplyList HavingFun) |> toString))  //(toString (scoutApplyList HavingFun (store.Get(getBody r)))))
        ServerErrors.INTERNAL_ERROR "Sorry, route not valid!" ]


[<EntryPoint>]
let main argv =
    let Store = ScoutStore()

    let cb ev =
        let all = Store.Get()
        printfn "-- EVENT: %A" ev
        printfn "-- ALL: %A" all

    Store.SaveEvent.Add(cb)

    startWebServer defaultConfig (app Store)
    0
