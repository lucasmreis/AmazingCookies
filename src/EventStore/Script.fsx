// Learn more about F# at http://fsharp.net. See the 'F# Tutorial' project
// for more guidance on F# programming.

#load "EventStore.fs"
open EventStore

// Define your library scripting code here
let store = EventStore<string, string>()

store.SaveEvent.Add(fun x -> printfn "-- EVENT: %A" x)

store.Save("a", ["aaa"])
store.Save("a", ["bbb"])
store.Save("a", ["ccc"])
store.Save("b", ["aaa"])
store.Save("b", ["bbb"])
store.Save("b", ["ccc1"; "ccc2"; "ccc3"])

store.Get()

store.Get("a")
store.Get("c")
