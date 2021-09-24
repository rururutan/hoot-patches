/**
 * MSX bsave header cutter
 *
 * 7byteのヘッダ
 * 00 : FE
 * 01 : ロードアドレス(LE)
 * 03 : エンドアドレス(LE)
 * 05 : ロードアドレス(LE)
 *
 */

import std.stdio;
import std.string;
import std.stream;

ushort get_word_le(ubyte* p_in)
{
    return (
        ((p_in[1] <<  8) & 0xff00) +
         (p_in[0]        & 0xff)
        );
}

void cutter(char[] name, ubyte[] input, ulong input_size)
{
  uint data_ofs;			// file size info offset
  uint data_end;			// file size info offset
  uint data_size;			// file data size

  if (input[0] != 0xfe) {
      writefln("illegal data.");
      return;
  }

  data_ofs  = get_word_le(&input[1]);
  data_end  = get_word_le(&input[3]);
  data_size = data_end - data_ofs + 1;
//  writefln("data ofs : 0x%04x data end : 0x%04x data size : 0x%04x", data_ofs, data_end, data_size);

    if (data_size > 0) {
        writefln("| 0x%04x | %5d |", data_ofs, data_size);

      File outp = new File(name, FileMode.OutNew);
      if (outp) {
        outp.writeExact(&input[7], data_size);
        delete outp;
      }
    }
}

// MBS→unicode変換API
extern(Windows) export int MultiByteToWideChar(
  uint   CodePage,
  uint   dwFlags,
  char*  lpMultiByteStr,
  int    cchMultiByte,
  wchar* lpWideCharStr,
  int    cchWideChar);

extern(Windows) export int WideCharToMultiByte(
  uint   CodePage,
  uint   dwFlags,
  wchar* lpWideCharStr,
  int    cchWideChar,
  char*  lpMultiByteStr,
  int    cchMultiByte,
  char*  lpDefaultChar,
  bool*  lpUsedDefaultChar);

wchar[] toWCS(char[] s)
{
  wchar[] result;
  result.length = MultiByteToWideChar(0, 0, s.ptr, s.length, null, 0);
  MultiByteToWideChar(0, 0, s.ptr, s.length, result.ptr, result.length);
  return result;
}

char[] toUtf8(char[] s)
{
  wchar[] utf16 = toWCS(s);
  char[] result;
  result.length = WideCharToMultiByte(65001, 0, utf16.ptr, utf16.length,
                                      null, 0, null, null);
  WideCharToMultiByte(65001, 0, utf16.ptr, utf16.length, result.ptr,
                      result.length, null, null);
    return result;
}

int main (char[][] args)
{
  writefln("+--------+-------+");
  writefln("| Offset | Size  |");
  writefln("+--------+-------+");

  foreach (arg; args[1 .. args.length]) {
    try {
      char fname[] = cast(char[])toUtf8(arg);
      auto input_size = std.file.getSize(fname);
      ubyte[] input = cast(ubyte[])std.file.read(fname);
      cutter(fname, input, input_size);
    } catch(Exception e) {
      writefln("catch %s", e.msg);
    }
  }
  writefln("+--------+-------+");
  return 0;
}
