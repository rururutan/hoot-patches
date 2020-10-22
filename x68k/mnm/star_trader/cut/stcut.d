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
      ulong curofs, nextofs;
      char[][] farray = split(arg, ".");
      char[] outname;
      outname = farray[0];	// dos fileだから1つだけで良いと割り切る

      curofs  =  (input[3] & 0xff)        + ((input[2] & 0xff) <<  8)
              + ((input[1] & 0xff) << 16) + ((input[0] & 0xff) << 24);

      for (auto cnt = 4; cnt <= 0x30; cnt+=4) {
        if ( cnt == 0x30) {
        nextofs  = input.length;
        } else {
        nextofs  =  (input[cnt+3] & 0xff)        + ((input[cnt+2] & 0xff) << 8)
                 + ((input[cnt+1] & 0xff) << 16) + ((input[cnt  ] & 0xff) << 24);
        }
        writefln("cur : %05x next : %05x - length : %04x", curofs, nextofs, nextofs - curofs);
        char c[] = std.string.format("%02d", cnt/4);
        File outp = new File(outname ~ c ~ ".m", FileMode.OutNew);
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
