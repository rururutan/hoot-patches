#ifndef D88_H_
#define D88_H_
#pragma once

#include <stdio.h>
#include <stdint.h>

class D88
{
public:
	enum {
		MAX_DISK = 64,
	};
	enum {
		TYPE_2D  = 0x00,
		TYPE_2DD = 0x10,
		TYPE_2HD = 0x20,
	};
public:
	D88();
	~D88();

	bool SetFile(char *_fname);
	bool SelectDisk(int _diskno);
	void SetRecordRange(int _min, int _max);

	int GetNumDisk() const;
	int GetCurrentDisk() const;
	const char *GetDiskName() const;
	int GetDiskType() const;

	int ReadDATA1(int _trk, int _C, int _H, int _R, int _N, uint8_t *_buffer, int _size);
	int ReadDATA(int _trk, int _C, int _H, int _R, int _N, uint8_t *_buffer, int _size);
	int ReadID(int _trk, uint8_t *_buffer, int _size);

private:
	FILE *m_fp;

	int m_curdisk;
	int m_numdisk;

	int m_minrec;
	int m_maxrec;

	int m_disk_offset[MAX_DISK];

	int m_disksize;
	int m_curdisk_offset;
	int m_trk[164];

	int m_disktype;
	char m_diskname[16+1];
};

#endif // D88_H_
