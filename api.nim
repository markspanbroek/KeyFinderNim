import httpclient
import json

var host = "https://dojomaze-api.maas.codes/evaluate/"

type
    KeyStatusResponse* = object
        currentKeyNumber*: int
        expiresUtc*: string
        maxNumberOfEntries*: int
        maxLineLength*: int
        playersJoined*: seq[string]
        winners*: seq[string]

    PlayerJoinRequest* = object
        clientId*: string
        playerName*: string

    PlayerJoinResponse* = object
        playerId*: string

    EvaluateRequest* = object
        playerId*: string
        entries*: seq[Entry]

    EvaluateResponse* = object
        entries*: seq[Entry]

    Entry* = object
        line*: string
        number*: int
        score*: float

proc httpGetString(url: string): string =
    var client = newHttpClient()
    return client.getContent(host & url)

proc httpGetJson(url: string): JsonNode =
    var jsonStr = httpGetString(url)
    return parseJson(jsonStr)

proc httpPostJson[T](url: string, request: T): JsonNode = 
    let client = newHttpClient()
    client.headers = newHttpHeaders({ "Content-Type": "application/json" })
    let body = %*request
    let response = client.request(host & url, httpMethod = HttpPost, body = $body)
    let responseStr = response.body()
    return parseJson(responseStr)

proc httpGetKeyStatus*(): KeyStatusResponse =
    return to(httpGetJson("status"), KeyStatusResponse)
    
proc httpGetLegalCharacters*(): string =
    return httpGetString("characters")

proc httpPostPlayerJoin*(request: PlayerJoinRequest): PlayerJoinResponse =
    return to(httpPostJson("join", request), PlayerJoinResponse)

proc httpPostEvaluate*(request: EvaluateRequest): EvaluateResponse =
    return to(httpPostJson("run", request), EvaluateResponse)
