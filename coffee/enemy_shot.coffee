class Enemy_Shot extends Shot
  @container = []
  constructor: (@pos, @vector) ->
    @dims = [3, 10]
    @enemies = Player.container
    super

  damage: (entity) ->
    super
    @explode(@pos, 50)
