import algorithm
type
  codeSizeBits {.size: sizeof(cint).} = enum
    A, B, C, D
  codeSize = set[codeSizeBits]
  Code = tuple[v: byte, l: codeSize]

proc toNum(bits: codeSize): int = cast[cint](bits)
proc toBits(num: byte): codeSize = cast[codeSize](num)

proc cmp(x, y: Code): int =
  if x.l > y.l: -1
  elif x.l == y.l: 0
  else: 1

proc decode*(src: seq[byte]): seq[byte] =
  # --- Bit sizes for each code to be used for the corresponding value ---
  # The first 256 values are the ascii characters
  # The remaining 256 values represent references to compressed tuples
  let codes {.noInit.}: array[512, Code]

  for i, b in src:
    codes[2*i] = (2*i, toBits(b and 0x0F))
    codes[2*i+1] = (2*i+1, toBits(b and 0xF0))

  codes.sort(cmp)
