/**
 * File cutter
 */
import std.stdio;
import std.string;
import std.stream;

void cutter(char[] arg) {
  auto c_cnt = std.file.getSize(arg);
  auto input = cast(byte[])std.file.read(arg);
  int f_cnt = 0;

  uint nameofs = 0, sizeofs = 0xc;
  uint fileofs = 0, nextofs = 0;
  char [13] outname = '\0';

	nextofs  =  (input[sizeofs+0] & 0xff)       + ((input[sizeofs+1] & 0xff) << 8);
	nextofs += ((input[sizeofs+2] & 0xff) <<16) + ((input[sizeofs+3] & 0xff) <<24);

	while(input[nameofs] != 0) {
	  fileofs = nextofs;

	nextofs  =  (input[sizeofs+0x10] & 0xff)       + ((input[sizeofs+0x11] & 0xff) << 8);
	nextofs += ((input[sizeofs+0x12] & 0xff) <<16) + ((input[sizeofs+0x13] & 0xff) <<24);

	  writefln("sizeofs: %04x fofs: %04x nofs: %04x fsize: %04x", sizeofs, fileofs, nextofs, nextofs - fileofs);

	  for (int i=0; i < 12; i++) {
		  outname[i] = input[nameofs + i];
	  }

      writefln("name : %s\n", outname);
      File outp = new File(outname, FileMode.OutNew);
      if (outp) {
        outp.writeExact(&input[fileofs], (nextofs - fileofs));
        delete outp;
      }

	  nameofs += 0x10;
	  sizeofs += 0x10;
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
