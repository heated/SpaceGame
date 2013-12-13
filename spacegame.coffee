class BaseEntity
  constructor: ->
    @index = @container.length
    @container.push(this)
    @mass = (@dims[0] * @dims[1] / 4) | 0
    @size = @dims[0]

  update_pos: ->
    @pos[0] += @vector[0]
    @pos[1] += @vector[1]
    if @out_of_bounds()
      @destroy()
    else
      @render()

  update: ->
    @update_pos()
    @act()

  destroy: ->
    @container[@index] = @container[@container.length - 1]
    @container[@index].index = @index
    @container.pop()
    explode(@pos, @mass)

  out_of_bounds: ->
    [x, y] = @pos
    tolerance = @dims[0]
    return x < -tolerance ||
           y < -tolerance ||
           x > canvas.width + tolerance ||
           y > canvas.height + tolerance

  collides: (entity) ->
    [x1, y1] = @pos
    [x2, y2] = entity.pos
    min_dist = @size / 2 + entity.size / 2
    return ( Math.pow(x1 - x2, 2) + Math.pow(y1 - y2, 2) ) < Math.pow(min_dist, 2) #TODO

  render: ->
    @rect(@pos, @dims)

  rect: ->
    [x, y] = @pos
    [dx, dy] = @dims
    ctx.fillRect( (x - dx / 2)|0, 
                  (y - dy / 2)|0, 
                            dx|0, 
                            dy|0 )

  act: ->

class Particle extends BaseEntity
  constructor: (@pos, @vector) ->
    @dims = [2, 2]
    @container = particles
    super
    @mass = 0

  act: ->
    @destroy() if Math.random() < .1

class Star extends BaseEntity
  constructor: (xpos) ->
    @pos = [xpos, -1]
    @vector = [0, 5]
    @dims = [1, 2]
    @container = stars
    super
    @mass = 0

class Shot extends BaseEntity
  act: ->
    explode(@pos, 1)
    @collide_with_enemies()

  collide_with_enemies: ->
    e = @enemies.length
    while(e-- > 0)
      if @collides(@enemies[e])
        @damage(@enemies[e])
        @destroy()
        break

class Player_Shot extends Shot
  constructor: (@pos, xspd) ->
    @vector = [xspd, -8]
    @dims = [3, 6]
    @container = player_attacks
    @enemies = enemy_mobs
    super

  damage: (entity) ->
    entity.destroy()
    inc_score()

class Enemy_Shot extends Shot
  constructor: (@pos, @vector) ->
    @dims = [3, 6]
    @container = enemy_attacks
    @enemies = [player]
    super

  damage: (entity) ->
    explode(@pos, 50)
    hitplayer()

  collides: (entity) ->
    collision(@pos, entity, 15)

class Enemy_Ship extends Shot
  constructor: (@pos, @vector, @cooldown) ->
    @dims = [25, 25]
    @container = enemy_mobs
    @enemies = [player]
    super

  damage: (entity, e) ->
    hitplayer()

  act: ->
    @collide_with_enemies()
    @spawn_shot() if @cooldown-- <= 0

  spawn_shot: ->
    @cooldown = 60
    new_shot = new Enemy_Shot([@pos...], [0, 6])
    new_shot.pos[1] += @size / 2

  collides: (entity) ->
    collision(@pos, entity, 25)

  render: ->
    dispImg(shipimg, @pos)

class Player extends BaseEntity
  constructor: ->
    @dims = [25, 25]
    @container = allies
    @enemies = enemy_mobs
    super
    @mass = 1000

  update_pos: ->
    [x, y] = @pos

    x += 4 * (keypress[2] - keypress[0])
    y += 4 * (keypress[3] - keypress[1])

    x = @buffer(x, @size / 2, canvas.width - @size / 2)
    y = @buffer(y, @size / 2, canvas.height - @size / 2)

  buffer: (index, left, right) ->
    return left if index < left
    return right if index > right
    return index

  act: ->
    @spawn_shot() if @cooldown-- <= 0 && keypress[4]

  spawn_shot: ->
    @cooldown = 10
    new_shot = new Player_Shot([@pos...], 0)
    new_shot.pos[1] -= @size / 2

  render: ->
    dispImg(pcimg, @pos)

window.BaseEntity = BaseEntity
window.Particle = Particle
window.Star = Star
window.Shot = Shot
window.Player_Shot = Player_Shot
window.Enemy_Ship = Enemy_Ship