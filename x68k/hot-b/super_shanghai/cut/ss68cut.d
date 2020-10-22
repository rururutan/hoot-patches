/**
 * SuperShanghai 68K cutter
 *
 * ヘッダ付単純連結形式 + LZ。LZは別途デコードの事。
 * ヘッダにはデータサイズがWORD(BE)で書かれている。
 * ヘッダ長は0x28固定
 *
 */

import std.stdio;
import std.string;
import std.stream;

uint get_word_be(ubyte[] p_in)
{
	return (
		(p_in[0] <<  8) +
		(p_in[1]      )
		);
}

void cutter(char[] arg)
{
	auto input_size = std.file.getSize(arg);
	auto input = cast(ubyte[])std.file.read(arg);
	string out_base = std.path.getName(arg);

	uint data_ofs;			// file size info offset
	uint data_size;			// file data size
	uint head_ofs;
	int i;
	string out_name;

	writefln("+---------+-------+----------------+");
	writefln("| Offset  | Size  | Name           |");
	writefln("+---------+-------+----------------+");

	// get count
	data_ofs = 40;
	head_ofs = 00;

	// split
	do {
		data_size = get_word_be(input[head_ofs..head_ofs+2]);
//		writefln("header ofs : 0x%04x data ofs : 0x%04x data size : 0x%04x", head_ofs, data_ofs, data_size);

		if (data_size > 0) {
			out_name = std.string.format("%s.%03d", out_base, i);
			writefln("| 0x%05x | %5d | %14s |", data_ofs, data_size, out_name);

			File outp = new File(out_name, FileMode.OutNew);
			if (outp) {
				outp.writeExact(&input[data_ofs], data_size);
				delete outp;
			}
		} else {
			break;
		}
		head_ofs += 2;
		data_ofs += data_size;
		i++;
	} while(input_size > data_ofs);

  writefln("+--------+------+------------------+");
}

int main (string[] args)
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
