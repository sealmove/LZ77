import algorithm, math

type
  CodeLenBits {.size: sizeof(cint).} = enum
    A, B, C, D
  CodeLen = set[CodeLenBits]
  BitStream = ref object
    data: seq[byte]
    pos: int

proc toNum(bits: CodeLen): int = cast[cint](bits)
proc toBits(b: byte): CodeLen = cast[CodeLen](b.int)

proc read[T: SomeUnsignedInt](bs: BitStream): T =
  for b in 0 ..< sizeof(T):
    result = result or (bs.data[bs.pos] shl (8*b))
    inc(bs.pos)

proc decodeBlock*(src: BitStream, dest: BitStream) =
  # Save code bit length of each symbol
  # The first 256 symbols represent ascii characters
  # The remaining 256 symbols represent references to compressed tuples
  var codes {.noInit.}: array[512, CodeLen]

  for i in 0 ..< 256:
    let b = read[byte](src)
    codes[2*i]   = toBits(b and 0x0F)
    codes[2*i+1] = toBits(b and 0xF0)

  # Construct the decoding table
  var
    table {.noInit.}: array[2^15, uint16]
    entry: int
  for l in 0 ..< 16:
    for i, c in codes:
      if c.toNum == l:
        for _ in 1 .. 1 shl (15 - l):
          if entry >= 2^15:
            quit("Compressed data is not valid")
          table[entry] = i.uint16
          inc(entry)
  if entry != 2^15:
    quit("Compressed data is not valid")

  # Decode the block
  var
    nextBits = read[uint32](src)
    extraBits = 16

  let blockEnd = dest.pos + 65536

  while true:
    if dest.pos >= blockEnd: return
    var
      next15bits = nextBits shr (32 - 15)
      huffmanSymbol = table[next15bits]
      huffmanSymbolBitLength = codes[huffmanSymbol].toNum
    if huffmanSymbol <= 0:
      nextBits = nextBits shl huffmanSymbolBitLength
      extraBits -= huffmanSymbolBitLength
      while huffmanSymbol <= 0:
        huffmanSymbol = -huffmanSymbol
        huffmanSymbol += (nextBits shr 31)
        nextBits *= 2
        dec extraBits
        huffmanSymbol = table[huffmanSymbol]
    else:
      let decodedBitCount = huffmanSymbol and 15
      nextBits = nextBits shr decodedBitCount
      extraBits -= decodedBitCount
