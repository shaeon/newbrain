//============================================================================
// Core COP400, generado a partir del VHDL del proyecto T400 de Arnim Laeuger
// (https://github.com/devsaurus/t400), licencia BSD de tres clausulas.
//
// NO EDITAR A MANO. Se regenera con:
//
//     tools/convierte_t400.sh common/T400 > rtl/t400_core.v
//
// Genericos horneados en esta version:
//   COP420, divisor CKI de 16, MICROBUS activado.
//
// El VHDL original se conserva en common/T400 como referencia y por la
// licencia. Lo que se compila es este fichero, para que Icarus pueda
// simularlo junto al resto del core.
//============================================================================

module t400_timer
  (input  ck_i,
   input  ck_en_i,
   input  por_i,
   input  icyc_en_i,
   input  [3:0] op_i,
   output c_o);
  wire [9:0] cnt_q;
  wire c_q;
  wire n2952_o;
  wire [9:0] n2954_o;
  wire [9:0] n2956_o;
  wire n2958_o;
  wire n2960_o;
  wire n2962_o;
  wire n2963_o;
  wire n2965_o;
  wire [9:0] n2973_o;
  reg [9:0] n2974_q;
  reg n2975_q;
  assign c_o = c_q;
  /* src/t400_timer.vhd:67:10  */
  assign cnt_q = n2974_q; // (signal)
  /* src/t400_timer.vhd:68:10  */
  assign c_q = n2975_q; // (signal)
  /* src/t400_timer.vhd:88:18  */
  assign n2952_o = cnt_q == 10'b0000000000;
  /* src/t400_timer.vhd:95:26  */
  assign n2954_o = cnt_q - 10'b0000000001;
  /* src/t400_timer.vhd:88:9  */
  assign n2956_o = n2952_o ? 10'b1111111111 : n2954_o;
  /* src/t400_timer.vhd:87:7  */
  assign n2958_o = n2960_o ? 1'b1 : c_q;
  /* src/t400_timer.vhd:87:7  */
  assign n2960_o = n2952_o & icyc_en_i;
  /* src/t400_timer.vhd:99:27  */
  assign n2962_o = op_i == 4'b1100;
  /* src/t400_timer.vhd:99:18  */
  assign n2963_o = n2962_o & ck_en_i;
  /* src/t400_timer.vhd:99:7  */
  assign n2965_o = n2963_o ? 1'b0 : n2958_o;
  /* src/t400_timer.vhd:86:5  */
  assign n2973_o = icyc_en_i ? n2956_o : cnt_q;
  /* src/t400_timer.vhd:86:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2974_q <= 10'b1111111111;
    else
      n2974_q <= n2973_o;
  /* src/t400_timer.vhd:86:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2975_q <= 1'b0;
    else
      n2975_q <= n2965_o;
endmodule

module t400_sio_0_0
  (input  ck_i,
   input  ck_en_i,
   input  por_i,
   input  res_i,
   input  phi1_i,
   input  out_en_i,
   input  in_en_i,
   input  op_i,
   input  en0_i,
   input  en3_i,
   input  [3:0] a_i,
   input  c_i,
   input  si_i,
   output [3:0] sio_o,
   output so_o,
   output so_en_o,
   output sk_o,
   output sk_en_o);
  wire si_q;
  wire [1:0] si_flt_s;
  wire [1:0] si_flt_q;
  wire si_0_ok_s;
  wire si_1_ok_s;
  wire si_0_ok_q;
  wire si_1_ok_q;
  wire dec_sio_s;
  wire [3:0] new_sio_s;
  wire [3:0] sio_q;
  wire skl_q;
  wire phi1_en_q;
  wire so_s;
  wire sk_s;
  wire n2812_o;
  wire [1:0] n2813_o;
  wire n2814_o;
  wire n2815_o;
  wire n2817_o;
  wire n2818_o;
  wire [3:0] n2819_o;
  wire n2820_o;
  wire n2821_o;
  wire n2822_o;
  wire [1:0] n2823_o;
  wire n2824_o;
  wire n2825_o;
  wire [3:0] n2826_o;
  wire n2828_o;
  wire n2830_o;
  wire n2854_o;
  wire [2:0] n2855_o;
  wire [3:0] n2857_o;
  wire [3:0] n2858_o;
  wire [3:0] n2859_o;
  wire [3:0] n2860_o;
  wire [3:0] n2861_o;
  wire n2864_o;
  wire [1:0] n2867_o;
  wire n2869_o;
  wire n2870_o;
  wire n2871_o;
  wire n2872_o;
  wire n2875_o;
  wire [1:0] n2877_o;
  wire n2879_o;
  wire n2881_o;
  wire n2883_o;
  wire n2885_o;
  wire [1:0] n2888_o;
  wire n2890_o;
  wire [1:0] n2892_o;
  wire n2894_o;
  wire n2896_o;
  wire n2898_o;
  wire [3:0] n2899_o;
  reg [1:0] n2900_o;
  reg n2901_o;
  reg n2903_o;
  reg n2905_o;
  wire n2908_o;
  wire n2909_o;
  wire n2910_o;
  wire n2911_o;
  wire n2912_o;
  localparam n2926_o = 1'b1;
  localparam n2940_o = 1'b1;
  reg n2941_q;
  reg [1:0] n2942_q;
  reg n2943_q;
  reg n2944_q;
  reg [3:0] n2945_q;
  reg n2946_q;
  reg n2947_q;
  assign sio_o = new_sio_s;
  assign so_o = so_s;
  assign so_en_o = n2926_o;
  assign sk_o = sk_s;
  assign sk_en_o = n2940_o;
  /* src/t400_sio.vhd:88:10  */
  assign si_q = n2941_q; // (signal)
  /* src/t400_sio.vhd:91:10  */
  assign si_flt_s = n2900_o; // (signal)
  /* src/t400_sio.vhd:92:10  */
  assign si_flt_q = n2942_q; // (signal)
  /* src/t400_sio.vhd:93:10  */
  assign si_0_ok_s = n2901_o; // (signal)
  /* src/t400_sio.vhd:94:10  */
  assign si_1_ok_s = n2903_o; // (signal)
  /* src/t400_sio.vhd:95:10  */
  assign si_0_ok_q = n2943_q; // (signal)
  /* src/t400_sio.vhd:96:10  */
  assign si_1_ok_q = n2944_q; // (signal)
  /* src/t400_sio.vhd:97:10  */
  assign dec_sio_s = n2905_o; // (signal)
  /* src/t400_sio.vhd:99:10  */
  assign new_sio_s = n2861_o; // (signal)
  /* src/t400_sio.vhd:100:10  */
  assign sio_q = n2945_q; // (signal)
  /* src/t400_sio.vhd:101:10  */
  assign skl_q = n2946_q; // (signal)
  /* src/t400_sio.vhd:102:10  */
  assign phi1_en_q = n2947_q; // (signal)
  /* src/t400_sio.vhd:104:10  */
  assign so_s = n2910_o; // (signal)
  /* src/t400_sio.vhd:105:10  */
  assign sk_s = n2912_o; // (signal)
  /* src/t400_sio.vhd:132:9  */
  assign n2812_o = in_en_i ? si_i : si_q;
  /* src/t400_sio.vhd:137:9  */
  assign n2813_o = out_en_i ? si_flt_s : si_flt_q;
  /* src/t400_sio.vhd:137:9  */
  assign n2814_o = out_en_i ? si_0_ok_s : si_0_ok_q;
  /* src/t400_sio.vhd:137:9  */
  assign n2815_o = out_en_i ? si_1_ok_s : si_1_ok_q;
  /* src/t400_sio.vhd:146:20  */
  assign n2817_o = op_i == 1'b1;
  /* src/t400_sio.vhd:146:31  */
  assign n2818_o = ck_en_i & n2817_o;
  /* src/t400_sio.vhd:146:9  */
  assign n2819_o = n2818_o ? a_i : new_sio_s;
  /* src/t400_sio.vhd:146:9  */
  assign n2820_o = n2818_o ? c_i : skl_q;
  /* src/t400_sio.vhd:155:9  */
  assign n2821_o = ck_en_i ? skl_q : phi1_en_q;
  /* src/t400_sio.vhd:127:7  */
  assign n2822_o = res_i ? si_q : n2812_o;
  /* src/t400_sio.vhd:127:7  */
  assign n2823_o = res_i ? si_flt_q : n2813_o;
  /* src/t400_sio.vhd:127:7  */
  assign n2824_o = res_i ? si_0_ok_q : n2814_o;
  /* src/t400_sio.vhd:127:7  */
  assign n2825_o = res_i ? si_1_ok_q : n2815_o;
  /* src/t400_sio.vhd:127:7  */
  assign n2826_o = res_i ? sio_q : n2819_o;
  /* src/t400_sio.vhd:127:7  */
  assign n2828_o = res_i ? 1'b1 : n2820_o;
  /* src/t400_sio.vhd:127:7  */
  assign n2830_o = res_i ? 1'b1 : n2821_o;
  /* src/t400_sio.vhd:187:16  */
  assign n2854_o = ~en0_i;
  /* src/t400_sio.vhd:189:39  */
  assign n2855_o = sio_q[2:0];
  /* src/t400_sio.vhd:195:30  */
  assign n2857_o = sio_q - 4'b0001;
  /* src/t400_sio.vhd:194:9  */
  assign n2858_o = dec_sio_s ? n2857_o : sio_q;
  assign n2859_o = {n2855_o, si_q};
  /* src/t400_sio.vhd:187:7  */
  assign n2860_o = n2854_o ? n2859_o : n2858_o;
  /* src/t400_sio.vhd:186:5  */
  assign n2861_o = out_en_i ? n2860_o : sio_q;
  /* src/t400_sio.vhd:223:17  */
  assign n2864_o = ~si_q;
  /* src/t400_sio.vhd:223:9  */
  assign n2867_o = n2864_o ? 2'b01 : 2'b10;
  /* src/t400_sio.vhd:222:7  */
  assign n2869_o = si_flt_q == 2'b00;
  /* src/t400_sio.vhd:230:17  */
  assign n2870_o = ~si_q;
  /* src/t400_sio.vhd:233:14  */
  assign n2871_o = ~si_0_ok_q;
  /* src/t400_sio.vhd:233:28  */
  assign n2872_o = si_1_ok_q & n2871_o;
  /* src/t400_sio.vhd:233:11  */
  assign n2875_o = n2872_o ? 1'b1 : 1'b0;
  /* src/t400_sio.vhd:230:9  */
  assign n2877_o = n2870_o ? si_flt_q : 2'b10;
  /* src/t400_sio.vhd:230:9  */
  assign n2879_o = n2870_o ? 1'b1 : si_0_ok_q;
  /* src/t400_sio.vhd:230:9  */
  assign n2881_o = n2870_o ? si_1_ok_q : 1'b0;
  /* src/t400_sio.vhd:230:9  */
  assign n2883_o = n2870_o ? n2875_o : 1'b0;
  /* src/t400_sio.vhd:229:7  */
  assign n2885_o = si_flt_q == 2'b01;
  /* src/t400_sio.vhd:245:9  */
  assign n2888_o = si_q ? 2'b11 : 2'b00;
  /* src/t400_sio.vhd:243:7  */
  assign n2890_o = si_flt_q == 2'b10;
  /* src/t400_sio.vhd:252:9  */
  assign n2892_o = si_q ? si_flt_q : 2'b00;
  /* src/t400_sio.vhd:252:9  */
  assign n2894_o = si_q ? si_0_ok_q : 1'b0;
  /* src/t400_sio.vhd:252:9  */
  assign n2896_o = si_q ? 1'b1 : si_1_ok_q;
  /* src/t400_sio.vhd:251:7  */
  assign n2898_o = si_flt_q == 2'b11;
  assign n2899_o = {n2898_o, n2890_o, n2885_o, n2869_o};
  /* src/t400_sio.vhd:221:5  */
  always @*
    case (n2899_o)
      4'b1000: n2900_o = n2892_o;
      4'b0100: n2900_o = n2888_o;
      4'b0010: n2900_o = n2877_o;
      4'b0001: n2900_o = n2867_o;
      default: n2900_o = si_flt_q;
    endcase
  /* src/t400_sio.vhd:221:5  */
  always @*
    case (n2899_o)
      4'b1000: n2901_o = n2894_o;
      4'b0100: n2901_o = si_0_ok_q;
      4'b0010: n2901_o = n2879_o;
      4'b0001: n2901_o = si_0_ok_q;
      default: n2901_o = si_0_ok_q;
    endcase
  /* src/t400_sio.vhd:221:5  */
  always @*
    case (n2899_o)
      4'b1000: n2903_o = n2896_o;
      4'b0100: n2903_o = 1'b0;
      4'b0010: n2903_o = n2881_o;
      4'b0001: n2903_o = si_1_ok_q;
      default: n2903_o = si_1_ok_q;
    endcase
  /* src/t400_sio.vhd:221:5  */
  always @*
    case (n2899_o)
      4'b1000: n2905_o = 1'b0;
      4'b0100: n2905_o = 1'b0;
      4'b0010: n2905_o = n2883_o;
      4'b0001: n2905_o = 1'b0;
      default: n2905_o = 1'b0;
    endcase
  /* src/t400_sio.vhd:271:39  */
  assign n2908_o = sio_q[3];
  /* src/t400_sio.vhd:271:31  */
  assign n2909_o = en0_i | n2908_o;
  /* src/t400_sio.vhd:271:20  */
  assign n2910_o = en3_i & n2909_o;
  /* src/t400_sio.vhd:272:35  */
  assign n2911_o = en0_i | phi1_i;
  /* src/t400_sio.vhd:272:24  */
  assign n2912_o = phi1_en_q & n2911_o;
  /* src/t400_sio.vhd:126:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2941_q <= 1'b1;
    else
      n2941_q <= n2822_o;
  /* src/t400_sio.vhd:126:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2942_q <= 2'b00;
    else
      n2942_q <= n2823_o;
  /* src/t400_sio.vhd:126:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2943_q <= 1'b0;
    else
      n2943_q <= n2824_o;
  /* src/t400_sio.vhd:126:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2944_q <= 1'b0;
    else
      n2944_q <= n2825_o;
  /* src/t400_sio.vhd:126:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2945_q <= 4'b0000;
    else
      n2945_q <= n2826_o;
  /* src/t400_sio.vhd:126:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2946_q <= 1'b1;
    else
      n2946_q <= n2828_o;
  /* src/t400_sio.vhd:126:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2947_q <= 1'b1;
    else
      n2947_q <= n2830_o;
endmodule

module t400_io_in
  (input  ck_i,
   input  ck_en_i,
   input  por_i,
   input  icyc_en_i,
   input  in_en_i,
   input  [1:0] op_i,
   input  en1_i,
   input  [3:0] io_in_i,
   output [3:0] in_o,
   output int_o);
  wire [5:0] neg_edge_q;
  wire [1:0] il_q;
  wire int_q;
  wire int_icyc_q;
  wire n2717_o;
  wire n2718_o;
  wire n2719_o;
  wire [2:0] n2720_o;
  wire [2:0] n2721_o;
  wire [2:0] n2722_o;
  wire [2:0] n2723_o;
  wire [5:0] n2724_o;
  wire n2726_o;
  wire n2727_o;
  wire [2:0] n2728_o;
  wire n2729_o;
  wire n2730_o;
  wire n2731_o;
  wire n2732_o;
  wire n2734_o;
  wire n2735_o;
  wire n2736_o;
  wire n2737_o;
  wire [2:0] n2738_o;
  wire n2739_o;
  wire n2740_o;
  wire n2741_o;
  wire n2742_o;
  wire n2744_o;
  wire n2745_o;
  wire [1:0] n2746_o;
  wire [1:0] n2747_o;
  wire n2748_o;
  wire n2749_o;
  wire [2:0] n2750_o;
  wire n2751_o;
  wire n2752_o;
  wire n2753_o;
  wire n2754_o;
  wire n2756_o;
  wire n2757_o;
  wire n2758_o;
  wire n2760_o;
  wire [1:0] n2762_o;
  wire n2764_o;
  wire n2766_o;
  wire n2768_o;
  wire n2769_o;
  wire n2770_o;
  wire n2771_o;
  wire n2791_o;
  wire [2:0] n2793_o;
  wire n2794_o;
  wire [3:0] n2795_o;
  wire n2797_o;
  wire [3:0] n2798_o;
  wire [5:0] n2799_o;
  reg [5:0] n2800_q;
  reg [1:0] n2802_q;
  reg n2803_q;
  reg n2804_q;
  assign in_o = n2798_o;
  assign int_o = int_icyc_q;
  /* src/t400_io_in.vhd:75:12  */
  assign neg_edge_q = n2800_q; // (signal)
  /* src/t400_io_in.vhd:78:12  */
  assign il_q = n2802_q; // (signal)
  /* src/t400_io_in.vhd:79:12  */
  assign int_q = n2803_q; // (signal)
  /* src/t400_io_in.vhd:80:12  */
  assign int_icyc_q = n2804_q; // (signal)
  /* src/t400_io_in.vhd:101:46  */
  assign n2717_o = io_in_i[3];
  /* src/t400_io_in.vhd:102:46  */
  assign n2718_o = io_in_i[0];
  /* src/t400_io_in.vhd:103:46  */
  assign n2719_o = io_in_i[1];
  /* src/t400_io_pack-p.vhd:56:14  */
  assign n2720_o = {n2717_o, n2718_o, n2719_o};
  /* src/t400_io_in.vhd:107:36  */
  assign n2721_o = neg_edge_q[2:0];
  /* src/t400_io_pack-p.vhd:56:14  */
  assign n2722_o = {n2717_o, n2718_o, n2719_o};
  /* src/t400_io_in.vhd:107:40  */
  assign n2723_o = n2721_o | n2722_o;
  /* src/t400_io_pack-p.vhd:17:12  */
  assign n2724_o = {n2723_o, n2720_o};
  /* src/t400_io_in.vhd:112:25  */
  assign n2726_o = neg_edge_q[5];
  /* src/t400_io_in.vhd:113:27  */
  assign n2727_o = neg_edge_q[2];
  /* src/t400_io_g.vhd:146:52  */
  assign n2728_o = {n2717_o, n2718_o, n2719_o};
  /* src/t400_io_in.vhd:113:52  */
  assign n2729_o = n2728_o[2];
  /* src/t400_io_in.vhd:113:39  */
  assign n2730_o = n2727_o | n2729_o;
  /* src/t400_io_in.vhd:113:65  */
  assign n2731_o = ~n2730_o;
  /* src/t400_io_in.vhd:112:43  */
  assign n2732_o = n2731_o & n2726_o;
  assign n2734_o = il_q[1];
  /* src/t400_io_in.vhd:112:9  */
  assign n2735_o = n2732_o ? 1'b1 : n2734_o;
  /* src/t400_io_in.vhd:116:25  */
  assign n2736_o = neg_edge_q[4];
  /* src/t400_io_in.vhd:117:27  */
  assign n2737_o = neg_edge_q[1];
  /* src/t400_io_pack-p.vhd:17:12  */
  assign n2738_o = {n2717_o, n2718_o, n2719_o};
  /* src/t400_io_in.vhd:117:52  */
  assign n2739_o = n2738_o[1];
  /* src/t400_io_in.vhd:117:39  */
  assign n2740_o = n2737_o | n2739_o;
  /* src/t400_io_in.vhd:117:65  */
  assign n2741_o = ~n2740_o;
  /* src/t400_io_in.vhd:116:43  */
  assign n2742_o = n2741_o & n2736_o;
  /* src/t400_io_pack-p.vhd:30:14  */
  assign n2744_o = il_q[0];
  /* src/t400_io_in.vhd:116:9  */
  assign n2745_o = n2742_o ? 1'b1 : n2744_o;
  /* src/t400_io_pack-p.vhd:14:12  */
  assign n2746_o = {n2735_o, n2745_o};
  /* src/t400_io_in.vhd:111:7  */
  assign n2747_o = in_en_i ? n2746_o : il_q;
  /* src/t400_io_in.vhd:124:25  */
  assign n2748_o = neg_edge_q[3];
  /* src/t400_io_in.vhd:125:27  */
  assign n2749_o = neg_edge_q[0];
  /* src/t400_io_pack-p.vhd:56:14  */
  assign n2750_o = {n2717_o, n2718_o, n2719_o};
  /* src/t400_io_in.vhd:125:52  */
  assign n2751_o = n2750_o[0];
  /* src/t400_io_in.vhd:125:39  */
  assign n2752_o = n2749_o | n2751_o;
  /* src/t400_io_in.vhd:125:65  */
  assign n2753_o = ~n2752_o;
  /* src/t400_io_in.vhd:124:43  */
  assign n2754_o = n2753_o & n2748_o;
  /* src/t400_io_in.vhd:123:7  */
  assign n2756_o = n2757_o ? 1'b1 : int_q;
  /* src/t400_io_in.vhd:123:7  */
  assign n2757_o = n2754_o & in_en_i;
  /* src/t400_io_in.vhd:129:7  */
  assign n2758_o = icyc_en_i ? int_q : int_icyc_q;
  /* src/t400_io_in.vhd:137:17  */
  assign n2760_o = op_i == 2'b01;
  /* src/t400_io_in.vhd:136:7  */
  assign n2762_o = n2769_o ? 2'b00 : n2747_o;
  /* src/t400_io_in.vhd:141:17  */
  assign n2764_o = op_i == 2'b10;
  /* src/t400_io_in.vhd:136:7  */
  assign n2766_o = n2770_o ? 1'b0 : n2756_o;
  /* src/t400_io_in.vhd:136:7  */
  assign n2768_o = n2771_o ? 1'b0 : n2758_o;
  /* src/t400_io_in.vhd:136:7  */
  assign n2769_o = n2760_o & ck_en_i;
  /* src/t400_io_in.vhd:136:7  */
  assign n2770_o = n2764_o & ck_en_i;
  /* src/t400_io_in.vhd:136:7  */
  assign n2771_o = n2764_o & ck_en_i;
  /* src/t400_io_in.vhd:156:18  */
  assign n2791_o = il_q[1];
  /* src/t400_io_in.vhd:156:22  */
  assign n2793_o = {n2791_o, 2'b00};
  /* src/t400_io_in.vhd:156:35  */
  assign n2794_o = il_q[0];
  /* src/t400_io_in.vhd:156:29  */
  assign n2795_o = {n2793_o, n2794_o};
  /* src/t400_io_in.vhd:157:22  */
  assign n2797_o = op_i == 2'b01;
  /* src/t400_io_in.vhd:157:12  */
  assign n2798_o = n2797_o ? n2795_o : io_in_i;
  /* src/t400_io_in.vhd:99:5  */
  assign n2799_o = in_en_i ? n2724_o : neg_edge_q;
  /* src/t400_io_in.vhd:99:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2800_q <= 6'b000000;
    else
      n2800_q <= n2799_o;
  /* src/t400_io_in.vhd:99:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2802_q <= 2'b00;
    else
      n2802_q <= n2762_o;
  /* src/t400_io_in.vhd:99:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2803_q <= 1'b0;
    else
      n2803_q <= n2766_o;
  /* src/t400_io_in.vhd:99:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2804_q <= 1'b0;
    else
      n2804_q <= n2768_o;
endmodule

module t400_io_g_0_0_0_0_1
  (input  ck_i,
   input  ck_en_i,
   input  por_i,
   input  res_i,
   input  [1:0] op_i,
   input  [3:0] m_i,
   input  [9:0] dec_data_i,
   input  cs_n_i,
   input  wr_n_i,
   output [3:0] io_g_o,
   output [3:0] io_g_en_o);
  wire [3:0] g_q;
  wire n2612_o;
  wire [3:0] n2613_o;
  wire n2615_o;
  wire [1:0] n2616_o;
  reg [3:0] n2617_o;
  localparam [3:0] n2619_o = 4'b0000;
  wire n2621_o;
  wire n2623_o;
  wire n2624_o;
  wire n2625_o;
  wire n2627_o;
  wire n2628_o;
  wire n2629_o;
  wire n2630_o;
  wire n2631_o;
  wire n2632_o;
  wire [2:0] n2633_o;
  wire [2:0] n2634_o;
  wire [2:0] n2635_o;
  wire [2:0] n2636_o;
  wire [2:0] n2637_o;
  wire [3:0] n2638_o;
  wire n2645_o;
  wire n2661_o;
  wire n2677_o;
  wire n2693_o;
  reg [3:0] n2709_q;
  wire [3:0] n2710_o;
  wire [3:0] n2711_o;
  assign io_g_o = n2710_o;
  assign io_g_en_o = n2711_o;
  /* src/t400_io_g.vhd:80:10  */
  assign g_q = n2709_q; // (signal)
  /* src/t400_io_g.vhd:102:11  */
  assign n2612_o = op_i == 2'b01;
  /* src/t400_io_g.vhd:105:30  */
  assign n2613_o = dec_data_i[3:0];
  /* src/t400_io_g.vhd:104:11  */
  assign n2615_o = op_i == 2'b10;
  /* src/t400_io_pack-p.vhd:30:14  */
  assign n2616_o = {n2615_o, n2612_o};
  /* src/t400_io_g.vhd:101:9  */
  always @*
    case (n2616_o)
      2'b10: n2617_o = n2613_o;
      2'b01: n2617_o = m_i;
      default: n2617_o = g_q;
    endcase
  /* src/t400_io_g.vhd:114:17  */
  assign n2621_o = ~cs_n_i;
  /* src/t400_io_g.vhd:113:47  */
  assign n2623_o = n2621_o & 1'b1;
  /* src/t400_io_g.vhd:114:34  */
  assign n2624_o = ~wr_n_i;
  /* src/t400_io_g.vhd:114:23  */
  assign n2625_o = n2624_o & n2623_o;
  /* src/t400_io_pack-p.vhd:17:12  */
  assign n2627_o = n2619_o[0];
  /* src/t400_io_d.vhd:131:52  */
  assign n2628_o = n2617_o[0];
  /* src/t400_io_l.vhd:185:54  */
  assign n2629_o = g_q[0];
  /* src/t400_io_g.vhd:100:7  */
  assign n2630_o = ck_en_i ? n2628_o : n2629_o;
  /* src/t400_io_g.vhd:96:7  */
  assign n2631_o = res_i ? n2627_o : n2630_o;
  /* src/t400_io_g.vhd:113:7  */
  assign n2632_o = n2625_o ? 1'b0 : n2631_o;
  /* src/t400_io_pack-p.vhd:14:12  */
  assign n2633_o = n2619_o[3:1];
  assign n2634_o = n2617_o[3:1];
  /* src/t400_io_pack-p.vhd:14:12  */
  assign n2635_o = g_q[3:1];
  /* src/t400_io_g.vhd:100:7  */
  assign n2636_o = ck_en_i ? n2634_o : n2635_o;
  /* src/t400_io_g.vhd:96:7  */
  assign n2637_o = res_i ? n2633_o : n2636_o;
  /* src/t400_io_pack-p.vhd:17:12  */
  assign n2638_o = {n2637_o, n2632_o};
  /* src/t400_io_g.vhd:132:40  */
  assign n2645_o = g_q[3];
  /* src/t400_io_g.vhd:138:40  */
  assign n2661_o = g_q[2];
  /* src/t400_io_g.vhd:144:40  */
  assign n2677_o = g_q[1];
  /* src/t400_io_g.vhd:150:40  */
  assign n2693_o = g_q[0];
  /* src/t400_io_g.vhd:95:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2709_q <= 4'b0000;
    else
      n2709_q <= n2638_o;
  /* src/t400_io_g.vhd:92:5  */
  assign n2710_o = {n2645_o, n2661_o, n2677_o, n2693_o};
  assign n2711_o = {1'b1, 1'b1, 1'b1, 1'b1};
endmodule

module t400_io_d_0_0_0_0
  (input  ck_i,
   input  ck_en_i,
   input  por_i,
   input  res_i,
   input  op_i,
   input  [3:0] bd_i,
   output [3:0] io_d_o,
   output [3:0] io_d_en_o);
  wire [3:0] d_q;
  wire n2529_o;
  wire [3:0] n2530_o;
  wire n2531_o;
  wire [3:0] n2533_o;
  wire n2540_o;
  wire n2556_o;
  wire n2572_o;
  wire n2588_o;
  reg [3:0] n2604_q;
  wire [3:0] n2605_o;
  wire [3:0] n2606_o;
  assign io_d_o = n2605_o;
  assign io_d_en_o = n2606_o;
  /* src/t400_io_d.vhd:76:10  */
  assign d_q = n2604_q; // (signal)
  /* src/t400_io_d.vhd:97:17  */
  assign n2529_o = op_i == 1'b1;
  /* src/t400_io_d.vhd:96:7  */
  assign n2530_o = n2531_o ? bd_i : d_q;
  /* src/t400_io_d.vhd:96:7  */
  assign n2531_o = n2529_o & ck_en_i;
  /* src/t400_io_d.vhd:92:7  */
  assign n2533_o = res_i ? 4'b0000 : n2530_o;
  /* src/t400_io_d.vhd:117:40  */
  assign n2540_o = d_q[3];
  /* src/t400_io_d.vhd:123:40  */
  assign n2556_o = d_q[2];
  /* src/t400_io_d.vhd:129:40  */
  assign n2572_o = d_q[1];
  /* src/t400_io_d.vhd:135:40  */
  assign n2588_o = d_q[0];
  /* src/t400_io_d.vhd:91:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2604_q <= 4'b0000;
    else
      n2604_q <= n2533_o;
  /* src/t400_io_d.vhd:88:5  */
  assign n2605_o = {n2540_o, n2556_o, n2572_o, n2588_o};
  /* src/t400_io_pack-p.vhd:17:12  */
  assign n2606_o = {1'b1, 1'b1, 1'b1, 1'b1};
endmodule

module t400_io_l_0_0_0_0_0_0_0_0_1
  (input  ck_i,
   input  ck_en_i,
   input  por_i,
   input  in_en_i,
   input  [2:0] op_i,
   input  en2_i,
   input  [3:0] m_i,
   input  [3:0] a_i,
   input  [7:0] pm_data_i,
   input  cs_n_i,
   input  rd_n_i,
   input  wr_n_i,
   input  [7:0] io_l_i,
   output [7:0] q_o,
   output [7:0] io_l_o,
   output [7:0] io_l_en_o);
  wire [7:0] q_q;
  wire en2_s;
  wire n2363_o;
  wire n2365_o;
  wire [1:0] n2366_o;
  wire [3:0] n2367_o;
  wire [3:0] n2368_o;
  reg [3:0] n2369_o;
  wire [3:0] n2370_o;
  wire [3:0] n2371_o;
  reg [3:0] n2372_o;
  wire [7:0] n2373_o;
  wire [7:0] n2374_o;
  wire n2375_o;
  wire n2377_o;
  wire n2378_o;
  wire n2379_o;
  wire [7:0] n2380_o;
  wire n2386_o;
  wire [7:0] n2387_o;
  wire n2388_o;
  wire n2390_o;
  wire n2393_o;
  wire n2409_o;
  wire n2425_o;
  wire n2441_o;
  wire n2457_o;
  wire n2473_o;
  wire n2489_o;
  wire n2505_o;
  reg [7:0] n2521_q;
  wire [7:0] n2522_o;
  wire [7:0] n2523_o;
  assign q_o = n2387_o;
  assign io_l_o = n2522_o;
  assign io_l_en_o = n2523_o;
  /* src/t400_io_l.vhd:90:10  */
  assign q_q = n2521_q; // (signal)
  /* src/t400_io_l.vhd:92:10  */
  assign en2_s = n2390_o; // (signal)
  /* src/t400_io_l.vhd:110:11  */
  assign n2363_o = op_i == 3'b001;
  /* src/t400_io_l.vhd:115:11  */
  assign n2365_o = op_i == 3'b010;
  /* src/t400_stack.vhd:85:5  */
  assign n2366_o = {n2365_o, n2363_o};
  assign n2367_o = pm_data_i[3:0];
  assign n2368_o = q_q[3:0];
  /* src/t400_io_l.vhd:108:9  */
  always @*
    case (n2366_o)
      2'b10: n2369_o = n2367_o;
      2'b01: n2369_o = m_i;
      default: n2369_o = n2368_o;
    endcase
  assign n2370_o = pm_data_i[7:4];
  assign n2371_o = q_q[7:4];
  /* src/t400_io_l.vhd:108:9  */
  always @*
    case (n2366_o)
      2'b10: n2372_o = n2370_o;
      2'b01: n2372_o = a_i;
      default: n2372_o = n2371_o;
    endcase
  assign n2373_o = {n2372_o, n2369_o};
  /* src/t400_io_l.vhd:107:7  */
  assign n2374_o = ck_en_i ? n2373_o : q_q;
  /* src/t400_io_l.vhd:125:17  */
  assign n2375_o = ~cs_n_i;
  /* src/t400_io_l.vhd:124:47  */
  assign n2377_o = n2375_o & 1'b1;
  /* src/t400_io_l.vhd:125:34  */
  assign n2378_o = ~wr_n_i;
  /* src/t400_io_l.vhd:125:23  */
  assign n2379_o = n2378_o & n2377_o;
  /* src/t400_io_l.vhd:124:7  */
  assign n2380_o = n2379_o ? io_l_i : n2374_o;
  /* src/t400_io_l.vhd:138:20  */
  assign n2386_o = op_i == 3'b011;
  /* src/t400_io_l.vhd:138:10  */
  assign n2387_o = n2386_o ? io_l_i : q_q;
  /* src/t400_io_l.vhd:145:21  */
  assign n2388_o = ~(cs_n_i | rd_n_i);
  /* src/t400_io_l.vhd:146:12  */
  assign n2390_o = 1'b1 ? n2388_o : en2_i;
  /* src/t400_io_l.vhd:159:40  */
  assign n2393_o = q_q[7];
  /* src/t400_io_l.vhd:165:40  */
  assign n2409_o = q_q[6];
  /* src/t400_io_l.vhd:171:40  */
  assign n2425_o = q_q[5];
  /* src/t400_io_l.vhd:177:40  */
  assign n2441_o = q_q[4];
  /* src/t400_io_l.vhd:183:40  */
  assign n2457_o = q_q[3];
  /* src/t400_io_l.vhd:189:40  */
  assign n2473_o = q_q[2];
  /* src/t400_io_l.vhd:195:40  */
  assign n2489_o = q_q[1];
  /* src/t400_io_l.vhd:201:40  */
  assign n2505_o = q_q[0];
  /* src/t400_io_l.vhd:106:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2521_q <= 8'b00000000;
    else
      n2521_q <= n2380_o;
  /* src/t400_io_l.vhd:104:5  */
  assign n2522_o = {n2393_o, n2409_o, n2425_o, n2441_o, n2457_o, n2473_o, n2489_o, n2505_o};
  assign n2523_o = {en2_s, en2_s, en2_s, en2_s, en2_s, en2_s, en2_s, en2_s};
endmodule

module t400_stack_0
  (input  ck_i,
   input  ck_en_i,
   input  por_i,
   input  [1:0] op_i,
   input  [9:0] pc_i,
   output [9:0] pc_o);
  wire [9:0] sa_q;
  wire [9:0] sb_q;
  wire [9:0] sc_q;
  wire n2325_o;
  wire n2327_o;
  wire [1:0] n2328_o;
  reg [9:0] n2329_o;
  reg [9:0] n2330_o;
  reg [9:0] n2331_o;
  wire [9:0] n2351_o;
  reg [9:0] n2352_q;
  wire [9:0] n2353_o;
  reg [9:0] n2354_q;
  wire [9:0] n2355_o;
  reg [9:0] n2356_q;
  assign pc_o = sa_q;
  /* src/t400_stack.vhd:69:10  */
  assign sa_q = n2352_q; // (signal)
  /* src/t400_stack.vhd:70:10  */
  assign sb_q = n2354_q; // (signal)
  /* src/t400_stack.vhd:71:10  */
  assign sc_q = n2356_q; // (signal)
  /* src/t400_stack.vhd:96:11  */
  assign n2325_o = op_i == 2'b01;
  /* src/t400_stack.vhd:105:11  */
  assign n2327_o = op_i == 2'b10;
  /* src/t400_alu.vhd:185:14  */
  assign n2328_o = {n2327_o, n2325_o};
  /* src/t400_stack.vhd:95:9  */
  always @*
    case (n2328_o)
      2'b10: n2329_o = sb_q;
      2'b01: n2329_o = pc_i;
      default: n2329_o = sa_q;
    endcase
  /* src/t400_stack.vhd:95:9  */
  always @*
    case (n2328_o)
      2'b10: n2330_o = sc_q;
      2'b01: n2330_o = sa_q;
      default: n2330_o = sb_q;
    endcase
  /* src/t400_stack.vhd:95:9  */
  always @*
    case (n2328_o)
      2'b10: n2331_o = sc_q;
      2'b01: n2331_o = sb_q;
      default: n2331_o = sc_q;
    endcase
  /* src/t400_stack.vhd:90:5  */
  assign n2351_o = ck_en_i ? n2329_o : sa_q;
  /* src/t400_stack.vhd:90:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2352_q <= 10'b0000000000;
    else
      n2352_q <= n2351_o;
  /* src/t400_stack.vhd:90:5  */
  assign n2353_o = ck_en_i ? n2330_o : sb_q;
  /* src/t400_stack.vhd:90:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2354_q <= 10'b0000000000;
    else
      n2354_q <= n2353_o;
  /* src/t400_stack.vhd:90:5  */
  assign n2355_o = ck_en_i ? n2331_o : sc_q;
  /* src/t400_stack.vhd:90:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2356_q <= 10'b0000000000;
    else
      n2356_q <= n2355_o;
endmodule

module t400_alu_0
  (input  ck_i,
   input  ck_en_i,
   input  por_i,
   input  res_i,
   input  cko_i,
   input  [4:0] op_i,
   input  [3:0] m_i,
   input  [9:0] dec_data_i,
   input  [3:0] q_low_i,
   input  [5:0] b_i,
   input  [3:0] g_i,
   input  [3:0] in_i,
   input  [3:0] sio_i,
   output [3:0] a_o,
   output carry_o,
   output c_o);
  wire [4:0] alu_result_s;
  wire [3:0] a_q;
  wire c_q;
  wire [3:0] n2152_o;
  wire n2154_o;
  wire n2156_o;
  wire n2157_o;
  wire n2159_o;
  wire n2160_o;
  wire n2162_o;
  wire n2163_o;
  wire n2165_o;
  wire n2166_o;
  wire n2168_o;
  wire n2169_o;
  wire n2171_o;
  wire n2172_o;
  wire n2174_o;
  wire n2176_o;
  wire n2178_o;
  wire n2180_o;
  wire n2181_o;
  wire n2184_o;
  wire n2186_o;
  localparam [1:0] n2187_o = 2'b00;
  wire [1:0] n2188_o;
  wire n2190_o;
  wire [3:0] n2191_o;
  wire n2193_o;
  wire n2195_o;
  wire [8:0] n2196_o;
  wire n2197_o;
  wire n2198_o;
  wire n2199_o;
  wire n2200_o;
  wire n2201_o;
  wire n2202_o;
  wire n2203_o;
  wire n2204_o;
  wire n2205_o;
  reg n2206_o;
  wire n2207_o;
  wire n2208_o;
  wire n2209_o;
  wire n2210_o;
  wire n2211_o;
  wire n2212_o;
  wire n2213_o;
  wire n2214_o;
  wire n2215_o;
  reg n2216_o;
  wire n2217_o;
  wire n2218_o;
  wire n2219_o;
  wire n2220_o;
  wire n2221_o;
  wire n2222_o;
  wire n2223_o;
  wire n2224_o;
  wire n2225_o;
  reg n2226_o;
  wire n2227_o;
  wire n2228_o;
  wire n2229_o;
  wire n2230_o;
  wire n2231_o;
  wire n2232_o;
  wire n2233_o;
  wire n2234_o;
  wire n2235_o;
  reg n2236_o;
  wire n2237_o;
  wire n2239_o;
  wire n2241_o;
  wire n2243_o;
  wire [2:0] n2244_o;
  reg n2247_o;
  wire [3:0] n2248_o;
  wire [3:0] n2249_o;
  wire n2250_o;
  wire [3:0] n2252_o;
  wire n2254_o;
  wire [4:0] n2269_o;
  wire n2271_o;
  wire n2273_o;
  wire [3:0] n2274_o;
  wire [4:0] n2276_o;
  wire [4:0] n2278_o;
  wire [4:0] n2279_o;
  wire [4:0] n2281_o;
  wire n2283_o;
  localparam [4:0] n2284_o = 5'b00000;
  wire [3:0] n2285_o;
  wire [4:0] n2286_o;
  wire [4:0] n2288_o;
  wire [4:0] n2289_o;
  wire [4:0] n2290_o;
  wire [4:0] n2291_o;
  wire n2293_o;
  wire n2295_o;
  wire n2297_o;
  wire n2298_o;
  wire n2300_o;
  wire n2301_o;
  wire n2303_o;
  wire n2304_o;
  wire [3:0] n2305_o;
  wire [4:0] n2307_o;
  wire n2309_o;
  wire n2311_o;
  wire [3:0] n2312_o;
  reg [4:0] n2315_o;
  wire n2317_o;
  reg [3:0] n2318_q;
  reg n2319_q;
  assign a_o = a_q;
  assign carry_o = n2317_o;
  assign c_o = c_q;
  /* src/t400_alu.vhd:84:11  */
  assign alu_result_s = n2315_o; // (signal)
  /* src/t400_alu.vhd:86:11  */
  assign a_q = n2318_q; // (signal)
  /* src/t400_alu.vhd:87:11  */
  assign c_q = n2319_q; // (signal)
  /* src/t400_alu.vhd:121:49  */
  assign n2152_o = alu_result_s[3:0];
  /* src/t400_alu.vhd:114:11  */
  assign n2154_o = op_i == 5'b00001;
  /* src/t400_alu.vhd:114:28  */
  assign n2156_o = op_i == 5'b01010;
  /* src/t400_alu.vhd:114:28  */
  assign n2157_o = n2154_o | n2156_o;
  /* src/t400_alu.vhd:115:28  */
  assign n2159_o = op_i == 5'b01011;
  /* src/t400_alu.vhd:115:28  */
  assign n2160_o = n2157_o | n2159_o;
  /* src/t400_alu.vhd:116:28  */
  assign n2162_o = op_i == 5'b01100;
  /* src/t400_alu.vhd:116:28  */
  assign n2163_o = n2160_o | n2162_o;
  /* src/t400_alu.vhd:117:28  */
  assign n2165_o = op_i == 5'b01101;
  /* src/t400_alu.vhd:117:28  */
  assign n2166_o = n2163_o | n2165_o;
  /* src/t400_alu.vhd:118:28  */
  assign n2168_o = op_i == 5'b01110;
  /* src/t400_alu.vhd:118:28  */
  assign n2169_o = n2166_o | n2168_o;
  /* src/t400_alu.vhd:119:28  */
  assign n2171_o = op_i == 5'b10001;
  /* src/t400_alu.vhd:119:28  */
  assign n2172_o = n2169_o | n2171_o;
  /* src/t400_alu.vhd:122:11  */
  assign n2174_o = op_i == 5'b00010;
  /* src/t400_alu.vhd:124:11  */
  assign n2176_o = op_i == 5'b00011;
  /* src/t400_alu.vhd:126:11  */
  assign n2178_o = op_i == 5'b00100;
  /* src/t400_alu.vhd:128:11  */
  assign n2180_o = op_i == 5'b00101;
  /* src/t400_alu.vhd:131:27  */
  assign n2181_o = in_i[3];
  /* src/t400_alu.vhd:138:27  */
  assign n2184_o = in_i[0];
  /* src/t400_alu.vhd:130:11  */
  assign n2186_o = op_i == 5'b00110;
  /* src/t400_alu.vhd:141:35  */
  assign n2188_o = b_i[5:4];
  /* src/t400_alu.vhd:139:11  */
  assign n2190_o = op_i == 5'b00111;
  /* src/t400_alu.vhd:143:23  */
  assign n2191_o = b_i[3:0];
  /* src/t400_alu.vhd:142:11  */
  assign n2193_o = op_i == 5'b01000;
  /* src/t400_alu.vhd:144:11  */
  assign n2195_o = op_i == 5'b01001;
  assign n2196_o = {n2195_o, n2193_o, n2190_o, n2186_o, n2180_o, n2178_o, n2176_o, n2174_o, n2172_o};
  assign n2197_o = n2152_o[0];
  assign n2198_o = m_i[0];
  assign n2199_o = q_low_i[0];
  assign n2200_o = g_i[0];
  assign n2201_o = in_i[0];
  assign n2202_o = n2188_o[0];
  assign n2203_o = n2191_o[0];
  assign n2204_o = sio_i[0];
  assign n2205_o = a_q[0];
  /* src/t400_alu.vhd:113:9  */
  always @*
    case (n2196_o)
      9'b100000000: n2206_o = n2204_o;
      9'b010000000: n2206_o = n2203_o;
      9'b001000000: n2206_o = n2202_o;
      9'b000100000: n2206_o = n2184_o;
      9'b000010000: n2206_o = n2201_o;
      9'b000001000: n2206_o = n2200_o;
      9'b000000100: n2206_o = n2199_o;
      9'b000000010: n2206_o = n2198_o;
      9'b000000001: n2206_o = n2197_o;
      default: n2206_o = n2205_o;
    endcase
  assign n2207_o = n2152_o[1];
  assign n2208_o = m_i[1];
  assign n2209_o = q_low_i[1];
  assign n2210_o = g_i[1];
  assign n2211_o = in_i[1];
  assign n2212_o = n2188_o[1];
  assign n2213_o = n2191_o[1];
  assign n2214_o = sio_i[1];
  assign n2215_o = a_q[1];
  /* src/t400_alu.vhd:113:9  */
  always @*
    case (n2196_o)
      9'b100000000: n2216_o = n2214_o;
      9'b010000000: n2216_o = n2213_o;
      9'b001000000: n2216_o = n2212_o;
      9'b000100000: n2216_o = 1'b0;
      9'b000010000: n2216_o = n2211_o;
      9'b000001000: n2216_o = n2210_o;
      9'b000000100: n2216_o = n2209_o;
      9'b000000010: n2216_o = n2208_o;
      9'b000000001: n2216_o = n2207_o;
      default: n2216_o = n2215_o;
    endcase
  assign n2217_o = n2152_o[2];
  assign n2218_o = m_i[2];
  assign n2219_o = q_low_i[2];
  assign n2220_o = g_i[2];
  assign n2221_o = in_i[2];
  assign n2222_o = n2187_o[0];
  assign n2223_o = n2191_o[2];
  assign n2224_o = sio_i[2];
  assign n2225_o = a_q[2];
  /* src/t400_alu.vhd:113:9  */
  always @*
    case (n2196_o)
      9'b100000000: n2226_o = n2224_o;
      9'b010000000: n2226_o = n2223_o;
      9'b001000000: n2226_o = n2222_o;
      9'b000100000: n2226_o = 1'b1;
      9'b000010000: n2226_o = n2221_o;
      9'b000001000: n2226_o = n2220_o;
      9'b000000100: n2226_o = n2219_o;
      9'b000000010: n2226_o = n2218_o;
      9'b000000001: n2226_o = n2217_o;
      default: n2226_o = n2225_o;
    endcase
  assign n2227_o = n2152_o[3];
  assign n2228_o = m_i[3];
  assign n2229_o = q_low_i[3];
  assign n2230_o = g_i[3];
  assign n2231_o = in_i[3];
  assign n2232_o = n2187_o[1];
  assign n2233_o = n2191_o[3];
  assign n2234_o = sio_i[3];
  assign n2235_o = a_q[3];
  /* src/t400_alu.vhd:113:9  */
  always @*
    case (n2196_o)
      9'b100000000: n2236_o = n2234_o;
      9'b010000000: n2236_o = n2233_o;
      9'b001000000: n2236_o = n2232_o;
      9'b000100000: n2236_o = n2181_o;
      9'b000010000: n2236_o = n2231_o;
      9'b000001000: n2236_o = n2230_o;
      9'b000000100: n2236_o = n2229_o;
      9'b000000010: n2236_o = n2228_o;
      9'b000000001: n2236_o = n2227_o;
      default: n2236_o = n2235_o;
    endcase
  /* src/t400_alu.vhd:154:32  */
  assign n2237_o = alu_result_s[4];
  /* src/t400_alu.vhd:153:11  */
  assign n2239_o = op_i == 5'b01100;
  /* src/t400_alu.vhd:157:11  */
  assign n2241_o = op_i == 5'b01111;
  /* src/t400_alu.vhd:161:11  */
  assign n2243_o = op_i == 5'b10000;
  assign n2244_o = {n2243_o, n2241_o, n2239_o};
  /* src/t400_alu.vhd:151:9  */
  always @*
    case (n2244_o)
      3'b100: n2247_o = 1'b1;
      3'b010: n2247_o = 1'b0;
      3'b001: n2247_o = n2237_o;
      default: n2247_o = c_q;
    endcase
  assign n2248_o = {n2236_o, n2226_o, n2216_o, n2206_o};
  /* src/t400_alu.vhd:111:7  */
  assign n2249_o = ck_en_i ? n2248_o : a_q;
  /* src/t400_alu.vhd:111:7  */
  assign n2250_o = ck_en_i ? n2247_o : c_q;
  /* src/t400_alu.vhd:106:7  */
  assign n2252_o = res_i ? 4'b0000 : n2249_o;
  /* src/t400_alu.vhd:106:7  */
  assign n2254_o = res_i ? 1'b0 : n2250_o;
  /* src/t400_alu.vhd:191:23  */
  assign n2269_o = {1'b0, a_q};
  /* src/t400_alu.vhd:192:16  */
  assign n2271_o = op_i == 5'b01011;
  /* src/t400_alu.vhd:194:16  */
  assign n2273_o = op_i == 5'b01101;
  /* src/t400_alu.vhd:195:44  */
  assign n2274_o = dec_data_i[3:0];
  /* src/t400_alu.vhd:195:23  */
  assign n2276_o = {1'b0, n2274_o};
  /* src/t400_alu.vhd:197:23  */
  assign n2278_o = {1'b0, m_i};
  /* src/t400_alu.vhd:194:5  */
  assign n2279_o = n2273_o ? n2276_o : n2278_o;
  /* src/t400_alu.vhd:192:5  */
  assign n2281_o = n2271_o ? 5'b01010 : n2279_o;
  /* src/t400_alu.vhd:199:13  */
  assign n2283_o = op_i == 5'b01100;
  assign n2285_o = n2284_o[4:1];
  assign n2286_o = {n2285_o, c_q};
  /* src/t400_alu.vhd:199:5  */
  assign n2288_o = n2283_o ? n2286_o : 5'b00000;
  /* src/t400_alu.vhd:205:20  */
  assign n2289_o = n2269_o + n2281_o;
  /* src/t400_alu.vhd:205:28  */
  assign n2290_o = n2289_o + n2288_o;
  /* src/t400_alu.vhd:208:20  */
  assign n2291_o = n2269_o ^ n2281_o;
  /* src/t400_alu.vhd:212:7  */
  assign n2293_o = op_i == 5'b00001;
  /* src/t400_alu.vhd:216:7  */
  assign n2295_o = op_i == 5'b01010;
  /* src/t400_alu.vhd:216:24  */
  assign n2297_o = op_i == 5'b01011;
  /* src/t400_alu.vhd:216:24  */
  assign n2298_o = n2295_o | n2297_o;
  /* src/t400_alu.vhd:217:24  */
  assign n2300_o = op_i == 5'b01100;
  /* src/t400_alu.vhd:217:24  */
  assign n2301_o = n2298_o | n2300_o;
  /* src/t400_alu.vhd:218:24  */
  assign n2303_o = op_i == 5'b01101;
  /* src/t400_alu.vhd:218:24  */
  assign n2304_o = n2301_o | n2303_o;
  /* src/t400_alu.vhd:224:31  */
  assign n2305_o = ~a_q;
  /* src/t400_alu.vhd:224:29  */
  assign n2307_o = {1'b0, n2305_o};
  /* src/t400_alu.vhd:223:7  */
  assign n2309_o = op_i == 5'b01110;
  /* src/t400_alu.vhd:227:7  */
  assign n2311_o = op_i == 5'b10001;
  assign n2312_o = {n2311_o, n2309_o, n2304_o, n2293_o};
  /* src/t400_alu.vhd:210:5  */
  always @*
    case (n2312_o)
      4'b1000: n2315_o = n2291_o;
      4'b0100: n2315_o = n2307_o;
      4'b0010: n2315_o = n2290_o;
      4'b0001: n2315_o = 5'b00000;
      default: n2315_o = 5'bX;
    endcase
  /* src/t400_alu.vhd:242:26  */
  assign n2317_o = alu_result_s[4];
  /* src/t400_alu.vhd:105:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2318_q <= 4'b0000;
    else
      n2318_q <= n2252_o;
  /* src/t400_alu.vhd:105:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2319_q <= 1'b0;
    else
      n2319_q <= n2254_o;
endmodule

module t400_skip_0
  (input  ck_i,
   input  ck_en_i,
   input  por_i,
   input  res_i,
   input  [3:0] op_i,
   input  [9:0] dec_data_i,
   input  carry_i,
   input  c_i,
   input  [3:0] bd_i,
   input  is_lbi_i,
   input  [3:0] a_i,
   input  [3:0] m_i,
   input  [3:0] g_i,
   input  tim_c_i,
   output skip_o,
   output skip_lbi_o);
  wire skip_q;
  wire skip_next_q;
  wire skip_lbi_q;
  wire skip_int_q;
  wire n2049_o;
  wire n2051_o;
  wire n2053_o;
  wire n2055_o;
  wire n2057_o;
  wire n2059_o;
  wire n2061_o;
  wire n2063_o;
  wire n2065_o;
  wire n2067_o;
  wire n2069_o;
  wire n2070_o;
  wire n2072_o;
  wire n2074_o;
  wire n2076_o;
  wire [3:0] n2077_o;
  wire [3:0] n2078_o;
  wire n2080_o;
  wire n2082_o;
  wire [3:0] n2083_o;
  wire [3:0] n2084_o;
  wire n2086_o;
  wire n2088_o;
  wire n2090_o;
  wire n2092_o;
  wire n2094_o;
  wire [13:0] n2095_o;
  reg n2097_o;
  reg n2101_o;
  reg n2103_o;
  reg n2105_o;
  wire n2106_o;
  wire n2107_o;
  wire n2108_o;
  wire n2109_o;
  wire n2110_o;
  wire n2111_o;
  wire n2112_o;
  wire n2113_o;
  wire n2117_o;
  wire n2119_o;
  wire n2121_o;
  wire n2123_o;
  reg n2143_q;
  reg n2144_q;
  reg n2145_q;
  reg n2146_q;
  assign skip_o = skip_q;
  assign skip_lbi_o = skip_lbi_q;
  /* src/t400_skip.vhd:83:10  */
  assign skip_q = n2143_q; // (signal)
  /* src/t400_skip.vhd:84:10  */
  assign skip_next_q = n2144_q; // (signal)
  /* src/t400_skip.vhd:85:10  */
  assign skip_lbi_q = n2145_q; // (signal)
  /* src/t400_skip.vhd:87:10  */
  assign skip_int_q = n2146_q; // (signal)
  /* src/t400_skip.vhd:126:18  */
  assign n2049_o = ~is_lbi_i;
  /* src/t400_skip.vhd:126:15  */
  assign n2051_o = n2049_o ? 1'b0 : skip_lbi_q;
  /* src/t400_skip.vhd:120:13  */
  assign n2053_o = op_i == 4'b0001;
  /* src/t400_skip.vhd:131:13  */
  assign n2055_o = op_i == 4'b0010;
  /* src/t400_skip.vhd:135:13  */
  assign n2057_o = op_i == 4'b0011;
  /* src/t400_skip.vhd:139:13  */
  assign n2059_o = op_i == 4'b0100;
  /* src/t400_skip.vhd:144:45  */
  assign n2061_o = bd_i == 4'b1111;
  /* src/t400_skip.vhd:143:13  */
  assign n2063_o = op_i == 4'b0101;
  /* src/t400_skip.vhd:148:45  */
  assign n2065_o = bd_i == 4'b0000;
  /* src/t400_skip.vhd:147:13  */
  assign n2067_o = op_i == 4'b0110;
  /* src/t400_skip.vhd:151:13  */
  assign n2069_o = op_i == 4'b0111;
  /* src/t400_skip.vhd:156:44  */
  assign n2070_o = a_i == m_i;
  /* src/t400_skip.vhd:155:13  */
  assign n2072_o = op_i == 4'b1000;
  /* src/t400_skip.vhd:160:44  */
  assign n2074_o = g_i == 4'b0000;
  /* src/t400_skip.vhd:159:13  */
  assign n2076_o = op_i == 4'b1001;
  /* src/t400_skip.vhd:164:57  */
  assign n2077_o = dec_data_i[3:0];
  /* src/t400_skip.vhd:164:43  */
  assign n2078_o = g_i & n2077_o;
  /* src/t400_skip.vhd:164:71  */
  assign n2080_o = n2078_o == 4'b0000;
  /* src/t400_skip.vhd:163:13  */
  assign n2082_o = op_i == 4'b1010;
  /* src/t400_skip.vhd:168:57  */
  assign n2083_o = dec_data_i[3:0];
  /* src/t400_skip.vhd:168:43  */
  assign n2084_o = m_i & n2083_o;
  /* src/t400_skip.vhd:168:71  */
  assign n2086_o = n2084_o == 4'b0000;
  /* src/t400_skip.vhd:167:13  */
  assign n2088_o = op_i == 4'b1011;
  /* src/t400_skip.vhd:171:13  */
  assign n2090_o = op_i == 4'b1100;
  /* src/t400_skip.vhd:176:13  */
  assign n2092_o = op_i == 4'b1101;
  /* src/t400_skip.vhd:186:13  */
  assign n2094_o = op_i == 4'b1110;
  /* src/t400_mnemonic_pack-p.vhd:62:12  */
  assign n2095_o = {n2094_o, n2092_o, n2090_o, n2088_o, n2082_o, n2076_o, n2072_o, n2069_o, n2067_o, n2063_o, n2059_o, n2057_o, n2055_o, n2053_o};
  /* src/t400_skip.vhd:118:11  */
  always @*
    case (n2095_o)
      14'b10000000000000: n2097_o = skip_q;
      14'b01000000000000: n2097_o = 1'b0;
      14'b00100000000000: n2097_o = skip_q;
      14'b00010000000000: n2097_o = skip_q;
      14'b00001000000000: n2097_o = skip_q;
      14'b00000100000000: n2097_o = skip_q;
      14'b00000010000000: n2097_o = skip_q;
      14'b00000001000000: n2097_o = skip_q;
      14'b00000000100000: n2097_o = skip_q;
      14'b00000000010000: n2097_o = skip_q;
      14'b00000000001000: n2097_o = skip_q;
      14'b00000000000100: n2097_o = skip_q;
      14'b00000000000010: n2097_o = skip_q;
      14'b00000000000001: n2097_o = skip_next_q;
      default: n2097_o = skip_q;
    endcase
  /* src/t400_skip.vhd:118:11  */
  always @*
    case (n2095_o)
      14'b10000000000000: n2101_o = skip_int_q;
      14'b01000000000000: n2101_o = 1'b0;
      14'b00100000000000: n2101_o = tim_c_i;
      14'b00010000000000: n2101_o = n2086_o;
      14'b00001000000000: n2101_o = n2080_o;
      14'b00000100000000: n2101_o = n2074_o;
      14'b00000010000000: n2101_o = n2070_o;
      14'b00000001000000: n2101_o = skip_next_q;
      14'b00000000100000: n2101_o = n2065_o;
      14'b00000000010000: n2101_o = n2061_o;
      14'b00000000001000: n2101_o = c_i;
      14'b00000000000100: n2101_o = carry_i;
      14'b00000000000010: n2101_o = 1'b1;
      14'b00000000000001: n2101_o = 1'b0;
      default: n2101_o = skip_next_q;
    endcase
  /* src/t400_skip.vhd:118:11  */
  always @*
    case (n2095_o)
      14'b10000000000000: n2103_o = skip_lbi_q;
      14'b01000000000000: n2103_o = skip_lbi_q;
      14'b00100000000000: n2103_o = skip_lbi_q;
      14'b00010000000000: n2103_o = skip_lbi_q;
      14'b00001000000000: n2103_o = skip_lbi_q;
      14'b00000100000000: n2103_o = skip_lbi_q;
      14'b00000010000000: n2103_o = skip_lbi_q;
      14'b00000001000000: n2103_o = 1'b1;
      14'b00000000100000: n2103_o = skip_lbi_q;
      14'b00000000010000: n2103_o = skip_lbi_q;
      14'b00000000001000: n2103_o = skip_lbi_q;
      14'b00000000000100: n2103_o = skip_lbi_q;
      14'b00000000000010: n2103_o = skip_lbi_q;
      14'b00000000000001: n2103_o = n2051_o;
      default: n2103_o = skip_lbi_q;
    endcase
  /* src/t400_skip.vhd:118:11  */
  always @*
    case (n2095_o)
      14'b10000000000000: n2105_o = 1'b0;
      14'b01000000000000: n2105_o = skip_next_q;
      14'b00100000000000: n2105_o = skip_int_q;
      14'b00010000000000: n2105_o = skip_int_q;
      14'b00001000000000: n2105_o = skip_int_q;
      14'b00000100000000: n2105_o = skip_int_q;
      14'b00000010000000: n2105_o = skip_int_q;
      14'b00000001000000: n2105_o = skip_int_q;
      14'b00000000100000: n2105_o = skip_int_q;
      14'b00000000010000: n2105_o = skip_int_q;
      14'b00000000001000: n2105_o = skip_int_q;
      14'b00000000000100: n2105_o = skip_int_q;
      14'b00000000000010: n2105_o = skip_int_q;
      14'b00000000000001: n2105_o = skip_int_q;
      default: n2105_o = skip_int_q;
    endcase
  /* src/t400_skip.vhd:114:7  */
  assign n2106_o = n2110_o ? n2097_o : skip_q;
  /* src/t400_skip.vhd:114:7  */
  assign n2107_o = n2111_o ? n2101_o : skip_next_q;
  /* src/t400_skip.vhd:114:7  */
  assign n2108_o = n2112_o ? n2103_o : skip_lbi_q;
  /* src/t400_skip.vhd:114:7  */
  assign n2109_o = n2113_o ? n2105_o : skip_int_q;
  /* src/t400_skip.vhd:114:7  */
  assign n2110_o = ck_en_i & ck_en_i;
  /* src/t400_skip.vhd:114:7  */
  assign n2111_o = ck_en_i & ck_en_i;
  /* src/t400_skip.vhd:114:7  */
  assign n2112_o = ck_en_i & ck_en_i;
  /* src/t400_skip.vhd:114:7  */
  assign n2113_o = ck_en_i & ck_en_i;
  /* src/t400_skip.vhd:107:7  */
  assign n2117_o = res_i ? 1'b0 : n2106_o;
  /* src/t400_skip.vhd:107:7  */
  assign n2119_o = res_i ? 1'b0 : n2107_o;
  /* src/t400_skip.vhd:107:7  */
  assign n2121_o = res_i ? 1'b0 : n2108_o;
  /* src/t400_skip.vhd:107:7  */
  assign n2123_o = res_i ? 1'b0 : n2109_o;
  /* src/t400_skip.vhd:106:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2143_q <= 1'b0;
    else
      n2143_q <= n2117_o;
  /* src/t400_skip.vhd:106:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2144_q <= 1'b0;
    else
      n2144_q <= n2119_o;
  /* src/t400_skip.vhd:106:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2145_q <= 1'b0;
    else
      n2145_q <= n2121_o;
  /* src/t400_skip.vhd:106:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2146_q <= 1'b0;
    else
      n2146_q <= n2123_o;
endmodule

module t400_decoder_0
  (input  ck_i,
   input  ck_en_i,
   input  por_i,
   input  res_i,
   input  out_en_i,
   input  in_en_i,
   input  icyc_en_i,
   input  skip_i,
   input  skip_lbi_i,
   input  int_i,
   input  [9:0] pm_addr_i,
   input  [7:0] pm_data_i,
   output [3:0] pc_op_o,
   output [1:0] stack_op_o,
   output [2:0] dmem_op_o,
   output [2:0] b_op_o,
   output [3:0] skip_op_o,
   output [4:0] alu_op_o,
   output [2:0] io_l_op_o,
   output io_d_op_o,
   output [1:0] io_g_op_o,
   output [1:0] io_in_op_o,
   output sio_op_o,
   output [9:0] dec_data_o,
   output [3:0] en_o,
   output is_lbi_o);
  wire [2:0] cyc_cnt_q;
  wire [7:0] ibyte1_q;
  wire [7:0] ibyte2_q;
  wire [7:0] opcode_s;
  wire second_cyc_q;
  wire [6:0] mnemonic_rec_s;
  wire [5:0] mnemonic_s;
  wire [5:0] mnemonic_q;
  wire multi_byte_s;
  wire multi_byte_q;
  wire last_cycle_s;
  wire force_mc_s;
  wire [3:0] en_q;
  wire set_en_s;
  wire ack_int_s;
  wire n347_o;
  wire n348_o;
  wire n349_o;
  wire n350_o;
  wire n351_o;
  wire n352_o;
  wire n356_o;
  wire [2:0] n358_o;
  wire [2:0] n359_o;
  wire [2:0] n361_o;
  wire n362_o;
  wire n365_o;
  wire n366_o;
  wire n367_o;
  wire n368_o;
  wire [7:0] n370_o;
  wire [5:0] n372_o;
  wire n374_o;
  wire [7:0] n375_o;
  wire [5:0] n376_o;
  wire n377_o;
  wire n378_o;
  wire n379_o;
  wire [7:0] n380_o;
  wire [3:0] n381_o;
  wire n383_o;
  wire n384_o;
  wire n385_o;
  wire n386_o;
  wire n387_o;
  wire n388_o;
  wire n389_o;
  wire [1:0] n390_o;
  wire [1:0] n391_o;
  wire [1:0] n392_o;
  wire [2:0] n393_o;
  wire n394_o;
  wire n395_o;
  wire n396_o;
  wire n397_o;
  wire n398_o;
  wire [3:0] n399_o;
  wire [3:0] n400_o;
  wire [2:0] n402_o;
  wire [7:0] n403_o;
  wire [7:0] n404_o;
  wire n405_o;
  wire [5:0] n407_o;
  wire n409_o;
  wire [3:0] n411_o;
  wire [7:0] n434_o;
  wire n445_o;
  wire n447_o;
  wire n449_o;
  wire n451_o;
  wire n453_o;
  wire n454_o;
  wire n456_o;
  wire n457_o;
  wire n459_o;
  wire n460_o;
  wire n462_o;
  wire n463_o;
  wire n465_o;
  wire n466_o;
  wire n468_o;
  wire n469_o;
  wire n471_o;
  wire n472_o;
  wire n474_o;
  wire n475_o;
  wire n477_o;
  wire n478_o;
  wire n480_o;
  wire n481_o;
  wire n483_o;
  wire n484_o;
  wire n486_o;
  wire n487_o;
  wire n489_o;
  wire n490_o;
  wire n492_o;
  wire n493_o;
  wire n495_o;
  wire n497_o;
  wire n499_o;
  wire n501_o;
  wire n503_o;
  wire n505_o;
  wire n506_o;
  wire n508_o;
  wire n510_o;
  wire n512_o;
  wire n514_o;
  wire n515_o;
  wire n517_o;
  wire n518_o;
  wire n520_o;
  wire n521_o;
  wire n523_o;
  wire n525_o;
  wire n526_o;
  wire n528_o;
  wire n529_o;
  wire n531_o;
  wire n532_o;
  wire n534_o;
  wire n535_o;
  wire n537_o;
  wire n538_o;
  wire n540_o;
  wire n541_o;
  wire n543_o;
  wire n544_o;
  wire n546_o;
  wire n547_o;
  wire n549_o;
  wire n550_o;
  wire n552_o;
  wire n553_o;
  wire n555_o;
  wire n556_o;
  wire n558_o;
  wire n559_o;
  wire n561_o;
  wire n562_o;
  wire n564_o;
  wire n565_o;
  wire n567_o;
  wire n568_o;
  wire n570_o;
  wire n571_o;
  wire n573_o;
  wire n574_o;
  wire n576_o;
  wire n577_o;
  wire n579_o;
  wire n580_o;
  wire n582_o;
  wire n583_o;
  wire n585_o;
  wire n586_o;
  wire n588_o;
  wire n589_o;
  wire n591_o;
  wire n592_o;
  wire n594_o;
  wire n595_o;
  wire n597_o;
  wire n598_o;
  wire n600_o;
  wire n601_o;
  wire n603_o;
  wire n604_o;
  wire n606_o;
  wire n607_o;
  wire n609_o;
  wire n610_o;
  wire n612_o;
  wire n613_o;
  wire n615_o;
  wire n616_o;
  wire n618_o;
  wire n619_o;
  wire n621_o;
  wire n622_o;
  wire n624_o;
  wire n625_o;
  wire n627_o;
  wire n628_o;
  wire n630_o;
  wire n631_o;
  wire n633_o;
  wire n634_o;
  wire n636_o;
  wire n637_o;
  wire n639_o;
  wire n640_o;
  wire n642_o;
  wire n643_o;
  wire n645_o;
  wire n646_o;
  wire n648_o;
  wire n649_o;
  wire n651_o;
  wire n652_o;
  wire n654_o;
  wire n655_o;
  wire n657_o;
  wire n658_o;
  wire n660_o;
  wire n661_o;
  wire n663_o;
  wire n664_o;
  wire n666_o;
  wire n667_o;
  wire n669_o;
  wire n670_o;
  wire n672_o;
  wire n673_o;
  wire n675_o;
  wire n676_o;
  wire n678_o;
  wire n679_o;
  wire n681_o;
  wire n682_o;
  wire n684_o;
  wire n685_o;
  wire n687_o;
  wire n688_o;
  wire n690_o;
  wire n691_o;
  wire n693_o;
  wire n694_o;
  wire n696_o;
  wire n697_o;
  wire n699_o;
  wire n700_o;
  wire n702_o;
  wire n703_o;
  wire n705_o;
  wire n706_o;
  wire n708_o;
  wire n709_o;
  wire n711_o;
  wire n712_o;
  wire n714_o;
  wire n715_o;
  wire n717_o;
  wire n718_o;
  wire n720_o;
  wire n721_o;
  wire n723_o;
  wire n724_o;
  wire n726_o;
  wire n727_o;
  wire n729_o;
  wire n730_o;
  wire n732_o;
  wire n733_o;
  wire n735_o;
  wire n736_o;
  wire n738_o;
  wire n739_o;
  wire n741_o;
  wire n742_o;
  wire n744_o;
  wire n745_o;
  wire n747_o;
  wire n748_o;
  wire n750_o;
  wire n751_o;
  wire n753_o;
  wire n754_o;
  wire n756_o;
  wire n757_o;
  wire n759_o;
  wire n760_o;
  wire n762_o;
  wire n763_o;
  wire n765_o;
  wire n766_o;
  wire n768_o;
  wire n769_o;
  wire n771_o;
  wire n772_o;
  wire n774_o;
  wire n775_o;
  wire n777_o;
  wire n778_o;
  wire n780_o;
  wire n781_o;
  wire n783_o;
  wire n784_o;
  wire n786_o;
  wire n787_o;
  wire n789_o;
  wire n790_o;
  wire n792_o;
  wire n793_o;
  wire n795_o;
  wire n796_o;
  wire n798_o;
  wire n799_o;
  wire n801_o;
  wire n802_o;
  wire n804_o;
  wire n805_o;
  wire n807_o;
  wire n808_o;
  wire n810_o;
  wire n811_o;
  wire n813_o;
  wire n814_o;
  wire n816_o;
  wire n817_o;
  wire n819_o;
  wire n820_o;
  wire n822_o;
  wire n823_o;
  wire n825_o;
  wire n826_o;
  wire n828_o;
  wire n829_o;
  wire n831_o;
  wire n832_o;
  wire n834_o;
  wire n835_o;
  wire n837_o;
  wire n838_o;
  wire n840_o;
  wire n841_o;
  wire n843_o;
  wire n844_o;
  wire n846_o;
  wire n847_o;
  wire n849_o;
  wire n850_o;
  wire n852_o;
  wire n853_o;
  wire n855_o;
  wire n856_o;
  wire n858_o;
  wire n859_o;
  wire n861_o;
  wire n862_o;
  wire n864_o;
  wire n865_o;
  wire n867_o;
  wire n868_o;
  wire n870_o;
  wire n871_o;
  wire n873_o;
  wire n874_o;
  wire n876_o;
  wire n877_o;
  wire n879_o;
  wire n880_o;
  wire n882_o;
  wire n883_o;
  wire n885_o;
  wire n886_o;
  wire n888_o;
  wire n889_o;
  wire n891_o;
  wire n892_o;
  wire n894_o;
  wire n895_o;
  wire n897_o;
  wire n898_o;
  wire n900_o;
  wire n902_o;
  wire n903_o;
  wire n905_o;
  wire n906_o;
  wire n908_o;
  wire n909_o;
  wire n911_o;
  wire n913_o;
  wire n915_o;
  wire n917_o;
  wire n918_o;
  wire n920_o;
  wire n921_o;
  wire n923_o;
  wire n924_o;
  wire n926_o;
  wire n928_o;
  wire n930_o;
  wire n932_o;
  wire n933_o;
  wire n935_o;
  wire n936_o;
  wire n938_o;
  wire n939_o;
  wire n941_o;
  wire n943_o;
  wire n944_o;
  wire n946_o;
  wire n947_o;
  wire n949_o;
  wire n950_o;
  wire n952_o;
  wire n954_o;
  wire n955_o;
  wire n957_o;
  wire n958_o;
  wire n960_o;
  wire n961_o;
  wire n963_o;
  wire n964_o;
  wire n966_o;
  wire n967_o;
  wire n969_o;
  wire n970_o;
  wire n972_o;
  wire n973_o;
  wire n975_o;
  wire n976_o;
  wire n978_o;
  wire n979_o;
  wire n981_o;
  wire n982_o;
  wire n984_o;
  wire n985_o;
  wire n987_o;
  wire n988_o;
  wire n990_o;
  wire n991_o;
  wire n993_o;
  wire n994_o;
  wire n996_o;
  wire n997_o;
  wire n999_o;
  wire n1001_o;
  wire n1002_o;
  wire n1004_o;
  wire n1005_o;
  wire n1007_o;
  wire n1008_o;
  wire n1010_o;
  wire n1012_o;
  wire n1013_o;
  wire n1015_o;
  wire n1016_o;
  wire n1018_o;
  wire n1019_o;
  wire n1021_o;
  wire n1023_o;
  wire n1024_o;
  wire n1026_o;
  wire n1027_o;
  wire n1029_o;
  wire n1030_o;
  wire n1032_o;
  wire n1034_o;
  wire n1036_o;
  wire n1038_o;
  wire n1039_o;
  wire n1041_o;
  wire n1042_o;
  wire n1044_o;
  wire n1045_o;
  wire n1047_o;
  wire n1048_o;
  wire n1050_o;
  wire n1051_o;
  wire n1053_o;
  wire n1054_o;
  wire n1056_o;
  wire n1057_o;
  wire n1059_o;
  wire n1060_o;
  wire n1062_o;
  wire n1063_o;
  wire n1065_o;
  wire n1066_o;
  wire n1068_o;
  wire n1069_o;
  wire n1071_o;
  wire n1072_o;
  wire n1074_o;
  wire n1075_o;
  wire n1077_o;
  wire n1078_o;
  wire n1080_o;
  wire n1081_o;
  wire n1083_o;
  wire n1084_o;
  wire n1086_o;
  wire n1087_o;
  wire n1089_o;
  wire n1090_o;
  wire n1092_o;
  wire n1093_o;
  wire n1095_o;
  wire n1096_o;
  wire n1098_o;
  wire n1099_o;
  wire n1101_o;
  wire n1102_o;
  wire n1104_o;
  wire n1105_o;
  wire n1107_o;
  wire n1108_o;
  wire n1110_o;
  wire n1111_o;
  wire n1113_o;
  wire n1114_o;
  wire n1116_o;
  wire n1117_o;
  wire n1119_o;
  wire n1120_o;
  wire n1122_o;
  wire n1123_o;
  wire n1125_o;
  wire n1126_o;
  wire n1128_o;
  wire n1129_o;
  wire n1131_o;
  wire n1133_o;
  wire n1135_o;
  wire n1137_o;
  wire n1139_o;
  wire n1140_o;
  wire n1142_o;
  wire n1143_o;
  wire n1145_o;
  wire n1146_o;
  wire n1148_o;
  wire n1150_o;
  wire n1152_o;
  wire [34:0] n1153_o;
  reg [5:0] n1190_o;
  reg n1197_o;
  wire [6:0] n1201_o;
  wire [5:0] n1202_o;
  wire n1203_o;
  wire [3:0] n1212_o;
  wire n1214_o;
  wire [3:0] n1217_o;
  wire n1219_o;
  wire [31:0] n1220_o;
  wire n1222_o;
  wire [3:0] n1224_o;
  wire [4:0] n1227_o;
  wire n1229_o;
  wire [31:0] n1230_o;
  wire n1232_o;
  wire [4:0] n1235_o;
  wire n1237_o;
  wire [31:0] n1238_o;
  wire n1240_o;
  wire [4:0] n1243_o;
  wire n1245_o;
  wire [3:0] n1246_o;
  wire [31:0] n1247_o;
  wire n1249_o;
  wire [3:0] n1251_o;
  wire [4:0] n1254_o;
  wire n1256_o;
  wire n1258_o;
  wire n1260_o;
  wire [1:0] n1261_o;
  reg [3:0] n1263_o;
  reg [4:0] n1267_o;
  wire n1269_o;
  wire [31:0] n1270_o;
  wire n1272_o;
  wire [4:0] n1275_o;
  wire n1277_o;
  wire [31:0] n1278_o;
  wire n1280_o;
  wire [4:0] n1283_o;
  wire n1285_o;
  wire n1287_o;
  wire [31:0] n1288_o;
  wire n1290_o;
  wire n1291_o;
  wire [4:0] n1294_o;
  wire [4:0] n1296_o;
  wire n1298_o;
  wire [31:0] n1299_o;
  wire n1301_o;
  wire [4:0] n1304_o;
  wire n1306_o;
  wire [31:0] n1307_o;
  wire n1309_o;
  wire n1310_o;
  wire [3:0] n1313_o;
  wire [3:0] n1314_o;
  wire n1315_o;
  wire n1316_o;
  wire [3:0] n1318_o;
  wire n1320_o;
  wire n1321_o;
  wire n1322_o;
  wire [1:0] n1323_o;
  wire [9:0] n1324_o;
  wire [31:0] n1325_o;
  wire n1327_o;
  wire n1328_o;
  wire [3:0] n1330_o;
  wire n1332_o;
  wire [6:0] n1333_o;
  wire [9:0] n1335_o;
  wire [31:0] n1336_o;
  wire n1338_o;
  wire [2:0] n1339_o;
  wire n1341_o;
  wire n1342_o;
  wire [3:0] n1345_o;
  wire [1:0] n1348_o;
  wire [3:0] n1350_o;
  wire [1:0] n1352_o;
  wire [3:0] n1353_o;
  wire [1:0] n1355_o;
  wire n1357_o;
  wire n1358_o;
  wire n1359_o;
  wire [1:0] n1360_o;
  wire [9:0] n1361_o;
  wire [31:0] n1362_o;
  wire n1364_o;
  wire n1365_o;
  wire [3:0] n1367_o;
  wire [1:0] n1370_o;
  wire n1372_o;
  wire [31:0] n1373_o;
  wire n1375_o;
  wire [3:0] n1377_o;
  wire [1:0] n1380_o;
  wire [3:0] n1382_o;
  wire n1384_o;
  wire [31:0] n1385_o;
  wire n1387_o;
  wire [3:0] n1389_o;
  wire [1:0] n1392_o;
  wire [3:0] n1394_o;
  wire n1396_o;
  wire [1:0] n1397_o;
  wire [31:0] n1398_o;
  wire n1400_o;
  wire [2:0] n1403_o;
  wire [4:0] n1406_o;
  wire n1408_o;
  wire [5:0] n1409_o;
  wire [1:0] n1410_o;
  wire n1412_o;
  wire n1414_o;
  wire [1:0] n1415_o;
  reg [2:0] n1418_o;
  reg [4:0] n1421_o;
  wire n1423_o;
  wire n1425_o;
  wire n1427_o;
  wire [1:0] n1428_o;
  reg [2:0] n1432_o;
  reg [4:0] n1435_o;
  wire n1437_o;
  wire [1:0] n1438_o;
  reg [2:0] n1440_o;
  reg [4:0] n1442_o;
  wire [2:0] n1444_o;
  wire [4:0] n1446_o;
  wire n1448_o;
  wire n1449_o;
  wire [31:0] n1450_o;
  wire n1452_o;
  wire [3:0] n1454_o;
  wire [1:0] n1457_o;
  wire [2:0] n1460_o;
  wire [31:0] n1461_o;
  wire n1463_o;
  wire [3:0] n1465_o;
  wire [1:0] n1468_o;
  wire [3:0] n1469_o;
  wire [1:0] n1470_o;
  wire [2:0] n1472_o;
  wire n1473_o;
  wire n1474_o;
  wire [3:0] n1476_o;
  wire n1478_o;
  wire [31:0] n1479_o;
  wire n1481_o;
  wire [3:0] n1482_o;
  wire n1485_o;
  wire n1488_o;
  wire n1491_o;
  wire n1494_o;
  wire [3:0] n1495_o;
  reg [3:0] n1497_o;
  wire [2:0] n1500_o;
  wire [3:0] n1502_o;
  wire n1504_o;
  wire [31:0] n1505_o;
  wire n1507_o;
  wire [3:0] n1508_o;
  wire n1511_o;
  wire n1514_o;
  wire n1517_o;
  wire n1520_o;
  wire [3:0] n1521_o;
  reg [3:0] n1523_o;
  wire [2:0] n1526_o;
  wire [3:0] n1528_o;
  wire n1530_o;
  wire [3:0] n1531_o;
  wire [31:0] n1532_o;
  wire n1534_o;
  wire [2:0] n1537_o;
  wire [2:0] n1540_o;
  wire n1542_o;
  wire [1:0] n1543_o;
  wire [31:0] n1544_o;
  wire n1546_o;
  wire [2:0] n1549_o;
  wire [2:0] n1552_o;
  wire [4:0] n1555_o;
  wire n1557_o;
  wire [1:0] n1558_o;
  wire n1560_o;
  wire n1562_o;
  wire [1:0] n1563_o;
  reg [2:0] n1566_o;
  reg [2:0] n1570_o;
  reg [3:0] n1572_o;
  reg [4:0] n1575_o;
  wire n1577_o;
  wire [1:0] n1578_o;
  wire n1580_o;
  wire n1582_o;
  wire [1:0] n1583_o;
  reg [2:0] n1586_o;
  reg [2:0] n1590_o;
  reg [3:0] n1592_o;
  reg [4:0] n1595_o;
  wire n1597_o;
  wire [31:0] n1598_o;
  wire n1600_o;
  wire [2:0] n1603_o;
  wire n1605_o;
  wire [31:0] n1606_o;
  wire n1608_o;
  wire [4:0] n1611_o;
  wire n1613_o;
  wire [1:0] n1614_o;
  wire [3:0] n1615_o;
  wire [31:0] n1616_o;
  wire n1618_o;
  wire n1619_o;
  wire n1620_o;
  wire [2:0] n1623_o;
  wire [3:0] n1625_o;
  wire n1627_o;
  wire [31:0] n1628_o;
  wire n1630_o;
  wire [2:0] n1633_o;
  wire [4:0] n1636_o;
  wire n1638_o;
  wire [31:0] n1639_o;
  wire n1641_o;
  wire [3:0] n1643_o;
  wire n1645_o;
  wire [31:0] n1646_o;
  wire n1648_o;
  wire [3:0] n1650_o;
  wire n1652_o;
  wire [31:0] n1653_o;
  wire n1655_o;
  wire n1658_o;
  wire n1661_o;
  wire n1664_o;
  wire n1667_o;
  wire [3:0] n1668_o;
  reg [3:0] n1670_o;
  wire [3:0] n1672_o;
  wire [3:0] n1674_o;
  wire n1676_o;
  wire [31:0] n1677_o;
  wire n1679_o;
  wire [3:0] n1681_o;
  wire n1683_o;
  wire [4:0] n1686_o;
  wire n1689_o;
  wire n1691_o;
  wire [2:0] n1694_o;
  wire n1696_o;
  wire n1698_o;
  wire [2:0] n1701_o;
  wire [4:0] n1704_o;
  wire [2:0] n1707_o;
  wire n1709_o;
  wire [3:0] n1711_o;
  wire n1713_o;
  wire [3:0] n1716_o;
  wire [3:0] n1718_o;
  wire n1720_o;
  wire [3:0] n1723_o;
  wire [3:0] n1725_o;
  wire n1727_o;
  wire [3:0] n1730_o;
  wire [3:0] n1732_o;
  wire n1734_o;
  wire [3:0] n1737_o;
  wire [3:0] n1739_o;
  wire n1741_o;
  wire [31:0] n1742_o;
  wire n1744_o;
  wire [4:0] n1747_o;
  wire n1749_o;
  wire [2:0] n1752_o;
  wire [4:0] n1755_o;
  wire [2:0] n1758_o;
  wire n1760_o;
  wire n1762_o;
  wire [4:0] n1765_o;
  wire n1767_o;
  wire n1769_o;
  wire [4:0] n1772_o;
  wire [1:0] n1775_o;
  wire n1777_o;
  wire n1780_o;
  wire n1782_o;
  wire [1:0] n1785_o;
  wire n1787_o;
  wire [5:0] n1788_o;
  wire [1:0] n1789_o;
  wire n1791_o;
  wire n1793_o;
  wire [31:0] n1794_o;
  wire n1796_o;
  wire n1797_o;
  wire n1798_o;
  wire [2:0] n1801_o;
  wire [3:0] n1803_o;
  wire [2:0] n1805_o;
  wire n1806_o;
  wire n1809_o;
  wire n1812_o;
  wire [3:0] n1813_o;
  wire n1815_o;
  wire n1816_o;
  wire n1817_o;
  wire n1818_o;
  wire [1:0] n1821_o;
  wire [1:0] n1823_o;
  wire n1826_o;
  wire [3:0] n1827_o;
  wire n1829_o;
  wire n1830_o;
  wire n1832_o;
  wire [1:0] n1835_o;
  wire [12:0] n1836_o;
  reg [2:0] n1838_o;
  reg [2:0] n1840_o;
  reg [3:0] n1841_o;
  reg [4:0] n1843_o;
  reg [2:0] n1845_o;
  reg n1847_o;
  reg [1:0] n1849_o;
  reg [1:0] n1851_o;
  wire [3:0] n1852_o;
  reg [3:0] n1854_o;
  wire [1:0] n1855_o;
  reg [1:0] n1857_o;
  reg n1859_o;
  reg n1861_o;
  reg n1863_o;
  wire [2:0] n1865_o;
  wire [2:0] n1867_o;
  wire [3:0] n1868_o;
  wire [4:0] n1870_o;
  wire [2:0] n1872_o;
  wire n1874_o;
  wire [1:0] n1876_o;
  wire [1:0] n1878_o;
  wire [5:0] n1879_o;
  wire [5:0] n1881_o;
  wire n1883_o;
  wire n1885_o;
  wire n1887_o;
  wire n1889_o;
  wire [34:0] n1890_o;
  reg [3:0] n1891_o;
  reg [1:0] n1893_o;
  reg [2:0] n1895_o;
  reg [2:0] n1897_o;
  reg [3:0] n1898_o;
  reg [4:0] n1900_o;
  reg [2:0] n1902_o;
  reg n1904_o;
  reg [1:0] n1906_o;
  reg [1:0] n1908_o;
  reg n1910_o;
  wire [3:0] n1911_o;
  wire [3:0] n1912_o;
  wire [3:0] n1913_o;
  wire [3:0] n1914_o;
  wire [3:0] n1915_o;
  wire [3:0] n1916_o;
  reg [3:0] n1918_o;
  wire [1:0] n1919_o;
  wire [1:0] n1920_o;
  wire [1:0] n1921_o;
  wire [1:0] n1922_o;
  wire [1:0] n1923_o;
  wire [1:0] n1924_o;
  reg [1:0] n1926_o;
  wire [1:0] n1927_o;
  wire [1:0] n1928_o;
  wire [1:0] n1929_o;
  wire [1:0] n1930_o;
  reg [1:0] n1932_o;
  wire [1:0] n1933_o;
  wire [1:0] n1934_o;
  wire [1:0] n1935_o;
  reg [1:0] n1937_o;
  reg n1940_o;
  reg n1944_o;
  reg n1946_o;
  reg n1956_o;
  wire [3:0] n1957_o;
  wire [1:0] n1959_o;
  wire [2:0] n1962_o;
  wire [2:0] n1965_o;
  wire [3:0] n1967_o;
  wire [4:0] n1969_o;
  wire [2:0] n1972_o;
  wire n1975_o;
  wire [1:0] n1978_o;
  wire [1:0] n1981_o;
  wire n1984_o;
  wire [9:0] n1986_o;
  wire [9:0] n1988_o;
  wire n1991_o;
  wire n1994_o;
  wire n1997_o;
  wire n2000_o;
  wire n2002_o;
  wire n2004_o;
  wire n2005_o;
  wire n2006_o;
  wire [31:0] n2007_o;
  wire n2009_o;
  wire [1:0] n2011_o;
  wire [3:0] n2013_o;
  wire [3:0] n2015_o;
  wire [1:0] n2017_o;
  wire n2020_o;
  wire n2021_o;
  wire n2022_o;
  wire n2023_o;
  wire n2024_o;
  wire n2026_o;
  wire n2027_o;
  wire n2028_o;
  wire n2029_o;
  wire n2030_o;
  wire n2032_o;
  reg [2:0] n2037_q;
  reg [7:0] n2038_q;
  reg [7:0] n2039_q;
  reg n2040_q;
  reg [5:0] n2041_q;
  reg n2042_q;
  reg [3:0] n2043_q;
  assign pc_op_o = n2013_o;
  assign stack_op_o = n2011_o;
  assign dmem_op_o = n1962_o;
  assign b_op_o = n1965_o;
  assign skip_op_o = n2015_o;
  assign alu_op_o = n1969_o;
  assign io_l_op_o = n1972_o;
  assign io_d_op_o = n1975_o;
  assign io_g_op_o = n1978_o;
  assign io_in_op_o = n2017_o;
  assign sio_op_o = n1984_o;
  assign dec_data_o = n1988_o;
  assign en_o = en_q;
  assign is_lbi_o = n1991_o;
  /* src/t400_decoder.vhd:96:10  */
  assign cyc_cnt_q = n2037_q; // (signal)
  /* src/t400_decoder.vhd:97:10  */
  assign ibyte1_q = n2038_q; // (signal)
  /* src/t400_decoder.vhd:98:10  */
  assign ibyte2_q = n2039_q; // (signal)
  /* src/t400_decoder.vhd:100:10  */
  assign opcode_s = n434_o; // (signal)
  /* src/t400_decoder.vhd:101:10  */
  assign second_cyc_q = n2040_q; // (signal)
  /* src/t400_decoder.vhd:102:10  */
  assign mnemonic_rec_s = n1201_o; // (signal)
  /* src/t400_decoder.vhd:103:10  */
  assign mnemonic_s = n1202_o; // (signal)
  /* src/t400_decoder.vhd:104:10  */
  assign mnemonic_q = n2041_q; // (signal)
  /* src/t400_decoder.vhd:105:10  */
  assign multi_byte_s = n1203_o; // (signal)
  /* src/t400_decoder.vhd:106:10  */
  assign multi_byte_q = n2042_q; // (signal)
  /* src/t400_decoder.vhd:107:10  */
  assign last_cycle_s = n352_o; // (signal)
  /* src/t400_decoder.vhd:108:10  */
  assign force_mc_s = n1994_o; // (signal)
  /* src/t400_decoder.vhd:110:10  */
  assign en_q = n2043_q; // (signal)
  /* src/t400_decoder.vhd:111:10  */
  assign set_en_s = n1997_o; // (signal)
  /* src/t400_decoder.vhd:112:10  */
  assign ack_int_s = n2032_o; // (signal)
  /* src/t400_decoder.vhd:148:20  */
  assign n347_o = ~multi_byte_q;
  /* src/t400_decoder.vhd:149:20  */
  assign n348_o = ~second_cyc_q;
  /* src/t400_decoder.vhd:148:37  */
  assign n349_o = n348_o & n347_o;
  /* src/t400_decoder.vhd:149:41  */
  assign n350_o = ~force_mc_s;
  /* src/t400_decoder.vhd:149:37  */
  assign n351_o = n350_o & n349_o;
  /* src/t400_decoder.vhd:150:19  */
  assign n352_o = n351_o | second_cyc_q;
  /* src/t400_decoder.vhd:198:25  */
  assign n356_o = cyc_cnt_q != 3'b100;
  /* src/t400_decoder.vhd:199:37  */
  assign n358_o = cyc_cnt_q + 3'b001;
  /* src/t400_decoder.vhd:198:9  */
  assign n359_o = n356_o ? n358_o : cyc_cnt_q;
  /* src/t400_decoder.vhd:195:9  */
  assign n361_o = icyc_en_i ? 3'b000 : n359_o;
  /* src/t400_decoder.vhd:204:14  */
  assign n362_o = ~last_cycle_s;
  /* src/t400_decoder.vhd:204:11  */
  assign n365_o = n362_o ? 1'b1 : 1'b0;
  /* src/t400_decoder.vhd:193:7  */
  assign n366_o = n396_o ? n365_o : second_cyc_q;
  /* src/t400_decoder.vhd:212:22  */
  assign n367_o = last_cycle_s & icyc_en_i;
  /* src/t400_decoder.vhd:213:14  */
  assign n368_o = ~ack_int_s;
  /* src/t400_decoder.vhd:213:11  */
  assign n370_o = n368_o ? pm_data_i : 8'b01000100;
  /* src/t400_decoder.vhd:213:11  */
  assign n372_o = n368_o ? mnemonic_s : 6'b000111;
  /* src/t400_decoder.vhd:213:11  */
  assign n374_o = n368_o ? multi_byte_s : 1'b0;
  /* src/t400_decoder.vhd:193:7  */
  assign n375_o = n394_o ? n370_o : ibyte1_q;
  /* src/t400_decoder.vhd:193:7  */
  assign n376_o = n397_o ? n372_o : mnemonic_q;
  /* src/t400_decoder.vhd:193:7  */
  assign n377_o = n398_o ? n374_o : multi_byte_q;
  /* src/t400_decoder.vhd:227:26  */
  assign n378_o = ~last_cycle_s;
  /* src/t400_decoder.vhd:227:22  */
  assign n379_o = n378_o & icyc_en_i;
  /* src/t400_decoder.vhd:193:7  */
  assign n380_o = n395_o ? pm_data_i : ibyte2_q;
  /* src/t400_decoder.vhd:233:35  */
  assign n381_o = ibyte2_q[3:0];
  assign n383_o = en_q[1];
  /* src/t400_decoder.vhd:234:9  */
  assign n384_o = ack_int_s ? 1'b0 : n383_o;
  assign n385_o = n381_o[0];
  assign n386_o = en_q[0];
  /* src/t400_decoder.vhd:232:9  */
  assign n387_o = set_en_s ? n385_o : n386_o;
  assign n388_o = n381_o[1];
  /* src/t400_decoder.vhd:232:9  */
  assign n389_o = set_en_s ? n388_o : n384_o;
  assign n390_o = n381_o[3:2];
  assign n391_o = en_q[3:2];
  /* src/t400_decoder.vhd:232:9  */
  assign n392_o = set_en_s ? n390_o : n391_o;
  /* src/t400_decoder.vhd:193:7  */
  assign n393_o = ck_en_i ? n361_o : cyc_cnt_q;
  /* src/t400_decoder.vhd:193:7  */
  assign n394_o = n367_o & ck_en_i;
  /* src/t400_decoder.vhd:193:7  */
  assign n395_o = n379_o & ck_en_i;
  /* src/t400_decoder.vhd:193:7  */
  assign n396_o = icyc_en_i & ck_en_i;
  /* src/t400_decoder.vhd:193:7  */
  assign n397_o = n367_o & ck_en_i;
  /* src/t400_decoder.vhd:193:7  */
  assign n398_o = n367_o & ck_en_i;
  assign n399_o = {n392_o, n389_o, n387_o};
  /* src/t400_decoder.vhd:193:7  */
  assign n400_o = ck_en_i ? n399_o : en_q;
  /* src/t400_decoder.vhd:186:7  */
  assign n402_o = res_i ? 3'b000 : n393_o;
  /* src/t400_decoder.vhd:186:7  */
  assign n403_o = res_i ? ibyte1_q : n375_o;
  /* src/t400_decoder.vhd:186:7  */
  assign n404_o = res_i ? ibyte2_q : n380_o;
  /* src/t400_decoder.vhd:186:7  */
  assign n405_o = res_i ? second_cyc_q : n366_o;
  /* src/t400_decoder.vhd:186:7  */
  assign n407_o = res_i ? 6'b000101 : n376_o;
  /* src/t400_decoder.vhd:186:7  */
  assign n409_o = res_i ? 1'b0 : n377_o;
  /* src/t400_decoder.vhd:186:7  */
  assign n411_o = res_i ? 4'b0000 : n400_o;
  /* src/t400_decoder.vhd:250:15  */
  assign n434_o = icyc_en_i ? pm_data_i : ibyte1_q;
  /* src/t400_mnemonic_pack-p.vhd:92:7  */
  assign n445_o = opcode_s == 8'b00110000;
  /* src/t400_mnemonic_pack-p.vhd:96:7  */
  assign n447_o = opcode_s == 8'b00110001;
  /* src/t400_mnemonic_pack-p.vhd:100:7  */
  assign n449_o = opcode_s == 8'b01001010;
  /* src/t400_mnemonic_pack-p.vhd:106:7  */
  assign n451_o = opcode_s == 8'b01010001;
  /* src/t400_mnemonic_pack-p.vhd:106:23  */
  assign n453_o = opcode_s == 8'b01010010;
  /* src/t400_mnemonic_pack-p.vhd:106:23  */
  assign n454_o = n451_o | n453_o;
  /* src/t400_mnemonic_pack-p.vhd:106:36  */
  assign n456_o = opcode_s == 8'b01010011;
  /* src/t400_mnemonic_pack-p.vhd:106:36  */
  assign n457_o = n454_o | n456_o;
  /* src/t400_mnemonic_pack-p.vhd:106:49  */
  assign n459_o = opcode_s == 8'b01010100;
  /* src/t400_mnemonic_pack-p.vhd:106:49  */
  assign n460_o = n457_o | n459_o;
  /* src/t400_mnemonic_pack-p.vhd:107:23  */
  assign n462_o = opcode_s == 8'b01010101;
  /* src/t400_mnemonic_pack-p.vhd:107:23  */
  assign n463_o = n460_o | n462_o;
  /* src/t400_mnemonic_pack-p.vhd:107:36  */
  assign n465_o = opcode_s == 8'b01010110;
  /* src/t400_mnemonic_pack-p.vhd:107:36  */
  assign n466_o = n463_o | n465_o;
  /* src/t400_mnemonic_pack-p.vhd:107:49  */
  assign n468_o = opcode_s == 8'b01010111;
  /* src/t400_mnemonic_pack-p.vhd:107:49  */
  assign n469_o = n466_o | n468_o;
  /* src/t400_mnemonic_pack-p.vhd:107:62  */
  assign n471_o = opcode_s == 8'b01011000;
  /* src/t400_mnemonic_pack-p.vhd:107:62  */
  assign n472_o = n469_o | n471_o;
  /* src/t400_mnemonic_pack-p.vhd:108:23  */
  assign n474_o = opcode_s == 8'b01011001;
  /* src/t400_mnemonic_pack-p.vhd:108:23  */
  assign n475_o = n472_o | n474_o;
  /* src/t400_mnemonic_pack-p.vhd:108:36  */
  assign n477_o = opcode_s == 8'b01011010;
  /* src/t400_mnemonic_pack-p.vhd:108:36  */
  assign n478_o = n475_o | n477_o;
  /* src/t400_mnemonic_pack-p.vhd:108:49  */
  assign n480_o = opcode_s == 8'b01011011;
  /* src/t400_mnemonic_pack-p.vhd:108:49  */
  assign n481_o = n478_o | n480_o;
  /* src/t400_mnemonic_pack-p.vhd:108:62  */
  assign n483_o = opcode_s == 8'b01011100;
  /* src/t400_mnemonic_pack-p.vhd:108:62  */
  assign n484_o = n481_o | n483_o;
  /* src/t400_mnemonic_pack-p.vhd:109:23  */
  assign n486_o = opcode_s == 8'b01011101;
  /* src/t400_mnemonic_pack-p.vhd:109:23  */
  assign n487_o = n484_o | n486_o;
  /* src/t400_mnemonic_pack-p.vhd:109:36  */
  assign n489_o = opcode_s == 8'b01011110;
  /* src/t400_mnemonic_pack-p.vhd:109:36  */
  assign n490_o = n487_o | n489_o;
  /* src/t400_mnemonic_pack-p.vhd:109:49  */
  assign n492_o = opcode_s == 8'b01011111;
  /* src/t400_mnemonic_pack-p.vhd:109:49  */
  assign n493_o = n490_o | n492_o;
  /* src/t400_mnemonic_pack-p.vhd:113:7  */
  assign n495_o = opcode_s == 8'b00010000;
  /* src/t400_mnemonic_pack-p.vhd:119:7  */
  assign n497_o = opcode_s == 8'b00000000;
  /* src/t400_mnemonic_pack-p.vhd:123:7  */
  assign n499_o = opcode_s == 8'b01000000;
  /* src/t400_mnemonic_pack-p.vhd:127:7  */
  assign n501_o = opcode_s == 8'b01000100;
  /* src/t400_mnemonic_pack-p.vhd:131:7  */
  assign n503_o = opcode_s == 8'b00110010;
  /* src/t400_mnemonic_pack-p.vhd:131:23  */
  assign n505_o = opcode_s == 8'b00100010;
  /* src/t400_mnemonic_pack-p.vhd:131:23  */
  assign n506_o = n503_o | n505_o;
  /* src/t400_mnemonic_pack-p.vhd:136:7  */
  assign n508_o = opcode_s == 8'b00000010;
  /* src/t400_mnemonic_pack-p.vhd:140:7  */
  assign n510_o = opcode_s == 8'b11111111;
  /* src/t400_mnemonic_pack-p.vhd:144:7  */
  assign n512_o = opcode_s == 8'b01100000;
  /* src/t400_mnemonic_pack-p.vhd:144:23  */
  assign n514_o = opcode_s == 8'b01100001;
  /* src/t400_mnemonic_pack-p.vhd:144:23  */
  assign n515_o = n512_o | n514_o;
  /* src/t400_mnemonic_pack-p.vhd:144:36  */
  assign n517_o = opcode_s == 8'b01100010;
  /* src/t400_mnemonic_pack-p.vhd:144:36  */
  assign n518_o = n515_o | n517_o;
  /* src/t400_mnemonic_pack-p.vhd:144:49  */
  assign n520_o = opcode_s == 8'b01100011;
  /* src/t400_mnemonic_pack-p.vhd:144:49  */
  assign n521_o = n518_o | n520_o;
  /* src/t400_mnemonic_pack-p.vhd:149:7  */
  assign n523_o = opcode_s == 8'b10000000;
  /* src/t400_mnemonic_pack-p.vhd:149:23  */
  assign n525_o = opcode_s == 8'b10000001;
  /* src/t400_mnemonic_pack-p.vhd:149:23  */
  assign n526_o = n523_o | n525_o;
  /* src/t400_mnemonic_pack-p.vhd:149:36  */
  assign n528_o = opcode_s == 8'b10000010;
  /* src/t400_mnemonic_pack-p.vhd:149:36  */
  assign n529_o = n526_o | n528_o;
  /* src/t400_mnemonic_pack-p.vhd:149:49  */
  assign n531_o = opcode_s == 8'b10000011;
  /* src/t400_mnemonic_pack-p.vhd:149:49  */
  assign n532_o = n529_o | n531_o;
  /* src/t400_mnemonic_pack-p.vhd:149:62  */
  assign n534_o = opcode_s == 8'b10000100;
  /* src/t400_mnemonic_pack-p.vhd:149:62  */
  assign n535_o = n532_o | n534_o;
  /* src/t400_mnemonic_pack-p.vhd:150:23  */
  assign n537_o = opcode_s == 8'b10000101;
  /* src/t400_mnemonic_pack-p.vhd:150:23  */
  assign n538_o = n535_o | n537_o;
  /* src/t400_mnemonic_pack-p.vhd:150:36  */
  assign n540_o = opcode_s == 8'b10000110;
  /* src/t400_mnemonic_pack-p.vhd:150:36  */
  assign n541_o = n538_o | n540_o;
  /* src/t400_mnemonic_pack-p.vhd:150:49  */
  assign n543_o = opcode_s == 8'b10000111;
  /* src/t400_mnemonic_pack-p.vhd:150:49  */
  assign n544_o = n541_o | n543_o;
  /* src/t400_mnemonic_pack-p.vhd:150:62  */
  assign n546_o = opcode_s == 8'b10001000;
  /* src/t400_mnemonic_pack-p.vhd:150:62  */
  assign n547_o = n544_o | n546_o;
  /* src/t400_mnemonic_pack-p.vhd:151:23  */
  assign n549_o = opcode_s == 8'b10001001;
  /* src/t400_mnemonic_pack-p.vhd:151:23  */
  assign n550_o = n547_o | n549_o;
  /* src/t400_mnemonic_pack-p.vhd:151:36  */
  assign n552_o = opcode_s == 8'b10001010;
  /* src/t400_mnemonic_pack-p.vhd:151:36  */
  assign n553_o = n550_o | n552_o;
  /* src/t400_mnemonic_pack-p.vhd:151:49  */
  assign n555_o = opcode_s == 8'b10001011;
  /* src/t400_mnemonic_pack-p.vhd:151:49  */
  assign n556_o = n553_o | n555_o;
  /* src/t400_mnemonic_pack-p.vhd:151:62  */
  assign n558_o = opcode_s == 8'b10001100;
  /* src/t400_mnemonic_pack-p.vhd:151:62  */
  assign n559_o = n556_o | n558_o;
  /* src/t400_mnemonic_pack-p.vhd:152:23  */
  assign n561_o = opcode_s == 8'b10001101;
  /* src/t400_mnemonic_pack-p.vhd:152:23  */
  assign n562_o = n559_o | n561_o;
  /* src/t400_mnemonic_pack-p.vhd:152:36  */
  assign n564_o = opcode_s == 8'b10001110;
  /* src/t400_mnemonic_pack-p.vhd:152:36  */
  assign n565_o = n562_o | n564_o;
  /* src/t400_mnemonic_pack-p.vhd:152:49  */
  assign n567_o = opcode_s == 8'b10001111;
  /* src/t400_mnemonic_pack-p.vhd:152:49  */
  assign n568_o = n565_o | n567_o;
  /* src/t400_mnemonic_pack-p.vhd:152:62  */
  assign n570_o = opcode_s == 8'b10010000;
  /* src/t400_mnemonic_pack-p.vhd:152:62  */
  assign n571_o = n568_o | n570_o;
  /* src/t400_mnemonic_pack-p.vhd:153:23  */
  assign n573_o = opcode_s == 8'b10010001;
  /* src/t400_mnemonic_pack-p.vhd:153:23  */
  assign n574_o = n571_o | n573_o;
  /* src/t400_mnemonic_pack-p.vhd:153:36  */
  assign n576_o = opcode_s == 8'b10010010;
  /* src/t400_mnemonic_pack-p.vhd:153:36  */
  assign n577_o = n574_o | n576_o;
  /* src/t400_mnemonic_pack-p.vhd:153:49  */
  assign n579_o = opcode_s == 8'b10010011;
  /* src/t400_mnemonic_pack-p.vhd:153:49  */
  assign n580_o = n577_o | n579_o;
  /* src/t400_mnemonic_pack-p.vhd:153:62  */
  assign n582_o = opcode_s == 8'b10010100;
  /* src/t400_mnemonic_pack-p.vhd:153:62  */
  assign n583_o = n580_o | n582_o;
  /* src/t400_mnemonic_pack-p.vhd:154:23  */
  assign n585_o = opcode_s == 8'b10010101;
  /* src/t400_mnemonic_pack-p.vhd:154:23  */
  assign n586_o = n583_o | n585_o;
  /* src/t400_mnemonic_pack-p.vhd:154:36  */
  assign n588_o = opcode_s == 8'b10010110;
  /* src/t400_mnemonic_pack-p.vhd:154:36  */
  assign n589_o = n586_o | n588_o;
  /* src/t400_mnemonic_pack-p.vhd:154:49  */
  assign n591_o = opcode_s == 8'b10010111;
  /* src/t400_mnemonic_pack-p.vhd:154:49  */
  assign n592_o = n589_o | n591_o;
  /* src/t400_mnemonic_pack-p.vhd:154:62  */
  assign n594_o = opcode_s == 8'b10011000;
  /* src/t400_mnemonic_pack-p.vhd:154:62  */
  assign n595_o = n592_o | n594_o;
  /* src/t400_mnemonic_pack-p.vhd:155:23  */
  assign n597_o = opcode_s == 8'b10011001;
  /* src/t400_mnemonic_pack-p.vhd:155:23  */
  assign n598_o = n595_o | n597_o;
  /* src/t400_mnemonic_pack-p.vhd:155:36  */
  assign n600_o = opcode_s == 8'b10011010;
  /* src/t400_mnemonic_pack-p.vhd:155:36  */
  assign n601_o = n598_o | n600_o;
  /* src/t400_mnemonic_pack-p.vhd:155:49  */
  assign n603_o = opcode_s == 8'b10011011;
  /* src/t400_mnemonic_pack-p.vhd:155:49  */
  assign n604_o = n601_o | n603_o;
  /* src/t400_mnemonic_pack-p.vhd:155:62  */
  assign n606_o = opcode_s == 8'b10011100;
  /* src/t400_mnemonic_pack-p.vhd:155:62  */
  assign n607_o = n604_o | n606_o;
  /* src/t400_mnemonic_pack-p.vhd:156:23  */
  assign n609_o = opcode_s == 8'b10011101;
  /* src/t400_mnemonic_pack-p.vhd:156:23  */
  assign n610_o = n607_o | n609_o;
  /* src/t400_mnemonic_pack-p.vhd:156:36  */
  assign n612_o = opcode_s == 8'b10011110;
  /* src/t400_mnemonic_pack-p.vhd:156:36  */
  assign n613_o = n610_o | n612_o;
  /* src/t400_mnemonic_pack-p.vhd:156:49  */
  assign n615_o = opcode_s == 8'b10011111;
  /* src/t400_mnemonic_pack-p.vhd:156:49  */
  assign n616_o = n613_o | n615_o;
  /* src/t400_mnemonic_pack-p.vhd:156:62  */
  assign n618_o = opcode_s == 8'b10100000;
  /* src/t400_mnemonic_pack-p.vhd:156:62  */
  assign n619_o = n616_o | n618_o;
  /* src/t400_mnemonic_pack-p.vhd:157:23  */
  assign n621_o = opcode_s == 8'b10100001;
  /* src/t400_mnemonic_pack-p.vhd:157:23  */
  assign n622_o = n619_o | n621_o;
  /* src/t400_mnemonic_pack-p.vhd:157:36  */
  assign n624_o = opcode_s == 8'b10100010;
  /* src/t400_mnemonic_pack-p.vhd:157:36  */
  assign n625_o = n622_o | n624_o;
  /* src/t400_mnemonic_pack-p.vhd:157:49  */
  assign n627_o = opcode_s == 8'b10100011;
  /* src/t400_mnemonic_pack-p.vhd:157:49  */
  assign n628_o = n625_o | n627_o;
  /* src/t400_mnemonic_pack-p.vhd:157:62  */
  assign n630_o = opcode_s == 8'b10100100;
  /* src/t400_mnemonic_pack-p.vhd:157:62  */
  assign n631_o = n628_o | n630_o;
  /* src/t400_mnemonic_pack-p.vhd:158:23  */
  assign n633_o = opcode_s == 8'b10100101;
  /* src/t400_mnemonic_pack-p.vhd:158:23  */
  assign n634_o = n631_o | n633_o;
  /* src/t400_mnemonic_pack-p.vhd:158:36  */
  assign n636_o = opcode_s == 8'b10100110;
  /* src/t400_mnemonic_pack-p.vhd:158:36  */
  assign n637_o = n634_o | n636_o;
  /* src/t400_mnemonic_pack-p.vhd:158:49  */
  assign n639_o = opcode_s == 8'b10100111;
  /* src/t400_mnemonic_pack-p.vhd:158:49  */
  assign n640_o = n637_o | n639_o;
  /* src/t400_mnemonic_pack-p.vhd:158:62  */
  assign n642_o = opcode_s == 8'b10101000;
  /* src/t400_mnemonic_pack-p.vhd:158:62  */
  assign n643_o = n640_o | n642_o;
  /* src/t400_mnemonic_pack-p.vhd:159:23  */
  assign n645_o = opcode_s == 8'b10101001;
  /* src/t400_mnemonic_pack-p.vhd:159:23  */
  assign n646_o = n643_o | n645_o;
  /* src/t400_mnemonic_pack-p.vhd:159:36  */
  assign n648_o = opcode_s == 8'b10101010;
  /* src/t400_mnemonic_pack-p.vhd:159:36  */
  assign n649_o = n646_o | n648_o;
  /* src/t400_mnemonic_pack-p.vhd:159:49  */
  assign n651_o = opcode_s == 8'b10101011;
  /* src/t400_mnemonic_pack-p.vhd:159:49  */
  assign n652_o = n649_o | n651_o;
  /* src/t400_mnemonic_pack-p.vhd:159:62  */
  assign n654_o = opcode_s == 8'b10101100;
  /* src/t400_mnemonic_pack-p.vhd:159:62  */
  assign n655_o = n652_o | n654_o;
  /* src/t400_mnemonic_pack-p.vhd:160:23  */
  assign n657_o = opcode_s == 8'b10101101;
  /* src/t400_mnemonic_pack-p.vhd:160:23  */
  assign n658_o = n655_o | n657_o;
  /* src/t400_mnemonic_pack-p.vhd:160:36  */
  assign n660_o = opcode_s == 8'b10101110;
  /* src/t400_mnemonic_pack-p.vhd:160:36  */
  assign n661_o = n658_o | n660_o;
  /* src/t400_mnemonic_pack-p.vhd:160:49  */
  assign n663_o = opcode_s == 8'b10101111;
  /* src/t400_mnemonic_pack-p.vhd:160:49  */
  assign n664_o = n661_o | n663_o;
  /* src/t400_mnemonic_pack-p.vhd:160:62  */
  assign n666_o = opcode_s == 8'b10110000;
  /* src/t400_mnemonic_pack-p.vhd:160:62  */
  assign n667_o = n664_o | n666_o;
  /* src/t400_mnemonic_pack-p.vhd:161:23  */
  assign n669_o = opcode_s == 8'b10110001;
  /* src/t400_mnemonic_pack-p.vhd:161:23  */
  assign n670_o = n667_o | n669_o;
  /* src/t400_mnemonic_pack-p.vhd:161:36  */
  assign n672_o = opcode_s == 8'b10110010;
  /* src/t400_mnemonic_pack-p.vhd:161:36  */
  assign n673_o = n670_o | n672_o;
  /* src/t400_mnemonic_pack-p.vhd:161:49  */
  assign n675_o = opcode_s == 8'b10110011;
  /* src/t400_mnemonic_pack-p.vhd:161:49  */
  assign n676_o = n673_o | n675_o;
  /* src/t400_mnemonic_pack-p.vhd:161:62  */
  assign n678_o = opcode_s == 8'b10110100;
  /* src/t400_mnemonic_pack-p.vhd:161:62  */
  assign n679_o = n676_o | n678_o;
  /* src/t400_mnemonic_pack-p.vhd:162:23  */
  assign n681_o = opcode_s == 8'b10110101;
  /* src/t400_mnemonic_pack-p.vhd:162:23  */
  assign n682_o = n679_o | n681_o;
  /* src/t400_mnemonic_pack-p.vhd:162:36  */
  assign n684_o = opcode_s == 8'b10110110;
  /* src/t400_mnemonic_pack-p.vhd:162:36  */
  assign n685_o = n682_o | n684_o;
  /* src/t400_mnemonic_pack-p.vhd:162:49  */
  assign n687_o = opcode_s == 8'b10110111;
  /* src/t400_mnemonic_pack-p.vhd:162:49  */
  assign n688_o = n685_o | n687_o;
  /* src/t400_mnemonic_pack-p.vhd:162:62  */
  assign n690_o = opcode_s == 8'b10111000;
  /* src/t400_mnemonic_pack-p.vhd:162:62  */
  assign n691_o = n688_o | n690_o;
  /* src/t400_mnemonic_pack-p.vhd:163:23  */
  assign n693_o = opcode_s == 8'b10111001;
  /* src/t400_mnemonic_pack-p.vhd:163:23  */
  assign n694_o = n691_o | n693_o;
  /* src/t400_mnemonic_pack-p.vhd:163:36  */
  assign n696_o = opcode_s == 8'b10111010;
  /* src/t400_mnemonic_pack-p.vhd:163:36  */
  assign n697_o = n694_o | n696_o;
  /* src/t400_mnemonic_pack-p.vhd:163:49  */
  assign n699_o = opcode_s == 8'b10111011;
  /* src/t400_mnemonic_pack-p.vhd:163:49  */
  assign n700_o = n697_o | n699_o;
  /* src/t400_mnemonic_pack-p.vhd:163:62  */
  assign n702_o = opcode_s == 8'b10111100;
  /* src/t400_mnemonic_pack-p.vhd:163:62  */
  assign n703_o = n700_o | n702_o;
  /* src/t400_mnemonic_pack-p.vhd:164:23  */
  assign n705_o = opcode_s == 8'b10111101;
  /* src/t400_mnemonic_pack-p.vhd:164:23  */
  assign n706_o = n703_o | n705_o;
  /* src/t400_mnemonic_pack-p.vhd:164:36  */
  assign n708_o = opcode_s == 8'b10111110;
  /* src/t400_mnemonic_pack-p.vhd:164:36  */
  assign n709_o = n706_o | n708_o;
  /* src/t400_mnemonic_pack-p.vhd:164:49  */
  assign n711_o = opcode_s == 8'b11000000;
  /* src/t400_mnemonic_pack-p.vhd:164:49  */
  assign n712_o = n709_o | n711_o;
  /* src/t400_mnemonic_pack-p.vhd:165:23  */
  assign n714_o = opcode_s == 8'b11000001;
  /* src/t400_mnemonic_pack-p.vhd:165:23  */
  assign n715_o = n712_o | n714_o;
  /* src/t400_mnemonic_pack-p.vhd:165:36  */
  assign n717_o = opcode_s == 8'b11000010;
  /* src/t400_mnemonic_pack-p.vhd:165:36  */
  assign n718_o = n715_o | n717_o;
  /* src/t400_mnemonic_pack-p.vhd:165:49  */
  assign n720_o = opcode_s == 8'b11000011;
  /* src/t400_mnemonic_pack-p.vhd:165:49  */
  assign n721_o = n718_o | n720_o;
  /* src/t400_mnemonic_pack-p.vhd:165:62  */
  assign n723_o = opcode_s == 8'b11000100;
  /* src/t400_mnemonic_pack-p.vhd:165:62  */
  assign n724_o = n721_o | n723_o;
  /* src/t400_mnemonic_pack-p.vhd:166:23  */
  assign n726_o = opcode_s == 8'b11000101;
  /* src/t400_mnemonic_pack-p.vhd:166:23  */
  assign n727_o = n724_o | n726_o;
  /* src/t400_mnemonic_pack-p.vhd:166:36  */
  assign n729_o = opcode_s == 8'b11000110;
  /* src/t400_mnemonic_pack-p.vhd:166:36  */
  assign n730_o = n727_o | n729_o;
  /* src/t400_mnemonic_pack-p.vhd:166:49  */
  assign n732_o = opcode_s == 8'b11000111;
  /* src/t400_mnemonic_pack-p.vhd:166:49  */
  assign n733_o = n730_o | n732_o;
  /* src/t400_mnemonic_pack-p.vhd:166:62  */
  assign n735_o = opcode_s == 8'b11001000;
  /* src/t400_mnemonic_pack-p.vhd:166:62  */
  assign n736_o = n733_o | n735_o;
  /* src/t400_mnemonic_pack-p.vhd:167:23  */
  assign n738_o = opcode_s == 8'b11001001;
  /* src/t400_mnemonic_pack-p.vhd:167:23  */
  assign n739_o = n736_o | n738_o;
  /* src/t400_mnemonic_pack-p.vhd:167:36  */
  assign n741_o = opcode_s == 8'b11001010;
  /* src/t400_mnemonic_pack-p.vhd:167:36  */
  assign n742_o = n739_o | n741_o;
  /* src/t400_mnemonic_pack-p.vhd:167:49  */
  assign n744_o = opcode_s == 8'b11001011;
  /* src/t400_mnemonic_pack-p.vhd:167:49  */
  assign n745_o = n742_o | n744_o;
  /* src/t400_mnemonic_pack-p.vhd:167:62  */
  assign n747_o = opcode_s == 8'b11001100;
  /* src/t400_mnemonic_pack-p.vhd:167:62  */
  assign n748_o = n745_o | n747_o;
  /* src/t400_mnemonic_pack-p.vhd:168:23  */
  assign n750_o = opcode_s == 8'b11001101;
  /* src/t400_mnemonic_pack-p.vhd:168:23  */
  assign n751_o = n748_o | n750_o;
  /* src/t400_mnemonic_pack-p.vhd:168:36  */
  assign n753_o = opcode_s == 8'b11001110;
  /* src/t400_mnemonic_pack-p.vhd:168:36  */
  assign n754_o = n751_o | n753_o;
  /* src/t400_mnemonic_pack-p.vhd:168:49  */
  assign n756_o = opcode_s == 8'b11001111;
  /* src/t400_mnemonic_pack-p.vhd:168:49  */
  assign n757_o = n754_o | n756_o;
  /* src/t400_mnemonic_pack-p.vhd:168:62  */
  assign n759_o = opcode_s == 8'b11010000;
  /* src/t400_mnemonic_pack-p.vhd:168:62  */
  assign n760_o = n757_o | n759_o;
  /* src/t400_mnemonic_pack-p.vhd:169:23  */
  assign n762_o = opcode_s == 8'b11010001;
  /* src/t400_mnemonic_pack-p.vhd:169:23  */
  assign n763_o = n760_o | n762_o;
  /* src/t400_mnemonic_pack-p.vhd:169:36  */
  assign n765_o = opcode_s == 8'b11010010;
  /* src/t400_mnemonic_pack-p.vhd:169:36  */
  assign n766_o = n763_o | n765_o;
  /* src/t400_mnemonic_pack-p.vhd:169:49  */
  assign n768_o = opcode_s == 8'b11010011;
  /* src/t400_mnemonic_pack-p.vhd:169:49  */
  assign n769_o = n766_o | n768_o;
  /* src/t400_mnemonic_pack-p.vhd:169:62  */
  assign n771_o = opcode_s == 8'b11010100;
  /* src/t400_mnemonic_pack-p.vhd:169:62  */
  assign n772_o = n769_o | n771_o;
  /* src/t400_mnemonic_pack-p.vhd:170:23  */
  assign n774_o = opcode_s == 8'b11010101;
  /* src/t400_mnemonic_pack-p.vhd:170:23  */
  assign n775_o = n772_o | n774_o;
  /* src/t400_mnemonic_pack-p.vhd:170:36  */
  assign n777_o = opcode_s == 8'b11010110;
  /* src/t400_mnemonic_pack-p.vhd:170:36  */
  assign n778_o = n775_o | n777_o;
  /* src/t400_mnemonic_pack-p.vhd:170:49  */
  assign n780_o = opcode_s == 8'b11010111;
  /* src/t400_mnemonic_pack-p.vhd:170:49  */
  assign n781_o = n778_o | n780_o;
  /* src/t400_mnemonic_pack-p.vhd:170:62  */
  assign n783_o = opcode_s == 8'b11011000;
  /* src/t400_mnemonic_pack-p.vhd:170:62  */
  assign n784_o = n781_o | n783_o;
  /* src/t400_mnemonic_pack-p.vhd:171:23  */
  assign n786_o = opcode_s == 8'b11011001;
  /* src/t400_mnemonic_pack-p.vhd:171:23  */
  assign n787_o = n784_o | n786_o;
  /* src/t400_mnemonic_pack-p.vhd:171:36  */
  assign n789_o = opcode_s == 8'b11011010;
  /* src/t400_mnemonic_pack-p.vhd:171:36  */
  assign n790_o = n787_o | n789_o;
  /* src/t400_mnemonic_pack-p.vhd:171:49  */
  assign n792_o = opcode_s == 8'b11011011;
  /* src/t400_mnemonic_pack-p.vhd:171:49  */
  assign n793_o = n790_o | n792_o;
  /* src/t400_mnemonic_pack-p.vhd:171:62  */
  assign n795_o = opcode_s == 8'b11011100;
  /* src/t400_mnemonic_pack-p.vhd:171:62  */
  assign n796_o = n793_o | n795_o;
  /* src/t400_mnemonic_pack-p.vhd:172:23  */
  assign n798_o = opcode_s == 8'b11011101;
  /* src/t400_mnemonic_pack-p.vhd:172:23  */
  assign n799_o = n796_o | n798_o;
  /* src/t400_mnemonic_pack-p.vhd:172:36  */
  assign n801_o = opcode_s == 8'b11011110;
  /* src/t400_mnemonic_pack-p.vhd:172:36  */
  assign n802_o = n799_o | n801_o;
  /* src/t400_mnemonic_pack-p.vhd:172:49  */
  assign n804_o = opcode_s == 8'b11011111;
  /* src/t400_mnemonic_pack-p.vhd:172:49  */
  assign n805_o = n802_o | n804_o;
  /* src/t400_mnemonic_pack-p.vhd:172:62  */
  assign n807_o = opcode_s == 8'b11100000;
  /* src/t400_mnemonic_pack-p.vhd:172:62  */
  assign n808_o = n805_o | n807_o;
  /* src/t400_mnemonic_pack-p.vhd:173:23  */
  assign n810_o = opcode_s == 8'b11100001;
  /* src/t400_mnemonic_pack-p.vhd:173:23  */
  assign n811_o = n808_o | n810_o;
  /* src/t400_mnemonic_pack-p.vhd:173:36  */
  assign n813_o = opcode_s == 8'b11100010;
  /* src/t400_mnemonic_pack-p.vhd:173:36  */
  assign n814_o = n811_o | n813_o;
  /* src/t400_mnemonic_pack-p.vhd:173:49  */
  assign n816_o = opcode_s == 8'b11100011;
  /* src/t400_mnemonic_pack-p.vhd:173:49  */
  assign n817_o = n814_o | n816_o;
  /* src/t400_mnemonic_pack-p.vhd:173:62  */
  assign n819_o = opcode_s == 8'b11100100;
  /* src/t400_mnemonic_pack-p.vhd:173:62  */
  assign n820_o = n817_o | n819_o;
  /* src/t400_mnemonic_pack-p.vhd:174:23  */
  assign n822_o = opcode_s == 8'b11100101;
  /* src/t400_mnemonic_pack-p.vhd:174:23  */
  assign n823_o = n820_o | n822_o;
  /* src/t400_mnemonic_pack-p.vhd:174:36  */
  assign n825_o = opcode_s == 8'b11100110;
  /* src/t400_mnemonic_pack-p.vhd:174:36  */
  assign n826_o = n823_o | n825_o;
  /* src/t400_mnemonic_pack-p.vhd:174:49  */
  assign n828_o = opcode_s == 8'b11100111;
  /* src/t400_mnemonic_pack-p.vhd:174:49  */
  assign n829_o = n826_o | n828_o;
  /* src/t400_mnemonic_pack-p.vhd:174:62  */
  assign n831_o = opcode_s == 8'b11101000;
  /* src/t400_mnemonic_pack-p.vhd:174:62  */
  assign n832_o = n829_o | n831_o;
  /* src/t400_mnemonic_pack-p.vhd:175:23  */
  assign n834_o = opcode_s == 8'b11101001;
  /* src/t400_mnemonic_pack-p.vhd:175:23  */
  assign n835_o = n832_o | n834_o;
  /* src/t400_mnemonic_pack-p.vhd:175:36  */
  assign n837_o = opcode_s == 8'b11101010;
  /* src/t400_mnemonic_pack-p.vhd:175:36  */
  assign n838_o = n835_o | n837_o;
  /* src/t400_mnemonic_pack-p.vhd:175:49  */
  assign n840_o = opcode_s == 8'b11101011;
  /* src/t400_mnemonic_pack-p.vhd:175:49  */
  assign n841_o = n838_o | n840_o;
  /* src/t400_mnemonic_pack-p.vhd:175:62  */
  assign n843_o = opcode_s == 8'b11101100;
  /* src/t400_mnemonic_pack-p.vhd:175:62  */
  assign n844_o = n841_o | n843_o;
  /* src/t400_mnemonic_pack-p.vhd:176:23  */
  assign n846_o = opcode_s == 8'b11101101;
  /* src/t400_mnemonic_pack-p.vhd:176:23  */
  assign n847_o = n844_o | n846_o;
  /* src/t400_mnemonic_pack-p.vhd:176:36  */
  assign n849_o = opcode_s == 8'b11101110;
  /* src/t400_mnemonic_pack-p.vhd:176:36  */
  assign n850_o = n847_o | n849_o;
  /* src/t400_mnemonic_pack-p.vhd:176:49  */
  assign n852_o = opcode_s == 8'b11101111;
  /* src/t400_mnemonic_pack-p.vhd:176:49  */
  assign n853_o = n850_o | n852_o;
  /* src/t400_mnemonic_pack-p.vhd:176:62  */
  assign n855_o = opcode_s == 8'b11110000;
  /* src/t400_mnemonic_pack-p.vhd:176:62  */
  assign n856_o = n853_o | n855_o;
  /* src/t400_mnemonic_pack-p.vhd:177:23  */
  assign n858_o = opcode_s == 8'b11110001;
  /* src/t400_mnemonic_pack-p.vhd:177:23  */
  assign n859_o = n856_o | n858_o;
  /* src/t400_mnemonic_pack-p.vhd:177:36  */
  assign n861_o = opcode_s == 8'b11110010;
  /* src/t400_mnemonic_pack-p.vhd:177:36  */
  assign n862_o = n859_o | n861_o;
  /* src/t400_mnemonic_pack-p.vhd:177:49  */
  assign n864_o = opcode_s == 8'b11110011;
  /* src/t400_mnemonic_pack-p.vhd:177:49  */
  assign n865_o = n862_o | n864_o;
  /* src/t400_mnemonic_pack-p.vhd:177:62  */
  assign n867_o = opcode_s == 8'b11110100;
  /* src/t400_mnemonic_pack-p.vhd:177:62  */
  assign n868_o = n865_o | n867_o;
  /* src/t400_mnemonic_pack-p.vhd:178:23  */
  assign n870_o = opcode_s == 8'b11110101;
  /* src/t400_mnemonic_pack-p.vhd:178:23  */
  assign n871_o = n868_o | n870_o;
  /* src/t400_mnemonic_pack-p.vhd:178:36  */
  assign n873_o = opcode_s == 8'b11110110;
  /* src/t400_mnemonic_pack-p.vhd:178:36  */
  assign n874_o = n871_o | n873_o;
  /* src/t400_mnemonic_pack-p.vhd:178:49  */
  assign n876_o = opcode_s == 8'b11110111;
  /* src/t400_mnemonic_pack-p.vhd:178:49  */
  assign n877_o = n874_o | n876_o;
  /* src/t400_mnemonic_pack-p.vhd:178:62  */
  assign n879_o = opcode_s == 8'b11111000;
  /* src/t400_mnemonic_pack-p.vhd:178:62  */
  assign n880_o = n877_o | n879_o;
  /* src/t400_mnemonic_pack-p.vhd:179:23  */
  assign n882_o = opcode_s == 8'b11111001;
  /* src/t400_mnemonic_pack-p.vhd:179:23  */
  assign n883_o = n880_o | n882_o;
  /* src/t400_mnemonic_pack-p.vhd:179:36  */
  assign n885_o = opcode_s == 8'b11111010;
  /* src/t400_mnemonic_pack-p.vhd:179:36  */
  assign n886_o = n883_o | n885_o;
  /* src/t400_mnemonic_pack-p.vhd:179:49  */
  assign n888_o = opcode_s == 8'b11111011;
  /* src/t400_mnemonic_pack-p.vhd:179:49  */
  assign n889_o = n886_o | n888_o;
  /* src/t400_mnemonic_pack-p.vhd:179:62  */
  assign n891_o = opcode_s == 8'b11111100;
  /* src/t400_mnemonic_pack-p.vhd:179:62  */
  assign n892_o = n889_o | n891_o;
  /* src/t400_mnemonic_pack-p.vhd:180:23  */
  assign n894_o = opcode_s == 8'b11111101;
  /* src/t400_mnemonic_pack-p.vhd:180:23  */
  assign n895_o = n892_o | n894_o;
  /* src/t400_mnemonic_pack-p.vhd:180:36  */
  assign n897_o = opcode_s == 8'b11111110;
  /* src/t400_mnemonic_pack-p.vhd:180:36  */
  assign n898_o = n895_o | n897_o;
  /* src/t400_mnemonic_pack-p.vhd:184:7  */
  assign n900_o = opcode_s == 8'b01101000;
  /* src/t400_mnemonic_pack-p.vhd:184:23  */
  assign n902_o = opcode_s == 8'b01101001;
  /* src/t400_mnemonic_pack-p.vhd:184:23  */
  assign n903_o = n900_o | n902_o;
  /* src/t400_mnemonic_pack-p.vhd:184:36  */
  assign n905_o = opcode_s == 8'b01101010;
  /* src/t400_mnemonic_pack-p.vhd:184:36  */
  assign n906_o = n903_o | n905_o;
  /* src/t400_mnemonic_pack-p.vhd:184:49  */
  assign n908_o = opcode_s == 8'b01101011;
  /* src/t400_mnemonic_pack-p.vhd:184:49  */
  assign n909_o = n906_o | n908_o;
  /* src/t400_mnemonic_pack-p.vhd:189:7  */
  assign n911_o = opcode_s == 8'b01001000;
  /* src/t400_mnemonic_pack-p.vhd:193:7  */
  assign n913_o = opcode_s == 8'b01001001;
  /* src/t400_mnemonic_pack-p.vhd:197:7  */
  assign n915_o = opcode_s == 8'b00000101;
  /* src/t400_mnemonic_pack-p.vhd:197:23  */
  assign n917_o = opcode_s == 8'b00010101;
  /* src/t400_mnemonic_pack-p.vhd:197:23  */
  assign n918_o = n915_o | n917_o;
  /* src/t400_mnemonic_pack-p.vhd:197:36  */
  assign n920_o = opcode_s == 8'b00100101;
  /* src/t400_mnemonic_pack-p.vhd:197:36  */
  assign n921_o = n918_o | n920_o;
  /* src/t400_mnemonic_pack-p.vhd:197:49  */
  assign n923_o = opcode_s == 8'b00110101;
  /* src/t400_mnemonic_pack-p.vhd:197:49  */
  assign n924_o = n921_o | n923_o;
  /* src/t400_mnemonic_pack-p.vhd:201:7  */
  assign n926_o = opcode_s == 8'b00100011;
  /* src/t400_mnemonic_pack-p.vhd:206:7  */
  assign n928_o = opcode_s == 8'b10111111;
  /* src/t400_mnemonic_pack-p.vhd:210:7  */
  assign n930_o = opcode_s == 8'b01001100;
  /* src/t400_mnemonic_pack-p.vhd:210:23  */
  assign n932_o = opcode_s == 8'b01000101;
  /* src/t400_mnemonic_pack-p.vhd:210:23  */
  assign n933_o = n930_o | n932_o;
  /* src/t400_mnemonic_pack-p.vhd:210:36  */
  assign n935_o = opcode_s == 8'b01000010;
  /* src/t400_mnemonic_pack-p.vhd:210:36  */
  assign n936_o = n933_o | n935_o;
  /* src/t400_mnemonic_pack-p.vhd:210:49  */
  assign n938_o = opcode_s == 8'b01000011;
  /* src/t400_mnemonic_pack-p.vhd:210:49  */
  assign n939_o = n936_o | n938_o;
  /* src/t400_mnemonic_pack-p.vhd:214:7  */
  assign n941_o = opcode_s == 8'b01001101;
  /* src/t400_mnemonic_pack-p.vhd:214:23  */
  assign n943_o = opcode_s == 8'b01000111;
  /* src/t400_mnemonic_pack-p.vhd:214:23  */
  assign n944_o = n941_o | n943_o;
  /* src/t400_mnemonic_pack-p.vhd:214:36  */
  assign n946_o = opcode_s == 8'b01000110;
  /* src/t400_mnemonic_pack-p.vhd:214:36  */
  assign n947_o = n944_o | n946_o;
  /* src/t400_mnemonic_pack-p.vhd:214:49  */
  assign n949_o = opcode_s == 8'b01001011;
  /* src/t400_mnemonic_pack-p.vhd:214:49  */
  assign n950_o = n947_o | n949_o;
  /* src/t400_mnemonic_pack-p.vhd:218:7  */
  assign n952_o = opcode_s == 8'b01110000;
  /* src/t400_mnemonic_pack-p.vhd:218:23  */
  assign n954_o = opcode_s == 8'b01110001;
  /* src/t400_mnemonic_pack-p.vhd:218:23  */
  assign n955_o = n952_o | n954_o;
  /* src/t400_mnemonic_pack-p.vhd:218:36  */
  assign n957_o = opcode_s == 8'b01110010;
  /* src/t400_mnemonic_pack-p.vhd:218:36  */
  assign n958_o = n955_o | n957_o;
  /* src/t400_mnemonic_pack-p.vhd:218:49  */
  assign n960_o = opcode_s == 8'b01110011;
  /* src/t400_mnemonic_pack-p.vhd:218:49  */
  assign n961_o = n958_o | n960_o;
  /* src/t400_mnemonic_pack-p.vhd:218:62  */
  assign n963_o = opcode_s == 8'b01110100;
  /* src/t400_mnemonic_pack-p.vhd:218:62  */
  assign n964_o = n961_o | n963_o;
  /* src/t400_mnemonic_pack-p.vhd:219:23  */
  assign n966_o = opcode_s == 8'b01110101;
  /* src/t400_mnemonic_pack-p.vhd:219:23  */
  assign n967_o = n964_o | n966_o;
  /* src/t400_mnemonic_pack-p.vhd:219:36  */
  assign n969_o = opcode_s == 8'b01110110;
  /* src/t400_mnemonic_pack-p.vhd:219:36  */
  assign n970_o = n967_o | n969_o;
  /* src/t400_mnemonic_pack-p.vhd:219:49  */
  assign n972_o = opcode_s == 8'b01110111;
  /* src/t400_mnemonic_pack-p.vhd:219:49  */
  assign n973_o = n970_o | n972_o;
  /* src/t400_mnemonic_pack-p.vhd:219:62  */
  assign n975_o = opcode_s == 8'b01111000;
  /* src/t400_mnemonic_pack-p.vhd:219:62  */
  assign n976_o = n973_o | n975_o;
  /* src/t400_mnemonic_pack-p.vhd:220:23  */
  assign n978_o = opcode_s == 8'b01111001;
  /* src/t400_mnemonic_pack-p.vhd:220:23  */
  assign n979_o = n976_o | n978_o;
  /* src/t400_mnemonic_pack-p.vhd:220:36  */
  assign n981_o = opcode_s == 8'b01111010;
  /* src/t400_mnemonic_pack-p.vhd:220:36  */
  assign n982_o = n979_o | n981_o;
  /* src/t400_mnemonic_pack-p.vhd:220:49  */
  assign n984_o = opcode_s == 8'b01111011;
  /* src/t400_mnemonic_pack-p.vhd:220:49  */
  assign n985_o = n982_o | n984_o;
  /* src/t400_mnemonic_pack-p.vhd:220:62  */
  assign n987_o = opcode_s == 8'b01111100;
  /* src/t400_mnemonic_pack-p.vhd:220:62  */
  assign n988_o = n985_o | n987_o;
  /* src/t400_mnemonic_pack-p.vhd:221:23  */
  assign n990_o = opcode_s == 8'b01111101;
  /* src/t400_mnemonic_pack-p.vhd:221:23  */
  assign n991_o = n988_o | n990_o;
  /* src/t400_mnemonic_pack-p.vhd:221:36  */
  assign n993_o = opcode_s == 8'b01111110;
  /* src/t400_mnemonic_pack-p.vhd:221:36  */
  assign n994_o = n991_o | n993_o;
  /* src/t400_mnemonic_pack-p.vhd:221:49  */
  assign n996_o = opcode_s == 8'b01111111;
  /* src/t400_mnemonic_pack-p.vhd:221:49  */
  assign n997_o = n994_o | n996_o;
  /* src/t400_mnemonic_pack-p.vhd:225:7  */
  assign n999_o = opcode_s == 8'b00000110;
  /* src/t400_mnemonic_pack-p.vhd:225:23  */
  assign n1001_o = opcode_s == 8'b00010110;
  /* src/t400_mnemonic_pack-p.vhd:225:23  */
  assign n1002_o = n999_o | n1001_o;
  /* src/t400_mnemonic_pack-p.vhd:225:36  */
  assign n1004_o = opcode_s == 8'b00100110;
  /* src/t400_mnemonic_pack-p.vhd:225:36  */
  assign n1005_o = n1002_o | n1004_o;
  /* src/t400_mnemonic_pack-p.vhd:225:49  */
  assign n1007_o = opcode_s == 8'b00110110;
  /* src/t400_mnemonic_pack-p.vhd:225:49  */
  assign n1008_o = n1005_o | n1007_o;
  /* src/t400_mnemonic_pack-p.vhd:229:7  */
  assign n1010_o = opcode_s == 8'b00000111;
  /* src/t400_mnemonic_pack-p.vhd:229:23  */
  assign n1012_o = opcode_s == 8'b00010111;
  /* src/t400_mnemonic_pack-p.vhd:229:23  */
  assign n1013_o = n1010_o | n1012_o;
  /* src/t400_mnemonic_pack-p.vhd:229:36  */
  assign n1015_o = opcode_s == 8'b00100111;
  /* src/t400_mnemonic_pack-p.vhd:229:36  */
  assign n1016_o = n1013_o | n1015_o;
  /* src/t400_mnemonic_pack-p.vhd:229:49  */
  assign n1018_o = opcode_s == 8'b00110111;
  /* src/t400_mnemonic_pack-p.vhd:229:49  */
  assign n1019_o = n1016_o | n1018_o;
  /* src/t400_mnemonic_pack-p.vhd:233:7  */
  assign n1021_o = opcode_s == 8'b00000100;
  /* src/t400_mnemonic_pack-p.vhd:233:23  */
  assign n1023_o = opcode_s == 8'b00010100;
  /* src/t400_mnemonic_pack-p.vhd:233:23  */
  assign n1024_o = n1021_o | n1023_o;
  /* src/t400_mnemonic_pack-p.vhd:233:36  */
  assign n1026_o = opcode_s == 8'b00100100;
  /* src/t400_mnemonic_pack-p.vhd:233:36  */
  assign n1027_o = n1024_o | n1026_o;
  /* src/t400_mnemonic_pack-p.vhd:233:49  */
  assign n1029_o = opcode_s == 8'b00110100;
  /* src/t400_mnemonic_pack-p.vhd:233:49  */
  assign n1030_o = n1027_o | n1029_o;
  /* src/t400_mnemonic_pack-p.vhd:237:7  */
  assign n1032_o = opcode_s == 8'b01010000;
  /* src/t400_mnemonic_pack-p.vhd:241:7  */
  assign n1034_o = opcode_s == 8'b01001110;
  /* src/t400_mnemonic_pack-p.vhd:245:7  */
  assign n1036_o = opcode_s == 8'b00001000;
  /* src/t400_mnemonic_pack-p.vhd:245:23  */
  assign n1038_o = opcode_s == 8'b00001001;
  /* src/t400_mnemonic_pack-p.vhd:245:23  */
  assign n1039_o = n1036_o | n1038_o;
  /* src/t400_mnemonic_pack-p.vhd:245:36  */
  assign n1041_o = opcode_s == 8'b00001010;
  /* src/t400_mnemonic_pack-p.vhd:245:36  */
  assign n1042_o = n1039_o | n1041_o;
  /* src/t400_mnemonic_pack-p.vhd:245:49  */
  assign n1044_o = opcode_s == 8'b00001011;
  /* src/t400_mnemonic_pack-p.vhd:245:49  */
  assign n1045_o = n1042_o | n1044_o;
  /* src/t400_mnemonic_pack-p.vhd:245:62  */
  assign n1047_o = opcode_s == 8'b00001100;
  /* src/t400_mnemonic_pack-p.vhd:245:62  */
  assign n1048_o = n1045_o | n1047_o;
  /* src/t400_mnemonic_pack-p.vhd:246:23  */
  assign n1050_o = opcode_s == 8'b00001101;
  /* src/t400_mnemonic_pack-p.vhd:246:23  */
  assign n1051_o = n1048_o | n1050_o;
  /* src/t400_mnemonic_pack-p.vhd:246:36  */
  assign n1053_o = opcode_s == 8'b00001110;
  /* src/t400_mnemonic_pack-p.vhd:246:36  */
  assign n1054_o = n1051_o | n1053_o;
  /* src/t400_mnemonic_pack-p.vhd:246:49  */
  assign n1056_o = opcode_s == 8'b00001111;
  /* src/t400_mnemonic_pack-p.vhd:246:49  */
  assign n1057_o = n1054_o | n1056_o;
  /* src/t400_mnemonic_pack-p.vhd:246:62  */
  assign n1059_o = opcode_s == 8'b00011000;
  /* src/t400_mnemonic_pack-p.vhd:246:62  */
  assign n1060_o = n1057_o | n1059_o;
  /* src/t400_mnemonic_pack-p.vhd:247:23  */
  assign n1062_o = opcode_s == 8'b00011001;
  /* src/t400_mnemonic_pack-p.vhd:247:23  */
  assign n1063_o = n1060_o | n1062_o;
  /* src/t400_mnemonic_pack-p.vhd:247:36  */
  assign n1065_o = opcode_s == 8'b00011010;
  /* src/t400_mnemonic_pack-p.vhd:247:36  */
  assign n1066_o = n1063_o | n1065_o;
  /* src/t400_mnemonic_pack-p.vhd:247:49  */
  assign n1068_o = opcode_s == 8'b00011011;
  /* src/t400_mnemonic_pack-p.vhd:247:49  */
  assign n1069_o = n1066_o | n1068_o;
  /* src/t400_mnemonic_pack-p.vhd:247:62  */
  assign n1071_o = opcode_s == 8'b00011100;
  /* src/t400_mnemonic_pack-p.vhd:247:62  */
  assign n1072_o = n1069_o | n1071_o;
  /* src/t400_mnemonic_pack-p.vhd:248:23  */
  assign n1074_o = opcode_s == 8'b00011101;
  /* src/t400_mnemonic_pack-p.vhd:248:23  */
  assign n1075_o = n1072_o | n1074_o;
  /* src/t400_mnemonic_pack-p.vhd:248:36  */
  assign n1077_o = opcode_s == 8'b00011110;
  /* src/t400_mnemonic_pack-p.vhd:248:36  */
  assign n1078_o = n1075_o | n1077_o;
  /* src/t400_mnemonic_pack-p.vhd:248:49  */
  assign n1080_o = opcode_s == 8'b00011111;
  /* src/t400_mnemonic_pack-p.vhd:248:49  */
  assign n1081_o = n1078_o | n1080_o;
  /* src/t400_mnemonic_pack-p.vhd:248:62  */
  assign n1083_o = opcode_s == 8'b00101000;
  /* src/t400_mnemonic_pack-p.vhd:248:62  */
  assign n1084_o = n1081_o | n1083_o;
  /* src/t400_mnemonic_pack-p.vhd:249:23  */
  assign n1086_o = opcode_s == 8'b00101001;
  /* src/t400_mnemonic_pack-p.vhd:249:23  */
  assign n1087_o = n1084_o | n1086_o;
  /* src/t400_mnemonic_pack-p.vhd:249:36  */
  assign n1089_o = opcode_s == 8'b00101010;
  /* src/t400_mnemonic_pack-p.vhd:249:36  */
  assign n1090_o = n1087_o | n1089_o;
  /* src/t400_mnemonic_pack-p.vhd:249:49  */
  assign n1092_o = opcode_s == 8'b00101011;
  /* src/t400_mnemonic_pack-p.vhd:249:49  */
  assign n1093_o = n1090_o | n1092_o;
  /* src/t400_mnemonic_pack-p.vhd:249:62  */
  assign n1095_o = opcode_s == 8'b00101100;
  /* src/t400_mnemonic_pack-p.vhd:249:62  */
  assign n1096_o = n1093_o | n1095_o;
  /* src/t400_mnemonic_pack-p.vhd:250:23  */
  assign n1098_o = opcode_s == 8'b00101101;
  /* src/t400_mnemonic_pack-p.vhd:250:23  */
  assign n1099_o = n1096_o | n1098_o;
  /* src/t400_mnemonic_pack-p.vhd:250:36  */
  assign n1101_o = opcode_s == 8'b00101110;
  /* src/t400_mnemonic_pack-p.vhd:250:36  */
  assign n1102_o = n1099_o | n1101_o;
  /* src/t400_mnemonic_pack-p.vhd:250:49  */
  assign n1104_o = opcode_s == 8'b00101111;
  /* src/t400_mnemonic_pack-p.vhd:250:49  */
  assign n1105_o = n1102_o | n1104_o;
  /* src/t400_mnemonic_pack-p.vhd:250:62  */
  assign n1107_o = opcode_s == 8'b00111000;
  /* src/t400_mnemonic_pack-p.vhd:250:62  */
  assign n1108_o = n1105_o | n1107_o;
  /* src/t400_mnemonic_pack-p.vhd:251:23  */
  assign n1110_o = opcode_s == 8'b00111001;
  /* src/t400_mnemonic_pack-p.vhd:251:23  */
  assign n1111_o = n1108_o | n1110_o;
  /* src/t400_mnemonic_pack-p.vhd:251:36  */
  assign n1113_o = opcode_s == 8'b00111010;
  /* src/t400_mnemonic_pack-p.vhd:251:36  */
  assign n1114_o = n1111_o | n1113_o;
  /* src/t400_mnemonic_pack-p.vhd:251:49  */
  assign n1116_o = opcode_s == 8'b00111011;
  /* src/t400_mnemonic_pack-p.vhd:251:49  */
  assign n1117_o = n1114_o | n1116_o;
  /* src/t400_mnemonic_pack-p.vhd:251:62  */
  assign n1119_o = opcode_s == 8'b00111100;
  /* src/t400_mnemonic_pack-p.vhd:251:62  */
  assign n1120_o = n1117_o | n1119_o;
  /* src/t400_mnemonic_pack-p.vhd:252:23  */
  assign n1122_o = opcode_s == 8'b00111101;
  /* src/t400_mnemonic_pack-p.vhd:252:23  */
  assign n1123_o = n1120_o | n1122_o;
  /* src/t400_mnemonic_pack-p.vhd:252:36  */
  assign n1125_o = opcode_s == 8'b00111110;
  /* src/t400_mnemonic_pack-p.vhd:252:36  */
  assign n1126_o = n1123_o | n1125_o;
  /* src/t400_mnemonic_pack-p.vhd:252:49  */
  assign n1128_o = opcode_s == 8'b00111111;
  /* src/t400_mnemonic_pack-p.vhd:252:49  */
  assign n1129_o = n1126_o | n1128_o;
  /* src/t400_mnemonic_pack-p.vhd:256:7  */
  assign n1131_o = opcode_s == 8'b00010010;
  /* src/t400_mnemonic_pack-p.vhd:262:7  */
  assign n1133_o = opcode_s == 8'b00100000;
  /* src/t400_mnemonic_pack-p.vhd:266:7  */
  assign n1135_o = opcode_s == 8'b00100001;
  /* src/t400_mnemonic_pack-p.vhd:270:7  */
  assign n1137_o = opcode_s == 8'b00000001;
  /* src/t400_mnemonic_pack-p.vhd:270:23  */
  assign n1139_o = opcode_s == 8'b00010001;
  /* src/t400_mnemonic_pack-p.vhd:270:23  */
  assign n1140_o = n1137_o | n1139_o;
  /* src/t400_mnemonic_pack-p.vhd:270:36  */
  assign n1142_o = opcode_s == 8'b00000011;
  /* src/t400_mnemonic_pack-p.vhd:270:36  */
  assign n1143_o = n1140_o | n1142_o;
  /* src/t400_mnemonic_pack-p.vhd:270:49  */
  assign n1145_o = opcode_s == 8'b00010011;
  /* src/t400_mnemonic_pack-p.vhd:270:49  */
  assign n1146_o = n1143_o | n1145_o;
  /* src/t400_mnemonic_pack-p.vhd:274:7  */
  assign n1148_o = opcode_s == 8'b01000001;
  /* src/t400_mnemonic_pack-p.vhd:280:7  */
  assign n1150_o = opcode_s == 8'b01001111;
  /* src/t400_mnemonic_pack-p.vhd:284:7  */
  assign n1152_o = opcode_s == 8'b00110011;
  assign n1153_o = {n1152_o, n1150_o, n1148_o, n1146_o, n1135_o, n1133_o, n1131_o, n1129_o, n1034_o, n1032_o, n1030_o, n1019_o, n1008_o, n997_o, n950_o, n939_o, n928_o, n926_o, n924_o, n913_o, n911_o, n909_o, n898_o, n521_o, n510_o, n508_o, n506_o, n501_o, n499_o, n497_o, n495_o, n493_o, n449_o, n447_o, n445_o};
  /* src/t400_mnemonic_pack-p.vhd:90:5  */
  always @*
    case (n1153_o)
      35'b10000000000000000000000000000000000: n1190_o = 6'b100001;
      35'b01000000000000000000000000000000000: n1190_o = 6'b100010;
      35'b00100000000000000000000000000000000: n1190_o = 6'b100000;
      35'b00010000000000000000000000000000000: n1190_o = 6'b011111;
      35'b00001000000000000000000000000000000: n1190_o = 6'b011110;
      35'b00000100000000000000000000000000000: n1190_o = 6'b011101;
      35'b00000010000000000000000000000000000: n1190_o = 6'b011100;
      35'b00000001000000000000000000000000000: n1190_o = 6'b011011;
      35'b00000000100000000000000000000000000: n1190_o = 6'b011010;
      35'b00000000010000000000000000000000000: n1190_o = 6'b011001;
      35'b00000000001000000000000000000000000: n1190_o = 6'b011000;
      35'b00000000000100000000000000000000000: n1190_o = 6'b010111;
      35'b00000000000010000000000000000000000: n1190_o = 6'b010110;
      35'b00000000000001000000000000000000000: n1190_o = 6'b010101;
      35'b00000000000000100000000000000000000: n1190_o = 6'b010100;
      35'b00000000000000010000000000000000000: n1190_o = 6'b010011;
      35'b00000000000000001000000000000000000: n1190_o = 6'b010010;
      35'b00000000000000000100000000000000000: n1190_o = 6'b010001;
      35'b00000000000000000010000000000000000: n1190_o = 6'b010000;
      35'b00000000000000000001000000000000000: n1190_o = 6'b001111;
      35'b00000000000000000000100000000000000: n1190_o = 6'b001110;
      35'b00000000000000000000010000000000000: n1190_o = 6'b001101;
      35'b00000000000000000000001000000000000: n1190_o = 6'b001100;
      35'b00000000000000000000000100000000000: n1190_o = 6'b001011;
      35'b00000000000000000000000010000000000: n1190_o = 6'b001010;
      35'b00000000000000000000000001000000000: n1190_o = 6'b001001;
      35'b00000000000000000000000000100000000: n1190_o = 6'b001000;
      35'b00000000000000000000000000010000000: n1190_o = 6'b000111;
      35'b00000000000000000000000000001000000: n1190_o = 6'b000110;
      35'b00000000000000000000000000000100000: n1190_o = 6'b000101;
      35'b00000000000000000000000000000010000: n1190_o = 6'b000100;
      35'b00000000000000000000000000000001000: n1190_o = 6'b000011;
      35'b00000000000000000000000000000000100: n1190_o = 6'b000010;
      35'b00000000000000000000000000000000010: n1190_o = 6'b000001;
      35'b00000000000000000000000000000000001: n1190_o = 6'b000000;
      default: n1190_o = 6'b000111;
    endcase
  /* src/t400_mnemonic_pack-p.vhd:90:5  */
  always @*
    case (n1153_o)
      35'b10000000000000000000000000000000000: n1197_o = 1'b1;
      35'b01000000000000000000000000000000000: n1197_o = 1'b0;
      35'b00100000000000000000000000000000000: n1197_o = 1'b0;
      35'b00010000000000000000000000000000000: n1197_o = 1'b0;
      35'b00001000000000000000000000000000000: n1197_o = 1'b0;
      35'b00000100000000000000000000000000000: n1197_o = 1'b0;
      35'b00000010000000000000000000000000000: n1197_o = 1'b0;
      35'b00000001000000000000000000000000000: n1197_o = 1'b0;
      35'b00000000100000000000000000000000000: n1197_o = 1'b0;
      35'b00000000010000000000000000000000000: n1197_o = 1'b0;
      35'b00000000001000000000000000000000000: n1197_o = 1'b0;
      35'b00000000000100000000000000000000000: n1197_o = 1'b0;
      35'b00000000000010000000000000000000000: n1197_o = 1'b0;
      35'b00000000000001000000000000000000000: n1197_o = 1'b0;
      35'b00000000000000100000000000000000000: n1197_o = 1'b0;
      35'b00000000000000010000000000000000000: n1197_o = 1'b0;
      35'b00000000000000001000000000000000000: n1197_o = 1'b0;
      35'b00000000000000000100000000000000000: n1197_o = 1'b1;
      35'b00000000000000000010000000000000000: n1197_o = 1'b0;
      35'b00000000000000000001000000000000000: n1197_o = 1'b0;
      35'b00000000000000000000100000000000000: n1197_o = 1'b0;
      35'b00000000000000000000010000000000000: n1197_o = 1'b1;
      35'b00000000000000000000001000000000000: n1197_o = 1'b0;
      35'b00000000000000000000000100000000000: n1197_o = 1'b1;
      35'b00000000000000000000000010000000000: n1197_o = 1'b0;
      35'b00000000000000000000000001000000000: n1197_o = 1'b0;
      35'b00000000000000000000000000100000000: n1197_o = 1'b0;
      35'b00000000000000000000000000010000000: n1197_o = 1'b0;
      35'b00000000000000000000000000001000000: n1197_o = 1'b0;
      35'b00000000000000000000000000000100000: n1197_o = 1'b0;
      35'b00000000000000000000000000000010000: n1197_o = 1'b0;
      35'b00000000000000000000000000000001000: n1197_o = 1'b0;
      35'b00000000000000000000000000000000100: n1197_o = 1'b0;
      35'b00000000000000000000000000000000010: n1197_o = 1'b0;
      35'b00000000000000000000000000000000001: n1197_o = 1'b0;
      default: n1197_o = 1'b0;
    endcase
  assign n1201_o = {n1197_o, n1190_o};
  /* src/t400_decoder.vhd:259:34  */
  assign n1202_o = mnemonic_rec_s[5:0];
  /* src/t400_decoder.vhd:260:34  */
  assign n1203_o = mnemonic_rec_s[6];
  /* src/t400_decoder.vhd:307:5  */
  assign n1212_o = icyc_en_i ? 4'b0001 : 4'b0000;
  /* src/t400_decoder.vhd:315:18  */
  assign n1214_o = last_cycle_s & icyc_en_i;
  /* src/t400_decoder.vhd:315:5  */
  assign n1217_o = n1214_o ? 4'b0001 : 4'b0000;
  /* src/t400_decoder.vhd:321:8  */
  assign n1219_o = ~skip_i;
  /* src/t400_decoder.vhd:326:20  */
  assign n1220_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:326:20  */
  assign n1222_o = n1220_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:326:11  */
  assign n1224_o = n1222_o ? 4'b0011 : n1217_o;
  /* src/t400_decoder.vhd:326:11  */
  assign n1227_o = n1222_o ? 5'b01100 : 5'b00000;
  /* src/t400_decoder.vhd:325:9  */
  assign n1229_o = mnemonic_q == 6'b000000;
  /* src/t400_decoder.vhd:333:20  */
  assign n1230_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:333:20  */
  assign n1232_o = n1230_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:333:11  */
  assign n1235_o = n1232_o ? 5'b01010 : 5'b00000;
  /* src/t400_decoder.vhd:332:9  */
  assign n1237_o = mnemonic_q == 6'b000001;
  /* src/t400_decoder.vhd:339:20  */
  assign n1238_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:339:20  */
  assign n1240_o = n1238_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:339:11  */
  assign n1243_o = n1240_o ? 5'b01011 : 5'b00000;
  /* src/t400_decoder.vhd:338:9  */
  assign n1245_o = mnemonic_q == 6'b000010;
  /* src/t400_decoder.vhd:345:45  */
  assign n1246_o = ibyte1_q[3:0];
  /* src/t400_decoder.vhd:346:20  */
  assign n1247_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:346:20  */
  assign n1249_o = n1247_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:346:11  */
  assign n1251_o = n1249_o ? 4'b0011 : n1217_o;
  /* src/t400_decoder.vhd:346:11  */
  assign n1254_o = n1249_o ? 5'b01101 : 5'b00000;
  /* src/t400_decoder.vhd:344:9  */
  assign n1256_o = mnemonic_q == 6'b000011;
  /* src/t400_decoder.vhd:354:13  */
  assign n1258_o = cyc_cnt_q == 3'b000;
  /* src/t400_decoder.vhd:356:13  */
  assign n1260_o = cyc_cnt_q == 3'b001;
  assign n1261_o = {n1260_o, n1258_o};
  /* src/t400_decoder.vhd:353:11  */
  always @*
    case (n1261_o)
      2'b10: n1263_o = 4'b0011;
      2'b01: n1263_o = n1217_o;
      default: n1263_o = n1217_o;
    endcase
  /* src/t400_decoder.vhd:353:11  */
  always @*
    case (n1261_o)
      2'b10: n1267_o = 5'b01100;
      2'b01: n1267_o = 5'b01110;
      default: n1267_o = 5'b00000;
    endcase
  /* src/t400_decoder.vhd:352:9  */
  assign n1269_o = mnemonic_q == 6'b000100;
  /* src/t400_decoder.vhd:365:20  */
  assign n1270_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:365:20  */
  assign n1272_o = n1270_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:365:11  */
  assign n1275_o = n1272_o ? 5'b00001 : 5'b00000;
  /* src/t400_decoder.vhd:364:9  */
  assign n1277_o = mnemonic_q == 6'b000101;
  /* src/t400_decoder.vhd:371:20  */
  assign n1278_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:371:20  */
  assign n1280_o = n1278_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:371:11  */
  assign n1283_o = n1280_o ? 5'b01110 : 5'b00000;
  /* src/t400_decoder.vhd:370:9  */
  assign n1285_o = mnemonic_q == 6'b000110;
  /* src/t400_decoder.vhd:376:9  */
  assign n1287_o = mnemonic_q == 6'b000111;
  /* src/t400_decoder.vhd:382:20  */
  assign n1288_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:382:20  */
  assign n1290_o = n1288_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:383:24  */
  assign n1291_o = ibyte1_q[4];
  /* src/t400_decoder.vhd:383:13  */
  assign n1294_o = n1291_o ? 5'b01111 : 5'b10000;
  /* src/t400_decoder.vhd:382:11  */
  assign n1296_o = n1290_o ? n1294_o : 5'b00000;
  /* src/t400_decoder.vhd:381:9  */
  assign n1298_o = mnemonic_q == 6'b001000;
  /* src/t400_decoder.vhd:392:20  */
  assign n1299_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:392:20  */
  assign n1301_o = n1299_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:392:11  */
  assign n1304_o = n1301_o ? 5'b10001 : 5'b00000;
  /* src/t400_decoder.vhd:391:9  */
  assign n1306_o = mnemonic_q == 6'b001001;
  /* src/t400_decoder.vhd:401:20  */
  assign n1307_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:401:20  */
  assign n1309_o = n1307_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:402:16  */
  assign n1310_o = ~second_cyc_q;
  /* src/t400_decoder.vhd:402:13  */
  assign n1313_o = n1310_o ? 4'b0111 : 4'b0100;
  /* src/t400_decoder.vhd:401:11  */
  assign n1314_o = n1309_o ? n1313_o : n1212_o;
  /* src/t400_decoder.vhd:411:28  */
  assign n1315_o = ~second_cyc_q;
  /* src/t400_decoder.vhd:411:24  */
  assign n1316_o = n1315_o & icyc_en_i;
  /* src/t400_decoder.vhd:411:11  */
  assign n1318_o = n1316_o ? 4'b0000 : n1314_o;
  /* src/t400_decoder.vhd:397:9  */
  assign n1320_o = mnemonic_q == 6'b001010;
  /* src/t400_decoder.vhd:419:33  */
  assign n1321_o = ibyte1_q[1];
  /* src/t400_decoder.vhd:419:47  */
  assign n1322_o = ibyte1_q[0];
  /* src/t400_decoder.vhd:419:37  */
  assign n1323_o = {n1321_o, n1322_o};
  /* src/t400_decoder.vhd:419:51  */
  assign n1324_o = {n1323_o, ibyte2_q};
  /* src/t400_decoder.vhd:420:37  */
  assign n1325_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:420:37  */
  assign n1327_o = n1325_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:420:27  */
  assign n1328_o = n1327_o & second_cyc_q;
  /* src/t400_decoder.vhd:420:11  */
  assign n1330_o = n1328_o ? 4'b0101 : n1212_o;
  /* src/t400_decoder.vhd:417:9  */
  assign n1332_o = mnemonic_q == 6'b001011;
  /* src/t400_decoder.vhd:428:46  */
  assign n1333_o = ibyte1_q[6:0];
  /* src/t400_decoder.vhd:428:36  */
  assign n1335_o = {3'b001, n1333_o};
  /* src/t400_decoder.vhd:429:20  */
  assign n1336_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:429:20  */
  assign n1338_o = n1336_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:430:28  */
  assign n1339_o = pm_addr_i[9:7];
  /* src/t400_decoder.vhd:430:41  */
  assign n1341_o = n1339_o == 3'b001;
  /* src/t400_decoder.vhd:433:27  */
  assign n1342_o = ibyte1_q[6];
  /* src/t400_decoder.vhd:433:13  */
  assign n1345_o = n1342_o ? 4'b0010 : 4'b0101;
  /* src/t400_decoder.vhd:433:13  */
  assign n1348_o = n1342_o ? 2'b00 : 2'b01;
  /* src/t400_decoder.vhd:430:13  */
  assign n1350_o = n1341_o ? 4'b0011 : n1345_o;
  /* src/t400_decoder.vhd:430:13  */
  assign n1352_o = n1341_o ? 2'b00 : n1348_o;
  /* src/t400_decoder.vhd:429:11  */
  assign n1353_o = n1338_o ? n1350_o : n1212_o;
  /* src/t400_decoder.vhd:429:11  */
  assign n1355_o = n1338_o ? n1352_o : 2'b00;
  /* src/t400_decoder.vhd:425:9  */
  assign n1357_o = mnemonic_q == 6'b001100;
  /* src/t400_decoder.vhd:446:33  */
  assign n1358_o = ibyte1_q[1];
  /* src/t400_decoder.vhd:446:47  */
  assign n1359_o = ibyte1_q[0];
  /* src/t400_decoder.vhd:446:37  */
  assign n1360_o = {n1358_o, n1359_o};
  /* src/t400_decoder.vhd:446:51  */
  assign n1361_o = {n1360_o, ibyte2_q};
  /* src/t400_decoder.vhd:447:37  */
  assign n1362_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:447:37  */
  assign n1364_o = n1362_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:447:27  */
  assign n1365_o = n1364_o & second_cyc_q;
  /* src/t400_decoder.vhd:447:11  */
  assign n1367_o = n1365_o ? 4'b0101 : n1212_o;
  /* src/t400_decoder.vhd:447:11  */
  assign n1370_o = n1365_o ? 2'b01 : 2'b00;
  /* src/t400_decoder.vhd:444:9  */
  assign n1372_o = mnemonic_q == 6'b001101;
  /* src/t400_decoder.vhd:455:20  */
  assign n1373_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:455:20  */
  assign n1375_o = n1373_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:455:11  */
  assign n1377_o = n1375_o ? 4'b0110 : n1212_o;
  /* src/t400_decoder.vhd:455:11  */
  assign n1380_o = n1375_o ? 2'b10 : 2'b00;
  /* src/t400_decoder.vhd:455:11  */
  assign n1382_o = n1375_o ? 4'b1110 : n1217_o;
  /* src/t400_decoder.vhd:453:9  */
  assign n1384_o = mnemonic_q == 6'b001110;
  /* src/t400_decoder.vhd:468:20  */
  assign n1385_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:468:20  */
  assign n1387_o = n1385_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:468:11  */
  assign n1389_o = n1387_o ? 4'b0110 : n1212_o;
  /* src/t400_decoder.vhd:468:11  */
  assign n1392_o = n1387_o ? 2'b10 : 2'b00;
  /* src/t400_decoder.vhd:468:11  */
  assign n1394_o = n1387_o ? 4'b0010 : n1217_o;
  /* src/t400_decoder.vhd:466:9  */
  assign n1396_o = mnemonic_q == 6'b001111;
  /* src/t400_decoder.vhd:476:45  */
  assign n1397_o = ibyte1_q[5:4];
  /* src/t400_decoder.vhd:477:20  */
  assign n1398_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:477:20  */
  assign n1400_o = n1398_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:477:11  */
  assign n1403_o = n1400_o ? 3'b101 : 3'b000;
  /* src/t400_decoder.vhd:477:11  */
  assign n1406_o = n1400_o ? 5'b00010 : 5'b00000;
  /* src/t400_decoder.vhd:475:9  */
  assign n1408_o = mnemonic_q == 6'b010000;
  /* src/t400_decoder.vhd:485:44  */
  assign n1409_o = ibyte2_q[5:0];
  /* src/t400_decoder.vhd:488:26  */
  assign n1410_o = ibyte2_q[7:6];
  /* src/t400_decoder.vhd:493:21  */
  assign n1412_o = cyc_cnt_q == 3'b001;
  /* src/t400_decoder.vhd:495:21  */
  assign n1414_o = cyc_cnt_q == 3'b010;
  assign n1415_o = {n1414_o, n1412_o};
  /* src/t400_decoder.vhd:492:19  */
  always @*
    case (n1415_o)
      2'b10: n1418_o = 3'b000;
      2'b01: n1418_o = 3'b100;
      default: n1418_o = 3'b000;
    endcase
  /* src/t400_decoder.vhd:492:19  */
  always @*
    case (n1415_o)
      2'b10: n1421_o = 5'b00010;
      2'b01: n1421_o = 5'b00000;
      default: n1421_o = 5'b00000;
    endcase
  /* src/t400_decoder.vhd:490:15  */
  assign n1423_o = n1410_o == 2'b00;
  /* src/t400_decoder.vhd:506:21  */
  assign n1425_o = cyc_cnt_q == 3'b001;
  /* src/t400_decoder.vhd:508:21  */
  assign n1427_o = cyc_cnt_q == 3'b010;
  assign n1428_o = {n1427_o, n1425_o};
  /* src/t400_decoder.vhd:505:19  */
  always @*
    case (n1428_o)
      2'b10: n1432_o = 3'b111;
      2'b01: n1432_o = 3'b100;
      default: n1432_o = 3'b000;
    endcase
  /* src/t400_decoder.vhd:505:19  */
  always @*
    case (n1428_o)
      2'b10: n1435_o = 5'b00010;
      2'b01: n1435_o = 5'b00000;
      default: n1435_o = 5'b00000;
    endcase
  /* src/t400_decoder.vhd:502:15  */
  assign n1437_o = n1410_o == 2'b10;
  assign n1438_o = {n1437_o, n1423_o};
  /* src/t400_decoder.vhd:488:13  */
  always @*
    case (n1438_o)
      2'b10: n1440_o = n1432_o;
      2'b01: n1440_o = n1418_o;
      default: n1440_o = 3'b000;
    endcase
  /* src/t400_decoder.vhd:488:13  */
  always @*
    case (n1438_o)
      2'b10: n1442_o = n1435_o;
      2'b01: n1442_o = n1421_o;
      default: n1442_o = 5'b00000;
    endcase
  /* src/t400_decoder.vhd:487:11  */
  assign n1444_o = second_cyc_q ? n1440_o : 3'b000;
  /* src/t400_decoder.vhd:487:11  */
  assign n1446_o = second_cyc_q ? n1442_o : 5'b00000;
  /* src/t400_decoder.vhd:483:9  */
  assign n1448_o = mnemonic_q == 6'b010001;
  /* src/t400_decoder.vhd:525:14  */
  assign n1449_o = ~second_cyc_q;
  /* src/t400_decoder.vhd:528:22  */
  assign n1450_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:528:22  */
  assign n1452_o = n1450_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:528:13  */
  assign n1454_o = n1452_o ? 4'b0111 : n1212_o;
  /* src/t400_decoder.vhd:528:13  */
  assign n1457_o = n1452_o ? 2'b01 : 2'b00;
  /* src/t400_decoder.vhd:533:13  */
  assign n1460_o = out_en_i ? 3'b010 : 3'b000;
  /* src/t400_decoder.vhd:537:22  */
  assign n1461_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:537:22  */
  assign n1463_o = n1461_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:537:13  */
  assign n1465_o = n1463_o ? 4'b0110 : n1212_o;
  /* src/t400_decoder.vhd:537:13  */
  assign n1468_o = n1463_o ? 2'b10 : 2'b00;
  /* src/t400_decoder.vhd:525:11  */
  assign n1469_o = n1449_o ? n1454_o : n1465_o;
  /* src/t400_decoder.vhd:525:11  */
  assign n1470_o = n1449_o ? n1457_o : n1468_o;
  /* src/t400_decoder.vhd:525:11  */
  assign n1472_o = n1449_o ? n1460_o : 3'b000;
  /* src/t400_decoder.vhd:544:28  */
  assign n1473_o = ~second_cyc_q;
  /* src/t400_decoder.vhd:544:24  */
  assign n1474_o = n1473_o & icyc_en_i;
  /* src/t400_decoder.vhd:544:11  */
  assign n1476_o = n1474_o ? 4'b0000 : n1469_o;
  /* src/t400_decoder.vhd:522:9  */
  assign n1478_o = mnemonic_q == 6'b010010;
  /* src/t400_decoder.vhd:551:20  */
  assign n1479_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:551:20  */
  assign n1481_o = n1479_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:554:26  */
  assign n1482_o = ibyte1_q[3:0];
  /* src/t400_decoder.vhd:555:15  */
  assign n1485_o = n1482_o == 4'b1100;
  /* src/t400_decoder.vhd:557:15  */
  assign n1488_o = n1482_o == 4'b0101;
  /* src/t400_decoder.vhd:559:15  */
  assign n1491_o = n1482_o == 4'b0010;
  /* src/t400_decoder.vhd:561:15  */
  assign n1494_o = n1482_o == 4'b0011;
  assign n1495_o = {n1494_o, n1491_o, n1488_o, n1485_o};
  /* src/t400_decoder.vhd:554:13  */
  always @*
    case (n1495_o)
      4'b1000: n1497_o = 4'b1000;
      4'b0100: n1497_o = 4'b0100;
      4'b0010: n1497_o = 4'b0010;
      4'b0001: n1497_o = 4'b0001;
      default: n1497_o = 4'b0000;
    endcase
  /* src/t400_decoder.vhd:551:11  */
  assign n1500_o = n1481_o ? 3'b110 : 3'b000;
  /* src/t400_decoder.vhd:551:11  */
  assign n1502_o = n1481_o ? n1497_o : 4'b0000;
  /* src/t400_decoder.vhd:550:9  */
  assign n1504_o = mnemonic_q == 6'b010011;
  /* src/t400_decoder.vhd:570:20  */
  assign n1505_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:570:20  */
  assign n1507_o = n1505_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:573:26  */
  assign n1508_o = ibyte1_q[3:0];
  /* src/t400_decoder.vhd:574:15  */
  assign n1511_o = n1508_o == 4'b1101;
  /* src/t400_decoder.vhd:576:15  */
  assign n1514_o = n1508_o == 4'b0111;
  /* src/t400_decoder.vhd:578:15  */
  assign n1517_o = n1508_o == 4'b0110;
  /* src/t400_decoder.vhd:580:15  */
  assign n1520_o = n1508_o == 4'b1011;
  assign n1521_o = {n1520_o, n1517_o, n1514_o, n1511_o};
  /* src/t400_decoder.vhd:573:13  */
  always @*
    case (n1521_o)
      4'b1000: n1523_o = 4'b1000;
      4'b0100: n1523_o = 4'b0100;
      4'b0010: n1523_o = 4'b0010;
      4'b0001: n1523_o = 4'b0001;
      default: n1523_o = 4'b0000;
    endcase
  /* src/t400_decoder.vhd:570:11  */
  assign n1526_o = n1507_o ? 3'b101 : 3'b000;
  /* src/t400_decoder.vhd:570:11  */
  assign n1528_o = n1507_o ? n1523_o : 4'b0000;
  /* src/t400_decoder.vhd:569:9  */
  assign n1530_o = mnemonic_q == 6'b010100;
  /* src/t400_decoder.vhd:589:45  */
  assign n1531_o = ibyte1_q[3:0];
  /* src/t400_decoder.vhd:590:20  */
  assign n1532_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:590:20  */
  assign n1534_o = n1532_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:590:11  */
  assign n1537_o = n1534_o ? 3'b010 : 3'b000;
  /* src/t400_decoder.vhd:590:11  */
  assign n1540_o = n1534_o ? 3'b110 : 3'b000;
  /* src/t400_decoder.vhd:588:9  */
  assign n1542_o = mnemonic_q == 6'b010101;
  /* src/t400_decoder.vhd:597:45  */
  assign n1543_o = ibyte1_q[5:4];
  /* src/t400_decoder.vhd:598:20  */
  assign n1544_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:598:20  */
  assign n1546_o = n1544_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:598:11  */
  assign n1549_o = n1546_o ? 3'b011 : 3'b000;
  /* src/t400_decoder.vhd:598:11  */
  assign n1552_o = n1546_o ? 3'b101 : 3'b000;
  /* src/t400_decoder.vhd:598:11  */
  assign n1555_o = n1546_o ? 5'b00010 : 5'b00000;
  /* src/t400_decoder.vhd:596:9  */
  assign n1557_o = mnemonic_q == 6'b010110;
  /* src/t400_decoder.vhd:606:45  */
  assign n1558_o = ibyte1_q[5:4];
  /* src/t400_decoder.vhd:608:13  */
  assign n1560_o = cyc_cnt_q == 3'b001;
  /* src/t400_decoder.vhd:612:13  */
  assign n1562_o = cyc_cnt_q == 3'b010;
  assign n1563_o = {n1562_o, n1560_o};
  /* src/t400_decoder.vhd:607:11  */
  always @*
    case (n1563_o)
      2'b10: n1566_o = 3'b000;
      2'b01: n1566_o = 3'b011;
      default: n1566_o = 3'b000;
    endcase
  /* src/t400_decoder.vhd:607:11  */
  always @*
    case (n1563_o)
      2'b10: n1570_o = 3'b101;
      2'b01: n1570_o = 3'b111;
      default: n1570_o = 3'b000;
    endcase
  /* src/t400_decoder.vhd:607:11  */
  always @*
    case (n1563_o)
      2'b10: n1572_o = 4'b0101;
      2'b01: n1572_o = n1217_o;
      default: n1572_o = n1217_o;
    endcase
  /* src/t400_decoder.vhd:607:11  */
  always @*
    case (n1563_o)
      2'b10: n1575_o = 5'b00000;
      2'b01: n1575_o = 5'b00010;
      default: n1575_o = 5'b00000;
    endcase
  /* src/t400_decoder.vhd:605:9  */
  assign n1577_o = mnemonic_q == 6'b010111;
  /* src/t400_decoder.vhd:621:45  */
  assign n1578_o = ibyte1_q[5:4];
  /* src/t400_decoder.vhd:623:13  */
  assign n1580_o = cyc_cnt_q == 3'b001;
  /* src/t400_decoder.vhd:627:13  */
  assign n1582_o = cyc_cnt_q == 3'b010;
  assign n1583_o = {n1582_o, n1580_o};
  /* src/t400_decoder.vhd:622:11  */
  always @*
    case (n1583_o)
      2'b10: n1586_o = 3'b000;
      2'b01: n1586_o = 3'b011;
      default: n1586_o = 3'b000;
    endcase
  /* src/t400_decoder.vhd:622:11  */
  always @*
    case (n1583_o)
      2'b10: n1590_o = 3'b101;
      2'b01: n1590_o = 3'b110;
      default: n1590_o = 3'b000;
    endcase
  /* src/t400_decoder.vhd:622:11  */
  always @*
    case (n1583_o)
      2'b10: n1592_o = 4'b0110;
      2'b01: n1592_o = n1217_o;
      default: n1592_o = n1217_o;
    endcase
  /* src/t400_decoder.vhd:622:11  */
  always @*
    case (n1583_o)
      2'b10: n1595_o = 5'b00000;
      2'b01: n1595_o = 5'b00010;
      default: n1595_o = 5'b00000;
    endcase
  /* src/t400_decoder.vhd:620:9  */
  assign n1597_o = mnemonic_q == 6'b011000;
  /* src/t400_decoder.vhd:636:20  */
  assign n1598_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:636:20  */
  assign n1600_o = n1598_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:636:11  */
  assign n1603_o = n1600_o ? 3'b001 : 3'b000;
  /* src/t400_decoder.vhd:635:9  */
  assign n1605_o = mnemonic_q == 6'b011001;
  /* src/t400_decoder.vhd:642:20  */
  assign n1606_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:642:20  */
  assign n1608_o = n1606_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:642:11  */
  assign n1611_o = n1608_o ? 5'b01000 : 5'b00000;
  /* src/t400_decoder.vhd:641:9  */
  assign n1613_o = mnemonic_q == 6'b011010;
  /* src/t400_decoder.vhd:650:45  */
  assign n1614_o = ibyte1_q[5:4];
  /* src/t400_decoder.vhd:651:45  */
  assign n1615_o = ibyte1_q[3:0];
  /* src/t400_decoder.vhd:652:20  */
  assign n1616_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:652:20  */
  assign n1618_o = n1616_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:652:28  */
  assign n1619_o = ~skip_lbi_i;
  /* src/t400_decoder.vhd:652:24  */
  assign n1620_o = n1619_o & n1618_o;
  /* src/t400_decoder.vhd:652:11  */
  assign n1623_o = n1620_o ? 3'b100 : 3'b000;
  /* src/t400_decoder.vhd:652:11  */
  assign n1625_o = n1620_o ? 4'b0111 : n1217_o;
  /* src/t400_decoder.vhd:647:9  */
  assign n1627_o = mnemonic_q == 6'b011011;
  /* src/t400_decoder.vhd:660:20  */
  assign n1628_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:660:20  */
  assign n1630_o = n1628_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:660:11  */
  assign n1633_o = n1630_o ? 3'b010 : 3'b000;
  /* src/t400_decoder.vhd:660:11  */
  assign n1636_o = n1630_o ? 5'b00111 : 5'b00000;
  /* src/t400_decoder.vhd:659:9  */
  assign n1638_o = mnemonic_q == 6'b011100;
  /* src/t400_decoder.vhd:667:20  */
  assign n1639_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:667:20  */
  assign n1641_o = n1639_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:667:11  */
  assign n1643_o = n1641_o ? 4'b0100 : n1217_o;
  /* src/t400_decoder.vhd:666:9  */
  assign n1645_o = mnemonic_q == 6'b011101;
  /* src/t400_decoder.vhd:673:20  */
  assign n1646_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:673:20  */
  assign n1648_o = n1646_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:673:11  */
  assign n1650_o = n1648_o ? 4'b1000 : n1217_o;
  /* src/t400_decoder.vhd:672:9  */
  assign n1652_o = mnemonic_q == 6'b011110;
  /* src/t400_decoder.vhd:679:20  */
  assign n1653_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:679:20  */
  assign n1655_o = n1653_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:683:15  */
  assign n1658_o = ibyte1_q == 8'b00000001;
  /* src/t400_decoder.vhd:685:15  */
  assign n1661_o = ibyte1_q == 8'b00010001;
  /* src/t400_decoder.vhd:687:15  */
  assign n1664_o = ibyte1_q == 8'b00000011;
  /* src/t400_decoder.vhd:689:15  */
  assign n1667_o = ibyte1_q == 8'b00010011;
  assign n1668_o = {n1667_o, n1664_o, n1661_o, n1658_o};
  /* src/t400_decoder.vhd:682:13  */
  always @*
    case (n1668_o)
      4'b1000: n1670_o = 4'b1000;
      4'b0100: n1670_o = 4'b0100;
      4'b0010: n1670_o = 4'b0010;
      4'b0001: n1670_o = 4'b0001;
      default: n1670_o = 4'b0000;
    endcase
  /* src/t400_decoder.vhd:679:11  */
  assign n1672_o = n1655_o ? 4'b1011 : n1217_o;
  /* src/t400_decoder.vhd:679:11  */
  assign n1674_o = n1655_o ? n1670_o : 4'b0000;
  /* src/t400_decoder.vhd:678:9  */
  assign n1676_o = mnemonic_q == 6'b011111;
  /* src/t400_decoder.vhd:698:20  */
  assign n1677_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:698:20  */
  assign n1679_o = n1677_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:698:11  */
  assign n1681_o = n1679_o ? 4'b1100 : n1217_o;
  /* src/t400_decoder.vhd:697:9  */
  assign n1683_o = mnemonic_q == 6'b100000;
  /* src/t400_decoder.vhd:704:11  */
  assign n1686_o = out_en_i ? 5'b01001 : 5'b00000;
  /* src/t400_decoder.vhd:704:11  */
  assign n1689_o = out_en_i ? 1'b1 : 1'b0;
  /* src/t400_decoder.vhd:703:9  */
  assign n1691_o = mnemonic_q == 6'b100010;
  /* src/t400_decoder.vhd:715:17  */
  assign n1694_o = out_en_i ? 3'b001 : 3'b000;
  /* src/t400_decoder.vhd:714:15  */
  assign n1696_o = ibyte2_q == 8'b00111100;
  /* src/t400_decoder.vhd:720:36  */
  assign n1698_o = in_en_i & 1'b1;
  /* src/t400_decoder.vhd:720:17  */
  assign n1701_o = n1698_o ? 3'b001 : 3'b000;
  /* src/t400_decoder.vhd:720:17  */
  assign n1704_o = n1698_o ? 5'b00011 : 5'b00000;
  /* src/t400_decoder.vhd:720:17  */
  assign n1707_o = n1698_o ? 3'b100 : 3'b000;
  /* src/t400_decoder.vhd:719:15  */
  assign n1709_o = ibyte2_q == 8'b00101100;
  /* src/t400_decoder.vhd:727:17  */
  assign n1711_o = in_en_i ? 4'b1001 : n1217_o;
  /* src/t400_decoder.vhd:726:15  */
  assign n1713_o = ibyte2_q == 8'b00100001;
  /* src/t400_decoder.vhd:732:17  */
  assign n1716_o = in_en_i ? 4'b1010 : n1217_o;
  /* src/t400_decoder.vhd:732:17  */
  assign n1718_o = in_en_i ? 4'b0001 : 4'b0000;
  /* src/t400_decoder.vhd:731:15  */
  assign n1720_o = ibyte2_q == 8'b00000001;
  /* src/t400_decoder.vhd:737:17  */
  assign n1723_o = in_en_i ? 4'b1010 : n1217_o;
  /* src/t400_decoder.vhd:737:17  */
  assign n1725_o = in_en_i ? 4'b0010 : 4'b0000;
  /* src/t400_decoder.vhd:736:15  */
  assign n1727_o = ibyte2_q == 8'b00010001;
  /* src/t400_decoder.vhd:742:17  */
  assign n1730_o = in_en_i ? 4'b1010 : n1217_o;
  /* src/t400_decoder.vhd:742:17  */
  assign n1732_o = in_en_i ? 4'b0100 : 4'b0000;
  /* src/t400_decoder.vhd:741:15  */
  assign n1734_o = ibyte2_q == 8'b00000011;
  /* src/t400_decoder.vhd:747:17  */
  assign n1737_o = in_en_i ? 4'b1010 : n1217_o;
  /* src/t400_decoder.vhd:747:17  */
  assign n1739_o = in_en_i ? 4'b1000 : 4'b0000;
  /* src/t400_decoder.vhd:746:15  */
  assign n1741_o = ibyte2_q == 8'b00010011;
  /* src/t400_decoder.vhd:753:26  */
  assign n1742_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:753:26  */
  assign n1744_o = n1742_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:753:17  */
  assign n1747_o = n1744_o ? 5'b00100 : 5'b00000;
  /* src/t400_decoder.vhd:752:15  */
  assign n1749_o = ibyte2_q == 8'b00101010;
  /* src/t400_decoder.vhd:758:17  */
  assign n1752_o = in_en_i ? 3'b001 : 3'b000;
  /* src/t400_decoder.vhd:758:17  */
  assign n1755_o = in_en_i ? 5'b00011 : 5'b00000;
  /* src/t400_decoder.vhd:758:17  */
  assign n1758_o = in_en_i ? 3'b011 : 3'b000;
  /* src/t400_decoder.vhd:757:15  */
  assign n1760_o = ibyte2_q == 8'b00101110;
  /* src/t400_decoder.vhd:765:36  */
  assign n1762_o = in_en_i & 1'b1;
  /* src/t400_decoder.vhd:765:17  */
  assign n1765_o = n1762_o ? 5'b00101 : 5'b00000;
  /* src/t400_decoder.vhd:764:15  */
  assign n1767_o = ibyte2_q == 8'b00101000;
  /* src/t400_decoder.vhd:770:36  */
  assign n1769_o = in_en_i & 1'b1;
  /* src/t400_decoder.vhd:770:17  */
  assign n1772_o = n1769_o ? 5'b00110 : 5'b00000;
  /* src/t400_decoder.vhd:770:17  */
  assign n1775_o = n1769_o ? 2'b01 : 2'b00;
  /* src/t400_decoder.vhd:769:15  */
  assign n1777_o = ibyte2_q == 8'b00101001;
  /* src/t400_decoder.vhd:776:17  */
  assign n1780_o = out_en_i ? 1'b1 : 1'b0;
  /* src/t400_decoder.vhd:775:15  */
  assign n1782_o = ibyte2_q == 8'b00111110;
  /* src/t400_decoder.vhd:781:17  */
  assign n1785_o = out_en_i ? 2'b01 : 2'b00;
  /* src/t400_decoder.vhd:780:15  */
  assign n1787_o = ibyte2_q == 8'b00111010;
  /* src/t400_decoder.vhd:787:50  */
  assign n1788_o = ibyte2_q[5:0];
  /* src/t400_decoder.vhd:789:28  */
  assign n1789_o = ibyte2_q[7:6];
  /* src/t400_decoder.vhd:789:41  */
  assign n1791_o = n1789_o == 2'b10;
  /* src/t400_decoder.vhd:789:48  */
  assign n1793_o = 1'b1 & n1791_o;
  /* src/t400_decoder.vhd:792:28  */
  assign n1794_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:792:28  */
  assign n1796_o = $signed(n1794_o) > $signed(32'b00000000000000000000000000000000);
  /* src/t400_decoder.vhd:792:36  */
  assign n1797_o = ~skip_lbi_i;
  /* src/t400_decoder.vhd:792:32  */
  assign n1798_o = n1797_o & n1796_o;
  /* src/t400_decoder.vhd:792:19  */
  assign n1801_o = n1798_o ? 3'b011 : 3'b000;
  /* src/t400_decoder.vhd:789:17  */
  assign n1803_o = n1806_o ? 4'b0111 : n1217_o;
  /* src/t400_decoder.vhd:789:17  */
  assign n1805_o = n1793_o ? n1801_o : 3'b000;
  /* src/t400_decoder.vhd:789:17  */
  assign n1806_o = n1798_o & n1793_o;
  /* src/t400_decoder.vhd:789:17  */
  assign n1809_o = n1793_o ? 1'b1 : 1'b0;
  /* src/t400_decoder.vhd:789:17  */
  assign n1812_o = n1793_o ? 1'b0 : 1'b1;
  /* src/t400_decoder.vhd:798:28  */
  assign n1813_o = ibyte2_q[7:4];
  /* src/t400_decoder.vhd:798:41  */
  assign n1815_o = n1813_o == 4'b0110;
  /* src/t400_decoder.vhd:798:50  */
  assign n1816_o = in_en_i & n1815_o;
  /* src/t400_decoder.vhd:805:26  */
  assign n1817_o = en_q[1];
  /* src/t400_decoder.vhd:805:30  */
  assign n1818_o = ~n1817_o;
  /* src/t400_decoder.vhd:805:19  */
  assign n1821_o = n1818_o ? 2'b10 : 2'b00;
  /* src/t400_decoder.vhd:798:17  */
  assign n1823_o = n1816_o ? n1821_o : 2'b00;
  /* src/t400_decoder.vhd:798:17  */
  assign n1826_o = n1816_o ? 1'b1 : 1'b0;
  /* src/t400_decoder.vhd:810:28  */
  assign n1827_o = ibyte2_q[7:4];
  /* src/t400_decoder.vhd:810:41  */
  assign n1829_o = n1827_o == 4'b0101;
  /* src/t400_decoder.vhd:810:50  */
  assign n1830_o = out_en_i & n1829_o;
  /* src/t400_decoder.vhd:810:63  */
  assign n1832_o = 1'b1 & n1830_o;
  /* src/t400_decoder.vhd:810:17  */
  assign n1835_o = n1832_o ? 2'b10 : 2'b00;
  assign n1836_o = {n1787_o, n1782_o, n1777_o, n1767_o, n1760_o, n1749_o, n1741_o, n1734_o, n1727_o, n1720_o, n1713_o, n1709_o, n1696_o};
  /* src/t400_decoder.vhd:712:13  */
  always @*
    case (n1836_o)
      13'b1000000000000: n1838_o = 3'b000;
      13'b0100000000000: n1838_o = 3'b000;
      13'b0010000000000: n1838_o = 3'b000;
      13'b0001000000000: n1838_o = 3'b000;
      13'b0000100000000: n1838_o = n1752_o;
      13'b0000010000000: n1838_o = 3'b000;
      13'b0000001000000: n1838_o = 3'b000;
      13'b0000000100000: n1838_o = 3'b000;
      13'b0000000010000: n1838_o = 3'b000;
      13'b0000000001000: n1838_o = 3'b000;
      13'b0000000000100: n1838_o = 3'b000;
      13'b0000000000010: n1838_o = n1701_o;
      13'b0000000000001: n1838_o = 3'b000;
      default: n1838_o = 3'b000;
    endcase
  /* src/t400_decoder.vhd:712:13  */
  always @*
    case (n1836_o)
      13'b1000000000000: n1840_o = 3'b000;
      13'b0100000000000: n1840_o = 3'b000;
      13'b0010000000000: n1840_o = 3'b000;
      13'b0001000000000: n1840_o = 3'b000;
      13'b0000100000000: n1840_o = 3'b000;
      13'b0000010000000: n1840_o = 3'b000;
      13'b0000001000000: n1840_o = 3'b000;
      13'b0000000100000: n1840_o = 3'b000;
      13'b0000000010000: n1840_o = 3'b000;
      13'b0000000001000: n1840_o = 3'b000;
      13'b0000000000100: n1840_o = 3'b000;
      13'b0000000000010: n1840_o = 3'b000;
      13'b0000000000001: n1840_o = 3'b000;
      default: n1840_o = n1805_o;
    endcase
  /* src/t400_decoder.vhd:712:13  */
  always @*
    case (n1836_o)
      13'b1000000000000: n1841_o = n1217_o;
      13'b0100000000000: n1841_o = n1217_o;
      13'b0010000000000: n1841_o = n1217_o;
      13'b0001000000000: n1841_o = n1217_o;
      13'b0000100000000: n1841_o = n1217_o;
      13'b0000010000000: n1841_o = n1217_o;
      13'b0000001000000: n1841_o = n1737_o;
      13'b0000000100000: n1841_o = n1730_o;
      13'b0000000010000: n1841_o = n1723_o;
      13'b0000000001000: n1841_o = n1716_o;
      13'b0000000000100: n1841_o = n1711_o;
      13'b0000000000010: n1841_o = n1217_o;
      13'b0000000000001: n1841_o = n1217_o;
      default: n1841_o = n1803_o;
    endcase
  /* src/t400_decoder.vhd:712:13  */
  always @*
    case (n1836_o)
      13'b1000000000000: n1843_o = 5'b00000;
      13'b0100000000000: n1843_o = 5'b00000;
      13'b0010000000000: n1843_o = n1772_o;
      13'b0001000000000: n1843_o = n1765_o;
      13'b0000100000000: n1843_o = n1755_o;
      13'b0000010000000: n1843_o = n1747_o;
      13'b0000001000000: n1843_o = 5'b00000;
      13'b0000000100000: n1843_o = 5'b00000;
      13'b0000000010000: n1843_o = 5'b00000;
      13'b0000000001000: n1843_o = 5'b00000;
      13'b0000000000100: n1843_o = 5'b00000;
      13'b0000000000010: n1843_o = n1704_o;
      13'b0000000000001: n1843_o = 5'b00000;
      default: n1843_o = 5'b00000;
    endcase
  /* src/t400_decoder.vhd:712:13  */
  always @*
    case (n1836_o)
      13'b1000000000000: n1845_o = 3'b000;
      13'b0100000000000: n1845_o = 3'b000;
      13'b0010000000000: n1845_o = 3'b000;
      13'b0001000000000: n1845_o = 3'b000;
      13'b0000100000000: n1845_o = n1758_o;
      13'b0000010000000: n1845_o = 3'b000;
      13'b0000001000000: n1845_o = 3'b000;
      13'b0000000100000: n1845_o = 3'b000;
      13'b0000000010000: n1845_o = 3'b000;
      13'b0000000001000: n1845_o = 3'b000;
      13'b0000000000100: n1845_o = 3'b000;
      13'b0000000000010: n1845_o = n1707_o;
      13'b0000000000001: n1845_o = n1694_o;
      default: n1845_o = 3'b000;
    endcase
  /* src/t400_decoder.vhd:712:13  */
  always @*
    case (n1836_o)
      13'b1000000000000: n1847_o = 1'b0;
      13'b0100000000000: n1847_o = n1780_o;
      13'b0010000000000: n1847_o = 1'b0;
      13'b0001000000000: n1847_o = 1'b0;
      13'b0000100000000: n1847_o = 1'b0;
      13'b0000010000000: n1847_o = 1'b0;
      13'b0000001000000: n1847_o = 1'b0;
      13'b0000000100000: n1847_o = 1'b0;
      13'b0000000010000: n1847_o = 1'b0;
      13'b0000000001000: n1847_o = 1'b0;
      13'b0000000000100: n1847_o = 1'b0;
      13'b0000000000010: n1847_o = 1'b0;
      13'b0000000000001: n1847_o = 1'b0;
      default: n1847_o = 1'b0;
    endcase
  /* src/t400_decoder.vhd:712:13  */
  always @*
    case (n1836_o)
      13'b1000000000000: n1849_o = n1785_o;
      13'b0100000000000: n1849_o = 2'b00;
      13'b0010000000000: n1849_o = 2'b00;
      13'b0001000000000: n1849_o = 2'b00;
      13'b0000100000000: n1849_o = 2'b00;
      13'b0000010000000: n1849_o = 2'b00;
      13'b0000001000000: n1849_o = 2'b00;
      13'b0000000100000: n1849_o = 2'b00;
      13'b0000000010000: n1849_o = 2'b00;
      13'b0000000001000: n1849_o = 2'b00;
      13'b0000000000100: n1849_o = 2'b00;
      13'b0000000000010: n1849_o = 2'b00;
      13'b0000000000001: n1849_o = 2'b00;
      default: n1849_o = n1835_o;
    endcase
  /* src/t400_decoder.vhd:712:13  */
  always @*
    case (n1836_o)
      13'b1000000000000: n1851_o = 2'b00;
      13'b0100000000000: n1851_o = 2'b00;
      13'b0010000000000: n1851_o = n1775_o;
      13'b0001000000000: n1851_o = 2'b00;
      13'b0000100000000: n1851_o = 2'b00;
      13'b0000010000000: n1851_o = 2'b00;
      13'b0000001000000: n1851_o = 2'b00;
      13'b0000000100000: n1851_o = 2'b00;
      13'b0000000010000: n1851_o = 2'b00;
      13'b0000000001000: n1851_o = 2'b00;
      13'b0000000000100: n1851_o = 2'b00;
      13'b0000000000010: n1851_o = 2'b00;
      13'b0000000000001: n1851_o = 2'b00;
      default: n1851_o = n1823_o;
    endcase
  assign n1852_o = n1788_o[3:0];
  /* src/t400_decoder.vhd:712:13  */
  always @*
    case (n1836_o)
      13'b1000000000000: n1854_o = 4'b0000;
      13'b0100000000000: n1854_o = 4'b0000;
      13'b0010000000000: n1854_o = 4'b0000;
      13'b0001000000000: n1854_o = 4'b0000;
      13'b0000100000000: n1854_o = 4'b0000;
      13'b0000010000000: n1854_o = 4'b0000;
      13'b0000001000000: n1854_o = n1739_o;
      13'b0000000100000: n1854_o = n1732_o;
      13'b0000000010000: n1854_o = n1725_o;
      13'b0000000001000: n1854_o = n1718_o;
      13'b0000000000100: n1854_o = 4'b0000;
      13'b0000000000010: n1854_o = 4'b0000;
      13'b0000000000001: n1854_o = 4'b0000;
      default: n1854_o = n1852_o;
    endcase
  assign n1855_o = n1788_o[5:4];
  /* src/t400_decoder.vhd:712:13  */
  always @*
    case (n1836_o)
      13'b1000000000000: n1857_o = 2'b00;
      13'b0100000000000: n1857_o = 2'b00;
      13'b0010000000000: n1857_o = 2'b00;
      13'b0001000000000: n1857_o = 2'b00;
      13'b0000100000000: n1857_o = 2'b00;
      13'b0000010000000: n1857_o = 2'b00;
      13'b0000001000000: n1857_o = 2'b00;
      13'b0000000100000: n1857_o = 2'b00;
      13'b0000000010000: n1857_o = 2'b00;
      13'b0000000001000: n1857_o = 2'b00;
      13'b0000000000100: n1857_o = 2'b00;
      13'b0000000000010: n1857_o = 2'b00;
      13'b0000000000001: n1857_o = 2'b00;
      default: n1857_o = n1855_o;
    endcase
  /* src/t400_decoder.vhd:712:13  */
  always @*
    case (n1836_o)
      13'b1000000000000: n1859_o = 1'b0;
      13'b0100000000000: n1859_o = 1'b0;
      13'b0010000000000: n1859_o = 1'b0;
      13'b0001000000000: n1859_o = 1'b0;
      13'b0000100000000: n1859_o = 1'b0;
      13'b0000010000000: n1859_o = 1'b0;
      13'b0000001000000: n1859_o = 1'b0;
      13'b0000000100000: n1859_o = 1'b0;
      13'b0000000010000: n1859_o = 1'b0;
      13'b0000000001000: n1859_o = 1'b0;
      13'b0000000000100: n1859_o = 1'b0;
      13'b0000000000010: n1859_o = 1'b0;
      13'b0000000000001: n1859_o = 1'b0;
      default: n1859_o = n1809_o;
    endcase
  /* src/t400_decoder.vhd:712:13  */
  always @*
    case (n1836_o)
      13'b1000000000000: n1861_o = 1'b0;
      13'b0100000000000: n1861_o = 1'b0;
      13'b0010000000000: n1861_o = 1'b0;
      13'b0001000000000: n1861_o = 1'b0;
      13'b0000100000000: n1861_o = 1'b0;
      13'b0000010000000: n1861_o = 1'b0;
      13'b0000001000000: n1861_o = 1'b0;
      13'b0000000100000: n1861_o = 1'b0;
      13'b0000000010000: n1861_o = 1'b0;
      13'b0000000001000: n1861_o = 1'b0;
      13'b0000000000100: n1861_o = 1'b0;
      13'b0000000000010: n1861_o = 1'b0;
      13'b0000000000001: n1861_o = 1'b0;
      default: n1861_o = n1826_o;
    endcase
  /* src/t400_decoder.vhd:712:13  */
  always @*
    case (n1836_o)
      13'b1000000000000: n1863_o = 1'b1;
      13'b0100000000000: n1863_o = 1'b1;
      13'b0010000000000: n1863_o = 1'b1;
      13'b0001000000000: n1863_o = 1'b1;
      13'b0000100000000: n1863_o = 1'b1;
      13'b0000010000000: n1863_o = 1'b1;
      13'b0000001000000: n1863_o = 1'b1;
      13'b0000000100000: n1863_o = 1'b1;
      13'b0000000010000: n1863_o = 1'b1;
      13'b0000000001000: n1863_o = 1'b1;
      13'b0000000000100: n1863_o = 1'b1;
      13'b0000000000010: n1863_o = 1'b1;
      13'b0000000000001: n1863_o = 1'b1;
      default: n1863_o = n1812_o;
    endcase
  /* src/t400_decoder.vhd:711:11  */
  assign n1865_o = second_cyc_q ? n1838_o : 3'b000;
  /* src/t400_decoder.vhd:711:11  */
  assign n1867_o = second_cyc_q ? n1840_o : 3'b000;
  /* src/t400_decoder.vhd:711:11  */
  assign n1868_o = second_cyc_q ? n1841_o : n1217_o;
  /* src/t400_decoder.vhd:711:11  */
  assign n1870_o = second_cyc_q ? n1843_o : 5'b00000;
  /* src/t400_decoder.vhd:711:11  */
  assign n1872_o = second_cyc_q ? n1845_o : 3'b000;
  /* src/t400_decoder.vhd:711:11  */
  assign n1874_o = second_cyc_q ? n1847_o : 1'b0;
  /* src/t400_decoder.vhd:711:11  */
  assign n1876_o = second_cyc_q ? n1849_o : 2'b00;
  /* src/t400_decoder.vhd:711:11  */
  assign n1878_o = second_cyc_q ? n1851_o : 2'b00;
  assign n1879_o = {n1857_o, n1854_o};
  /* src/t400_decoder.vhd:711:11  */
  assign n1881_o = second_cyc_q ? n1879_o : 6'b000000;
  /* src/t400_decoder.vhd:711:11  */
  assign n1883_o = second_cyc_q ? n1859_o : 1'b0;
  /* src/t400_decoder.vhd:711:11  */
  assign n1885_o = second_cyc_q ? n1861_o : 1'b0;
  /* src/t400_decoder.vhd:711:11  */
  assign n1887_o = second_cyc_q ? n1863_o : 1'b1;
  /* src/t400_decoder.vhd:710:9  */
  assign n1889_o = mnemonic_q == 6'b100001;
  assign n1890_o = {n1889_o, n1691_o, n1683_o, n1676_o, n1652_o, n1645_o, n1638_o, n1627_o, n1613_o, n1605_o, n1597_o, n1577_o, n1557_o, n1542_o, n1530_o, n1504_o, n1478_o, n1448_o, n1408_o, n1396_o, n1384_o, n1372_o, n1357_o, n1332_o, n1320_o, n1306_o, n1298_o, n1287_o, n1285_o, n1277_o, n1269_o, n1256_o, n1245_o, n1237_o, n1229_o};
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1891_o = n1212_o;
      35'b01000000000000000000000000000000000: n1891_o = n1212_o;
      35'b00100000000000000000000000000000000: n1891_o = n1212_o;
      35'b00010000000000000000000000000000000: n1891_o = n1212_o;
      35'b00001000000000000000000000000000000: n1891_o = n1212_o;
      35'b00000100000000000000000000000000000: n1891_o = n1212_o;
      35'b00000010000000000000000000000000000: n1891_o = n1212_o;
      35'b00000001000000000000000000000000000: n1891_o = n1212_o;
      35'b00000000100000000000000000000000000: n1891_o = n1212_o;
      35'b00000000010000000000000000000000000: n1891_o = n1212_o;
      35'b00000000001000000000000000000000000: n1891_o = n1212_o;
      35'b00000000000100000000000000000000000: n1891_o = n1212_o;
      35'b00000000000010000000000000000000000: n1891_o = n1212_o;
      35'b00000000000001000000000000000000000: n1891_o = n1212_o;
      35'b00000000000000100000000000000000000: n1891_o = n1212_o;
      35'b00000000000000010000000000000000000: n1891_o = n1212_o;
      35'b00000000000000001000000000000000000: n1891_o = n1476_o;
      35'b00000000000000000100000000000000000: n1891_o = n1212_o;
      35'b00000000000000000010000000000000000: n1891_o = n1212_o;
      35'b00000000000000000001000000000000000: n1891_o = n1389_o;
      35'b00000000000000000000100000000000000: n1891_o = n1377_o;
      35'b00000000000000000000010000000000000: n1891_o = n1367_o;
      35'b00000000000000000000001000000000000: n1891_o = n1353_o;
      35'b00000000000000000000000100000000000: n1891_o = n1330_o;
      35'b00000000000000000000000010000000000: n1891_o = n1318_o;
      35'b00000000000000000000000001000000000: n1891_o = n1212_o;
      35'b00000000000000000000000000100000000: n1891_o = n1212_o;
      35'b00000000000000000000000000010000000: n1891_o = n1212_o;
      35'b00000000000000000000000000001000000: n1891_o = n1212_o;
      35'b00000000000000000000000000000100000: n1891_o = n1212_o;
      35'b00000000000000000000000000000010000: n1891_o = n1212_o;
      35'b00000000000000000000000000000001000: n1891_o = n1212_o;
      35'b00000000000000000000000000000000100: n1891_o = n1212_o;
      35'b00000000000000000000000000000000010: n1891_o = n1212_o;
      35'b00000000000000000000000000000000001: n1891_o = n1212_o;
      default: n1891_o = n1212_o;
    endcase
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1893_o = 2'b00;
      35'b01000000000000000000000000000000000: n1893_o = 2'b00;
      35'b00100000000000000000000000000000000: n1893_o = 2'b00;
      35'b00010000000000000000000000000000000: n1893_o = 2'b00;
      35'b00001000000000000000000000000000000: n1893_o = 2'b00;
      35'b00000100000000000000000000000000000: n1893_o = 2'b00;
      35'b00000010000000000000000000000000000: n1893_o = 2'b00;
      35'b00000001000000000000000000000000000: n1893_o = 2'b00;
      35'b00000000100000000000000000000000000: n1893_o = 2'b00;
      35'b00000000010000000000000000000000000: n1893_o = 2'b00;
      35'b00000000001000000000000000000000000: n1893_o = 2'b00;
      35'b00000000000100000000000000000000000: n1893_o = 2'b00;
      35'b00000000000010000000000000000000000: n1893_o = 2'b00;
      35'b00000000000001000000000000000000000: n1893_o = 2'b00;
      35'b00000000000000100000000000000000000: n1893_o = 2'b00;
      35'b00000000000000010000000000000000000: n1893_o = 2'b00;
      35'b00000000000000001000000000000000000: n1893_o = n1470_o;
      35'b00000000000000000100000000000000000: n1893_o = 2'b00;
      35'b00000000000000000010000000000000000: n1893_o = 2'b00;
      35'b00000000000000000001000000000000000: n1893_o = n1392_o;
      35'b00000000000000000000100000000000000: n1893_o = n1380_o;
      35'b00000000000000000000010000000000000: n1893_o = n1370_o;
      35'b00000000000000000000001000000000000: n1893_o = n1355_o;
      35'b00000000000000000000000100000000000: n1893_o = 2'b00;
      35'b00000000000000000000000010000000000: n1893_o = 2'b00;
      35'b00000000000000000000000001000000000: n1893_o = 2'b00;
      35'b00000000000000000000000000100000000: n1893_o = 2'b00;
      35'b00000000000000000000000000010000000: n1893_o = 2'b00;
      35'b00000000000000000000000000001000000: n1893_o = 2'b00;
      35'b00000000000000000000000000000100000: n1893_o = 2'b00;
      35'b00000000000000000000000000000010000: n1893_o = 2'b00;
      35'b00000000000000000000000000000001000: n1893_o = 2'b00;
      35'b00000000000000000000000000000000100: n1893_o = 2'b00;
      35'b00000000000000000000000000000000010: n1893_o = 2'b00;
      35'b00000000000000000000000000000000001: n1893_o = 2'b00;
      default: n1893_o = 2'b00;
    endcase
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1895_o = n1865_o;
      35'b01000000000000000000000000000000000: n1895_o = 3'b000;
      35'b00100000000000000000000000000000000: n1895_o = 3'b000;
      35'b00010000000000000000000000000000000: n1895_o = 3'b000;
      35'b00001000000000000000000000000000000: n1895_o = 3'b000;
      35'b00000100000000000000000000000000000: n1895_o = 3'b000;
      35'b00000010000000000000000000000000000: n1895_o = 3'b000;
      35'b00000001000000000000000000000000000: n1895_o = 3'b000;
      35'b00000000100000000000000000000000000: n1895_o = 3'b000;
      35'b00000000010000000000000000000000000: n1895_o = 3'b000;
      35'b00000000001000000000000000000000000: n1895_o = n1586_o;
      35'b00000000000100000000000000000000000: n1895_o = n1566_o;
      35'b00000000000010000000000000000000000: n1895_o = n1549_o;
      35'b00000000000001000000000000000000000: n1895_o = n1537_o;
      35'b00000000000000100000000000000000000: n1895_o = n1526_o;
      35'b00000000000000010000000000000000000: n1895_o = n1500_o;
      35'b00000000000000001000000000000000000: n1895_o = 3'b000;
      35'b00000000000000000100000000000000000: n1895_o = n1444_o;
      35'b00000000000000000010000000000000000: n1895_o = 3'b000;
      35'b00000000000000000001000000000000000: n1895_o = 3'b000;
      35'b00000000000000000000100000000000000: n1895_o = 3'b000;
      35'b00000000000000000000010000000000000: n1895_o = 3'b000;
      35'b00000000000000000000001000000000000: n1895_o = 3'b000;
      35'b00000000000000000000000100000000000: n1895_o = 3'b000;
      35'b00000000000000000000000010000000000: n1895_o = 3'b000;
      35'b00000000000000000000000001000000000: n1895_o = 3'b000;
      35'b00000000000000000000000000100000000: n1895_o = 3'b000;
      35'b00000000000000000000000000010000000: n1895_o = 3'b000;
      35'b00000000000000000000000000001000000: n1895_o = 3'b000;
      35'b00000000000000000000000000000100000: n1895_o = 3'b000;
      35'b00000000000000000000000000000010000: n1895_o = 3'b000;
      35'b00000000000000000000000000000001000: n1895_o = 3'b000;
      35'b00000000000000000000000000000000100: n1895_o = 3'b000;
      35'b00000000000000000000000000000000010: n1895_o = 3'b000;
      35'b00000000000000000000000000000000001: n1895_o = 3'b000;
      default: n1895_o = 3'b000;
    endcase
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1897_o = n1867_o;
      35'b01000000000000000000000000000000000: n1897_o = 3'b000;
      35'b00100000000000000000000000000000000: n1897_o = 3'b000;
      35'b00010000000000000000000000000000000: n1897_o = 3'b000;
      35'b00001000000000000000000000000000000: n1897_o = 3'b000;
      35'b00000100000000000000000000000000000: n1897_o = 3'b000;
      35'b00000010000000000000000000000000000: n1897_o = n1633_o;
      35'b00000001000000000000000000000000000: n1897_o = n1623_o;
      35'b00000000100000000000000000000000000: n1897_o = 3'b000;
      35'b00000000010000000000000000000000000: n1897_o = n1603_o;
      35'b00000000001000000000000000000000000: n1897_o = n1590_o;
      35'b00000000000100000000000000000000000: n1897_o = n1570_o;
      35'b00000000000010000000000000000000000: n1897_o = n1552_o;
      35'b00000000000001000000000000000000000: n1897_o = n1540_o;
      35'b00000000000000100000000000000000000: n1897_o = 3'b000;
      35'b00000000000000010000000000000000000: n1897_o = 3'b000;
      35'b00000000000000001000000000000000000: n1897_o = 3'b000;
      35'b00000000000000000100000000000000000: n1897_o = 3'b000;
      35'b00000000000000000010000000000000000: n1897_o = n1403_o;
      35'b00000000000000000001000000000000000: n1897_o = 3'b000;
      35'b00000000000000000000100000000000000: n1897_o = 3'b000;
      35'b00000000000000000000010000000000000: n1897_o = 3'b000;
      35'b00000000000000000000001000000000000: n1897_o = 3'b000;
      35'b00000000000000000000000100000000000: n1897_o = 3'b000;
      35'b00000000000000000000000010000000000: n1897_o = 3'b000;
      35'b00000000000000000000000001000000000: n1897_o = 3'b000;
      35'b00000000000000000000000000100000000: n1897_o = 3'b000;
      35'b00000000000000000000000000010000000: n1897_o = 3'b000;
      35'b00000000000000000000000000001000000: n1897_o = 3'b000;
      35'b00000000000000000000000000000100000: n1897_o = 3'b000;
      35'b00000000000000000000000000000010000: n1897_o = 3'b000;
      35'b00000000000000000000000000000001000: n1897_o = 3'b000;
      35'b00000000000000000000000000000000100: n1897_o = 3'b000;
      35'b00000000000000000000000000000000010: n1897_o = 3'b000;
      35'b00000000000000000000000000000000001: n1897_o = 3'b000;
      default: n1897_o = 3'b000;
    endcase
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1898_o = n1868_o;
      35'b01000000000000000000000000000000000: n1898_o = n1217_o;
      35'b00100000000000000000000000000000000: n1898_o = n1681_o;
      35'b00010000000000000000000000000000000: n1898_o = n1672_o;
      35'b00001000000000000000000000000000000: n1898_o = n1650_o;
      35'b00000100000000000000000000000000000: n1898_o = n1643_o;
      35'b00000010000000000000000000000000000: n1898_o = n1217_o;
      35'b00000001000000000000000000000000000: n1898_o = n1625_o;
      35'b00000000100000000000000000000000000: n1898_o = n1217_o;
      35'b00000000010000000000000000000000000: n1898_o = n1217_o;
      35'b00000000001000000000000000000000000: n1898_o = n1592_o;
      35'b00000000000100000000000000000000000: n1898_o = n1572_o;
      35'b00000000000010000000000000000000000: n1898_o = n1217_o;
      35'b00000000000001000000000000000000000: n1898_o = n1217_o;
      35'b00000000000000100000000000000000000: n1898_o = n1217_o;
      35'b00000000000000010000000000000000000: n1898_o = n1217_o;
      35'b00000000000000001000000000000000000: n1898_o = n1217_o;
      35'b00000000000000000100000000000000000: n1898_o = n1217_o;
      35'b00000000000000000010000000000000000: n1898_o = n1217_o;
      35'b00000000000000000001000000000000000: n1898_o = n1394_o;
      35'b00000000000000000000100000000000000: n1898_o = n1382_o;
      35'b00000000000000000000010000000000000: n1898_o = n1217_o;
      35'b00000000000000000000001000000000000: n1898_o = n1217_o;
      35'b00000000000000000000000100000000000: n1898_o = n1217_o;
      35'b00000000000000000000000010000000000: n1898_o = n1217_o;
      35'b00000000000000000000000001000000000: n1898_o = n1217_o;
      35'b00000000000000000000000000100000000: n1898_o = n1217_o;
      35'b00000000000000000000000000010000000: n1898_o = n1217_o;
      35'b00000000000000000000000000001000000: n1898_o = n1217_o;
      35'b00000000000000000000000000000100000: n1898_o = n1217_o;
      35'b00000000000000000000000000000010000: n1898_o = n1263_o;
      35'b00000000000000000000000000000001000: n1898_o = n1251_o;
      35'b00000000000000000000000000000000100: n1898_o = n1217_o;
      35'b00000000000000000000000000000000010: n1898_o = n1217_o;
      35'b00000000000000000000000000000000001: n1898_o = n1224_o;
      default: n1898_o = n1217_o;
    endcase
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1900_o = n1870_o;
      35'b01000000000000000000000000000000000: n1900_o = n1686_o;
      35'b00100000000000000000000000000000000: n1900_o = 5'b00000;
      35'b00010000000000000000000000000000000: n1900_o = 5'b00000;
      35'b00001000000000000000000000000000000: n1900_o = 5'b00000;
      35'b00000100000000000000000000000000000: n1900_o = 5'b00000;
      35'b00000010000000000000000000000000000: n1900_o = n1636_o;
      35'b00000001000000000000000000000000000: n1900_o = 5'b00000;
      35'b00000000100000000000000000000000000: n1900_o = n1611_o;
      35'b00000000010000000000000000000000000: n1900_o = 5'b00000;
      35'b00000000001000000000000000000000000: n1900_o = n1595_o;
      35'b00000000000100000000000000000000000: n1900_o = n1575_o;
      35'b00000000000010000000000000000000000: n1900_o = n1555_o;
      35'b00000000000001000000000000000000000: n1900_o = 5'b00000;
      35'b00000000000000100000000000000000000: n1900_o = 5'b00000;
      35'b00000000000000010000000000000000000: n1900_o = 5'b00000;
      35'b00000000000000001000000000000000000: n1900_o = 5'b00000;
      35'b00000000000000000100000000000000000: n1900_o = n1446_o;
      35'b00000000000000000010000000000000000: n1900_o = n1406_o;
      35'b00000000000000000001000000000000000: n1900_o = 5'b00000;
      35'b00000000000000000000100000000000000: n1900_o = 5'b00000;
      35'b00000000000000000000010000000000000: n1900_o = 5'b00000;
      35'b00000000000000000000001000000000000: n1900_o = 5'b00000;
      35'b00000000000000000000000100000000000: n1900_o = 5'b00000;
      35'b00000000000000000000000010000000000: n1900_o = 5'b00000;
      35'b00000000000000000000000001000000000: n1900_o = n1304_o;
      35'b00000000000000000000000000100000000: n1900_o = n1296_o;
      35'b00000000000000000000000000010000000: n1900_o = 5'b00000;
      35'b00000000000000000000000000001000000: n1900_o = n1283_o;
      35'b00000000000000000000000000000100000: n1900_o = n1275_o;
      35'b00000000000000000000000000000010000: n1900_o = n1267_o;
      35'b00000000000000000000000000000001000: n1900_o = n1254_o;
      35'b00000000000000000000000000000000100: n1900_o = n1243_o;
      35'b00000000000000000000000000000000010: n1900_o = n1235_o;
      35'b00000000000000000000000000000000001: n1900_o = n1227_o;
      default: n1900_o = 5'b00000;
    endcase
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1902_o = n1872_o;
      35'b01000000000000000000000000000000000: n1902_o = 3'b000;
      35'b00100000000000000000000000000000000: n1902_o = 3'b000;
      35'b00010000000000000000000000000000000: n1902_o = 3'b000;
      35'b00001000000000000000000000000000000: n1902_o = 3'b000;
      35'b00000100000000000000000000000000000: n1902_o = 3'b000;
      35'b00000010000000000000000000000000000: n1902_o = 3'b000;
      35'b00000001000000000000000000000000000: n1902_o = 3'b000;
      35'b00000000100000000000000000000000000: n1902_o = 3'b000;
      35'b00000000010000000000000000000000000: n1902_o = 3'b000;
      35'b00000000001000000000000000000000000: n1902_o = 3'b000;
      35'b00000000000100000000000000000000000: n1902_o = 3'b000;
      35'b00000000000010000000000000000000000: n1902_o = 3'b000;
      35'b00000000000001000000000000000000000: n1902_o = 3'b000;
      35'b00000000000000100000000000000000000: n1902_o = 3'b000;
      35'b00000000000000010000000000000000000: n1902_o = 3'b000;
      35'b00000000000000001000000000000000000: n1902_o = n1472_o;
      35'b00000000000000000100000000000000000: n1902_o = 3'b000;
      35'b00000000000000000010000000000000000: n1902_o = 3'b000;
      35'b00000000000000000001000000000000000: n1902_o = 3'b000;
      35'b00000000000000000000100000000000000: n1902_o = 3'b000;
      35'b00000000000000000000010000000000000: n1902_o = 3'b000;
      35'b00000000000000000000001000000000000: n1902_o = 3'b000;
      35'b00000000000000000000000100000000000: n1902_o = 3'b000;
      35'b00000000000000000000000010000000000: n1902_o = 3'b000;
      35'b00000000000000000000000001000000000: n1902_o = 3'b000;
      35'b00000000000000000000000000100000000: n1902_o = 3'b000;
      35'b00000000000000000000000000010000000: n1902_o = 3'b000;
      35'b00000000000000000000000000001000000: n1902_o = 3'b000;
      35'b00000000000000000000000000000100000: n1902_o = 3'b000;
      35'b00000000000000000000000000000010000: n1902_o = 3'b000;
      35'b00000000000000000000000000000001000: n1902_o = 3'b000;
      35'b00000000000000000000000000000000100: n1902_o = 3'b000;
      35'b00000000000000000000000000000000010: n1902_o = 3'b000;
      35'b00000000000000000000000000000000001: n1902_o = 3'b000;
      default: n1902_o = 3'b000;
    endcase
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1904_o = n1874_o;
      35'b01000000000000000000000000000000000: n1904_o = 1'b0;
      35'b00100000000000000000000000000000000: n1904_o = 1'b0;
      35'b00010000000000000000000000000000000: n1904_o = 1'b0;
      35'b00001000000000000000000000000000000: n1904_o = 1'b0;
      35'b00000100000000000000000000000000000: n1904_o = 1'b0;
      35'b00000010000000000000000000000000000: n1904_o = 1'b0;
      35'b00000001000000000000000000000000000: n1904_o = 1'b0;
      35'b00000000100000000000000000000000000: n1904_o = 1'b0;
      35'b00000000010000000000000000000000000: n1904_o = 1'b0;
      35'b00000000001000000000000000000000000: n1904_o = 1'b0;
      35'b00000000000100000000000000000000000: n1904_o = 1'b0;
      35'b00000000000010000000000000000000000: n1904_o = 1'b0;
      35'b00000000000001000000000000000000000: n1904_o = 1'b0;
      35'b00000000000000100000000000000000000: n1904_o = 1'b0;
      35'b00000000000000010000000000000000000: n1904_o = 1'b0;
      35'b00000000000000001000000000000000000: n1904_o = 1'b0;
      35'b00000000000000000100000000000000000: n1904_o = 1'b0;
      35'b00000000000000000010000000000000000: n1904_o = 1'b0;
      35'b00000000000000000001000000000000000: n1904_o = 1'b0;
      35'b00000000000000000000100000000000000: n1904_o = 1'b0;
      35'b00000000000000000000010000000000000: n1904_o = 1'b0;
      35'b00000000000000000000001000000000000: n1904_o = 1'b0;
      35'b00000000000000000000000100000000000: n1904_o = 1'b0;
      35'b00000000000000000000000010000000000: n1904_o = 1'b0;
      35'b00000000000000000000000001000000000: n1904_o = 1'b0;
      35'b00000000000000000000000000100000000: n1904_o = 1'b0;
      35'b00000000000000000000000000010000000: n1904_o = 1'b0;
      35'b00000000000000000000000000001000000: n1904_o = 1'b0;
      35'b00000000000000000000000000000100000: n1904_o = 1'b0;
      35'b00000000000000000000000000000010000: n1904_o = 1'b0;
      35'b00000000000000000000000000000001000: n1904_o = 1'b0;
      35'b00000000000000000000000000000000100: n1904_o = 1'b0;
      35'b00000000000000000000000000000000010: n1904_o = 1'b0;
      35'b00000000000000000000000000000000001: n1904_o = 1'b0;
      default: n1904_o = 1'b0;
    endcase
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1906_o = n1876_o;
      35'b01000000000000000000000000000000000: n1906_o = 2'b00;
      35'b00100000000000000000000000000000000: n1906_o = 2'b00;
      35'b00010000000000000000000000000000000: n1906_o = 2'b00;
      35'b00001000000000000000000000000000000: n1906_o = 2'b00;
      35'b00000100000000000000000000000000000: n1906_o = 2'b00;
      35'b00000010000000000000000000000000000: n1906_o = 2'b00;
      35'b00000001000000000000000000000000000: n1906_o = 2'b00;
      35'b00000000100000000000000000000000000: n1906_o = 2'b00;
      35'b00000000010000000000000000000000000: n1906_o = 2'b00;
      35'b00000000001000000000000000000000000: n1906_o = 2'b00;
      35'b00000000000100000000000000000000000: n1906_o = 2'b00;
      35'b00000000000010000000000000000000000: n1906_o = 2'b00;
      35'b00000000000001000000000000000000000: n1906_o = 2'b00;
      35'b00000000000000100000000000000000000: n1906_o = 2'b00;
      35'b00000000000000010000000000000000000: n1906_o = 2'b00;
      35'b00000000000000001000000000000000000: n1906_o = 2'b00;
      35'b00000000000000000100000000000000000: n1906_o = 2'b00;
      35'b00000000000000000010000000000000000: n1906_o = 2'b00;
      35'b00000000000000000001000000000000000: n1906_o = 2'b00;
      35'b00000000000000000000100000000000000: n1906_o = 2'b00;
      35'b00000000000000000000010000000000000: n1906_o = 2'b00;
      35'b00000000000000000000001000000000000: n1906_o = 2'b00;
      35'b00000000000000000000000100000000000: n1906_o = 2'b00;
      35'b00000000000000000000000010000000000: n1906_o = 2'b00;
      35'b00000000000000000000000001000000000: n1906_o = 2'b00;
      35'b00000000000000000000000000100000000: n1906_o = 2'b00;
      35'b00000000000000000000000000010000000: n1906_o = 2'b00;
      35'b00000000000000000000000000001000000: n1906_o = 2'b00;
      35'b00000000000000000000000000000100000: n1906_o = 2'b00;
      35'b00000000000000000000000000000010000: n1906_o = 2'b00;
      35'b00000000000000000000000000000001000: n1906_o = 2'b00;
      35'b00000000000000000000000000000000100: n1906_o = 2'b00;
      35'b00000000000000000000000000000000010: n1906_o = 2'b00;
      35'b00000000000000000000000000000000001: n1906_o = 2'b00;
      default: n1906_o = 2'b00;
    endcase
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1908_o = n1878_o;
      35'b01000000000000000000000000000000000: n1908_o = 2'b00;
      35'b00100000000000000000000000000000000: n1908_o = 2'b00;
      35'b00010000000000000000000000000000000: n1908_o = 2'b00;
      35'b00001000000000000000000000000000000: n1908_o = 2'b00;
      35'b00000100000000000000000000000000000: n1908_o = 2'b00;
      35'b00000010000000000000000000000000000: n1908_o = 2'b00;
      35'b00000001000000000000000000000000000: n1908_o = 2'b00;
      35'b00000000100000000000000000000000000: n1908_o = 2'b00;
      35'b00000000010000000000000000000000000: n1908_o = 2'b00;
      35'b00000000001000000000000000000000000: n1908_o = 2'b00;
      35'b00000000000100000000000000000000000: n1908_o = 2'b00;
      35'b00000000000010000000000000000000000: n1908_o = 2'b00;
      35'b00000000000001000000000000000000000: n1908_o = 2'b00;
      35'b00000000000000100000000000000000000: n1908_o = 2'b00;
      35'b00000000000000010000000000000000000: n1908_o = 2'b00;
      35'b00000000000000001000000000000000000: n1908_o = 2'b00;
      35'b00000000000000000100000000000000000: n1908_o = 2'b00;
      35'b00000000000000000010000000000000000: n1908_o = 2'b00;
      35'b00000000000000000001000000000000000: n1908_o = 2'b00;
      35'b00000000000000000000100000000000000: n1908_o = 2'b00;
      35'b00000000000000000000010000000000000: n1908_o = 2'b00;
      35'b00000000000000000000001000000000000: n1908_o = 2'b00;
      35'b00000000000000000000000100000000000: n1908_o = 2'b00;
      35'b00000000000000000000000010000000000: n1908_o = 2'b00;
      35'b00000000000000000000000001000000000: n1908_o = 2'b00;
      35'b00000000000000000000000000100000000: n1908_o = 2'b00;
      35'b00000000000000000000000000010000000: n1908_o = 2'b00;
      35'b00000000000000000000000000001000000: n1908_o = 2'b00;
      35'b00000000000000000000000000000100000: n1908_o = 2'b00;
      35'b00000000000000000000000000000010000: n1908_o = 2'b00;
      35'b00000000000000000000000000000001000: n1908_o = 2'b00;
      35'b00000000000000000000000000000000100: n1908_o = 2'b00;
      35'b00000000000000000000000000000000010: n1908_o = 2'b00;
      35'b00000000000000000000000000000000001: n1908_o = 2'b00;
      default: n1908_o = 2'b00;
    endcase
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1910_o = 1'b0;
      35'b01000000000000000000000000000000000: n1910_o = n1689_o;
      35'b00100000000000000000000000000000000: n1910_o = 1'b0;
      35'b00010000000000000000000000000000000: n1910_o = 1'b0;
      35'b00001000000000000000000000000000000: n1910_o = 1'b0;
      35'b00000100000000000000000000000000000: n1910_o = 1'b0;
      35'b00000010000000000000000000000000000: n1910_o = 1'b0;
      35'b00000001000000000000000000000000000: n1910_o = 1'b0;
      35'b00000000100000000000000000000000000: n1910_o = 1'b0;
      35'b00000000010000000000000000000000000: n1910_o = 1'b0;
      35'b00000000001000000000000000000000000: n1910_o = 1'b0;
      35'b00000000000100000000000000000000000: n1910_o = 1'b0;
      35'b00000000000010000000000000000000000: n1910_o = 1'b0;
      35'b00000000000001000000000000000000000: n1910_o = 1'b0;
      35'b00000000000000100000000000000000000: n1910_o = 1'b0;
      35'b00000000000000010000000000000000000: n1910_o = 1'b0;
      35'b00000000000000001000000000000000000: n1910_o = 1'b0;
      35'b00000000000000000100000000000000000: n1910_o = 1'b0;
      35'b00000000000000000010000000000000000: n1910_o = 1'b0;
      35'b00000000000000000001000000000000000: n1910_o = 1'b0;
      35'b00000000000000000000100000000000000: n1910_o = 1'b0;
      35'b00000000000000000000010000000000000: n1910_o = 1'b0;
      35'b00000000000000000000001000000000000: n1910_o = 1'b0;
      35'b00000000000000000000000100000000000: n1910_o = 1'b0;
      35'b00000000000000000000000010000000000: n1910_o = 1'b0;
      35'b00000000000000000000000001000000000: n1910_o = 1'b0;
      35'b00000000000000000000000000100000000: n1910_o = 1'b0;
      35'b00000000000000000000000000010000000: n1910_o = 1'b0;
      35'b00000000000000000000000000001000000: n1910_o = 1'b0;
      35'b00000000000000000000000000000100000: n1910_o = 1'b0;
      35'b00000000000000000000000000000010000: n1910_o = 1'b0;
      35'b00000000000000000000000000000001000: n1910_o = 1'b0;
      35'b00000000000000000000000000000000100: n1910_o = 1'b0;
      35'b00000000000000000000000000000000010: n1910_o = 1'b0;
      35'b00000000000000000000000000000000001: n1910_o = 1'b0;
      default: n1910_o = 1'b0;
    endcase
  assign n1911_o = pm_data_i[3:0];
  assign n1912_o = n1324_o[3:0];
  assign n1913_o = n1335_o[3:0];
  assign n1914_o = n1361_o[3:0];
  assign n1915_o = n1409_o[3:0];
  assign n1916_o = n1881_o[3:0];
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1918_o = n1916_o;
      35'b01000000000000000000000000000000000: n1918_o = 4'b0000;
      35'b00100000000000000000000000000000000: n1918_o = 4'b0000;
      35'b00010000000000000000000000000000000: n1918_o = n1674_o;
      35'b00001000000000000000000000000000000: n1918_o = 4'b0000;
      35'b00000100000000000000000000000000000: n1918_o = 4'b0000;
      35'b00000010000000000000000000000000000: n1918_o = 4'b0000;
      35'b00000001000000000000000000000000000: n1918_o = n1615_o;
      35'b00000000100000000000000000000000000: n1918_o = 4'b0000;
      35'b00000000010000000000000000000000000: n1918_o = 4'b0000;
      35'b00000000001000000000000000000000000: n1918_o = 4'b0000;
      35'b00000000000100000000000000000000000: n1918_o = 4'b0000;
      35'b00000000000010000000000000000000000: n1918_o = 4'b0000;
      35'b00000000000001000000000000000000000: n1918_o = n1531_o;
      35'b00000000000000100000000000000000000: n1918_o = n1528_o;
      35'b00000000000000010000000000000000000: n1918_o = n1502_o;
      35'b00000000000000001000000000000000000: n1918_o = 4'b0000;
      35'b00000000000000000100000000000000000: n1918_o = n1915_o;
      35'b00000000000000000010000000000000000: n1918_o = 4'b0000;
      35'b00000000000000000001000000000000000: n1918_o = 4'b0000;
      35'b00000000000000000000100000000000000: n1918_o = 4'b0000;
      35'b00000000000000000000010000000000000: n1918_o = n1914_o;
      35'b00000000000000000000001000000000000: n1918_o = n1913_o;
      35'b00000000000000000000000100000000000: n1918_o = n1912_o;
      35'b00000000000000000000000010000000000: n1918_o = n1911_o;
      35'b00000000000000000000000001000000000: n1918_o = 4'b0000;
      35'b00000000000000000000000000100000000: n1918_o = 4'b0000;
      35'b00000000000000000000000000010000000: n1918_o = 4'b0000;
      35'b00000000000000000000000000001000000: n1918_o = 4'b0000;
      35'b00000000000000000000000000000100000: n1918_o = 4'b0000;
      35'b00000000000000000000000000000010000: n1918_o = 4'b0000;
      35'b00000000000000000000000000000001000: n1918_o = n1246_o;
      35'b00000000000000000000000000000000100: n1918_o = 4'b0000;
      35'b00000000000000000000000000000000010: n1918_o = 4'b0000;
      35'b00000000000000000000000000000000001: n1918_o = 4'b0000;
      default: n1918_o = 4'b0000;
    endcase
  assign n1919_o = pm_data_i[5:4];
  assign n1920_o = n1324_o[5:4];
  assign n1921_o = n1335_o[5:4];
  assign n1922_o = n1361_o[5:4];
  assign n1923_o = n1409_o[5:4];
  assign n1924_o = n1881_o[5:4];
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1926_o = n1924_o;
      35'b01000000000000000000000000000000000: n1926_o = 2'b00;
      35'b00100000000000000000000000000000000: n1926_o = 2'b00;
      35'b00010000000000000000000000000000000: n1926_o = 2'b00;
      35'b00001000000000000000000000000000000: n1926_o = 2'b00;
      35'b00000100000000000000000000000000000: n1926_o = 2'b00;
      35'b00000010000000000000000000000000000: n1926_o = 2'b00;
      35'b00000001000000000000000000000000000: n1926_o = n1614_o;
      35'b00000000100000000000000000000000000: n1926_o = 2'b00;
      35'b00000000010000000000000000000000000: n1926_o = 2'b00;
      35'b00000000001000000000000000000000000: n1926_o = n1578_o;
      35'b00000000000100000000000000000000000: n1926_o = n1558_o;
      35'b00000000000010000000000000000000000: n1926_o = n1543_o;
      35'b00000000000001000000000000000000000: n1926_o = 2'b00;
      35'b00000000000000100000000000000000000: n1926_o = 2'b00;
      35'b00000000000000010000000000000000000: n1926_o = 2'b00;
      35'b00000000000000001000000000000000000: n1926_o = 2'b00;
      35'b00000000000000000100000000000000000: n1926_o = n1923_o;
      35'b00000000000000000010000000000000000: n1926_o = n1397_o;
      35'b00000000000000000001000000000000000: n1926_o = 2'b00;
      35'b00000000000000000000100000000000000: n1926_o = 2'b00;
      35'b00000000000000000000010000000000000: n1926_o = n1922_o;
      35'b00000000000000000000001000000000000: n1926_o = n1921_o;
      35'b00000000000000000000000100000000000: n1926_o = n1920_o;
      35'b00000000000000000000000010000000000: n1926_o = n1919_o;
      35'b00000000000000000000000001000000000: n1926_o = 2'b00;
      35'b00000000000000000000000000100000000: n1926_o = 2'b00;
      35'b00000000000000000000000000010000000: n1926_o = 2'b00;
      35'b00000000000000000000000000001000000: n1926_o = 2'b00;
      35'b00000000000000000000000000000100000: n1926_o = 2'b00;
      35'b00000000000000000000000000000010000: n1926_o = 2'b00;
      35'b00000000000000000000000000000001000: n1926_o = 2'b00;
      35'b00000000000000000000000000000000100: n1926_o = 2'b00;
      35'b00000000000000000000000000000000010: n1926_o = 2'b00;
      35'b00000000000000000000000000000000001: n1926_o = 2'b00;
      default: n1926_o = 2'b00;
    endcase
  assign n1927_o = pm_data_i[7:6];
  assign n1928_o = n1324_o[7:6];
  assign n1929_o = n1335_o[7:6];
  assign n1930_o = n1361_o[7:6];
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1932_o = 2'b00;
      35'b01000000000000000000000000000000000: n1932_o = 2'b00;
      35'b00100000000000000000000000000000000: n1932_o = 2'b00;
      35'b00010000000000000000000000000000000: n1932_o = 2'b00;
      35'b00001000000000000000000000000000000: n1932_o = 2'b00;
      35'b00000100000000000000000000000000000: n1932_o = 2'b00;
      35'b00000010000000000000000000000000000: n1932_o = 2'b00;
      35'b00000001000000000000000000000000000: n1932_o = 2'b00;
      35'b00000000100000000000000000000000000: n1932_o = 2'b00;
      35'b00000000010000000000000000000000000: n1932_o = 2'b00;
      35'b00000000001000000000000000000000000: n1932_o = 2'b00;
      35'b00000000000100000000000000000000000: n1932_o = 2'b00;
      35'b00000000000010000000000000000000000: n1932_o = 2'b00;
      35'b00000000000001000000000000000000000: n1932_o = 2'b00;
      35'b00000000000000100000000000000000000: n1932_o = 2'b00;
      35'b00000000000000010000000000000000000: n1932_o = 2'b00;
      35'b00000000000000001000000000000000000: n1932_o = 2'b00;
      35'b00000000000000000100000000000000000: n1932_o = 2'b00;
      35'b00000000000000000010000000000000000: n1932_o = 2'b00;
      35'b00000000000000000001000000000000000: n1932_o = 2'b00;
      35'b00000000000000000000100000000000000: n1932_o = 2'b00;
      35'b00000000000000000000010000000000000: n1932_o = n1930_o;
      35'b00000000000000000000001000000000000: n1932_o = n1929_o;
      35'b00000000000000000000000100000000000: n1932_o = n1928_o;
      35'b00000000000000000000000010000000000: n1932_o = n1927_o;
      35'b00000000000000000000000001000000000: n1932_o = 2'b00;
      35'b00000000000000000000000000100000000: n1932_o = 2'b00;
      35'b00000000000000000000000000010000000: n1932_o = 2'b00;
      35'b00000000000000000000000000001000000: n1932_o = 2'b00;
      35'b00000000000000000000000000000100000: n1932_o = 2'b00;
      35'b00000000000000000000000000000010000: n1932_o = 2'b00;
      35'b00000000000000000000000000000001000: n1932_o = 2'b00;
      35'b00000000000000000000000000000000100: n1932_o = 2'b00;
      35'b00000000000000000000000000000000010: n1932_o = 2'b00;
      35'b00000000000000000000000000000000001: n1932_o = 2'b00;
      default: n1932_o = 2'b00;
    endcase
  assign n1933_o = n1324_o[9:8];
  assign n1934_o = n1335_o[9:8];
  assign n1935_o = n1361_o[9:8];
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1937_o = 2'b00;
      35'b01000000000000000000000000000000000: n1937_o = 2'b00;
      35'b00100000000000000000000000000000000: n1937_o = 2'b00;
      35'b00010000000000000000000000000000000: n1937_o = 2'b00;
      35'b00001000000000000000000000000000000: n1937_o = 2'b00;
      35'b00000100000000000000000000000000000: n1937_o = 2'b00;
      35'b00000010000000000000000000000000000: n1937_o = 2'b00;
      35'b00000001000000000000000000000000000: n1937_o = 2'b00;
      35'b00000000100000000000000000000000000: n1937_o = 2'b00;
      35'b00000000010000000000000000000000000: n1937_o = 2'b00;
      35'b00000000001000000000000000000000000: n1937_o = 2'b00;
      35'b00000000000100000000000000000000000: n1937_o = 2'b00;
      35'b00000000000010000000000000000000000: n1937_o = 2'b00;
      35'b00000000000001000000000000000000000: n1937_o = 2'b00;
      35'b00000000000000100000000000000000000: n1937_o = 2'b00;
      35'b00000000000000010000000000000000000: n1937_o = 2'b00;
      35'b00000000000000001000000000000000000: n1937_o = 2'b00;
      35'b00000000000000000100000000000000000: n1937_o = 2'b00;
      35'b00000000000000000010000000000000000: n1937_o = 2'b00;
      35'b00000000000000000001000000000000000: n1937_o = 2'b00;
      35'b00000000000000000000100000000000000: n1937_o = 2'b00;
      35'b00000000000000000000010000000000000: n1937_o = n1935_o;
      35'b00000000000000000000001000000000000: n1937_o = n1934_o;
      35'b00000000000000000000000100000000000: n1937_o = n1933_o;
      35'b00000000000000000000000010000000000: n1937_o = 2'b00;
      35'b00000000000000000000000001000000000: n1937_o = 2'b00;
      35'b00000000000000000000000000100000000: n1937_o = 2'b00;
      35'b00000000000000000000000000010000000: n1937_o = 2'b00;
      35'b00000000000000000000000000001000000: n1937_o = 2'b00;
      35'b00000000000000000000000000000100000: n1937_o = 2'b00;
      35'b00000000000000000000000000000010000: n1937_o = 2'b00;
      35'b00000000000000000000000000000001000: n1937_o = 2'b00;
      35'b00000000000000000000000000000000100: n1937_o = 2'b00;
      35'b00000000000000000000000000000000010: n1937_o = 2'b00;
      35'b00000000000000000000000000000000001: n1937_o = 2'b00;
      default: n1937_o = 2'b00;
    endcase
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1940_o = n1883_o;
      35'b01000000000000000000000000000000000: n1940_o = 1'b0;
      35'b00100000000000000000000000000000000: n1940_o = 1'b0;
      35'b00010000000000000000000000000000000: n1940_o = 1'b0;
      35'b00001000000000000000000000000000000: n1940_o = 1'b0;
      35'b00000100000000000000000000000000000: n1940_o = 1'b0;
      35'b00000010000000000000000000000000000: n1940_o = 1'b0;
      35'b00000001000000000000000000000000000: n1940_o = 1'b1;
      35'b00000000100000000000000000000000000: n1940_o = 1'b0;
      35'b00000000010000000000000000000000000: n1940_o = 1'b0;
      35'b00000000001000000000000000000000000: n1940_o = 1'b0;
      35'b00000000000100000000000000000000000: n1940_o = 1'b0;
      35'b00000000000010000000000000000000000: n1940_o = 1'b0;
      35'b00000000000001000000000000000000000: n1940_o = 1'b0;
      35'b00000000000000100000000000000000000: n1940_o = 1'b0;
      35'b00000000000000010000000000000000000: n1940_o = 1'b0;
      35'b00000000000000001000000000000000000: n1940_o = 1'b0;
      35'b00000000000000000100000000000000000: n1940_o = 1'b0;
      35'b00000000000000000010000000000000000: n1940_o = 1'b0;
      35'b00000000000000000001000000000000000: n1940_o = 1'b0;
      35'b00000000000000000000100000000000000: n1940_o = 1'b0;
      35'b00000000000000000000010000000000000: n1940_o = 1'b0;
      35'b00000000000000000000001000000000000: n1940_o = 1'b0;
      35'b00000000000000000000000100000000000: n1940_o = 1'b0;
      35'b00000000000000000000000010000000000: n1940_o = 1'b0;
      35'b00000000000000000000000001000000000: n1940_o = 1'b0;
      35'b00000000000000000000000000100000000: n1940_o = 1'b0;
      35'b00000000000000000000000000010000000: n1940_o = 1'b0;
      35'b00000000000000000000000000001000000: n1940_o = 1'b0;
      35'b00000000000000000000000000000100000: n1940_o = 1'b0;
      35'b00000000000000000000000000000010000: n1940_o = 1'b0;
      35'b00000000000000000000000000000001000: n1940_o = 1'b0;
      35'b00000000000000000000000000000000100: n1940_o = 1'b0;
      35'b00000000000000000000000000000000010: n1940_o = 1'b0;
      35'b00000000000000000000000000000000001: n1940_o = 1'b0;
      default: n1940_o = 1'b0;
    endcase
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1944_o = 1'b0;
      35'b01000000000000000000000000000000000: n1944_o = 1'b0;
      35'b00100000000000000000000000000000000: n1944_o = 1'b0;
      35'b00010000000000000000000000000000000: n1944_o = 1'b0;
      35'b00001000000000000000000000000000000: n1944_o = 1'b0;
      35'b00000100000000000000000000000000000: n1944_o = 1'b0;
      35'b00000010000000000000000000000000000: n1944_o = 1'b0;
      35'b00000001000000000000000000000000000: n1944_o = 1'b0;
      35'b00000000100000000000000000000000000: n1944_o = 1'b0;
      35'b00000000010000000000000000000000000: n1944_o = 1'b0;
      35'b00000000001000000000000000000000000: n1944_o = 1'b0;
      35'b00000000000100000000000000000000000: n1944_o = 1'b0;
      35'b00000000000010000000000000000000000: n1944_o = 1'b0;
      35'b00000000000001000000000000000000000: n1944_o = 1'b0;
      35'b00000000000000100000000000000000000: n1944_o = 1'b0;
      35'b00000000000000010000000000000000000: n1944_o = 1'b0;
      35'b00000000000000001000000000000000000: n1944_o = 1'b1;
      35'b00000000000000000100000000000000000: n1944_o = 1'b0;
      35'b00000000000000000010000000000000000: n1944_o = 1'b0;
      35'b00000000000000000001000000000000000: n1944_o = 1'b0;
      35'b00000000000000000000100000000000000: n1944_o = 1'b0;
      35'b00000000000000000000010000000000000: n1944_o = 1'b0;
      35'b00000000000000000000001000000000000: n1944_o = 1'b0;
      35'b00000000000000000000000100000000000: n1944_o = 1'b0;
      35'b00000000000000000000000010000000000: n1944_o = 1'b1;
      35'b00000000000000000000000001000000000: n1944_o = 1'b0;
      35'b00000000000000000000000000100000000: n1944_o = 1'b0;
      35'b00000000000000000000000000010000000: n1944_o = 1'b0;
      35'b00000000000000000000000000001000000: n1944_o = 1'b0;
      35'b00000000000000000000000000000100000: n1944_o = 1'b0;
      35'b00000000000000000000000000000010000: n1944_o = 1'b0;
      35'b00000000000000000000000000000001000: n1944_o = 1'b0;
      35'b00000000000000000000000000000000100: n1944_o = 1'b0;
      35'b00000000000000000000000000000000010: n1944_o = 1'b0;
      35'b00000000000000000000000000000000001: n1944_o = 1'b0;
      default: n1944_o = 1'b0;
    endcase
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1946_o = n1885_o;
      35'b01000000000000000000000000000000000: n1946_o = 1'b0;
      35'b00100000000000000000000000000000000: n1946_o = 1'b0;
      35'b00010000000000000000000000000000000: n1946_o = 1'b0;
      35'b00001000000000000000000000000000000: n1946_o = 1'b0;
      35'b00000100000000000000000000000000000: n1946_o = 1'b0;
      35'b00000010000000000000000000000000000: n1946_o = 1'b0;
      35'b00000001000000000000000000000000000: n1946_o = 1'b0;
      35'b00000000100000000000000000000000000: n1946_o = 1'b0;
      35'b00000000010000000000000000000000000: n1946_o = 1'b0;
      35'b00000000001000000000000000000000000: n1946_o = 1'b0;
      35'b00000000000100000000000000000000000: n1946_o = 1'b0;
      35'b00000000000010000000000000000000000: n1946_o = 1'b0;
      35'b00000000000001000000000000000000000: n1946_o = 1'b0;
      35'b00000000000000100000000000000000000: n1946_o = 1'b0;
      35'b00000000000000010000000000000000000: n1946_o = 1'b0;
      35'b00000000000000001000000000000000000: n1946_o = 1'b0;
      35'b00000000000000000100000000000000000: n1946_o = 1'b0;
      35'b00000000000000000010000000000000000: n1946_o = 1'b0;
      35'b00000000000000000001000000000000000: n1946_o = 1'b0;
      35'b00000000000000000000100000000000000: n1946_o = 1'b0;
      35'b00000000000000000000010000000000000: n1946_o = 1'b0;
      35'b00000000000000000000001000000000000: n1946_o = 1'b0;
      35'b00000000000000000000000100000000000: n1946_o = 1'b0;
      35'b00000000000000000000000010000000000: n1946_o = 1'b0;
      35'b00000000000000000000000001000000000: n1946_o = 1'b0;
      35'b00000000000000000000000000100000000: n1946_o = 1'b0;
      35'b00000000000000000000000000010000000: n1946_o = 1'b0;
      35'b00000000000000000000000000001000000: n1946_o = 1'b0;
      35'b00000000000000000000000000000100000: n1946_o = 1'b0;
      35'b00000000000000000000000000000010000: n1946_o = 1'b0;
      35'b00000000000000000000000000000001000: n1946_o = 1'b0;
      35'b00000000000000000000000000000000100: n1946_o = 1'b0;
      35'b00000000000000000000000000000000010: n1946_o = 1'b0;
      35'b00000000000000000000000000000000001: n1946_o = 1'b0;
      default: n1946_o = 1'b0;
    endcase
  /* src/t400_decoder.vhd:323:7  */
  always @*
    case (n1890_o)
      35'b10000000000000000000000000000000000: n1956_o = n1887_o;
      35'b01000000000000000000000000000000000: n1956_o = 1'b1;
      35'b00100000000000000000000000000000000: n1956_o = 1'b1;
      35'b00010000000000000000000000000000000: n1956_o = 1'b1;
      35'b00001000000000000000000000000000000: n1956_o = 1'b1;
      35'b00000100000000000000000000000000000: n1956_o = 1'b1;
      35'b00000010000000000000000000000000000: n1956_o = 1'b1;
      35'b00000001000000000000000000000000000: n1956_o = 1'b0;
      35'b00000000100000000000000000000000000: n1956_o = 1'b1;
      35'b00000000010000000000000000000000000: n1956_o = 1'b1;
      35'b00000000001000000000000000000000000: n1956_o = 1'b1;
      35'b00000000000100000000000000000000000: n1956_o = 1'b1;
      35'b00000000000010000000000000000000000: n1956_o = 1'b1;
      35'b00000000000001000000000000000000000: n1956_o = 1'b1;
      35'b00000000000000100000000000000000000: n1956_o = 1'b1;
      35'b00000000000000010000000000000000000: n1956_o = 1'b1;
      35'b00000000000000001000000000000000000: n1956_o = 1'b0;
      35'b00000000000000000100000000000000000: n1956_o = 1'b1;
      35'b00000000000000000010000000000000000: n1956_o = 1'b1;
      35'b00000000000000000001000000000000000: n1956_o = 1'b0;
      35'b00000000000000000000100000000000000: n1956_o = 1'b0;
      35'b00000000000000000000010000000000000: n1956_o = 1'b0;
      35'b00000000000000000000001000000000000: n1956_o = 1'b0;
      35'b00000000000000000000000100000000000: n1956_o = 1'b0;
      35'b00000000000000000000000010000000000: n1956_o = 1'b0;
      35'b00000000000000000000000001000000000: n1956_o = 1'b1;
      35'b00000000000000000000000000100000000: n1956_o = 1'b1;
      35'b00000000000000000000000000010000000: n1956_o = 1'b1;
      35'b00000000000000000000000000001000000: n1956_o = 1'b1;
      35'b00000000000000000000000000000100000: n1956_o = 1'b1;
      35'b00000000000000000000000000000010000: n1956_o = 1'b1;
      35'b00000000000000000000000000000001000: n1956_o = 1'b1;
      35'b00000000000000000000000000000000100: n1956_o = 1'b1;
      35'b00000000000000000000000000000000010: n1956_o = 1'b1;
      35'b00000000000000000000000000000000001: n1956_o = 1'b1;
      default: n1956_o = 1'b1;
    endcase
  /* src/t400_decoder.vhd:321:5  */
  assign n1957_o = n1219_o ? n1891_o : n1212_o;
  /* src/t400_decoder.vhd:321:5  */
  assign n1959_o = n1219_o ? n1893_o : 2'b00;
  /* src/t400_decoder.vhd:321:5  */
  assign n1962_o = n1219_o ? n1895_o : 3'b000;
  /* src/t400_decoder.vhd:321:5  */
  assign n1965_o = n1219_o ? n1897_o : 3'b000;
  /* src/t400_decoder.vhd:321:5  */
  assign n1967_o = n1219_o ? n1898_o : n1217_o;
  /* src/t400_decoder.vhd:321:5  */
  assign n1969_o = n1219_o ? n1900_o : 5'b00000;
  /* src/t400_decoder.vhd:321:5  */
  assign n1972_o = n1219_o ? n1902_o : 3'b000;
  /* src/t400_decoder.vhd:321:5  */
  assign n1975_o = n1219_o ? n1904_o : 1'b0;
  /* src/t400_decoder.vhd:321:5  */
  assign n1978_o = n1219_o ? n1906_o : 2'b00;
  /* src/t400_decoder.vhd:321:5  */
  assign n1981_o = n1219_o ? n1908_o : 2'b00;
  /* src/t400_decoder.vhd:321:5  */
  assign n1984_o = n1219_o ? n1910_o : 1'b0;
  assign n1986_o = {n1937_o, n1932_o, n1926_o, n1918_o};
  /* src/t400_decoder.vhd:321:5  */
  assign n1988_o = n1219_o ? n1986_o : 10'b0000000000;
  /* src/t400_decoder.vhd:321:5  */
  assign n1991_o = n1219_o ? n1940_o : 1'b0;
  /* src/t400_decoder.vhd:321:5  */
  assign n1994_o = n1219_o ? n1944_o : 1'b0;
  /* src/t400_decoder.vhd:321:5  */
  assign n1997_o = n1219_o ? n1946_o : 1'b0;
  /* src/t400_decoder.vhd:321:5  */
  assign n2000_o = n1219_o ? n1956_o : 1'b1;
  /* src/t400_decoder.vhd:826:12  */
  assign n2002_o = en_q[1];
  /* src/t400_decoder.vhd:825:20  */
  assign n2004_o = n2002_o & 1'b1;
  /* src/t400_decoder.vhd:826:22  */
  assign n2005_o = int_i & n2004_o;
  /* src/t400_decoder.vhd:826:32  */
  assign n2006_o = n2000_o & n2005_o;
  /* src/t400_decoder.vhd:828:18  */
  assign n2007_o = {29'b0, cyc_cnt_q};  //  uext
  /* src/t400_decoder.vhd:828:18  */
  assign n2009_o = n2007_o == 32'b00000000000000000000000000000001;
  /* src/t400_decoder.vhd:825:5  */
  assign n2011_o = n2028_o ? 2'b01 : n1959_o;
  /* src/t400_decoder.vhd:825:5  */
  assign n2013_o = n2027_o ? 4'b1000 : n1957_o;
  /* src/t400_decoder.vhd:825:5  */
  assign n2015_o = n2029_o ? 4'b1101 : n1967_o;
  /* src/t400_decoder.vhd:825:5  */
  assign n2017_o = n2030_o ? 2'b10 : n1981_o;
  /* src/t400_decoder.vhd:831:9  */
  assign n2020_o = icyc_en_i ? 1'b1 : 1'b0;
  /* src/t400_decoder.vhd:827:7  */
  assign n2021_o = icyc_en_i & last_cycle_s;
  /* src/t400_decoder.vhd:827:7  */
  assign n2022_o = n2009_o & last_cycle_s;
  /* src/t400_decoder.vhd:827:7  */
  assign n2023_o = icyc_en_i & last_cycle_s;
  /* src/t400_decoder.vhd:827:7  */
  assign n2024_o = icyc_en_i & last_cycle_s;
  /* src/t400_decoder.vhd:827:7  */
  assign n2026_o = last_cycle_s ? n2020_o : 1'b0;
  /* src/t400_decoder.vhd:825:5  */
  assign n2027_o = n2021_o & n2006_o;
  /* src/t400_decoder.vhd:825:5  */
  assign n2028_o = n2022_o & n2006_o;
  /* src/t400_decoder.vhd:825:5  */
  assign n2029_o = n2023_o & n2006_o;
  /* src/t400_decoder.vhd:825:5  */
  assign n2030_o = n2024_o & n2006_o;
  /* src/t400_decoder.vhd:825:5  */
  assign n2032_o = n2006_o ? n2026_o : 1'b0;
  /* src/t400_decoder.vhd:185:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2037_q <= 3'b001;
    else
      n2037_q <= n402_o;
  /* src/t400_decoder.vhd:185:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2038_q <= 8'b00000000;
    else
      n2038_q <= n403_o;
  /* src/t400_decoder.vhd:185:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2039_q <= 8'b00000000;
    else
      n2039_q <= n404_o;
  /* src/t400_decoder.vhd:185:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2040_q <= 1'b0;
    else
      n2040_q <= n405_o;
  /* src/t400_decoder.vhd:185:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2041_q <= 6'b000101;
    else
      n2041_q <= n407_o;
  /* src/t400_decoder.vhd:185:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2042_q <= 1'b0;
    else
      n2042_q <= n409_o;
  /* src/t400_decoder.vhd:185:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n2043_q <= 4'b0000;
    else
      n2043_q <= n411_o;
endmodule

module t400_dmem_ctrl_0
  (input  ck_i,
   input  ck_en_i,
   input  por_i,
   input  res_i,
   input  [2:0] dmem_op_i,
   input  [2:0] b_op_i,
   input  [9:0] dec_data_i,
   input  [3:0] a_i,
   input  [3:0] q_high_i,
   input  [3:0] dm_data_i,
   output [5:0] b_o,
   output [5:0] dm_addr_o,
   output [3:0] dm_data_o,
   output dm_we_o);
  wire [1:0] br_q;
  wire [3:0] bd_q;
  wire n241_o;
  wire [1:0] n242_o;
  wire n244_o;
  wire [1:0] n245_o;
  wire [3:0] n246_o;
  wire n248_o;
  wire [1:0] n249_o;
  wire [3:0] n250_o;
  wire [3:0] n252_o;
  wire n254_o;
  wire [1:0] n255_o;
  wire [1:0] n256_o;
  wire n258_o;
  wire [3:0] n260_o;
  wire n262_o;
  wire [3:0] n264_o;
  wire n266_o;
  wire [6:0] n267_o;
  reg [1:0] n268_o;
  reg [3:0] n269_o;
  wire [1:0] n270_o;
  wire [3:0] n271_o;
  wire [1:0] n273_o;
  wire [3:0] n275_o;
  wire n289_o;
  wire n291_o;
  wire [3:0] n292_o;
  wire n294_o;
  wire n296_o;
  wire [5:0] n297_o;
  wire n299_o;
  wire [5:0] n300_o;
  wire n302_o;
  wire [3:0] n303_o;
  wire [3:0] n304_o;
  wire n306_o;
  wire [3:0] n307_o;
  wire [3:0] n308_o;
  wire [3:0] n309_o;
  wire n311_o;
  wire [7:0] n312_o;
  wire [5:0] n313_o;
  reg [5:0] n314_o;
  reg [3:0] n316_o;
  reg n325_o;
  wire n328_o;
  reg [1:0] n330_q;
  reg [3:0] n331_q;
  wire [5:0] n332_o;
  assign b_o = n332_o;
  assign dm_addr_o = n314_o;
  assign dm_data_o = n316_o;
  assign dm_we_o = n328_o;
  /* src/t400_dmem_ctrl.vhd:80:10  */
  assign br_q = n330_q; // (signal)
  /* src/t400_dmem_ctrl.vhd:81:10  */
  assign bd_q = n331_q; // (signal)
  /* src/t400_dmem_ctrl.vhd:106:11  */
  assign n241_o = b_op_i == 3'b001;
  /* src/t400_dmem_ctrl.vhd:111:33  */
  assign n242_o = a_i[1:0];
  /* src/t400_dmem_ctrl.vhd:110:11  */
  assign n244_o = b_op_i == 3'b010;
  /* src/t400_dmem_ctrl.vhd:115:40  */
  assign n245_o = dec_data_i[5:4];
  /* src/t400_dmem_ctrl.vhd:116:40  */
  assign n246_o = dec_data_i[3:0];
  /* src/t400_dmem_ctrl.vhd:114:11  */
  assign n248_o = b_op_i == 3'b011;
  /* src/t400_dmem_ctrl.vhd:120:40  */
  assign n249_o = dec_data_i[5:4];
  /* src/t400_dmem_ctrl.vhd:121:40  */
  assign n250_o = dec_data_i[3:0];
  /* src/t400_dmem_ctrl.vhd:121:54  */
  assign n252_o = n250_o + 4'b0001;
  /* src/t400_dmem_ctrl.vhd:119:11  */
  assign n254_o = b_op_i == 3'b100;
  /* src/t400_dmem_ctrl.vhd:125:49  */
  assign n255_o = dec_data_i[5:4];
  /* src/t400_dmem_ctrl.vhd:125:26  */
  assign n256_o = br_q ^ n255_o;
  /* src/t400_dmem_ctrl.vhd:124:11  */
  assign n258_o = b_op_i == 3'b101;
  /* src/t400_dmem_ctrl.vhd:129:26  */
  assign n260_o = bd_q + 4'b0001;
  /* src/t400_dmem_ctrl.vhd:128:11  */
  assign n262_o = b_op_i == 3'b110;
  /* src/t400_dmem_ctrl.vhd:133:26  */
  assign n264_o = bd_q - 4'b0001;
  /* src/t400_dmem_ctrl.vhd:132:11  */
  assign n266_o = b_op_i == 3'b111;
  assign n267_o = {n266_o, n262_o, n258_o, n254_o, n248_o, n244_o, n241_o};
  /* src/t400_dmem_ctrl.vhd:104:9  */
  always @*
    case (n267_o)
      7'b1000000: n268_o = br_q;
      7'b0100000: n268_o = br_q;
      7'b0010000: n268_o = n256_o;
      7'b0001000: n268_o = n249_o;
      7'b0000100: n268_o = n245_o;
      7'b0000010: n268_o = n242_o;
      7'b0000001: n268_o = br_q;
      default: n268_o = br_q;
    endcase
  /* src/t400_dmem_ctrl.vhd:104:9  */
  always @*
    case (n267_o)
      7'b1000000: n269_o = n264_o;
      7'b0100000: n269_o = n260_o;
      7'b0010000: n269_o = bd_q;
      7'b0001000: n269_o = n252_o;
      7'b0000100: n269_o = n246_o;
      7'b0000010: n269_o = bd_q;
      7'b0000001: n269_o = a_i;
      default: n269_o = bd_q;
    endcase
  /* src/t400_dmem_ctrl.vhd:103:7  */
  assign n270_o = ck_en_i ? n268_o : br_q;
  /* src/t400_dmem_ctrl.vhd:103:7  */
  assign n271_o = ck_en_i ? n269_o : bd_q;
  /* src/t400_dmem_ctrl.vhd:98:7  */
  assign n273_o = res_i ? 2'b00 : n270_o;
  /* src/t400_dmem_ctrl.vhd:98:7  */
  assign n275_o = res_i ? 4'b0000 : n271_o;
  /* src/t400_dmem_ctrl.vhd:172:7  */
  assign n289_o = dmem_op_i == 3'b000;
  /* src/t400_dmem_ctrl.vhd:176:7  */
  assign n291_o = dmem_op_i == 3'b001;
  /* src/t400_dmem_ctrl.vhd:183:32  */
  assign n292_o = dec_data_i[3:0];
  /* src/t400_dmem_ctrl.vhd:181:7  */
  assign n294_o = dmem_op_i == 3'b010;
  /* src/t400_dmem_ctrl.vhd:186:7  */
  assign n296_o = dmem_op_i == 3'b011;
  /* src/t400_dmem_ctrl.vhd:192:32  */
  assign n297_o = dec_data_i[5:0];
  /* src/t400_dmem_ctrl.vhd:191:7  */
  assign n299_o = dmem_op_i == 3'b100;
  /* src/t400_dmem_ctrl.vhd:197:32  */
  assign n300_o = dec_data_i[5:0];
  /* src/t400_dmem_ctrl.vhd:195:7  */
  assign n302_o = dmem_op_i == 3'b111;
  /* src/t400_dmem_ctrl.vhd:203:45  */
  assign n303_o = dec_data_i[3:0];
  /* src/t400_dmem_ctrl.vhd:203:32  */
  assign n304_o = dm_data_i | n303_o;
  /* src/t400_dmem_ctrl.vhd:201:7  */
  assign n306_o = dmem_op_i == 3'b101;
  /* src/t400_dmem_ctrl.vhd:208:50  */
  assign n307_o = dec_data_i[3:0];
  /* src/t400_dmem_ctrl.vhd:208:36  */
  assign n308_o = ~n307_o;
  /* src/t400_dmem_ctrl.vhd:208:32  */
  assign n309_o = dm_data_i & n308_o;
  /* src/t400_dmem_ctrl.vhd:206:7  */
  assign n311_o = dmem_op_i == 3'b110;
  assign n312_o = {n311_o, n306_o, n302_o, n299_o, n296_o, n294_o, n291_o, n289_o};
  assign n313_o = {br_q, bd_q};
  /* src/t400_dmem_ctrl.vhd:170:5  */
  always @*
    case (n312_o)
      8'b10000000: n314_o = n313_o;
      8'b01000000: n314_o = n313_o;
      8'b00100000: n314_o = n300_o;
      8'b00010000: n314_o = n297_o;
      8'b00001000: n314_o = n313_o;
      8'b00000100: n314_o = n313_o;
      8'b00000010: n314_o = n313_o;
      8'b00000001: n314_o = n313_o;
      default: n314_o = n313_o;
    endcase
  /* src/t400_dmem_ctrl.vhd:170:5  */
  always @*
    case (n312_o)
      8'b10000000: n316_o = n309_o;
      8'b01000000: n316_o = n304_o;
      8'b00100000: n316_o = a_i;
      8'b00010000: n316_o = 4'b0000;
      8'b00001000: n316_o = a_i;
      8'b00000100: n316_o = n292_o;
      8'b00000010: n316_o = q_high_i;
      8'b00000001: n316_o = 4'b0000;
      default: n316_o = 4'b0000;
    endcase
  /* src/t400_dmem_ctrl.vhd:170:5  */
  always @*
    case (n312_o)
      8'b10000000: n325_o = 1'b1;
      8'b01000000: n325_o = 1'b1;
      8'b00100000: n325_o = 1'b1;
      8'b00010000: n325_o = 1'b0;
      8'b00001000: n325_o = 1'b1;
      8'b00000100: n325_o = 1'b1;
      8'b00000010: n325_o = 1'b1;
      8'b00000001: n325_o = 1'b0;
      default: n325_o = 1'b0;
    endcase
  /* src/t400_dmem_ctrl.vhd:222:5  */
  assign n328_o = ck_en_i ? n325_o : 1'b0;
  /* src/t400_dmem_ctrl.vhd:97:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n330_q <= 2'b00;
    else
      n330_q <= n273_o;
  /* src/t400_dmem_ctrl.vhd:97:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n331_q <= 4'b0000;
    else
      n331_q <= n275_o;
  /* src/t400_dmem_ctrl.vhd:93:5  */
  assign n332_o = {br_q, bd_q};
endmodule

module t400_pmem_ctrl_0
  (input  ck_i,
   input  ck_en_i,
   input  por_i,
   input  res_i,
   input  [3:0] a_i,
   input  [3:0] m_i,
   input  [3:0] op_i,
   input  [9:0] dec_data_i,
   input  [9:0] pc_i,
   output [9:0] pc_o,
   output [9:0] pm_addr_o);
  wire [9:0] pc_q;
  wire [9:0] last_pc_s;
  wire [9:0] n154_o;
  wire n158_o;
  wire [9:0] n160_o;
  wire [9:0] n162_o;
  wire n164_o;
  wire [5:0] n165_o;
  wire n167_o;
  wire [6:0] n168_o;
  wire n170_o;
  wire [7:0] n171_o;
  wire n173_o;
  wire n175_o;
  wire n177_o;
  wire n179_o;
  wire n181_o;
  wire [7:0] n182_o;
  wire [3:0] n183_o;
  wire [3:0] n184_o;
  wire [3:0] n185_o;
  wire [3:0] n186_o;
  wire [3:0] n187_o;
  wire [3:0] n188_o;
  wire [3:0] n190_o;
  reg [3:0] n191_o;
  wire [1:0] n192_o;
  wire [1:0] n193_o;
  wire [1:0] n194_o;
  wire [1:0] n195_o;
  wire [1:0] n196_o;
  wire [1:0] n197_o;
  wire [1:0] n198_o;
  wire [1:0] n200_o;
  reg [1:0] n201_o;
  wire n202_o;
  wire n203_o;
  wire n204_o;
  wire n205_o;
  wire n206_o;
  wire n207_o;
  wire n209_o;
  reg n210_o;
  wire n211_o;
  wire n212_o;
  wire n213_o;
  wire n214_o;
  wire n215_o;
  wire n217_o;
  reg n218_o;
  wire [1:0] n219_o;
  wire [1:0] n220_o;
  wire [1:0] n221_o;
  wire [1:0] n223_o;
  reg [1:0] n224_o;
  wire [9:0] n225_o;
  wire [9:0] n226_o;
  wire [9:0] n228_o;
  reg [9:0] n233_q;
  assign pc_o = pc_q;
  assign pm_addr_o = pc_q;
  /* src/t400_pmem_ctrl.vhd:78:10  */
  assign pc_q = n233_q; // (signal)
  /* src/t400_pmem_ctrl.vhd:79:10  */
  assign last_pc_s = n154_o; // (signal)
  /* src/t400_pmem_ctrl.vhd:87:16  */
  assign n154_o = 1'b0 ? 10'b0111111111 : 10'b1111111111;
  /* src/t400_pmem_ctrl.vhd:112:21  */
  assign n158_o = pc_q == last_pc_s;
  /* src/t400_pmem_ctrl.vhd:116:38  */
  assign n160_o = pc_q + 10'b0000000001;
  /* src/t400_pmem_ctrl.vhd:112:13  */
  assign n162_o = n158_o ? 10'b0000000000 : n160_o;
  /* src/t400_pmem_ctrl.vhd:111:11  */
  assign n164_o = op_i == 4'b0001;
  /* src/t400_pmem_ctrl.vhd:121:52  */
  assign n165_o = dec_data_i[5:0];
  /* src/t400_pmem_ctrl.vhd:120:11  */
  assign n167_o = op_i == 4'b0010;
  /* src/t400_pmem_ctrl.vhd:125:52  */
  assign n168_o = dec_data_i[6:0];
  /* src/t400_pmem_ctrl.vhd:124:11  */
  assign n170_o = op_i == 4'b0011;
  /* src/t400_pmem_ctrl.vhd:129:52  */
  assign n171_o = dec_data_i[7:0];
  /* src/t400_pmem_ctrl.vhd:128:11  */
  assign n173_o = op_i == 4'b0100;
  /* src/t400_pmem_ctrl.vhd:132:11  */
  assign n175_o = op_i == 4'b0101;
  /* src/t400_pmem_ctrl.vhd:136:11  */
  assign n177_o = op_i == 4'b0110;
  /* src/t400_pmem_ctrl.vhd:140:11  */
  assign n179_o = op_i == 4'b0111;
  /* src/t400_pmem_ctrl.vhd:145:11  */
  assign n181_o = op_i == 4'b1000;
  assign n182_o = {n181_o, n179_o, n177_o, n175_o, n173_o, n170_o, n167_o, n164_o};
  assign n183_o = n162_o[3:0];
  assign n184_o = n165_o[3:0];
  assign n185_o = n168_o[3:0];
  assign n186_o = n171_o[3:0];
  assign n187_o = dec_data_i[3:0];
  assign n188_o = pc_i[3:0];
  assign n190_o = pc_q[3:0];
  /* src/t400_pmem_ctrl.vhd:109:9  */
  always @*
    case (n182_o)
      8'b10000000: n191_o = 4'b0000;
      8'b01000000: n191_o = m_i;
      8'b00100000: n191_o = n188_o;
      8'b00010000: n191_o = n187_o;
      8'b00001000: n191_o = n186_o;
      8'b00000100: n191_o = n185_o;
      8'b00000010: n191_o = n184_o;
      8'b00000001: n191_o = n183_o;
      default: n191_o = n190_o;
    endcase
  assign n192_o = n162_o[5:4];
  assign n193_o = n165_o[5:4];
  assign n194_o = n168_o[5:4];
  assign n195_o = n171_o[5:4];
  assign n196_o = dec_data_i[5:4];
  assign n197_o = pc_i[5:4];
  assign n198_o = a_i[1:0];
  assign n200_o = pc_q[5:4];
  /* src/t400_pmem_ctrl.vhd:109:9  */
  always @*
    case (n182_o)
      8'b10000000: n201_o = 2'b00;
      8'b01000000: n201_o = n198_o;
      8'b00100000: n201_o = n197_o;
      8'b00010000: n201_o = n196_o;
      8'b00001000: n201_o = n195_o;
      8'b00000100: n201_o = n194_o;
      8'b00000010: n201_o = n193_o;
      8'b00000001: n201_o = n192_o;
      default: n201_o = n200_o;
    endcase
  assign n202_o = n162_o[6];
  assign n203_o = n168_o[6];
  assign n204_o = n171_o[6];
  assign n205_o = dec_data_i[6];
  assign n206_o = pc_i[6];
  assign n207_o = a_i[2];
  assign n209_o = pc_q[6];
  /* src/t400_pmem_ctrl.vhd:109:9  */
  always @*
    case (n182_o)
      8'b10000000: n210_o = 1'b0;
      8'b01000000: n210_o = n207_o;
      8'b00100000: n210_o = n206_o;
      8'b00010000: n210_o = n205_o;
      8'b00001000: n210_o = n204_o;
      8'b00000100: n210_o = n203_o;
      8'b00000010: n210_o = n209_o;
      8'b00000001: n210_o = n202_o;
      default: n210_o = n209_o;
    endcase
  assign n211_o = n162_o[7];
  assign n212_o = n171_o[7];
  assign n213_o = dec_data_i[7];
  assign n214_o = pc_i[7];
  assign n215_o = a_i[3];
  assign n217_o = pc_q[7];
  /* src/t400_pmem_ctrl.vhd:109:9  */
  always @*
    case (n182_o)
      8'b10000000: n218_o = 1'b0;
      8'b01000000: n218_o = n215_o;
      8'b00100000: n218_o = n214_o;
      8'b00010000: n218_o = n213_o;
      8'b00001000: n218_o = n212_o;
      8'b00000100: n218_o = n217_o;
      8'b00000010: n218_o = n217_o;
      8'b00000001: n218_o = n211_o;
      default: n218_o = n217_o;
    endcase
  assign n219_o = n162_o[9:8];
  assign n220_o = dec_data_i[9:8];
  assign n221_o = pc_i[9:8];
  assign n223_o = pc_q[9:8];
  /* src/t400_pmem_ctrl.vhd:109:9  */
  always @*
    case (n182_o)
      8'b10000000: n224_o = 2'b01;
      8'b01000000: n224_o = n223_o;
      8'b00100000: n224_o = n221_o;
      8'b00010000: n224_o = n220_o;
      8'b00001000: n224_o = n223_o;
      8'b00000100: n224_o = n223_o;
      8'b00000010: n224_o = n223_o;
      8'b00000001: n224_o = n219_o;
      default: n224_o = n223_o;
    endcase
  assign n225_o = {n224_o, n218_o, n210_o, n201_o, n191_o};
  /* src/t400_pmem_ctrl.vhd:107:7  */
  assign n226_o = ck_en_i ? n225_o : pc_q;
  /* src/t400_pmem_ctrl.vhd:103:7  */
  assign n228_o = res_i ? 10'b0000000000 : n226_o;
  /* src/t400_pmem_ctrl.vhd:102:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n233_q <= 10'b0000000000;
    else
      n233_q <= n228_o;
endmodule

module t400_reset
  (input  ck_i,
   input  icyc_en_i,
   input  por_i,
   input  reset_n_i,
   output res_o);
  wire [1:0] res_state_q;
  wire res_q;
  wire n109_o;
  wire [1:0] n111_o;
  wire n113_o;
  wire n114_o;
  wire [1:0] n117_o;
  wire n119_o;
  wire n120_o;
  wire [1:0] n123_o;
  wire n125_o;
  wire [1:0] n127_o;
  wire n129_o;
  wire [3:0] n130_o;
  reg [1:0] n132_o;
  reg n135_o;
  wire n138_o;
  wire [1:0] n147_o;
  reg [1:0] n148_q;
  reg n149_q;
  assign res_o = res_q;
  /* src/t400_reset.vhd:67:10  */
  assign res_state_q = n148_q; // (signal)
  /* src/t400_reset.vhd:68:10  */
  assign res_q = n149_q; // (signal)
  /* src/t400_reset.vhd:91:26  */
  assign n109_o = ~reset_n_i;
  /* src/t400_reset.vhd:91:13  */
  assign n111_o = n109_o ? 2'b01 : res_state_q;
  /* src/t400_reset.vhd:90:11  */
  assign n113_o = res_state_q == 2'b00;
  /* src/t400_reset.vhd:96:26  */
  assign n114_o = ~reset_n_i;
  /* src/t400_reset.vhd:96:13  */
  assign n117_o = n114_o ? 2'b10 : 2'b00;
  /* src/t400_reset.vhd:95:11  */
  assign n119_o = res_state_q == 2'b01;
  /* src/t400_reset.vhd:103:26  */
  assign n120_o = ~reset_n_i;
  /* src/t400_reset.vhd:103:13  */
  assign n123_o = n120_o ? 2'b11 : 2'b00;
  /* src/t400_reset.vhd:102:11  */
  assign n125_o = res_state_q == 2'b10;
  /* src/t400_reset.vhd:111:13  */
  assign n127_o = reset_n_i ? 2'b00 : res_state_q;
  /* src/t400_reset.vhd:109:11  */
  assign n129_o = res_state_q == 2'b11;
  /* src/t400_core.vhd:86:5  */
  assign n130_o = {n129_o, n125_o, n119_o, n113_o};
  /* src/t400_reset.vhd:89:9  */
  always @*
    case (n130_o)
      4'b1000: n132_o = n127_o;
      4'b0100: n132_o = n123_o;
      4'b0010: n132_o = n117_o;
      4'b0001: n132_o = n111_o;
      default: n132_o = 2'b00;
    endcase
  /* src/t400_reset.vhd:89:9  */
  always @*
    case (n130_o)
      4'b1000: n135_o = 1'b1;
      4'b0100: n135_o = 1'b0;
      4'b0010: n135_o = 1'b0;
      4'b0001: n135_o = 1'b0;
      default: n135_o = 1'b0;
    endcase
  /* src/t400_reset.vhd:88:7  */
  assign n138_o = icyc_en_i ? n135_o : 1'b0;
  /* src/t400_reset.vhd:86:5  */
  assign n147_o = icyc_en_i ? n132_o : res_state_q;
  /* src/t400_reset.vhd:86:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n148_q <= 2'b00;
    else
      n148_q <= n147_o;
  /* src/t400_reset.vhd:86:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n149_q <= 1'b0;
    else
      n149_q <= n138_o;
endmodule

module t400_clkgen_2
  (input  ck_i,
   input  ck_en_i,
   input  por_i,
   output phi1_o,
   output out_en_o,
   output in_en_o,
   output icyc_en_o);
  wire [5:0] ck_div_cnt_q;
  wire ck_div_zero_s;
  wire ck_div_half_s;
  wire phi1_q;
  wire [5:0] n79_o;
  wire n81_o;
  wire [5:0] n83_o;
  wire n85_o;
  wire n96_o;
  wire n98_o;
  wire n99_o;
  wire n100_o;
  wire n101_o;
  wire [5:0] n102_o;
  reg [5:0] n103_q;
  wire n104_o;
  reg n105_q;
  assign phi1_o = phi1_q;
  assign out_en_o = n100_o;
  assign in_en_o = n101_o;
  assign icyc_en_o = n99_o;
  /* src/t400_clkgen.vhd:83:12  */
  assign ck_div_cnt_q = n103_q; // (signal)
  /* src/t400_clkgen.vhd:84:12  */
  assign ck_div_zero_s = n96_o; // (signal)
  /* src/t400_clkgen.vhd:85:12  */
  assign ck_div_half_s = n98_o; // (signal)
  /* src/t400_clkgen.vhd:86:12  */
  assign phi1_q = n105_q; // (signal)
  /* src/t400_clkgen.vhd:109:40  */
  assign n79_o = ck_div_cnt_q - 6'b000001;
  /* src/t400_clkgen.vhd:111:11  */
  assign n81_o = ck_div_half_s ? 1'b1 : phi1_q;
  /* src/t400_clkgen.vhd:105:9  */
  assign n83_o = ck_div_zero_s ? 6'b001111 : n79_o;
  /* src/t400_clkgen.vhd:105:9  */
  assign n85_o = ck_div_zero_s ? 1'b0 : n81_o;
  /* src/t400_clkgen.vhd:120:33  */
  assign n96_o = ck_div_cnt_q == 6'b000000;
  /* src/t400_clkgen.vhd:121:33  */
  assign n98_o = ck_div_cnt_q == 6'b001000;
  /* src/t400_clkgen.vhd:131:24  */
  assign n99_o = ck_div_zero_s & ck_en_i;
  /* src/t400_clkgen.vhd:133:24  */
  assign n100_o = ck_div_zero_s & ck_en_i;
  /* src/t400_clkgen.vhd:135:24  */
  assign n101_o = ck_div_half_s & ck_en_i;
  /* src/t400_clkgen.vhd:103:5  */
  assign n102_o = ck_en_i ? n83_o : ck_div_cnt_q;
  /* src/t400_clkgen.vhd:103:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n103_q <= 6'b001111;
    else
      n103_q <= n102_o;
  /* src/t400_clkgen.vhd:103:5  */
  assign n104_o = ck_en_i ? n85_o : phi1_q;
  /* src/t400_clkgen.vhd:103:5  */
  always @(posedge ck_i or posedge por_i)
    if (por_i)
      n105_q <= 1'b0;
    else
      n105_q <= n104_o;
endmodule

module t400_core
  (input  ck_i,
   input  ck_en_i,
   input  por_n_i,
   input  reset_n_i,
   input  cko_i,
   input  [7:0] pm_data_i,
   input  [3:0] dm_data_i,
   input  [7:0] io_l_i,
   input  [3:0] io_g_i,
   input  [3:0] io_in_i,
   input  si_i,
   output [9:0] pm_addr_o,
   output [5:0] dm_addr_o,
   output dm_we_o,
   output [3:0] dm_data_o,
   output [7:0] io_l_o,
   output [7:0] io_l_en_o,
   output [3:0] io_d_o,
   output [3:0] io_d_en_o,
   output [3:0] io_g_o,
   output [3:0] io_g_en_o,
   output so_o,
   output so_en_o,
   output sk_o,
   output sk_en_o);
  wire ck_en_s;
  wire por_s;
  wire res_s;
  wire phi1_s;
  wire out_en_s;
  wire in_en_s;
  wire icyc_en_s;
  wire [9:0] pm_addr_s;
  wire [3:0] a_s;
  wire [9:0] dec_data_s;
  wire [9:0] pc_to_stack_s;
  wire [9:0] pc_from_stack_s;
  wire [7:0] q_s;
  wire [5:0] b_s;
  wire c_s;
  wire carry_s;
  wire [3:0] sio_s;
  wire [3:0] pc_op_s;
  wire [1:0] stack_op_s;
  wire [2:0] dmem_op_s;
  wire [2:0] b_op_s;
  wire [3:0] skip_op_s;
  wire [4:0] alu_op_s;
  wire [2:0] io_l_op_s;
  wire io_d_op_s;
  wire [1:0] io_g_op_s;
  wire [1:0] io_in_op_s;
  wire sio_op_s;
  wire is_lbi_s;
  wire [3:0] en_s;
  wire skip_s;
  wire skip_lbi_s;
  wire tim_c_s;
  wire [3:0] in_s;
  wire int_s;
  wire [3:0] io_g_s;
  wire cs_n_s;
  wire rd_n_s;
  wire wr_n_s;
  wire n14_o;
  wire clkgen_b_phi1_o;
  wire clkgen_b_out_en_o;
  wire clkgen_b_in_en_o;
  wire clkgen_b_icyc_en_o;
  wire reset_b_res_o;
  wire [9:0] pmem_ctrl_b_pc_o;
  wire [9:0] pmem_ctrl_b_pm_addr_o;
  wire [5:0] dmem_ctrl_b_b_o;
  wire [5:0] dmem_ctrl_b_dm_addr_o;
  wire [3:0] dmem_ctrl_b_dm_data_o;
  wire dmem_ctrl_b_dm_we_o;
  wire [3:0] n22_o;
  wire [3:0] decoder_b_pc_op_o;
  wire [1:0] decoder_b_stack_op_o;
  wire [2:0] decoder_b_dmem_op_o;
  wire [2:0] decoder_b_b_op_o;
  wire [3:0] decoder_b_skip_op_o;
  wire [4:0] decoder_b_alu_op_o;
  wire [2:0] decoder_b_io_l_op_o;
  wire decoder_b_io_d_op_o;
  wire [1:0] decoder_b_io_g_op_o;
  wire [1:0] decoder_b_io_in_op_o;
  wire decoder_b_sio_op_o;
  wire [9:0] decoder_b_dec_data_o;
  wire [3:0] decoder_b_en_o;
  wire decoder_b_is_lbi_o;
  wire skip_b_skip_o;
  wire skip_b_skip_lbi_o;
  wire [3:0] n41_o;
  wire [3:0] alu_b_a_o;
  wire alu_b_carry_o;
  wire alu_b_c_o;
  wire [3:0] n44_o;
  wire [9:0] stack_b_pc_o;
  wire n49_o;
  wire n50_o;
  wire n51_o;
  wire [7:0] io_l_b_q_o;
  wire [7:0] io_l_b_io_l_o;
  wire [7:0] io_l_b_io_l_en_o;
  wire n52_o;
  wire [3:0] io_d_b_io_d_o;
  wire [3:0] io_d_b_io_d_en_o;
  wire [3:0] n56_o;
  wire [3:0] io_g_b_io_g_o;
  wire [3:0] io_g_b_io_g_en_o;
  wire [3:0] use_in_io_in_b_in_o;
  wire use_in_io_in_b_int_o;
  wire n61_o;
  wire [3:0] sio_b_sio_o;
  wire sio_b_so_o;
  wire sio_b_so_en_o;
  wire sio_b_sk_o;
  wire sio_b_sk_en_o;
  wire n64_o;
  wire n65_o;
  wire use_tim_timer_b_c_o;
  assign pm_addr_o = pm_addr_s;
  assign dm_addr_o = dmem_ctrl_b_dm_addr_o;
  assign dm_we_o = dmem_ctrl_b_dm_we_o;
  assign dm_data_o = dmem_ctrl_b_dm_data_o;
  assign io_l_o = io_l_b_io_l_o;
  assign io_l_en_o = io_l_b_io_l_en_o;
  assign io_d_o = io_d_b_io_d_o;
  assign io_d_en_o = io_d_b_io_d_en_o;
  assign io_g_o = io_g_b_io_g_o;
  assign io_g_en_o = io_g_b_io_g_en_o;
  assign so_o = sio_b_so_o;
  assign so_en_o = sio_b_so_en_o;
  assign sk_o = sio_b_sk_o;
  assign sk_en_o = sio_b_sk_en_o;
  /* src/t400_core.vhd:107:10  */
  assign ck_en_s = ck_en_i; // (signal)
  /* src/t400_core.vhd:108:10  */
  assign por_s = n14_o; // (signal)
  /* src/t400_core.vhd:109:10  */
  assign res_s = reset_b_res_o; // (signal)
  /* src/t400_core.vhd:111:10  */
  assign phi1_s = clkgen_b_phi1_o; // (signal)
  /* src/t400_core.vhd:112:10  */
  assign out_en_s = clkgen_b_out_en_o; // (signal)
  /* src/t400_core.vhd:113:10  */
  assign in_en_s = clkgen_b_in_en_o; // (signal)
  /* src/t400_core.vhd:114:10  */
  assign icyc_en_s = clkgen_b_icyc_en_o; // (signal)
  /* src/t400_core.vhd:116:10  */
  assign pm_addr_s = pmem_ctrl_b_pm_addr_o; // (signal)
  /* src/t400_core.vhd:118:10  */
  assign a_s = alu_b_a_o; // (signal)
  /* src/t400_core.vhd:119:10  */
  assign dec_data_s = decoder_b_dec_data_o; // (signal)
  /* src/t400_core.vhd:121:10  */
  assign pc_to_stack_s = pmem_ctrl_b_pc_o; // (signal)
  /* src/t400_core.vhd:122:10  */
  assign pc_from_stack_s = stack_b_pc_o; // (signal)
  /* src/t400_core.vhd:124:10  */
  assign q_s = io_l_b_q_o; // (signal)
  /* src/t400_core.vhd:125:10  */
  assign b_s = dmem_ctrl_b_b_o; // (signal)
  /* src/t400_core.vhd:127:10  */
  assign c_s = alu_b_c_o; // (signal)
  /* src/t400_core.vhd:128:10  */
  assign carry_s = alu_b_carry_o; // (signal)
  /* src/t400_core.vhd:130:10  */
  assign sio_s = sio_b_sio_o; // (signal)
  /* src/t400_core.vhd:132:10  */
  assign pc_op_s = decoder_b_pc_op_o; // (signal)
  /* src/t400_core.vhd:133:10  */
  assign stack_op_s = decoder_b_stack_op_o; // (signal)
  /* src/t400_core.vhd:134:10  */
  assign dmem_op_s = decoder_b_dmem_op_o; // (signal)
  /* src/t400_core.vhd:135:10  */
  assign b_op_s = decoder_b_b_op_o; // (signal)
  /* src/t400_core.vhd:136:10  */
  assign skip_op_s = decoder_b_skip_op_o; // (signal)
  /* src/t400_core.vhd:137:10  */
  assign alu_op_s = decoder_b_alu_op_o; // (signal)
  /* src/t400_core.vhd:138:10  */
  assign io_l_op_s = decoder_b_io_l_op_o; // (signal)
  /* src/t400_core.vhd:139:10  */
  assign io_d_op_s = decoder_b_io_d_op_o; // (signal)
  /* src/t400_core.vhd:140:10  */
  assign io_g_op_s = decoder_b_io_g_op_o; // (signal)
  /* src/t400_core.vhd:141:10  */
  assign io_in_op_s = decoder_b_io_in_op_o; // (signal)
  /* src/t400_core.vhd:142:10  */
  assign sio_op_s = decoder_b_sio_op_o; // (signal)
  /* src/t400_core.vhd:143:10  */
  assign is_lbi_s = decoder_b_is_lbi_o; // (signal)
  /* src/t400_core.vhd:144:10  */
  assign en_s = decoder_b_en_o; // (signal)
  /* src/t400_core.vhd:146:10  */
  assign skip_s = skip_b_skip_o; // (signal)
  /* src/t400_core.vhd:147:10  */
  assign skip_lbi_s = skip_b_skip_lbi_o; // (signal)
  /* src/t400_core.vhd:148:10  */
  assign tim_c_s = use_tim_timer_b_c_o; // (signal)
  /* src/t400_core.vhd:150:10  */
  assign in_s = use_in_io_in_b_in_o; // (signal)
  /* src/t400_core.vhd:151:10  */
  assign int_s = use_in_io_in_b_int_o; // (signal)
  /* src/t400_core.vhd:153:10  */
  assign io_g_s = io_g_i; // (signal)
  /* src/t400_core.vhd:155:10  */
  assign cs_n_s = n49_o; // (signal)
  /* src/t400_core.vhd:156:10  */
  assign rd_n_s = n50_o; // (signal)
  /* src/t400_core.vhd:157:10  */
  assign wr_n_s = n51_o; // (signal)
  /* src/t400_core.vhd:162:22  */
  assign n14_o = ~por_n_i;
  /* src/t400_core.vhd:169:3  */
  t400_clkgen_2 clkgen_b (
    .ck_i(ck_i),
    .ck_en_i(ck_en_s),
    .por_i(por_s),
    .phi1_o(clkgen_b_phi1_o),
    .out_en_o(clkgen_b_out_en_o),
    .in_en_o(clkgen_b_in_en_o),
    .icyc_en_o(clkgen_b_icyc_en_o));
  /* src/t400_core.vhd:187:3  */
  t400_reset reset_b (
    .ck_i(ck_i),
    .icyc_en_i(icyc_en_s),
    .por_i(por_s),
    .reset_n_i(reset_n_i),
    .res_o(reset_b_res_o));
  /* src/t400_core.vhd:200:3  */
  t400_pmem_ctrl_0 pmem_ctrl_b (
    .ck_i(ck_i),
    .ck_en_i(ck_en_s),
    .por_i(por_s),
    .res_i(res_s),
    .a_i(a_s),
    .m_i(dm_data_i),
    .op_i(pc_op_s),
    .dec_data_i(dec_data_s),
    .pc_i(pc_from_stack_s),
    .pc_o(pmem_ctrl_b_pc_o),
    .pm_addr_o(pmem_ctrl_b_pm_addr_o));
  /* src/t400_core.vhd:224:3  */
  t400_dmem_ctrl_0 dmem_ctrl_b (
    .ck_i(ck_i),
    .ck_en_i(ck_en_s),
    .por_i(por_s),
    .res_i(res_s),
    .dmem_op_i(dmem_op_s),
    .b_op_i(b_op_s),
    .dec_data_i(dec_data_s),
    .a_i(a_s),
    .q_high_i(n22_o),
    .dm_data_i(dm_data_i),
    .b_o(dmem_ctrl_b_b_o),
    .dm_addr_o(dmem_ctrl_b_dm_addr_o),
    .dm_data_o(dmem_ctrl_b_dm_data_o),
    .dm_we_o(dmem_ctrl_b_dm_we_o));
  /* src/t400_core.vhd:237:24  */
  assign n22_o = q_s[7:4];
  /* src/t400_core.vhd:249:3  */
  t400_decoder_0 decoder_b (
    .ck_i(ck_i),
    .ck_en_i(ck_en_s),
    .por_i(por_s),
    .res_i(res_s),
    .out_en_i(out_en_s),
    .in_en_i(in_en_s),
    .icyc_en_i(icyc_en_s),
    .skip_i(skip_s),
    .skip_lbi_i(skip_lbi_s),
    .int_i(int_s),
    .pm_addr_i(pm_addr_s),
    .pm_data_i(pm_data_i),
    .pc_op_o(decoder_b_pc_op_o),
    .stack_op_o(decoder_b_stack_op_o),
    .dmem_op_o(decoder_b_dmem_op_o),
    .b_op_o(decoder_b_b_op_o),
    .skip_op_o(decoder_b_skip_op_o),
    .alu_op_o(decoder_b_alu_op_o),
    .io_l_op_o(decoder_b_io_l_op_o),
    .io_d_op_o(decoder_b_io_d_op_o),
    .io_g_op_o(decoder_b_io_g_op_o),
    .io_in_op_o(decoder_b_io_in_op_o),
    .sio_op_o(decoder_b_sio_op_o),
    .dec_data_o(decoder_b_dec_data_o),
    .en_o(decoder_b_en_o),
    .is_lbi_o(decoder_b_is_lbi_o));
  /* src/t400_core.vhd:286:3  */
  t400_skip_0 skip_b (
    .ck_i(ck_i),
    .ck_en_i(ck_en_s),
    .por_i(por_s),
    .res_i(res_s),
    .op_i(skip_op_s),
    .dec_data_i(dec_data_s),
    .carry_i(carry_s),
    .c_i(c_s),
    .bd_i(n41_o),
    .is_lbi_i(is_lbi_s),
    .a_i(a_s),
    .m_i(dm_data_i),
    .g_i(io_g_s),
    .tim_c_i(tim_c_s),
    .skip_o(skip_b_skip_o),
    .skip_lbi_o(skip_b_skip_lbi_o));
  /* src/t400_core.vhd:299:24  */
  assign n41_o = b_s[3:0];
  /* src/t400_core.vhd:313:3  */
  t400_alu_0 alu_b (
    .ck_i(ck_i),
    .ck_en_i(ck_en_s),
    .por_i(por_s),
    .res_i(res_s),
    .cko_i(cko_i),
    .op_i(alu_op_s),
    .m_i(dm_data_i),
    .dec_data_i(dec_data_s),
    .q_low_i(n44_o),
    .b_i(b_s),
    .g_i(io_g_s),
    .in_i(in_s),
    .sio_i(sio_s),
    .a_o(alu_b_a_o),
    .carry_o(alu_b_carry_o),
    .c_o(alu_b_c_o));
  /* src/t400_core.vhd:326:24  */
  assign n44_o = q_s[3:0];
  /* src/t400_core.vhd:340:3  */
  t400_stack_0 stack_b (
    .ck_i(ck_i),
    .ck_en_i(ck_en_s),
    .por_i(por_s),
    .op_i(stack_op_s),
    .pc_i(pc_to_stack_s),
    .pc_o(stack_b_pc_o));
  /* src/t400_core.vhd:357:20  */
  assign n49_o = io_in_i[2];
  /* src/t400_core.vhd:358:20  */
  assign n50_o = io_in_i[1];
  /* src/t400_core.vhd:359:20  */
  assign n51_o = io_in_i[3];
  /* src/t400_core.vhd:361:3  */
  t400_io_l_0_0_0_0_0_0_0_0_1 io_l_b (
    .ck_i(ck_i),
    .ck_en_i(ck_en_s),
    .por_i(por_s),
    .in_en_i(in_en_s),
    .op_i(io_l_op_s),
    .en2_i(n52_o),
    .m_i(dm_data_i),
    .a_i(a_s),
    .pm_data_i(pm_data_i),
    .cs_n_i(cs_n_s),
    .rd_n_i(rd_n_s),
    .wr_n_i(wr_n_s),
    .io_l_i(io_l_i),
    .q_o(io_l_b_q_o),
    .io_l_o(io_l_b_io_l_o),
    .io_l_en_o(io_l_b_io_l_en_o));
  /* src/t400_core.vhd:379:24  */
  assign n52_o = en_s[2];
  /* src/t400_core.vhd:396:3  */
  t400_io_d_0_0_0_0 io_d_b (
    .ck_i(ck_i),
    .ck_en_i(ck_en_s),
    .por_i(por_s),
    .res_i(res_s),
    .op_i(io_d_op_s),
    .bd_i(n56_o),
    .io_d_o(io_d_b_io_d_o),
    .io_d_en_o(io_d_b_io_d_en_o));
  /* src/t400_core.vhd:409:23  */
  assign n56_o = b_s[3:0];
  /* src/t400_core.vhd:418:3  */
  t400_io_g_0_0_0_0_1 io_g_b (
    .ck_i(ck_i),
    .ck_en_i(ck_en_s),
    .por_i(por_s),
    .res_i(res_s),
    .op_i(io_g_op_s),
    .m_i(dm_data_i),
    .dec_data_i(dec_data_s),
    .cs_n_i(cs_n_s),
    .wr_n_i(wr_n_s),
    .io_g_o(io_g_b_io_g_o),
    .io_g_en_o(io_g_b_io_g_en_o));
  /* src/t400_core.vhd:445:5  */
  t400_io_in use_in_io_in_b (
    .ck_i(ck_i),
    .ck_en_i(ck_en_s),
    .por_i(por_s),
    .icyc_en_i(icyc_en_s),
    .in_en_i(in_en_s),
    .op_i(io_in_op_s),
    .en1_i(n61_o),
    .io_in_i(io_in_i),
    .in_o(use_in_io_in_b_in_o),
    .int_o(use_in_io_in_b_int_o));
  /* src/t400_core.vhd:453:26  */
  assign n61_o = en_s[1];
  /* src/t400_core.vhd:469:3  */
  t400_sio_0_0 sio_b (
    .ck_i(ck_i),
    .ck_en_i(ck_en_s),
    .por_i(por_s),
    .res_i(res_s),
    .phi1_i(phi1_s),
    .out_en_i(out_en_s),
    .in_en_i(in_en_s),
    .op_i(sio_op_s),
    .en0_i(n64_o),
    .en3_i(n65_o),
    .a_i(a_s),
    .c_i(c_s),
    .si_i(si_i),
    .sio_o(sio_b_sio_o),
    .so_o(sio_b_so_o),
    .so_en_o(sio_b_so_en_o),
    .sk_o(sio_b_sk_o),
    .sk_en_o(sio_b_sk_en_o));
  /* src/t400_core.vhd:483:25  */
  assign n64_o = en_s[0];
  /* src/t400_core.vhd:484:25  */
  assign n65_o = en_s[3];
  /* src/t400_core.vhd:501:5  */
  t400_timer use_tim_timer_b (
    .ck_i(ck_i),
    .ck_en_i(ck_en_s),
    .por_i(por_s),
    .icyc_en_i(icyc_en_s),
    .op_i(skip_op_s),
    .c_o(use_tim_timer_b_c_o));
endmodule

