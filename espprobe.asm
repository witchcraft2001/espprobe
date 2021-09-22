        device  zxspectrum128
bigbuff:equ     0x4000
	include "dss_equ.asm"
	include "head.asm"
	include "sp_equ.asm"
;---------------------------------------
base_com1_addr	equ 0x3f8
base_com2_addr	equ 0x2f8
base_com3_addr	equ 0x3e8
base_com4_addr	equ 0x2e8

SER_P	equ	isa_adr_base + base_com1_addr	;Port COM

LCR     equ     SER_P + 3
FCR     equ     SER_P + 2
DLL     equ     SER_P
DLM     equ     SER_P + 1
MCR     equ     SER_P + 4
LSR     equ     SER_P + 5
DAT     equ     SER_P
begin:
        ; res     4,(iy+1)
        ; ld      bc,0x7ffd
        ; ld      a,0x17
        ; out     (c),a
        ; ld      a,0x07
        ; ld      (0x5c48),a
        ; ld      (0x5c8d),a
        ; xor     a
        ; out     (0xfe),a
        call    clear_screen
        call    reset_isa
        call    check_ports
        jr      nz,p100
        ld      hl,msg_no_comport
        call    zx_puts_safe
        jp      exit
        ; ld      hl,udg
        ; ld      (0x5c7b),hl

p100:   ld      a,0x05
        call    SetAttr
        ld      hl,p100
        push    hl

        ld      hl,msg_baudmenu
        call    zx_puts_safe
p102:   call    zx_getkey
        ld      de,1
        cp      0x31
        jr      z,p101
        inc     e
        cp      0x32
        jr      z,p101
        inc     e
        cp      0x33
        jr      z,p101
        inc     e
        cp      0x34
        jr      z,p101
        ld      e,6
        cp      0x35
        jr      z,p101
        ld      e,8
        cp      0x36
        jr      z,p101
        ld      e,12
        cp      0x37
        jr      nz,p102
p101:
        call    rs232_init
        halt
        ld      b,3
p103:   push    bc
        ld      de,25
        ld      hl,cmd_ate0
        call    send_cmd_wait_ok
        pop     bc
        jr      z,p104
        djnz    p103
        jp      x_err
p104:
;
        ld      hl,msg_req_vers
        call    zx_puts_safe
        ld      de,25
        ld      hl,cmd_gmr
        call    send_cmd_wait_ok
        jp      nz,x_err
;
        ld      hl,msg_press_key
        call    zx_puts_safe
        call    zx_getkey
;
        ld      hl,msg_chg_baud
        call    zx_puts_safe
        ld      de,25
        ld      hl,cmd_uart_9600
        call    send_cmd_wait_ok
        jp      nz,x_err
        ld      de,12
        call    rs232_init
        halt
;
        ld      de,25
        ld      hl,cmd_cwmode
        call    send_cmd_wait_ok
        jp      nz,x_err
        ld      de,25
        ld      hl,cmd_cwautoconn
        call    send_cmd_wait_ok
        jp      nz,x_err
        ld      de,25
        ld      hl,cmd_cwqap
        call    send_cmd_wait_ok
        jp      nz,x_err
;
p110:   ld      hl,msg_ap_list
        call    zx_puts_safe
        ld      de,250
        ld      hl,cmd_cwlap
        call    send_cmd_wait_ok
        jp      nz,x_err

        ld      hl,msg_repeat
        call    zx_puts_safe
        call    zx_getkey
        cp      'R'
        jr      z,p110
        cp      'r'
        jr      z,p110
;
        ld      hl,msg_ap_conn
        call    zx_puts_safe
        ld      de,1000
        ld      hl,cmd_cwjap
        call    send_cmd_wait_ok
        jp      z,p120
        call    x_err
        jr      p110
;
p120:   ld      hl,msg_ipcfg
        call    zx_puts_safe
        ld      de,25
        ld      hl,cmd_cipsta
        call    send_cmd_wait_ok
        call    nz,x_err
;
        ld      hl,msg_ping
        call    zx_puts_safe
        ld      de,75
        ld      hl,cmd_ping_g
        call    send_cmd_wait_ok
        call    nz,x_err
        ld      de,75
        ld      hl,cmd_ping_y
        call    send_cmd_wait_ok
        call    nz,x_err
;
p199:   ld      hl,msg_press_key
        call    zx_puts_safe
        call    zx_getkey
;
p200:   ld      hl,bigbuff
        ld      (ptr),hl
        ld      de,bigbuff+1
        ld      bc,16384
        ld      (hl),0
        ldir
        call    clear_screen
        ld      a,0x05
        call    SetAttr
        ld      hl,msg_menuload
        call    zx_puts_safe
p201:   call    zx_getkey
        cp      0x31
        jr      c,p201
        cp      0x3a
        jr      nc,p201
        sub     0x31
        ld      (resnum),a

        call    rs232_reset_fifo
        ld      hl,msg_open_tcp
        call    zx_puts_safe
        ld      de,250
        ld      hl,cmd_conn2site
        call    send_cmd_wait_ok
        jp      z,p210
        call    x_err
        jr      p199
p210:
        ld      de,50
        call    set_timeout50
        ld      a,0x06
        call    SetAttr
        ld      hl,cmd_cipsend
        call    rs232_putstr
        ld      a,(resnum)
        ld      l,a
        ld      h,0
        add     hl,hl
        add     hl,hl
        ld      de,tabl_ptrurl
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        call    rs232_putstr
        ld      hl,str_crlf
        call    rs232_putstr

        call    wait_ok
        jp      z,p211
        call    x_err
        jp      p199
p211:   ld      a,0x07
        call    SetAttr
p212:   call    rs232_getchar
        jr      z,p212
        push    af
        call    zx_putchar_safe
        pop     af
        cp      '>'
        jr      nz,p211

        ld      a,0x06
        call    SetAttr
        ld      hl,str_get1
        call    rs232_putstr
        ld      a,(resnum)
        ld      l,a
        ld      h,0
        add     hl,hl
        inc     hl
        add     hl,hl
        ld      de,tabl_ptrurl
        add     hl,de
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        ex      de,hl
        call    rs232_putstr
        ld      hl,str_get2
        call    rs232_putstr

        call    wait_ok
        cp      0xfd
        jp      z,p220
        call    x_err
        jp      p199

p220:   ld      de,1000
        call    set_timeout50

p22a:   ld      a,0x07
        call    SetAttr
        ld      hl,strbuff
        ld      (hl),0
        call    rdipd
        ld      a,(strbuff)
        or      a
        jr      nz,p221
        call    x_tout
        jp      p199
p221:   ld      de,str_ipd
        call    ss_cmp
        jr      z,p222
        call    x_err
        jp      p199
p222:
        ld      a,0x05
        call    SetAttr
        ld      hl,msg_skip
        call    zx_puts_safe
        ld      hl,0
        ld      de,strbuff+7
p223:   ld      a,(de)
        inc     de
        cp      ':'
        jr      z,p230
        sub     0x30
        ld      c,l
        ld      b,h
        add     hl,hl
        add     hl,hl
        add     hl,bc
        add     hl,hl
        ld      c,a
        ld      b,0
        add     hl,bc
        jr      p223

p230:   ld      (packsz),hl
        ex      de,hl
        ld      hl,(ptr)
p231:   call    rs232_getchar
        jr      nz,p232
        call    check_timeout
        jr      c,p231
        call    x_tout
        jp      p199
p232:   ld      (hl),a
        inc     hl
        dec     de
        ld      a,d
        or      e
        jr      nz,p231
        ld      (ptr),hl

        ld      hl,(packsz)
        ld      de,1360
        xor     a
        sbc     hl,de
        jr      nc,p22a
;
        ld      hl,bigbuff
p241:   ld      a,(hl)
        inc     hl
p242:   cp      10
        jr      nz,p241
        ld      a,(hl)
        inc     hl
        cp      13
        jr      nz,p242
        inc     hl

        ld      a,(resnum)
        cp      3
        jp      c,pscr0
        cp      6
        jp      c,pgiga0
;pmus0:
        push    hl
        ex      de,hl
        ld      hl,(ptr)
        xor     a
        sbc     hl,de
        ld      c,l
        ld      b,h
        pop     hl
        ld      de,0xc86e
        ldir
        ld      hl,vtpl
        ld      de,0xc000
        ld      bc,sz_vtpl
        ldir
        ld      a,0x05
        call    SetAttr
        ld      hl,msg_musply
        call    zx_puts_safe
        call    0xc000
        ei
        res     5,(iy+1)
pmus1:  halt
        call    0xc005
        bit     5,(iy+1)
        jr      z,pmus1
        call    0xc008
        jp      p200
;
pgiga0: ld      de,0x4000
        ld      bc,0x1b00
        ldir
        ld      de,0xc000
        ld      bc,0x1b00
        ldir
        res     5,(iy+1)
        ld      bc,0x7ffd
pgiga1: halt
        ld      a,0x1f
        out     (c),a
        halt
        ld      a,0x17
        out     (c),a
        bit     5,(iy+1)
        jr      z,pgiga1
        jp      p200
;
pscr0:  ld      de,0x4000
        ld      bc,0x1b00
        ldir
        call    zx_getkey
        jp      p200
;------------------------------
x_err:  ld      hl,msgff_error
        cp      1
        jr      nz,x_er1
x_tout: ld      hl,msgff_timeout
x_er1:  call    zx_puts_ff
        jp      exit
exit    ld      c,Dss.Exit              ;exit!
        ld      b,0xff
        rst     0x10
        ret
;------------------------------
send_cmd_wait_ok:
        push    hl
        call    set_timeout50
        call    rs232_reset_fifo
        ld      a,0x06
        call    SetAttr
        pop     hl
        call    rs232_putstr
        ld      a,0x05
        call    SetAttr
wait_ok:ld      hl,strbuff
        call    rdstr
        ld      a,(strbuff)
        or      a
        jr      nz,_scwo1
        inc     a
        ret
_scwo1: ld      a,0x07
        call    SetAttr
        ld      hl,strbuff
        call    zx_puts_safe
        ld      a,0x05
        call    SetAttr
        ld      de,str_ok
        call    ss_cmp
        ld      a,0x00
        jr      z,_scwo9
        ld      de,str_fail
        call    ss_cmp
        ld      a,0xff
        jr      z,_scwo9
        ld      de,str_error
        call    ss_cmp
        ld      a,0xfe
        jr      z,_scwo9
        ld      de,str_send_ok
        call    ss_cmp
        ld      a,0xfd
        jr      nz,wait_ok
_scwo9: or      a
        ret
;------------------------------
rdstr:  call    rs232_getchar
        jr      z,rdst2
        cp      10              ;LF
        jr      z,rdst3
        ld      (hl),a
        inc     hl
        push hl
        call tst_brk        
        pop hl
        jr c,rdst3
        jr      rdstr
rdst2:  call    check_timeout
        jr      c,rdstr
rdst3:  ld      (hl),0
        ret
;------------------------------
rdipd:  call    rs232_getchar
        jr      z,ripd2
        ld      (hl),a
        inc     hl
        push    af
        call    zx_putchar_safe
        pop     af
        cp      ':'
        ret     z
        jr      rdipd
ripd2:  call    check_timeout
        jr      c,rdipd
        ret
;------------------------------
ss_cmp: ld      hl,strbuff
ss_cm1: ld      a,(de)
        or      a
        ret     z
        inc     de
        cpi
        jr      z,ss_cm1
        ret
;------------------------------
rs232_reset_fifo:
        di
        call    open_isa_ports
        jr      rs232_init.reset_fifo
;------------------------------
rs232_init:
        di
        call    open_isa_ports
        ld      hl,LCR          ;LCR
        ld      a,0x83
        ld      (hl),a
        ld      hl,DLL          ;DLL
        ld      (hl),e
        inc     hl              ;DLM
        ld      (hl),d
        ld      hl,MCR          ;MCR
        ld      a,0x03
        ld      (hl),a
        dec     hl               ;LCR
        ld      a,0x03
        ld      (hl),a
.reset_fifo:
        ld      hl,FCR       ;FCR
        ld      a,0x07          ;FIFO reset
        ld      (hl),a
        ld      a,0x01
        ld      (hl),a
_clfifo:
        ld a,2
        out (#fe),a
        ld      hl,LSR          ;LSR
        ld      a,(hl)
        and     0x01
        jr      z,.exit
        ld      hl,DAT          ;DAT
        ld      a,(hl)
        jr      _clfifo
.exit:  call    close_isa_ports
        push af
        xor a
        out (#fe),a
        pop af
        ei
        ret
;------------------------------
rs232_putchar:
        push    hl
        push    AF
        call    zx_putchar_safe
        di
        call    open_isa_ports
        pop     de
        ld a,3
        out (#fe),a
        ld      hl,LSR       ;LSR        
_putch1:
        ld      a,(hl)
        and     0x20
        jr      z,_putch1
        ld      hl,DAT          ;DAT
        ld      (hl),d
        call    close_isa_ports
        xor a
        out (#fe),a
        pop     hl
        ei
        ret
;------------------------------
rs232_putstr:
        ld      a,(hl)
        inc     hl
        or      a
        ret     z
        call    rs232_putchar
        jr      rs232_putstr
;------------------------------
rs232_getchar:
        di
        ld      a,1
        out (#fe),a
        call    open_isa_ports
        ld      hl,LSR       ;LSR
        ld      a,(hl)
        and     0x01
        jr      z,.exit
        ld      hl,DAT          ;DAT
        ld      a,(hl)
        inc     b
.exit:  call    close_isa_ports
        push af
        xor a
        out (#fe),a
        pop af
        ei
        ret
check_ports:
        di
        call    open_isa_ports
        ld      hl,LSR
        ld      a,(hl)
        cp      0xff
        jr      rs232_getchar.exit
;------------------------------
zx_putchar_safe:
        cp      10              ;LF
        jr      z,_putc1
        cp      13              ;CR
        jr      z,_putc1
        cp      0x20
        jr      c,_putc2
        cp      0x80
        jr      c,_putc1
_putc2: ld      a,'?'
_putc1: push    hl
        call    PrintChar
        pop     hl
        ret
;------------------------------
zx_puts_safe:
        push hl
        call Print
        pop hl
        ret
;         ld      a,0xff
;         ld      (0x5c8c),a
; _puts1: ld      a,(hl)
;         inc     hl
;         or      a
;         ret     z
;         call    zx_putchar_safe
;         jr      _puts1
;------------------------------
zx_puts_ff:
        ; ld      a,0xff
        ; ld      (0x5c8c),a
_psff1: ld      a,(hl)
        inc     hl
        cp      0xff
        ret     z
        push    hl
        call    PrintChar
        pop     hl
        jr      _psff1
;------------------------------
zx_getkey:
        ld      c,Dss.WaitKey
        rst     #10
        ld      a,e
        ret
;------------------------------
set_timeout50:
        ld      a,e
        ld      (tmout),a
        ld      c,Dss.SysTime
        rst     0x10
        ld      a,b
        ld      (lastsec),a
        ret
        ; ld      hl,(0x5c78)
        ; add     hl,de
        ; ld      (tmout),hl
        ; ret
;------------------------------
check_timeout:
        push    hl
        push    de
        push    bc
        ld      c,Dss.SysTime
        rst     0x10
        ld      a,(lastsec)
        cp      b
        ld      a,b
        pop     bc
        pop     de
        pop     hl
        ret     z
        ld      (lastsec),a
        ld      a,(tmout)
        dec     a
        ld      (tmout),a
        ret
        ; push    hl
        ; push    de
        ; ld      de,(tmout)
        ; ld      hl,(0x5c78)
        ; xor     a
        ; sbc     hl,de
        ; pop     de
        ; pop     hl
        ; ret
;------------------------------
tmout:  defw    0
lastsec: defb   0
ptr:    defw    0
packsz: defw    0
resnum: defb    0
color:  defb    7
;------------------------------
udg:    defb    %00000000
        defb    %01010100
        defb    %00101010
        defb    %01010100
        defb    %00101010
        defb    %01010100
        defb    %00101010
        defb    %00000000
;------------------------------
vtpl:
        ; listing off
        include "vtplayer.inc"
        ; listing on
sz_vtpl:equ     $-vtpl

;------------------------------
        include "utils.asm"
        include "isa.asm"        
        include "console.asm"
        
;------------------------------
tabl_ptrurl:
        defw    str_rqsz1,str_uri1
        defw    str_rqsz2,str_uri2
        defw    str_rqsz3,str_uri3
        defw    str_rqsz4,str_uri4
        defw    str_rqsz5,str_uri5
        defw    str_rqsz6,str_uri6
        defw    str_rqsz7,str_uri7
        defw    str_rqsz8,str_uri8
        defw    str_rqsz9,str_uri9
;------------------------------
msgff_timeout:  defb    19,1,13,16,2,"- Timeout! -",16,5,13,0xff
msgff_error:    defb    19,1,13,16,2,"- Error! -",16,5,13,0xff

msg_no_comport: defb    "COM-port is not found!",13,10,0

msg_baudmenu:   defb    "Select baudrate:",13,10
                defb    "1.115200",13,10
                defb    "2. 57600",13,10
                defb    "3. 38400",13,10
                defb    "4. 28800",13,10
                defb    "5. 19200",13,10
                defb    "6. 14400",13,10
                defb    "7.  9600",13,10,0
msg_req_vers:   defb    "Firmware version...",13,10,0
msg_press_key:  defb    "Press a key",13,10,0
msg_chg_baud:   defb    "Change baudrate...",13,10,0
msg_ap_list:    defb    "AccessPoint list...",13,10,0
msg_repeat:     defb    "R - repeat, else continue",13,10,0
msg_ap_conn:    defb    "Connect to AccessPoint...",13,10,0
msg_ipcfg:      defb    "IP config info...",13,10,0
msg_ping:       defb    "Ping...",13,10,0
msg_menuload:   defb    "Now, we can try to load some",13,10
                defb    "pre-defined resources",13,10
                defb    "from the Internet.",13,10
                defb    "1. scr #1",13,10
                defb    "2. scr #2",13,10
                defb    "3. scr #3",13,10
                defb    "4. gigascr #1",13,10
                defb    "5. gigascr #2",13,10
                defb    "6. gigascr #3",13,10
                defb    "7. pt3 #1",13,10
                defb    "8. pt3 #2",13,10
                defb    "9. pt3 #3",13,10,0
msg_open_tcp:   defb    "Open TCP connection...",13,10,0
msg_musply:     defb    13,10,"PT3-module playing"
msg_skip:       defb    "...",0

cmd_ate0:       defb    "ATE0"
str_crlf:       defb    13,10,0
cmd_gmr:        defb    "AT+GMR",13,10,0
cmd_uart_9600:  defb    "AT+UART_CUR=9600,8,1,0,0",13,10,0
cmd_cwmode:     defb    "AT+CWMODE_DEF=1",13,10,0
cmd_cwautoconn: defb    "AT+CWAUTOCONN=0",13,10,0
cmd_cwqap:      defb    "AT+CWQAP",13,10,0
cmd_cwlap:      defb    "AT+CWLAP",13,10,0
cmd_cwjap:      defb    "AT+CWJAP_CUR=",0x22
                defb    "wifitest123"                           ; SSID
                defb    0x22,0x2c,0x22
                defb    "ZXSpectrumForeverHelloEverybody321"    ; password
                defb    0x22,13,10,0
cmd_cipsta:     defb    "AT+CIPSTA?",13,10,0
cmd_ping_g:     defb    "AT+PING=",0x22,"google.com",0x22,13,10,0
cmd_ping_y:     defb    "AT+PING=",0x22,"yandex.ru",0x22,13,10,0
cmd_conn2site:  defb    "AT+CIPSTART=",0x22,"TCP",0x22,",",0x22
                defb    "zxart.ee"                              ; site
                defb    0x22,",80",13,10,0
cmd_cipsend:    defb    "AT+CIPSEND=",0

str_get1:       defb    "GET ",0 ;size=4
str_get2:       defb    " HTTP/1.1",13,10 ;size=123
                defb    "Host: zxart.ee",13,10
                defb    "User-Agent: ESP8266-probe1 (ZX Spectrum; CPU Z80; RAM 128Kb)",13,10    ; show off ;)
                defb    "Accept: */*",13,10
                defb    "Connection: close",13,10,13,10,0

str_uri1:       defb    "/file/id:61049/filename:%D0%9A%D0%90%D0%A1%D0%B8%D0%BA_-_Banka_%282015%29_%283BM_OpenAir_2015%2C_3%29.scr",0 ;size=105
str_rqsz1:      defb    "232",0 ;232=4+105+123=get1+uri1+get2

str_uri2:       defb    "/file/id:61053/filename:Buddy_-_Drunk_Kung-Fu_%282015%29_%283BM_OpenAir_2015%2C_5%29.scr",0 ;size=88
str_rqsz2:      defb    "215",0 ;215=4+88+123=get1+uri2+get2

str_uri3:       defb    "/file/id:61058/filename:brightentayle_-_The_Split_Foundations_%282015%29_%283BM_OpenAir_2015%2C_6%29.scr",0 ;size=104
str_rqsz3:      defb    "231",0 ;231=4+104+123=get1+uri3+get2

str_uri4:       defb    "/file/id:61060/filename:Tutty_-_Bat2Con_%282015%29_%283BM_OpenAir_2015%2C_1%29.img",0 ;size=82
str_rqsz4:      defb    "209",0 ;209=4+82+123=get1+uri4+get2

str_uri5:       defb    "/file/id:61059/filename:Dimidrol_-_Amur_tiger_%282015%29_%283BM_OpenAir_2015%2C_2%29.img",0 ;size=88
str_rqsz5:      defb    "215",0 ;215=4+88+123=get1+uri5+get2

str_uri6:       defb    "/file/id:61061/filename:prof4d_-_Fructus_%282015%29_%283BM_OpenAir_2015%2C_4%29.img",0 ;size=83
str_rqsz6:      defb    "210",0 ;210=4+83+123=get1+uri6+get2

str_uri7:       defb    "/file/id:61065/filename:luchibobra_-_three_bad_mice_%282015%29_%283BM_OpenAir_2015%2C_1%29.pt3",0 ;size=94
str_rqsz7:      defb    "221",0 ;221=4+94+123=get1+uri7+get2

str_uri8:       defb    "/file/id:61067/filename:MmcM_-_summertime_%282015%29_%283BM_OpenAir_2015%2C_2%29.pt3",0 ;size=84
str_rqsz8:      defb    "211",0 ;211=4+84+123=get1+uri8+get2

str_uri9:       defb    "/file/id:61066/filename:wbc_-_isglass-3_%282015%29_%283BM_OpenAir_2015%2C_3%29.pt3",0 ;size=82
str_rqsz9:      defb    "209",0 ;209=4+82+123=get1+uri9+get2

str_ok:         defb    "OK",13,0
str_error:      defb    "ERROR",13,0
str_fail:       defb    "FAIL",13,0
str_send_ok:    defb    "SEND OK",13,0
str_ipd:        defb    13,10,"+IPD,",0
strbuff:
;------------------------------
end_addr: