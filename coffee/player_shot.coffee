class Player_Shot extends Shot
  @container = []
  constructor: (@pos, xspd) ->
    @vector = [xspd, -8]
    @dims ?= [3, 10]
    @enemies = Enemy_Ship.container
    super

  damage: (entity) ->
    super
    @inc_score()

  inc_score: ->
    @game.killcount++
    @game.player.mass += 10
