window.requestAnimFrame =
  requestAnimationFrame || 
  webkitRequestAnimationFrame || 
  mozRequestAnimationFrame || 
  oRequestAnimationFrame || 
  msRequestAnimationFrame || 
  (callback, element) -> setTimeout(callback, 1000 / 60)

window.Game = new Game()