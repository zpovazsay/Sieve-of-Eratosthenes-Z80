            output sieve2.com

            macro exos n
                    rst   030h
                    defb  n
            endm

            MACRO xset variable, value
                    ld   bc, 256 + variable
                    ld   d, value
                    exos 16
            ENDM

            org  0xf0
            db   00, 05
            dw   fillen
            db   00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00

PrimeArray: equ  0x8000
X_SIZE:     equ  40
Y_SIZE:     equ  24
VID_CH:     equ  120

            di
            ld   sp, 0x100
            ei

            ld   a, 12
            out  (191), a
            ld   a, 0xc9
            ld   (0x38), a

            call Init
            call InitArray
            call CreateSquareTable
            call Sieve
            call WritePrimeNumbers

            ld   a, 0xf5
            ld   (0x38), a
vege:       jr   vege

; ======================================================================

Sieve:
            ld   c, 0           ; n = 0

loop3:      ld   b, high PrimeArray
loop1:      inc  c              ; ++n
            ret  m              ; if (n == 128) return
            ld   a, (bc)        ; A = prime[n]
            or   a
            jp   z, loop1       ; if (!prime[n]) goto loop1

            ; HL = C * C
            ld   a, c
            add  a, a
            ld   h, high squareTable
            ld   l, a
            ld   a, (hl)
            inc  l
            ld   h, (hl)
            ld   l, a

; HL = index = 2 * (n ^ 2 + n)
            ld   b, 0
            add  hl, bc         ; HL = BC * BC + BC
            add  hl, hl         ; HL = 2 * (BC * BC + BC)
            set  7, h
loop2:      ld   (hl), b        ; prime[index] = false  (B is always 0)
            add  hl, bc         ; index += 2 * n + 1
            add  hl, bc
            inc  hl
            bit  7, h
            jp   nz, loop2
            jp   loop3

; ======================================================================

NoRAM:      out  (0x81), a
            dec  a
            jr   NoRAM

; ======================================================================

Init:
            exos 24
            jr   nz, NoRAM
            ld   a, c
            out  (0xb3), a
            exos 24
            jr   nz, NoRAM
            ld   a, c
            out  (0xb2), a

; set EXOS variables:
            xset 22, 0          ; MODE_VID  = 0
            xset 23, 0          ; COLR_VID  = 0
            xset 24, X_SIZE     ; X_SIZ_VID = 40
            xset 25, Y_SIZE     ; Y_SIZ_VID = 20
            xset 27, 0          ; BORD_VID  = 0

; open and display video channel
            ld   a, VID_CH
            ld   de, vid_str
            exos 1

            ld   a, VID_CH
            ld   bc, 0x0101
            ld   de, Y_SIZE * 256 + 1
            exos 11

            ld   a, VID_CH
            ld   bc, 2
            ld   de, cursorOff
            exos 8

            ret

vid_str:    db   6, "VIDEO:"
cursorOff:  db   27, "o"

; ======================================================================

InitArray:
; set prime array (0x8000 .. 0xffff) all values true (0xff)
            di
            ld   de, 0xffff
            ld   (.l2 + 1), sp
            ld   sp, 0x0000
            ld   a, 16
            ld   b, 0
.l1:        push de
            push de
            push de
            push de
            djnz .l1
            dec  a
            jp   nz, .l1
.l2:        ld   sp, 0
            ei
            ret

; ======================================================================

CreateSquareTable:
            ld   d, high squareTable
            ld   hl, 0
            ld   b, 1

.loop1:     ld   a, b
            add  a, a
            ld   e, a
            dec  a

            add  a, l
            ld   l, a
            ld   (de), a
            inc  e
            adc  a, h
            sub  l
            ld   h, a
            ld   (de), a

            inc  b
            jp   p, .loop1
            ret

; ======================================================================

WritePrimeNumbers:
            ld   hl, 2
            call writeHL
            ld   hl, PrimeArray
_loop1:     inc  hl
            bit  7, h
            ret  z
            ld   a, (hl)
            or   a
            jp   z, _loop1
            push hl
            res  7, h
            add  hl, hl
            inc  l
            call writeHL
            pop  hl
            jp   _loop1

writeHL:    ld   ix, str
            call Num2Dec
            ld   a, VID_CH
            ld   bc, 8
            ld   de, str
            exos 8
            ret
str:        db   "00000   "

Num2Dec:    ld   d, '0'
            ld   bc, -10000
            call Num1
            ld   bc, -1000
            call Num1
            ld   bc, -100
            call Num1
            ld   c, -10
            call Num1
            ld   c, b
Num1:       ld   a, '0' - 1
Num2:       inc  a
            add  hl, bc
            jr   c, Num2
            sbc  hl, bc
            cp   d
            jr   z, leading_space
            dec  d
xxx:        ld   (ix + 0), a
            inc  ix
            ret
leading_space:
            ld   a, ' '
            jr   xxx

fillen:     equ  $ - 0x100

squareTable:    equ     ((high $) + 1) * 256

            end




