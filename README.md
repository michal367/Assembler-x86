# Assembler x86

Programs made in assembler for 16-bit Intel 8086 CPU, DOS operating system and MASM assembler.

## Programs

- hellwrld - hello world in assembler. Not as simple as in other languages 
- ascii - it shows ASCII number for given letter
- dec2hex - it converts decimal number to hexadecimal number
- args3 - example how program can receive 3 arguments separated by spaces
- xor - encrypts input file using xor and key and then saves result to output file (max 1kB)
- gfx_text - displays zoomed text in VGA mode - 320x200 pixels, 256 colors (it needs 'letters' folder with files)

## Usage

Programs were created using [DosBox](https://www.dosbox.com/) 0.74 and MASM (Microsoft Macro Assembler) version 6.11. In the 'MS programs' folder are located MASM files (ML.EXE, ML.ERR, LINK.EXE) for DOS and Windows. DOS also must have DOS-Extender (DOSXNT.EXE, DOSXNT.386). Additionaly there are also MS-DOS Debug (DEBUG.EXE) and MS-DOS Editor (EDIT.COM).

To assemble and link asm files run command (you can do it in DOS or Windows but you have to use relevant MASM):
```bash
ML program.asm
```
To start program you have to be in DOS. There you run command:
```bash
program.exe
```
Program can also have arguments which has to be given when executing, for example:
```bash
program.exe arg1 arg2
```
