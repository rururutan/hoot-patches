// 銀河鉄道の旅 cutter
import std.stdio;
import std.string;
import std.stream;

static uint getDwordBe(ubyte* data)
{
    uint ret;
    ret = data[0];
    ret+= data[1] << 8;
    ret+= data[2] <<16;
    ret+= data[3] <<24;

    return ret;
}

static uint getWordBe(ubyte* data)
{
    uint ret;
    ret = data[0];
    ret+= data[1] << 8;

    return ret;
}

int main (char[][] args)
{
  foreach (arg; args[1 .. args.length]) {
    try {
      auto c_cnt = std.file.getSize(arg);
      auto input = cast(byte[])std.file.read(arg);
      uint offset;
      ushort size;
      ushort filenum = getWordBe(cast(ubyte*)input.ptr);

      for (auto cnt = 2; cnt < (2 + filenum * 0x16); cnt+=0x16) {
        offset = getDwordBe(cast(ubyte*)input.ptr +(cnt + 0x0e));
        size   = getWordBe(cast(ubyte*)input.ptr +(cnt + 0x12));
        writefln("cur : 0x%08x - length : %04d", offset, size);
        string filename = toString(cast(char*)(input.ptr + cnt));
        File outp = new File(filename, FileMode.OutNew);
        if (outp) {
          outp.writeExact(&input[offset], size);
          delete outp;
        }
      }
    } catch(Exception e) {
      writefln("catch %s", e.msg);
    }
  }
  return 0;
}
