#include <stdio.h>
#include <stdlib.h>
#include <string.h>



static unsigned int get_word(unsigned char *p){
	unsigned int t;
	t = p[1];
	t = ((t << 8) | p[0]);
	return t;
}

static unsigned long get_dword(unsigned char *p){
	unsigned long t;
	t = p[3];
	t = ((t << 8) | p[2]);
	t = ((t << 8) | p[1]);
	t = ((t << 8) | p[0]);
	return t;
}



static long expand(unsigned char *dest, unsigned char *src, long size){
	int flag1, flag2;
	long ofs, dest_ofs;
	int t_ofs, t_len;
	int t;

	ofs = 0;
	dest_ofs = 0;

	flag1 = src[ofs];
	ofs += 1;
	flag2 = src[ofs];
	ofs += 1;
	while(ofs < size){
		t = src[ofs];
		ofs += 1;
		if(t == flag1){
			if(0x80 != (src[ofs + 1] & 0xe0)){
printf("%x\n", (ofs + 3));
				return dest_ofs;
			}
			t_ofs = (get_word(src + ofs) & 0x1fff);
			t_len = src[ofs + 2];
			t_ofs = (dest_ofs - t_ofs);
			while(0 < t_len){
				dest[dest_ofs] = dest[t_ofs];
				dest_ofs += 1;
				t_ofs += 1;
				t_len -= 1;
			}
			ofs += 3;
			continue;
		}

		if(t == flag2){
//printf("%x: %02x\n", (ofs + 3), src[ofs]);
			if(0 == (src[ofs] & 0x0f)){
printf("%x\n", (ofs + 3));
				return dest_ofs;
			}
			t_ofs = src[ofs];
			t_len = (t_ofs & 0x0f);
			t_ofs = ((t_ofs >> 4) + 1);
			t_ofs = (dest_ofs - t_ofs);
			while(0 < t_len){
				dest[dest_ofs] = dest[t_ofs];
				dest_ofs += 1;
				t_ofs += 1;
				t_len -= 1;
			}
			ofs += 1;
			continue;
		}

		dest[dest_ofs] = t;
		dest_ofs += 1;
	}

	return dest_ofs;
}



int main(int argc, char *argv[]){
	unsigned char *src;
	long size;
	unsigned char *dest;
	long dest_size;


	if(2 > argc){
		exit(0);
	}

	{
		FILE *f;
		f = fopen(argv[1], "rb");
		if(NULL == f){
			printf("ファイルが存在しません (%s\n", argv[1]);
			exit(1);
		}
		fseek(f, 0, SEEK_END);
		size = ftell(f);
		src = malloc(size);
		if(NULL == src){
			fclose(f);
			printf("メモリを確保できませんでした (%s\n", argv[1]);
			exit(1);
		}
		fseek(f, 0, SEEK_SET);
		fread(src, 1, size, f);
		fclose(f);
	}

	dest = malloc(0x10000);
	if(NULL == dest){
		free(src);
		printf("メモリを確保できませんでした (%s\n", argv[1]);
		exit(1);
	}

	{
		int k;
		long ofs, t_ofs, t_size;

		k = 0;
		ofs = 0;
		while(256 > ofs){
			t_ofs = get_dword(src + ofs);
			t_size = get_dword(src + ofs + 4);
			if(0 == t_size){
				break;
			}
			t_size -= t_ofs;

			dest_size = expand(dest, (src + t_ofs + 4), (t_size - 4));

			{
				FILE *f;
				char *t;
				char t_name[64];
				t = "_%02d.DAT";
				if(3 <= argc){
					t = argv[2];
				}
				sprintf(t_name, t, k);
				f = fopen(t_name, "wb");
				fwrite(dest, 1, dest_size, f);
				fclose(f);
			}

			ofs += 4;
			k += 1;
		}
	}

	free(dest);
	free(src);

	exit(0);
}
