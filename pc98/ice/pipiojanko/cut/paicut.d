/**
 * パイパイお雀娘連結ファイルカッター
 *
 */

import std.stdio;
import std.string;
import std.stream;

uint get_dword_le(ubyte[] p_in)
{
  return (
      ((p_in[1] << 24) & 0xff000000) +
      ((p_in[0] << 16) & 0xff0000) +
      ((p_in[3] <<  8) & 0xff00) +
       (p_in[2]        & 0xff)
      );
}

ushort get_word_le(ubyte[] p_in)
{
    return (
        ((p_in[1] <<  8) & 0xff00) +
         (p_in[0]        & 0xff)
        );
}

void cutter(ubyte[] input, ulong input_size)
{
  uint data_ofs;			// file size info offset
  uint data_size;			// file data size
  uint read_ofs;
  int i;
  char fnamez[13] = '\0';

  // data check
  if ("FILPACver1.00A" != cast(char[])input[0x02..0x10]) {
      return;
  }

  // file count
  uint count = get_word_le(input);

  writefln("+----------+-------+---------------+");
  writefln("| Offset   | Size  | Name          |");
  writefln("+----------+-------+---------------+");

  // split
  for (i=0 ; i < count; i++) {
    read_ofs = i * 0x20 + 0x10;
    fnamez[0..13] = cast(char[])input[read_ofs+0..read_ofs+13];

    data_size = get_dword_le(input[(read_ofs+0x0c)..(read_ofs+0x10)]);
    data_ofs = get_dword_le(input[(read_ofs+0x10)..(read_ofs+0x14)]);

    writefln("| 0x%06x | %5d | %12s |", data_ofs, data_size, fnamez);

    if (data_size == 0) {
      continue;
    }

    File outp = new File(fnamez, FileMode.OutNew);
    if (outp) {
      outp.writeExact(&input[data_ofs], data_size);
      delete outp;
    }
  }

  writefln("+--------+------+------------------+");
}

int main (char[][] args)
{
  foreach (arg; args[1 .. args.length]) {
    try {
      auto input_size = std.file.getSize(arg);
      ubyte[] input = cast(ubyte[])std.file.read(arg);
      cutter(input, input_size);
    } catch(Exception e) {
      writefln("catch %s", e.msg);
    }
  }
  return 0;
}
