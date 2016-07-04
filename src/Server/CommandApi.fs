module CommandApi
    open Suave
    open Suave.Successful
    open Suave.RequestErrors
    open System.Text
    open FSharp.Data
    open Chiron

    open Domain
    open EventStore

    let toString x = sprintf "%A" x

    let stateJson state =
        Map.ofList
            [ "state", String (toString state) ]
            |> Object
            |> Json.format

    let errorJson error =
        Map.ofList
            [ "message", String (toString error) ]
            |> Object
            |> Json.format

    let execute (store: EventStore<string, ScoutEvent>) name cmd =
        let state =
            name
            |> store.Get
            |> scoutApplyList HavingFun

        match scoutExecute state cmd with
        | Ok events ->
            store.Save(name, events)
            let newState = scoutApplyList state events
            OK (stateJson newState)
        | Bad err ->
            UNPROCESSABLE_ENTITY (errorJson err)

    let getBody req =
        req.rawForm |> Encoding.UTF8.GetString

    type CommandJSON = JsonProvider<""" { "type": "StartDay", "name": "Ana Maria", "quantity": 123 } """>

    let commandRequest store req =
        let json = req |> getBody |> CommandJSON.Parse
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