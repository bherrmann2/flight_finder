/*
 * Main requires no other files. 
 * 
 * TODO 
 * __ binary example file
 * ___ Unit Tests.
 * ___make utils static.
 */
import java.awt.*;

import java.awt.event.*;
import java.nio.ByteBuffer;

import javax.swing.*;


public class Main extends JFrame implements ActionListener
{
	public final static String VERSION = "0.1";
	protected Utils utils = new Utils();
	protected JButton decodeButton = new JButton("Decode");
	protected JTextArea in = new JTextArea();
	protected JEditorPane out = new JEditorPane("text/html","");
	
	String STARTUP_CONTENT = "Cut and paste RFTRACE or PCAP Hexdump of DV content here,\nThen select the 'Decode' menu option to decode it in the other window.\nTo view example Content use the 'Test' menu.\n";
      
	//FIXME - Read these from a resource file or at least put them in their own static class
	String HELP_TEXT = ""
		+"DVDecoder version " + VERSION + "\n"
		+"==========================================================================\n"
		+"To decode dv content, cut and paste a hexdump of the content in the left\n"
		+"window and choose the 'Decode' menu option.  The tool will accept hexdumps\n"
		+"from RFTRACE or from Wireshark.  To see what these hexdumps should look like\n"
		+"one can use the Test->RFTRACE Example or the Test->PCAP Example menu options\n"
		+"to load example content.  GZIPED content will automatically be unzipped.\n"
		+"\n"
		+"In the BREW client, DV content can be saved using the SAVE_CONTENT_STREAM\n"
		+"debug feature.  To load these files use the 'Load' Menu item.  The binary\n"
		+"content will be loaded and displayed in the left window, after which the  \n"
		+"user can use the 'Decode' menu option to actually decode it. \n"
		+"\n"
		+"\n"
		+"\n"
		+"\n"
		+"FAQ\n"
		+"===\n"
		+"* How do I get a hexdump of a wireshark trace?\n"
		+"  a. Right click on a packet that contains a DV request or content." 
		+"  b. Choose the 'Follow TCP Stream' option.\n" 
		+"  c. In this window click the 'Hex Dump' radio buttton.\n" 
		+"  d. Cut and paste the hexdump content into the left window of this tool.\n" 
		+"\n" 
		+"\n" 
		+"\n" 
		+"\n" 
		+"\n" 
		+"\n" 
		+"\n" 
		+"\n" 
		+"\n" 
		+"\n" 
		
		
		+"";
		
	
	String PCAP_EXAMPLE = ""
		+ "00000000  47 45 54 20 68 74 74 70  3a 2f 2f 66 72 6f 6f 67 GET http ://froog\n"
		+ "00000010  6c 65 2e 63 6f 6d 3f 64  6a 66 66 2f 20 48 54 54 le.com?d jff/ HTT\n"
		+ "00000020  50 2f 31 2e 31 0d 0a 68  6f 73 74 3a 20 66 72 6f P/1.1..h ost: fro\n"
		+ "00000030  6f 67 6c 65 2e 63 6f 6d  0d 0a 58 2d 50 49 44 3a ogle.com ..X-PID:\n"
		+ "00000040  20 30 0d 0a 75 73 65 72  2d 61 67 65 6e 74 3a 20  0..user -agent: \n"
		+ "00000050  6e 6f 76 61 72 72 61 6d  69 63 72 6f 2f 38 2e 31 novarram icro/8.1\n"
		+ "00000060  20 44 20 28 4c 47 2f 56  4e 35 33 30 29 0d 0a 50  D (LG/V N530)..P\n"
		+ "00000070  72 6f 78 79 2d 41 75 74  68 6f 72 69 7a 61 74 69 roxy-Aut horizati\n"
		+ "00000080  6f 6e 3a 20 42 61 73 69  63 20 4d 54 6b 7a 4d 7a on: Basi c MTkzMz\n"
		+ "00000090  59 77 4e 6a 59 34 4d 7a  70 32 65 6e 63 3d 0d 0a YwNjY4Mz p2enc=..\n"
		+ "000000A0  6e 6f 76 61 72 72 61 2d  6d 64 6e 3a 20 63 46 47 novarra- mdn: cFG\n"
		+ "000000B0  4e 36 41 6a 79 42 43 45  56 71 51 3d 3d 0d 0a 78 N6AjyBCE VqQ==..x\n"
		+ "000000C0  2d 6e 6f 76 61 72 72 61  2d 6d 61 6b 65 2d 6d 6f -novarra -make-mo\n"
		+ "000000D0  64 65 6c 3a 20 4c 47 2f  56 4e 35 33 30 0d 0a 78 del: LG/ VN530..x\n"
		+ "000000E0  2d 6e 6f 76 61 72 72 61  2d 63 75 73 74 6f 6d 65 -novarra -custome\n"
		+ "000000F0  72 3a 20 76 65 72 69 7a  6f 6e 0d 0a 78 2d 77 61 r: veriz on..x-wa\n"
		+ "00000100  70 2d 70 72 6f 66 69 6c  65 3a 20 68 74 74 70 3a p-profil e: http:\n"
		+ "00000110  2f 2f 75 61 70 72 6f 66  2e 76 74 65 78 74 2e 63 //uaprof .vtext.c\n"
		+ "00000120  6f 6d 2f 6c 67 2f 76 6e  35 33 30 2f 76 6e 35 33 om/lg/vn 530/vn53\n"
		+ "00000130  30 2e 78 6d 6c 0d 0a 6e  6f 76 61 72 72 61 2d 75 0.xml..n ovarra-u\n"
		+ "00000140  73 65 72 2d 61 67 65 6e  74 3a 20 4e 6f 76 61 72 ser-agen t: Novar\n"
		+ "00000150  72 61 2f 38 2e 31 2e 32  2e 32 37 20 44 28 42 52 ra/8.1.2 .27 D(BR\n"
		+ "00000160  45 57 2d 4f 50 54 3b 34  31 38 38 39 33 37 37 32 EW-OPT;4 18893772\n"
		+ "00000170  3b 55 53 29 42 52 45 57  5f 30 78 30 31 30 39 45 ;US)BREW _0x0109E\n"
		+ "00000180  34 45 35 0d 0a 61 63 63  65 70 74 3a 20 74 65 78 4E5..acc ept: tex\n"
		+ "00000190  74 2f 78 6d 6c 2c 74 65  78 74 2f 68 74 6d 6c 2c t/xml,te xt/html,\n"
		+ "000001A0  69 6d 61 67 65 2f 70 6e  67 2c 69 6d 61 67 65 2f image/pn g,image/\n"
		+ "000001B0  6a 70 67 2c 69 6d 61 67  65 2f 6a 70 65 67 2c 69 jpg,imag e/jpeg,i\n"
		+ "000001C0  6d 61 67 65 2f 6d 6e 67  2c 76 69 64 65 6f 2f 33 mage/mng ,video/3\n"
		+ "000001D0  67 70 70 0d 0a 61 63 63  65 70 74 2d 65 6e 63 6f gpp..acc ept-enco\n"
		+ "000001E0  64 69 6e 67 3a 20 67 7a  69 70 0d 0a 61 63 63 65 ding: gz ip..acce\n"
		+ "000001F0  70 74 2d 6c 61 6e 67 75  61 67 65 3a 20 65 6e 0d pt-langu age: en.\n"
		+ "00000200  0a 63 61 63 68 65 2d 63  6f 6e 74 72 6f 6c 3a 20 .cache-c ontrol: \n"
		+ "00000210  6e 6f 2d 63 61 63 68 65  0d 0a 6e 6f 76 61 72 72 no-cache ..novarr\n"
		+ "00000220  61 2d 64 65 76 69 63 65  2d 69 64 3a 20 63 46 71 a-device -id: cFq\n"
		+ "00000230  4d 36 41 33 78 42 69 4d  5a 72 67 3d 3d 0d 0a 4e M6A3xBiM Zrg==..N\n"
		+ "00000240  4f 56 41 52 52 41 2d 44  56 2d 46 4f 4e 54 2d 48 OVARRA-D V-FONT-H\n"
		+ "00000250  41 53 48 3a 20 36 63 61  30 64 35 66 30 63 39 39 ASH: 6ca 0d5f0c99\n"
		+ "00000260  34 63 37 34 61 32 64 39  33 36 61 39 33 32 36 61 4c74a2d9 36a9326a\n"
		+ "00000270  30 37 65 37 36 0d 0a 6e  6f 76 61 72 72 61 2d 70 07e76..n ovarra-p\n"
		+ "00000280  6c 61 74 66 6f 72 6d 2d  69 64 3a 20 30 0d 0a 6e latform- id: 0..n\n"
		+ "00000290  6f 76 61 72 72 61 2d 63  61 72 72 69 65 72 2d 69 ovarra-c arrier-i\n"
		+ "000002A0  64 3a 20 30 0d 0a 6e 6f  76 61 72 72 61 2d 64 65 d: 0..no varra-de\n"
		+ "000002B0  76 69 63 65 2d 74 79 70  65 3a 20 42 52 45 57 2d vice-typ e: BREW-\n"
		+ "000002C0  4f 50 54 0d 0a 6e 6f 76  61 72 72 61 2d 63 6c 69 OPT..nov arra-cli\n"
		+ "000002D0  65 6e 74 2d 61 74 74 72  69 62 75 74 65 73 3a 20 ent-attr ibutes: \n"
		+ "000002E0  42 69 74 2d 44 65 70 74  68 3d 36 2c 43 6f 6c 6f Bit-Dept h=6,Colo\n"
		+ "000002F0  72 2d 4d 6f 64 65 6c 3d  50 41 4c 45 54 54 45 2c r-Model= PALETTE,\n"
		+ "00000300  52 53 53 3d 56 32 2c 73  6e 61 70 73 68 6f 74 2c RSS=V2,s napshot,\n"
		+ "00000310  69 6d 67 69 6e 64 65 78  2c 66 61 76 69 63 6f 6e imgindex ,favicon\n"
		+ "00000320  2c 48 54 4d 4c 3d 31 2e  30 2c 4e 6f 76 61 72 72 ,HTML=1. 0,Novarr\n"
		+ "00000330  61 2d 44 56 49 2d 56 65  72 73 69 6f 6e 3d 32 2e a-DVI-Ve rsion=2.\n"
		+ "00000340  30 2c 66 6f 6e 74 2d 68  65 69 67 68 74 3d 28 38 0,font-h eight=(8\n"
		+ "00000350  7c 31 30 7c 31 32 29 2c  64 70 69 3d 39 36 2c 43 |10|12), dpi=96,C\n"
		+ "00000360  53 53 3d 31 2e 30 0d 0a  6e 6f 76 61 72 72 61 2d SS=1.0.. novarra-\n"
		+ "00000370  75 73 65 72 2d 70 72 65  66 73 3a 20 56 69 65 77 user-pre fs: View\n"
		+ "00000380  2d 4d 6f 64 65 3d 64 76  2c 46 6f 6e 74 54 61 62 -Mode=dv ,FontTab\n"
		+ "00000390  6c 65 3d 31 2c 4a 61 76  61 73 63 72 69 70 74 2c le=1,Jav ascript,\n"
		+ "000003A0  43 6f 6f 6b 69 65 73 2c  49 6d 61 67 65 2d 46 69 Cookies, Image-Fi\n"
		+ "000003B0  74 2d 53 69 7a 65 3d 32  33 31 78 33 30 34 2c 42 t-Size=2 31x304,B\n"
		+ "000003C0  61 74 63 68 2d 44 61 74  61 2d 53 69 7a 65 3d 30 atch-Dat a-Size=0\n"
		+ "000003D0  2c 4e 61 76 2d 49 63 6f  6e 73 3d 31 30 2c 43 68 ,Nav-Ico ns=10,Ch\n"
		+ "000003E0  75 6e 6b 65 64 2c 41 75  74 6f 4a 75 6d 70 2c 50 unked,Au toJump,P\n"
		+ "000003F0  69 63 6f 6c 6f 56 32 2e  35 2c 46 75 6c 6c 53 63 icoloV2. 5,FullSc\n"
		+ "00000400  72 65 65 6e 56 69 64 65  6f 0d 0a 52 65 66 65 72 reenVide o..Refer\n"
		+ "00000410  65 72 3a 20 68 74 74 70  3a 2f 2f 73 63 69 73 73 er: http ://sciss\n"
		+ "00000420  6f 72 73 6f 66 74 2e 63  6f 6d 2f 6e 6f 76 61 72 orsoft.c om/novar\n"
		+ "00000430  72 61 2f 74 65 73 74 2e  68 74 6d 6c 0d 0a 63 6f ra/test. html..co\n"
		+ "00000440  6e 6e 65 63 74 69 6f 6e  3a 20 6b 65 65 70 2d 61 nnection : keep-a\n"
		+ "00000450  6c 69 76 65 0d 0a 55 53  45 52 49 50 3a 20 31 30 live..US ERIP: 10\n"
		+ "00000460  2e 32 30 30 2e 32 30 31  2e 32 31 39 0d 0a 0d 0a .200.201 .219....\n"
		+ "                                                                              00000000  48 54 54 50 2f 31 2e 31  20 32 30 30 20 4f 4b 0d HTTP/1.1  200 OK.\n"
		+ "                                                                              00000010  0a 44 61 74 65 3a 20 46  72 69 2c 20 32 35 20 4a .Date: F ri, 25 J\n"
		+ "                                                                              00000020  75 6e 20 32 30 31 30 20  31 39 3a 32 39 3a 35 35 un 2010  19:29:55\n"
		+ "                                                                              00000030  20 47 4d 54 0d 0a 43 6f  6e 74 65 6e 74 2d 54 79  GMT..Co ntent-Ty\n"
		+ "                                                                              00000040  70 65 3a 20 74 65 78 74  2f 6e 6f 76 61 72 72 61 pe: text /novarra\n"
		+ "                                                                              00000050  0d 0a 43 6f 6e 74 65 6e  74 2d 4c 6f 63 61 74 69 ..Conten t-Locati\n"
		+ "                                                                              00000060  6f 6e 3a 20 68 74 74 70  3a 2f 2f 77 77 77 2e 67 on: http ://www.g\n"
		+ "                                                                              00000070  6f 6f 67 6c 65 2e 63 6f  6d 2f 70 72 6f 64 75 63 oogle.co m/produc\n"
		+ "                                                                              00000080  74 73 0d 0a 4e 6f 76 61  72 72 61 2d 43 61 63 68 ts..Nova rra-Cach\n"
		+ "                                                                              00000090  65 2d 43 6f 6e 74 72 6f  6c 3a 20 6d 61 78 2d 61 e-Contro l: max-a\n"
		+ "                                                                              000000A0  67 65 3d 30 0d 0a 43 61  63 68 65 2d 43 6f 6e 74 ge=0..Ca che-Cont\n"
		+ "                                                                              000000B0  72 6f 6c 3a 20 6e 6f 2d  74 72 61 6e 73 66 6f 72 rol: no- transfor\n"
		+ "                                                                              000000C0  6d 2c 20 6d 61 78 2d 61  67 65 3d 30 0d 0a 4e 6f m, max-a ge=0..No\n"
		+ "                                                                              000000D0  76 61 72 72 61 2d 50 61  67 65 2d 49 64 3a 20 31 varra-Pa ge-Id: 1\n"
		+ "                                                                              000000E0  38 38 39 30 38 39 31 39  0d 0a 4e 6f 76 61 72 72 88908919 ..Novarr\n"
		+ "                                                                              000000F0  61 2d 55 52 49 3a 20 68  74 74 70 3a 2f 2f 66 72 a-URI: h ttp://fr\n"
		+ "                                                                              00000100  6f 6f 67 6c 65 2e 63 6f  6d 2f 0d 0a 54 72 61 6e oogle.co m/..Tran\n"
		+ "                                                                              00000110  73 66 65 72 2d 45 6e 63  6f 64 69 6e 67 3a 20 63 sfer-Enc oding: c\n"
		+ "                                                                              00000120  68 75 6e 6b 65 64 0d 0a  53 65 72 76 65 72 3a 20 hunked.. Server: \n"
		+ "                                                                              00000130  4a 65 74 74 79 28 36 2e  31 2e 31 32 72 63 31 29 Jetty(6. 1.12rc1)\n"
		+ "                                                                              00000140  0d 0a 0d 0a 38 35 39 0d  0a                      ....859. .\n"
		+ "                                                                              00000149  43 6f 6e 74 65 6e 74 2d  54 79 70 65 3a 20 64 76 Content- Type: dv\n"
		+ "                                                                              00000159  0d 0a 43 6f 6e 74 65 6e  74 2d 4c 6f 63 61 74 69 ..Conten t-Locati\n"
		+ "                                                                              00000169  6f 6e 3a 20 68 74 74 70  3a 2f 2f 77 77 77 2e 67 on: http ://www.g\n"
		+ "                                                                              00000179  6f 6f 67 6c 65 2e 63 6f  6d 2f 70 72 6f 64 75 63 oogle.co m/produc\n"
		+ "                                                                              00000189  74 73 0d 0a 4e 6f 76 61  72 72 61 2d 43 61 63 68 ts..Nova rra-Cach\n"
		+ "                                                                              00000199  65 2d 43 6f 6e 74 72 6f  6c 3a 20 6d 61 78 2d 61 e-Contro l: max-a\n"
		+ "                                                                              000001A9  67 65 3d 30 0d 0a 4e 6f  76 61 72 72 61 2d 50 61 ge=0..No varra-Pa\n"
		+ "                                                                              000001B9  67 65 2d 49 64 3a 20 31  38 38 39 30 38 39 31 39 ge-Id: 1 88908919\n"
		+ "                                                                              000001C9  0d 0a 4e 6f 76 61 72 72  61 2d 55 52 49 3a 20 68 ..Novarr a-URI: h\n"
		+ "                                                                              000001D9  74 74 70 3a 2f 2f 66 72  6f 6f 67 6c 65 2e 63 6f ttp://fr oogle.co\n"
		+ "                                                                              000001E9  6d 2f 0d 0a 43 6f 6e 74  65 6e 74 2d 45 6e 63 6f m/..Cont ent-Enco\n"
		+ "                                                                              000001F9  64 69 6e 67 3a 20 67 7a  69 70 0d 0a 4e 6f 76 61 ding: gz ip..Nova\n"
		+ "                                                                              00000209  72 72 61 2d 43 6f 6e 74  65 6e 74 2d 4c 65 6e 67 rra-Cont ent-Leng\n"
		+ "                                                                              00000219  74 68 3a 20 33 39 32 39  0d 0a 43 6f 6e 74 65 6e th: 3929 ..Conten\n"
		+ "                                                                              00000229  74 2d 4c 65 6e 67 74 68  3a 20 31 38 39 35 0d 0a t-Length : 1895..\n"
		+ "                                                                              00000239  0d 0a 1f 8b 08 00 00 00  00 00 00 00 85 57 4b 8c ........ .....WK.\n"
		+ "                                                                              00000249  1c 57 15 3d af bb e7 63  8f bb 33 63 f7 38 fe cc .W.=...c ..3c.8..\n"
		+ "                                                                              00000259  d8 65 3b 19 9b 94 e6 1b  64 e2 c8 c3 93 67 91 f4 .e;..... d....g..\n"
		+ "                                                                              00000269  20 9c 58 36 10 94 28 f4  54 77 bf 99 2e a7 ba aa  .X6..(. Tw......\n"
		+ "                                                                              00000279  5d 55 3d ed 21 12 1b 58  45 60 10 04 5a 96 b2 ce ]U=.!..X E`..Z...\n"
		+ "                                                                              00000289  22 62 03 06 29 48 08 23  40 e2 93 d9 60 89 8f c4 \"b..)H.# @...`...\n"
		+ "                                                                              00000299  02 b1 b2 60 61 09 65 83  60 61 ee ad 57 55 7e 2d ...`a.e. `a..WU~-\n"
		+ "                                                                              000002A9  35 62 64 77 77 bd ba e7  be 73 cf 79 ef d5 2d 08 5bdww... .s.y..-.\n"
		+ "                                                                              000002B9  00 97 20 50 2a a1 08 fa  57 40 84 12 7d 3e 87 31 .. P*... W@..}>.1\n"
		+ "                                                                              000002C9  fa 5c c4 38 7d 16 30 81  d9 97 83 60 c7 53 d6 b5 .\\.8}.0. ...`.S..\n"
		+ "                                                                              000002D9  30 68 f5 9a b1 75 43 39  61 b3 4d b7 80 7b 14 3a 0h...uC9 a.M..{.:\n"
		+ "                                                                              000002E9  d7 8e e3 ee 8b cb cb 1d  c7 f5 96 76 92 d0 a5 66 ........ ...v...f\n"
		+ "                                                                              000002F9  d0 49 ae 97 71 34 bd db  ef f7 cd 9b 78 6e f4 b8 .I..q4.. ....xn..\n"
		+ "                                                                              00000309  eb c7 de b2 f2 eb bd 68  b9 ab a7 8b 96 71 e6 ff .......h .....q..\n"
		+ "                                                                              00000319  c6 fe af 74 79 0e 33 96  8a ad bc 01 3c 7e fc 98 ...ty.3. ....<~..\n"
		+ "                                                                              00000329  15 40 52 3d ee de bd 3b  c0 c4 51 ba 02 56 14 48 .@R=...; ..Q..V.H\n"
		+ "                                                                              00000339  96 49 aa f0 24 aa f9 e8  45 05 21 48 16 16 e8 c9 .I..$... E.!H....\n"
		+ "                                                                              00000349  e8 65 85 82 40 83 46 2f  18 a3 1b 0a 45 81 77 69 .e..@.F/ ....E.wi\n"
		+ "                                                                              00000359  d4 32 46 6b 0a 25 81 fb  d9 e8 29 3d 7a bd 9c 7c .2Fk.%.. ..)=z..|\n"
		+ "                                                                              00000369  4d 56 50 96 6d 6f 5d f9  0b b1 d3 58 df ee 28 8c MVP.mo]. ...X..(.\n"
		+ "                                                                              00000379  09 b1 4a c1 67 8d 14 af  29 8c 17 c5 9b 34 3a 8f ..J.g... )....4:.\n"
		+ "                                                                              00000389  aa f8 32 7d 97 e8 fb 2b  e4 55 11 4f 0d b0 a0 a3 ..2}...+ .U.O....\n"
		+ "                                                                              00000399  7e a1 53 2e 54 30 1b b5  83 6e d7 f5 77 3c 37 8a ~.S.T0.. .n..w<7.\n"
		+ "                                                                              000003A9  75 fa fa e7 6f 28 4c 88  e2 77 08 ac 50 bd 8b 69 u...o(L. .w..P..i\n"
		+ "                                                                              000003B9  0d fa db 0c 0a 93 a8 42  dc 52 98 14 f8 25 ee 15 .......B .R...%..\n"
		+ "                                                                              000003C9  5e c0 e9 f7 b2 99 3f 56  38 20 0a ff c1 8f 70 05 ^.....?V 8 ....p.\n"
		+ "                                                                              000003D9  a7 f8 f6 03 ba 4d 02 fe  f6 4f ff 04 66 66 f6 8b .....M.. .O..ff..\n"
		+ "                                                                              000003E9  24 d8 2c ce 61 76 ac 50  a6 9f 45 d6 0e c5 d7 54 $.,.av.P ..E....T\n"
		+ "                                                                              000003F9  03 fa 2f 09 59 a2 90 2f  62 b6 4c 32 16 59 46 8c ../.Y../ b.L2.YF.\n"
		+ "                                                                              00000409  6f 76 9c 1d 15 99 31 0d  8a 79 87 63 1a 14 73 81 ov....1. .y.c..s.\n"
		+ "                                                                              00000419  63 be e0 b6 54 30 14 f3  5d 8a f9 31 c7 bc 4b 31 c...T0.. ]..1..K1\n"
		+ "                                                                              00000429  24 26 4a 57 9d ee 50 c4  7d 8a f8 2b 47 dc cf 22 $&JW..P. }..+G..\"\n"
		+ "                                                                              00000439  5e 51 7d 1d 51 12 65 fc  9d 46 d7 69 74 f2 46 aa ^Q}.Q.e. .F.it.F.\n"
		+ "                                                                              00000449  4f 29 05 92 e2 b3 e2 06  01 e9 47 91 a5 c7 d8 cb O)...... ..G.....\n"
		+ "                                                                              00000459  bc 92 8d dc e2 4b 14 f2  36 87 bc 49 21 f3 9c bb .....K.. 6..I!...\n"
		+ "                                                                              00000469  13 84 6a 4c 94 c9 88 09  36 02 05 29 d3 05 c6 32 ..jL.... 6..)...2\n"
		+ "                                                                              00000479  5e c4 29 60 7f 7f 3f 13  55 88 c2 bf 69 eb 08 9c ^.)`..?. U...i...\n"
		+ "                                                                              00000489  4e 46 f8 87 ce 4c 9e cc  16 ff 95 48 48 3f 8b 6c NF...L.. ...HH?.l\n"
		+ "                                                                              00000499  0f a6 af ee 59 19 49 eb  b3 e4 e2 b8 d8 c5 8a a8 ....Y.I. ........\n"
		+ "                                                                              000004A9  c2 67 f5 37 c2 bf 8c a1  5c f8 01 fe 80 af e3 30 .g.7.... \\......0\n"
		+ "                                                                              000004B9  8e 5f 69 ed 3a 7e 53 b5  a4 4c 77 ab 94 e9 76 c5 ._i.:~S. .Lw...v.\n"
		+ "                                                                              000004C9  fc 4b ef 8f 15 4a 62 80  0b 89 a1 a2 98 2f 92 a7 .K...Jb. ...../..\n"
		+ "                                                                              000004D9  9d 14 55 4f f7 4b 3d 4a  30 0a 07 45 96 ba 2c 3e ..UO.K=J 0..E..,>\n"
		+ "                                                                              000004E9  24 d1 be 89 39 1c d3 09  ad ed 20 b4 a2 b8 b7 bd $...9... .. .....\n"
		+ "                                                                              000004F9  6d c5 81 d5 e8 ed 2d 69  71 51 c6 6f c4 71 b1 43 m.....-i qQ.o.q.C\n"
		+ "                                                                              00000509  d4 d7 af 58 db aa 6f 05  14 d1 56 96 1b ab 4e 64 ...X..o. ..V...Nd\n"
		+ "                                                                              00000519  85 aa a9 68 2f ee 11 bc  e7 b7 ac be 1b b7 ad 91 ...h/... ........\n"
		+ "                                                                              00000529  e7 cb 8b 89 24 03 5c d2  6c cf e4 6c 2f 64 9b 5a ....$.\\. l..l/d.Z\n"
		+ "                                                                              00000539  de 5a ef 38 7b b1 b3 63  87 6a 3b 74 77 54 e8 c4 .Z.8{..c .j;twT..\n"
		+ "                                                                              00000549  41 b8 10 39 9d ae a7 6e  ad af 2a 4c 09 e2 b2 0a A..9...n ..*L....\n"
		+ "                                                                              00000559  8f 37 d0 92 ce 73 3e cf  33 6f e4 f1 08 63 07 ae .7...s>. 3o...c..\n"
		+ "                                                                              00000569  67 82 0f 09 f1 12 81 17  19 bc a2 c1 8b 39 f8 b4 g....... .....9..\n"
		+ "                                                                              00000579  01 6e 07 9e b2 bb 3d bf  d9 36 e1 65 21 7e 45 70 .n....=. .6.e!~Ep\n"
		+ "                                                                              00000589  c9 f0 8b 1a fe 7c 0e 7f  d6 80 6f bb a1 ea d3 7f .....|.. ..o.....\n"
		+ "                                                                              00000599  3b 6a 3a be af 86 0a a8  88 c2 06 25 79 dd e0 70 ;j:..... ...%y..p\n"
		+ "                                                                              000005A9  69 24 87 d0 71 7d bb 11  04 71 64 c2 9f 12 85 9f i$..q}.. .qd.....\n"
		+ "                                                                              000005B9  13 fc 12 aa 6c ca 1a 0b  81 aa d6 4c 4a 53 b4 32 ....l... ...LJS.2\n"
		+ "                                                                              000005C9  95 ba c6 a5 e2 00 4b 21  25 69 51 26 fe 6b cc 1f ......K! %iQ&.k..\n"
		+ "                                                                              000005D9  53 5c a1 94 49 89 65 22  b4 c6 84 30 93 11 97 32 S\\..I.e\" ...0...2\n"
		+ "                                                                              000005E9  65 5e a6 d9 d6 78 36 4c  31 1f 29 13 42 03 2c 6a e^...x6L 1.).B.,j\n"
		+ "                                                                              000005F9  e6 1b 39 f3 39 83 79 37  e8 36 83 d0 37 69 4f b3 ..9.9.y7 .6..7iO.\n"
		+ "                                                                              00000609  6d 35 3a 2c a8 ea 4f 6a  6c 2d c7 9e 33 6d 0b fa m5:,..Oj l-..3m..\n"
		+ "                                                                              00000619  76 e8 46 ca be a9 1c 7f  a8 f2 19 36 af 86 57 39 v.F..... ...6..W9\n"
		+ "                                                                              00000629  c5 f3 3a c5 2b 79 8a b3  46 8a 28 56 4e c7 6e 7a ..:.+y.. F.(VN.nz\n"
		+ "                                                                              00000639  94 60 58 fa c3 ec 5f 0d  d7 0d e9 3f 37 52 fa a4 .`X..._. ...?7R..\n"
		+ "                                                                              00000649  f6 96 ed b8 43 f0 23 ec  5c 0d 97 19 fe 29 0d 7f ....C.#. \\....)..\n"
		+ "                                                                              00000659  3d 87 2f 0c d5 1f d2 79  4f 2b a8 19 78 41 68 c7 =./....y O+..xAh.\n"
		+ "                                                                              00000669  bb 66 96 2a 1b 58 c3 1b  da c0 4d 96 04 13 a9 62 .f.*.X.. ..M....b\n"
		+ "                                                                              00000679  ec d9 26 57 88 69 d2 81  fc 24 21 a4 4c 94 60 eb ..&W.i.. .$!.L.`.\n"
		+ "                                                                              00000689  36 99 3a 2a 49 7d 52 a6  05 b2 7b 9b 4c 0a 53 9a 6.:*I}R. ..{.L.S.\n"
		+ "                                                                              00000699  b6 94 c4 9b 7d db e4 49  70 24 63 43 08 a6 23 65 ....}..I p$cC..#e\n"
		+ "                                                                              000006A9  bc 9b f3 6f 8e e4 df 71  e2 d0 bd 6d 47 3d 7a c6 ...o...q ...mG=z.\n"
		+ "                                                                              000006B9  38 51 a4 86 6c 98 65 27  eb b8 69 d8 e0 8e b6 a1 8Q..l.e' ..i.....\n"
		+ "                                                                              000006C9  e7 c7 8e 6f 7b 41 ec 06  43 6b e1 28 1b 59 c7 67 ...o{A.. Ck.(.Y.g\n"
		+ "                                                                              000006D9  0c 1b 82 91 36 c4 4e b3  1d 74 54 3c ec e2 d3 ec ....6.N. .tT<....\n"
		+ "                                                                              000006E9  62 9d 1e 59 04 5f d5 f0  5e 0e b7 4c 17 43 d5 55 b..Y._.. ^..L.C.U\n"
		+ "                                                                              000006F9  76 c7 79 6b                                      v.yk\n"
		+ "                                                                              000006FD  18 7f 8c 6d ac a3 c6 f8  17 34 fe ed 1c 7f de c0 ...m.... .4......\n"
		+ "                                                                              0000070D  b7 dc a8 1b 44 da 48 a7  43 bb 6a 48 87 e3 ec 63 ....D.H. C.jH...c\n"
		+ "                                                                              0000071D  1d b1 f6 71 8b 05 c1 61  ad 1c ed 9e 5c 3a b6 74 ...q...a ....\\:.t\n"
		+ "                                                                              0000072D  8b 6b 25 df 12 41 a4 d4  8a b0 a1 5b 5c 05 0e 3e .k%..A.. ...[\\..>\n"
		+ "                                                                              0000073D  a9 93 cd dc 62 6a 38 94  b0 97 32 a1 cf 6e 6e f1 ....bj8. ..2..nn.\n"
		+ "                                                                              0000074D  54 38 f2 84 14 f9 a9 59  f1 fc 7d bd ab bb ae e3 T8.....Y ..}.....\n"
		+ "                                                                              0000075D  07 34 03 d1 e4 89 fb 38  c6 4f bb 5b 3d d7 8b 79 .4.....8 .O.[=..y\n"
		+ "                                                                              0000076D  be 3e 16 78 b5 d1 21 11  35 94 e2 c9 fa b8 ca d4 .>.x..!. 5.......\n"
		+ "                                                                              0000077D  de 72 63 7a 36 f8 c9 b6  f7 14 4f d7 c7 45 4e d8 .rcz6... ..O..EN.\n"
		+ "                                                                              0000078D  da a5 f5 d4 0f e9 a0 0f  73 b3 be 36 d2 ac 64 6a ........ s..6..dj\n"
		+ "                                                                              0000079D  9b 67 36 55 3a 21 32 72  03 d8 1a fe 4e 0e 3f 61 .g6U:!2r ....N.?a\n"
		+ "                                                                              000007AD  c0 13 8e 26 f2 a4 c8 0a  c8 4f 9b 6f 8d 3c 6d d2 ...&.... .O.o.<m.\n"
		+ "                                                                              000007BD  6a 4c ec 9c c8 8a cd d7  e8 f7 46 ae d1 b4 6e 3b jL...... ..F...n;\n"
		+ "                                                                              000007CD  29 db cc 30 2f 32 71 f2  b2 df 1b 59 36 09 64 6b )..0/2q. ...Y6.dk\n"
		+ "                                                                              000007DD  7d 4c f8 29 91 49 c8 e6  dc c1 33 2c 7b a8 62 d7 }L.).I.. ..3,{.b.\n"
		+ "                                                                              000007ED  5f 74 d8 98 3b 89 c7 d3  4d 87 1e e6 9e 1b 13 9a _t..;... M.......\n"
		+ "                                                                              000007FD  4f d6 db ec 91 be 55 a6  2b 1e a4 5e 2f 8c 23 76 O.....U. +..^/.#v\n"
		+ "                                                                              0000080D  ea 0e 36 d8 10 1a e8 f3  8d a6 d3 65 9b ee e8 07 ..6..... ...e....\n"
		+ "                                                                              0000081D  40 5f b5 5a d4 4c 48 e9  fa bb 6e ec f0 fa 8a 92 @_.Z.LH. ..n.....\n"
		+ "                                                                              0000082D  4e 22 d7 ee fd 91 da a5  94 4c ea a7 45 c6 38 3f N\"...... .L..E.8?\n"
		+ "                                                                              0000083D  a9 bf 3f f2 a4 26 f2 b6  e6 4e 4f a9 db 66 0a 4b ..?..&.. .NO..f.K\n"
		+ "                                                                              0000084D  64 25 0e b0 a6 53 fc 30  4f 71 c6 48 91 14 69 eb d%...S.0 Oq.H..i.\n"
		+ "                                                                              0000085D  1a cd 04 67 44 26 44 ae  fe 87 23 d5 d7 6a d0 f6 ...gD&D. ..#..j..\n"
		+ "                                                                              0000086D  1c 5a 74 67 45 a6 57 de  6b fc 6c 64 af 91 ca 66 .ZtgE.W. k.ld...f\n"
		+ "                                                                              0000087D  1b aa 99 79 ce 89 4c e1  b2 f8 aa f8 49 72 30 1f ...y..L. ....Ir0.\n"
		+ "                                                                              0000088D  d2 9d 8d 94 35 da b1 69  07 49 3a 97 c5 3f 28 e0 ....5..i .I:..?(.\n"
		+ "                                                                              0000089D  db 14 70 72 d3 a7 36 aa  93 64 93 72 9b 0f dc ab ..pr..6. .d.r....\n"
		+ "                                                                              000008AD  8a 9a 1f c7 e7 e7 66 45  d3 f9 75 4a 47 e1 19 91 ......fE ..uJG...\n"
		+ "                                                                              000008BD  a5 1e 60 4e df dc d7 37  3f 5d 21 b7 7b 8d 8e 1b ..`N...7 ?]!.{...\n"
		+ "                                                                              000008CD  2f b5 e3 8e a7 f0 ac c8  26 19 60 5e 87 fe 5e 87 /....... &.`^..^.\n"
		+ "                                                                              000008DD  de ac e0 50 37 74 77 9d  e6 5e 1a bb 20 c4 03 f1 ...P7tw. .^.. ...\n"
		+ "                                                                              000008ED  3b fd 5a 73 52 c7 fe 51  c7 7e a3 82 83 4e 23 e8 ;.ZsR..Q .~...N#.\n"
		+ "                                                                              000008FD  65 59 cf 8b 42 95 22 4f  70 91 0f c4 47 49 0b 3f eY..B.\"O p...GI.?\n"
		+ "                                                                              0000090D  71 4d 27 33 ea a3 a0 8f  38 08 a5 9a f2 ba 00 bd qM'3.... 8.......\n"
		+ "                                                                              0000091D  95 51 97 2a fe 2c 3e c6  35 ea 52 cb 52 ae ad ac .Q.*.,>. 5.R.R...\n"
		+ "                                                                              0000092D  ae a4 7d 5f f2 0a c1 6f  62 c7 78 e2 fc 07 f0 f0 ..}_...o b.x.....\n"
		+ "                                                                              0000093D  e1 43 51 5c 4f fa 63 0b  78 f4 e8 91 6e 9b af 64 .CQ\\O.c. x...n..d\n"
		+ "                                                                              0000094D  dd 34 bd 8c dc 23 df 44  f2 f2 26 8a 97 75 24 0f .4...#.D ..&..u$.\n"
		+ "                                                                              0000095D  3f d0 c3 f4 c7 9d f4 38  7e 8a 4f 50 53 3e 9e 75 ?......8 ~.OPS>.u\n"
		+ "                                                                              0000096D  c2 d4 98 57 b2 f7 1b 7a  ef ca 5e 6a 70 e0 03 4c ...W...z ..^jp..L\n"
		+ "                                                                              0000097D  1d c7 64 da e1 74 f5 55  da 38 a5 57 49 87 13 67 ..d..t.U .8.WI..g\n"
		+ "                                                                              0000098D  57 49 d7 f4 6a 7e c5 fd  d2 75 74 ff 0b 45 90 fd WI..j~.. .ut..E..\n"
		+ "                                                                              0000099D  9f 59 0f 00 00 0d 0a                             .Y.....\n"
		+ "                                                                              000009A4  33 44 45 0d 0a 54 6f 74  61 6c 2d 49 6d 61 67 65 3DE..Tot al-Image\n"
		+ "                                                                              000009B4  73 3a 20 32 0d 0a 43 6f  6e 74 65 6e 74 2d 54 79 s: 2..Co ntent-Ty\n"
		+ "                                                                              000009C4  70 65 3a 20 69 6d 61 67  65 2f 70 6e 67 0d 0a 4e pe: imag e/png..N\n"
		+ "                                                                              000009D4  6f 76 61 72 72 61 2d 49  6d 61 67 65 2d 49 6e 64 ovarra-I mage-Ind\n"
		+ "                                                                              000009E4  65 78 3a 20 30 0d 0a 43  6f 6e 74 65 6e 74 2d 4c ex: 0..C ontent-L\n"
		+ "                                                                              000009F4  65 6e 67 74 68 3a 20 39  30 31 0d 0a 0d 0a 89 50 ength: 9 01.....P\n"
		+ "                                                                              00000A04  4e 47 0d 0a 1a 0a 00 00  00 0d 49 48 44 52 00 00 NG...... ..IHDR..\n"
		+ "                                                                              00000A14  00 10 00 00 00 10 08 06  00 00 00 1f f3 ff 61 00 ........ ......a.\n"
		+ "                                                                              00000A24  00 03 4c 49 44 41 54 78  da 25 93 7f 4c 55 65 1c ..LIDATx .%..LUe.\n"
		+ "                                                                              00000A34  c6 df f3 1e 6c c9 48 e0  0f db 9a bf 58 2b 33 8d ....l.H. ....X+3.\n"
		+ "                                                                              00000A44  b9 36 8b 0b 17 22 75 b1  60 35 6d a6 86 9b ba 65 .6...\"u. `5m....e\n"
		+ "                                                                              00000A54  f9 4f f6 e3 af 4a bb 35  05 2f 8a a6 62 18 09 f6 .O...J.5 ./..b...\n"
		+ "                                                                              00000A64  93 b5 9b 98 33 40 41 ef  2c ac d4 22 c7 40 5d 58 ....3@A. ,..\".@]X\n"
		+ "                                                                              00000A74  81 f2 2b 4b f2 5e 81 7b  61 57 2f e7 de f3 e9 7b ..+K.^.{ aW/....{\n"
		+ "                                                                              00000A84  8e 67 7b ce fb 9e f7 9c  e7 f9 3e df e7 7d 8f 52 .g{..... ..>..}.R\n"
		+ "                                                                              00000A94  72 59 09 e8 e8 1d 22 6b  7d 80 94 e7 be a2 e2 e8 rY....\"k }.......\n"
		+ "                                                                              00000AA4  25 92 24 88 47 46 39 5b  98 47 b7 a1 98 d4 9a a4 %.$.GF9[ .G......\n"
		+ "                                                                              00000AB4  52 02 4d 4c 9e 47 64 ee  70 55 c2 02 1b 58 5e 7e R.ML.Gd. pU...X^~\n"
		+ "                                                                              00000AC4  0a b5 3a 88 de d0 c1 b4  97 bf e7 ea bf 51 79 91 ..:..... .....Qy.\n"
		+ "                                                                              00000AD4  20 f6 7b 37 37 d2 52 5d  b2 6d 98 24 85 ec 08 84  .{77.R] .m.$....\n"
		+ "                                                                              00000AE4  55 0a 03 5a 44 84 8b 65  59 3c b4 a9 15 b5 a1 1d U..ZD..e Y<......\n"
		+ "                                                                              00000AF4  b5 b1 0b 55 fa 13 e5 df  5d 76 95 45 83 81 a2 22 ...U.... ]v.E...\"\n"
		+ "                                                                              00000B04  e2 ca 20 61 2a e2 86 c1  98 32 09 89 48 bf e3 c2 .. a*... .2..H...\n"
		+ "                                                                              00000B14  4e 8a 82 7c e4 f5 b5 a1  d7 fe 82 de d8 8e 5e 73 N..|.... ......^s\n"
		+ "                                                                              00000B24  8e d5 7b 3b 1d 69 47 9f  6b 2b 96 33 21 15 31 9c ..{;.iG. k+.3!.1.\n"
		+ "                                                                              00000B34  16 4c c6 65 fc 47 c8 3d  da 74 1c 38 0a 49 ca 1a .L.e.G.= .t.8.I..\n"
		+ "                                                                              00000B44  2e a3 56 04 49 79 e5 02  fa a5 1f 28 ad 6a 97 55 ..V.Iy.. ...(.j.U\n"
		+ "                                                                              00000B54  b1 70 07 7e 7d 74 1e 3f  3f 70 0f 4d 73 33 69 cd .p.~}t.? ?p.Ms3i.\n"
		+ "                                                                              00000B64  ca a4 23 63 0a 83 62 df  c9 46 f5 0e de 72 33 18 ..#c..b. .F...r3.\n"
		+ "                                                                              00000B74  8e c4 98 b7 a9 05 f5 e2  69 a6 ad 0d 12 ec ba ee ........ i.......\n"
		+ "                                                                              00000B84  ae d7 36 1d 62 d6 5b 59  a8 8f 73 30 6b 0a 50 d5 ..6.b.[Y ..s0k.P.\n"
		+ "                                                                              00000B94  5e a6 56 3e 49 de ab d9  ec 5a 90 8e 7a 64 dd 17 ^.V>I... .Z..zd..\n"
		+ "                                                                              00000BA4  1c 6d bb 22 26 6c 46 a3  71 be 3c d3 47 cf d0 2d .m.\"&lF. q.<.G..-\n"
		+ "                                                                              00000BB4  b7 ba ff 54 2d aa ec 31  cc 3a 2f e6 c1 3c 54 4d ...T-..1 .:/..<TM\n"
		+ "                                                                              00000BC4  8e 20 17 63 bf cc ab 0b  31 76 2c 41 4d 5f 75 98 . .c.... 1v,AM_u.\n"
		+ "                                                                              00000BD4  8c 65 9f b2 e4 cd 00 db  eb db ee a6 26 bd 9f e9 .e...... ....&...\n"
		+ "                                                                              00000BE4  f9 0d fd ce 1c d4 a1 27  50 b5 42 ac cb c1 38 90 .......' P.B...8.\n"
		+ "                                                                              00000BF4  ef 42 ed f3 60 ec 2e 10  81 a7 c4 41 69 3d 33 57 .B..`... ...Ai=3W\n"
		+ "                                                                              00000C04  7e cd bd 25 9f 93 f9 ec  41 fa 87 23 d8 b6 cd 60 ~..%.... A..#...`\n"
		+ "                                                                              00000C14  f8 3a 73 eb 5e 40 1d c8  46 7f 92 2b f0 ca dc 83 .:s.^@.. F..+....\n"
		+ "                                                                              00000C24  fe c8 8b b1 af 00 2d 02  aa d2 83 7a b0 78 2f 9e ......-. ...z.x/.\n"
		+ "                                                                              00000C34  75 9f b1 ea 83 66 de a8  fa 91 ae 9e 11 d7 be 2d u....f.. .......-\n"
		+ "                                                                              00000C44  f7 50 34 44 d1 e1 d7 30  f6 64 8b f5 7c b7 7f 17 .P4D...0 .d..|...\n"
		+ "                                                                              00000C54  22 a0 76 09 b6 0b 02 a7  2f 12 1a 71 f3 66 72 ac \".v..... /..q.fr.\n"
		+ "                                                                              00000C64  9b e1 6b 8d f4 75 d5 70  7b fc a6 bb 85 93 72 d2 ..k..u.p {.....r.\n"
		+ "                                                                              00000C74  8a 03 af 8b c8 7c 21 4b  c5 2a af 54 cf 45 ed 14 .....|!K .*.T.E..\n"
		+ "                                                                              00000C84  41 bf c0 d9 c5 f1 ff 2e  d2 d9 e8 a1 bf 31 95 bf A....... .....1..\n"
		+ "                                                                              00000C94  5b 14 43 c7 34 57 1a e6  13 09 ff e5 66 f2 c7 f0 [.C.4W.. ....f...\n"
		+ "                                                                              00000CA4  00 f7 55 14 0a 39 17 f3  c3 7c 74 a5 54 f6 4b ff ..U..9.. .|t.T.K.\n"
		+ "                                                                              00000CB4  db 04 77 ac 09 3a 02 39  8c 9e 90 a3 7a 5e 63 9d ..w..:.9 ....z^c.\n"
		+ "                                                                              00000CC4  4d 25 d6 36 95 9b 47 14  bd 8d 25 6e 1e 4e ae 0f M%.6..G. ..%n.N..\n"
		+ "                                                                              00000CD4  ef 5f 29 3d 2f 42 ed 91  16 2a 0a 98 b2 6d 29 c6 ._)=/B.. .*...m).\n"
		+ "                                                                              00000CE4  fb 22 10 0d f7 f1 67 fd  0c 6e 07 33 88 04 d3 88 .\"....g. .n.3....\n"
		+ "                                                                              00000CF4  b6 a4 33 d6 9c ce c4 f1  19 dc f8 76 21 c4 c7 89 ..3..... ...v!...\n"
		+ "                                                                              00000D04  59 36 b3 fc 25 42 94 30  fd 8b 65 14 17 5b 9f 46 Y6..%B.0 ..e..[.F\n"
		+ "                                                                              00000D14  bd 27 4e ac 84 4d ff c9  f5 84 bf 49 63 ac e9 7e .'N..M.. ...Ic..~\n"
		+ "                                                                              00000D24  22 cd d3 5d 72 e4 c8 6c  46 ce f9 dc 6c 1a 2e 9c \"..]r..l F...l...\n"
		+ "                                                                              00000D34  c4 7c fb 71 8c 72 39 0f  65 d2 8a 53 79 8b 60 f3 .|.q.r9. e..Sy.`.\n"
		+ "                                                                              00000D44  d2 bb 7f a4 35 11 26 74  de c7 68 eb 32 22 4d cf ....5.&t ..h.2\"M.\n"
		+ "                                                                              00000D54  c8 f8 3c b1 ce 6a e2 56  8c 4b 83 7d cc 7c b7 58 ..<..j.V .K.}.|.X\n"
		+ "                                                                              00000D64  08 8b d0 3e 21 fb 9c ca  12 de 96 c5 2e f9 7f 58 ...>!... .......X\n"
		+ "                                                                              00000D74  3f 86 7a b3 de 61 42 00  00 00 00 49 45 4e 44 ae ?.z..aB. ...IEND.\n"
		+ "                                                                              00000D84  42 60 82 0d 0a                                   B`...\n"
		+ "                                                                              00000D89  31 33 38 35 0d 0a 43 6f  6e 74 65 6e 74 2d 54 79 1385..Co ntent-Ty\n"
		+ "                                                                              00000D99  70 65 3a 20 69 6d 61 67  65 2f 70 6e 67 0d 0a 4e pe: imag e/png..N\n"
		+ "                                                                              00000DA9  6f 76 61 72 72 61 2d 49  6d 61 67 65 2d 49 6e 64 ovarra-I mage-Ind\n"
		+ "                                                                              00000DB9  65 78 3a 20 31 0d 0a 43  6f 6e 74 65 6e 74 2d 4c ex: 1..C ontent-L\n"
		+ "                                                                              00000DC9  65 6e 67 74 68 3a 20 34  39 32 34 0d 0a 0d 0a 89 ength: 4 924.....\n"
		+ "                                                                              00000DD9  50 4e 47 0d 0a 1a 0a 00  00 00 0d 49 48 44 52 00 PNG..... ...IHDR.\n"
		+ "                                                                              00000DE9  00 01 14 00 00 00 6e 08  03 00 00 00 d1 60 1c 58 ......n. .....`.X\n"
		+ "                                                                              00000DF9  00 00 00 c0 50 4c 54 45  15 73 1f 72 7c 74 b1 0b ....PLTE .s.r|t..\n"
		+ "                                                                              00000E09  26 9b 17 2b d2 14 2e e2  1b 32 e9 27 34 f1 36 39 &..+.... .2.'4.69\n"
		+ "                                                                              00000E19  d8 26 35 da 6a 0a e6 38  44 9f 5e 5e f4 4f 4d ec .&5.j..8 D.^^.OM.\n"
		+ "                                                                              00000E29  67 63 ae 60 36 02 92 12  07 aa 18 1d a8 2c 55 a4 gc.`6... .....,U.\n"
		+ "                                                                              00000E39  5e ec 92 06 fc ae 0e e1  98 21 ff c4 2f ac 8b 63 ^....... .!../..c\n"
		+ "                                                                              00000E49  fb ce 59 d8 9d 5c 19 3c  bb 0a 2d b8 28 47 bc 5d ..Y..\\.< ..-.(G.]\n"
		+ "                                                                              00000E59  6f a8 0f 37 d5 11 3e e2  32 52 c6 15 46 ea 17 4d o..7..>. 2R..F..M\n"
		+ "                                                                              00000E69  f2 1c 54 f6 25 59 f0 32  6b f7 29 50 d8 4f 71 d9 ..T.%Y.2 k.)P.Oq.\n"
		+ "                                                                              00000E79  78 8c d7 50 86 f8 72 98  f2 78 87 a1 8f 8e 8f b8 x..P..r. .x......\n"
		+ "                                                                              00000E89  b8 b8 a8 a8 a9 9f 9a a0  e2 a5 9d f1 db a7 8a 9c ........ ........\n"
		+ "                                                                              00000E99  dc 96 ac eb 9f ae df b8  c6 ed c7 c7 c7 d8 d8 d9 ........ ........\n"
		+ "                                                                              00000EA9  cf cd d2 ce d6 f1 e9 e9  e9 e6 ea f8 ff ff ff f4 ........ ........\n"
		+ "                                                                              00000EB9  ef ee e9 de e0 99 d6 a0  3c ad 3d 7b 00 00 12 37 ........ <.={...7\n"
		+ "                                                                              00000EC9  49 44 41 54 78 da ed 9c  7d 43 e2 38 13 c0 59 45 IDATx... }C.8..YE\n"
		+ "                                                                              00000ED9  7c 41 d6 c7 75 3d 15 01  5b 29 04 91 42 a5 a5 dd |A..u=.. [)..B...\n"
		+ "                                                                              00000EE9  b6 b4 f7 fd bf d5 33 33  49 da f4 1d 17 76 cf db ......33 I....v..\n"
		+ "                                                                              00000EF9  73 fe 58 d9 52 9a e4 97  99 c9 64 92 b4 b5 fd 43 s.X.R... ..d....C\n"
		+ "                                                                              00000F09  e5 ef 6f 8a 6c de f7 db  d6 9f 8a e4 fa fa fa 7f ..o.l... ........\n"
		+ "                                                                              00000F19  42 ae 57 de 01 a1 44 f1  c6 b6 e7 f3 17 94 f9 dc B.W...D. ........\n"
		+ "                                                                              00000F29  76 7c 3f fc 37 10 09 08  89 64 72 75 b5 30 0f 06 v|?.7... .dru.0..\n"
		+ "                                                                              00000F39  c5 b7 5f 26 24 86 61 4c  a4 b0 97 b9 e3 7f 7c 26 .._&$.aL ......|&\n"
		+ "                                                                              00000F49  28 02 ca 55 eb cb f2 9d  4c aa a0 f8 36 03 04 63 (..U.... L...6..c\n"
		+ "                                                                              00000F59  94 67 21 e3 b1 64 f3 62  fb d1 c7 c6 e2 ba a6 79 .g!..d.b .......y\n"
		+ "                                                                              00000F69  2d f4 a4 b5 70 b7 07 80  12 91 8e 20 0f 5d 63 43 -...p... ... .]cC\n"
		+ "                                                                              00000F79  12 a6 19 3a 91 11 60 d8  c7 d6 97 00 44 40 69 b5 ...:..`. ....D@i.\n"
		+ "                                                                              00000F89  96 c1 fe 50 08 89 01 44  8c e1 70 b5 34 4d 97 c4 ...P...D ..p.4M..\n"
		+ "                                                                              00000F99  34 57 af 4c d7 53 2c 93  97 0f 6e 46 09 14 73 7f 4W.L.S,. ..nF..s.\n"
		+ "                                                                              00000FA9  28 9b 17 86 48 74 6d b8  58 ba 9e 17 04 09 7b cf (...Htm. X.....{.\n"
		+ "                                                                              00000FB9  5d be 6a c8 85 b0 18 63  9d f9 ff 0d 28 e1 fc 05 ].j....c ....(...\n"
		+ "                                                                              00000FC9  0d e7 59 7b 5d 9a 09 90  54 2b 3d f7 d5 00 2c 63 ..Y{]... T+=...,c\n"
		+ "                                                                              00000FD9  f0 bd 60 5b ba 3e 0b fe  03 50 36 2f c8 04 0c 07 ..`[.>.. .P6/....\n"
		+ "                                                                              00000FE9  46 b1 a0 c2 87 81 11 91  7b d1 f5 a7 a7 d1 d4 fb F....... {.......\n"
		+ "                                                                              00000FF9  e8 50 ae f6 85 62 03 13  30 0b 0d 0c a7 fa 41 de .P...b.. 0.....A.\n"
		+ "                                                                              00001009  7a aa a3 3c 8d 40 86 ee  9f 0e 05 99 80 37 19 36 z..<.@.. .....7.6\n"
		+ "                                                                              00001019  04 3b 81 33 15 48 46 c3  a5 f7 87 9b cf 1c 99 3c .;.3.HF. .......<\n"
		+ "                                                                              00001029  23 93 a6 a7 fc 60 23 c1  c4 0d fe 6c 28 b6 64 b2 #....`#. ...l(.d.\n"
		+ "                                                                              00001039  43 43 3d f6 e1 99 1c 04  8a b0 1d 6d b1 d3 33 66 CC=..... ...m..3f\n"
		+ "                                                                              00001049  1f dc 76 0e 03 85 8f 3b  ba be 1b 13 ff e3 33 39 ..v....; ......39\n"
		+ "                                                                              00001059  00 14 ff 05 62 36 34 9e  dd 5a 3a 19 41 20 f3 b1 ....b64. .Z:.A ..\n"
		+ "                                                                              00001069  99 1c 00 8a 70 b2 da 6e  93 a7 d8 76 96 e6 07 67 ....p..n ...v...g\n"
		+ "                                                                              00001079  b2 3f 14 5b 18 cf 70 c7  07 04 9e 17 6c ff 0d 50 .?.[..p. ....l..P\n"
		+ "                                                                              00001089  ae 7e 1e 4a fc 22 14 e5  a3 9b c4 ef 84 32 e7 91 .~.J.\".. .....2..\n"
		+ "                                                                              00001099  ec ce 8a f2 5f 80 e2 f3  19 0f 78 94 3f 48 51 f6 ...._... ..x.?HQ.\n"
		+ "                                                                              000010A9  85 f2 5e 8f b2 9b 44 31  97 28 da f5 fe b7 7b 21 ..^...D1 .(....{!\n"
		+ "                                                                              000010B9  6f 71 f4 3b a0 44 b1 45  52 28 0d a0 84 42 51 f4 oq.;.D.E R(...BQ.\n"
		+ "                                                                              000010C9  57 f7 70 40 ac de a5 94  9e 65 35 b6 31 7a bb ff W.p@.... .e5.1z..\n"
		+ "                                                                              000010D9  2b 23 f7 6f 8d 85 84 fe  66 63 e7 64 0e e2 84 bb +#.o.... fc.d....\n"
		+ "                                                                              000010E9  40 51 6b 08 55 cc 43 b1  19 23 28 d3 43 59 4f 6c @Qk.U.C. .#(.CYOl\n"
		+ "                                                                              000010F9  5d 5e 9e 9f 9e 76 3a 9d  d3 d3 53 51 6a dc 88 e4 ]^...v:. ..SQj...\n"
		+ "                                                                              00001109  7b 2a 9c 4b 2d 96 70 63  43 64 35 61 b4 d2 80 0d {*.K-.pc Cd5a....\n"
		+ "                                                                              00001119  c0 04 2a e6 33 74 b6 09  9a a1 20 11 a8 22 c8 85 ..*.3t.. .. ..\"..\n"
		+ "                                                                              00001129  e0 62 65 a1 bc f0 3c 1a  8c 3d 07 b1 9e f8 e1 f2 .be...<. .=......\n"
		+ "                                                                              00001139  f2 b4 73 da eb 82 f4 2e  00 0c 16 7b 71 51 83 85 ..s..... ...{qQ..\n"
		+ "                                                                              00001149  23 b9 bd 5b 2d 96 cb d5  dd ad c0 02 57 2a b1 6c #..[-... ....W*.l\n"
		+ "                                                                              00001159  e6 93 54 18 31 31 38 92  e9 4a 66 82 6a a0 c4 80 ..T.118. .Jf.j...\n"
		+ "                                                                              00001169  e4 54 d4 30 ad 60 a0 40  89 39 e4 03 b9 94 08 fa .T.0.`.@ .9......\n"
		+ "                                                                              00001179  e0 bc 73 da 5d f0 ec ae  b9 a2 52 49 ac 0a 88 02 ..s.]... ..RI....\n"
		+ "                                                                              00001189  c9 d2 74 3d 4c 7a 7a d6  03 61 c1 7f ee cb 91 50 ..t=Lzz. .a.....P\n"
		+ "                                                                              00001199  76 10 60 18 63 f8 93 ac  c3 60 bf 2a d9 b1 4a 28 v.`.c... .`.*..J(\n"
		+ "                                                                              000011A9  58 c5 53 aa 21 26 9f 97  58 41 80 72 da b9 f0 52 X.S.!&.. XA.r...R\n"
		+ "                                                                              000011B9  28 76 02 e5 00 2e 25 ee  41 81 9d 2e a6 77 29 99 (v....%. A....w).\n"
		+ "                                                                              000011C9  09 8d 5c 9d 71 2c a7 9d  5e 50 a9 26 77 4a aa 2f ..\\.q,.. ^P.&wJ./\n"
		+ "                                                                              000011D9  f0 ac c4 90 1e 8a 3f 09  41 4b c6 c6 10 b4 ca 34 ......?. AK.....4\n"
		+ "                                                                              000011E9  57 4c 66 d2 c7 78 01 2e  a5 f3 f6 2a 28 54 45 60 WLf..x.. ...*(TE`\n"
		+ "                                                                              000011F9  22 0a 84 0a 9e 52 fd 3a  29 95 d6 76 2e a1 1c c0 \"....R.: )..v....\n"
		+ "                                                                              00001209  cf be 61 81 67 dd 4c 4a  21 70 7b 27 bc d4 93 9e ..a.g.LJ !p{'....\n"
		+ "                                                                              00001219  57 c2 e4 fe af ef 37 77  d9 24 44 f0 56 4d 85 d4 W.....7w .$D.VM..\n"
		+ "                                                                              00001229  84 71 ea 80 dc 99 d2 8a  14 d8 0e 73 f1 42 e3 e8 .q...... ...s.B..\n"
		+ "                                                                              00001239  13 8b 2a a6 21 79 60 11  95 4e 5a bf d6 96 09 97 ..*.!y`. .NZ.....\n"
		+ "                                                                              00001249  a2 af bc 5f c1 04 73 52  17 27 a8 2c 9d 93 22 15 ..._..sR .'.,..\".\n"
		+ "                                                                              00001259  c9 a4 70 fd a6 82 8a 60  92 cc bc 02 77 4a 19 63 ..p....` ....wJ.c\n"
		+ "                                                                              00001269  e8 54 16 ec 30 24 0b 55  ce 16 68 e1 88 d0 39 69 .T..0$.U ..h...9i\n"
		+ "                                                                              00001279  b7 bb fc d6 56 3c 39 18  94 d2 02 51 dc b3 36 60 ....V<9. ...Q..6`\n"
		+ "                                                                              00001289  81 ae 68 e7 2c a8 8a 09  d4 b3 9c 0a 66 38 c6 46 ..h.,... ....f8.F\n"
		+ "                                                                              00001299  26 bf f1 c3 10 79 74 7d  1d 34 42 89 1e d0 e5 15 &....yt} .4B.....\n"
		+ "                                                                              000012A9  aa d8 a3 ca b5 db 47 dc  ef b5 7c 69 3d fa 2a d8 ......G. ..|i=.*.\n"
		+ "                                                                              000012B9  9b 49 ef bc 73 5c 36 d1  b6 da 27 27 bc 5c 2b d3 .I..s\\6. ..''.\\+.\n"
		+ "                                                                              000012C9  6d f7 e8 50 6e cb 7e 11  dc 4a 28 37 ca 18 14 53 m..Pn.~. .J(7...S\n"
		+ "                                                                              000012D9  48 95 cb 6f 38 b4 ba 80  b9 74 a7 11 8a 05 fd d6 H..o8... .t......\n"
		+ "                                                                              000012E9  39 2b 14 68 09 26 47 5c  55 5a 9b 83 41 79 a0 02 9+.h.&G\\ UZ..Ay..\n"
		+ "                                                                              000012F9  bb 65 63 58 d0 6b 0b 28  6d 75 0c ba 17 8a 52 56 .ecX.k.( mu....RV\n"
		+ "                                                                              00001309  70 2c 55 e5 e6 d6 cb a6  91 f5 7c 9b 98 54 15 e6 p,U..... ..|..T..\n"
		+ "                                                                              00001319  35 40 91 ba 9c 2f 30 ea  10 92 a3 a3 63 7a 74 cb 5@.../0. ....czt.\n"
		+ "                                                                              00001329  3e 14 14 8b 0a 3c 2e 8f  00 ad 36 ea 0a 42 e9 7a >....<.. ..6..B.z\n"
		+ "                                                                              00001339  19 e3 01 45                                      ...E\n"
		+ "                                                                              0000133D  b9 2b 77 f0 0f 12 ca 4d  a2 5d 94 1e 7c 36 f2 ca .+w....M .]..|6..\n"
		+ "                                                                              0000134D  ef 4b af a2 3b 0d 8e 96  fa ad dd 2d 14 88 50 8e .K..;... ...-..P.\n"
		+ "                                                                              0000135D  48 08 c2 c1 a0 a0 f1 a0  a2 54 44 80 a0 2a 20 00 H....... .TD..* .\n"
		+ "                                                                              0000136D  a5 9d 14 13 71 45 39 af  c8 57 c4 09 94 44 55 78 ....qE9. .W...DUx\n"
		+ "                                                                              0000137D  86 a3 18 64 be 48 28 43  af 16 0a 2a ca 39 58 8f ...d.H(C ...*.9X.\n"
		+ "                                                                              0000138D  57 d2 67 a4 27 c7 5c cf  5b f3 14 8a b7 bf a2 40 W.g.'.\\. [......@\n"
		+ "                                                                              0000139D  2f 94 43 21 55 21 28 89  aa 70 45 b9 f9 5a 15 33 /.C!U!(. .pE..Z.3\n"
		+ "                                                                              000013AD  de 4b 28 52 55 f8 6c 5e  67 85 1f 6c 24 14 cd ad .K(RU.l^ g..l$...\n"
		+ "                                                                              000013BD  85 22 94 39 07 35 b2 2e  89 c9 31 85 57 5b 09 85 .\".9.5.. ..1.W[..\n"
		+ "                                                                              000013CD  2f 0c bf ee 03 25 ea d1  70 5c a2 9a 42 2e a4 aa /....%.. p\\..B...\n"
		+ "                                                                              000013DD  1c c9 4a 12 13 70 29 55  50 de 12 28 77 bc 66 5c ..J..p)U P..(w.f\\n"
		+ "                                                                              000013ED  a9 4b a0 6c 27 02 ca 54  f9 aa 08 45 d4 f1 38 3b .K.l'..T ...E..8;\n"
		+ "                                                                              000013FD  46 5b 10 2b a0 8b ed 52  48 cd 47 1f db 30 04 94 F[.+...R H.G..0..\n"
		+ "                                                                              0000140D  a1 b7 a7 a2 80 b9 b6 2b  d5 cd 4a a0 88 60 20 c6 .......+ ..J..` .\n"
		+ "                                                                              0000141D  49 1f b8 d1 bb 2a 8c 51  02 e5 96 df 42 93 b4 67 I....*.Q ....B..g\n"
		+ "                                                                              0000142D  50 87 02 94 b9 80 32 52  5c c0 f5 55 1e ca 1b d5 P.....2R \\..U....\n"
		+ "                                                                              0000143D  31 33 14 c4 38 3b 6b b7  b9 92 24 97 11 8a d8 42 13..8;k. ..$....B\n"
		+ "                                                                              0000144D  b0 57 98 df e3 d6 53 0d  25 4e a0 7c e5 e5 bc 35 .W....S. %N.|...5\n"
		+ "                                                                              0000145D  41 11 f6 73 73 73 7e 4e  6d 95 93 34 ad a8 29 1b A..sss~N m..4..).\n"
		+ "                                                                              0000146D  0e 65 34 52 8a 2f 42 b1  b8 4b e9 2a 17 4e 11 49 .e4R./B. .K.*.N.I\n"
		+ "                                                                              0000147D  17 62 7e 57 4d 3a b7 6c  be af e2 39 6b 90 ef b6 .b~WM:.l ...9k...\n"
		+ "                                                                              0000148D  1e 9c 7d 13 94 4a 6f 7d  21 a1 1c ad b8 9b 6d 84 ..}..Jo} !.....m.\n"
		+ "                                                                              0000149D  f2 96 40 21 fb 91 11 95  51 32 ed e5 2d a8 87 12 ..@!.... Q2..-...\n"
		+ "                                                                              000014AD  f5 a8 8e 12 0a b8 12 44  72 96 55 12 0e 65 03 33 .......D r.U..e.3\n"
		+ "                                                                              000014BD  07 31 ed de 63 96 1c 23  94 4e 2d 94 5e 02 85 ec .1..c..# .N-.^...\n"
		+ "                                                                              000014CD  87 5b 4f 2d 94 38 0b 85  47 54 e3 d2 61 72 b2 03 .[O-.8.. GT..ar..\n"
		+ "                                                                              000014DD  94 98 43 69 9f e1 85 b8  87 09 9f b3 82 92 88 88 ..Ci.... ........\n"
		+ "                                                                              000014ED  56 ec f6 db 6f 4c b6 78  27 d4 98 cf d6 7a 37 94 V...oL.x '....z7.\n"
		+ "                                                                              000014FD  28 85 e2 a6 50 9e cb 46  04 86 2d 78 7a 1a 2d ea (...P..F ..-xz.-.\n"
		+ "                                                                              0000150D  a0 70 6d 3e 03 28 d6 25  ce 3a 50 49 4a f7 e1 b4 .pm>.(.% .:PIJ...\n"
		+ "                                                                              0000151D  42 23 81 c2 bc 5f 09 25  96 4c 8e 68 50 7e 93 50 B#..._.% .L.hP~.P\n"
		+ "                                                                              0000152D  1e aa ad f6 56 42 21 37  e4 93 f7 03 28 ac f8 8b ....VB!7 ....(...\n"
		+ "                                                                              0000153D  97 31 29 ca 60 19 ec 00  a5 0b 0e 10 33 4c 65 4a .1).`... ....3LeJ\n"
		+ "                                                                              0000154D  22 67 c9 cf 44 45 df cb  a9 3c 48 28 dd 4a 28 51 \"g..DE.. .<H(.J(Q\n"
		+ "                                                                              0000155D  a7 00 85 37 b9 da 6a ef  33 50 78 f7 41 ff 19 4e ...7..j. 3Px.A..N\n"
		+ "                                                                              0000156D  50 01 45 cd 93 15 a0 bc  51 1d 69 30 f0 5c 4c 81 P.E..... Q.i0.\\L.\n"
		+ "                                                                              0000157D  55 2e e8 b5 b6 0e 26 24  f6 b5 9f de 05 4e be 6b U.....&$ .....N.k\n"
		+ "                                                                              0000158D  a1 a0 a7 55 a1 f0 e4 5a  2d 94 b7 0c 14 b0 11 a1 ...U...Z -.......\n"
		+ "                                                                              0000159D  d4 af a5 50 46 a3 91 3a  2b 42 28 57 19 4d 39 3d ...PF..: +B(W.M9=\n"
		+ "                                                                              000015AD  bd e0 a3 8d 97 cd bc 94  40 d9 d0 c6 e1 1d ed c7 ........ @.......\n"
		+ "                                                                              000015BD  9f 2b 82 19 63 c6 26 38  37 ed 61 0e 98 0a ac d6 .+..c.&8 7.a.....\n"
		+ "                                                                              000015CD  b6 4b 0a 68 31 72 f4 32  a1 d9 aa 01 ca b9 84 62 .K.h1r.2 .......b\n"
		+ "                                                                              000015DD  8f 05 95 e2 4e 3b 26 ac  c7 ab 83 72 79 ca 7b ae ....N;&. ...ry.{.\n"
		+ "                                                                              000015ED  db 64 11 2d d0 4a b1 a5  3a 37 a1 2a 45 a2 64 8b .d.-.J.. :7.*E.d.\n"
		+ "                                                                              000015FD  31 92 42 df c6 30 96 7a  90 50 8e cd 9a e1 47 85 1.B..0.z .P....G.\n"
		+ "                                                                              0000160D  12 e7 e3 d5 3a 28 dc 19  c7 86 50 ea e7 75 ae 10 ....:(.. ..P..u..\n"
		+ "                                                                              0000161D  68 03 2a ca ab 1a d6 95  43 e9 a0 3a 37 0d b3 2d h.*..... C..:7..-\n"
		+ "                                                                              0000162D  11 0e 3e 37 ab 4a 3c 1f  d3 0e 40 5d ee d5 37 70 ..>7.J<. ..@]..7p\n"
		+ "                                                                              0000163D  e7 db 70 e9 f2 84 04 2e  69 b4 eb c7 64 82 72 2c ..p..... i...d.r,\n"
		+ "                                                                              0000164D  a0 dc 4a 2a 0f 6e 33 14  5e af 99 dc 12 6f e4 7e ..J*.n3. ^....o.~\n"
		+ "                                                                              0000165D  62 8f c9 a3 64 a6 96 05  28 d1 a5 ac e4 5d 33 94 b...d... (....]3.\n"
		+ "                                                                              0000166D  8d ae a8 4a f5 42 8b 6d  00 0d 0d 84 0d 87 62 9d ...J.B.m ......b.\n"
		+ "                                                                              0000167D  05 2b c2 77 83 59 1d 92  76 9d 53 e9 71 97 72 7c .+.w.Y.. v.S.q.r|\n"
		+ "                                                                              0000168D  4c dc a2 bf 92 49 b0 15  d4 40 41 97 72 2e c6 b4 L....I.. .@A.r...\n"
		+ "                                                                              0000169D  d8 d0 45 5d b3 a9 c7 68  f2 ac cb ee a9 86 42 f9 ..E]...h ......B.\n"
		+ "                                                                              000016AD  b5 0e 77 2a cd cb a6 4c  df 41 55 42 df 73 28 5f ..w*...L .AUB.s(_\n"
		+ "                                                                              000016BD  8e e2 a0 b2 70 45 11 e1  e1 2e 50 a4 f5 f0 9f dc ....pE.. ..P.....\n"
		+ "                                                                              000016CD  37 3b 95 37 e9 52 e4 48  eb 70 55 85 ba 66 b6 35 7;.7.R.H .pU..f.5\n"
		+ "                                                                              000016DD  a3 0a 8f f2 9b f5 8a 50  d2 9e 6b 18 51 68 2d 59 .......P ..k.Qh-Y\n"
		+ "                                                                              000016ED  6c 17 6e f0 2a 41 2a 3e  28 0d 31 49 36 d2 5e ca l.n.*A*> (.1I6.^.\n"
		+ "                                                                              000016FD  f2 aa 0d b6 27 ad c7 2d  9f 04 57 43 49 67 2b 82 ....'..- ..WCIg+.\n"
		+ "                                                                              0000170D  0a 54 97 c5 ca 9a 07 28  4a 61 57 62 11 8a e8 b9 .T.....( JaWb....\n"
		+ "                                                                              0000171D  66 55 69 91 9b 4a 36 51  eb c6 8f 5d 46 60 9f 6a fUi..J6Q ...]F`.j\n"
		+ "                                                                              0000172D  a6 ee 2e e6 bd 80 06 72  57 07 05 ad 47 46 9d 89 .......r W...GF..\n"
		+ "                                                                              0000173D  53 b9 75 1b a0 a4 23 6d  90 52 99 d8 21 37 6b 06 S.u...#m .R..!7k.\n"
		+ "                                                                              0000174D  4c a6 c5 9d 9a 45 28 a2  e7 9a 55 a5 95 f0 97 06 L....E(. ..U.....\n"
		+ "                                                                              0000175D  14 ec 0a 85 6f b9 16 2d  8c cf 30 35 7d 52 67 3f ....o..- ..05}Rg?\n"
		+ "                                                                              0000176D  17 42 51 92 60 2a 55 95  ea 34 53 c6 7a 88 0a 13 .BQ.`*U. .4S.z...\n"
		+ "                                                                              0000177D  54 c6 93 09 c5 05 e8 db  a6 25 3b f0 4a a0 08 fb T....... .%;.J...\n"
		+ "                                                                              0000178D  81 5a 5e 78 8d 50 82 89  42 65 1d bc 07 4a 32 0f .Z^x.P.. Be...J2.\n"
		+ "                                                                              0000179D  e9 25 a9 b5 8a 5e 88 cf  38 94 a4 db e3 ef 37 f9 .%...^.. 8.....7.\n"
		+ "                                                                              000017AD  7c 63 31 cc 4f 07 64 29  de 8a 4d 47 58 5d 70 6b |c1.O.d) ..MGX]pk\n"
		+ "                                                                              000017BD  b8 b8 8e 29 96 b2 5d 89  25 50 22 be d4 82 d5 ec ...)..]. %P\".....\n"
		+ "                                                                              000017CD  05 4d 50 60 00 92 0e ac  76 04 aa 83 12 b7 a5 54 .MP`.... v......T\n"
		+ "                                                                              000017DD  a8 8a 75 c6 15 25 ed f6  7b 50 92 3a 55 89 a5 a2 ..u..%.. {P.:U...\n"
		+ "                                                                              000017ED  64 1f 18 78 e6 eb 90 69  da 14 62 25 0c 97 2a f6 d..x...i ..b%..*.\n"
		+ "                                                                              000017FD  74 5e 5f 5d 11 13 35 71  6d b5 a9 eb 4e f2 6b 2d t^_]..5q m...N.k-\n"
		+ "                                                                              0000180D  a5 50 b6 33 49 05 dd ca  e6 67 a0 70 3f da ae 56 .P.3I... .g.p?..V\n"
		+ "                                                                              0000181D  95 9e f0 28 ae b2 b6 73  43 58 e0 1f b7 c6 7a 8a ...(...s CX....z.\n"
		+ "                                                                              0000182D  cb 42 81 87 a7 b2 4c 93  89 0c 4b e9 82 6f 19 94 .B....L. ..K..o..\n"
		+ "                                                                              0000183D  e0 4c 52 39 39 b3 1a a1  04 53 45 57 9a a9 60 be .LR99... .SEW..`.\n"
		+ "                                                                              0000184D  21 0f 25 b8 90 50 4a 0d  36 3e cb 7a 14 be 38 2a !.%..PJ. 6>.z..8*\n"
		+ "                                                                              0000185D  a5 64 21 5d 2a 4a 45 0e  17 c7 40 0a 22 9f 2b 52 .d!]*JE. ..@.\".+R\n"
		+ "                                                                              0000186D  ee 1c 4a 7e 31 8c 2a d8  44 45 ee b8 f6 8d 27 e9 ..J~1.*. DE....'.\n"
		+ "                                                                              0000187D  d7 81 8a f3 13 50 44 81  28 65 06 cb 15 25 bf 88 .....PD. (e...%..\n"
		+ "                                                                              0000188D  9b 50 29 d1 e6 7b 3e 1c  57 ef d8 dc e0 86 03 e3 .P)..{>. W.......\n"
		+ "                                                                              0000189D  b9 22 e5 5e 0a 45 ea 33  61 b1 9a a0 6c 9d e9 e8 .\".^.E.3 a...l...\n"
		+ "                                                                              000018AD  49 72 69 f4 2b be 21 a1  a8 d9 ee 94 4a b1 89 16 Iri.+.!. ....J...\n"
		+ "                                                                              000018BD  67 92 33 85 e0 41 42 f9  fe 56 32 1e df 20 93 ea g.3..AB. .V2.. ..\n"
		+ "                                                                              000018CD  d9 9b c3 93 86 15 39 0f  01 25 77 de c7 3b 53 a8 ......9. .%w..;S.\n"
		+ "                                                                              000018DD  14 37 12 45 56 ac 42 41  2a a3 94 4a fd 41 38 80 .7.EV.BA *..J.A8.\n"
		+ "                                                                              000018ED  22 4f fc 28                                      \"O.(\n"
		+ "                                                                              000018F1  50 82 ee d1 91 a4 52 64  c2 47 9e dc 63 83 87 f3 P.....Rd .G..c...\n"
		+ "                                                                              00001901  73 0e 25 4f 45 30 a9 3b  53 82 fa ca 33 a9 cc ab s.%OE0.; S...3...\n"
		+ "                                                                              00001911  86 72 95 5d e6 71 8f db  29 96 b3 2c 96 b8 77 41 .r.].q.. )..,..wA\n"
		+ "                                                                              00001921  dd a9 9c f7 41 2a 29 96  c9 a6 d6 7c 04 93 0c 94 ....A*). ...|....\n"
		+ "                                                                              00001931  6d b0 3a 92 58 b2 ba c2  99 94 b5 30 b8 3b e7 58 m.:.X... ...0.;.X\n"
		+ "                                                                              00001941  be 7f bf 57 77 07 dc 4b  3d a9 e9 9c 70 22 ce 4d ...Ww..K =...p\".M\n"
		+ "                                                                              00001951  43 6d 0b 67 3c 63 c9 e4  ea 5b f6 11 d6 51 52 49 Cm.g<c.. .[...QRI\n"
		+ "                                                                              00001961  c0 d2 e9 f1 cd 91 51 64  59 e0 14 2d 2f 07 65 eb ......Qd Y..-/.e.\n"
		+ "                                                                              00001971  68 d8 4c 69 44 e3 9a 33  b6 be 64 f2 98 5d 2c 0a h.LiD..3 ..d..],.\n"
		+ "                                                                              00001981  ac 63 59 62 ef 4d e9 00  ce a4 b4 85 81 75 2e b1 .cYb.M.. .....u..\n"
		+ "                                                                              00001991  dc be 89 5d 94 f1 3d 4d  04 bf 2e 96 f5 bb dd e7 ...]..=M ........\n"
		+ "                                                                              000019A1  c9 49 72 dd b0 73 df fd  7d 8d 23 0f ca f5 b7 d7 .Ir..s.. }.#.....\n"
		+ "                                                                              000019B1  bf 37 71 9c 86 70 c7 29  16 22 43 9b cf f8 b8 c9 .7q..p.) .\"C.....\n"
		+ "                                                                              000019C1  f7 bd 64 ce 10 8a 13 5f  02 cb d8 a8 c4 e2 4b 26 ..d...._ ......K&\n"
		+ "                                                                              000019D1  39 28 db c0 ed 26 25 62  1f 44 51 8c 8b 92 98 ad 9(...&%b .DQ.....\n"
		+ "                                                                              000019E1  ae 6a 61 f0 e3 4e 60 81  98 e5 16 b7 d1 de d2 28 .ja..N`. .......(\n"
		+ "                                                                              000019F1  7d 7e d7 f8 8e 02 4c b0  c8 79 5b 76 8a b8 8d af }~....L. .y[v....\n"
		+ "                                                                              00001A01  af 5b 52 ae f0 cd 07 df  52 d7 e2 75 f9 62 7a 3b .[R..... R..u.bz;\n"
		+ "                                                                              00001A11  2b 47 5f 65 81 d9 d3 a6  de 8a 37 56 58 d1 78 cc +G_e.... ..7VX.x.\n"
		+ "                                                                              00001A21  ec 92 4d 8d a1 33 11 48  0a 50 b6 91 b7 ec 16 4b ..M..3.H .P.....K\n"
		+ "                                                                              00001A31  3c fa 7a 57 63 08 81 7b  97 68 8b 08 fc 39 92 c6 <.zWc..{ .h...9..\n"
		+ "                                                                              00001A41  d8 3a 9d 09 3d ab 53 44  90 6f 29 13 92 2f 6a 97 .:..=.SD .o)../j.\n"
		+ "                                                                              00001A51  04 ab af 47 52 44 05 69  14 90 dc 72 e7 92 03 67 ...GRD.i ...r...g\n"
		+ "                                                                              00001A61  28 b1 48 75 61 73 47 79  19 46 e8 db 2f c6 93 60 (.HuasGy .F../..`\n"
		+ "                                                                              00001A71  d2 ef 0f 8b 21 42 00 58  8e 55 2e 47 c7 25 eb 4d ....!B.X .U.G.%.M\n"
		+ "                                                                              00001A81  59 f1 dc 55 c2 e5 e6 f6  f6 e1 ae 62 ed 41 cd 64 Y..U.... ...b.A.d\n"
		+ "                                                                              00001A91  6c ec f9 0b d3 75 35 be  52 14 fb f5 5b 56 b2 ee l....u5. R...[V..\n"
		+ "                                                                              00001AA1  2c f0 56 dd 63 90 04 0d  21 49 4a 2c 9c 60 f7 4c ,.V.c... !IJ,.`.L\n"
		+ "                                                                              00001AB1  89 45 71 2f 06 df c5 0b  41 b5 21 0f 9a f6 07 c3 .Eq/.... A.!.....\n"
		+ "                                                                              00001AC1  e1 42 dd 8d 98 09 38 97  ab 6e 22 8b a5 e9 36 76 .B....8. .n\"...6v\n"
		+ "                                                                              00001AD1  7a e0 59 d6 9d 90 d5 d2  ad fd 81 6f cf 99 58 ff z.Y..... ...o..X.\n"
		+ "                                                                              00001AE1  7e 92 6a 4d 3b 99 0c 75  28 f4 32 52 3c 77 6e 2e ~.jM;..u (.2R<wn.\n"
		+ "                                                                              00001AF1  ba 04 06 a4 9b 5b 00 6a  95 54 cf 1c 0e 46 0a 18 .....[.j .T...F..\n"
		+ "                                                                              00001B01  12 ac 00 0a 5d 1b 08 20  d5 a7 7e 02 19 89 bb ae ....]..  ..~.....\n"
		+ "                                                                              00001B11  eb 05 3b 1e 22 0a 44 43  6a ef c7 f7 75 88 15 4d ..;.\".DC j...u..M\n"
		+ "                                                                              00001B21  7d 8a 89 40 35 92 78 cf  d9 71 ac a2 29 24 57 c7 }..@5.x. .q..)$W.\n"
		+ "                                                                              00001B31  56 69 af b9 2b 95 8b 2a  1a f1 58 9a bb 34 35 68 Vi..+..* ..X..45h\n"
		+ "                                                                              00001B41  58 49 f8 09 c1 ad d6 e4  5d b5 e1 70 b5 a2 3c e0 XI...... ]..p..<.\n"
		+ "                                                                              00001B51  12 35 5b 52 61 ef 2b 4f  26 cd aa 22 da 02 17 73 .5[Ra.+O &..\"...s\n"
		+ "                                                                              00001B61  35 1c 0e 07 83 01 47 81  ca 01 38 f8 46 6a 2f f8 5.....G. ..8.Fj/.\n"
		+ "                                                                              00001B71  67 ce 05 f9 3c 51 40 2f  a7 20 3d 25 f1 56 a9 b2 g...<Q@/ . =%.V..\n"
		+ "                                                                              00001B81  3c 1d e4 ed 0b ad 5a f5  42 fd 5a 2e 65 6a d6 e5 <.....Z. B.Z.ej..\n"
		+ "                                                                              00001B91  f5 d8 fe 53 62 f3 c3 9f  f8 72 8a 8c cf 09 30 c0 ...Sb... .r....0.\n"
		+ "                                                                              00001BA1  12 50 a6 9b 5f 0a 25 9f  97 0d fe e9 53 63 c4 44 .P.._.%. ....Sc.D\n"
		+ "                                                                              00001BB1  d7 4b 5e 4e 11 40 80 c5  07 85 a7 d1 6b f0 cb a1 .K^N.@.. ....k...\n"
		+ "                                                                              00001BC1  7c 20 41 26 86 5e 71 c2  de 63 23 01 45 73 ff 29 | A&.^q. .c#.Es.)\n"
		+ "                                                                              00001BD1  28 bf fc 25 5e 61 09 93  17 f4 27 55 6f 1d 08 66 (..%^a.. ..'Uo..f\n"
		+ "                                                                              00001BE1  a8 2a 38 3a 1e e0 80 ce  4f 41 09 35 bb f6 6b 67 .*8:.... OA.5..kg\n"
		+ "                                                                              00001BF1  6f 26 da 3a 1f d1 e3 aa  35 1e d4 aa 0a 8c 03 f6 o&.:.... 5.......\n"
		+ "                                                                              00001C01  c4 c3 96 24 ef e7 2e 2a  63 45 ef 57 40 e9 af 6b ...$...* cE.W@..k\n"
		+ "                                                                              00001C11  83 ef c1 be 9a 14 0e 66  f9 b9 1f 0f 1c 6b 4e d8 .......f .....kN.\n"
		+ "                                                                              00001C21  c7 b4 b2 ad a4 bd dc 45  95 ce 2c cc df 0f 65 dd .......E ..,...e.\n"
		+ "                                                                              00001C31  3f 38 94 98 27 1e 47 c3  9a 54 82 c3 35 45 81 b2 ?8..'.G. .T..5E..\n"
		+ "                                                                              00001C41  fd b3 a1 d8 7c b7 e8 a8  ee 98 63 fc 8b a0 84 e0 ....|... ..c.....\n"
		+ "                                                                              00001C51  0f 1c db 97 be ce b1 45  64 ed 38 61 12 65 c3 67 .......E d.8a.e.g\n"
		+ "                                                                              00001C61  0e 25 cc 38 c5 68 e3 38  1b ca 87 84 b3 be 1f 86 .%.8.h.8 ........\n"
		+ "                                                                              00001C71  4a 5c ee 38 b1 74 36 f2  e1 f4 d9 d9 84 e2 01 3e J\\.8.t6. .......>\n"
		+ "                                                                              00001C81  bf 0c b7 f2 0f 08 25 86  1b 92 19 1e 6d 81 c6 7d ......%. ....m..}\n"
		+ "                                                                              00001C91  b2 75 de 60 c2 7d 8a 6a  3e 10 6a 25 07 ce 5c 57 .u.`.}.j >.j%..\\W\n"
		+ "                                                                              00001CA1  7c 13 24 50 e0 5a 99 ea  65 df c9 a4 39 5a bf df |.$P.Z.. e...9Z..\n"
		+ "                                                                              00001CB1  1f 38 e4 eb 66 b3 be 16  a2 8b 83 4b 7d cd 11 4a .8..f... ...K}..J\n"
		+ "                                                                              00001CC1  40 9f 11 8a ad f1 26 ad  e9 af 4f 77 e1 4b ce 7c @.....&. ..Ow.K.|\n"
		+ "                                                                              00001CD1  ad ff 38 48 7a 9a 5f 1f  10 dd 0d 3e bc 3f 8b 78 ..8Hz._. ...>.?.x\n"
		+ "                                                                              00001CE1  51 f4 a4 0d 7d 84 ff 20  e5 f5 00 6f 5d 73 28 74 Q...}..  ...o]s(t\n"
		+ "                                                                              00001CF1  c3 40 3a 74 66 d0 99 a4  7a 28 0c a1 a4 db de dc .@:tf... z(......\n"
		+ "                                                                              00001D01  85 bb 40 e1 63 b4 49 9f  3d fa f4 05 3e c1 5d c1 ..@.c.I. =...>.].\n"
		+ "                                                                              00001D11  92 ae 99 f5 50 d6 8f 83  99 1f 6f d8 a3 83 f5 82 ....P... ..o.....\n"
		+ "                                                                              00001D21  26 42 73 43 d6 5f fb 31  c0 a2 fa 3f b2 4d ec cf &BsC._.1 ...?.M..\n"
		+ "                                                                              00001D31  06 8f eb d4 48 66 e8 56  43 6d 60 fb be a3 01 a0 ....Hf.V Cm`.....\n"
		+ "                                                                              00001D41  68 c3 fa 76 d2 c7 0c ae  c7 0e 3d d1 d7 98 13 fb h..v.... ..=.....\n"
		+ "                                                                              00001D51  6b 6a ff a6 8f 0f a2 fb  a1 54 cd c1 f7 2e c2 c3 kj...... .T......\n"
		+ "                                                                              00001D61  7d 78 78 df a6 c7 69 50  ea 46 1b f8 12 8a 81 f1 }xx...iP .F......\n"
		+ "                                                                              00001D71  fd d3 6b 3d 94 91 ba ed  cd fd b2 30 21 2c 5f 7e ..k=.... ...0!,_~\n"
		+ "                                                                              00001D81  71 89 04 7e e6 2c dc c5  92 c6 9f e5 02 4f d8 99 q..~.,.. .....O..\n"
		+ "                                                                              00001D91  c5 75 a5 1c 14 ea 99 90  69 11 40 e1 9a 60 3f 92 .u...... i.@..`?.\n"
		+ "                                                                              00001DA1  8e 40 8b b0 ae 4c 5c cb  43 71 fa 74 d7 86 fe 28 .@...L\\. Cq.t...(\n"
		+ "                                                                              00001DB1  3e 45 38 07 bf cf 50 a5  7c ae 59 60 4c 6b fe 20 >E8...P. |.Y`Lk. \n"
		+ "                                                                              00001DC1  ba 7f cd 4b 80 87 93 0e  31 28 37 e4 7d 00 df 0b ...K.... 1(7.}...\n"
		+ "                                                                              00001DD1  55 c1 dd 8a b4 d2 5d 17  9a 4d c8 a5 24 77 b8 5f U.....]. .M..$w._\n"
		+ "                                                                              00001DE1  f8 c7 c5 22 b1 18 f1 47  fe 87 7f bf 5c d4 43 11 ...\"...G ....\\.C.\n"
		+ "                                                                              00001DF1  ad b1 fb 7e e2 eb 98 b4  12 b8 c6 db 2c 1c 6d 06 ...~.... ....,.m.\n"
		+ "                                                                              00001E01  0a 63 a2 f2 b3 1c 14 8d  7f b1 76 c4 77 00 08 ad .c...... ..v.w...\n"
		+ "                                                                              00001E11  13 cf fa 83 df 09 09 4a  df 4f 81 a2 91 a5 85 27 .......J .O.....'\n"
		+ "                                                                              00001E21  1e fd e5 59 1e fe 0a ea  13 c7 ca b6 37 39 24 93 ...Y.... ....79$.\n"
		+ "                                                                              00001E31  6f 11 9f cd 45 d1 d1 9a  bb 41 f1 a1 83 44 bd c0 o...E... .A...D..\n"
		+ "                                                                              00001E41  b5 88 22 a1 ce 4e df 2f  87 92 dc 45 0e 56 1d 7d ..\"..N./ ...E.V.}\n"
		+ "                                                                              00001E51  66 8f 33 91 b7 0b 07 cc  59 83 cc a8 a1 fe 0c f7 f.3..... Y.......\n"
		+ "                                                                              00001E61  44 cd 94 07 c9 87 a3 e3  2e 40 71 92 dc 40 b5 fd D....... .@q..@..\n"
		+ "                                                                              00001E71  cc 69 db 5b 9a 8a 95 a3  0f 6a 84 bb e0 ef c0 5c .i.[.... .j.....\\n"
		+ "                                                                              00001E81  64 a0 b8 e8 54 96 8b dd  a0 c4 00 40 42 91 d5 c2 d...T... ...@B...\n"
		+ "                                                                              00001E91  6b 33 11 95 15 a1 64 c6  68 15 4a b8 d6 fa e0 4b k3....d. h.J....K\n"
		+ "                                                                              00001EA1  b0 a1 fd c7                                      ....\n"
		+ "                                                                              00001EA5  3e 97 35 79 63 36 9b 31  d5 39 cd 94 90 af 00 85 >.5yc6.1 .9......\n"
		+ "                                                                              00001EB5  b6 d0 d4 2f 48 f9 7c 07  5e 0a 4d 85 62 7e 59 08 .../H.|. ^.M.b~Y.\n"
		+ "                                                                              00001EC5  51 a0 80 ef 35 cd 25 b8  dd bd a0 ac df 0f 05 c7 Q...5.%. ........\n"
		+ "                                                                              00001ED5  de 99 86 c3 12 3c 30 e4  42 fe 97 8f c1 fd 1d a1 .....<0. B.......\n"
		+ "                                                                              00001EE5  6c d7 4d cb 74 21 7a 94  81 ea 34 33 50 32 d1 2d l.M.t!z. ..43P2.-\n"
		+ "                                                                              00001EF5  87 e2 25 6c f6 34 9f f8  bd e6 23 b4 1f 1c 6d fa ..%l.4.. ..#...m.\n"
		+ "                                                                              00001F05  a4 30 db e8 bc f9 f8 65  50 82 e9 93 cc 18 b3 b2 .0.....e P.......\n"
		+ "                                                                              00001F15  b7 26 c4 8c 98 a8 4b a4  59 f3 09 44 2a 24 85 e2 .&....K. Y..D*$..\n"
		+ "                                                                              00001F25  66 fc 4c 0d 94 78 27 47  1b f3 b6 c4 25 8e 96 65 f.L..x'G ....%..e\n"
		+ "                                                                              00001F35  a1 f8 e2 f5 ac 33 78 8a  b8 c7 87 d9 a4 6c 6c ac .....3x. .....ll.\n"
		+ "                                                                              00001F45  40 49 1d ed a6 04 0a fc  2c 59 79 31 8a fb 8a 6c @I...... ,Yy1...l\n"
		+ "                                                                              00001F55  a3 c0 24 e7 68 bd 82 a3  95 30 9a a0 3c ce 94 21 ..$.h... .0..<..!\n"
		+ "                                                                              00001F65  99 d7 cb 79 5c ab 43 b2  f0 9e 18 bc c9 51 13 a9 ...y\\.C. .....Q..\n"
		+ "                                                                              00001F75  d9 72 48 5e ab 7d 8e 17  24 da 48 de 83 74 23 f5 .rH^.}.. $.H..t#.\n"
		+ "                                                                              00001F85  41 02 8a 1c ef d9 20 2e  83 b2 fd a1 a5 0b 52 86 A..... . ......R.\n"
		+ "                                                                              00001F95  fa 46 e9 d0 9f 53 2c 9b  cf 2a b8 5f cc 64 48 de .F...S,. .*._.dH.\n"
		+ "                                                                              00001FA5  2e 96 5c 69 96 aa a6 78  fc 5a 13 94 01 c6 54 ac ..\\i...x .Z....T.\n"
		+ "                                                                              00001FB5  ef a4 1a 1c b1 fe 4c 0d  de 30 b8 23 ff e8 43 3c ......L. .0.#..C<\n"
		+ "                                                                              00001FC5  0a b1 98 36 a0 e0 8d 89  e0 2d e6 91 d9 5a 66 0f ...6.... .-...Zf.\n"
		+ "                                                                              00001FD5  f0 d7 a1 4f a3 0c bf 67  8d 21 0b a0 a6 28 b1 af ...O...g .!...(..\n"
		+ "                                                                              00001FE5  06 3c 22 78 c3 4b 65 50  92 f5 4b be 4c 87 ab 2e .<\"x.KeP ..K.L...\n"
		+ "                                                                              00001FF5  b4 e7 8d f1 55 97 41 e1  d5 a8 10 bc 2d 3d 08 de ....U.A. ....-=..\n"
		+ "                                                                              00002005  c8 cf 40 c0 46 c1 9b c7  23 13 13 74 0a 68 40 f0 ..@.F... #..t.h@.\n"
		+ "                                                                              00002015  e6 36 3b 5a 9b a5 61 be  f4 b0 85 30 9f 39 94 4f .6;Z..a. ...0.9.O\n"
		+ "                                                                              00002025  b1 31 2a d7 ec 7c 98 4f  16 d5 97 61 3e 4c 84 28 .1*..|.O ...a>L.(\n"
		+ "                                                                              00002035  b6 57 ee e1 6e 95 1e 6a  6b ca 7c 61 eb a4 61 be .W..n..j k.|a..a.\n"
		+ "                                                                              00002045  28 3c 9b b8 f1 56 9a ba  7e 29 05 13 06 83 61 f1 (<...V.. ~)....a.\n"
		+ "                                                                              00002055  c5 73 d9 30 df 4d c2 7c  74 b1 14 da 7a 3c ca 37 .s.0.M.| t...z<.7\n"
		+ "                                                                              00002065  17 41 83 a3 cd 4c 08 d5  49 60 e6 b3 f0 c7 0e 4d .A...L.. I`.....M\n"
		+ "                                                                              00002075  f5 94 09 61 32 47 0c d5  85 9a b5 9c 05 e2 3d 7e ...a2G.. ......=~\n"
		+ "                                                                              00002085  f6 41 91 5a 92 5f 28 3c  cc ad af ae 86 b9 f5 28 .A.Z._(< .......(\n"
		+ "                                                                              00002095  5a 6b 18 56 2e 28 66 27  84 85 c9 9f 57 3a 1f 2c Zk.V.(f' ....W:.,\n"
		+ "                                                                              000020A5  1f 7d 3e ae 04 9e b9 1a  0e b4 64 19 6a 2a 97 e5 .}>..... ..d.j*..\n"
		+ "                                                                              000020B5  0e 9a 55 ff 97 41 c1 41  f5 87 b3 1a 4a 79 6d 5a ..U..A.A ....JymZ\n"
		+ "                                                                              000020C5  62 dd 1f 4a 62 dd 1f 1e  8c 5c 29 fe 35 0b 2f ad b..Jb... .\\).5./.\n"
		+ "                                                                              000020D5  df 9b a5 ff 77 48 eb 13  c1 27 94 4f 28 9f 50 3e ....wH.. .'.O(.P>\n"
		+ "                                                                              000020E5  a1 7c 42 f9 84 f2 09 e5  13 ca 27 94 4f 28 9f 50 .|B..... ..'.O(.P\n"
		+ "                                                                              000020F5  3e a1 7c 42 f9 94 4f 28  d5 f2 7f 8b f6 55 c8 71 >.|B..O( .....U.q\n"
		+ "                                                                              00002105  2f 4f 83 00 00 00 00 49  45 4e 44 ae 42 60 82 0d /O.....I END.B`..\n"
		+ "                                                                              00002115  0a 31 36 0d 0a 43 6f 6e  74 65 6e 74 2d 54 79 70 .16..Con tent-Typ\n"
		+ "                                                                              00002125  65 3a 20 44 6f 6e 65 0d  0a 0d 0a 0d 0a 30 0d 0a e: Done. .....0..\n"
		+ "                                                                              00002135  0d 0a                                            ..\n"
		+ "\n"
		+ "";

	
	String RFTRACE_EXAMPLE = ""
    +"0000 436F6E74656E742D547970653A2064760D0A436F6E74656E742D4C6F63617469     Content-Type: dv..Content-Locati\n"
    +"0001 6F6E3A20687474703A2F2F7777772E676F6F676C652E636F6D2F0D0A4E6F7661     on: http://www.google.com/..Nova\n"
    +"0002 7272612D43616368652D436F6E74726F6C3A206D61782D6167653D3235393230     rra-Cache-Control: max-age=25920\n"
    +"0003 30300D0A4E6F76617272612D506167652D49643A203132373939323230300D0A     00..Novarra-Page-Id: 127992200..\n"
    +"0004 4E6F76617272612D5552493A20687474703A2F2F676F6F676C652E636F6D2F0D     Novarra-URI: http://google.com/.\n"
    +"0005 0A436F6E74656E742D456E636F64696E673A20677A69700D0A4E6F7661727261     .Content-Encoding: gzip..Novarra\n"
    +"0006 2D436F6E74656E742D4C656E6774683A20323130340D0A436F6E74656E742D4C     -Content-Length: 2104..Content-L\n"
    +"0007 656E6774683A20313232390D0A0D0A1F8B080000000000000075544F6C146514     ength: 1229..............uTOl.e.\n"
    +"0008 FFBDD9E9EE9676B614CBAA48CB40EC6A40BA942A35EA4A2AA4B5E18F901A403D     ......v....H.@.j@..*5.J*......@=\n"
    +"0009 D4E9F6EB74607766D999DD05F4004482918B17DD34F18047E5E0CD7831694C38     ....t`wf......D.....4..G...x1iL8\n"
    +"0010 98349183C8D54413124D484C84680AADEF9B6F66DD8A6C36F3BDEFBDDFFBFFBD     .4....D..MHL.h....of..l6........\n"
    +"0011 0702B01D045D4702FCD75087CEDF2C3AF8DB87247F35A4909CF03CBB249806CE     .....]G...P...,:...$5....<.$...\n"
    +"0012 3162F37C10545ECAE7CB96531AB243D950D12B87F73CB291B4D168B40B614ABE     1b.|.T^....S..C.P.+..<....h..aJ.\n"
    +"0013 FFB0C02A16BD9A1BF8790CFCBFA6E306A5BC70F332C8D44560757555460E1975     ...*.....y........p.2..E`uuUF..u\n"
    +"0014 13A92C13C00E01CE6488E9EDE86B718705885064FAD936EE28A742F88469B38D     ..,.....d....kq...Pd..6.(.B..i..\n"
    +"0015 5B10481016FFC3DD27A0137E637A8FE40E28EEA4111EE90C8CBDF3A582707381     [.H.....'..~cz...(...........ps.\n"
    +"0016 35536894053A8876B06C5B9B89C302C9041D67BA1F7D14F0A9F37906698EBFA7     5Sh..:.v.l[.......g..}....y.i...\n"
    +"0017 890F14EA1B653297815FAB96F6FA56A192AB54C55CC1B17395BA552A8CE44E17     .....e2.._....V...T.\\..s..U*..N.\n"
    +"0018 1E51207B70647CBE3438B25FB883BBF7F85EAD5A147C73ECD2A95CCDB70B63E3     .Q {pd|.48._.....^.Z.|s...\\...c.\n"
    +"0019 474FEE3B3C3E36FCE2892373F6CCE8EC01F7C4DC8173A36746EDE189FDAF0F07     GO.;<>6...#s.........s.gF.......\n"
    +"0020 B6408A12231CC17332F06D2AA46F5B21F5CA484455B845E1AB8405D29438C9F2     .@..#..s2.m*.o[!..HDU.E......8..\n"
    +"0021 77A4C22B4AE13BA5F06A063B0E7AB6E346B5297A6EE0B835F188F0053A297143     w..+J.;..j.;.z..F.)zn..5....:)qC\n"
    +"0022 F52849751CA2C7308DB0C5E8D00CFEFEC0C21ED055E0F6EDDBA4ADE2268BB72E     .(Iu...0............U.......&...\n"
    +"0023 60BD727BAF175A9ADF2B9D1658476031BF54531277B9CFA45E0C1F37690503C0     `.r{..Z..+..XG`1.TS.w...^..7i...\n"
    +"0024 D2D2520C2249FCC4902DC0C2C202692BA1E92D92FDA7942B8F740F0FA4C7CFA2     ..R.\"I...-....i+..-....+.t......\n"
    +"0025 965252A08BE802561060A0C5ED11E826BACFDC4B186822A7B89B5A55DC68CDD6     .RR....V.`.....&...K.h\"...ZU.h..\n"
    +"0026 2D2EE1ECB42FAC6A713EAEA44109033F72CE1B9A18544AFD2DA5BE92E5DA35CB     -..../.jq>..A..?r....TJ.-.....5.\n"
    +"0027 16D381E7955AD5CF489D5FF03636109DA77E3464AC77EEDC91513D9051A93CE9     .....Z..H._.66...~4d.w...Q=.Q.<.\n"
    +"0028 3CDFEA9C27132BFFE64977C384B648DDCD521E16DBA08F49C3313C0E434DBC39     <...'.+..Iw...H..R.....I.1<.CM.9\n"
    +"0029 15C61995FDA22A02D132FBFBB0E5EF3EB32FB5FC2DF3EDB2F4B7DCEE4FBB10FB     ......*..2.....>./..-.......O...\n"
    +"0030 5B667F97637F5A37FB13ECAF77F299B2392E44C9716DF360AD78EA6CFB98CB7E     [f.cZ7....w...9.D.qm.`.x.l...~\n"
    +"0031 4444A8A793C1C3C37B887B9E382E66F490BB94002F1FBC85AC11EF012427CB5C     DD......{.{.8.f...../.......$'.\\\n"
    +"0032 391FF18F3145C65C9198682B2079CC9915DE1ACCA78CF95A62A21D01FD905559     9...1E.\\..h+ y.........Zb.....UY\n"
    +"0033 835864C4CF12B118230E8BC61AC4EFC8D25689887607D253F35EA5C209B6A178     .Xd.....#........V..v..S.^.....x\n"
    +"0034 5764E910A3E2A5818E09B945DB2127185293906883402F7B55D14146BC427830     Wd.........E.!'.R..h.@/{U.AF.Bx0\n"
    +"0035 123CBBD9C434B23C2FF11823E5447B3BAC354B7574C98A99EF9BCA34CF6F3671     .<...4.</..#.D{;.5Kut......4.o6q\n"
    +"0036 9D4DC7838C1ED570D317014FACED47AAD71F56BDC1AA7F49D56870919A726CD7     .M.....p...O..G...V...I.hp..rl.\n"
    +"0037 745CE0FB5B7FC87E3DA187F31511AA9FBCC16FF0681D057A7B973AD8B2C1F3C6     t\\..[.~=.........o.h..z{.:.....\n"
    +"0038 EF1E3D63D168444F4E4A7E95AF1B9983D1FB37DF94EF3F7E17D460ABE3CA8ED6     ..=c.hDONJ~.......7...?~..`.....\n"
    +"0039 C4463536793536EF66A05BB33E6F961EA2CFB94EEFC945BB496176B746ABD317     .F56y56.f.[.>o.....N..E.Iav.F...\n"
    +"0040 D5BAC32B8D81EB35ED7906EE618D6BF4913C0DD63C2B35D1C7C1896AE0F85C92     ...+...5.y..a.k..<..<+5....j..\\.\n"
    +"0041 AB47AA9E5DB5CABEC1F8B31287F46B359608DF6FE229E5E2855618EBAC19AF16     .G..].........k5...o.)...V......\n"
    +"0042 0CCD0765EE432FD1DF6CFB0D69FB1A5D09953BA7BC522D703CD7375878450AD1     ...e.C/..l..i..]..;..R-p<.7XxE..\n"
    +"0043 3D2695CCB87BF57A5D76FB167D859D30D0F985B97BD7F02E73A719666F683A0B     =&...{.z]v..}..0....{...s..foh:.\n"
    +"0044 9E6641EA48D5A95B45353A99780D625D265E54E8CAC4DB09DD4DF4AB605F6E05     .fA.H..[E5:.x.b]&^T......M..`_n.\n"
    +"0045 DB5D5106A27037506CFA4B743D8974D4ACADFF002CF3E70038080000             .]Q..p7Pl.Kt=.t.....,...8...   \n"; 

	public Main()
	{
		super("DVDecoder");
		setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		JFrame f = this;
		f.setPreferredSize(new Dimension(1200,800));
		Container container = f.getContentPane();
		
		in.setText(STARTUP_CONTENT);
        in.setFont(new Font("Courier", Font.PLAIN, 12));
        decodeButton.addActionListener(this);
        in.setEditable(true);
        out.setEditable(false);
        
        JScrollPane inputArea = new JScrollPane(in);
        JScrollPane outputArea = new JScrollPane(out);
        
        inputArea.setSize(100,100);
        outputArea.setSize(100,100);
        
        //Menu
        JMenuBar menuBar = new JMenuBar();
        JMenu menu = new JMenu("Run");
        
        //Decode 
        JMenuItem decodeMenuItem = new JMenuItem("Decode");
        decodeMenuItem.addActionListener(this);
        menu.add(decodeMenuItem);
        
        //Load
        JMenuItem loadMenuItem = new JMenuItem("Load");
        loadMenuItem.addActionListener(this);
        menu.add(loadMenuItem);
        
        //Clear  
        JMenuItem clearMenuItem = new JMenuItem("Clear");
        clearMenuItem.addActionListener(this);
        menu.add(clearMenuItem);
        
        //Test   
        JMenu testSubmenu = new JMenu("Test");
        JMenuItem testPcapMenuItem = new JMenuItem("PCAP Example");
        JMenuItem testRftraceMenuItem = new JMenuItem("RFTRACE Example");
        testSubmenu.add(testPcapMenuItem);
        testSubmenu.add(testRftraceMenuItem);
        testPcapMenuItem.addActionListener(this);
        testRftraceMenuItem.addActionListener(this);
        menu.add(testSubmenu);
        
        //Help
        JMenuItem helpMenuItem = new JMenuItem("Help");
        helpMenuItem.addActionListener(this);
        menu.add(helpMenuItem);
        
        //Exit
        JMenuItem exitMenuItem = new JMenuItem("Exit");
        exitMenuItem.addActionListener(this);
        menu.add(exitMenuItem);
   
        //Add our Menu
        menuBar.add(menu);
        setJMenuBar(menuBar);

        
		//Layout layout = new GridLayout();
		f.setLayout(new GridLayout(1,2));
		GridBagConstraints c = new GridBagConstraints();

		
		container.add(inputArea,c);
		
		
		container.add(outputArea, c);
		
	
        
        
	}



    /**
     * Create the GUI and show it.  For thread safety,
     * this method should be invoked from the
     * event-dispatching thread.
     */
    private static void createAndShowGUI() {
        //Create and set up the window.
        JFrame frame = new JFrame("DVdecoder");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);


        Main m = new Main();
        m.pack();
        m.setVisible(true);
    
    }

    public static byte[] file2byteArray(String filename)
    {
    	return null;
    }
    
    public static void main(String[] args) {
        //Schedule a job for the event-dispatching thread:
        //creating and showing this application's GUI.
        javax.swing.SwingUtilities.invokeLater(new Runnable() {
            public void run() {
                createAndShowGUI();
            }
        });
    }
    
    
    public void alert(String msg)
    {
    	JOptionPane.showMessageDialog(this,msg,"title",JOptionPane.PLAIN_MESSAGE);
    	
    }
    private void setTextAreaToFile(JTextArea t, String filename)
    {
    	try 
    	{
    		String text = (filename == null) ? "" : utils.file2String(filename);
    		t.setText(text);
    	}
    	catch (Exception e)
    	{
    		t.setText(e.toString());
    	}
    }
   
    private void doLoad()
    {
        JFileChooser c = new JFileChooser();
        // Demonstrate "Open" dialog:
        int rVal = c.showOpenDialog(this);
        if (rVal == JFileChooser.APPROVE_OPTION) {
        	String path = c.getSelectedFile().getAbsolutePath();
          try
          {
        	  in.setText(utils.fileToPcapHexDump(path));
          }
          catch (Exception e)
          {
        	  in.setText(e.toString());
          }
          
        }
        if (rVal == JFileChooser.CANCEL_OPTION) {
          //filename.setText("You pressed cancel");
          //dir.setText("");
        }
    }
    private void doClear()
    {
    	setTextAreaToFile(in,null);
    	out.setText("");
	
    }
    public void actionPerformed(ActionEvent e) {
    	
    	String cmd = e.getActionCommand();
    	if (cmd == "Clear") doClear();
    	
    	else if (cmd == "Exit") System.exit(0);
    
    	else if (cmd == "RFTRACE Example")
    	{
    		in.setText(RFTRACE_EXAMPLE);
    	}
    	else if (cmd == "PCAP Example")
    	{
    		in.setText(PCAP_EXAMPLE);
    	}
    	else if (cmd == "Load") doLoad();
    	else if (cmd == "Help")
    	{
    		in.setText(HELP_TEXT);
    	}
    	else if (cmd == "Decode")
    	{
    		String hex = in.getText();
    		try {
    	
    			String h = utils.extractDVHexStringFromHexDump(hex);
    			System.out.println("DVHEX: " + h);
    			System.out.println("LEN=" + h.length());
    			System.out.println("DVHEX: (" + (h.length()/2) + ")" + h);
    			h = utils.cleanHexString(h);
    			byte[] zbytes = utils.hexStringToByteArray(h);
    			//FIXME - SHould be static.
				Dv dv = new Dv();
    			if (utils.isGziped(zbytes))
    			{
    				byte[] b = utils.unzipByteArray(zbytes);
    				System.out.println("UNSIPPED DVHEX: " + utils.byteArrayToHexString(b));
    				

    				String u = utils.unzipHexString(h);
    				System.out.println("(" + (u.length()/2) + " bytes)" + u);
    				String dump = dv.getDump(b);
    				System.out.println(dump);
    			
    				out.setText("<pre>\n" + dump + "</pre>");
    			
    			}
    			else 
    			{
    				System.out.println("First 2 bytes="+zbytes[0] + " and " + zbytes[1]);
    				out.setText(dv.getDump(zbytes));
    			}
 
    	
    		}
    
    		catch (Exception ee)
    		{
    			JOptionPane.showMessageDialog(this, "Whoops! It is likely the content you have entered is not the correct format.  Too see correct formats choose \"Test\" from the menu.");
    			ee.printStackTrace();
    		}

    	}//end "Decode"
    }
    	

}
