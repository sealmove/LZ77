## Implementation of LZ77+Huffman Decompression Algorithm
## Based on Microsoft documents: MS-XCA (2.2) & MS-FRS2 (3.1.1.1.3)

import math, lz77/[bitstream, huffman]

proc huffmanDecompress*(bytes: seq[byte]): tuple[count: int, data: seq[byte]] =
  let
    tree = newHuffmanTree(bytes[0 .. 255])
    stream = newBitStream(bytes[256 .. ^1])
    blockEnd = result.data.len + 65536

  while result.data.len < blockEnd:
    var symbol = tree.decode(stream)
    if symbol < 256:
      result.data.add(symbol.byte)
    else:
      let distBitLen = int((symbol and 0xF0) shr 4)
      var len = symbol and 0x0F
      let dist = (1'u32 shl distBitLen) + stream.peek(distBitLen)
      if len == 15:
        len = stream.currentByte.int + 15
        stream.pos += 1
        if len == 270:
          len = stream.currentWord.int
          stream.pos += 2
          if len < 15:
            quit("The compressed data is invalid")

      stream.skip(distBitLen)
      len += 3

      let l = result.data.len
      for i in 0 ..< len:
        let b = result.data[l - dist.int + i]
        result.data.add(b)
  result.count = 256 + stream.pos
