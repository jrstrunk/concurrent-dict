import gleam/erlang
import gleam/erlang/atom
import gleam/int
import gleam/list
import tempo/instant

pub opaque type ConcurrentDict(key, val) {
  ConcurrentDict(reference: erlang.Reference, name: atom.Atom)
}

/// Creates a new, unique concurrent dictionary. Under the hood, this creates
/// a new ETS table with a unique name.
pub fn new() -> ConcurrentDict(key, val) {
  let name =
    { "concurrentdict" <> instant.now() |> instant.to_unique_int |> int.to_string }
    |> atom.create_from_string

  create_ffi(name)
  |> ConcurrentDict(name)
}

/// Deletes all values in the dictionary.
pub fn delete_all(dict: ConcurrentDict(key, val)) -> Nil {
  delete_all_ffi(dict.reference)
  Nil
}

@external(erlang, "ets", "delete_all_objects")
fn delete_all_ffi(reference: erlang.Reference) -> Nil

/// Drops a concurrent dictionary, removing it from memory and invalidating all
/// references to it. Operations on a dropped dictionary will crash.
pub fn drop(dict: ConcurrentDict(key, val)) -> Nil {
  drop_ffi(dict.reference)
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

pub fn insert(dict: ConcurrentDict(key, val), key: key, val: val) -> Nil {
  let assert True = insert_ffi(dict.reference, [#(key, val)])

  Nil
}

@external(erlang, "ets", "insert")
fn insert_ffi(dict: erlang.Reference, rows: List(#(key, val))) -> Bool

pub fn get(
  from dict: ConcurrentDict(key, val),
  key key: key,
) -> Result(val, Nil) {
  ffi_lookup_set(dict.reference, key)
}

@external(erlang, "concurrent_dict_ffi", "lookup")
fn ffi_lookup_set(dict: erlang.Reference, key: key) -> val

pub fn to_list(dict: ConcurrentDict(key, val)) -> List(#(key, val)) {
  select_ffi(dict.reference, [
    #(#(atom.create_from_string("_"), atom.create_from_string("_")), [], [
      atom.create_from_string("$_"),
    ]),
  ])
}

@external(erlang, "ets", "select")
fn select_ffi(dict: erlang.Reference, queries: List(a)) -> List(b)
