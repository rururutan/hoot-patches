/**
 * File decoder for BonnoYobikou
 *
 */
import std.stdio;
import std.string;
import std.stream;

/**
 * 暗号化デコード
 * データをNot + 1するだけ...
 *
 * @param arg filename
 *
 */
void decode(char[] arg) {
  auto c_cnt = std.file.getSize(arg);
  auto input = cast(ubyte[])std.file.read(arg);

  for (auto cnt = 0x00; cnt < c_cnt; cnt+=0x01) {
    ubyte data = input[cnt] & 0xff;
    ulong ld = ~cast(ulong)data;
    data = cast(ubyte)(ld + 1);
    input[cnt] = data;
  }

  char[] outbase = std.path.getName(arg);
  char[256] outname = '\0';
  std.string.sformat(outname, "%s%s", outbase, ".org");
  rename(&arg[0], &outname[0]);
  writefln("name : %s\n", arg);
  File outp = new File(arg, FileMode.OutNew);
  if (outp) {
    outp.writeExact(&input[0], c_cnt);
    delete outp;
  }
}

int main (char[][] args)
{
  foreach (arg; args[1 .. args.length]) {
    try {
      decode(arg);
    } catch(Exception e) {
      writefln("catch %s", e.msg);
    }
  }
  return 0;
}
