#include <stdio.h>
#include <string.h>

#include "d88.h"

//#define STRICT_CHECK

#define D88_HEADER_SIZE (0x20 + 4 * 164)	// D88ヘッダのサイズ
#define D88_NAME	(0)						// ディスク名の位置
#define D88_PROTECT	(0x1a)					// ライトプロテクトの有無の位置 (0:なし 1:あり)
#define D88_TYPE	(0x1b)					// ディスクの種類の位置(00H:2D 10H:2DD 20H:2HD)
#define D88_SIZE	(0x1c)					// ディスクのサイズの位置(DWORD)
#define D88_TRACK	(0x20)					// トラックデータテーブルの先頭の位置

// dword値を取得
static int GetInt(unsigned char *_p)
{
	int ret;

	ret = (_p[3]<<24) + (_p[2]<<16) + (_p[1]<<8) + _p[0];

	return ret;
}

// word値を取得
static int GetShort(unsigned char *_p)
{
	int ret;

	ret = (_p[1]<<8) + _p[0];

	return ret;
}

// コンストラクタ
D88::D88()
{
	m_fp = NULL;

	m_minrec = 1;
	m_maxrec = 16;

	m_curdisk = -1;
	m_numdisk = 0;
	m_disktype = -1;

	m_diskname[16] = '\0';
}

// デストラクタ
D88::~D88()
{
	if (m_fp) fclose(m_fp);
}

// D88ファイルの準備
bool D88::SetFile(char *_fname)
{
	// 引数指定がないときは、選択を解除する
	if (_fname == NULL)
	{
		fclose(m_fp);
		m_fp = NULL;
		m_numdisk = 0;
		m_curdisk = -1;
		m_disktype = -1;
		return true;
	}

	// D88ファイルオープン(バイナリモード/読み込み)
	m_fp = fopen(_fname, "rb");
	if (m_fp == NULL) return false;

	int offset = 0;

	// ディスク枚数分ループ
	for (m_numdisk = 0; m_numdisk < MAX_DISK; m_numdisk++)
	{
		int size;
		// D88ヘッダ部のメモリ確保
		unsigned char header[D88_HEADER_SIZE];
		// ディスク番号ごとのオフセット位置を格納
		m_disk_offset[m_numdisk] = offset;

		// 各ディスクの先頭へシーク
		fseek(m_fp, offset, SEEK_SET);
		size = fread(header, 1, D88_HEADER_SIZE, m_fp);
		// D88ヘッダのサイズ以下になったときに中断
		if (size != D88_HEADER_SIZE) break;
		// 次のD88ヘッダの位置を計算
		offset += GetInt(&header[D88_SIZE]);
	}
	return true;
}

// 最小/最大セクタ番号をセット
void D88::SetRecordRange(int _min, int _max)
{
	m_minrec = _min;
	m_maxrec = _max;
}

// 現在選択中のD88内のディスク数を返す
int D88::GetNumDisk() const
{
	return m_numdisk;
};

// 現在選択中のD88内のディスク番号を返す
int D88::GetCurrentDisk() const
{
	return m_curdisk;
};

// 指定したディスク番号のディスクを開く
bool D88::SelectDisk(int _diskno)
{
	unsigned char header[D88_HEADER_SIZE];

	// D88ファイルを開いてあるか?
	if (m_fp == NULL) return false;

	m_curdisk_offset = -1;

	m_curdisk = -1;
	m_disktype = -1;
	m_disksize = 0;
	m_diskname[0] = '\0';

	// 指定したディスクが実際の枚数より多い場合は中断
	if (_diskno > m_numdisk) return false;

	m_curdisk_offset = m_disk_offset[_diskno];

	// シーク
	fseek(m_fp, m_curdisk_offset, SEEK_SET);

	// D88ヘッダ部読み込み
	fread(header, 1, D88_HEADER_SIZE, m_fp);
	// 各トラックのオフセット位置を取得
	for (int trk = 0; trk<164; trk++)
	{
		m_trk[trk] = GetInt(&header[D88_TRACK + trk*4]);
	}

	// ディスクタイプを取得
	m_disktype = header[D88_TYPE];
	// ディスクサイズを取得
	m_disksize = GetInt(&header[D88_SIZE]);
	// ディスク名をコピー
	strncpy(m_diskname, (char *)&header[D88_NAME], 16);

	return true;
}

// ディスク名を返す
const char *D88::GetDiskName() const
{
	return m_diskname;
}

// ディスクタイプを返す
int D88::GetDiskType() const
{
	return m_disktype;
}

// ReadDATA1
// 指定した1セクタを読み込む
int D88::ReadDATA1(int _trk, int _C, int _H, int _R, int _N, unsigned char *_buffer, int _size)
{
	// ファイルを開いてない場合は戻る
	if (m_fp == NULL) return 0;

	// トラック指定がおかしいときは戻る
	if (_trk >= 164 || m_trk[_trk] == 0 || m_trk[_trk] > m_disksize) return 0;

	// ファイルシーク
	fseek(m_fp, m_curdisk_offset + m_trk[_trk], SEEK_SET);

	// セクタ数分ループ
	for (int sec = 0;; sec++)
	{
		unsigned char header[16];

		// ID部読み取り
		fread(header, 1, 16, m_fp);

#ifdef STRICT_CHECK
		for (int i = 0x09; i <= 0x0e; i++)
		{
			if (header[i] != 0) return 0;
		}
#endif

		int C = header[0];
		int H = header[1];
		int R = header[2];
		int N = header[3];
		int maxsec = GetShort(&header[0x04]);	// 最大セクタ数
		int size = GetShort(&header[0x0e]);		// セクタサイズ

		// ひとつもセクタがない場合
		if (maxsec == 0) break;

		// 指定したセクタが見つかったとき
		if (C == _C && H == _H && R == _R && N == _N)
		{
		 	// 実際のセクタが指定されたサイズより大きかった場合は、指定されたサイズまで読み込む
			if (size > _size) size = _size;

			// ディスクイメージから読み込む
			fread(_buffer, 1, size, m_fp);
			// 実際に読み込んだサイズを返しておわり
			return size;
		}
		else
		{
			// 次のセクタへシークを継続
			fseek(m_fp, size, SEEK_CUR);
		}
		// それ以上セクタがないときは中断
		if (sec == maxsec - 1) break;
	}
	return 0;
}

// Read DATA
// ディスクイメージからの読み込み
int D88::ReadDATA(int _trk, int _C, int _H, int _R, int _N, unsigned char *_buffer, int _size)
{
	int trk = _trk;		// トラック番号
	int C = _C;			// C
	int H = _H;			// H
	int R = _R;			// R
	int N = _N;			// N
	unsigned char *buffer = _buffer;	// ばっふぁ
	int size = 0;		// 実際に読み込めたサイズ

	// セクタサイズをNの値から計算 (N=1のとき256)
	int secsize = 0x80 << _N;
	int r;

	// 指定したサイズを読むまで繰り返す
	while (size < _size)
	{
		// 最後の端数の読み込むバイト数を計算
		if (secsize > _size - size) secsize = _size - size;
		// 1セクタ分読み込み
		r = ReadDATA1(trk, C, H, R, N, buffer, secsize);
		// 最後の端数部分まで読み込みおわったら、実際に読み取ったサイズを返しておわり
		if (r < secsize) return size;

		// バッファの位置を更新
		buffer += secsize;
		// 実際に読み込んだサイズを更新
		size += secsize;

		// 次のセクタがセクタ数を越えていた場合
		if (R == m_maxrec)
		{
			trk++;			// 次のトラックへ
			if (H == 0)
			{
				H = 1;		// 裏面へ
			}
			else
			{
				H = 0;		// 表面にしてCの値を+1
				C++;
			}
			R = m_minrec;	// Rを最小のセクタ番号にあわせる
		}
		else
		{
			R++;			// 次のセクタへ
		}
	}
	// 読み込んだサイズを返しておわり
	return size;
}

// Read ID
// 指定トラックのID部を全て読み込む
int D88::ReadID(int _trk, unsigned char *_buffer, int _size)
{
	// ファイルを開いてない場合は戻る
	if (m_fp == NULL) return 0;

	// トラック指定がおかしいときは戻る
	if (_trk >= 164 || m_trk[_trk] == 0 || m_trk[_trk] > m_disksize) return 0;

	// ディスクのシーク
	fseek(m_fp, m_curdisk_offset + m_trk[_trk], SEEK_SET);

	int ret = 0;

	// 指定サイズになるまで繰り返す
	for (int sec = 0; sec*4 < _size; sec++)
	{
		unsigned char header[16];

		// ID部読み取り
		fread(header, 1, 16, m_fp);

#ifdef STRICT_CHECK
		for (int i = 0x09; i <= 0x0e; i++)
		{
			if (header[i] != 0) return 0;
		}
#endif
		// 読み取ったIDを取得
		int C = header[0];
		int H = header[1];
		int R = header[2];
		int N = header[3];
		int maxsec = GetShort(&header[0x04]);
		int size = GetShort(&header[0x0e]);

		// それぞれの値をバッファに書き込む
		_buffer[sec*4 + 0] = C;
		_buffer[sec*4 + 1] = H;
		_buffer[sec*4 + 2] = R;
		_buffer[sec*4 + 3] = N;

		// 読み込んだサイズをカウント
		ret += 4;

		// 現在位置を取得
		fseek(m_fp, size, SEEK_CUR);

		// 最終セクタの場合はループを抜ける
		if (sec == maxsec - 1)
		{
			break;
		}
	}
	// 読み込んだサイズを返しておわり
	return ret;
}

