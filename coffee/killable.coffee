class Killable extends BaseEntity
  constructor: ->
    @max_health ?= 1
    @health = @max_health
    super

  hit: ->
    @destroy() if --@health <= 0
