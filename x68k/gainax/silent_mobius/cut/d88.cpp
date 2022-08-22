#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "d88.h"

//#define STRICT_CHECK

#define D88_HEADER_SIZE (0x20 + 4 * 164)	// D88ヘッダのサイズ
#define D88_NAME	(0)						// ディスク名の位置
#define D88_PROTECT	(0x1a)					// ライトプロテクトの有無の位置 (0:なし 1:あり)
#define D88_TYPE	(0x1b)					// ディスクの種類の位置(00H:2D 10H:2DD 20H:2HD)
#define D88_SIZE	(0x1c)					// ディスクのサイズの位置(DWORD)
#define D88_TRACK	(0x20)					// トラックデータテーブルの先頭の位置

// dword値を変数に代入
static int GetInt(uint8_t *_p)
{
	int ret;

	ret = (_p[3]<<24) + (_p[2]<<16) + (_p[1]<<8) + _p[0];

	return ret;
}

// word値を変数に代入
static int GetShort(uint8_t *_p)
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

// デスクトラクタ
D88::~D88()
{
	if (m_fp) {
		fclose(m_fp);
	}
}

/**
 * ファイルを開いてポインタをセット
 *
 * @param _fname [in] Input file name.
 * @return true / false
 *
 */
bool D88::SetFile(char *_fname)
{
	if (_fname == NULL) {
		fclose(m_fp);			// 引数指定がないときは、選択解除
		m_fp = NULL;			// ディスクイメージのファイルポインタ

		m_numdisk = 0;			// ディスク数
		m_curdisk = -1;			// 選択中のディスク番号(0～)
		m_disktype = -1;		// ディスクタイプ(2D/2DD/2HD)

		return true;
	}

	m_fp = fopen(_fname, "rb");	// ファイルを開く (rb=読み出し、CR/LF変換をしない)

	if (m_fp == NULL) {			// 開けないとき
		return false;
	}

	int offset = 0;

	for (m_numdisk = 0; m_numdisk < MAX_DISK; m_numdisk++) {	// ディスク数分だけ繰り返す
		int size;
		uint8_t header[D88_HEADER_SIZE];	// D88ヘッダ部のメモリ確保

		m_disk_offset[m_numdisk] = offset;	// ディスク番号ごとのオフセット位置を配列に格納

		fseek(m_fp, offset, SEEK_SET);		// ファイルポインタを移動
		size = fread(header, 1, D88_HEADER_SIZE, m_fp);
		if (size != D88_HEADER_SIZE) {		// D88ヘッダのサイズ以下になったときに中断
			break;
		}

		offset += GetInt(&header[D88_SIZE]);	// 次のD88ヘッダの位置を計算
	}

	return true;
}

/**
 * 1トラック内の最小/最大セクタ数を設定
 *
 * 設定しないと最小1/最大16で動作
 *
 * @param _min [in] 最小セクタ
 * @param _max [in] 最大セクタ
 *
 */
void D88::SetRecordRange(int _min, int _max)
{
	m_minrec = _min;
	m_maxrec = _max;
}

/**
 * 現在選択中のD88内のディスク数を返す
 *
 * @return ディスク枚数 (1~)
 */
int D88::GetNumDisk() const
{
	return m_numdisk;
};

/**
 * 現在選択中のディスク番号を返す
 *
 * @return 選択ディスク番号 (1~)
 */
int D88::GetCurrentDisk() const
{
	return m_curdisk;
};

/**
 * 指定したディスク番号のディスクを開く
 *
 * @param _diskno [in] ディスク番号
 * @return true / false
 *
 */
bool D88::SelectDisk(int _diskno)
{
	uint8_t header[D88_HEADER_SIZE];

	if (m_fp == NULL) {		// D88ファイルがオープンされてないときは処理せず戻る
		return false;
	}

	m_curdisk_offset = -1;

	m_curdisk = -1;
	m_disktype = -1;	
	m_disksize = 0;
	m_diskname[0] = '\0';

	if (_diskno > m_numdisk) {	// 指定したディスクが実際の枚数より多いときは処理せず戻る
		return false;
	}

	m_curdisk_offset = m_disk_offset[_diskno];


	fseek(m_fp, m_curdisk_offset, SEEK_SET);	// ディスクをシーク
	fread(header, 1, D88_HEADER_SIZE, m_fp);
//	      buffer,size(byte),最大数,   stream

	for (int trk = 0; trk < 164; trk++) {		// トラック位置を配列に取り込む
		m_trk[trk] = GetInt(&header[D88_TRACK + trk*4]);
	}

	m_disktype = header[D88_TYPE];				// ディスクタイプを取得
	m_disksize = GetInt(&header[D88_SIZE]);		// ディスクサイズを取得
	strncpy(m_diskname, (char *)&header[D88_NAME], 16);	// ディスク名を変数にコピー

	return true;
}

/**
 * ディスク名を返す
 *
 * @return ディスク名
 *
 */
const char *D88::GetDiskName() const
{
	return m_diskname;
}

/**
 * ディスクタイプを返す
 *
 * @return ディスクタイプ
 *
 */
int D88::GetDiskType() const
{
	return m_disktype;
}

/**
 * ReadDATA1
 * トラック内指定した1セクタを読み込む
 *
 * @param _trk [in] Track number. (1~163)
 * @param _C [in] Cyrinder
 * @param _H [in] Head
 * @param _N [in] Num of sector.
 * @parma _buffer [out] Buffer pointer.
 * @param _size [in] Buffer size.
 * @return Read size.
 *
 */
int D88::ReadDATA1(int _trk, int _C, int _H, int _R, int _N, uint8_t *_buffer, int _size)
{
	if (m_fp == NULL) {		// ファイルを開いてない場合は戻る
		printf("error! - 1\n");
		return 0;
	}

	if (_trk >= 164 || m_trk[_trk] == 0 || m_trk[_trk] > m_disksize) {
		printf("error! - 2\n");
		return 0;			// トラック指定がおかしいときは戻る
	}

	fseek(m_fp, m_curdisk_offset + m_trk[_trk], SEEK_SET);	// ファイルシーク

	for (int sec = 0;; sec++) {		// セクタ数分繰り返す
		uint8_t header[16];

		fread(header, 1, 16, m_fp);	// ID部読み取り

#ifdef STRICT_CHECK
		for (int i = 0x09; i <= 0x0e; i++) {
			if (header[i] != 0) {
				printf("error! - 3\n");
				return 0;
			}
		}
#endif

		int C = header[0];
		int H = header[1];
		int R = header[2];
		int N = header[3];
		int maxsec = GetShort(&header[0x04]);	// 最大セクタ数
		int size = GetShort(&header[0x0e]);		// セクタサイズ

		if (maxsec == 0) {		// ひとつもセクタがありません
			printf("error! - 4\n");
			break;
		}

		if (C == _C && H == _H && R == _R && N == _N) { // 指定したセクタに到達したとき
			if (size > _size) {	// 実際のセクタが指定された読み取りデータ数より大きかった場合は
				size = _size;	// セクタサイズまで読み込む
			}

			fread(_buffer, 1, size, m_fp);	// ディスクイメージから読んで_bufferに格納

			return size;					// 実際に読み込んだサイズを返しておわり
		} else {
			fseek(m_fp, size, SEEK_CUR);	// 実際のセクタまで到達してない時はシークを継続
		}

		if (sec == maxsec - 1) {	// それ以上セクタがないときは中断
			break;
		}
	}

	return 0;
}

/**
 * ReadDATA
 * 指定した位置から転送バッファへ指定したサイズを読み込む
 *
 * @param _trk [in] Track number
 * @param _C [in] Cyrinder
 * @param _H [in] Head (0/1)
 * @param _R [in] Record
 * @param _N [in] Num of sector
 * @param _buffer [out] Buffer pointer
 * @param _size [in] Buffer size
 * @return Read size.
 *
 */
int D88::ReadDATA(int _trk, int _C, int _H, int _R, int _N, uint8_t *_buffer, int _size)
{
	int trk = _trk;		// トラック番号
	int C = _C;			// C
	int H = _H;			// H
	int R = _R;			// R
	int N = _N;			// N
	uint8_t *buffer = _buffer;	// ばっふぁ
	int size = 0;		// 実際に読み込めたサイズ

	int secsize = 0x80 << _N;	// セクタサイズをNの値から計算 N=1のとき256
	int r;

	while (size < _size) {		// 指定したサイズを読むまで繰り返す
		// 最後の端数の読み込むバイト数を計算
		if (secsize > _size - size) {
			secsize = _size - size;
		}
		// 1セクタ分読み込み
		r = ReadDATA1(trk, C, H, R, N, buffer, secsize);
		// 最後の端数部分まで読み込みおわったら、実際に読み取ったサイズを返しておわり
		if (r < secsize) {
			return size;
		}

		buffer += secsize;	// バッファの位置を更新
		size += secsize;	// 実際に読み込んだサイズを更新

		// 次のセクタがセクタ内の最大トラック数を越えていた場合
		if (R == m_maxrec) {
			trk++;			// 次のトラック
			if (H == 0) {
				H = 1;		// 裏面へ
			} else {
				H = 0;		// 表面にしてCの値を+1
				C++;
			}
			R = m_minrec;	// Rを最小のセクタ番号にあわせる
		} else {
			R++;			// 次のセクタにあわせる
		}
	}

	return size;			// 読み込んだバイト数を返しておわり
}

/**
 * ReadID
 * 指定トラックのID部を全て読み込む
 *
 * @param _trk [in] Track number
 * @param _buffer [out] Buffer pointer
 * @param _size [in] Buffer size
 * @return
 *
 */
int D88::ReadID(int _trk, uint8_t *_buffer, int _size)
{
	// 指定なしのとき
	if (m_fp == NULL) {
		return 0;
	}

	// 指定したトラックのエラーチェック
	if (_trk >= 164 || m_trk[_trk] == 0 || m_trk[_trk] > m_disksize) {
		return 0;
	}

	// ディスクのシーク
	fseek(m_fp, m_curdisk_offset + m_trk[_trk], SEEK_SET);

	int ret = 0;

	// 指定サイズになるまで繰り返す
	for (int sec = 0; sec*4 < _size; sec++) {
		uint8_t header[16];

		// ID部読み取り
		fread(header, 1, 16, m_fp);

#ifdef STRICT_CHECK
		for (int i = 0x09; i <= 0x0e; i++) {
			if (header[i] != 0) {
				return 0;
			}
		}
#endif
		// 読み取った値を変数にセット
		int C = header[0];
		int H = header[1];
		int R = header[2];
		int N = header[3];
		int maxsec = GetShort(&header[0x04]);
		int size = GetShort(&header[0x0e]);

		// それぞれの値をバッファにセット
		_buffer[sec*4 + 0] = C;
		_buffer[sec*4 + 1] = H;
		_buffer[sec*4 + 2] = R;
		_buffer[sec*4 + 3] = N;

		// 読み込んだサイズをカウント
		ret += 4;

		// 現在位置を取得
		fseek(m_fp, size, SEEK_CUR);

		// 最終セクタの場合は抜ける
		if (sec == maxsec - 1) {
			break;
		}
	}

	// 読み込んだサイズを返しておわり
	return ret;
}
