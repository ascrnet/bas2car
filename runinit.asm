;-----------------------------------------------------------------------
;
; RunInit function for bas2car
; (c) 2024 GienekP
;
;-----------------------------------------------------------------------

DOSVEC  = $0A
ICBAZ   = $24
ICAX1Z  = $2A
ICAX2Z  = $2B
ICAX3Z  = $2C
ICAX4Z  = $2D
ICAX5Z  = $2E
ICAX6Z  = $2F
KBCODES = $02FC
MEMLO   = $02E7
CDST    = $A000
NEWDEV  = $EEBC
EOUTCH  = $F2B0
CRSUP   = $F3E6
CRSDWN  = $F3F3

;-----------------------------------------------------------------------
; CARTRIDGE BANK 1

		OPT h-f+
		
;-----------------------------------------------------------------------
; Files table
; NOF - number of files

		ORG $A000

NOF		dta 0

;-----------------------------------------------------------------------
; $0700

		ORG $BD00
;----------------
PAGE7
;----------------
; VECTOR TABLE
DRIVER	.WORD ($0700+(OPEN-PAGE7)-1)
		.WORD ($0700+(CLOSE-PAGE7)-1)
		.WORD ($0700+(GET-PAGE7)-1)
		.WORD ($0700+(PUT-PAGE7)-1)
		.WORD ($0700+(STATUS-PAGE7)-1)
		.WORD ($0700+(SPEC-PAGE7)-1)
		jmp ($0700+(CLOSE-PAGE7))
		dta 0
;----------------
BANK	dta 0
BPOS	dta 0,0
POS		dta 0,0
SIZE	dta 0,0
;----------------
PUT
STATUS	ldy #$01
SPEC	rts
;----------------
OPEN	sta $D501
		jsr HOPEN
		sta $D500
		rts
;----------------
CLOSE	lda #$00
		ldx #$06
@		sta $0700+(BANK-PAGE7),x
		dex
		bpl @-
		jmp $0700+(STATUS-PAGE7)
;----------------
GET		ldy #$00
		lda $0700+(BANK-PAGE7)
		beq ERROR
		tax
		lda ICAX5Z
		pha
		lda ICAX6Z
		pha
		lda $0700+(BPOS-PAGE7)
		sta ICAX5Z
		lda $0700+(BPOS-PAGE7)+1
		sta ICAX6Z
		sta $D500,x
		lda (ICAX5Z),y
		tax
		pla
		sta ICAX6Z
		pla
		sta ICAX5Z
		txa
		pha
		sta $D500
		inc $0700+(BPOS-PAGE7)
		bne @+
		inc $0700+(BPOS-PAGE7)+1
		lda $0700+(BPOS-PAGE7)+1
		cmp #$C0
		bne @+
		lda #$A0
		sta $0700+(BPOS-PAGE7)+1
		inc $0700+(BANK-PAGE7)
@		inc $0700+(POS-PAGE7)
		bne @+
		inc $0700+(POS-PAGE7)+1
@		lda $0700+(POS-PAGE7)
		cmp $0700+(SIZE-PAGE7)
		bne @+
		lda $0700+(POS-PAGE7)+1
		cmp $0700+(SIZE-PAGE7)+1
		bne @+
		sty $0700+(BANK-PAGE7)		
@		pla
		ldy #$01
ERROR	rts
;----------------
DOSCMD	sta $D501
		jsr DIR
		sta $D500
		rts
;----------------
ENDPAG7
;----------------
;-----------------------------------------------------------------------
; MAIN PROC

		ORG $BE00
;-----------------------------------------------------------------------
; BEGIN
BEGIN	jsr CPYP7
		jsr NEWHAND
		jsr CRSDWN
		jsr CRSDWN
		jsr PRINTAR
		jsr CRSUP
		jsr CRSUP
		lda #$0C
		sta KBCODES
		jmp RUN

;-----------------------------------------------------------------------
; Copy data to page 7
CPYP7	ldx #$00
		lda #(ENDPAG7-PAGE7)
		clc
		adc MEMLO
		sta MEMLO
		bcc @+
		inc MEMLO+1		
@		lda PAGE7,X
		sta $0700,x
		inx
		cpx #(ENDPAG7-PAGE7)
		bne @-
		lda #<($0700+(DOSCMD-PAGE7))
		sta DOSVEC
		lda #>($0700+(DOSCMD-PAGE7))
		sta DOSVEC+1
		rts
		
;-----------------------------------------------------------------------
; New handler
NEWHAND	ldx #'D'
		ldy #<($0700+(DRIVER-PAGE7))
		lda #>($0700+(DRIVER-PAGE7))
		jsr NEWDEV
		ldx #'H'
		ldy #<($0700+(DRIVER-PAGE7))
		lda #>($0700+(DRIVER-PAGE7))
		jsr NEWDEV
		rts

;-----------------------------------------------------------------------
; Print RUN command
PRINTAR	ldx #$00
@		txa
		pha
		lda FILE,x
		jsr EOUTCH
		pla
		tax
		inx
		cpx #(EFILE-FILE)
		bne @-
		rts
FILE	dta c'RUN "D:AUTORUN.BAS"'
EFILE
;-----------------------------------------------------------------------
; DIR command (run as BASIC: DOS command)
DIR		lda #$9B
		jsr EOUTCH
		lda #$00
		sta ICAX5Z
CDY		lda #<NOF
		sta ICAX1Z
		lda #>NOF
		sta ICAX2Z
		lda ICAX5Z
		asl
		asl
		asl
		asl
		ora #$01
		sta ICAX3Z
		lda ICAX5Z
		lsr
		lsr
		lsr
		lsr
		sta ICAX4Z
		clc
		lda ICAX1Z
		adc ICAX3Z
		sta ICAX1Z
		lda ICAX2Z
		adc ICAX4Z
		sta ICAX2Z
		lda #$00
		sta ICAX6Z
@		ldy ICAX6Z
		lda (ICAX1Z),Y
		beq EOFN
		jsr $F2B0
		inc ICAX6Z
		lda ICAX6Z
		cmp #$0B
		bne @-
EOFN	lda #$9B
		jsr EOUTCH
		inc ICAX5Z
		lda ICAX5Z
		cmp NOF
		bne CDY
		rts
		
;-----------------------------------------------------------------------
; Open New Device
HOPEN	lda ICAX1Z
		pha
		lda ICAX2Z
		pha
		lda ICAX3Z
		pha
		lda ICAX4Z
		pha	
		lda ICAX5Z
		pha
		lda ICAX1Z
		cmp #$04
		beq @+
		bne OPERR
OPERR	ldy #$85
		clc
		bcc RESTORE
@		ldy #$00
@		lda (ICBAZ),y
		cmp #':'
		beq @+
		iny
		cpy #$03
		bne @-
		beq OPERR
@		iny
		tya
		clc		
		adc ICBAZ
		sta ICAX1Z
		lda ICBAZ+1
		adc #$0
		sta ICAX2Z
		lda #$01
		sta ICAX3Z
		lda #$A0
		sta ICAX4Z
		lda #$00
		sta ICAX5Z
STRCMP	ldy #$00
		lda (ICAX1Z),y
@		cmp (ICAX3Z),y
		bne @+
		iny
		cpy #$16
		beq OPERR
		lda (ICAX1Z),y
		cmp #$9B
		bne @-
		beq FINDON
@		inc ICAX5Z
		lda ICAX5Z
		cmp NOF
		beq OPERR
		clc
		lda ICAX3Z
		adc #$10
		sta ICAX3Z
		lda ICAX4Z
		adc #$00
		sta ICAX4Z
		clc
		bcc STRCMP
FINDON	ldy #$0C
		lda #$00
		sta $0700+(POS-PAGE7)
		sta $0700+(POS-PAGE7)+1
		sta $0700+(BPOS-PAGE7)
		lda (ICAX3Z),Y
		sta $0700+(SIZE-PAGE7)
		iny
		lda (ICAX3Z),Y
		sta $0700+(SIZE-PAGE7)+1
		iny
		lda (ICAX3Z),Y
		sta $0700+(BANK-PAGE7)
		iny
		lda (ICAX3Z),Y
		clc
		adc #$A0
		sta $0700+(BPOS-PAGE7)+1
		ldy #$01
RESTORE	pla
		sta ICAX5Z
		pla
		sta ICAX4Z
		pla
		sta ICAX3Z
		pla
		sta ICAX2Z
		pla
		sta ICAX1Z
		rts
		
;-----------------------------------------------------------------------
; RUN & INIT

		ORG $BFF0

RUN		sta $D500
		jmp CDST
INIT	sta $D501
RETURN	rts

;-----------------------------------------------------------------------
; CARTRIDGE HEADER

		ORG $BFFA
		
		dta <BEGIN, >BEGIN, $00, $04, <INIT, >INIT
;-----------------------------------------------------------------------
