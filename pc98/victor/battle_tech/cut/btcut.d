/**
 * BT cutter
 *
 * 実データの単純連結形式
 * 曲データは先頭2byteがサイズなのでそれに従う
 *
 */

import std.stdio;
import std.string;
import std.stream;

ushort get_word_le(byte[] p_in)
{
    return (
        ((p_in[1] <<  8) & 0xff00) +
         (p_in[0]        & 0xff)
        );
}

void cutter(char[] name, byte[] input, ulong input_size)
{
  uint data_ofs;			// file size info offset
  uint data_size;			// file data size
  uint read_ofs;
  int i;
  char fnamez[0x10] = '\0';

  writefln("+--------+------+------------------+");
  writefln("| Offset | Size | Name             |");
  writefln("+--------+------+------------------+");

  // get count
  uint data_head = get_word_le(input);
//  writefln("data_head : %x\n", data_head);

  // split
  do {
    data_ofs  = get_word_le(input[read_ofs..read_ofs+2]);
    data_size = get_word_le(input[data_ofs..data_ofs+2]);
//    writefln("read ofs : 0x%04x data ofs : 0x%04x data size : 0x%04x", read_ofs, data_ofs, data_size);

    if (data_size > 1) {
      std.string.sformat(fnamez, "%s.%03d", "SND", i);
      writefln("| 0x%04x | %4d | %12s |", data_ofs, data_size, fnamez);

      File outp = new File(fnamez, FileMode.OutNew);
      if (outp) {
        outp.writeExact(&input[data_ofs], data_size);
        delete outp;
      }
    } else {
      // 例外:音色ファイル
      data_size = input_size - data_ofs;
      std.string.sformat(fnamez, "%s.%s", "SND", "TON");
      writefln("| 0x%04x | %4d | %12s |", data_ofs, data_size, fnamez);

      File outp = new File(fnamez, FileMode.OutNew);
      if (outp) {
        outp.writeExact(&input[data_ofs], data_size);
        delete outp;
      }
      break;
    }
    read_ofs += 2;
    i++;
  } while(input_size > data_ofs || data_head > read_ofs);

  writefln("+--------+------+------------------+");
}

const string TARGET_FILE = "SND.DAT";

int main (char[][] args)
{
  try {
    auto input_size = std.file.getSize(TARGET_FILE);
    byte[] input = cast(byte[])std.file.read(TARGET_FILE);
    cutter(TARGET_FILE, input, input_size);
  } catch(Exception e) {
    writefln("catch %s", e.msg);
  }
  return 0;
}
