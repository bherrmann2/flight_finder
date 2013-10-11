import java.util.HashMap;



public class DesktopView /*extends MozillaBase */ {

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
    
    /*
    private static final HashMap A_ATTR_IDs = new HashMap();
    static {
          //Note - Attributes not supported yet - Downloadable, NovDirect, NovExit, point to jump
          A_ATTR_IDs.put(new Integer(QuickDomConstants.ONCHANGE_ATTR_ID), new Integer(ONCHANGE));
          A_ATTR_IDs.put(new Integer(QuickDomConstants.ONCLICK_ATTR_ID), new Integer(ONCLICK));
          A_ATTR_IDs.put(new Integer(QuickDomConstants.ONSELECT_ATTR_ID), new Integer(ONSELECT));
          A_ATTR_IDs.put(new Integer(QuickDomConstants.READONLY_ATTR_ID), new Integer(READONLY));          
          A_ATTR_IDs.put(new Integer(QuickDomConstants.MULTIPLE_ATTR_ID), new Integer(MULTIPLE_SELECTION));
          A_ATTR_IDs.put(new Integer(QuickDomConstants.HREF_ATTR_ID), new Integer(HREF));
          A_ATTR_IDs.put(new Integer(QuickDomConstants.SRC_ATTR_ID), new Integer(SRC));
          A_ATTR_IDs.put(new Integer(QuickDomConstants.MAXLENGTH_ATTR_ID), new Integer(MAX_LENGTH));
          A_ATTR_IDs.put(new Integer(QuickDomConstants.VALUE_ATTR_ID), new Integer(INITIAL_VALUE));
          A_ATTR_IDs.put(new Integer(QuickDomConstants.SELECTED_ATTR_ID), new Integer(SELECTED));
          A_ATTR_IDs.put(new Integer(QuickDomConstants.CHECKED_ATTR_ID), new Integer(SELECTED));
          A_ATTR_IDs.put(new Integer(QuickDomConstants.NAME_ATTR_ID), new Integer(NAME));
          A_ATTR_IDs.put(new Integer(QuickDomConstants.P_ATTR_ID), new Integer(P_POINTER));
          A_ATTR_IDs.put(new Integer(QuickDomConstants.ACCESSKEY_ATTR_ID), new Integer(ACCESS_KEY));
          //No need to map attributes, image, input textarea, input password, input reset, base href, number of options
    }
    */

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
    
    /*
    private final static String DESKTOPVIEW_URL_REGEXP =
        "^https?://" +
        Snapshot.getRegexpIP() +
        "(:\\d+)?" + 
        "/" + ProxyUtils.DEVICEIDPREFIX +
        "([^/]+)" +
        '/' + ProxyUtils.DESKTOPVIEW + '/' +
        "(\\d+)/(\\d+)(\\?.*)?$";
    private final static Pattern PATTERN_DESKTOPVIEW_LINK_DIR = Pattern.compile(DESKTOPVIEW_URL_REGEXP);
    */
    

 
	
	//TODO byteArrayToInt, byteArrayToShort & intToByteArray needs to be revised
	
	/**
	 * Upto 4 bytes from startPos to endPos (including startPos & endPos) are converted to int.
	 * NOTE - This method should be used with caution for length less than 4. For example, 
	 * the signed value of a short will change it's meaning when converted to unsigned int.
	 * @param b, startPos, endPos
	 * @return
	 */
	public static int byteArrayToInt(byte[] b, int startPos, int length) {
		if(length > 4)
			return -1;
		
		int value = 0;
        for (int i = 0; i < length; i++) {
            int shift = (length - 1 - i) * 8;
            value += (b[startPos + i] & 0xFF) << shift;
        }
        return value;
	}
	
	public static short byteArrayToShort(byte[] b, int startPos, int length) {
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
	public static byte[] intToByteArray(int val)
	{
		byte[] b = new byte[4];
		b[0] = (byte) ((val >>> 24) & 0xff);
		b[1] = (byte) ((val >>> 16) & 0xff);
		b[2] = (byte) ((val >>> 8) & 0xff);
		b[3] = (byte) (val & 0xff);
		return b;
	}
	    
  
    
    public static String bytesToString(byte[] bytes) {        
        char[] chars = new char[bytes.length];
        for (int i = 0; i < bytes.length; i++) {
            chars[i] = (char)bytes[i];
        }
        return new String(chars);
    }

    
 
}

