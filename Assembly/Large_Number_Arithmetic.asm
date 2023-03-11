;***********************************************************
;*	 Author: Zach Taylor and Sara Vanaken
;*	 Date: 2/15/23
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; A variable
.def	B = r4					; Another variable

.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter


;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0056					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:			
		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)	; Load MPR with low byte of RAEMEND
		out		SPL, mpr		    ; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)	; Load MPR with high byte of RAEMEND
		out		SPH, mpr		    ; Load SPH with high byte of RAMEND

		clr		zero			    ; Set the zero register to zero, maintain these semantics, meaning, don't load anything else into it.

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:

		rcall ADD_PREP  ; Call function to load ADD16 operands
		nop             ; Check load ADD16 operands (Set Break point here #1)

		rcall ADD16     ; Call ADD16 function to display its results (calculate FCBA + FFFF)
		nop             ; Check ADD16 result (Set Break point here #2)


		rcall SUB_PREP  ; Call function to load SUB16 operands
		nop             ; Check load SUB16 operands (Set Break point here #3)

		rcall SUB16     ; Call SUB16 function to display its results (calculate FCB9 - E420)
		nop             ; Check SUB16 result (Set Break point here #4)


		rcall MUL_PREP  ; Call function to load MUL24 operands
		nop             ; Check load MUL24 operands (Set Break point here #5)

		rcall MUL24     ; Call MUL24 function to display its results (calculate FFFFFF * FFFFFF)
		nop             ; Check MUL24 result (Set Break point here #6)

		rcall COMP_PREP ; Setup the COMPOUND function direct test
		nop             ; Check load COMPOUND operands (Set Break point here #7)

		rcall COMPOUND  ; Call the COMPOUND function
		nop             ; Check COMPOUND result (Set Break point here #8)

DONE:	rjmp	DONE	; Create an infinite while loop to signify the end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;       where the high byte of the result contains the carry
;       out bit.
;-----------------------------------------------------------
ADD16:
		; Load beginning address of first operand into X
		ldi		XL, low(ADD16_OP1)	; Load low byte of address
		ldi		XH, high(ADD16_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi YL, low(ADD16_OP2)      ; Load low byte of address
		ldi YH, high(ADD16_OP2)     ; Load high byte of address

		; Load beginning address of result into Z
		ldi ZL, low(ADD16_Result)   ; Load low byte of address
		ldi ZH, high(ADD16_Result)  ; Load high byte of address

		; Execute the function
		ld mpr, X+                  ; Load first operand into mpr
		ld r19, Y+                  ; Load second operand into r19
		
		add r19, mpr                ; Add first two bytes
		st Z+, r19                  ; Store the first byte in result

		ld mpr, X                   ; Load next byte of the first operand
		ld r19, Y                   ; Load second byte of the second operand

		adc r19, mpr                ; Add last two bytes
		st Z+, r19                  ; Store in next result byte

		brcc EXIT                   ; Break if no carry
		st Z, XH                    ; Add any carry bits

EXIT:
		ret						    ; End a function with RET

;-----------------------------------------------------------
; Func: SUB16
; Desc: Subtracts two 16-bit numbers and generates a 16-bit
;       result. Always subtracts from the bigger values.
;-----------------------------------------------------------
SUB16:
		; Load beginning address of first operand into X
		ldi	XL, low(SUB16_OP1)	     ; Load low byte of address
		ldi	XH, high(SUB16_OP1)	     ; Load high byte of address

		; Load beginning address of second operand into Y
		ldi YL, low(SUB16_OP2)       ; Load low byte of address
		ldi YH, high(SUB16_OP2)      ; Load high byte of address

		; Load beginning address of result into Z
		ldi ZL, low(SUB16_Result)    ; Load low byte of address
		ldi ZH, high(SUB16_Result)   ; Load high byte of address

		; Execute the function
		ld mpr, X+                   ; Load first operand into mpr
		ld r19, Y+                   ; Load second operand into r19
		
		sub mpr, r19                 ; Subtract first two bytes
		st Z+, mpr                   ; Store the first byte in result

		ld mpr, X                    ; Load next byte of the first operand
		ld r19, Y                    ; Load second byte of the second operand

		sbc mpr, r19                 ; Subtract last two bytes
		st Z, mpr                    ; Store in next result byte

		ret						     ; End a function with RET

;-----------------------------------------------------------
; Func: MUL24
; Desc: Multiplies two 24-bit numbers and generates a 48-bit
;       result.
;-----------------------------------------------------------
MUL24:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of MUL24_OP2
		ldi		YL, low(MUL24_OP2)	; Load low byte
		ldi		YH, high(MUL24_OP2)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(MUL24_Result)	; Load low byte
		ldi		ZH, high(MUL24_Result)  ; Load high byte

		; Begin outer for loop
		ldi		oloop, 3		; Load counter
MUL24_OLOOP:
		; Set X to beginning address of MUL24_OP1
		ldi		XL, low(MUL24_OP1)	; Load low byte
		ldi		XH, high(MUL24_OP1)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 3		; Load counter
MUL24_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry

		ld		A, Z+			; Get a third byte from the result
		ld      B, Z            ; Get a fourth byte from the result
		adc		A, zero			; Add carry to A
		adc     B, zero         ; Add second carry to B
		st      Z, B            ; Store fourth byte to memory
		st		-Z, A			; Store third byte to memory

		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store first byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1
		dec		iloop			; Decrement counter
		brne	MUL24_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 2		; Z <= Z - 2
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL24_OLOOP		; Loop if oLoop != 0
		; End outer for loop

		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: COMPOUND
; Desc: Computes the compound expression ((G - H) + I)^2
;       by making use of SUB16, ADD16, and MUL24.
;
;       D, E, and F are declared in program memory, and must
;       be moved into data memory for use as input operands.
;
;       All result bytes should be cleared before beginning.
;-----------------------------------------------------------
COMPOUND:

		; Setup SUB16 with operands G and H
		ldi XL, low(SUB16_OP1)     ; Load low byte of address
		ldi XH, high(SUB16_OP1)    ; Load high byte of address

		ldi YL, low(COMPOUND_G)    ; Load low byte of address
		ldi YH, high(COMPOUND_G)   ; Load high byte of address

		ld mpr, Y+                 ; Load first byte from data memory to reg
		st X+, mpr                 ; Store first byte into data memory at X
		ld mpr, Y                  ; Load second byte from data memory to reg
		st X, mpr                  ; Store second byte into data memory at X

		ldi XL, low(SUB16_OP2)     ; Load low byte of address
		ldi XH, high(SUB16_OP2)    ; Load high byte of address

		ldi YL, low(COMPOUND_H)    ; Load low byte of address
		ldi YH, high(COMPOUND_H)   ; Load high byte of address

		ld mpr, Y+                 ; Load first byte from data memory to reg
		st X+, mpr                 ; Store first byte into data memory at X
		ld mpr, Y                  ; Load second byte from data memory to reg
		st X, mpr                  ; Store second byte into data memory at X

		; Perform subtraction to calculate G - H
		rcall SUB16

		; Setup the ADD16 function with SUB16 result and operand I
		ldi XL, low(ADD16_OP1)     ; Load low byte of address
		ldi XH, high(ADD16_OP1)    ; Load high byte of address

		ldi YL, low(SUB16_Result)  ; Load low byte of address
		ldi YH, high(SUB16_Result) ; Load high byte of address

		ld mpr, Y+                 ; Load first byte from data memory to reg
		st X+, mpr                 ; Store first byte into data memory at X
		ld mpr, Y                  ; Load second byte from data memory to reg
		st X, mpr                  ; Store second byte into data memory at X

		ldi XL, low(ADD16_OP2)     ; Load low byte of address
		ldi XH, high(ADD16_OP2)    ; Load high byte of address

		ldi YL, low(COMPOUND_I)    ; Load low byte of address
		ldi YH, high(COMPOUND_I)   ; Load high byte of address

		ld mpr, Y+                 ; Load first byte from data memory to reg
		st X+, mpr                 ; Store first byte into data memory at X
		ld mpr, Y                  ; Load second byte from data memory to reg
		st X, mpr                  ; Store second byte into data memory at X

		; Perform addition next to calculate (G - H) + I
		rcall ADD16

		; Setup the MUL24 function with ADD16 result as both operands
		ldi XL, low(MUL24_OP1)     ; Load low byte of address
		ldi XH, high(MUL24_OP1)    ; Load high byte of address

		ldi YL, low(ADD16_Result)  ; Load low byte of address
		ldi YH, high(ADD16_Result) ; Load high byte of address

		ld mpr, Y+                 ; Load first byte from data memory to reg
		st X+, mpr                 ; Store first byte into data memory at X
		ld mpr, Y+                 ; Load second byte from data memory to reg
		st X+, mpr                 ; Store second byte into data memory at X
		ld mpr, Y                  ; Load third byte from data memory to reg
		st X, mpr                  ; Store third byte into data memory at X

		ldi XL, low(MUL24_OP2)     ; Load low byte of address
		ldi XH, high(MUL24_OP2)    ; Load high byte of address

		ldi YL, low(ADD16_Result)  ; Load low byte of address
		ldi YH, high(ADD16_Result) ; Load high byte of address

		ld mpr, Y+                 ; Load first byte from data memory to reg
		st X+, mpr                 ; Store first byte into data memory at X
		ld mpr, Y+                 ; Load second byte from data memory to reg
		st X+, mpr                 ; Store second byte into data memory at X
		ld mpr, Y                  ; Load third byte from data memory to reg
		st X, mpr                  ; Store third byte into data memory at X

		; Perform multiplication to calculate ((G - H) + I)^2
		rcall MUL24

		; End a function with RET
		ret

;-----------------------------------------------------------
; Func: MUL16
; Desc: An example function that multiplies two 16-bit numbers
;       A - Operand A is gathered from address $0101:$0100
;       B - Operand B is gathered from address $0103:$0102
;       Res - Result is stored in address
;             $0107:$0106:$0105:$0104
;       You will need to make sure that Res is cleared before
;       calling this function.
;-----------------------------------------------------------
MUL16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(LAddrP)	; Load low byte
		ldi		ZH, high(LAddrP); Load high byte

		; Begin outer for loop
		ldi		oloop, 2		; Load counter
MUL16_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 2		; Load counter
MUL16_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store first byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1
		dec		iloop			; Decrement counter
		brne	MUL16_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 1		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL16_OLOOP		; Loop if oLoop != 0
		; End outer for loop

		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------------
; Func: ADD_PREP
; Desc: Loads values fromm program memory to data memory for ADD16
;-----------------------------------------------------------------
ADD_PREP:							
		ldi ZL, low(OperandA<<1)   ; Load low byte of address
		ldi ZH, high(OperandA<<1)  ; Load high byte of address

		ldi YL, low(ADD16_OP1)     ; Load low byte of address
		ldi YH, high(ADD16_OP1)    ; Load high byte of address


		lpm mpr, Z+                ; Load first byte from program memory to reg
		st Y+, mpr                 ; Put first byte into data memory at Y
		lpm mpr, Z                 ; Load second byte from program memory
		st Y, mpr                  ; Store byte in data memory

		ldi ZL, low(OperandB<<1)   ; Load low byte of address
		ldi ZH, high(OperandB<<1)  ; Load high byte of address

		ldi YL, low(ADD16_OP2)     ; Load low byte of address
		ldi YH, high(ADD16_OP2)    ; Load high byte of address

		lpm mpr, Z+                ; Load first byte from program memory to reg
		st Y+, mpr                 ; Put first byte into data memory at Y
		lpm mpr, Z                 ; Load second byte from program memory
		st Y, mpr                  ; Store byte in data memory

		ret	                       ; End a function with RET

;-----------------------------------------------------------------
; Func: SUB_PREP
; Desc: Loads values fromm program memory to data memory for SUB16
;-----------------------------------------------------------------
SUB_PREP:							
		ldi ZL, low(OperandC<<1)   ; Load low byte of address
		ldi ZH, high(OperandC<<1)  ; Load high byte of address

		ldi YL, low(SUB16_OP1)     ; Load low byte of address
		ldi YH, high(SUB16_OP1)    ; Load high byte of address


		lpm mpr, Z+                ; Load first byte from program memory to reg
		st Y+, mpr                 ; Put first byte into data memory at Y
		lpm mpr, Z
		st Y, mpr                  ; Store byte in data memory

		ldi ZL, low(OperandD<<1)   ; Load low byte of address
		ldi ZH, high(OperandD<<1)  ; Load high byte of address

		ldi YL, low(SUB16_OP2)     ; Load low byte of address
		ldi YH, high(SUB16_OP2)    ; Load high byte of address

		lpm mpr, Z+                ; Load first byte from program memory to reg
		st Y+, mpr                 ; Put first byte into data memory at Y
		lpm mpr, Z                 ; Load second byte from program memory
		st Y, mpr                  ; Store byte in data memory

		ret	                       ; End a function with RET

;-----------------------------------------------------------------
; Func: MUL_PREP
; Desc: Loads values fromm program memory to data memory for MUL24
;-----------------------------------------------------------------
MUL_PREP:							
		ldi ZL, low(OperandE1<<1)  ; Load low byte of address
		ldi ZH, high(OperandE1<<1) ; Load high byte of address

		ldi YL, low(MUL24_OP1)     ; Load low byte of address
		ldi YH, high(MUL24_OP1)    ; Load high byte of address


		lpm mpr, Z+                ; Load first byte from program memory to reg
		st Y+, mpr                 ; Put first byte into data memory at Y
		lpm mpr, Z                 ; Load second byte from program memory
		st Y+, mpr                 ; Store byte in data memory

		ldi ZL, low(OperandE2<<1)  ; Load low byte of address
		ldi ZH, high(OperandE2<<1) ; Load high byte of address

		lpm mpr, Z                 ; Load third byte from program memory to reg
		st Y, mpr                  ; Store byte in data memory

		ldi ZL, low(OperandF1<<1)  ; Load low byte of address
		ldi ZH, high(OperandF1<<1) ; Load high byte of address

		ldi YL, low(MUL24_OP2)     ; Load low byte of address
		ldi YH, high(MUL24_OP2)    ; Load high byte of address


		lpm mpr, Z+                ; Load first byte from program memory to reg
		st Y+, mpr                 ; Put first byte into data memory at Y
		lpm mpr, Z                 ; Load second byte from program memory
		st Y+, mpr                 ; Store byte in data memory

		ldi ZL, low(OperandF2<<1)  ; Load low byte of address
		ldi ZH, high(OperandF2<<1) ; Load high byte of address

		lpm mpr, Z                 ; Load third byte from program memory to reg
		st Y, mpr                  ; Store byte in data memory

		ret	                       ; End a function with RET

;--------------------------------------------------------------------
; Func: COMP_PREP
; Desc: Loads values fromm program memory to data memory for compound
;       Also clears the result bytes.
;--------------------------------------------------------------------
COMP_PREP:							
		ldi ZL, low(OperandG<<1)  ; Load low byte of address
		ldi ZH, high(OperandG<<1) ; Load high byte of address

		ldi YL, low(COMPOUND_G)   ; Load low byte of address
		ldi YH, high(COMPOUND_G)  ; Load high byte of address


		lpm mpr, Z+               ; Load first byte from program memory to reg
		st Y+, mpr                ; Put first byte into data memory at Y
		lpm mpr, Z                ; Load second byte from program memory
		st Y, mpr                 ; Store byte in data memory

		ldi ZL, low(OperandH<<1)  ; Load low byte of address
		ldi ZH, high(OperandH<<1) ; Load high byte of address

		ldi YL, low(COMPOUND_H)   ; Load low byte of address
		ldi YH, high(COMPOUND_H)  ; Load high byte of address


		lpm mpr, Z+               ; Load first byte from program memory to reg
		st Y+, mpr                ; Put first byte into data memory at Y
		lpm mpr, Z                ; Load second byte from program memory
		st Y, mpr                 ; Store byte in data memory

		ldi ZL, low(OperandI<<1)  ; Load low byte of address
		ldi ZH, high(OperandI<<1) ; Load high byte of address

		ldi YL, low(COMPOUND_I)   ; Load low byte of address
		ldi YH, high(COMPOUND_I)  ; Load high byte of address

		lpm mpr, Z+               ; Load first byte from program memory to reg
		st Y+, mpr                ; Put first byte into data memory at Y
		lpm mpr, Z                ; Load second byte from program memory
		st Y, mpr

		; Clear result bytes
		ldi r19, $00               ; Prep clear byte

		ldi ZL, low(ADD16_Result)  ; Load low byte of address
		ldi ZH, high(ADD16_Result) ; Load high byte of address

		st Z+, r19                 ; Write $00 to byte pointed by Z
		st Z+, r19                 ; Write $00 to byte pointed by Z
		st Z, r19                  ; Write $00 to byte pointed by Z
		 
		ldi ZL, low(SUB16_Result)  ; Load low byte of address
		ldi ZH, high(SUB16_Result) ; Load high byte of address

		st Z+, r19                 ; Write $00 to byte pointed by Z
		st Z, r19                  ; Write $00 to byte pointed by Z

		ldi ZL, low(MUL24_Result)  ; Load low byte of address
		ldi ZH, high(MUL24_Result) ; Load high byte of address

		ldi r20, $06               ; Load counter to loop thorugh MUL24_Result
LOOP:
		st Z+, r19                 ; Write $00 to byte pointed by Z
		dec r20                    ; Dec counter
		brne LOOP                  ; Break if 0

		ret	                       ; End a function with RET
;***********************************************************
;*	Stored Program Data
;*	Do not  section.
;***********************************************************
; ADD16 operands
OperandA:
	.DW 0xFCBA
OperandB:
	.DW 0xFFFF

; SUB16 operands
OperandC:
	.DW 0XFCB9
OperandD:
	.DW 0XE420

; MUL24 operands
OperandE1:
	.DW	0XFFFF
OperandE2:
	.DW	0X00FF
OperandF1:
	.DW	0XFFFF
OperandF2:
	.DW	0X00FF

; Compoud operands
OperandG:
	.DW	0xFCBA				; test value for operand G
OperandH:
	.DW	0x2022				; test value for operand H
OperandI:
	.DW	0x21BB				; test value for operand I

;***********************************************************
;*	Data Memory Allocation
;***********************************************************
.dseg
.org	$0100				; data memory allocation for MUL16 example
addrA:	.byte 2
addrB:	.byte 2
LAddrP:	.byte 4

.org	$0110				; data memory allocation for operands
ADD16_OP1:
		.byte 2				; allocate two bytes for first operand of ADD16
ADD16_OP2:
		.byte 2				; allocate two bytes for second operand of ADD16

.org	$0120				; data memory allocation for results
ADD16_Result:
		.byte 3				; allocate three bytes for ADD16 result

.org    $0140
SUB16_OP1:
		.byte 2				; allocate two bytes for first operand of SUB16
SUB16_OP2:
		.byte 2				; allocate two bytes for second operand of SUB16

.org	$0150				; data memory allocation for results
SUB16_Result:
		.byte 3				; allocate three bytes for SUB16 result

.org    $0170
MUL24_OP1:
		.byte 3				; allocate two bytes for first operand of MUL24
MUL24_OP2:
		.byte 3				; allocate two bytes for second operand of MUL24

.org	$0180				; data memory allocation for results
MUL24_Result:
		.byte 3				; allocate three bytes for MUL24 result

.org    $0190
COMPOUND_G:
		.byte 2				; allocate two bytes for operand G
COMPOUND_H:
		.byte 2				; allocate two bytes for operand H
COMPOUND_I:
		.byte 2				; allocate two bytes for operand I

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program
