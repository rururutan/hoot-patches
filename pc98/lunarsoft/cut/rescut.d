/**
 * リザレクト cutter
 *
 * 0x000 - 0x0ff ファイルサイズ(DWORD)
 *               サイズが0なら終了
 * 0x100 -       実データ
 *
 */

import std.stdio;
import std.string;
import std.stream;

ushort get_word(byte[] p_in)
{
  return ((p_in[1] << 8) & 0xff00) + (p_in[0] & 0xff);
}

uint get_dword(byte[] p_in)
{
  return (
    ((p_in[3] << 24) & 0xff000000) +
    ((p_in[2] << 16) & 0xff0000) +
    ((p_in[1] <<  8) & 0xff00) +
     (p_in[0] & 0xff));
}

void cutter(char[] name, byte[] input, ulong input_size)
{
  uint read_ofs;			// file size info offset
  ushort data_prev;			// file data offset
  ushort data_size;			// file data offset
  ushort data_ofs = 0x100;	// file data offset
  int i = 0;
  string fname;

  // 展開
  do {
    data_size = get_dword(input[(i*4)..(i*4)+4]);
    fname = std.string.format("_%02d.DAT", i);

    if (data_size) {
      writefln("%s - %5d byte", fname, data_size);
      File outp = new File(fname, FileMode.OutNew);
      if (outp) {
        outp.writeExact(&input[data_ofs], data_size);
        delete outp;
      }
      data_ofs += data_size;
      i++;
    }
  } while(data_size && i < 0x80);
}

void usage(char[] name)
{
  writefln("usage: %s [filename]", name);
}

int main (char[][] args)
{
  if (args.length == 1) {
    usage(args[0]);
  }

  foreach (arg; args[1 .. args.length]) {
    try {
      auto input_size = std.file.getSize(arg);
      byte[] input = cast(byte[])std.file.read(arg);
      cutter(arg, input, input_size);
    } catch(Exception e) {
      writefln("catch %s", e.msg);
    }
  }
  return 0;
}
