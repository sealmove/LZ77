import bitstream

type HuffmanTree = ref object

# The input is 256 bytes.
# It consists of 512 numbers that represent bit lengths of symbols.
# Each number is stored in 4 bits.
# For each bytes, the least significant bits should be read first.
# The first 256 symbols represent ascii characters.
# The remaining 256 symbols represent references to compressed tuples.
proc newHuffmanTree*(input: seq[byte]): HuffmanTree = discard

proc read(tree: HuffmanTree): int = discard
