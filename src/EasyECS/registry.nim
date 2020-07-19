import variant
import
  macros,
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

proc numEntitiesCreated*(this: Registry): uint64 =
  ## The number of entities that have been created.
  this.entitiesCreated

proc numEntitiesExisting*(this: Registry): int =
  ## The number of existing entities in the registry.
  this.entities.len

proc registerNewEntity*(this: Registry): Entity =
  result = Entity(this.entitiesCreated)
  inc this.entitiesCreated
  this.entities.add(result)

proc getComponents(this: Registry, C: typedesc): seq[C] =
  const typeId = getTypeId(C)
  let components = cast[type(result)](this.componentsTable.getOrDefault(typeId))
  return components

proc addComponent*[C](this: Registry, entity: Entity, component: C) =
  var components = this.getComponents(C)
  components.add(component)

proc getCallbackArgTypes(callback: NimNode): seq[NimNode] =
  for node in callback.getImpl():
    if node.kind == nnkLambda:
      for param in node.params:
        if param.kind == nnkIdentDefs:
          for ident in param:
            if ident.kind == nnkSym:
              result.add(ident)

macro transformTypesToTypeIds(callback: proc): untyped =
  let cbTypes = getCallbackArgTypes(callback)
  # here you can do stuff with this seq of "types" at CT
  # in principle you can do this now
  var tIds = ident"typIds"
  var varSec = quote do:
    var `tIds` = newSeq[TypeId]()
  result = newStmtList(varSec)
  for x in cbTypes:
    result.add nnkCall.newTree(
      ident"add", tIds,
      nnkCall.newTree(
        ident"getTypeId",
        ident(x.strVal)) # getTypeId needs an ident it seems
    )
  echo result.repr

template processCallback(this: Registry, callback: proc) =
  let types = getCallbackArgTypes(callback)  
  for callbackType in types:
    let typeId = callbackType.getTypeId()
    echo(typeId)
    let components = this.componentsTable[typeId]

when isMainModule:
  let testRegistry: Registry = newRegistry()
  let testEntity: Entity = testRegistry.registerNewEntity()

  type
    Foo = object
      x: int
    Bar = object
      s: string

  testRegistry.addComponent(testEntity, Foo(x: 1))
  testRegistry.addComponent(testEntity, Bar(s: "test"))

  # The componentsTable now has entries for Foo and Bar

  let callback: proc =
    proc(foo: Foo, bar: Bar) =
      echo(foo.x, bar.s)

  testRegistry.processCallback(callback)

