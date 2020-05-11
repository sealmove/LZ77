## Implementation of LZ77+Huffman Decompression Algorithm
## Based on Microsoft documents: MS-XCA (2.2) & MS-FRS2 (3.1.1.1.3)

import math, lz77/[bitstream, huffman]

proc decompressHuffman*(input: seq[byte], output: var seq[byte]) =
  let
    blockEnd = output.len + 65536
    tree = newHuffmanTree(input[0 ..< 256])
    stream = newBitStream(input[256 .. ^1])

  while output.len < blockEnd and not stream.atEnd:
    echo output.len
    var symbol = tree.decode(stream)
    if symbol < 256:
      output.add(symbol.byte)
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

      for _ in 0 ..< len:
        let l = output.len
        let b = output[l - dist.int]
        output.add(b)

proc decompressMam*(bytes: seq[byte], size: SomeInteger): seq[byte] =
  while result.len < size.int:
    decompressHuffman(bytes, result)
