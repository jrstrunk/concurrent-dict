import gleam/erlang

pub type ConcurrentCounter {
  ConcurrentCounter(reference: erlang.Reference)
}

pub fn new() {
  new_ffi(1, [])
  |> ConcurrentCounter
}

@external(erlang, "counters", "new")
fn new_ffi(num_counters: Int, options: List(a)) -> erlang.Reference

pub fn increment(counter: ConcurrentCounter) -> Nil {
  increment_ffi(counter.reference, 1, 1)
}

@external(erlang, "counters", "add")
fn increment_ffi(counter: erlang.Reference, index: Int, amount: Int) -> Nil

pub fn decrement(counter: ConcurrentCounter) -> Nil {
  decrement_ffi(counter.reference, 1, 1)
}

@external(erlang, "counters", "sub")
fn decrement_ffi(counter: erlang.Reference, index: Int, amount: Int) -> Nil

pub fn value(of counter: ConcurrentCounter) -> Int {
  value_ffi(counter.reference, 1)
}

@external(erlang, "counters", "get")
fn value_ffi(counter: erlang.Reference, index: Int) -> Int
