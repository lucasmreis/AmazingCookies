namespace EventStore

type EventStore<'Key, 'Event when 'Key : comparison>() =
    let eventList =
        new ResizeArray<'Key * 'Event>()

    let saveEvent =
        new Event<'Key * 'Event>()

    member this.SaveEvent =
        saveEvent.Publish

    member this.Save(name, event) =
        eventList.Add(name, event)
        saveEvent.Trigger((name, event))

    member this.Get() =
        eventList

    member this.Get(name) =
        query {
            for (n, ev) in eventList do
            where (n = name)
            select ev
        } |> Seq.toList
