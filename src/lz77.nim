## Implementation of Microsoft's LZ77+Huffman Decompression Algorithm
## Based on section 2.2 of [MS-XCA] document

import math, bitstream, huffman, sequtils

proc decompress*(bytes: seq[byte]): tuple[processedCnt: int, data: seq[byte]] =
  let
    tree = newHuffmanTree(bytes[0 .. 255])
    stream = newBitStream(bytes[256 .. ^1])
    blockEnd = result.len + 65536

  while result.data.len < blockEnd:
    var symbol = tree.read(stream)
    if symbol < 256:
      result.add(symbol.byte)
    else:
      let distBitLen = int((symbol and 0xF0) shr 4)
      var len = symbol and 0x0F
      let matchDistance = stream.peek(distBitLen) + (1'u32 shl distBitLen)
      if len == 15:
        len = stream.read(8).uint16 + 15
        if len == 270:
          len = stream.read(16).uint16
          if len < 15:
            quit("The compressed data is invalid")

      stream.skip(distBitLen)
      len += 3

      for _ in 0 ..< len:
        result.add(result[^matchDistance.int])
  result.processedCnt = 256 + stream.pos
