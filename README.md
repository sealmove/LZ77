# Implementation of LZ77 algorithms
### **Motivation**
This project was motivated by the attempt to write an os-agnostic parser for Windows Prefetch files.  
Most parsers use the Windows API to decompress MAM data, which means they only work on Windows 8.1 & 10.

### **Generality of implementation**
I will try to make the implementation as general as possible, but for now I follow Microsoft's conventions.
