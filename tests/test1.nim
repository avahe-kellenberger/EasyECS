import unittest
import EasyECS

# Example of a component
type Location = object
  x, y: int

suite "Registry":
  var registry: Registry

  setup:
    registry = newRegistry()

  test "can create components":
    discard registry.registerNewEntity()
    check(registry.numEntitiesCreated == 1)
    check(registry.numEntitiesExisting == 1)

