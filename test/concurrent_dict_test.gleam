import concurrent_dict
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn insert_get_test() {
  let tab = concurrent_dict.new()

  concurrent_dict.insert(tab, 1, "hello")

  concurrent_dict.get(tab, 1)
  |> should.equal(Ok("hello"))

  concurrent_dict.get(tab, 2)
  |> should.equal(Error(Nil))

  concurrent_dict.insert(tab, 1, "world")

  concurrent_dict.get(tab, 1)
  |> should.equal(Ok("world"))

  concurrent_dict.to_list(tab)
  |> should.equal([#(1, "world")])
}
