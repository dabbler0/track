video = document.querySelector 'video'
canvas = document.querySelector 'canvas'
ctx = canvas.getContext '2d'
output = document.getElementById 'deltaOutput'

DIMENSIONS = 450
ITERATIONS = 10
WINDOW_SIZE = 100

canvas.width = canvas.height = DIMENSIONS

localMediaStream = null
lastImageData = null

navigator.webkitGetUserMedia video: true, (stream) ->
  video.src = window.URL.createObjectURL stream
  localMediaStream = stream
  snapshot()

recentTriggers = {
  bottom : false
  top : false
}

lastCentroid = [DIMENSIONS / 2, DIMENSIONS / 2]

colorWanted = [255, 255, 255]

colorDiff = (a, b) ->
  100 / (Math.abs(a[0] - b[0]) + Math.abs(a[1] - b[1]) + Math.abs(a[2] - b[2]) + 1)

getColor = (x, a) ->
  [a[x], a[x+1], a[x+2]]

snapshot = ->
  ctx.drawImage video, 0, 0
  if localMediaStream? and not selecting
    data = ctx.getImageData 0, 0, DIMENSIONS, DIMENSIONS
    img = ctx.createImageData DIMENSIONS, DIMENSIONS

    getWindowCentroid = (center) ->
      centroid = [0, 0]
      total = 0
      for i in [Math.max(0, Math.floor(center[0] - WINDOW_SIZE / 2))..Math.min(DIMENSIONS-1, Math.floor(center[0] + WINDOW_SIZE / 2))]
        for j in [Math.max(0, Math.floor(center[1] - WINDOW_SIZE / 2))..Math.min(DIMENSIONS-1, Math.floor(center[1] + WINDOW_SIZE / 2))]
          c =i * DIMENSIONS + j
          x = c * 4

          centroid[1] += j * colorDiff(colorWanted, getColor(x, data.data))
          centroid[0] += i * colorDiff(colorWanted, getColor(x, data.data))

          total += colorDiff(colorWanted, getColor(x, data.data))
          if total isnt total
            debugger

      centroid[0] /= total
      centroid[1] /= total

      return centroid
    
    for [1..5]
      lastCentroid = getWindowCentroid lastCentroid
    #output.innerText = lastCentroid
  
  ctx.strokeRect lastCentroid[1] - 50, lastCentroid[0] - 50, 100, 100

  setTimeout snapshot, 30

selecting = false

canvas.addEventListener 'click', ->
  unless selecting
    selecting = true
    center = lastCentroid = [DIMENSIONS / 2, DIMENSIONS / 2]
    ctx.strokeRect lastCentroid[1] - 50, lastCentroid[0] - 50, 100, 100
  else
    data = ctx.getImageData 0, 0, DIMENSIONS, DIMENSIONS
    center = lastCentroid

    avgColor = [0, 0, 0]
    total = 0
    for i in [Math.max(0, Math.floor(center[0] - WINDOW_SIZE / 2))..Math.min(DIMENSIONS-1, Math.floor(center[0] + WINDOW_SIZE / 2))]
      for j in [Math.max(0, Math.floor(center[1] - WINDOW_SIZE / 2))..Math.min(DIMENSIONS-1, Math.floor(center[1] + WINDOW_SIZE / 2))]
        c =i * DIMENSIONS + j
        x = c * 4

        avgColor[0] += data.data[x]
        avgColor[1] += data.data[x+1]
        avgColor[2] += data.data[x+2]

        total += 1

    avgColor[k] /= total for k in [0..2]

    colorWanted = avgColor

    document.body.style.backgroundColor = "rgb(#{Math.floor(avgColor[0])}, #{Math.floor(avgColor[1])}, #{Math.floor(avgColor[2])})"

    selecting = false
