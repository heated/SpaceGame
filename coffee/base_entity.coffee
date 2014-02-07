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
