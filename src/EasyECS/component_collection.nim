import entity

type
  EntityComponent[C] = tuple[entity: Entity, component: C]
  AbstractComponentCollection* = ref object of RootObj
  ComponentCollection*[C] = ref object of AbstractComponentCollection
    components: seq[EntityComponent[C]]

proc newComponentCollection*[C](): ComponentCollection[C] =
  result.new()

proc `[]`*[C](this: ComponentCollection[C], i: int): EntityComponent[C] =
  this.components[i]

proc add*[C](this: ComponentCollection[C], entity: Entity, component: C) =
  this.components.add((entity, component))

iterator forEach*[C](this: ComponentCollection[C]): C =
  for c in this.components:
    yield c

