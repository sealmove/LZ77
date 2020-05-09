import strutils

type WordBitStream* = ref object
  data*: seq[byte]
  pos*: int
  dword*: uint32
  bits*: int

proc fetchBits(wbs: WordBitStream) =
  var word: uint32
  copyMem(addr(word), addr(wbs.data[wbs.pos]), 2)
  wbs.dword += word shl (16 - wbs.bits)
  wbs.pos += 2
  wbs.bits += 16

#proc atEnd*(wbs: WordBitStream): bool =
#  return wbs.pos >= wbs.data.len

## Return the next `n` bits as an integer. Bits are not consumed
proc peek*(wbs: WordBitStream, n: int): uint32 =
  if n == 0: 0'u32
  else: wbs.dword shr (32 - n)

## Return the next `n` bits as an integer. Bits are consumed
proc read*(wbs: WordBitStream, n: int): uint32 =
  result = wbs.peek(n)
  wbs.dword = wbs.dword shl n
  wbs.bits -= n
  if wbs.bits < 16:
    wbs.fetchBits

proc close*(wbs: WordBitStream) =
  when defined(nimNoNilSeqs):
    wbs.data = @[]
  else:
    wbs.data = nil

proc newWordBitStream*(s: seq[byte] = @[]): owned WordBitStream =
  new(result)
  result.data = s
  result.fetchBits
  result.fetchBits
