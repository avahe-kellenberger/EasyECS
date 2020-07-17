import variant
import
  entity,
  tables

export entity

type
  Registry* = ref object
    entitiesCreated: uint64
    entities: seq[Entity]
    componentsTable: Table[TypeId, seq[RootObj]]

proc newRegistry*(): Registry =
  result.new()
  result.entitiesCreated = 0
  result.componentsTable = initTable[TypeId, seq[RootObj]]()

proc createEntity*(this: Registry): Entity =
  result = Entity(this.entitiesCreated)
  inc this.entitiesCreated

proc getComponents(this: Registry, C: typedesc): seq[C] =
  const typeId = getTypeId(C)
  let components = cast[type(result)](this.componentsTable.getOrDefault(typeId))
  return components

proc addComponent*[C](this: Registry, entity: Entity, component: C) =
  var components = this.getComponents(C)
  components.add(component)

