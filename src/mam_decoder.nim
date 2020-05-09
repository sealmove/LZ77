## Implementation of Microsoft's LZ77+Huffman Decompression Algorithm
## Based on section 2.2 of the spec linked below:
## https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-xca/a8b7cb0a-92a6-4187-a23b-5e14273b96f8

import math, wordbitstream, sequtils, strutils

type
  CodeLenBits {.size: sizeof(cint).} = enum
    A, B, C, D
  CodeLen = set[CodeLenBits]

proc toNum(bits: CodeLen): int = cast[cint](bits)
proc toBits(b: byte): CodeLen = cast[CodeLen](b)

proc decode*(compressedBytes: seq[byte]): seq[byte] =
  let src = newWordBitStream(compressedBytes)

  while true:
    block decoding:
      # Save code bit length of each symbol
      # The first 256 symbols represent ascii characters
      # The remaining 256 symbols represent references to compressed tuples
      var codes {.noInit.}: array[512, CodeLen]

      for i in 0 ..< 256:
        let b = src.read(8).byte
        codes[2*i]   = toBits(b and 15)
        codes[2*i+1] = toBits(b shr 4)

      # Construct the decoding table
      var
        table {.noInit.}: array[2^15, uint16]
        entry: int
      for l in 1 ..< 16:
        for i, c in codes:
          if c.toNum == l:
            for _ in 1 .. 1 shl (15 - l):
              if entry >= 2^15:
                quit("1. Compressed data is not valid")
              table[entry] = i.uint16
              inc(entry)
      if entry != 2^15:
        quit("2. Compressed data is not valid")

      # Decode the block
      let blockEnd = result.len + 65536

      while true:
        if result.len >= blockEnd: break
        var huffmanSymbol = table[src.peek(15)]
        let huffmanSymbolBitLength = codes[huffmanSymbol].toNum
        discard src.read(huffmanSymbolBitLength)
        if huffmanSymbol < 256:
          stdout.write $huffmanSymbol & " "
        else:
          huffmanSymbol -= 256
          let matchDistanceBitLength = huffmanSymbol shr 4
          var matchLength = huffmanSymbol and 15

          if matchLength == 15:
            matchLength = src.read(8).uint16 + 15
            if matchLength == 270:
              matchLength = src.read(16).uint16
              if matchLength < 15:
                quit("The compressed data is invalid")
          matchLength += 3

          let matchDistance = src.read(matchDistanceBitLength.int) +
                            (1'u32 shl matchDistanceBitLength)

          for _ in 0'u16 ..< matchLength:
            result.add(result[^matchDistance.int])
