import variant
import
  macros,
  entity,
  tables,
  component_collection

export entity

type
  Registry* = ref object
    entitiesCreated: uint64
    entities: seq[Entity]
    componentsTable: Table[TypeId, AbstractComponentCollection]

proc newRegistry*(): Registry =
  result.new()
  result.entitiesCreated = 0
  result.componentsTable = initTable[TypeId, AbstractComponentCollection]()

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

proc getComponents*(this: Registry, C: typedesc): ComponentCollection[C] =
  const typeId = getTypeId(C)
  let components = cast[type(result)](this.componentsTable.getOrDefault(typeId))
  return components

proc addComponent*[C](this: Registry, entity: Entity, component: C) =
  # var components = this.getComponents(C)
  const typeId: TypeId = getTypeId(C)
  var components = cast[ComponentCollection[C]](this.componentsTable.getOrDefault(typeId))
  if components.isNil:
    components = newComponentCollection[C]()
    this.componentsTable[typeId] = components
  components.add(entity, component)

proc getCallbackArgTypes(callback: NimNode): seq[NimNode] =
  for node in callback.getImpl():
    if node.kind == nnkLambda:
      for param in node.params:
        if param.kind == nnkIdentDefs:
          for ident in param:
            if ident.kind == nnkSym:
              result.add(ident)

macro transformTypesToTypeIds(callback: proc): untyped =
  let callbackTypes = getCallbackArgTypes(callback)
  # here you can do stuff with this seq of "types" at CT
  # in principle you can do this now
  let typeIds = ident("typeIds")
  var varSec = quote do:
    var `typeIds` = newSeq[TypeId]()
  result = newStmtList(varSec)
  for x in callbackTypes:
    result.add nnkCall.newTree(
      ident("add"), typeIds,
      nnkCall.newTree(
        ident("getTypeId"),
        ident(x.strVal)) # getTypeId needs an ident it seems
    )

# macro invokeWithArgs(callback: proc, collections: seq[AbstractComponentCollection], index: static int) =
#   var res = newStmtList()
#   var call = nnkCall.newTree()
#   for collection in collections:
#     call.add newIdentNode("callback")
#     call.add nnkBracketExpr.newTree(
#       newIdentNode("collection"),
#       newIdentNode("index")
#     )
#   res.add call
#   echo res.repr

macro invokeWithArgs[T](callback: typed, params: openArray[T]): untyped =
  # Build a call with a macro: callback(arg1, arg2...)
  expectKind callback, nnkSym
  let prcDef = callback.getImpl
  expectKind prcDef, RoutineNodes
  let prcParams = prcDef.params
  expectMinLen prcParams, 2 # check if there's at least one parameter.

  var paramCount = 0
  for paramDef in prcParams[1..^1]:
    paramCount.inc paramDef.len - 2

  let paramSym = genSym(nskLet, "params")
  result = quote do:
    let `paramSym` = @`params`
    doAssert `paramSym`.len == `paramCount`

  var callParams: seq[NimNode]
  for i in 0 ..< paramCount:
    callParams.add(
      quote do:
        `paramSym`[i][0]
    )

  result.add newCall(callback, callParams)
  # echo repr result

template processCallback(this: Registry, callback: proc) =
  transformTypesToTypeIds(callback)
  var matchingComponentCollections: seq[AbstractComponentCollection]
  for callbackType in typeIds:
    let collection = this.componentsTable[callbackType]
    if collection != nil:
      matchingComponentCollections.add(
        cast[ComponentCollection[string]](collection)
      )
  invokeWithArgs(callback, matchingComponentCollections)

when isMainModule:
  let testRegistry: Registry = newRegistry()
  let testEntity: Entity = testRegistry.registerNewEntity()

  type
    Foo = object
      x: int
    Bar = object
      s: string

  # Our callback
  proc foo(foo: Foo, bar: Bar) =
    echo(foo.x, bar.s)

  testRegistry.addComponent(testEntity, Foo(x: 1))
  testRegistry.addComponent(testEntity, Bar(s: "test"))
  # The componentsTable now has entries for Foo and Bar

  testRegistry.processCallback(foo)

