module Domain
    type ScoutState =
        | Walking
        | Visiting
        | HavingFun

    type ScoutCommand =
        | StartDay
        | VisitHouse
        | Sell of int
        | HaveFun

    type ScoutEvent =
        | DayStarted
        | HouseVisited
        | Sold of int
        | DayFinished

    type ScoutError =
        | ShouldBeHavingFun
        | ShouldBeWalking
        | ShouldBeVisiting

    type Result =
        | Ok of ScoutEvent list
        | Bad of ScoutError

    let startDay state =
        match state with
        | HavingFun -> Ok [ DayStarted ]
        | _ -> Bad ShouldBeHavingFun

    let visitHouse state =
        match state with
        | Walking -> Ok [ HouseVisited ]
        | _ -> Bad ShouldBeWalking

    let sell quantity state =
        match state with
        | Visiting -> Ok [ Sold quantity ]
        | _ -> Bad ShouldBeVisiting

    let haveFun state =
        match state with
        | Walking -> Ok [ DayFinished ]
        | _ -> Bad ShouldBeWalking

    let scoutExecute state command =
        match command with
        | StartDay -> startDay state
        | VisitHouse -> visitHouse state
        | Sell quantity -> sell quantity state
        | HaveFun -> haveFun state

    let scoutApply state event =
        match event with
        | DayStarted -> Walking
        | HouseVisited -> Visiting
        | Sold _ -> Walking
        | DayFinished -> HavingFun

    let scoutApplyList initialState events =
        List.fold scoutApply initialState events

