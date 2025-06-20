import gleam/erlang
import gleam/erlang/atom
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/otp/actor
import gleam/result
import tempo/instant

pub opaque type ConcurrentDict(key, val) {
  ConcurrentDict(
    ets_table: erlang.Reference,
    name: atom.Atom,
    // If the subscriber actor fails to start, we still want to continue with
    // just the ETS table because that is the core functionality. When users
    // subscribe to the dictionary, they will get an error there if the actor
    // fails to start.
    subscriber_actor: Result(process.Subject(Message), actor.StartError),
  )
}

/// Creates a new, unique concurrent dictionary. Under the hood, this creates
/// a new ETS table with a unique name.
pub fn new() -> ConcurrentDict(key, val) {
  let name =
    {
      "concurrentdict"
      <> instant.now() |> instant.to_unique_int |> int.to_string
    }
    |> atom.create_from_string

  let subscriber_actor = actor.start([], handle_message)

  create_ffi(name)
  |> ConcurrentDict(name:, subscriber_actor:)
}

/// Deletes all values in the dictionary.
pub fn delete_all(dict: ConcurrentDict(key, val)) -> Nil {
  delete_all_ffi(dict.ets_table)

  case dict.subscriber_actor {
    Ok(subscriber_actor) -> process.send(subscriber_actor, UpdateSubscribers)
    Error(..) -> Nil
  }

  Nil
}

@external(erlang, "ets", "delete_all_objects")
fn delete_all_ffi(reference: erlang.Reference) -> Nil

/// Drops a concurrent dictionary, removing it from memory and invalidating all
/// references to it. Operations on a dropped dictionary will crash.
pub fn drop(dict: ConcurrentDict(key, val)) -> Nil {
  drop_ffi(dict.ets_table)

  case dict.subscriber_actor {
    Ok(subscriber_actor) -> process.send(subscriber_actor, Shutdown)
    Error(..) -> Nil
  }

  Nil
}

@external(erlang, "ets", "delete")
fn drop_ffi(reference: erlang.Reference) -> Nil

pub fn from_list(list: List(#(key, val))) -> ConcurrentDict(key, val) {
  let cd = new()

  list.each(list, fn(item) { insert(cd, item.0, item.1) })

  cd
}

@external(erlang, "concurrent_dict_ffi", "create_table")
fn create_ffi(name: atom.Atom) -> erlang.Reference

/// Inserts a key-value pair into the dictionary, then updates all subscribers.
/// If you need to insert multiple key-value pairs, use `insert_many` function
/// to only update the subscribers once after all insertions are complete.
pub fn insert(dict: ConcurrentDict(key, val), key: key, val: val) -> Nil {
  let assert True = insert_ffi(dict.ets_table, [#(key, val)])
  update_subscribers(dict)
}

/// Inserts multiple key-value pairs into the dictionary, then updates all
/// subscribers.
pub fn insert_many(dict: ConcurrentDict(key, val), rows: List(#(key, val))) {
  list.each(rows, fn(row) { insert(dict, row.0, row.1) })
  update_subscribers(dict)
}

fn update_subscribers(dict: ConcurrentDict(key, val)) {
  case dict.subscriber_actor {
    Ok(subscriber_actor) -> process.send(subscriber_actor, UpdateSubscribers)
    Error(..) -> Nil
  }
}

@external(erlang, "ets", "insert")
fn insert_ffi(dict: erlang.Reference, rows: List(#(key, val))) -> Bool

pub fn get(
  from dict: ConcurrentDict(key, val),
  key key: key,
) -> Result(val, Nil) {
  ffi_lookup_set(dict.ets_table, key)
}

@external(erlang, "concurrent_dict_ffi", "lookup")
fn ffi_lookup_set(dict: erlang.Reference, key: key) -> val

pub fn to_list(dict: ConcurrentDict(key, val)) -> List(#(key, val)) {
  select_ffi(dict.ets_table, [
    #(#(atom.create_from_string("_"), atom.create_from_string("_")), [], [
      atom.create_from_string("$_"),
    ]),
  ])
}

@external(erlang, "ets", "select")
fn select_ffi(dict: erlang.Reference, queries: List(a)) -> List(b)

pub type SubscribeError(a) {
  StartError(actor.StartError)
  CallError(process.CallError(a))
}

pub fn subscribe(to dict: ConcurrentDict(key, val), with effect: fn() -> Nil) {
  case dict.subscriber_actor {
    Ok(subscriber_actor) -> {
      process.try_call(
        subscriber_actor,
        AddSubscriber(effect, reply: _),
        10_000,
      )
      |> result.map_error(CallError)
    }
    Error(error) -> Error(StartError(error))
  }
}

// Subject Actor ---------------------------------------------------------------

type Message {
  AddSubscriber(effect: fn() -> Nil, reply: process.Subject(Nil))
  UpdateSubscribers
  Shutdown
}

type State =
  List(fn() -> Nil)

fn handle_message(message: Message, state: State) {
  case message {
    AddSubscriber(effect, reply) -> {
      let new_state = [effect, ..state]
      process.send(reply, Nil)
      actor.continue(new_state)
    }
    UpdateSubscribers -> {
      list.each(state, fn(effect) { effect() })
      actor.continue(state)
    }
    Shutdown -> actor.Stop(process.Normal)
  }
}
