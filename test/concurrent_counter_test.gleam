import concurrent_counter
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn counter_test() {
  let counter = concurrent_counter.new()

  concurrent_counter.value(counter)
  |> should.equal(0)

  concurrent_counter.increment(counter)

  concurrent_counter.value(counter)
  |> should.equal(1)

  concurrent_counter.increment(counter)

  concurrent_counter.value(counter)
  |> should.equal(2)

  concurrent_counter.decrement(counter)
  concurrent_counter.decrement(counter)

  concurrent_counter.value(counter)
  |> should.equal(0)
}
