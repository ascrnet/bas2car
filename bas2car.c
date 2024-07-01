/*--------------------------------------------------------------------*/
/* BAS2CAR                                                            */
/* by GienekP                                                         */
/* (c) 2024                                                           */
/*--------------------------------------------------------------------*/
#include <stdio.h>
/*--------------------------------------------------------------------*/
typedef unsigned char U8;
/*--------------------------------------------------------------------*/
#include "ataribas.h"
#include "runinit.h"
/*--------------------------------------------------------------------*/
void clearCAR(U8 *car, unsigned int max)
{
	unsigned int i;
	for (i=0; i<max; i++) {car[i]=0xFF;};
}
/*--------------------------------------------------------------------*/
void prepareBANKS(U8 *cardata)
{
	unsigned int i;
	// copy ATARI BASIC to BANK 0
	for (i=0; i<8192; i++) {cardata[i]=ataribas_rom[i];};
	// copy BAS2CAR code to BANK 1
	for (i=0; i<8192; i++) {cardata[8192+i]=runinit_bin[i];};
	// modyfi RUNINIT
	for (i=0; i<16; i++) {cardata[8192-16+i]=runinit_bin[8192-16+i];};
	// crazy maxflash old
	for (i=0; i<16; i++) {cardata[1024*1024-16+i]=runinit_bin[8192-16+i];};
}
/*--------------------------------------------------------------------*/
unsigned int loadBAS(const char *filename, U8 *buf, unsigned int size)
{
	unsigned int ret=0;
	FILE *pf;
	pf=fopen(filename,"rb");
	if (pf)
	{
		ret=fread(buf,sizeof(U8),size,pf);
		fclose(pf);
	};
	return ret;
}
/*--------------------------------------------------------------------*/
char upper(char c)
{
	if ((c>='a') && (c<='z'))
	{
		c-='a';
		c+='A';
	};
	return c;
}
/*--------------------------------------------------------------------*/
void ATARIfilename(const char *filename, U8 *name)
{
	unsigned int i,j=0,len=0,n;
	while (filename[len]) {len++;};
	n=len-4;
	if (n>8) {n=8;};
	for (i=0; i<n; i++) {name[j++]=upper(filename[i]);};
	for (i=0; i<4; i++) {name[j++]=upper(filename[len-4+i]);};
};
/*--------------------------------------------------------------------*/
U8 addBAS(const char *filename, const U8 *buf, unsigned int size, 
                    U8 *cardata, unsigned int *no, unsigned int *pos)
{
	U8 header[16]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	U8 ret=0;
	unsigned int i;
	if ((((*pos)+size)<(1024*1024)) && ((*no)<255))
	{
		if (*no) {ATARIfilename(filename,header);}
		else {ATARIfilename("AUTORUN.BAS",header);};
		header[12]=(size & 0xFF);
		header[13]=((size>>8) & 0xFF);
		header[14]=(((*pos)/8192) & 0xFF);
		header[15]=(((*pos)%8192) / 256);
		for (i=0; i<size; i++) {cardata[(*pos)+i]=buf[i];};
		for (i=0; i<sizeof(header); i++) {cardata[8192+1+(*no)*sizeof(header)+i]=header[i];};
		cardata[8192]++;
		(*pos)+=(((size/256)+1)*256);
		(*no)+=1;
		ret=1;
	};
	return ret;
}
/*--------------------------------------------------------------------*/
U8 saveCARtype(const char *filename, U8 *cardata, unsigned int carsize, U8 cartype)
{
	U8 header[16]={0x43, 0x41, 0x52, 0x54, 0x00, 0x00, 0x00, cartype,
		           0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00};
	U8 ret=0;
	unsigned int i,sum=0;
	FILE *pf;
	for (i=0; i<carsize; i++) {sum+=cardata[i];};
	header[8]=((sum>>24)&0xFF);
	header[9]=((sum>>16)&0xFF);
	header[10]=((sum>>8)&0xFF);
	header[11]=(sum&0xFF);
	pf=fopen(filename,"wb");
	if (pf)
	{
		i=fwrite(header,sizeof(U8),16,pf);
		if (i==16)
		{
			i=fwrite(cardata,sizeof(U8),carsize,pf);
			if (i==carsize) {ret=1;};			
		};
		fclose(pf);
	};
	return ret;
}
/*--------------------------------------------------------------------*/
U8 saveCAR(const char *filename, U8 *cardata, unsigned int size)
{
	U8 ret=0;
	if (size>(512*1024)) {ret=saveCARtype(filename,cardata,1024*1024,42);} else
	if (size>(256*1024)) {ret=saveCARtype(filename,cardata,512*1024,112);} else
	if (size>(128*1024)) {ret=saveCARtype(filename,cardata,256*1024,109);} else
	if (size>(64*1024)) {ret=saveCARtype(filename,cardata,128*1024,108);} else
	if (size>(32*1024)) {ret=saveCARtype(filename,cardata,64*1024,107);} else
	{ret=saveCARtype(filename,cardata,32*1024,106);}
	return ret;
}
/*--------------------------------------------------------------------*/
void bas2car(int argc, char *argv[])
{
	U8 cardata[1024*1024];
	U8 buf[64*1024];
	unsigned int i,pos=2*8192,no=0;
	clearCAR(cardata,sizeof(cardata));
	prepareBANKS(cardata);
	for (i=0; i<(argc-2); i++)
	{
		unsigned int size=loadBAS(argv[1+i],buf,sizeof(buf));
		if (size)
		{
			if (addBAS(argv[1+i],buf,size,cardata,&no,&pos))
			{
				printf("%i) Load \"%s\" (%i bytes)\n",no,argv[1+i],size);
			}
			else
			{
				printf("%i) Error \"%s\" (%i bytes)\n",no,argv[1+i],size);
			};
		}
		else
		{
			printf("Error \"%s\"\n",argv[1+i]);
		};
	};
	saveCAR(argv[argc-1],cardata,pos);
}
/*--------------------------------------------------------------------*/
int main( int argc, char* argv[] )
{	
	printf("BAS2CAR - ver: %s\n",__DATE__);
	if (argc>2)
	{
		bas2car(argc,argv);
	}
	else
	{
		printf("(c) GienekP\nuse:\n   bas2car start.bas file.car\n   bas2car autorun.bas intro.bas program.bas help.bas file.car\n");
	};
	printf("\n");
	return 0;
}
/*--------------------------------------------------------------------*/
