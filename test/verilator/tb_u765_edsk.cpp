// tb_u765_edsk.cpp - Verilator testbench that mounts an EDSK image in the
// MiST u765.sv core (gyurco/Amstrad_MiST, u765/ folder), reads every track
// with a multi-sector READ DATA and compares the result against a raw image.
//
// Build (Verilator 5.x):
//   verilator -Wno-fatal -Wno-lint -Wno-style --top-module u765_test --cc --exe \
//             --build -O2 u765_test.sv u765.sv tb_u765_edsk.cpp -o tb
// Run:
//   ./obj_dir/tb DISK.dsk DISK.img <heads> <cylinders>
//
// Note: Verilator 5.020 crashes on the initialised local reg in the
// SECTOR_SIZE function of u765.sv; for simulation split it into
//   reg [15:0] logical_size;  logical_size = (16'h80 << ...);
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>
#include "Vu765_test.h"
#include "verilated.h"
static Vu765_test *tb; static unsigned char sdbuf[512]; static FILE *edsk;
static int reading, read_ptr, sd_rd_prev;
static void tick(int c){ tb->clk_sys=c; tb->eval();
  if(c){ if(reading){tb->sd_ack=1;tb->sd_buff_wr=1;tb->sd_buff_dout=sdbuf[read_ptr];tb->sd_buff_addr=read_ptr;
           if(++read_ptr==512)reading=0;} else {tb->sd_ack=0;tb->sd_buff_wr=0;}
         if(tb->sd_rd!=sd_rd_prev && tb->sd_rd){ memset(sdbuf,0,512); fseek(edsk,(long)tb->sd_lba<<9,SEEK_SET);
           fread(sdbuf,1,512,edsk); reading=1; read_ptr=0; }
         sd_rd_prev=tb->sd_rd; } }
static void cyc(){tick(1);tick(0);}
static void wait(int n){while(n--)cyc();}
static int status(){tb->a0=0;cyc();tb->nRD=0;tb->nWR=1;cyc();cyc();int d=tb->dout;tb->nRD=1;cyc();return d;}
static void send(int b){while((status()&0xcf)!=0x80);tb->a0=1;cyc();tb->nRD=1;tb->nWR=0;tb->din=b;cyc();cyc();tb->nWR=1;cyc();}
static int rbyte(){while((status()&0xcf)!=0xc0);tb->a0=1;cyc();tb->nRD=0;tb->nWR=1;cyc();cyc();int b=tb->dout;tb->nRD=1;cyc();return b;}
static void result(int *r){for(int i=0;i<7;i++)r[i]=rbyte();}
static void sense_int(){send(0x08); rbyte(); rbyte();}
int main(int argc,char**argv){
  if(argc<5){printf("usage: tb image.dsk image.img heads cyls\n");return 1;}
  edsk=fopen(argv[1],"rb"); FILE*rf=fopen(argv[2],"rb"); int heads=atoi(argv[3]), cyls=atoi(argv[4]);
  std::vector<unsigned char> raw(cyls*heads*10*512); fread(raw.data(),1,raw.size(),rf);
  fseek(edsk,0,SEEK_END); long fsz=ftell(edsk);
  tb=new Vu765_test; tb->reset=1; tb->ce=1; tb->nWR=1; tb->nRD=1; tb->fast=1; cyc();cyc();cyc(); tb->reset=0;
  tb->img_size=fsz; tb->img_mounted=1; cyc(); tb->img_mounted=0; wait(1000);
  tb->motor=1; tb->ready=1; tb->available=1; wait(100000);
  send(0x07); send(0x00); wait(2000); sense_int();
  long bad=0, total=0; int r[7];
  for(int c=0;c<cyls;c++){
    send(0x0f); send(0x00); send(c); wait(2000); sense_int();
    for(int h=0;h<heads;h++){
      // READ ID once (shows physical sector under the head)
      send(0x4a); send(h<<2); result(r);
      if(c==0||c==cyls-1) printf("C%02d H%d READ ID -> ST0=%02x C=%d H=%d R=%d N=%d\n",c,h,r[0],r[3],r[4],r[5],r[6]);
      // READ DATA (MFM) sectors 1..10 in one multi-sector command
      send(0x46); send(h<<2); send(c); send(h); send(1); send(2); send(10); send(0x2a); send(0xff);
      std::vector<unsigned char> got;
      while(true){ int st; while(((st=status())&0xcf)!=0xc0); if(!(st&0x20))break;
        tb->a0=1;tb->nRD=0;tb->nWR=1;cyc();cyc();got.push_back(tb->dout);tb->nRD=1;cyc(); }
      result(r);
      size_t base=((size_t)(c*heads+h))*10*512; int mism=0;
      for(size_t i=0;i<5120;i++){ if(i>=got.size()||got[i]!=raw[base+i]) mism++; }
      if(got.size()!=5120||mism||(r[0]&0xc0)!=0x40&&(r[0]&0xc0)!=0x00){
        printf("C%02d H%d: got %zu bytes, %d mismatches, ST0=%02x ST1=%02x ST2=%02x R=%d\n",c,h,got.size(),mism,r[0],r[1],r[2],r[5]); bad++; }
      total++;
    }
  }
  printf("%s: %ld/%ld tracks OK\n",argv[1],total-bad,total); return bad?1:0;
}
