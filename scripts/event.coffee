module.exports = (robot) ->

  crypto = require 'crypto'
  cloneDeep = require 'lodash/cloneDeep'

  robot.router.post "/github/practiceDev-GitHub", (request, res) ->

    #===============slackのチャンネル=============================

    target_chanel = "#テス"

    #===============eventに対応するhanler=============================

    event_hanler_list = (config) ->

      body = config.req().body
      action = config.action()

      return {

        issues: () ->
          issue = body.issue

          #sendResponseのmessageとなります。
          return  """
                  #{issue.url}
                  <@#{issue.user.login}>さんがIssueを#{action}。
                  """
      }

    #==============レスポンス========================

    sendErrorResponse = (e = null) ->
      console.log e
      (message = "エラーです") ->
        res.status(400).send message


    sendResponse = (message) ->
      robot.messageRoom target_chanel, message
      res.status(201).send

    #==================================================
    #==================================================
    #==================================================

    #初期設定
    init = (request) ->
      req = cloneDeep request
      getRequest = () ->
        return () ->
            return req

      getAction = () ->
        return () ->
            return req.body.action

      getSignature = () ->
        signature = req.get 'X-Hub-Signature'
        return () ->
            return signature

      getEventType = () ->
        event_type = req.get 'X-Github-Event'
        return () ->
          return event_type

      obj =  {
        #valueは全てfunc型
        req: getRequest(),
        action: getAction(),
        signature: getSignature(),
        event_type: getEventType(),
      }

      return obj

    #認証
    isCorrectSignature = (config) ->

      pairs = config.signature().split '='
      digest_method = pairs[0]
      hmac = crypto.createHmac digest_method, process.env.HUBOT_GITHUB_SECRET
      hmac.update JSON.stringify(config.req().body), 'utf-8'
      hashed_data = hmac.digest 'hex'
      generated_signature = [digest_method, hashed_data].join '='

      return config.signature() is generated_signature

    #=================メインロジック==========================
    try

      # 1. 設定を取得
      config = init(request)

      # 2. 認証する
      checkAuth = isCorrectSignature config
      console.log "checkAuth : #{checkAuth}"
      unless checkAuth?
        sendErrorResponse()("認証エラー")

      # 3. EventHandler有無をチェック
      event = config.event_type()
      handler = event_hanler_list(config)[event]

      unless event?
        sendErrorResponse()("#{event}：未対応イベント")

      # 4. EventHandlerを実行
      message = handler()

      # 5. レスポンスする
      sendResponse(message)

    catch e
      sendErrorResponse(e)()
