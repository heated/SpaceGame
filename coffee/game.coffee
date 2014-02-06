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