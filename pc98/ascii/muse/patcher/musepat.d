/**
 *
 * hoot用にHSYNC待ちとVersionチェックの部分にパッチを当てる
 *
 *
 */

import std.stdio;
import std.string;
import std.stream;

bool patch_hsync(ubyte[] input, ulong input_size)
{
	for (uint read_ofs = 0; read_ofs < (input_size -0x0d); read_ofs++) {
		if (input[read_ofs  ] == 0xba && input[read_ofs+1] == 0x60 &&
			input[read_ofs+2] == 0x00 && input[read_ofs+3] == 0xec) {
			if ((input[read_ofs + 6]&0xff) == 0x75) {
				input[read_ofs+0x06] = 0x90;
				input[read_ofs+0x07] = 0x90;
				input[read_ofs+0x0b] = 0x90;
				input[read_ofs+0x0c] = 0x90;
				return true;
			}
		}
	}
	return false;
}

bool patch_dosver(ubyte[] input, ulong input_size)
{
	for (uint read_ofs = 0; read_ofs < (input_size -0x08); read_ofs++) {
		if (input[read_ofs  ] == 0xb4 && input[read_ofs+1] == 0x30 &&
			input[read_ofs+2] == 0xcd && input[read_ofs+3] == 0x21) {
			if (input[read_ofs+0x06] == 0x03) {
				input[read_ofs+0x06] = 0x05;
				return true;
			}
		}
	}
	return false;
}

void rename_file(char[] file_name)
{
	char fnamez[0x10] = '\0';
	std.string.sformat(fnamez, "%s%s", file_name, ".old");
	rename(&file_name[0], &fnamez[0]);
	writefln("renameed %s -> %s", file_name, fnamez);
}

int main (char[][] args)
{
	try {
		writefln("Muse driver patch tool for hoot.");

		if (args.length <= 1) {
			throw new Exception("need file name.");
		}

		auto input_size = std.file.getSize(args[1]);
		ubyte[] input = cast(ubyte[])std.file.read(args[1]);

		bool change = false;

		if (patch_hsync(input, input_size) == true) {
			change = true;
			writefln("found hsync wait.");
		}

		if (patch_dosver(input, input_size) == true) {
			change = true;
			writefln("found version check.");
		}

		if (change == true) {
			rename_file(args[1]);

			File outp = new File(args[1], FileMode.OutNew);
			if (outp) {
				writefln("patched file.");
				outp.writeExact(cast(void*)input, input_size);
				delete outp;
			}
		}
	} catch (Exception e) {
		writefln("catch : %s", e.msg);
		return -1;
	}
	return 0;
}

