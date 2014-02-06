class Star extends BaseEntity
  @container = []
  constructor: (xpos) ->
    @pos = [xpos, -1]
    @vector = [0, 6]
    @dims = [1, 2]
    @mass = 0
    super
