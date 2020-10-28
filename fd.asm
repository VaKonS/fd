; fasm 16-bit COM program
	org     100h                    ; code starts at offset 100h
	use16                           ; use 16-bit code
;include 'only8086.inc'
; ^^^ uncomment this line to check for 8086 compatibility
; with only8086.inc macros from
; https://board.flatassembler.net/topic.php?t=6667#53151

	cld
	mov	cx, 128
	mov	si, cx
	inc	si	;81h
scl:	dec	cx	;letters left
	jnz	havel
h:	mov	dx, hlp
	jmp	q
havel:	lodsb
	cmp	al, 13
	je	h
	cmp	al, ' '
	jle	scl

	cmp	al, '*'
	jne	sm		;search mode

	dec	cx		;check mode, ds:si = {:|+}filename
	jz	h
	mov	dh, -1		;check mode flag (a...z in search mode)
	lodsb
	dec	cx
	jz	h
	cmp	al, ':'
	sbb	bp, bp
	jmp	en		;ds:si = exact name

sm:	dec	si		;search mode, ds:si = variable name
	call	l
	xchg	ax, bx		;bx = string name length
getpp:	mov	dx, es		;save current es
	mov	ax, [es:16h]	;[psp:16h] = parent psp (DOS 2.0+)
	or	ax, ax
	jnz	havep
noenv:	mov	dx, er1
	jmp	q
havep:	mov	es, ax
	sub	dx, ax		;child-parent psp difference
	mov	ax, [es:2Ch]	;[2Ch] = environment
	or	ax, ax		;is segment address 0 (parent environment)?
	jnz	fe		;no, have environment segment
	test	dx, dx		;is segment of child psp same?
	jz	noenv		;yes, infinite loop
	jmp	getpp		;no, different psp, get parent
fe:	mov	es, ax
	xor	di, di		;es:di = start of environment block
	mov	dx, cx		;save name+remain length in dx
chkn:	cmp	byte[es:di], 0
	je	noenv		;end of environment block, no matches found
	mov	cx, bx		;cx = name length
	push	si
cmpn:	 lodsb
	 mov	ah, [es:di]
	 inc	di
	 or	ax, 'AA' xor 'aa'
	 cmp	al, ah
	loope	cmpn		;dec cx, j...
	pop	si
	je	mesn
nomtch:	dec	di		;es:di is after matched part
nmtch2:	mov	al, 0		;(dec di is for broken case 'matched_part',0,di)
	or	cx, -1
	repne	scasb		;searching 0
	jmp	chkn		;es:di is after stringz
mesn:	cmp	byte[es:di], '=' ;part of name matched, is es:di on '='?
	jne	nmtch2		;even in broken case di is on 0

	inc	di		;found string, es:di is after '='
	sub	dx, bx
	mov	cx, dx
	add	si, bx		;ds:si is after variable name
skpsp:	lodsb
	cmp	al, ' '
	jg	ffn
	cmp	al, 13
	loopne	skpsp
	jmp	curdr		;only var_name => current disk

ffn:	mov	dh, 'A'
	cmp	al, '-'		;reversed order
	jnz	fo
	mov	dh, 'Z'
	lodsb
	dec	cx
fo:	dec	si		;ds:si = {:|+}filename
	cmp	al, ':'
	sbb	bp, bp		;-1 if '+' (label)
	jz	curp		;file mode, allow current path (a:name)
	dec	si
	inc	cx
	mov	word[si], ':\'	;label mode, search in root directories
curp:	dec	si		;ds:si = *:[\]filename
en:	mov	bx, si
nl:	inc	bx
	cmp	byte[bx], 13
	loopne	nl
	mov	byte[bx], 0	;zero terminate filename

	mov	bh, dh		;start letter (Z for reversed order)

	mov	dx, ceh
	mov	ax, 2524h	;set read errors skipper
	int	21h

	mov	dx, dta
	mov	ah, 1Ah
	int	21h

	mov	bl, bh		;A or Z
	mov	dx, si
	mov	cx, 6		;hidden / system file
	sub	cx, bp
	sub	cx, bp		;6-(-1)-(-1) = 8, label
sfl:	or	bh, bh
	js	s1		;exact name, do not substitute
	mov	[si], bl
s1:	mov	ah, 4eh
	int	21h
	salc			;al = -1 if not found
	or	bh, bh
	jns	s2
	mov	ah, 4Ch		;in check mode, return 0 or FF (not exist)
	int	21h
s2:	or	al, al
	js	nf		;not found
	xchg	ax, bx		;al = found letter
	jmp	setltr

nf:	dec	bx		;dec bx if reversed order
	cmp	bh, 'Z'		;set carry flag for straight search order
	salc			;SALC is officially documented by Intel and AMD
	;sbb	al, al		;for 16/32-bit mode, it is safe to use
	sub	bl, al		;+1, inc bx if straight order
	sub	bl, al
	cmp	bl, 'Z'
	ja	ooraz
	cmp	bl, 'A'
	jae	sfl
ooraz:	mov	dx, nom
	jmp	q

curdr:	mov	ah, 19h		;get current disk, 0 = A:
	int	21h
	add	al, 'A'

setltr:	mov	[dltr], al
	mov	[es:di], al
	mov	dx, mst

q:	mov	ah, 9		;dx = message
	int	21h
	mov     ah, 4Ch
	int     21h

ceh:	mov	al, 3		;critical errors handler
	iret

l:	push	bx
	push	si
	push	cx
	mov	bx, si
	jcxz	fl		;df=0, cx=scan length, ds:si=*, ret ax=length
l2:	lodsb
	cmp	al, ' '
	jle	l3
	loop	l2
	inc	si
l3:	dec	si
fl:	pop	cx
	xchg	ax, si
	pop	si
	sub	ax, bx
	pop	bx
	retn

hlp	db 'Usage:',13,10
db 'FD env_str_name',13,10
db 'Puts to environment variable a letter of current disk.',13,10
db 13,10
db 'FD env_str_name [ [-]:pathname | [-]+label ]',13,10
db 'Finds disk with file or label, "-" means search from Z: to A:.',13,10
db 13,10
db 'FD *{:drive:\pathname | +drive:\label}',13,10
db 'Sets errorlevel 255 if file does not exist',13,10
db 'and does not modify the environment.',13,10,36
er1	db 'No such environment string.',13,10,36
nom	db 'No drives matched.',13,10,36
mst	db 'Drive is '
dltr	db 'A:.',13,10,36
align 128
dta:
