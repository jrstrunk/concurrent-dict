import gleam/erlang

pub fn new() {
  new_ffi(1, [])
}

@external(erlang, "counters", "new")
fn new_ffi(num_counters: Int, options: List(a)) -> erlang.Reference

pub fn increment(counter: erlang.Reference) -> Nil {
  increment_ffi(counter, 1, 1)
}

@external(erlang, "counters", "add")
fn increment_ffi(counter: erlang.Reference, index: Int, amount: Int) -> Nil

pub fn decrement(counter: erlang.Reference) -> Nil {
  decrement_ffi(counter, 1, 1)
}

@external(erlang, "counters", "sub")
fn decrement_ffi(counter: erlang.Reference, index: Int, amount: Int) -> Nil

pub fn value(of counter: erlang.Reference) -> Int {
  value_ffi(counter, 1)
}

@external(erlang, "counters", "get")
fn value_ffi(counter: erlang.Reference, index: Int) -> Int
