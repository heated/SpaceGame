class Shot extends BaseEntity
  act: ->
    @collide_with_enemies()
    @explode(@pos, 1)

  collide_with_enemies: ->
    e = @enemies.length
    while(e-- > 0)
      if @collides(@enemies[e])
        @damage(@enemies[e])
        @destroy()
        break

  damage: (entity) ->
    entity.hit()
