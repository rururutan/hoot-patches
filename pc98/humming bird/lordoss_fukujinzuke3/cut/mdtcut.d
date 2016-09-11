/**
 * File cutter
 */
import std.stdio;
import std.string;
import std.stream;

void cutter(char[] arg) {
  auto c_cnt = std.file.getSize(arg);
  auto input = cast(byte[])std.file.read(arg);
  char[] outbase = std.path.getName(arg);
  int f_cnt = 0;

  uint startofs, curofs, nextofs;
  startofs  =  (input[0x00] & 0xff)       + ((input[0x01] & 0xff) << 8);
  startofs += ((input[0x02] & 0xff) <<16) + ((input[0x03] & 0xff) <<24);
  curofs = startofs;

  for (auto cnt = 0x04; ; cnt+=0x04) {
    if (cnt > startofs) {
      break;
    }

    if (cnt == startofs) {
        nextofs = c_cnt;
    } else {
        nextofs  = ((input[cnt    ] & 0xff)     ) + ((input[cnt + 1] & 0xff) << 8);
        nextofs += ((input[cnt + 2] & 0xff) <<16) + ((input[cnt + 3] & 0xff) <<24);
    }

    writefln("cur : %04x next : %04x - length : %04x", curofs, nextofs, nextofs - curofs);
    if (nextofs != curofs) {
      char [256] outname = '\0';
      std.string.sformat(outname, "%s%02d%s", outbase, f_cnt, ".MLD");
      writefln("name : %s\n", outname);
      File outp = new File(outname, FileMode.OutNew);
      if (outp) {
        outp.writeExact(&input[curofs], (nextofs - curofs));
        delete outp;
      }
      f_cnt++;
    }
    curofs = nextofs;
  }
}

int main (char[][] args)
{
  foreach (arg; args[1 .. args.length]) {
    try {
      cutter(arg);
    } catch(Exception e) {
      writefln("catch %s", e.msg);
    }
  }
  return 0;
}
