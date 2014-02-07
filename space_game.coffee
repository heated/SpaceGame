class BaseEntity
  constructor: ->
    @game = window.Game
    @container = @constructor.container ?= []
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
    x > @game.width + tolerance ||
    y > @game.height + tolerance

  collides: (entity) ->
    [x1, y1] = @pos
    [x2, y2] = entity.pos
    min_dist = (@size + entity.size) / 2
    Math.pow(x1 - x2, 2) + Math.pow(y1 - y2, 2) < Math.pow(min_dist, 2)

  render: ->
    @rect(@pos, @dims)

  rect: ->
    [x, y] = @pos
    [dx, dy] = @dims
    @game.ctx.fillRect( (x - dx / 2)|0, 
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
      new Particle(pos.slice(0), [xspeed, yspeed])

class Particle extends BaseEntity
  @container = []
  constructor: (@pos, @vector) ->
    @dims = [2, 2]
    @mass = 0
    super

  act: ->
    @destroy() if Math.random() < .1

class Star extends BaseEntity
  @container = []
  constructor: (xpos) ->
    @pos = [xpos, -1]
    @vector = [0, 6]
    @dims = [1, 2]
    @mass = 0
    super

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
    @game.player.mass += 100

class Enemy_Shot extends Shot
  @container = []
  constructor: (@pos, @vector) ->
    @dims = [3, 10]
    @enemies = Player.container
    super

  damage: (entity) ->
    super
    @explode(@pos, 50)

class Killable extends BaseEntity
  constructor: ->
    @max_health ?= 1
    @health = @max_health
    super

  hit: ->
    @destroy() if --@health <= 0

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

class Player extends Killable
  @container = []
  constructor: ->
    @dims ?= [25, 25]
    @pos ?= [320, 350]
    @enemies = Enemy_Ship.container
    @mass ?= 500
    @max_health ?= 3
    @cooldown = 0
    super

  update_pos: ->
    [x, y] = @pos
    dirs = ((key ? 1 : 0) for key in @game.keypress)

    x += 4 * (dirs[2] - dirs[0])
    y += 4 * (dirs[3] - dirs[1])

    x = @buffer(x, @size / 2, @game.width - @size / 2)
    y = @buffer(y, @size / 2, @game.height - @size / 2)

    @pos = [x, y]
    @render()

  buffer: (index, left, right) ->
    return left if index < left
    return right if index > right
    index

  act: ->
    @spawn_shot() if @cooldown-- <= 0 && @game.keypress[4]

  spawn_shot: ->
    @cooldown = 30

    [x, y] = @pos
    side_length = @size / 2
    shoty = y - side_length
    left = x - side_length
    right = x + side_length

    killcount = @game.killcount
    if killcount >= 60
      @cooldown = 0
      new Player_Shot([x, shoty], Math.random() - .5)
    else if killcount >= 40
      a = 5
      while(a-- > 0)
        new Player_Shot([x, shoty], a - 2)
    else if killcount >= 20
      new Player_Shot([left, y], -1)
      new Player_Shot([x, shoty], 0)
      new Player_Shot([right, y], 1)
    else if killcount >= 5
      new Player_Shot([left, y], 0)
      new Player_Shot([right, y], 0)
    else
      new Player_Shot([x, shoty], 0)

  render: ->
    @game.dispImg(@game.pcimg, @pos)

  destroy: ->
    super
    @game.restart()

  hit: ->
    @explode([27 + 15 * @health, @game.height - 10], 50)
    super

class Game
  constructor: ->  
    @canvas = document.getElementById('game')
    @ctx = @canvas.getContext('2d')
    @width = @canvas.width
    @height = @canvas.height

    @pcimg        = @srcimg('MqaLKP2')
    @meteorimg    = @srcimg('ChDuBLO')
    @bigmeteorimg = @srcimg('tIyQv1V')
    @shipimg      = @srcimg('SbyapXR')
    @bigshipimg   = @srcimg('nzSFj9X')
    @armorimg     = @srcimg('pXRIDRB')

    @all_entities = [['white', Star       ]
                     [ 'grey', Particle   ]
                     ['white', Player_Shot]
                     [  'red', Enemy_Shot ]
                     ['white', Enemy_Ship ]
                     ['white', Player     ]]

    @keypress = [false, false, false, false, false]
    @paused = false

    @killcount = 0
    @spawntime = 60
    @spawner = 0
    @stargen = 0

    @canvas.addEventListener('keydown', (e) => @handleKeys(e))
    @canvas.addEventListener('keyup', (e) => @handleKeys(e))

    window.requestAnimFrame(=> @game_loop())

  srcimg: (src) -> # get images more easily
    img = document.createElement('img')
    img.src = 'http://i.imgur.com/' + src + '.png'
    img

  game_loop: ->
    return if @paused
    @player = new Player() if Player.container.length == 0

    window.requestAnimFrame(=> @game_loop())

    @increment_spawning()

    @ctx.clearRect(0, 0, @width, @height)
    @renderEntities()
    @renderText()

  renderText: ->
    @ctx.fillStyle = 'white'
    @ctx.textAlign = 'left'
    @ctx.fillText('kills: ' + @killcount, 5, 13)
    @ctx.fillText('armor: ', 5, @height - 6)

    @ctx.fillStyle = 'grey'
    a = @player.health
    while a-- > 0
      @dispImg(@armorimg, [42 + 15 * a, @height - 10])

  renderEntities: ->
    @render_group(group) for group in @all_entities

  render_group: ([color, base_class]) ->
    @ctx.fillStyle = color
    group = base_class.container
    a = group.length
    while a-- > 0
      group[a].update()

  restart: ->
    Player_Shot.container = []
    Enemy_Shot.container = []
    Enemy_Ship.container = []
    Player.container = []
    @player = new Player()
    @killcount = 0

  dispImg: (img, pos) ->
    center_x = pos[0] - img.width / 2
    center_y = pos[1] - img.height / 2
    @ctx.drawImage(img, (center_x|0) + .5, (center_y|0) + .5)

  increment_spawning: ->
    @spawner--
    if @spawner <= 0
      if @killcount >= 40
        @spawner = @spawntime / 4
      else if @killcount >= 15
        @spawner = @spawntime / 2
      else
        @spawner = @spawntime

      x = Math.random() * (@width - 25) + 25 / 2
      y = -25 / 2
      x_speed = .6 * Math.random() - .3
      y_speed = 1.5
      shot_offset = 30 + Math.random() * 60

      new Enemy_Ship([x, y], [x_speed, y_speed], shot_offset)

    new Star(Math.random() * @width)

  handleKeys: (event) ->
    down = event.type == 'keydown'

    a = -1
    switch event.keyCode
      when 37, 65 then a = 0 # a
      when 38, 87 then a = 1 # w
      when 39, 68 then a = 2 # d
      when 40, 83 then a = 3 # s
      when 32, 76 then a = 4 # l, space

    if down
      switch event.keyCode
        when 80 then @toggle_pause() # p
        when 82 then @restart() # r

    @keypress[a] = down if a >= 0

    event.preventDefault()
    event.stopPropagation()

  toggle_pause: ->
    @paused = !@paused
    if @paused
      @ctx.fillStyle = 'white'
      @ctx.fillText('-paused-', @width / 2 + 20, @height / 2 + 5)
    else window.requestAnimFrame(=> @game_loop())


window.requestAnimFrame =
  requestAnimationFrame || 
  webkitRequestAnimationFrame || 
  mozRequestAnimationFrame || 
  oRequestAnimationFrame || 
  msRequestAnimationFrame || 
  (callback, element) -> setTimeout(callback, 1000 / 60)

window.Game = new Game()