; Dummy int 33h
		ORG	0x0100
		USE16
		CPU	186

start:
		mov	ax, cs
		mov	ds, ax
		mov	es, ax

		mov	ax, 0x2533
		mov	dx, vect_33
		int	0x21

		mov	es, [0x002c]		; ŠÂ‹«—Ìˆæ‰ğ•ú
		mov	ah, 0x49
		int	21

		mov	ax,cs
		mov	es,ax
		mov	bx,start
		add	bx,0x000f
		shr	bx,4
		mov	ah,0x4a			; ƒƒ‚ƒŠƒuƒƒbƒN‚Ìk¬
		int	0x21

		mov	ax, 0x3100
		int	0x21

vect_33
		iret

prgend:
		ends

