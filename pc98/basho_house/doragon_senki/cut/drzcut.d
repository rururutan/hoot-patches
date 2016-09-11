import std.stdio;
import std.string;
import std.stream;

int main (char[][] args)
{
  foreach (arg; args[1 .. args.length]) {
    try {
      auto c_cnt = std.file.getSize(arg);

      if (c_cnt <= 0x30) {
        writefln("length too short!");
        continue;
      }

      auto input = cast(byte[])std.file.read(arg);
      ushort curofs, nextofs;
      char[][] farray = split(arg, ".");
      char[] outname;
      outname = farray[0];	// dos fileだから1つだけで良いと割り切る

      for (auto cnt = 0; cnt < 48; cnt+=2) {
        nextofs  = (input[cnt] & 0xff) + ((input[cnt+1] & 0xff) << 8);
//      writefln("cur : %04x next : %04x - length : %04x", curofs, nextofs, nextofs - curofs);
        char c[] = std.string.format(".%03x", cnt/2);
        File outp = new File(outname ~ c, FileMode.OutNew);
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
