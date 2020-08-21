module.exports = (robot) ->
  robot.hear /おはよう/i, (res) ->
    res.reply "おはよう"

  robot.hear /こんにちは/i, (res) ->
    res.reply "こんにちは"

  robot.hear /こんばんは/i, (res) ->
    res.reply "こんばんは"
