SPACE:  EQU     32
TAB:    EQU     9
CR:	equ	13
LF:	equ	10
EN:	equ	0
COL:	equ	16

;Заливает экран атрибутом 7 и бордер 0, очищает экран
InitConsole:
ClearScr:
	ld	b,0x07
	ld	de,0
	ld	hl,0x2050
	ld	a,SPACE
        ld	c,Dss.Clear
	RST	0x10
	ld	de,0
	ld	c,Dss.Locate
        RST	0x10
	ld	de,0
	ld	(COORDS),DE
	ret


;Производит отчистку выбранной области текстового экрана (консоли).
;in:
;  HL = высота, ширина
;  DE = Y,X
;  BC = new cursor position (Y,X)
winClearScr:	push bc
		ld a,SPACE
		ld b,7
		ld c,Dss.Clear
	        RST 0x10
		pop de
		ld (COORDS),de
		ld c,Dss.Locate
                RST 0x10
		ret	


;Печать строки
Print:
.printlp:
		ld a,(hl)
		or a
		ret z
                cp 255
                ret z
		call PrintChar
.pskip:		inc hl
		jr .printlp

;Выводит символ в текущих координатах и смещает координаты, при необходимости скроллит экран
PrintChar:
		cp  1
		ret z
		cp LF
		ret z
		cp CR
		jr z,.C13
		cp  16
		jr  z,.C16
                push hl
                call PrintSym
                pop hl
                ld a,(COORDS)
                inc a
		cp 80
		jr nc,.C13
                ld (COORDS),a
                ret
.C13:
		ld a,(COORDS+1)			;Y
		cp 31
		jr c,.noscroll
		push	hl
		call ScrollUP
		pop	hl
		jr .prtNullX

.noscroll:	inc a
		ld (COORDS+1),a

.prtNullX:	xor a
		ld (COORDS),a
		ret
.C16:		inc hl
		ld  a,(hl)
		ld  (PrtAtr),a
                ret

PrintSym:
	ex	af,af'
	ld	de,(COORDS)
	ld	a,(PrtAtr)
	ld	b,a
	ex	af,af'
	ld	c,0x58
	rst	0x10
	ret
ScrollUP
	ld	de,0
	ld	hl,0x1e50
	ld	bc,0x0155
	xor	a
	rst	0x10
        ret

;Установка цвета текста
SetAttr:
        ld (PrtAtr),a
        ret

CursorOn
	ld	a,1
	ld	(curShow),a
	xor	a
	ld	(curState),a
	ld	(curIterate),a
	ret

CursorOff
	xor	a
	ld	(curShow),a
	ld	a,32
PrintCursor
	call	PrintSym
	ret
curShow	db	0
curIterate
	db	0
curState
	db	0


_tab_8_sps:	ds 8,SPACE
		db 0

COORDS	DW	0	;Y,X
PrtAtr  db  7
