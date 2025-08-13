import gleam/erlang/reference

pub type ConcurrentCounter {
  ConcurrentCounter(reference: reference.Reference)
}

pub fn new() {
  new_ffi(1, [])
  |> ConcurrentCounter
}

@external(erlang, "counters", "new")
fn new_ffi(num_counters: Int, options: List(a)) -> reference.Reference

pub fn increment(counter: ConcurrentCounter) -> Nil {
  increment_ffi(counter.reference, 1, 1)
}

@external(erlang, "counters", "add")
fn increment_ffi(counter: reference.Reference, index: Int, amount: Int) -> Nil

pub fn decrement(counter: ConcurrentCounter) -> Nil {
  decrement_ffi(counter.reference, 1, 1)
}

@external(erlang, "counters", "sub")
fn decrement_ffi(counter: reference.Reference, index: Int, amount: Int) -> Nil

pub fn value(of counter: ConcurrentCounter) -> Int {
  value_ffi(counter.reference, 1)
}

@external(erlang, "counters", "get")
fn value_ffi(counter: reference.Reference, index: Int) -> Int

pub fn reset(counter: ConcurrentCounter) -> Nil {
  reset_ffi(counter.reference, 1, 0)
}

@external(erlang, "counters", "put")
fn reset_ffi(counter: reference.Reference, index: Int, value: Int) -> Nil
