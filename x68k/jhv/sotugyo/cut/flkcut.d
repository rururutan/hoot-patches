/**
 * File cutter
 */
import std.stdio;
import std.string;
import std.stream;


uint get_dword_be(ubyte* p_in)
{
  return (
      ((p_in[0] << 24) & 0xff000000) +
      ((p_in[1] << 16) & 0xff0000) +
      ((p_in[2] <<  8) & 0xff00) +
       (p_in[3]        & 0xff)
      );
}

ushort get_word_be(ubyte* p_in)
{
    return (
        ((p_in[0] <<  8) & 0xff00) +
         (p_in[1]        & 0xff)
        );
}

void cutter(char[] arg) {
  auto c_cnt = std.file.getSize(arg);
  auto input = cast(ubyte[])std.file.read(arg);

  uint curofs, nextofs, headerofs = 0, nameofs = 0, fsize;

  curofs = get_dword_be(&input[headerofs]) * 0x10;

  for (;;) {

    nameofs = headerofs + 4;

    if (input[nameofs] == 0x00) {
      break;
    }

    headerofs += 0x10;
    nextofs =  get_dword_be(&input[headerofs]) * 0x10;

//    writefln("cur : %04x next : %04x - length : %04x", curofs+0x200, nextofs+0x200, (nextofs - curofs));
    string outname = cast(char[])input[nameofs..nameofs+13];
    writefln("name : %s", outname);
    File outp = new File(outname, FileMode.OutNew);
    if (outp) {
      outp.writeExact(&input[curofs+0x200], (nextofs - curofs));
      delete outp;
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
