video = document.querySelector 'video'
canvas = document.querySelector 'canvas'
ctx = canvas.getContext '2d'
output = document.getElementById 'deltaOutput'

Reveal.initialize {}

verticalGraphCanvas = document.querySelector '#verticalGraphCanvas'
verticalGraphCtx = verticalGraphCanvas.getContext '2d'

horizGraphCanvas = document.querySelector '#horizGraphCanvas'
horizGraphCtx = horizGraphCanvas.getContext '2d'

DIMENSIONS = 450

horizGraphCanvas.width = horizGraphCanvas.height = verticalGraphCanvas.width = verticalGraphCanvas.height = canvas.width = canvas.height = DIMENSIONS

localMediaStream = null
lastImageData = null

navigator.webkitGetUserMedia video: true, ((stream) ->
  video.src = window.URL.createObjectURL stream
  localMediaStream = stream
  snapshot()), ->

recentGesture = {
  xmin: 0
  xmax: 0
  xIncreased: false
  ymin: 0
  ymax: 0
  yIncreased: false
}

checkGestureTrigger = ->
  if recentGesture.ymax - recentGesture.ymin > 120
    if recentGesture.yIncreased
      #slider.style.top = (slider.offsetTop + 100) + 'px'
      Reveal.up()
      console.log 'SWIPE DOWN'
    else
      #slider.style.top = (slider.offsetTop - 100) + 'px'
      Reveal.down()
      console.log 'SWIPE UP'

    video.play()

    recentGesture.ymin = Infinity; recentGesture.ymax = -Infinity

  if recentGesture.xmax - recentGesture.xmin > 200
    if recentGesture.xIncreased
      #slider.style.left = (slider.offsetLeft - 100) + 'px'
      Reveal.right()
      console.log 'SWIPE LEFT'
    else
      #slider.style.left = (slider.offsetLeft + 100) + 'px'
      Reveal.left()
      console.log 'SWIPE RIGHT'

    video.play()

    recentGesture.xmin = Infinity; recentGesture.xmax = -Infinity

clearGesture = ->
  console.log 'CLEARING GESTURE'
  recentGesture.xmin = recentGesture.ymin = Infinity
  recentGesture.xmax = recentGesture.ymax = -Infinity

recentGestureTimeout = null

verticalLastPeak = 0
horizLastPeak = 0

snapshot = ->
  if localMediaStream?
    ctx.drawImage video, 0, 0
    data = ctx.getImageData 0, 0, DIMENSIONS, DIMENSIONS
    img = ctx.createImageData DIMENSIONS, DIMENSIONS

    histogramData = []
    histogramTotal = 0
    histogramAvgSum = 0

    horizHistogramData = (0 for [1..DIMENSIONS])
    horizHistogramTotal = 0
    horizHistogramAvgSum = 0
    
    if lastImageData?
      for i in [0...DIMENSIONS]
        di = 0

        for j in [0...DIMENSIONS]
          c = i * DIMENSIONS + j
          x = c * 4

          d = 0

          d += img.data[x] = 128 + data.data[x] - lastImageData.data[x]
          d += img.data[x + 1] = 128 + data.data[x + 1] - lastImageData.data[x + 1]
          d += img.data[x + 2] = 128 + data.data[x + 2] - lastImageData.data[x + 2]

          di += Math.abs d - 128 * 3

          horizHistogramData[j] += Math.abs d - 128 * 3

          img.data[x + 3] = 255

        histogramData.push di
        histogramTotal += di * di
        histogramAvgSum += i * di * di

    #ctx.clearRect 0, 0, DIMENSIONS, DIMENSIONS
    #ctx.putImageData img, 0, 0
    
    lastImageData = data

    verticalGraphCtx.clearRect 0, 0, 500, 500
    verticalGraphCtx.strokeStyle = '#00F'
    verticalGraphCtx.beginPath()
    verticalGraphCtx.moveTo 0, 0
    for dataPoint, i in histogramData by 10
      verticalGraphCtx.lineTo (Math.abs dataPoint / 100), i

    verticalGraphCtx.stroke()

    if histogramTotal > 20000000000
      verticalLastPeak = histogramAvgSum / histogramTotal

      if verticalLastPeak < recentGesture.ymin
        recentGesture.ymin = verticalLastPeak
        recentGesture.yIncreased = false

      if verticalLastPeak > recentGesture.ymax
        recentGesture.ymax = verticalLastPeak
        recentGesture.yIncreased = true

      ctx.fillStyle = '#00F'
      ctx.fillRect 0, verticalLastPeak, DIMENSIONS, 10

      checkGestureTrigger()

      clearTimeout recentGestureTimeout
      recentGestureTimeout = setTimeout clearGesture, 200
  
    horizGraphCtx.clearRect 0, 0, 500, 500
    horizGraphCtx.strokeStyle = '#00F'
    horizGraphCtx.beginPath()
    horizGraphCtx.moveTo 0, 0
    for dataPoint, i in horizHistogramData by 10
      horizHistogramTotal += dataPoint * dataPoint
      horizHistogramAvgSum += i * dataPoint * dataPoint
      horizGraphCtx.lineTo i, (Math.abs dataPoint / 100)

    horizGraphCtx.stroke()

    if horizHistogramTotal > 2000000000
      horizLastPeak = horizHistogramAvgSum / horizHistogramTotal
      
      if horizLastPeak < recentGesture.xmin
        recentGesture.xmin = horizLastPeak
        recentGesture.xIncreased = false

      if horizLastPeak > recentGesture.xmax
        recentGesture.xmax = horizLastPeak
        recentGesture.xIncreased = true

      ctx.fillStyle = '#00F'
      ctx.fillRect horizLastPeak, 0, 10, DIMENSIONS

      checkGestureTrigger()

      clearTimeout recentGestureTimeout
      recentGestureTimeout = setTimeout clearGesture, 200
    
    setTimeout snapshot, 30
