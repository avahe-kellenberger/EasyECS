type
  ComponentEntity[C, E] = tuple[component: C, entity: E]
  ComponentCollection*[C, E] = ref object
    components: seq[ComponentEntity[C, E]]

proc newComponentCollection*[C, E](): ComponentCollection[C, E] =
  result.new()

