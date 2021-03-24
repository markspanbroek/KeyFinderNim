import std/sequtils
import std/sugar
import std/json
import std/httpclient
import std/random
import api

randomize()

var playerId: string
var maxNumberOfEntries: int
var maxLineLength: int
var allowedCharacters: string

proc random(_: type Entry): Entry =
  result.number = int32.rand
  let linelen = rand(0..maxLineLength)
  for _ in 0..<linelen:
    result.line.add(allowedCharacters.sample)
  result.score = -10000000000.0

proc join: string =
  let request = PlayerJoinRequest(clientId: "Cracker", playerName: "Jeff Sitar")
  httpPostPlayerJoin(request).playerId

proc randomPopulation: seq[Entry] =
  for _ in 0..<maxNumberOfEntries:
    result.add(Entry.random)

proc initialize =
  echo "initializing"
  while true:
    echo "."
    try:
      playerId = join()
      allowedCharacters = httpGetLegalCharacters()
      maxLineLength = httpGetKeyStatus().maxLineLength
      maxNumberOfEntries = httpGetKeyStatus().maxNumberOfEntries
      break
    except KeyError:
      discard

proc modulo(a,n: int): int =
  ((a mod n) + n) mod n

proc mutate(s: string): string =
  result = s
  while rand(1.0) < 0.5:
    if result.len > 0:
      let index = rand(result.len - 1)
      let character = result[index]
      var offset = rand(1) + 1
      if rand(1.0) < 0.5:
        offset = -offset
      let next = allowedCharacters[modulo(allowedCharacters.find(character) + offset, allowedCharacters.len)]
      result[rand(result.len - 1)] = next
  if rand(1.0) < 0.1 and result.len < maxLineLength:
    result.add(allowedCharacters.sample)
  if rand(1.0) < 0.1 and result.len > 0:
    result = result.substr(1)
  if rand(1.0) < 0.3:
    result = Entry.random().line

proc mutate(i: int32): int32 =
  result = i
  while rand(1.0) < 0.99:
    if rand(1.0) < 0.1:
      result = result div 2
    if rand(1.0) < 0.1 and
      int32.low div 2 < result and
      result < int32.high div 2:
      result = result * 2
    if rand(1.0) < 0.5 and result < int32.high:
      result = result + rand(1000).int32
    if rand(1.0) < 0.5 and result > int32.low:
      result = result - rand(1000).int32
  if rand(1.0) < 0.3:
    result = Entry.random().number

proc best(population: seq[Entry]): Entry =
  let index = maxIndex(population.map(x => x.score))
  population[index]

proc mutate(entry: Entry): Entry =
  result = entry
  if rand(1.0) < 0.5:
    result.line = mutate(result.line)
  else:
    result.number = mutate(result.number)

proc done(population: seq[Entry]): bool =
  for entry in population:
    if entry.score == 0.0:
      return true
  false

proc evaluate(population: seq[Entry]): seq[Entry] =
  let request = EvaluateRequest(playerId: playerId, entries: population)
  let response = httpPostEvaluate(request)
  response.entries

initialize()
var population = randomPopulation()
while not population.done():
  let best = population.best()
  population = best & newSeqWith(population.len-1, best.mutate)
  try:
    population = evaluate(population)
    echo population.best
  except KeyError, JsonParsingError, ProtocolError:
    initialize()
    continue
