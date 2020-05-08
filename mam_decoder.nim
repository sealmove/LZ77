## Implementation of Microsoft's LZ77+Huffman Decompression Algorithm
## Based on section 2.2 of the spec linked below:
## https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-xca/a8b7cb0a-92a6-4187-a23b-5e14273b96f8

import math, bstreams, sequtils, strutils

type
  CodeLenBits {.size: sizeof(cint).} = enum
    A, B, C, D
  CodeLen = set[CodeLenBits]

proc toNum(bits: CodeLen): int = cast[cint](bits)
proc toBits(b: byte): CodeLen = cast[CodeLen](b)

proc decode*(compressedBytes: seq[byte]): seq[byte] =
  let src = WordBitStream(data: compressedBytes)

  block decoding:
    while true:
      # Save code bit length of each symbol
      # The first 256 symbols represent ascii characters
      # The remaining 256 symbols represent references to compressed tuples
      var codes {.noInit.}: array[512, CodeLen]

      for i in 0 ..< 256:
        let b = src.read(8).byte
        codes[2*i]   = toBits(b and 0x0F)
        codes[2*i+1] = toBits((b and 0xF0) shr 4)

      # Construct the decoding table
      var
        table {.noInit.}: array[2^15, int32]
        entry: int
      for l in 1 ..< 16:
        for i, c in codes:
          if c.toNum == l:
            for _ in 1 .. 1 shl (15 - l):
              if entry >= 2^15:
                quit("1. Compressed data is not valid")
              table[entry] = i.int32
              inc(entry)
      if entry != 2^15:
        quit("2. Compressed data is not valid")

      # Decode the block
      let blockEnd = result.len + 65536

      while true:
        if result.len >= blockEnd: break
        if not src.hasLeft(15): break decoding
        var huffmanSymbol = table[src.peek(15)]
        let huffmanSymbolBitLength = codes[huffmanSymbol].toNum
        if not src.hasLeft(huffmanSymbolBitLength): break decoding
        discard src.read(huffmanSymbolBitLength)
        if huffmanSymbol < 256:
          result.add(huffmanSymbol.byte)
        else:
          huffmanSymbol -= 256
          let matchOffsetBitLength = huffmanSymbol shr 4
          var matchLength = huffmanSymbol and 15

          if matchLength == 15:
            align(src)
            if not src.hasLeft(8): break decoding
            matchLength = src.read(8).int32 + 15
            if matchLength == 270:
              align(src)
              if not src.hasLeft(16): break decoding
              matchLength = src.read(16).int32
              if matchLength < 15:
                quit("The compressed data is invalid")
          matchLength += 3

          if not src.hasLeft(matchOffsetBitLength): break decoding
          let matchOffset =  (1 shl matchOffsetBitLength) +
                             src.read(matchOffsetBitLength).int

          for _ in 0 ..< matchLength:
            result.add(result[result.len - matchOffset])
