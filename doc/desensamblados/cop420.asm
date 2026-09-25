
; ---- pagina 0 (000h-03Fh) ----
>000  00     CLRA
 001  33 28  ININ
>003  06     X 0
 004  33 28  ININ
 006  06     X 0
 007  02     XOR
 008  06     X 0
 009  01     SKMBZ 0
 00A  C3     JP 003h
 00B  06     X 0
 00C  01     SKMBZ 0
 00D  CF     JP 00Fh
 00E  D3     JP 013h
>00F  00     CLRA
 010  55     AISC 5
 011  B6     JP 036h
 012  CF     JP 00Fh
>013  33 68  LEI 8
 015  1E     LBI 1,1
 016  83     JP 003h
>017  09     LBI 0,6
 018  71     STII 1
 019  7E     STII 14
 01A  19     LBI 1,6
 01B  4C     RMB 0
 01C  42     RMB 2
 01D  B1     JP 031h
 01E  23 00  LDD 0,0
 020  40     COMP
 021  1A     LBI 1,5
 022  51     AISC 1
 023  43     RMB 3
 024  13     SKMBZ 3
 025  F2     JP 032h
 026  00     CLRA
 027  0F     LBI 0,0
 028  B6     JP 036h
 029  F2     JP 032h
 02A  23 9B  LDD 1,11
 02C  00     CLRA
 02D  23 80  LDD 0,0
 02F  00     CLRA
>030  62 B0  JMP 2B0h
>032  19     LBI 1,6
 033  46     SMB 2
 034  B1     JP 031h
 035  6A 10  JSR 210h
 037  80     JP 000h
 038  6A E9  JSR 2E9h
 03A  B0     JP 030h
 03B  1E     LBI 1,1
 03C  15     LD 1
 03D  21     SKE
 03E  00     CLRA
 03F  06     X 0

; ---- pagina 1 (040h-07Fh) ----
>040  03     SKMBZ 2
 041  C4     JP 044h
 042  AA     JP 06Ah
 043  C7     JP 047h
>044  0F     LBI 0,0
 045  47     SMB 1
>046  0E     LBI 0,1
>047  6A 5C  JSR 25Ch
>049  80     JP 040h
>04A  B0     JP 070h
 04B  0C     LBI 0,3
 04C  23 0A  LDD 0,10
 04E  11     SKMBZ 1
 04F  D6     JP 056h
 050  44     NOP
>051  23 1F  LDD 1,15
>053  5F     AISC 15
>054  DB     JP 05Bh
 055  DC     JP 05Ch
>056  33 97  EXT 97
 058  21     SKE
 059  1B     LBI 1,4
 05A  21     SKE
>05B  DF     JP 05Fh
>05C  69 C9  JSR 1C9h
 05E  E2     JP 062h
>05F  86     JP 046h
 060  8A     JP 04Ah
 061  91     JP 051h
>062  09     LBI 0,6
 063  A5     JP 065h
 064  20     SKC
>065  C9     JP 049h
 066  80     JP 040h
 067  6A E9  JSR 2E9h
 069  15     LD 1
>06A  21     SKE
 06B  00     CLRA
 06C  08     LBI 0,7
 06D  06     X 0
 06E  02     XOR
 06F  18     LBI 1,7
>070  5F     AISC 15
 071  FA     JP 07Ah
 072  51     AISC 1
 073  06     X 0
 074  5F     AISC 15
 075  FB     JP 07Bh
 076  16     X 1
 077  02     XOR
 078  06     X 0
 079  FD     JP 07Dh
>07A  93     JP 053h
>07B  75     STII 5
 07C  94     JP 054h
>07D  60 17  JMP 017h
 07F  00     CLRA

; ---- pagina 2 (080h-0BFh) ----
 080  62 CF  JMP 2CFh
 082  DA     JP 09Ah
>083  D4     JP 094h
 084  EB     JP 0ABh
 085  F7     JP 0B7h
 086  68 94  JSR 094h
>088  68 8E  JSR 08Eh
 08A  68 8E  JSR 08Eh
>08C  68 8E  JSR 08Eh
>08E  44     NOP
 08F  44     NOP
 090  44     NOP
>091  44     NOP
>092  44     NOP
>093  44     NOP
>094  AA     JSRP 0AAh
 095  1C     LBI 1,3
 096  05     LD 0
 097  30     DB 30h
 098  44     NOP
 099  16     X 1
>09A  05     LD 0
 09B  A7     JSRP 0A7h
 09C  08     LBI 0,7
 09D  00     CLRA
 09E  06     X 0
 09F  1B     LBI 1,4
 0A0  32     RC
 0A1  30     DB 30h
 0A2  44     NOP
 0A3  07     XDS 0
 0A4  A6     JSRP 0A6h
 0A5  22     SC
>0A6  00     CLRA
>0A7  30     DB 30h
 0A8  44     NOP
 0A9  07     XDS 0
>0AA  48     RET
>0AB  19     LBI 1,6
 0AC  47     SMB 1
 0AD  B1     JSRP 0B1h
 0AE  19     LBI 1,6
 0AF  45     RMB 1
 0B0  19     LBI 1,6
>0B1  05     LD 0
 0B2  50     CAB
 0B3  33 3E  OBD
 0B5  48     RET
 0B6  33 3C  CAMQ
 0B8  0A     LBI 0,5
 0B9  4D     SMB 0
 0BA  33 3A  OMG
 0BC  61 10  JMP 110h
 0BE  32     RC
 0BF  00     CLRA

; ---- pagina 3 (0C0h-0FFh) ----
 0C0  4F     XAS
 0C1  0F     LBI 0,0
 0C2  4B     SMB 3
 0C3  5F     AISC 15
 0C4  43     RMB 3
 0C5  08     LBI 0,7
 0C6  CF     JP 0CFh
>0C7  05     LD 0
 0C8  51     AISC 1
 0C9  CE     JP 0CEh
 0CA  0F     LBI 0,0
 0CB  46     SMB 2
 0CC  4C     RMB 0
 0CD  48     RET
>0CE  06     X 0
>0CF  00     CLRA
 0D0  4F     XAS
 0D1  5F     AISC 15
 0D2  C7     JP 0C7h
 0D3  48     RET
 0D4  00     CLRA
 0D5  16     X 1
 0D6  00     CLRA
 0D7  17     XDS 1
 0D8  83     JSRP 083h
 0D9  48     RET
 0DA  33 5F  OGI 15
>0DC  33 01  SKGBZ 0
 0DE  DC     JP 0DCh
 0DF  91     JSRP 091h
>0E0  33 5E  OGI 14
 0E2  0B     LBI 0,4
>0E3  33 2A  ING
 0E5  06     X 0
 0E6  21     SKE
 0E7  00     CLRA
 0E8  0E     LBI 0,1
 0E9  06     X 0
 0EA  48     RET
 0EB  09     LBI 0,6
 0EC  05     LD 0
 0ED  51     AISC 1
 0EE  16     X 1
 0EF  4D     SMB 0
 0F0  42     RMB 2
 0F1  59     AISC 9
 0F2  48     RET
 0F3  4C     RMB 0
 0F4  09     LBI 0,6
 0F5  70     STII 0
 0F6  49     RETSK
 0F7  09     LBI 0,6
 0F8  25     LD 2
 0F9  50     CAB
 0FA  15     LD 1
 0FB  23 8E  LDD 0,14
 0FD  05     LD 0
 0FE  1D     LBI 1,2
 0FF  16     X 1

; ---- pagina 4 (100h-13Fh) ----
 100  43     RMB 3
 101  15     LD 1
>102  BF     LQID
 103  0E     LBI 0,1
 104  33 2C  CQMA
 106  16     X 1
 107  17     XDS 1
>108  15     LD 1
 109  54     AISC 4
>10A  BF     LQID
>10B  33 2C  CQMA
 10D  16     X 1
>10E  06     X 0
 10F  48     RET
>110  4C     RMB 0
 111  8E     JP 10Eh
 112  8E     JP 10Eh
 113  90     JP 110h
 114  33 3A  OMG
 116  8E     JP 10Eh
 117  8E     JP 10Eh
 118  8E     JP 10Eh
>119  0E     LBI 0,1
 11A  33 2C  CQMA
 11C  13     SKMBZ 3
 11D  49     RETSK
 11E  48     RET
 11F  00     CLRA
>120  00     CLRA
 121  AC     JP 12Ch
 122  10     CASC
 123  5B     AISC 11
 124  9B     JP 11Bh
 125  21     SKE
 126  AD     JP 12Dh
 127  10     CASC
 128  20     SKC
>129  04     XIS 0
 12A  36     X 3
 12B  12     XABR
>12C  00     CLRA
>12D  02     XOR
 12E  00     CLRA
 12F  20     SKC
 130  E9     JP 129h
 131  18     LBI 1,7
 132  CA     JP 10Ah
 133  CB     JP 10Bh
 134  43     RMB 3
 135  88     JP 108h
 136  8B     JP 10Bh
 137  A0     JP 120h
 138  CB     JP 10Bh
 139  CB     JP 10Bh
 13A  88     JP 108h
 13B  10     CASC
 13C  28     LBI 2,7
 13D  0A     LBI 0,5
 13E  0C     LBI 0,3
 13F  C2     JP 102h

; ---- pagina 5 (140h-17Fh) ----
 140  C9     JP 149h
>141  C3     JP 143h
>142  DB     JP 15Bh
>143  C8     JP 148h
>144  D9     JP 159h
 145  8A     JP 14Ah
 146  82     JP 142h
 147  8B     JP 14Bh
>148  43     RMB 3
>149  98     JP 158h
>14A  49     RETSK
>14B  20     SKC
 14C  08     LBI 0,7
 14D  65     DB 65h
 14E  45     RMB 1
 14F  C9     JP 149h
>150  C2     JP 142h
 151  C9     JP 149h
 152  C2     JP 142h
 153  8B     JP 14Bh
 154  90     JP 150h
 155  49     RETSK
 156  20     SKC
 157  41     SKT
>158  24     XIS 2
>159  4B     SMB 3
 15A  A8     JP 168h
>15B  88     JP 148h
 15C  04     XIS 0
 15D  C9     JP 149h
 15E  00     CLRA
 15F  2A     LBI 2,5
 160  00     CLRA
>161  81     JP 141h
 162  40     COMP
 163  25     LD 2
 164  E5     JP 165h
>165  48     RET
 166  B3     JP 173h
 167  00     CLRA
>168  02     XOR
 169  08     LBI 0,7
 16A  2E     LBI 2,1
 16B  24     XIS 2
 16C  08     LBI 0,7
 16D  20     SKC
 16E  04     XIS 0
 16F  08     LBI 0,7
 170  D9     JP 159h
>171  05     LD 0
 172  89     JP 149h
>173  81     JP 141h
 174  60 E3  JMP 0E3h
 176  F1     JP 171h
 177  88     JP 148h
 178  F1     JP 171h
 179  E1     JP 161h
 17A  81     JP 141h
 17B  08     LBI 0,7
 17C  09     LBI 0,6
 17D  21     SKE
 17E  03     SKMBZ 2
 17F  C4     JP 144h

; ---- pagina 6 (180h-1BFh) ----
 180  B5     JP 1B5h
>181  F0     JP 1B0h
 182  85     JP 185h
 183  D1     JP 191h
>184  85     JP 185h
>185  F1     JP 1B1h
 186  F0     JP 1B0h
 187  D1     JP 191h
 188  70     STII 0
>189  85     JP 185h
 18A  11     SKMBZ 1
 18B  72     STII 2
 18C  51     AISC 1
 18D  50     CAB
 18E  52     AISC 2
 18F  D1     JP 191h
 190  F0     JP 1B0h
>191  D3     JP 193h
 192  F2     JP 1B2h
>193  E1     JP 1A1h
 194  84     JP 184h
 195  51     AISC 1
 196  58     AISC 8
 197  5A     AISC 10
 198  0A     LBI 0,5
 199  61 89  JMP 189h
 19B  D1     JP 191h
 19C  02     XOR
 19D  81     JP 181h
 19E  0A     LBI 0,5
 19F  25     LD 2
>1A0  23 0A  LDD 0,10
 1A2  21     SKE
 1A3  60 8C  JMP 08Ch
 1A5  16     X 1
 1A6  05     LD 0
 1A7  0E     LBI 0,1
 1A8  16     X 1
 1A9  15     LD 1
>1AA  16     X 1
 1AB  5F     AISC 15
 1AC  4C     RMB 0
 1AD  5F     AISC 15
 1AE  45     RMB 1
 1AF  5F     AISC 15
>1B0  42     RMB 2
>1B1  5F     AISC 15
>1B2  43     RMB 3
 1B3  15     LD 1
 1B4  21     SKE
>1B5  49     RETSK
 1B6  48     RET
>1B7  1E     LBI 1,1
 1B8  15     LD 1
 1B9  22     SC
 1BA  4F     XAS
 1BB  AA     JP 1AAh
 1BC  07     XDS 0
 1BD  4F     XAS
 1BE  AA     JP 1AAh
 1BF  15     LD 1

; ---- pagina 7 (1C0h-1FFh) ----
 1C0  4F     XAS
 1C1  AA     JP 1EAh
 1C2  05     LD 0
 1C3  4F     XAS
 1C4  19     LBI 1,6
 1C5  46     SMB 2
 1C6  32     RC
 1C7  4F     XAS
>1C8  48     RET
>1C9  0C     LBI 0,3
>1CA  01     SKMBZ 0
 1CB  CF     JP 1CFh
 1CC  75     STII 5
 1CD  88     JP 1C8h
 1CE  E3     JP 1E3h
>1CF  1B     LBI 1,4
 1D0  69 A0  JSR 1A0h
 1D2  DA     JP 1DAh
>1D3  0C     LBI 0,3
 1D4  03     SKMBZ 2
 1D5  4B     SMB 3
 1D6  42     RMB 2
 1D7  1C     LBI 1,3
 1D8  7D     STII 13
 1D9  DB     JP 1DBh
>1DA  91     JP 1D1h
>1DB  23 1F  LDD 1,15
 1DD  5F     AISC 15
 1DE  F9     JP 1F9h
 1DF  0C     LBI 0,3
 1E0  11     SKMBZ 1
 1E1  FC     JP 1FCh
 1E2  47     SMB 1
>1E3  1E     LBI 1,1
 1E4  00     CLRA
 1E5  53     AISC 3
 1E6  01     SKMBZ 0
 1E7  5F     AISC 15
 1E8  11     SKMBZ 1
 1E9  5F     AISC 15
>1EA  03     SKMBZ 2
 1EB  5F     AISC 15
 1EC  44     NOP
 1ED  0C     LBI 0,3
 1EE  11     SKMBZ 1
 1EF  33 87  EXT 87
 1F1  0B     LBI 0,4
 1F2  16     X 1
 1F3  23 0A  LDD 0,10
 1F5  04     XIS 0
 1F6  7F     STII 15
 1F7  93     JP 1D3h
 1F8  FA     JP 1FAh
>1F9  8A     JP 1CAh
>1FA  60 92  JMP 092h
>1FC  33 97  EXT 97
 1FE  69 A0  JSR 1A0h

; ---- pagina 8 (200h-23Fh) ----
 200  60 93  JMP 093h
>202  33 98  EXT 98
 204  79     STII 9
 205  48     RET
 206  00     CLRA
 207  00     CLRA
 208  F3     JP 233h
>209  A4     JP 224h
>20A  C2     JP 202h
 20B  B9     JP 239h
 20C  AA     JP 22Ah
>20D  CD     JP 20Dh
>20E  C9     JP 209h
 20F  AA     JP 22Ah
>210  08     LBI 0,7
>211  01     SKMBZ 0
 212  E2     JP 222h
>213  1B     LBI 1,4
 214  05     LD 0
 215  5D     AISC 13
 216  40     COMP
 217  08     LBI 0,7
 218  01     SKMBZ 0
 219  51     AISC 1
 21A  EA     JP 22Ah
 21B  1F     LBI 1,0
 21C  01     SKMBZ 0
 21D  E9     JP 229h
 21E  71     STII 1
 21F  7A     STII 10
 220  70     STII 0
 221  EE     JP 22Eh
>222  8E     JP 20Eh
 223  1B     LBI 1,4
>224  01     SKMBZ 0
>225  E9     JP 229h
 226  71     STII 1
 227  7F     STII 15
 228  7B     STII 11
>229  EE     JP 22Eh
>22A  44     NOP
 22B  1F     LBI 1,0
 22C  70     STII 0
 22D  93     JP 213h
>22E  33 92  EXT 92
 230  A5     JP 225h
 231  A2     JP 222h
 232  01     SKMBZ 0
>233  20     SKC
 234  FB     JP 23Bh
 235  71     STII 1
 236  7B     STII 11
 237  7C     STII 12
 238  08     LBI 0,7
>239  42     RMB 2
 23A  FC     JP 23Ch
>23B  91     JP 211h
>23C  90     JP 210h
 23D  8A     JP 20Ah
 23E  33 98  EXT 98

; ---- pagina 9 (240h-27Fh) ----
 240  A5     JP 265h
 241  0C     LBI 0,3
 242  5F     AISC 15
 243  45     RMB 1
 244  1C     LBI 1,3
 245  A5     JP 265h
 246  5F     AISC 15
 247  CA     JP 24Ah
 248  94     JP 254h
 249  CE     JP 24Eh
>24A  0C     LBI 0,3
 24B  11     SKMBZ 1
 24C  D0     JP 250h
 24D  70     STII 0
>24E  8E     JP 24Eh
 24F  DB     JP 25Bh
>250  75     STII 5
>251  1C     LBI 1,3
 252  23 18  LDD 1,8
>254  07     XDS 0
 255  23 17  LDD 1,7
 257  16     X 1
 258  23 07  LDD 0,7
 25A  06     X 0
>25B  48     RET
>25C  11     SKMBZ 1
 25D  E4     JP 264h
 25E  33 86  EXT 86
 260  A5     JP 265h
 261  5F     AISC 15
 262  4C     RMB 0
 263  F1     JP 271h
>264  33 86  EXT 86
>266  7D     STII 13
 267  33 85  EXT 85
 269  01     SKMBZ 0
 26A  EF     JP 26Fh
 26B  4D     SMB 0
 26C  0F     LBI 0,0
 26D  46     SMB 2
 26E  F0     JP 270h
>26F  93     JP 253h
>270  44     NOP
>271  33 84  EXT 84
 273  A5     JP 265h
 274  A6     JP 266h
 275  A6     JP 266h
 276  A6     JP 266h
 277  20     SKC
 278  01     SKMBZ 0
 279  4D     SMB 0
 27A  09     LBI 0,6
 27B  72     STII 2
 27C  8A     JP 24Ah
 27D  91     JP 251h
 27E  0C     LBI 0,3
 27F  13     SKMBZ 3

; ---- pagina 10 (280h-2BFh) ----
 280  C3     JP 283h
 281  60 AA  JMP 0AAh
>283  1A     LBI 1,5
 284  03     SKMBZ 2
 285  48     RET
>286  43     RMB 3
 287  08     LBI 0,7
 288  23 0C  LDD 0,12
>28A  03     SKMBZ 2
 28B  54     AISC 4
 28C  13     SKMBZ 3
 28D  58     AISC 8
 28E  11     SKMBZ 1
 28F  5C     AISC 12
 290  44     NOP
 291  23 88  LDD 0,8
 293  8A     JP 28Ah
 294  19     LBI 1,6
 295  42     RMB 2
 296  B1     JP 2B1h
 297  00     CLRA
 298  53     AISC 3
 299  B6     JP 2B6h
 29A  48     RET
 29B  23 08  LDD 0,8
 29D  1B     LBI 1,4
 29E  33 3C  CAMQ
 2A0  0C     LBI 0,3
 2A1  43     RMB 3
 2A2  60 88  JMP 088h
 2A4  33 3C  CAMQ
>2A6  69 19  JSR 119h
 2A8  E6     JP 2A6h
 2A9  EE     JP 2AEh
 2AA  86     JP 286h
 2AB  0E     LBI 0,1
 2AC  33 3E  OBD
>2AE  60 13  JMP 013h
>2B0  FF     JID
>2B1  03     SKMBZ 2
 2B2  F5     JP 2B5h
 2B3  63 00  JMP 300h
>2B5  0F     LBI 0,0
>2B6  63 A8  JMP 3A8h
 2B8  00     CLRA
 2B9  82     JP 282h
 2BA  33 84  EXT 84
 2BC  33 2C  CQMA
 2BE  07     XDS 0
 2BF  07     XDS 0

; ---- pagina 11 (2C0h-2FFh) ----
 2C0  44     NOP
 2C1  33 2C  CQMA
>2C3  07     XDS 0
 2C4  07     XDS 0
>2C5  CD     JP 2CDh
 2C6  82     JP 2C2h
 2C7  3E     LBI 3,1
>2C8  33 2C  CQMA
 2CA  16     X 1
 2CB  17     XDS 1
>2CC  C8     JP 2C8h
>2CD  60 32  JMP 032h
>2CF  09     LBI 0,6
 2D0  25     LD 2
 2D1  50     CAB
 2D2  05     LD 0
 2D3  33 91  EXT 91
 2D5  11     SKMBZ 1
 2D6  58     AISC 8
 2D7  E1     JP 2E1h
 2D8  0D     LBI 0,2
 2D9  70     STII 0
 2DA  78     STII 8
 2DB  1D     LBI 1,2
 2DC  71     STII 1
 2DD  70     STII 0
 2DE  8C     JP 2CCh
 2DF  94     JP 2D4h
 2E0  E2     JP 2E2h
>2E1  85     JP 2C5h
>2E2  19     LBI 1,6
 2E3  42     RMB 2
 2E4  4D     SMB 0
 2E5  B1     JP 2F1h
 2E6  69 B7  JSR 1B7h
 2E8  1E     LBI 1,1
>2E9  0E     LBI 0,1
 2EA  33 28  ININ
 2EC  06     X 0
 2ED  33 2A  ING
 2EF  01     SKMBZ 0
 2F0  51     AISC 1
>2F1  06     X 0
 2F2  48     RET
 2F3  23 1B  LDD 1,11
 2F5  0E     LBI 0,1
 2F6  07     XDS 0
 2F7  83     JP 2C3h
 2F8  05     LD 0
 2F9  0A     LBI 0,5
 2FA  06     X 0
 2FB  33 3A  OMG
 2FD  62 B1  JMP 2B1h
 2FF  00     CLRA

; ---- pagina 12 (300h-33Fh) ----
>300  AE     JP 32Eh
 301  85     JP 305h
 302  69 B7  JSR 1B7h
>304  8E     JP 30Eh
>305  05     LD 0
>306  08     LBI 0,7
 307  01     SKMBZ 0
>308  52     AISC 2
 309  B2     JP 332h
 30A  86     JP 306h
 30B  8E     JP 30Eh
>30C  90     JP 310h
 30D  AB     JP 32Bh
>30E  84     JP 304h
>30F  92     JP 312h
>310  B0     JP 330h
 311  8F     JP 30Fh
>312  8E     JP 30Eh
>313  08     LBI 0,7
 314  A5     JP 325h
>315  A6     JP 326h
 316  A6     JP 326h
 317  20     SKC
 318  C0     JP 300h
>319  AE     JP 32Eh
 31A  86     JP 306h
 31B  AB     JP 32Bh
 31C  86     JP 306h
 31D  AE     JP 32Eh
 31E  88     JP 308h
>31F  93     JP 313h
 320  AB     JP 32Bh
 321  85     JP 305h
 322  8E     JP 30Eh
 323  92     JP 312h
 324  AE     JP 32Eh
>325  69 B7  JSR 1B7h
 327  8E     JP 30Eh
 328  8F     JP 30Fh
 329  0C     LBI 0,3
 32A  13     SKMBZ 3
>32B  F0     JP 330h
 32C  AE     JP 32Eh
 32D  86     JP 306h
>32E  AB     JP 32Bh
 32F  F4     JP 334h
>330  AB     JP 32Bh
 331  86     JP 306h
>332  AE     JP 32Eh
 333  44     NOP
>334  95     JP 315h
 335  8C     JP 30Ch
 336  93     JP 313h
 337  84     JP 304h
 338  DF     JP 31Fh
 339  AB     JP 32Bh
 33A  86     JP 306h
 33B  AE     JP 32Eh
 33C  68 E0  JSR 0E0h
 33E  00     CLRA
 33F  54     AISC 4

; ---- pagina 13 (340h-37Fh) ----
 340  B6     JP 376h
 341  D2     JP 352h
 342  8F     JP 34Fh
 343  AA     JP 36Ah
 344  AB     JP 36Bh
 345  0E     LBI 0,1
>346  03     SKMBZ 2
 347  DA     JP 35Ah
>348  86     JP 346h
 349  1C     LBI 1,3
 34A  69 0B  JSR 10Bh
 34C  88     JP 348h
 34D  63 19  JMP 319h
>34F  0D     LBI 0,2
>350  0C     LBI 0,3
>351  0B     LBI 0,4
>352  0E     LBI 0,1
 353  4E     CBA
 354  1E     LBI 1,1
 355  06     X 0
 356  00     CLRA
 357  51     AISC 1
 358  B6     JP 376h
 359  D2     JP 352h
>35A  60 13  JMP 013h
>35C  11     SKMBZ 1
 35D  E1     JP 361h
 35E  13     SKMBZ 3
 35F  E8     JP 368h
 360  EC     JP 36Ch
>361  03     SKMBZ 2
 362  CF     JP 34Fh
 363  13     SKMBZ 3
 364  D0     JP 350h
 365  68 E0  JSR 0E0h
 367  F0     JP 370h
>368  01     SKMBZ 0
 369  63 BA  JMP 3BAh
>36B  46     SMB 2
>36C  68 E0  JSR 0E0h
 36E  4D     SMB 0
 36F  44     NOP
>370  00     CLRA
 371  52     AISC 2
 372  B6     JP 376h
 373  D2     JP 352h
 374  03     SKMBZ 2
 375  DA     JP 35Ah
>376  0C     LBI 0,3
 377  15     LD 1
 378  33 3C  CAMQ
 37A  BE     JP 37Eh
 37B  9C     JP 35Ch
 37C  6B F8  JSR 3F8h
>37E  23 1B  LDD 1,11

; ---- pagina 14 (380h-3BFh) ----
 380  5B     AISC 11
 381  CF     JP 38Fh
 382  00     CLRA
 383  56     AISC 6
 384  9F     JP 39Fh
 385  23 1B  LDD 1,11
 387  5A     AISC 10
 388  D5     JP 395h
 389  18     LBI 1,7
>38A  05     LD 0
 38B  5F     AISC 15
 38C  44     NOP
 38D  06     X 0
>38E  D6     JP 396h
>38F  18     LBI 1,7
>390  05     LD 0
>391  51     AISC 1
>392  06     X 0
>393  92     JP 392h
 394  8E     JP 38Eh
>395  91     JP 391h
>396  0F     LBI 0,0
 397  11     SKMBZ 1
 398  F5     JP 3B5h
 399  03     SKMBZ 2
 39A  E8     JP 3A8h
 39B  13     SKMBZ 3
 39C  E5     JP 3A5h
 39D  33 82  EXT 82
>39F  A5     JP 3A5h
 3A0  A6     JP 3A6h
 3A1  20     SKC
 3A2  01     SKMBZ 0
 3A3  4D     SMB 0
 3A4  FE     JP 3BEh
>3A5  90     JP 390h
>3A6  01     SKMBZ 0
>3A7  FC     JP 3BCh
>3A8  70     STII 0
 3A9  7C     STII 12
 3AA  70     STII 0
 3AB  05     LD 0
 3AC  51     AISC 1
 3AD  F3     JP 3B3h
 3AE  06     X 0
 3AF  19     LBI 1,6
 3B0  00     CLRA
 3B1  52     AISC 2
 3B2  02     XOR
>3B3  06     X 0
 3B4  FE     JP 3BEh
>3B5  90     JP 390h
 3B6  13     SKMBZ 3
 3B7  FB     JP 3BBh
 3B8  63 51  JMP 351h
>3BA  8A     JP 38Ah
>3BB  93     JP 393h
>3BC  8E     JP 38Eh
 3BD  47     SMB 1
>3BE  93     JP 393h
 3BF  09     LBI 0,6

; ---- pagina 15 (3C0h-3FFh) ----
 3C0  00     CLRA
 3C1  16     X 1
 3C2  4C     RMB 0
 3C3  42     RMB 2
>3C4  1A     LBI 1,5
>3C5  70     STII 0
 3C6  78     STII 8
>3C7  85     JP 3C5h
 3C8  B0     JP 3F0h
 3C9  BE     JP 3FEh
 3CA  33 68  LEI 8
 3CC  69 B7  JSR 1B7h
>3CE  33 61  LEI 1
 3D0  B1     JP 3F1h
 3D1  6B F8  JSR 3F8h
 3D3  94     JP 3D4h
>3D4  9C     JP 3DCh
>3D5  0F     LBI 0,0
 3D6  13     SKMBZ 3
 3D7  11     SKMBZ 1
 3D8  DD     JP 3DDh
 3D9  01     SKMBZ 0
 3DA  63 A7  JMP 3A7h
>3DC  46     SMB 2
>3DD  32     RC
 3DE  13     SKMBZ 3
>3DF  22     SC
 3E0  95     JP 3D5h
 3E1  84     JP 3C4h
 3E2  C7     JP 3C7h
 3E3  18     LBI 1,7
 3E4  05     LD 0
>3E5  30     DB 30h
 3E6  EB     JP 3EBh
 3E7  9F     JP 3DFh
 3E8  1A     LBI 1,5
 3E9  A5     JP 3E5h
>3EA  ED     JP 3EDh
>3EB  9F     JP 3DFh
 3EC  8E     JP 3CEh
>3ED  B0     JP 3F0h
 3EE  BE     JP 3FEh
 3EF  9C     JP 3DCh
>3F0  44     NOP
>3F1  6B F8  JSR 3F8h
 3F3  0F     LBI 0,0
 3F4  63 5C  JMP 35Ch
>3F6  AA     JP 3EAh
 3F7  FD     JP 3FDh
>3F8  32     RC
 3F9  00     CLRA
 3FA  4F     XAS
 3FB  23 19  LDD 1,9
>3FD  51     AISC 1
>3FE  F6     JP 3F6h
 3FF  48     RET
