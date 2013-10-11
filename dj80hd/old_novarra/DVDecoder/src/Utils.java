import java.io.*;
import java.nio.ByteBuffer;
import java.util.zip.GZIPInputStream;
import java.util.zip.Inflater;
import java.util.zip.ZipInputStream;


public class Utils
{
	public byte[] dumpStringToByteArray(String s)
	{
		return null;
	}
	
	/*
	 * Takes an RFTRACE or PCAP style hex dump and extracts the actual hex data.
	 * Addresses, text conversions, etc. are left out and a whitespace free hex string
	 * is returned.
	 * 
	 * RFTRACE style looks like this:
	 *  A. Full Line:
	 *  0000 436F6E74656E742D547970653A2064760D0A436F6E74656E742D4C6F63617469     Content-Type: dv..Content-Locati
	 *  B. Partial line:
	 *  0010 41                                                                   A
	 *  
	 * PCAP hexdump style looks like this:
	 * A. Full Line:
	 * 00000380  2d 4d 6f 64 65 3d 64 76  2c 46 6f 6e 74 54 61 62 -Mode=dv ,FontTab
	 * B. Partial Line
	 * 00001080  41    
	 * 
	 * A "SAVE_CONTENT_STREAM" from brew will look like this:
	 * 00000000 23 23 23 23 23 20 42 45 47 49 4e 20 44 56 20 68 ##### BEGIN DV h
     * 00000010 74 74 70 3a 2f 2f 73 63 69 73 73 6f 72 73 6f 66 ttp://scissorsof
     * 00000020 74 2e 63 6f 6d 2f 6e 6f 76 61 72 72 61 2f 74 65 t.com/novarra/te
     * 00000030 73 74 2e 68 74 6d 6c 0a 0a 00 01 00 00 00 24 00 st.html.......$.
	 * 
	 * 
	 * When PCAP hexdump is the response (which it would be) there is whitespace in front of the address number.
	 * 
	 * 
	 */
	public String extractHexDataFromHexDump(String dump)
	{
		StringBuffer hexdata = new StringBuffer();
		String[] lines = dump.split("\\n");
		//System.out.println("Got "+lines.length + " lines.");
		for (int i=0;i<lines.length;i++)
		{
			String line = lines[i];
			//System.out.println("LINE:" + line);
			int index = 0;
			//Ignore any leading whitespace in the line.
			while ((index < line.length()) && line.charAt(index) <= 32) 
			{
				index++;
			}
			
			if (index >= line.length()) continue;
			//if we have a line that looks like it begins with an address...
			if (isHexDigit(line.charAt(index)) 
					&& isHexDigit(line.charAt(index + 1)) 
					&& isHexDigit(line.charAt(index + 2))
					&& isHexDigit(line.charAt(index + 3)))
			{
				//FIXME - CHeck length of lines
				//If it is the form of RFTRACE like
				//0000 436F6E74656E742D547970653A2064760D0A436F6E74656E742D4C6F63617469     Content-Type: dv..Content-Locati 	
				if (Character.isWhitespace(line.charAt(index + 4)))
				{
					String h = line.substring(index + 5, index + 5 + 64);
					//System.out.println("DATA:" + h);
					hexdata.append(h);
				}
				
				//Else if we have PCAP style dump like 
				//00000380  2d 4d 6f 64 65 3d 64 76  2c 46 6f 6e 74 54 61 62 -Mode=dv ,FontTab
				else if (isHexDigit(line.charAt(index + 4)) 
						&& isHexDigit(line.charAt(index + 5)) 
						&& isHexDigit(line.charAt(index + 6))
						&& isHexDigit(line.charAt(index + 7)) 
						&& Character.isWhitespace(line.charAt(index + 8))
						&& Character.isWhitespace(line.charAt(index + 9))
						
				)
				{
					//System.out.println("LINE:"+line);
					String hex = line.substring(index + 10, index + 10 + 48);
					hex = nowhitespace(hex);
					//System.out.println("DATA:" + hex);
					hexdata.append(hex);
				}			
			}				
		}
		String ret = cleanHexString(hexdata.toString());
		System.out.println("ret="+ret);
		return ret;
		
	}//extractHexDataFromHexDump
	
	
	/**
	 * Return the unsigned integer value of a hex string if it is interpreted as a sequence of
	 * ASCII numbers, for example "373432" would be interpreted as 742
	 * 
	 * @param hexString
	 * @return the interger value of the hex String
	 * @return -1 for invalid hex String.
	 * 
	 */
	public int hexStringToInt(String hexString)
	{
		byte[] digits = this.hexStringToByteArray(hexString);
		int sum = 0;
		//Example 373432 would be bytes 37,34,32
		for (int i=0;i<digits.length;i++)
		{
			if ((digits[i] > 0x39) || (digits[i] < 0x30)) return -1;
			sum = (sum * 10) + (digits[i] - 0x30);
			//String hexdigit = Integer.toHexString(digits[i]);
			//System.out.println("Sum not " + sum + " for digit " + hexdigit);
		}
		return sum;
	}
	
	/**
	 * Takes an RFTRACE or PCAP style hexdump and returns the DV content as a 
	 * whitespace-free hex string
	 * 
	 * @param dump
	 * @return
	 */
	public String extractDVHexStringFromHexDump(String dump)
	{
		String data = extractHexDataFromHexDump(dump);	
		return extractDVHexStringFromHexString(data);
	}
	
	/**
	 * Extract the DV part as a Hex String from another Hex String which may contain
	 * other stuff like HTTP headers, etc.
	 * @param hex
	 * @return null if it is not recognized as DV content.
	 * 
	 * 
	 */
	public String extractDVHexStringFromHexString(String hex)
	{
		//First, attempt to find a "Content-Type: dv" HTTP header and go from there.
		int i = hex.indexOf("436F6E74656E742D547970653A206476");
		if (i>=0)
		{
		
		//now find the content length (add with 0D0A at front to avoid Novarra-Content-Length
			String clString = "0D0A436F6E74656E742D4C656E6774683A20";
			int clStringIndex = hex.indexOf(clString, i);
			System.out.println("Found CL at " + clStringIndex);
			if (clStringIndex < 0) return null;
			//Get the character index of the first character of the length;
			int lengthIndex1 = clStringIndex + clString.length();
			System.out.println("Found L1 at " + lengthIndex1);
			//Get the cahacter index just past the length
			int lengthIndex2 = hex.indexOf("0D0A", lengthIndex1);
			String lengthAsHexString = hex.substring(lengthIndex1,lengthIndex2);
			System.out.println("lengthAsHexString " + lengthAsHexString);
			int length = hexStringToInt(lengthAsHexString);
			System.out.println("lengthAsHexStringInt " + length);
			i = lengthIndex2 + 4 + 4; //Assume this is last header and there are 2 newlines (0d0a)
			String dvhex = hex.substring(i,i + (length*2));	
		
			return dvhex;
		}
		//If that doesn't work, just search for the start of DV content "000100"
		//FIXME - hex could contain 000100 and NOT be DV content !
		else if (0 <= hex.indexOf("000100"))
		{
			int startOfDv = hex.indexOf("000100");
			//FIXME - we assume that the end of DV is the end of the string which may not be
			return hex.substring(startOfDv,hex.length());
		}
		return null;
	}
	
	/**
	 * Reads a file and returns the content as an ascii string
	 * @param filePath
	 * @return
	 * @throws java.io.IOException
	 */
    public String file2String(String filePath) throws java.io.IOException
    {
        StringBuffer fileData = new StringBuffer(1000);
        BufferedReader reader = new BufferedReader(
                new FileReader(filePath));
        char[] buf = new char[1024];
        int numRead=0;
        while((numRead=reader.read(buf)) != -1){
            String readData = String.valueOf(buf, 0, numRead);
            fileData.append(readData);
            buf = new char[1024];
        }
        reader.close();
        return fileData.toString();
    }
    public String file2HexString(String filepath) throws Exception
    {
    	byte[] b = file2ByteArray(filepath);
    	return byteArrayToHexString(b);
    }
    public byte[] file2ByteArray(String filepath) throws Exception
    {
    	File file = new File(filepath);
    	InputStream is = new FileInputStream(file);
    	long length = file.length();
    	if (length > Integer.MAX_VALUE) throw new Exception("File too large " + length + " bytes");
    	byte[] bytes = new byte[(int)length];
    	    
    	// Read in the bytes
    	int offset = 0; int numRead = 0;
    	while (offset < bytes.length
    	               && (numRead=is.read(bytes, offset, bytes.length-offset)) >= 0) 
    	{
    		offset += numRead;
    	}
    	    
    	        // Ensure all the bytes have been read in
    	if (offset < bytes.length) throw new IOException("Could not completely read file "+file.getName());
    	is.close();
    	return bytes;
    }//file2ByteArray

    /**
     * Makes a hex string all uppercase and removes any non-hex digits.
     * @param hex
     * @return
     */
	public String cleanHexString(String hex)
	{
		StringBuffer ret = new StringBuffer();
		hex = hex.toUpperCase();
		for (int i=0; i<hex.length();i++)
		{
			if (isHexDigit(hex.charAt(i)))
			{
				ret.append(hex.charAt(i));
			}
		}
		return ret.toString();
	}
	
    /**
     * Removes whitespace from a string
     * @param source
     * @return
     */
    public String nowhitespace(String source) {
        return source.replaceAll("\\s+", "");
    }

    /**
     * Returns true if c is a hex digit, false otherwise.
     * @param c
     * @return
     */
	public boolean isHexDigit(char c)
	{
		return (('0' <= c && c <= '9') || ('a' <= c && c <= 'f') || ('A' <= c && c <= 'F'));
		
	}

	
	/**
	 * Returns a pcap style hexdump of a given byte array.
	 */
	public String pcapStyleHexDump(byte[] b)
	{
		int k;
		StringBuffer out = new StringBuffer();
		for (k=0; k < (b.length); k = k + 16)
		{
			//Address		
			String addressString = String.format("%08x",k).toUpperCase();
			out.append(addressString).append("  ");
		
			
			//If k < (b.length -16)
			//Hex data
			for (int m=0; m<16; m++)
			{
				//Defend against the last line where there is less than 16 bytes left.
				String byteHexString = (k+m >= b.length) ? "  " : byteToHexString(b[k+m]);
				out.append(byteHexString);
				out.append(" ");
				//Extra space at midway and at tend.
				if (m==8 || m==15) out.append(" ");
			}
			
			//Defend against case where last line has less than 16 bytes
			int asciiStringLength = ((k+16) > b.length) ? (b.length % 16) : 16;
			out.append(byteArrayToAsciiString(b,k,asciiStringLength));
			
			
			//Ascii format
			
			out.append("\n");
		}

		return out.toString();
	}
	/**
	 * Writes a given byte array to a file
	 * @param buf
	 * @param fname name of the file to write
	 * @throws Exception
	 */
	public void byteArrayToFile(byte[] buf, String fname) throws Exception
	{
		FileOutputStream fos = new FileOutputStream(fname);
		fos.write(buf);
		fos.close();
	}

	/**
	 * Best guess attempt to see if a given hexString is gzipped content.
	 * @param hexString
	 * @return
	 */
	public boolean isGziped(String hexString)
	{
		return hexString.startsWith("1F8B");
	}
	
	/**
	 * Best guess attempt to see if a given byte array is gzipped content.
	 * FIXME - Make this better than just a guess
	 * @param hexString
	 * @return
	 */	
	public boolean isGziped(byte[] b)
	{
		return (b.length > 3 && b[0] == (byte)0x1F && b[1] == (byte)0x8B);
	}


	/**
	 * Takes a byte array of gzipped content and returns a byte array that is unzipped
	 * @param in
	 * @return
	 * @throws Exception
	 */
	public byte[] unzipByteArray(byte[] in) throws Exception
	{
		ByteArrayInputStream bis = new ByteArrayInputStream(in);
		GZIPInputStream zipin = new GZIPInputStream(bis);
		ByteArrayOutputStream bos = new ByteArrayOutputStream(in.length);
		byte[] buf = new byte[1024];  //size can be 
	    int len;
	    while ((len = zipin.read(buf)) > 0) {bos.write(buf,0,len);}
	    bos.close();
	    return bos.toByteArray();      
	}
	
	/**
	 * Takes a hexString of gzipped content and returns an unzipped hexString
	 * @param gzipedHexString
	 * @return
	 * @throws Exception
	 */
	public String unzipHexString(String gzipedHexString) throws Exception
	{
		byte[] b = hexStringToByteArray(gzipedHexString);
		byte[] out = unzipByteArray(b);
		return byteArrayToHexString(out);
	}
	
	/**
	 * Takes a hexString and returns it in byte array format.
	 * @param hex
	 * @return
	 */
	public byte[] hexStringToByteArray(String hex)
	{
		byte[] bts = new byte[hex.length() / 2];
		for (int i = 0; i < bts.length; i++) 
		{
			String hexdigit = hex.substring(i*2, (i*2)+2);
			
		   bts[i] = (byte) Integer.parseInt(hexdigit, 16);
		   System.out.println(bts[i] + " from " + hexdigit );
		}
		return bts;
	}
	
	
	
	/**
	 * Converts a byte array to an ascii string
	 * Unprintable characters will show up as period (.)
	 * @param bytes
	 * @return
	 */
	public String byteArrayToAsciiString(byte[] bytes)
	{
		return byteArrayToAsciiString(bytes,0,bytes.length);
	}
	/**
	 * This is used to give a visual indication of the binary content.
	 * e.g. {0x65, 0x6E, 0x67, 0x0D} becomes "eng."
	 * @param bytes
	 * @param startIndex
	 * @param length
	 * @return
	 */
	public String byteArrayToAsciiString(byte[] bytes, int startIndex, int length)
	{
		StringBuffer buf = new StringBuffer();
		for (int i=startIndex; i < startIndex + length; i++)
		{
			byte b = bytes[i];
			//Make each non printable character a .
			if (b < 32 || b >126)
			{
				buf.append(".");
			}
			//Make each printable byte its equivalent ascii character.
			else 
			{
				buf.append((char)b);
			}
		}
		return buf.toString();
	}
	
	/**
	 * Converts a byte array to a hex string representation.
	 * e.g. {0x65, 0x6E, 0x67} becomes "656E67"
	 */
	public String byteArrayToHexString(byte bytes[])
	{
		return byteArrayToHexString(bytes,0,bytes.length);
	}
	public String byteArrayToHexString(byte bytes[],int start,int len)
	{
		StringBuffer retString = new StringBuffer();
		for (int i = start; ((i < len + start) && (i < bytes.length)); ++i)
		{
			retString.append(byteToHexString(bytes[i]));
				//Integer.toHexString(0x0100 + (bytes[i] & 0x00FF)).substring(1));
		}
		return retString.toString();
	}
	
	/**
	 * Converts the given byte to its hex string equivalent.
	 * e.g. byte 13 would be "0D"
	 * @param b
	 * @return
	 */
	public String byteToHexString(byte b)
	{
		return Integer.toHexString(0x0100 + (b & 0x00FF)).substring(1);
	}
	/**
	 * Reads the given file and returns a pcap style hexdump of it as a string.
	 * @param filename filename of the file (e.g. "/tmp/foo.txt")
	 * @return String containing pcap style hexdump
	 * @throws Exception
	 */
	public String fileToPcapHexDump(String filename) throws Exception
	{
		byte[] b = file2ByteArray(filename);
		System.out.println(b.length + " bytes from " + filename);
		return pcapStyleHexDump(b);
	}
	
	
	
 

	
	
}