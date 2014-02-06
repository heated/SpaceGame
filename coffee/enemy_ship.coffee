class Enemy_Ship extends Killable
  @container = []
  constructor: (@pos, @vector, @cooldown) ->
    @dims = [25, 25]
    @enemies = Player.container
    super

  act: ->
    @collide_with_enemies()
    @spawn_shot() if @cooldown-- <= 0

  spawn_shot: ->
    @cooldown = 60
    new_shot = new Enemy_Shot(@pos.slice(0), [0, 6])
    new_shot.pos[1] += @size / 2

  collide_with_enemies: ->
    e = @enemies.length
    while(e-- > 0)
      if @collides(@enemies[e])
        @damage(@enemies[e])
        @destroy()
        break

  damage: (entity) ->
    entity.hit()

  render: ->
    @game.dispImg(@game.shipimg, @pos)
