class BaseEntity
  constructor: ->
    @index = @container.length
    @container.push(this)
    @mass ?= (@dims[0] * @dims[1] / 4) | 0
    @size ?= @dims[0]

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
    @explode(@pos, @mass)

  out_of_bounds: ->
    [x, y] = @pos
    tolerance = @dims[0]
    x < -tolerance ||
    y < -tolerance ||
    x > canvas.width + tolerance ||
    y > canvas.height + tolerance

  collides: (entity) ->
    [x1, y1] = @pos
    [x2, y2] = entity.pos
    min_dist = @size / 2 + entity.size / 2
    Math.pow(x1 - x2, 2) + Math.pow(y1 - y2, 2) < Math.pow(min_dist, 2)

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

  explode: (pos, power) ->
    e = power
    while(e-- > 0)
      angle = Math.random() * Math.PI * 2
      blast = Math.random() * Math.sqrt(power) / 4
      xspeed = Math.cos(angle) * blast
      yspeed = Math.sin(angle) * blast
      new Particle([pos...], [xspeed, yspeed])

class Particle extends BaseEntity
  constructor: (@pos, @vector) ->
    @dims = [2, 2]
    @container = particles
    @mass = 0
    super

  act: ->
    @destroy() if Math.random() < .1

class Star extends BaseEntity
  constructor: (xpos) ->
    @pos = [xpos, -1]
    @vector = [0, 5]
    @dims = [1, 2]
    @container = stars
    @mass = 0
    super

class Killable extends BaseEntity
  constructor: ->
    @max_health ?= 1
    @health = @max_health
    super

  hit: ->
    @destroy() if --@health <= 0

class Shot extends Killable
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

class Player_Shot extends Shot
  constructor: (@pos, xspd) ->
    @vector = [xspd, -8]
    @dims ?= [3, 6]
    @container = player_attacks
    @enemies = enemy_mobs
    super

  damage: (entity) ->
    super
    @inc_score()

  inc_score: ->
    killcount++
    player.mass += 10

class Enemy_Shot extends Shot
  constructor: (@pos, @vector) ->
    @dims = [3, 6]
    @container = enemy_attacks
    @enemies = [player]
    super

  damage: (entity) ->
    super
    @explode(@pos, 50)

class Enemy_Ship extends Shot
  constructor: (@pos, @vector, @cooldown) ->
    @dims = [25, 25]
    @container = enemy_mobs
    @enemies = [player]
    super

  act: ->
    @collide_with_enemies()
    @spawn_shot() if @cooldown-- <= 0

  spawn_shot: ->
    @cooldown = 60
    new_shot = new Enemy_Shot(@pos.slice(0), [0, 6])
    new_shot.pos[1] += @size / 2

  render: ->
    dispImg(shipimg, @pos)

class Player extends Killable
  constructor: ->
    @dims ?= [25, 25]
    @pos ?= [320, 350]
    @container = allies
    @enemies = enemy_mobs
    @mass ?= 500
    @max_health ?= 3
    @cooldown = 0
    super

  update_pos: ->
    [x, y] = @pos
    dirs = ((key ? 1 : 0) for key in keypress)

    x += 4 * (dirs[2] - dirs[0])
    y += 4 * (dirs[3] - dirs[1])

    x = @buffer(x, @size / 2, canvas.width - @size / 2)
    y = @buffer(y, @size / 2, canvas.height - @size / 2)

    @pos = [x, y]
    @render()

  buffer: (index, left, right) ->
    return left if index < left
    return right if index > right
    index

  act: ->
    @spawn_shot() if @cooldown-- <= 0 && keypress[4]

  spawn_shot: ->
    @cooldown = 10

    [x, y] = @pos
    side_length = @size / 2
    shoty = y - side_length
    left = x - side_length
    right = x + side_length

    if killcount >= 70
      @cooldown = 0
      new Player_Shot([x, shoty], Math.random() - .5)
    else if killcount >= 45
      a = 5
      while(a-- > 0)
        new Player_Shot([x, shoty], a - 2)
    else if killcount >= 25
      new Player_Shot([left, y], -1)
      new Player_Shot([x, shoty], 0)
      new Player_Shot([right, y], 1)
    else if killcount >= 10
      new Player_Shot([left, y], 0)
      new Player_Shot([right, y], 0)
    else
      new Player_Shot([x, shoty], 0) # x, y, xspd

  render: ->
    dispImg(pcimg, @pos)

  destroy: ->
    super
    restart()

  hit: ->  
    @explode([27 + 15 * @health, canvas.height - 10], 50)
    super

srcimg = (src) -> # get images more easily
  img = document.createElement('img')
  img.src = 'http://i.imgur.com/' + src + '.png'
  img

canvas = document.getElementById('game')
ctx = canvas.getContext('2d')

pcimg = srcimg('MqaLKP2')
meteorimg = srcimg('ChDuBLO')
bigmeteorimg = srcimg('tIyQv1V')
shipimg = srcimg('SbyapXR')
bigshipimg = srcimg('nzSFj9X')
armorimg = srcimg('pXRIDRB')

particles = []
stars = []

player_attacks = []
enemy_attacks = []
enemy_mobs = []
allies = []
player = new Player()
killcount = 0

all_entities = [['white', stars]
                ['grey', particles]
                ['white', player_attacks]
                ['red', enemy_attacks]
                ['white', enemy_mobs]
                ['white', allies]]

spawntime = 60
spawner = 0
stargen = 0

keypress = [false, false, false, false, false] #w, a, s, d, l
paused = false

game_loop = ->
  return if paused

  window.requestAnimFrame(game_loop)

  increment_spawning()

  ctx.clearRect(0, 0, canvas.width, canvas.height)
  renderEntities()
  renderText()

renderText = ->
  ctx.fillStyle = 'white'
  ctx.textAlign = 'left'
  ctx.fillText('kills: ' + killcount, 5, 13)
  ctx.fillText('armor: ', 5, canvas.height - 6)

  ctx.fillStyle = 'grey'
  a = player.health
  while a-- > 0
    dispImg(armorimg, [42 + 15 * a, canvas.height - 10])

renderEntities = ->
  render_group(color, group) for [color, group] in all_entities

render_group = (color, group) ->
  ctx.fillStyle = color
  a = group.length
  while a-- > 0
    group[a].update()

restart = ->
  player_attacks = []
  enemy_attacks = []
  enemy_mobs = []
  allies = []
  player = new Player()
  killcount = 0

dispImg = (img, pos) ->
  center_x = pos[0] - img.width / 2
  center_y = pos[1] - img.height / 2
  ctx.drawImage(img, (center_x|0) + .5, (center_y|0) + .5)

increment_spawning = ->
  spawner--
  if spawner <= 0
    if killcount >= 40
      spawner = spawntime / 4
    else if killcount >= 15
      spawner = spawntime / 2
    else
      spawner = spawntime

    x = Math.random() * (canvas.width - 25) + 25 / 2
    y = -25 / 2
    x_speed = .6 * Math.random() - .3
    y_speed = 1.5
    shot_offset = 30 + Math.random() * 60

    new Enemy_Ship([x, y], [x_speed, y_speed], shot_offset)

  if stargen-- < 0
    stargen = 0
    new Star(Math.random() * canvas.width) # x

handleKeys = (event) ->
  a = -1
  switch event.keyCode
    when 37, 65 then a = 0 # a
    when 38, 87 then a = 1 # w
    when 39, 68 then a = 2 # d
    when 40, 83 then a = 3 # s
    when 32, 76 then a = 4 # l

  down = event.type == 'keydown'
  if a >= 0
    keypress[a] = down ? true : false

  if event.keyCode == 80 && down
    toggle_pause() # p

  event.preventDefault()
  event.stopPropagation()

toggle_pause = ->
  paused = !paused
  if paused
    ctx.fillStyle = 'white'
    ctx.fillText('-paused-', canvas.width / 2 + 20, canvas.height / 2 + 5)
  else window.requestAnimFrame(game_loop)

window.requestAnimFrame = # render cycle
  window.requestAnimationFrame || 
  window.webkitRequestAnimationFrame || 
  window.mozRequestAnimationFrame || 
  window.oRequestAnimationFrame || 
  window.msRequestAnimationFrame || 
  (callback, element) -> window.setTimeout(callback, 1000 / 60)

canvas.addEventListener('keydown', handleKeys, true)
canvas.addEventListener('keyup', handleKeys, true)

window.requestAnimFrame(game_loop)