class Particle extends BaseEntity
  @container = []
  constructor: (@pos, @vector) ->
    @dims = [2, 2]
    @mass = 0
    super

  act: ->
    @destroy() if Math.random() < .1
