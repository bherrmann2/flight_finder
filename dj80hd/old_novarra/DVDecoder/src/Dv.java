import java.nio.ByteBuffer;
import java.util.HashMap;
public class Dv {
	
		public static final String PAINTCMD_COLOR = "purple";
		public static final String LINKCMD_COLOR = "red";
		public static final String FOCUSCMD_COLOR = "green";

	    /** Minimum number of bytes in a image section */
	    private static int MIN_IMAGE_BYTES = 12;

	    /** ID of Page Global section */
	    static final int PAGE_GLOBAL_SECTION_ID = 1;

	    /** ID of Base Href section */
	    static final int BASE_HREF_SECTION_ID = 2;

	    /** ID of Paint Commands section */
	    static final int PAINT_CMDS_SECTION_ID = 3;

	    /** ID of Actionable Elements section */
	    static final int ACTIONABLE_ELEMS_SECTION_ID = 4;

	    /** ID of Focusable Areas section */
	    static final int FOCUSABLE_AREAS_SECTION_ID = 5;

	    /** ID of Image Info section */
	    static final int IMAGE_INFO_SECTION_ID = 6;

	    /** ID of Named Anchor Position section */
	    static final int NAMED_ANCHOR_POSITION_SECTION_ID = 7;

	    /** focusable rectangle opcode */
	    static final int FRECT_OPCODE = 101;  
	    /** focusable polygon opcode */
	    static final int FPOLYGON_OPCODE = 102;
	    /** focusable circle opcode */
	    static final int FCIRCLE_OPCODE = 103; 
	    
	    /** focusable area actionable element position */
	    private static final int FOCUS_ACTION_ELEM_POS = 1;
	    
	    /** number of focusable rectanges(or vertices in polygon) position */
	    private static final int NUM_OF_FOCUS_ELEM_POS = 3;

	    /** y position for focusable rectangle/polygon */
	    private static final int Y_POS_FOR_FOCUS = 6;
	    /** y position for focusable circle */
	    private static final int Y_POS_FOR_FOCUS_CIRCLE = 5;
	    
	    /** protocol of mozilla image resource*/
	    private static final String MZ_CHROME = "chrome://";

	    /** yet another protocol of mozilla image resource*/
	    private static final String MZ_RESOURCE = "resource://";
	    
	    /** page global page dimension attribute id */
	    static final int PG_PAGE_DIMENSIONS_ATTR_ID = 1;
	    
	    /** page global jump to attribute id */
	    static final int PG_JUMP_TO_ATTR_ID = 2;
	    
	    /** page global number of paint commands attribute id */
	    static final int PG_NUMBER_OF_PAINT_CMDS_ATTR_ID = 3;

	    /** page global number of focuable rectangles attribute id */
	    static final int PG_NUMBER_OF_FOCUSABLE_AREAS_ATTR_ID = 4;
	    
	    /** page global number of actionable elements attribute id */
	    static final int PG_NUMBER_OF_ACTIONABLE_ELEMS_ATTR_ID = 5;
	    
	    /** page global number of images attribute id */
	    static final int PG_NUMBER_OF_IMAGES_ATTR_ID = 6;
	    
	    /** page global title attribute id */
	    static final int PG_TITLE_ATTR_ID = 7;    
	    
	    /** page global background color attribute id */
	    static final int PG_BACKGROUND_COLOR = 8;
	    
	    /** page global document id attribute id */
	    static final int PG_DOCUMENT_ID = 9;
	    
	    /** page global frame/iframe visible dimensions attribute id */
	    static final int PG_FRAME_IFRAME_VISIBLE_DIMENSIONS = 10;
	    
	    /** page global frame/iframe position attribute id */
	    static final int PG_FRAME_IFRAME_POSITION = 11;
	    
	    /** page global zoomable attribute id */
	    static final int PG_ZOOMABLE = 12;
	    
	    /** page global ShowInZoomIn attribute id */
	    static final int PG_SHOW_IN_ZOOMIN = 13;
	    
	    /**
	     * Paint command OpCodes
	     */
	    
	    /** paint command opcode - set color */
	    static final int SET_COLOR = 0;
	    
	    /** paint command opcode - fill rectangle */
	    static final int FILL_RECTANGLE = 1;
	    
	    /** paint command opcode - draw rectangle */
	    static final int DRAW_RECTANGLE = 2;
	    
	    /** paint command opcode - draw line */
	    static final int DRAW_LINE = 3;
	    
	    /** paint command opcode - set font style */
	    static final int SET_FONT_STYLE = 4;
	    
	    /** paint command opcode - set font size */
	    static final int SET_FONT_SIZE = 5;
	    
	    /** paint command opcode - draw image */
	    static final int DRAW_IMAGE = 6;
	    
	    /** paint command opcode - draw image tile */
	    static final int DRAW_IMAGE_TILE = 7;
	    
	    /** paint command opcode - draw image tile offset */
	    static final int DRAW_IMAGE_TILE_OFFSET = 8;
	    
	    /** paint command opcode - set line style */
	    static final int SET_LINE_STYLE = 9;
	    
	    /** paint command opcode - set line width */
	    static final int SET_LINE_WIDTH = 10;
	    
	    /** paint command opcode - set font family */
	    static final int SET_FONT_FAMILY = 11;
	    
	    /** paint command opcode - end of document (EOD) */
	    // Note: This opcode is deprecated
	    static final int EOD = 12;
	    
	    /** paint command opcode - draw text */
	    static final int DRAW_TEXT = 13;
	    
	    /** paint command opcode - paint input field */
	    static final int PAINT_INPUT_FIELD = 14;
	    
	    /** paint command opcode - draw ellipse */
	    static final int DRAW_ELLIPSE = 16;
	    
	    /** paint command opcode - fill ellipse */
	    static final int FILL_ELLIPSE = 17;
	 
	    /** default hash if font DB is down */
	    public static final String DEFAULT_HASH = "default-hash";

	    /**
	     * Paint Command: Opcode to Total Command Length Mapping
	     */
	    public static final HashMap P_OPCODE_TO_LENGTH = new HashMap();
	    static {
	        P_OPCODE_TO_LENGTH.put(new Integer(SET_COLOR), new Integer(5));
	        P_OPCODE_TO_LENGTH.put(new Integer(FILL_RECTANGLE), new Integer(9));
	        P_OPCODE_TO_LENGTH.put(new Integer(DRAW_RECTANGLE), new Integer(9));
	        P_OPCODE_TO_LENGTH.put(new Integer(DRAW_LINE), new Integer(9));
	        P_OPCODE_TO_LENGTH.put(new Integer(SET_FONT_STYLE), new Integer(2));
	        P_OPCODE_TO_LENGTH.put(new Integer(SET_FONT_SIZE), new Integer(2));
	        P_OPCODE_TO_LENGTH.put(new Integer(DRAW_IMAGE), new Integer(11));
	        P_OPCODE_TO_LENGTH.put(new Integer(DRAW_IMAGE_TILE), new Integer(12));
	        P_OPCODE_TO_LENGTH.put(new Integer(DRAW_IMAGE_TILE_OFFSET), new Integer(16));
	        P_OPCODE_TO_LENGTH.put(new Integer(SET_LINE_STYLE), new Integer(2));
	        P_OPCODE_TO_LENGTH.put(new Integer(SET_FONT_FAMILY), new Integer(2));
	        P_OPCODE_TO_LENGTH.put(new Integer(PAINT_INPUT_FIELD), new Integer(11));
	        P_OPCODE_TO_LENGTH.put(new Integer(DRAW_ELLIPSE), new Integer(9));
	        P_OPCODE_TO_LENGTH.put(new Integer(FILL_ELLIPSE), new Integer(9));
	    }
	    
	    /**
	     * Paint Command: Opcode to y coordinate start position mapping
	     */
	    public static final HashMap P_OPCODE_TO_Y = new HashMap();
	    static {
	        //TODO - Map all opcodes
	        P_OPCODE_TO_Y.put(new Integer(SET_COLOR), new Integer(-1));
	        P_OPCODE_TO_Y.put(new Integer(FILL_RECTANGLE), new Integer(3)); //Counting y coord from 0
	        P_OPCODE_TO_Y.put(new Integer(DRAW_RECTANGLE), new Integer(3));
	        P_OPCODE_TO_Y.put(new Integer(DRAW_LINE), new Integer(3));
	        P_OPCODE_TO_Y.put(new Integer(SET_FONT_STYLE), new Integer(-1));
	        P_OPCODE_TO_Y.put(new Integer(SET_FONT_SIZE), new Integer(-1));
	        P_OPCODE_TO_Y.put(new Integer(DRAW_IMAGE), new Integer(3));
	        P_OPCODE_TO_Y.put(new Integer(DRAW_IMAGE_TILE), new Integer(3));
	        P_OPCODE_TO_Y.put(new Integer(SET_LINE_STYLE), new Integer(-1));
	        P_OPCODE_TO_Y.put(new Integer(SET_LINE_WIDTH), new Integer(-1));
	        P_OPCODE_TO_Y.put(new Integer(SET_FONT_FAMILY), new Integer(-1));
	        P_OPCODE_TO_Y.put(new Integer(DRAW_TEXT), new Integer(3));
	        P_OPCODE_TO_Y.put(new Integer(PAINT_INPUT_FIELD), new Integer(3));
	        P_OPCODE_TO_Y.put(new Integer(DRAW_ELLIPSE), new Integer(3));
	        P_OPCODE_TO_Y.put(new Integer(FILL_ELLIPSE), new Integer(3));
	    }

	    /**
	     * Paint Command: Special Case - Draw Text. The text length is 2 bytes and begins at position 9
	     */
	    public static final int TEXT_LENGTH_POS = 9;
	    
	    /* 
	     * Action Elem opcode
	     */
	    /** actionable element anchor opcode */
	    static final int A_TAG_OP = 151;
	    
	    /** actionable element image opcode */
	    static final int IMG_OP = 152;
	    
	    /** actionable element input text opcode  */
	    static final int INPUT_TEXT_OP = 153;
	    
	    /** actionable element input radio opcode */
	    static final int INPUT_RADIO_OP = 154;
	    
	    /** actionable element input checkbox opcode */
	    static final int INPUT_CHECKBOX_OP = 155;
	    
	    /** actionable element input button opcode */
	    static final int INPUT_BUTTON_OP = 156;
	    
	    /** actionable element input select opcode */
	    static final int INPUT_SELECT_OP = 157;
	    
	    /** actionable element input option opcode  */
	    static final int OPTION_OP = 158;
	    
	    /** actionable element sub document type opcode  */
	    static final int SUB_DOCUMENT_TYPE_OP = 160;
	    
	    /** actionable element snap to type opcode  */
	    static final int SNAP_TO_TYPE_OP = 170;
	    
	    /*
	     * Attribute Spec 
	     */    
	    /** actionable element downloadable attribute id */
	    static final int DOWNLOADABLE       = 1;  
	    
	    /** actionable element nov_direct attribute id */
	    static final int NOV_DIRECT         = 2;  
	    
	    /** actionable element nov_exit attribute id */
	    static final int NOV_EXIT           = 3;  
	    
	    /** actionable element onchange attribute id */
	    static final int ONCHANGE           = 4;  
	    
	    /** actionable element onclick attribute id */
	    static final int ONCLICK            = 5;
	    
	    /** actionable element onselect attribute id */
	    static final int ONSELECT           = 6;
	    
	    /** actionable element input_img attribute id */
	    static final int INPUT_IMG          = 7;
	    
	    /** actionable element readonly attribute id */
	    static final int READONLY           = 8;
	    
	    /** actionable element input_text_area attribute id */
	    static final int INPUT_TEXT_AREA    = 9;
	    
	    /** actionable element input_password attribute id */
	    static final int INPUT_PASSWORD     = 10;
	    
	    /** actionable element reset attribute id */
	    static final int INPUT_RESET        = 11;
	    
	    /** actionable element multiple_selection attribute id */
	    static final int MULTIPLE_SELECTION = 12;
	    
	    /** actionable element base_href attribute id */
	    static final int BASE_HREF_ATTR     = 13;
	    
	    /** actionable element href attribute id */
	    static final int HREF               = 14;
	    
	    /** actionable element src attribute id */
	    static final int SRC                = 15;
	    
	    /** actionable element point to jump attribute id */
	    static final int POINT_TO_JUMP      = 16;
	    
	    /** actionable element max length attribute id */
	    static final int MAX_LENGTH         = 17;
	    
	    /** actionable element initial value attribute id */
	    static final int INITIAL_VALUE      = 18;
	    
	    /** actionable element selected attribute id */
	    static final int SELECTED           = 19;
	    
	    /** actionable element name attribute id */
	    static final int NAME               = 20;
	    
	    /** actionable element num_options attribute id */
	    static final int NUM_OPTIONS        = 21;
	    
	    /** actionable element p_pointer attribute id */
	    static final int P_POINTER          = 22;
	    
	    /** actionable element access_key attribute id */
	    static final int ACCESS_KEY         = 23;
	    
	    /** actionable element document_id attribute id */
	    static final int DOCUMENT_ID        = 24;
	    
	    /** actionable element rectangle attribute id */
	    static final int RECTANGLE          = 25;


	    /** default bgcolor used for scaling transparent images */
	    static final byte[] bgcolor = { (byte) 0xff, (byte) 0xff, (byte) 0xff };

	    /** debug option for user friendly trace of content  */
	    public static boolean DEBUG = true;
	    
	    /** filter trace via oamp */
	    public static final String TRACE_FILTER_CLIENT = "client"; 
	    
	    /** filter trace via oamp */
	    public static final String TRACE_FILTER_DVS = "dvs";
	    
	    /** filter trace via oamp */
	    public static final String TRACE_FILTER_ACA = "aca";
	    
	 
	    static HashMap aElemAttrIdAsString = new HashMap();
	    static {
	        aElemAttrIdAsString.put(new Integer(DOWNLOADABLE), "downloadable");
	        aElemAttrIdAsString.put(new Integer(NOV_DIRECT), "nov_direct");
	        aElemAttrIdAsString.put(new Integer(NOV_EXIT), "nov_exit");
	        aElemAttrIdAsString.put(new Integer(ONCHANGE), "onchange");
	        aElemAttrIdAsString.put(new Integer(ONCLICK), "onclick");
	        aElemAttrIdAsString.put(new Integer(ONSELECT), "onselect");
	        aElemAttrIdAsString.put(new Integer(INPUT_IMG), "input_img");
	        aElemAttrIdAsString.put(new Integer(READONLY), "readonly");
	        aElemAttrIdAsString.put(new Integer(INPUT_TEXT_AREA), "input_text_area");
	        aElemAttrIdAsString.put(new Integer(INPUT_PASSWORD), "input_password");
	        aElemAttrIdAsString.put(new Integer(INPUT_RESET), "input_reset");
	        aElemAttrIdAsString.put(new Integer(MULTIPLE_SELECTION), "multiple_selection");
	        aElemAttrIdAsString.put(new Integer(BASE_HREF_ATTR), "base_href_attr");
	        aElemAttrIdAsString.put(new Integer(HREF), "href");
	        aElemAttrIdAsString.put(new Integer(SRC ), "src");
	        aElemAttrIdAsString.put(new Integer(POINT_TO_JUMP), "point_to_jump");
	        aElemAttrIdAsString.put(new Integer(MAX_LENGTH), "max_length");
	        aElemAttrIdAsString.put(new Integer(INITIAL_VALUE), "initial_value");
	        aElemAttrIdAsString.put(new Integer(SELECTED), "selected");
	        aElemAttrIdAsString.put(new Integer(NAME), "name");
	        aElemAttrIdAsString.put(new Integer(NUM_OPTIONS), "num_options");
	        aElemAttrIdAsString.put(new Integer(P_POINTER), "p_pointer");
	        aElemAttrIdAsString.put(new Integer(ACCESS_KEY), "access_key");
	        aElemAttrIdAsString.put(new Integer(DOCUMENT_ID), "document_id");
	        aElemAttrIdAsString.put(new Integer(RECTANGLE), "rectangle");
	    }
		//TODO byteArrayToInt, byteArrayToShort & intToByteArray needs to be revised
		
		/**
		 * Upto 4 bytes from startPos to endPos (including startPos & endPos) are converted to int.
		 * NOTE - This method should be used with caution for length less than 4. For example, 
		 * the signed value of a short will change it's meaning when converted to unsigned int.
		 * @param b, startPos, endPos
		 * @return
		 */
		public int byteArrayToInt(byte[] b, int startPos, int length) {
			if(length > 4)
				return -1;
			
			int value = 0;
	        for (int i = 0; i < length; i++) {
	            int shift = (length - 1 - i) * 8;
	            value += (b[startPos + i] & 0xFF) << shift;
	        }
	        return value;
		}
		
		public short byteArrayToShort(byte[] b, int startPos, int length) {
			if(length > 2)
				return -1; //TODO Revise this return value
			
			short value = 0;
	        for (int i = 0; i < length; i++) {
	            int shift = (length - 1 - i) * 8;
	            value += (b[startPos + i] & 0xFF) << shift;
	        }
	        return value;
		}
		
		/**
		 * converts integer to 4 bytes byte[]
		 * @param val
		 * @return
		 */
		public byte[] intToByteArray(int val)
		{
			byte[] b = new byte[4];
			b[0] = (byte) ((val >>> 24) & 0xff);
			b[1] = (byte) ((val >>> 16) & 0xff);
			b[2] = (byte) ((val >>> 8) & 0xff);
			b[3] = (byte) (val & 0xff);
			return b;
		}
		    
	  
	    
	    public String bytesToString(byte[] bytes) {        
	        char[] chars = new char[bytes.length];
	        for (int i = 0; i < bytes.length; i++) {
	            chars[i] = (char)bytes[i];
	        }
	        return new String(chars);
	    }
	    
	    public String utf8BytesToString(byte[] bytes) {
	    	try
	    	{
	    		return new String(bytes,"UTF-8");
	    	}
	    	catch (Exception e)
	    	{
	    		return bytesToString(bytes);
	    	}
	
	    }
	    public String withColor(String color,String s)
	    {
	    	return "<font color='" + color + "'>" + s + "</font>";
	    }
	    public String boldItalic(String s)
	    {
	    	return "<b><i>" + s + "</i></b>";
	    }

	    public StringBuffer log = new StringBuffer();
	    public void trace(StringBuffer msg)
	    {
	    	trace(msg.toString());
	    }
	    public void trace(String msg)
	    {
	    	log.append(msg + "\n");
	    }
	    
	    public String getDump(byte[] rawbytes)
	    {
	    	ByteBuffer payload = ByteBuffer.wrap(rawbytes);
	    	payload.position(0);
	    	
	       

	            //trace("===BEGIN Client Payload Trace===");
	            ByteBuffer pageGlobalByteBuffer = null;// = globalSegment;
	            ByteBuffer baseHrefByteBuffer = null;
	            ByteBuffer paintCmdsEtcByteBuffer = null;

	            
	            // split payload into sections
	            while (payload.hasRemaining()) {
	                int sectionId = payload.getShort() & 0xFFFF;
	                int sectionSize = 0;
	                byte[] buf = null;
	                switch (sectionId) {
	                case PAGE_GLOBAL_SECTION_ID:
	                    sectionSize = payload.getInt();
	                    //System.out.println("SectSize="+sectionSize);
	                    buf = new byte[sectionSize];
	                    payload = payload.get(buf, 0, sectionSize);
	                    pageGlobalByteBuffer = ByteBuffer.wrap(buf);
	                    trace("page global section id = " + sectionId + " size = " + sectionSize);
	                    break;
	                case BASE_HREF_SECTION_ID:
	                    sectionSize = payload.getInt();
	                    buf = new byte[sectionSize];
	                    payload = payload.get(buf, 0, sectionSize);
	                    baseHrefByteBuffer = ByteBuffer.wrap(buf);
	                    trace("base href section id = " + sectionId + " size = " + sectionSize);
	                    break;
	                case PAINT_CMDS_SECTION_ID:
	                	sectionSize = payload.getInt();
	                    buf = new byte[sectionSize];
	                    payload = payload.get(buf, 0, sectionSize);
	                    paintCmdsEtcByteBuffer = ByteBuffer.wrap(buf);
	                    trace("paint cmds section id = " + sectionId + " size = " + sectionSize);
	                    break;
	                default:
	                    break;
	                }
	            }

	            // process page global
	            while (pageGlobalByteBuffer != null && pageGlobalByteBuffer.hasRemaining()) {
	                int attrId = pageGlobalByteBuffer.getShort();
	                int attrLength = pageGlobalByteBuffer.getShort();
	                switch (attrId) {
	                case PG_PAGE_DIMENSIONS_ATTR_ID:
	                    int pageWidth = pageGlobalByteBuffer.getShort() & 0xFFFF;
	                    int pageHeight = pageGlobalByteBuffer.getShort() & 0xFFFF;
	                    trace("page width = " + pageWidth + " h=" + pageHeight);
	                    break;
	                case PG_JUMP_TO_ATTR_ID:
	                    // not yet supported
	                    int jumptoX = pageGlobalByteBuffer.getShort() & 0xFFFF;
	                    int jumptoY = pageGlobalByteBuffer.getShort() & 0xFFFF;
	                    trace("page jumpto x = " + jumptoX + " y=" + jumptoY);
	                    break;
	                case PG_SHOW_IN_ZOOMIN:
	                	byte zoomin = pageGlobalByteBuffer.get() ;
	                	trace("Show in zoom in = " + zoomin);
	                	break;
	                case PG_NUMBER_OF_PAINT_CMDS_ATTR_ID:
	                    int totalPaintCmds = pageGlobalByteBuffer.getShort() & 0xFFFF;
	                    trace("total # of pCmds = " + totalPaintCmds);
	                    break;
	                case PG_NUMBER_OF_ACTIONABLE_ELEMS_ATTR_ID:
	                    int totalActionElems = pageGlobalByteBuffer.getShort() & 0xFFFF;
	                    trace("total # of aElems = " + totalActionElems);
	                    break;
	                case PG_NUMBER_OF_FOCUSABLE_AREAS_ATTR_ID:
	                    int totalFocusAreas = pageGlobalByteBuffer.getShort() & 0xFFFF;
	                    trace("total # of fAreas = " + totalFocusAreas);
	                    break;
	                case PG_NUMBER_OF_IMAGES_ATTR_ID:
	                    int totalNumberOfImages = pageGlobalByteBuffer.getShort() & 0xFFFF;
	                    trace("total # of images = " + totalNumberOfImages);
	                    break;
	                case PG_TITLE_ATTR_ID:
	                    byte[] buf = new byte[attrLength];
	                    pageGlobalByteBuffer = pageGlobalByteBuffer.get(buf);
	                    //String value = NovCharset.decode(buf, NovCharset.UTF_8);
	                    trace("page title = " + new String(buf));
	                    break;
	                case PG_BACKGROUND_COLOR:
	                    // optional, default is 0xffffff
	                    // of the form a r g b (each two bytes)
	                    int a = pageGlobalByteBuffer.getShort() & 0xFFFF;
	                    int r = pageGlobalByteBuffer.getShort() & 0xFFFF;
	                    int g = pageGlobalByteBuffer.getShort() & 0xFFFF;
	                    int b = pageGlobalByteBuffer.getShort() & 0xFFFF;
	                    trace("page bgcolor a = " + a + " r = " + r + " g = " + g + " b = " + b);
	                    break;
	                default:
	                    break;
	                }
	            }

	            // process base href
	            int numOfBaseHrefs = baseHrefByteBuffer.getShort() & 0xFFFF;
	            int baseHrefCount = 0;
	            while (baseHrefByteBuffer.hasRemaining()) {
	                baseHrefCount++;
	                int length = baseHrefByteBuffer.getShort() & 0xFFFF;            
	                byte[] buf = new byte[length];
	                baseHrefByteBuffer = baseHrefByteBuffer.get(buf);
	                String value = new String(buf);//NovCharset.decode(buf, NovCharset.UTF_8);
	                trace("basehref #" + baseHrefCount + ": " + value);
	            }

	            // process paint cmds, etc. section
	            int pCmdCount = 0;
	            int fAreaCount = 0;
	            int aElemCount = -1;

	            while (paintCmdsEtcByteBuffer != null && paintCmdsEtcByteBuffer.hasRemaining()) {
	                int opcode = paintCmdsEtcByteBuffer.get() & 0xFF;
	                switch (opcode) {
	                // paint commands
	                case SET_COLOR:
	                {
	                    pCmdCount++;
	                    int a = paintCmdsEtcByteBuffer.get() & 0xFF;
	                    int r = paintCmdsEtcByteBuffer.get() & 0xFF;
	                    int g = paintCmdsEtcByteBuffer.get() & 0xFF;
	                    int b = paintCmdsEtcByteBuffer.get() & 0xFF;
	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" set color")
	                        .append(" a=").append(a) 
	                        .append(" r=").append(r) 
	                        .append(" g=").append(g) 
	                        .append(" b=").append(b); 
	                    trace(withColor(PAINTCMD_COLOR,sbuf.toString()));
	                    break;
	                }
	                case FILL_RECTANGLE:
	                {
	                    pCmdCount++;
	                    int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" fill rectangle")
	                        .append(" x=").append(x) 
	                        .append(" y=").append(y) 
	                        .append(" w=").append(w) 
	                        .append(" h=").append(h); 
	                    trace(withColor(PAINTCMD_COLOR,sbuf.toString()));
	                    break;
	                }
	                case DRAW_RECTANGLE:
	                {
	                    pCmdCount++;
	                    int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" draw rectangle")
	                        .append(" x=").append(x) 
	                        .append(" y=").append(y) 
	                        .append(" w=").append(w) 
	                        .append(" h=").append(h); 
	                    trace(withColor(PAINTCMD_COLOR,sbuf.toString()));
	                    break;
	                }
	                case FILL_ELLIPSE:
	                {
	                    pCmdCount++;
	                    int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" fill ellipse")
	                        .append(" x=").append(x) 
	                        .append(" y=").append(y) 
	                        .append(" w=").append(w) 
	                        .append(" h=").append(h); 
	                    trace(withColor(PAINTCMD_COLOR,sbuf.toString()));
	                    break;
	                }
	                case DRAW_ELLIPSE:
	                {
	                    pCmdCount++;
	                    int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" draw ellipse")
	                        .append(" x=").append(x) 
	                        .append(" y=").append(y) 
	                        .append(" w=").append(w) 
	                        .append(" h=").append(h); 
	                    trace(withColor(PAINTCMD_COLOR,sbuf.toString()));
	                    break;
	                }
	                case DRAW_LINE:
	                {
	                    pCmdCount++;
	                    int x1 = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int y1 = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int x2 = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int y2 = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" draw line")
	                        .append(" x1=").append(x1) 
	                        .append(" y1=").append(y1) 
	                        .append(" x2=").append(x2) 
	                        .append(" y2=").append(y2); 
	                    trace(withColor(PAINTCMD_COLOR,sbuf.toString()));
	                    break;
	                }
	                case SET_FONT_STYLE:
	                {
	                    pCmdCount++;
	                    int style = paintCmdsEtcByteBuffer.get() & 0xFF;
	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" set font style")
	                        .append(" style=").append(style); 
	                    trace(withColor(PAINTCMD_COLOR,sbuf.toString()));
	                    break;
	                }
	                case SET_FONT_SIZE:
	                {
	                    pCmdCount++;
	                    int size = paintCmdsEtcByteBuffer.get() & 0xFF;
	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" set font size")
	                        .append(" size = ").append(size); 
	                    trace(withColor(PAINTCMD_COLOR,sbuf.toString()));
	                    break;
	                }
	                case DRAW_IMAGE:
	                {
	                    pCmdCount++;
	                    int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int i = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" draw image")
	                        .append(" x=").append(x) 
	                        .append(" y=").append(y) 
	                        .append(" w=").append(w) 
	                        .append(" h=").append(h)
	                        .append(" index = ").append(i); 
	                    trace(sbuf);
	                    break;
	                }
	                case DRAW_IMAGE_TILE:
	                {
	                    pCmdCount++;
	                    int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int t = paintCmdsEtcByteBuffer.get() & 0xFF;
	                    int i = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" draw image tile")
	                        .append(" x=").append(x) 
	                        .append(" y=").append(y) 
	                        .append(" width to cover = ").append(w) 
	                        .append(" height to cover = ").append(h)
	                        .append(" tile = ").append(t)
	                        .append(" index = ").append(i); 
	                    trace(sbuf);
	                    break;
	                }
	                case DRAW_IMAGE_TILE_OFFSET:
	                {
	                    pCmdCount++;
	                    int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int ox = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int oy = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int t = paintCmdsEtcByteBuffer.get() & 0xFF;
	                    int i = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" draw image tile offset")
	                        .append(" x=").append(x) 
	                        .append(" y=").append(y) 
	                        .append(" width to cover = ").append(w) 
	                        .append(" height to cover = ").append(h)
	                        .append(" offset in x = ").append(ox) 
	                        .append(" offset in y = ").append(oy) 
	                        .append(" tile = ").append(t)
	                        .append(" index = ").append(i); 
	                    trace(sbuf);
	                    break;
	                }
	                case SET_LINE_STYLE:
	                {
	                    pCmdCount++;
	                    int style = paintCmdsEtcByteBuffer.get() & 0xFF;
	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" set line style")
	                        .append(" style = ").append(style); 
	                    trace(withColor(PAINTCMD_COLOR,sbuf.toString()));
	                    break;
	                }
	                case SET_LINE_WIDTH:
	                {
	                    pCmdCount++;
	                    int width = paintCmdsEtcByteBuffer.get() & 0xFF;
	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" set line width")
	                        .append(" w=").append(width); 
	                    trace(withColor(PAINTCMD_COLOR,sbuf.toString()));
	                    break;
	                }
	                case SET_FONT_FAMILY:
	                {
	                    pCmdCount++;
	                    int ff = paintCmdsEtcByteBuffer.get() & 0xFF;
	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" set font family")
	                        .append(" family = ").append(ff); 
	                    trace(withColor(PAINTCMD_COLOR,sbuf.toString()));
	                    break;
	                }
	                case DRAW_TEXT:
	                {
	                    pCmdCount++;
	                    int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int length = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    byte[] buf = new byte[length];
	                    paintCmdsEtcByteBuffer = paintCmdsEtcByteBuffer.get(buf);
	                    String value = new String(buf);//NovCharset.decode(buf, NovCharset.UTF_8);

	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" draw text")
	                        .append(" x=").append(x) 
	                        .append(" y=").append(y) 
	                        .append(" w=").append(w) 
	                        .append(" h=").append(h)
	                        .append(" len=").append(length) 
	                        .append(" v=").append(boldItalic(value)); 
	                    trace(sbuf);
	                    break;
	                }
	                case PAINT_INPUT_FIELD:
	                {
	                    pCmdCount++;
	                    int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int aElemId = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;

	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("P#").append(pCmdCount)
	                        .append(" paint input field")
	                        .append(" x=").append(x) 
	                        .append(" y=").append(y) 
	                        .append(" w=").append(w) 
	                        .append(" h=").append(h)
	                        .append(" aElemId  = ").append(aElemId); 
	                    trace(sbuf);
	                    break;
	                }
	                // focusable rectangles
	                case FRECT_OPCODE:
	                // focusable polygon
	                case FPOLYGON_OPCODE:
	                // focusable circle
	                case FCIRCLE_OPCODE:
	                {
	                    fAreaCount++;
	                    StringBuffer sbuf = new StringBuffer();
	                    int aElemId = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    
	                    sbuf.append("F#").append(fAreaCount)
	                        .append(" op=").append(opcode).append("[").append(Integer.toHexString(opcode)).append("]") 
	                        .append(" aElemId=").append(aElemId);
	                    
	                    if (opcode == FRECT_OPCODE) {
	                        int numOfFRects = paintCmdsEtcByteBuffer.get() & 0xFF;
	                        sbuf.append(" numOfFRects = ").append(numOfFRects); 
	                        for (int qux = 1; qux <= numOfFRects; qux++) {
	                            int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            sbuf.append(" x").append(qux).append("=").append(x) 
	                                .append(" y").append(qux).append("=").append(y) 
	                                .append(" w").append(qux).append("=").append(w) 
	                                .append(" h").append(qux).append("=").append(h) ;
	                        }                	
	                    }
	                    else if (opcode == FPOLYGON_OPCODE) {
	                        int numOfVertices = paintCmdsEtcByteBuffer.get() & 0xFF;
	                        sbuf.append(" numVertices=").append(numOfVertices); 
	                        for (int qux = 1; qux <= numOfVertices; qux++) {
	                            int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            sbuf.append(" x").append(qux).append("=").append(x) 
	                                .append(" y").append(qux).append("=").append(y);
	                        }                	
	                    }
	                    else {
	                            sbuf.append(" x=").append(paintCmdsEtcByteBuffer.getShort() & 0xFFFF)
	                                .append(" y=").append(paintCmdsEtcByteBuffer.getShort() & 0xFFFF)
	                                .append(" w=").append(paintCmdsEtcByteBuffer.getShort() & 0xFFFF)
	                                .append(" h=").append(paintCmdsEtcByteBuffer.getShort() & 0xFFFF);
	                    }
	                    trace(withColor(FOCUSCMD_COLOR,sbuf.toString()));
	                    break;
	                }
	                case A_TAG_OP:
	                case IMG_OP:
	                case INPUT_TEXT_OP:
	                case INPUT_RADIO_OP:
	                case INPUT_CHECKBOX_OP:
	                case INPUT_BUTTON_OP:
	                case INPUT_SELECT_OP:
	                case OPTION_OP:
	                case SUB_DOCUMENT_TYPE_OP:
	                case SNAP_TO_TYPE_OP:
	                {
	                    aElemCount++;
	                    StringBuffer sbuf = new StringBuffer();
	                    sbuf.append("A#").append(aElemCount)
	                        .append(" op=").append(opcode).append("[").append(Integer.toHexString(opcode)).append("]");
	                    int opcodeLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                    int bytesRead = 0;
	                    while (bytesRead < opcodeLength) {
	                        int attrId = paintCmdsEtcByteBuffer.get() & 0xFF;
	                        bytesRead++;
	                        sbuf.append(" aid=").append(aElemAttrIdAsString.get(new Integer(attrId)));
	                        switch (attrId) {
	                        case DOWNLOADABLE: 
	                        case NOV_DIRECT: 
	                        case NOV_EXIT: 
	                        case ONCHANGE: 
	                        case ONCLICK: 
	                        case ONSELECT: 
	                        case INPUT_IMG: 
	                        case READONLY:                                         
	                        case INPUT_PASSWORD: 
	                        case INPUT_RESET: 
	                        case MULTIPLE_SELECTION: 
	                        {
	                            int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int attrValue = paintCmdsEtcByteBuffer.get() & 0xFF;
	                            bytesRead += 3;
	                            sbuf.append(" len=").append(attrLength)
	                                .append(" v=").append(attrValue);
	                            break;
	                        }
	                        case INPUT_TEXT_AREA:
	                        {
	                        	int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                        	int attrValue = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                        	bytesRead += 4;
	                        	sbuf.append(" len=").append(attrLength)
	                                .append(" v=").append(attrValue);
	                        	break;
	                        }
	                        case BASE_HREF_ATTR: 
	                        {
	                            int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int attrValue = paintCmdsEtcByteBuffer.getInt();
	                            bytesRead += 6;
	                            sbuf.append(" len=").append(attrLength)
	                                .append(" v=").append(attrValue);
	                            break;
	                        }
	                        
	                        case HREF: 
	                        case SRC: 
	                        {
	                            int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            byte[] buf = new byte[attrLength];
	                            paintCmdsEtcByteBuffer = paintCmdsEtcByteBuffer.get(buf);
	                            String attrValue = utf8BytesToString(buf);//NovCharset.decode(buf, NovCharset.UTF_8);

	                            bytesRead += 2 + attrLength;
	                            sbuf.append(" len=").append(attrLength)
	                                .append(" v=").append(attrValue);
	                            break;
	                        }
	                        case POINT_TO_JUMP: 
	                        {
	                            int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            bytesRead += 6;
	                            sbuf.append(" len=").append(attrLength)
	                                .append(" x=").append(x)
	                                .append(" y=").append(y);
	                            break;
	                        }
	                        case MAX_LENGTH: 
	                        {
	                            int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int attrValue = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            bytesRead += 4;
	                            sbuf.append(" len=").append(attrLength)
	                                .append(" v=").append(attrValue);
	                            break;
	                        }
	                        case INITIAL_VALUE: 
	                        {
	                            int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            byte[] buf = new byte[attrLength];
	                            paintCmdsEtcByteBuffer = paintCmdsEtcByteBuffer.get(buf);
	                            String attrValue = utf8BytesToString(buf);//NovCharset.decode(buf, NovCharset.UTF_8);


	                            bytesRead += 2 + attrLength;
	                            sbuf.append(" len=").append(attrLength)
	                                .append(" v=").append(attrValue);
	                            break;
	                        }
	                        case SELECTED: 
	                        {
	                            int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int attrValue = paintCmdsEtcByteBuffer.get() & 0xFF;
	                            bytesRead += 3;
	                            sbuf.append(" len=").append(attrLength)
	                                .append(" v=").append(attrValue);
	                            break;
	                        }
	                        case NAME: 
	                        {
	                            int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            byte[] buf = new byte[attrLength];
	                            paintCmdsEtcByteBuffer = paintCmdsEtcByteBuffer.get(buf);
	                            String attrValue =  utf8BytesToString(buf);
	                            bytesRead += 2 + attrLength;
	                            sbuf.append(" len=").append(attrLength)
	                                .append(" v=").append(attrValue);
	                            break;
	                        }
	                        case NUM_OPTIONS: 
	                        {
	                            int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int attrValue = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            bytesRead += 4;
	                            sbuf.append(" len=").append(attrLength)
	                                .append(" v=").append(attrValue);
	                            break;
	                        }
	                        case P_POINTER: 
	                        {
	                            int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int attrValue = paintCmdsEtcByteBuffer.getInt();
	                            bytesRead += 6;
	                            sbuf.append(" len=").append(attrLength)
	                                .append(" v=").append(attrValue);
	                            break;
	                        }
	                        case ACCESS_KEY: 
	                        {
	                            int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int attrValue = paintCmdsEtcByteBuffer.get() & 0xFF;
	                            bytesRead += 3;
	                            sbuf.append(" len=").append(attrLength)
	                                .append(" v=").append(attrValue);
	                            break;
	                        }
	                        case DOCUMENT_ID: 
	                        {
	                            int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int attrValue = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            bytesRead += 4;
	                            sbuf.append(" len=").append(attrLength)
	                                .append(" v=").append(attrValue);
	                            break;
	                        }
	                        case RECTANGLE: 
	                        {
	                            int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
	                            bytesRead += 10;
	                            sbuf.append(" len=").append(attrLength)
	                                .append(" x=").append(x)
	                                .append(" y=").append(y)
	                                .append(" w=").append(w)
	                                .append(" h=").append(h);
	                            break;
	                        }
	                        default:
	                            break;
	                        }
	                    }
	                    trace(withColor(LINKCMD_COLOR,sbuf.toString()));
	                    break;
	                }
	                default:
	                    // do nothing
	                    break;
	                }
	            }
	            
	            /** FIXME - ADD THIS BACK
	            // process image info
	            if (imageInfoList != null) {
	                for (Iterator iter = imageInfoList.iterator(); iter.hasNext();) {
	                    DvImageInfo imageInfo = (DvImageInfo) iter.next();
	                    trace(imageInfo.toString());            
	                }
	            }
	            */
	        //trace("===END Client Payload Trace===");

	    
	        String ret = log.toString();
	        log = new StringBuffer();
	        return ret;
	        
	    }//getDump
	


}//class Dv
