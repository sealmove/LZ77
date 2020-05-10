import strutils

type BitStream* = ref object
  data: seq[byte]
  pos*: int
  dword: uint32
  bits: int

proc fetchBits(bs: BitStream) =
  var word: uint32
  copyMem(addr(word), addr(bs.data[bs.pos]), 2)
  bs.dword += word shl (16 - bs.bits)
  bs.pos += 2
  bs.bits += 16

## Advance `n` bits.
proc skip*(bs: BitStream, n: int) =
  bs.dword = bs.dword shl n
  bs.bits -= n
  if bs.bits < 16:
    bs.fetchBits

## Return the next `n` bits as an integer. Bits are not consumed.
proc peek*(bs: BitStream, n: int): uint32 =
  if n == 0: 0'u32
  else: bs.dword shr (32 - n)

## Return the next `n` bits as an integer. Bits are consumed.
proc read*(bs: BitStream, n: int): uint32 =
  result = bs.peek(n)
  skip(n)

proc close*(bs: BitStream) =
  when defined(nimNoNilSeqs):
    bs.data = @[]
  else:
    bs.data = nil

proc newBitStream*(s: seq[byte] = @[]): owned BitStream =
  new(result)
  result.data = s
  result.fetchBits
  result.fetchBits