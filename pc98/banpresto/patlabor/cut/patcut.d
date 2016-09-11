import std.stdio;
import std.string;
import std.stream;

int main (char[][] args)
{
  foreach (arg; args[1 .. args.length]) {
    try {
      auto c_cnt = std.file.getSize(arg);

      if (c_cnt <= 0x200) {
        writefln("length too short!");
        continue;
      }

      auto input = cast(byte[])std.file.read(arg);
      ushort curofs = 0x200, nextofs;
      char[13] outname;

      for (auto cnt = 0; cnt < 0x200; cnt+=0x10) {
        nextofs  = (input[cnt + 0x10] & 0xff) + ((input[cnt + 0x11] & 0xff) << 8);
        nextofs <<= 4;
        if (nextofs == 0) {
          break;
        }
        nextofs += 0x200;
        writefln("cur : %04x next : %04x - length : %04x", curofs, nextofs, nextofs - curofs);
        byte[] nametemp = cast(byte[])outname;
        nametemp[0 .. 12] = input[cnt+4 .. cnt+16];
        outname[12] = '\0';
        writefln("name : %s\n", outname);
        File outp = new File(outname, FileMode.OutNew);
        if (outp) {
          outp.writeExact(&input[curofs], (nextofs - curofs));
          delete outp;
        }
        curofs = nextofs;
      }
    } catch(Exception e) {
      writefln("catch %s", e.msg);
    }
  }
  return 0;
}
