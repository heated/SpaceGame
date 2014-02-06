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
      new Player_Shot([x, shoty], 0)

  render: ->
    @game.dispImg(@game.pcimg, @pos)

  destroy: ->
    super
    @game.restart()

  hit: ->
    @explode([27 + 15 * @health, @game.height - 10], 50)
    super
