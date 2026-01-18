#pragma once
#ifndef D88_H_
#define D88_H_

#include <cstdio>

/**
 * @class D88
 * @brief D88形式ディスクイメージ（読み込み専用）操作クラス
 *
 * D88ファイルに含まれるディスクを選択し、
 * トラック・セクタ単位でデータやID情報を読み込むためのクラスです。
 *
 * - 書き込み操作には対応していません
 * - 1つのD88ファイルに最大64枚のディスクを扱えます
 */
class D88
{
public:
	/** 最大ディスク数 */
	enum {
		MAX_DISK = 64,
	};
	/** ディスクタイプ */
	enum {
		TYPE_2D  = 0x00,
		TYPE_2DD = 0x10,
		TYPE_2HD = 0x20,
	};
public:
	/** コンストラクタ */
	D88();
	/** デストラクタ */
	~D88();

	/**
	 * @brief D88ファイルを開く
	 *
	 * D88ファイルを開き、内部的に含まれるディスク数と
	 * 各ディスクのオフセットを解析します。
	 *
	 * @param _fname D88ファイル名（NULL指定時はファイルをクローズ）
	 * @return true 成功 / false 失敗
	 */
	bool SetFile(char *_fname);
	/**
	 * @brief 操作対象ディスクを選択する
	 *
	 * D88ファイル内の指定されたディスクを選択し、
	 * ディスクヘッダおよびトラックオフセットを読み込みます。
	 *
	 * @param _diskno ディスク番号（0始まり）
	 * @return true 成功 / false 失敗
	 */
	bool SelectDisk(int _diskno);
	/**
	 * @brief 1トラック内で扱うセクタ番号（R）の範囲を設定する
	 *
	 * ReadDATA() による連続読み込み時に使用される、
	 * 1トラック内の最小・最大セクタ番号（R値）を指定します。
	 *
	 * @note
	 * 実ディスクのセクタ数と一致しない範囲を指定すると、
	 * トラック跨ぎ時に意図しない読み込み失敗やデータ欠落が発生します。
	 * ReadDATA() を使用する前に、必ず正しい値を設定してください。
	 *
	 * デフォルトは 1～16 です。
	 *
	 * @param _min 最小セクタ番号（通常 1）
	 * @param _max 最大セクタ番号
	 */
	void SetRecordRange(int _min, int _max);

	/**
	 * @brief D88ファイル内のディスク数を取得する
	 * @return ディスク数
	 */
	int GetNumDisk() const;
	/**
	 * @brief 現在選択されているディスク番号を取得する
	 * @return ディスク番号（未選択時は -1）
	 */
	int GetCurrentDisk() const;
	/**
	 * @brief 現在選択中ディスクのディスク名を取得する
	 * @return ディスク名（最大16文字）
	 */
	const char *GetDiskName() const;
	/**
	 * @brief 現在選択中ディスクのタイプを取得する
	 * @return ディスクタイプ（TYPE_2D / TYPE_2DD / TYPE_2HD）
	 */
	int GetDiskType() const;

	/**
	 * @brief トラック内の指定された1セクタを読み込む
	 *
	 * 指定トラックの先頭から順にセクタを走査し、
	 * C/H/R/N が一致するセクタを1つ読み込みます。
	 *
	 * @param _trk トラック番号（0～163）
	 * @param _C シリンダ番号
	 * @param _H ヘッド番号
	 * @param _R セクタ番号（Record）
	 * @param _N セクタサイズコード
	 * @param _buffer 読み込み先バッファ
	 * @param _size バッファサイズ
	 * @return 実際に読み込んだバイト数
	 */
	int ReadDATA1(int _trk, int _C, int _H, int _R, int _N, unsigned char *_buffer, int _size);
	/**
	 * @brief 指定位置から連続したデータを読み込む
	 *
	 * ReadDATA1() を用いて、セクタを跨ぎながら
	 * 指定サイズ分のデータを連続して読み込みます。
	 *
	 * @warning
	 * 本関数は SetRecordRange() で設定されたセクタ範囲を前提に
	 * トラック跨ぎ処理を行います。
	 * 実ディスクのセクタ数と一致しない場合、
	 * 正しくデータを取得できません。
	 *
	 * @param _trk 開始トラック番号（0オリジン）
	 * @param _C 開始シリンダ番号（0オリジン）
	 * @param _H 開始ヘッド番号（0オリジン）
	 * @param _R 開始セクタ番号（1オリジン）
	 * @param _N セクタサイズコード
	 * @param _buffer 読み込み先バッファ
	 * @param _size 読み込みサイズ
	 * @return 実際に読み込んだバイト数
	 */
	int ReadDATA(int _trk, int _C, int _H, int _R, int _N, unsigned char *_buffer, int _size);
	/**
	 * @brief 指定トラック内のID情報をすべて読み込む
	 *
	 * 各セクタの C/H/R/N 情報のみを取得し、
	 * 実データ部は読み飛ばします。
	 *
	 * @param _trk トラック番号
	 * @param _buffer ID情報格納バッファ（C,H,R,Nの4byte単位）
	 * @param _size バッファサイズ
	 * @return 実際に読み込んだバイト数
	 */
	int ReadID(int _trk, unsigned char *_buffer, int _size);

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
