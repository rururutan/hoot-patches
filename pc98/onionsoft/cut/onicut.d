/*
  ONION SOFTWARE (*.ES / *.EXE) cutter

  ファイルリストのoffset
    先頭2~4byte。計算方法はソース参照

  ファイルリストの構造
    ファイル名(NULL終端) x ファイル数(""が来たら終わり)
    ファイル情報 x ファイル数

    の順で並んでいる。
    ファイル数の取得方法はNULL文字列が出るまでファイル名を辿っていくしか無い。

  ファイル情報の構造(6byte)
    WORD フラグ
    WORD サイズ1
    WORD サイズ2(上と同じ)

    恐らく圧縮対応させる為のフラグ/圧縮サイズ/オリジナルサイズを入れることを
    想定していたのだろうが、機能していない模様。このプログラムではサイズ1を使用。

 */

import std.stdio;
import std.string;
import std.stream;

void cutter(char[] name, byte[] input, ulong input_size)
{
  static const ulong FILEINFO_SIZE = 6;
  struct esfile {
    ushort size;
    string name;
  };
  ushort fn_ofs;	// file name info offset
  ushort fs_ofs;	// file size info offset
  ushort fd_ofs;	// file data offset

  // file check
  if (input[0] != 'M' && input[1] != 'Z') {
    writefln("%s : not onion's archive!", name);
    return;
  }

  // file list offsetの取得
  fn_ofs  = ((input[3] << 8) & 0xff00 | input[2] & 0xff)
         +((((input[5] << 8) & 0xff00 | input[4] & 0xff) - 1) << 9);

  // 総file数+ファイル名の取得
  auto totalcount = 0;	// total file count
  esfile fileinfo[];
  ulong workofs = fn_ofs + 4;	// +4は固定ヘッダ
  while((workofs < input_size && (input[workofs] != 0))) {
    fileinfo.length = fileinfo.length + 1;
    fileinfo[totalcount].name = std.string.toString(cast(char*)&input[workofs]);
    workofs += fileinfo[totalcount].name.length + 1;
    totalcount++;
  }

  fs_ofs = ++workofs;
  fd_ofs = fs_ofs + (FILEINFO_SIZE * totalcount);

  writefln("\n[%s]\nfile name     : offset  : size\n-------------------------------", name);

  // 展開
  ulong dataofs = fd_ofs;
  for (auto cnt =0; cnt < totalcount; cnt++) {
    fileinfo[cnt].size = (input[workofs + 3] << 8) & 0xff00;
    fileinfo[cnt].size += input[workofs + 2] & 0xff;
    writefln("%13s : 0x%05x : %5d", fileinfo[cnt].name, dataofs, fileinfo[cnt].size);
    File outp = new File(fileinfo[cnt].name, FileMode.OutNew);
    if (outp) {
      outp.writeExact(&input[dataofs], fileinfo[cnt].size);
      delete outp;
    }
    dataofs += fileinfo[cnt].size;
    workofs += FILEINFO_SIZE;
  }
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
