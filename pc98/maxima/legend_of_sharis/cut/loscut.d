/**
 * Legend of sharis cutter
 *
 * 実データの単純連結形式
 * アーカイブヘッダ/データ識別子は存在しないので'26 00'を目印にカットする
 *
 */

import std.stdio;
import std.string;
import std.stream;

uint get_dword(byte[] p_in)
{
  return (
      ((p_in[0] << 24) & 0xff000000) +
      ((p_in[1] << 16) & 0xff0000) +
      ((p_in[2] <<  8) & 0xff00) +
       (p_in[3]        & 0xff)
      );
}

ushort get_word(byte[] p_in)
{
    return (
        ((p_in[0] <<  8) & 0xff00) +
         (p_in[1]        & 0xff)
        );
}

void cutter(char[] name, byte[] input, ulong input_size)
{
  uint data_ofs;			// file size info offset
  uint data_size;			// file data size
  uint read_ofs = 0x02;
  int i;
  char fnamez[0x10] = '\0';

  writefln("+--------+------+------------------+");
  writefln("| Offset | Size | Name             |");
  writefln("+--------+------+------------------+");

  // data check
  if (input[0x00] == 0x26 && input[0x01] == 0x00 && input_size <= 2) {
      return;
  }

  // split
  do {
    for (;read_ofs < input_size; read_ofs++) {
      if (input[read_ofs] == 0x26 && input[read_ofs+1] == 0x00) {
        break;
      }
    }

    data_size = read_ofs - data_ofs;
    if (data_size) {
      if ((input[read_ofs-1] & 0xff) == 0xfc) {
      std.string.sformat(fnamez, "%s%02d%s", "BGM", i, ".O");
      writefln("| 0x%04x | %4d | %12s |", data_ofs, data_size, fnamez);

      File outp = new File(fnamez, FileMode.OutNew);
      if (outp) {
        outp.writeExact(&input[data_ofs], data_size);
        delete outp;
      }
      } else {
//      writefln("read_ofs : %5x %x", read_ofs, input[read_ofs-1]);
        read_ofs++;
        continue;
      }
    }
    data_ofs = read_ofs;
    read_ofs++;
    i++;
  } while(input_size > read_ofs);

  writefln("+--------+------+------------------+");
}

int main (char[][] args)
{
  try {
    auto input_size = std.file.getSize("BGM.DAT");
    byte[] input = cast(byte[])std.file.read("BGM.DAT");
    cutter("BGM.DAT", input, input_size);
  } catch(Exception e) {
    writefln("catch %s", e.msg);
  }
  return 0;
}
