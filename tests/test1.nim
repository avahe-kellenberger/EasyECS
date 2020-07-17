# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import EasyECS

test "can add":
  type Location = object
    x, y: int

  let registry = newRegistry()
  let e: Entity = registry.createEntity()
  let loc = Location(x: 7, y: 13)
  registry.addComponent(e, loc)

