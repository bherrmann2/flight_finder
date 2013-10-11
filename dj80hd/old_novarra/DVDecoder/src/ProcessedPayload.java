package com.novarra.aca.desktopview;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

import com.novarra.aca.util.tracer.Tracer;
import com.novarra.aca.charset.NovCharset;

public class ProcessedPayload { 
    
    /** payload containing page global, base href, p cmds, a elems, f rects */
	/**
	 * by default we don't send Jump To -1 and PG_SHOW_IN_ZOOMIN to 1
	 * if page is renormalized or reserialized as a result of user click
	 * we will change payload to send 
	 *   PG_SHOW_IN_ZOOMIN = (-1,-1)
	 *   PG_JUMP_TO_ATTR_ID = 1
	 */
	protected boolean jumpBackZoomIn = false;
	
	protected ByteBuffer globalSegment;
	protected ByteBuffer payload;
    
    /** ArrayList of DvImageInfo objects */
    public ArrayList imageInfoList;
    
    /** ArrayList of Strings of image urls*/
    public ArrayList imageUrlList;
    
    /** Flag denoting whether or not favicon has been added to imageUrlList/imageInfoList */
    private boolean imageListHasFavicon = false;   
    
    /** 
     * default ctor 
     */
    public ProcessedPayload() {}
    
    public byte[] getPayload()
    {
    	byte [] globalBytes = globalSegment.array();
    	byte [] otherBytes = payload.array();
    	byte [] totalPayload = new byte[otherBytes.length + globalBytes.length];
    	System.arraycopy(globalBytes, 0, totalPayload, 0, globalBytes.length);
    	System.arraycopy(otherBytes, 0, totalPayload, globalBytes.length, otherBytes.length);
    	return totalPayload;
    }
    
    /* Checks whether or not the favicon has already been added to the imageLists */
    public boolean imageListHasFavicon() { return this.imageListHasFavicon; }
    
    /* Called when the favicon is added to the imageLists */
    public void setImageListHasFavicon(boolean imageListHasFavicon) { this.imageListHasFavicon = imageListHasFavicon; }
    
    /**
     *  Ensures isProcessed/isZoomOutViewProcessed flags are false in DvImageInfo List.
     *  In cases where there is no renormalization the processedPayload object from the
     *  previous request is used. Since the imageList was iterated over once before in
     *  the previous request all isProcessed flags are asserted and the image handling
     *  is broken the second time. See SCR-31770 for more information.
     */
    public void resetImageLists() {
        for (Iterator it = imageInfoList.iterator(); it.hasNext();) {            
            DvImageInfo dvii = (DvImageInfo) it.next();
           	dvii.isZoomOutViewProcessed = false;
           	dvii.isProcessed = false;
        }
    }
    
    /**
     *  If page is renormalized or reserialized as a result of the user click
     *  we will be sending Jump To (-1,-1) and PG_JUMP_TO_ATTR_ID = 1
     *  If we already in jumpBackZoomIn there is nothing to do. we already changed global payload.
     */
    public void setSamePage()
    {
    	if(!jumpBackZoomIn)
    	{
    		//read global and find if we got PG_JUMP_TO_ATTR_ID or/and PG_SHOW_IN_ZOOMIN
    		//if found we will change them
    		
    		//mng: this is not thread safe
    		//skip section id and size
    		globalSegment.position(6);
    		boolean foundZoomIn = false;
    		boolean foundJumpTo = false;
    		while (globalSegment.hasRemaining()) 
    		{
    			int attrId = globalSegment.getShort();
                int attrLength = globalSegment.getShort();
                
                switch (attrId) {
                case DesktopView.PG_JUMP_TO_ATTR_ID:
                    // not yet supported
                    globalSegment.putShort((short)-1) ;
                    globalSegment.putShort((short)-1);
                    trace("page jumpto x = -1 y = -1");
                    foundJumpTo = true;
                    break;
                case DesktopView.PG_SHOW_IN_ZOOMIN:
                    globalSegment.put((byte)1) ;
                	trace("Show in zoom in = 1");
                	foundZoomIn = true;
                	break;
               
                default:
                	globalSegment.position(globalSegment.position()+attrLength);
                    break;
                }
    			
    		}
    		
    		int additionalSize = 0;
    		if(!foundJumpTo)
    			additionalSize+=8;
    		if(!foundZoomIn)
    			additionalSize+=5;
    		
    		if(additionalSize > 0)
    		{
    			ByteBuffer newGlobal = ByteBuffer.allocate(globalSegment.capacity()+ additionalSize);
    			newGlobal.put(globalSegment.array());
    			
	    		//if we did not find PG_JUMP_TO_ATTR_ID add one
	    		if( ! foundJumpTo)
	    		{
	    			newGlobal.putShort((short)DesktopView.PG_JUMP_TO_ATTR_ID);
	    			newGlobal.putShort((short)4);
	    			newGlobal.putShort((short)-1);
	    			newGlobal.putShort((short)-1);
	    		}
	    		
	    		//if we did not find PG_SHOW_IN_ZOOMIN add one
	    		if( ! foundZoomIn )
	    		{
	    			
	    			newGlobal.putShort((short)DesktopView.PG_SHOW_IN_ZOOMIN);
	    			newGlobal.putShort((short)1);
	    			newGlobal.put((byte)1);
	    		}
	    		
	    		//change section size
	    		newGlobal.putInt(2,newGlobal.getInt(2)+additionalSize);
	    		
	    		globalSegment = newGlobal;
    		}
    		
    		jumpBackZoomIn = true;
    	}
    }
    /** 
     * examine the payload and image information being sent to the client. 
     * please use only for debugging.
     */
    public void examineSelf() {

        trace("===BEGIN Client Payload Trace===");
        ByteBuffer pageGlobalByteBuffer = globalSegment;
        ByteBuffer baseHrefByteBuffer = null;
        ByteBuffer paintCmdsEtcByteBuffer = null;

        /*
        // Uncomment to dump payload to file of your choice
        // Note: this only includes the desktop view document payload: Page Global + Base HREF Table + Paint/FA/AE Commands
        payload.position(0);
        File dumpFile = new File("/home/mmcvady/j2mePayloadDump.bin");
        try { 
        	FileOutputStream dumpOS = new FileOutputStream(dumpFile);
        	dumpOS.write(payload.array()); 
        }
        catch(Exception e) { e.printStackTrace(); }
        */
        
        // set position to 0
        payload.position(0);
        
        // split payload into sections
        while (payload.hasRemaining()) {
            int sectionId = payload.getShort() & 0xFFFF;
            int sectionSize = 0;
            byte[] buf = null;
            switch (sectionId) {
            case DesktopView.PAGE_GLOBAL_SECTION_ID:
                sectionSize = payload.getInt();
                buf = new byte[sectionSize];
                payload = payload.get(buf, 0, sectionSize);
                pageGlobalByteBuffer = ByteBuffer.wrap(buf);
                trace("page global section id = " + sectionId + " size = " + sectionSize);
                break;
            case DesktopView.BASE_HREF_SECTION_ID:
                sectionSize = payload.getInt();
                buf = new byte[sectionSize];
                payload = payload.get(buf, 0, sectionSize);
                baseHrefByteBuffer = ByteBuffer.wrap(buf);
                trace("base href section id = " + sectionId + " size = " + sectionSize);
                break;
            case DesktopView.PAINT_CMDS_SECTION_ID:
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
            case DesktopView.PG_PAGE_DIMENSIONS_ATTR_ID:
                int pageWidth = pageGlobalByteBuffer.getShort() & 0xFFFF;
                int pageHeight = pageGlobalByteBuffer.getShort() & 0xFFFF;
                trace("page width = " + pageWidth + " height = " + pageHeight);
                break;
            case DesktopView.PG_JUMP_TO_ATTR_ID:
                // not yet supported
                int jumptoX = pageGlobalByteBuffer.getShort() & 0xFFFF;
                int jumptoY = pageGlobalByteBuffer.getShort() & 0xFFFF;
                trace("page jumpto x = " + jumptoX + " y = " + jumptoY);
                break;
            case DesktopView.PG_SHOW_IN_ZOOMIN:
            	byte zoomin = pageGlobalByteBuffer.get() ;
            	trace("Show in zoom in = " + zoomin);
            	break;
            case DesktopView.PG_NUMBER_OF_PAINT_CMDS_ATTR_ID:
                int totalPaintCmds = pageGlobalByteBuffer.getShort() & 0xFFFF;
                trace("total # of pCmds = " + totalPaintCmds);
                break;
            case DesktopView.PG_NUMBER_OF_ACTIONABLE_ELEMS_ATTR_ID:
                int totalActionElems = pageGlobalByteBuffer.getShort() & 0xFFFF;
                trace("total # of aElems = " + totalActionElems);
                break;
            case DesktopView.PG_NUMBER_OF_FOCUSABLE_AREAS_ATTR_ID:
                int totalFocusAreas = pageGlobalByteBuffer.getShort() & 0xFFFF;
                trace("total # of fAreas = " + totalFocusAreas);
                break;
            case DesktopView.PG_NUMBER_OF_IMAGES_ATTR_ID:
                int totalNumberOfImages = pageGlobalByteBuffer.getShort() & 0xFFFF;
                trace("total # of images = " + totalNumberOfImages);
                break;
            case DesktopView.PG_TITLE_ATTR_ID:
                byte[] buf = new byte[attrLength];
                pageGlobalByteBuffer = pageGlobalByteBuffer.get(buf);
                String value = NovCharset.decode(buf, NovCharset.UTF_8);
                trace("page title = " + value);
                break;
            case DesktopView.PG_BACKGROUND_COLOR:
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
            String value = NovCharset.decode(buf, NovCharset.UTF_8);
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
            case DesktopView.SET_COLOR:
            {
                pCmdCount++;
                int a = paintCmdsEtcByteBuffer.get() & 0xFF;
                int r = paintCmdsEtcByteBuffer.get() & 0xFF;
                int g = paintCmdsEtcByteBuffer.get() & 0xFF;
                int b = paintCmdsEtcByteBuffer.get() & 0xFF;
                StringBuffer sbuf = new StringBuffer();
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" set color")
                    .append(" a = ").append(a) 
                    .append(" r = ").append(r) 
                    .append(" g = ").append(g) 
                    .append(" b = ").append(b); 
                trace(sbuf);
                break;
            }
            case DesktopView.FILL_RECTANGLE:
            {
                pCmdCount++;
                int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                StringBuffer sbuf = new StringBuffer();
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" fill rectangle")
                    .append(" x = ").append(x) 
                    .append(" y = ").append(y) 
                    .append(" w = ").append(w) 
                    .append(" h = ").append(h); 
                trace(sbuf);
                break;
            }
            case DesktopView.DRAW_RECTANGLE:
            {
                pCmdCount++;
                int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                StringBuffer sbuf = new StringBuffer();
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" draw rectangle")
                    .append(" x = ").append(x) 
                    .append(" y = ").append(y) 
                    .append(" w = ").append(w) 
                    .append(" h = ").append(h); 
                trace(sbuf);
                break;
            }
            case DesktopView.FILL_ELLIPSE:
            {
                pCmdCount++;
                int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                StringBuffer sbuf = new StringBuffer();
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" fill ellipse")
                    .append(" x = ").append(x) 
                    .append(" y = ").append(y) 
                    .append(" w = ").append(w) 
                    .append(" h = ").append(h); 
                trace(sbuf);
                break;
            }
            case DesktopView.DRAW_ELLIPSE:
            {
                pCmdCount++;
                int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                StringBuffer sbuf = new StringBuffer();
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" draw ellipse")
                    .append(" x = ").append(x) 
                    .append(" y = ").append(y) 
                    .append(" w = ").append(w) 
                    .append(" h = ").append(h); 
                trace(sbuf);
                break;
            }
            case DesktopView.DRAW_LINE:
            {
                pCmdCount++;
                int x1 = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int y1 = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int x2 = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int y2 = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                StringBuffer sbuf = new StringBuffer();
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" draw line")
                    .append(" x1 = ").append(x1) 
                    .append(" y1 = ").append(y1) 
                    .append(" x2 = ").append(x2) 
                    .append(" y2 = ").append(y2); 
                trace(sbuf);
                break;
            }
            case DesktopView.SET_FONT_STYLE:
            {
                pCmdCount++;
                int style = paintCmdsEtcByteBuffer.get() & 0xFF;
                StringBuffer sbuf = new StringBuffer();
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" set font style")
                    .append(" style = ").append(style); 
                trace(sbuf);
                break;
            }
            case DesktopView.SET_FONT_SIZE:
            {
                pCmdCount++;
                int size = paintCmdsEtcByteBuffer.get() & 0xFF;
                StringBuffer sbuf = new StringBuffer();
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" set font size")
                    .append(" size = ").append(size); 
                trace(sbuf);
                break;
            }
            case DesktopView.DRAW_IMAGE:
            {
                pCmdCount++;
                int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int i = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                StringBuffer sbuf = new StringBuffer();
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" draw image")
                    .append(" x = ").append(x) 
                    .append(" y = ").append(y) 
                    .append(" width = ").append(w) 
                    .append(" height = ").append(h)
                    .append(" index = ").append(i); 
                trace(sbuf);
                break;
            }
            case DesktopView.DRAW_IMAGE_TILE:
            {
                pCmdCount++;
                int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int t = paintCmdsEtcByteBuffer.get() & 0xFF;
                int i = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                StringBuffer sbuf = new StringBuffer();
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" draw image tile")
                    .append(" x = ").append(x) 
                    .append(" y = ").append(y) 
                    .append(" width to cover = ").append(w) 
                    .append(" height to cover = ").append(h)
                    .append(" tile = ").append(t)
                    .append(" index = ").append(i); 
                trace(sbuf);
                break;
            }
            case DesktopView.DRAW_IMAGE_TILE_OFFSET:
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
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" draw image tile offset")
                    .append(" x = ").append(x) 
                    .append(" y = ").append(y) 
                    .append(" width to cover = ").append(w) 
                    .append(" height to cover = ").append(h)
                    .append(" offset in x = ").append(ox) 
                    .append(" offset in y = ").append(oy) 
                    .append(" tile = ").append(t)
                    .append(" index = ").append(i); 
                trace(sbuf);
                break;
            }
            case DesktopView.SET_LINE_STYLE:
            {
                pCmdCount++;
                int style = paintCmdsEtcByteBuffer.get() & 0xFF;
                StringBuffer sbuf = new StringBuffer();
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" set line style")
                    .append(" style = ").append(style); 
                trace(sbuf);
                break;
            }
            case DesktopView.SET_LINE_WIDTH:
            {
                pCmdCount++;
                int width = paintCmdsEtcByteBuffer.get() & 0xFF;
                StringBuffer sbuf = new StringBuffer();
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" set line width")
                    .append(" width = ").append(width); 
                trace(sbuf);
                break;
            }
            case DesktopView.SET_FONT_FAMILY:
            {
                pCmdCount++;
                int ff = paintCmdsEtcByteBuffer.get() & 0xFF;
                StringBuffer sbuf = new StringBuffer();
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" set font family")
                    .append(" family = ").append(ff); 
                trace(sbuf);
                break;
            }
            case DesktopView.DRAW_TEXT:
            {
                pCmdCount++;
                int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int length = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                byte[] buf = new byte[length];
                paintCmdsEtcByteBuffer = paintCmdsEtcByteBuffer.get(buf);
                String value = NovCharset.decode(buf, NovCharset.UTF_8);

                StringBuffer sbuf = new StringBuffer();
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" draw text")
                    .append(" x = ").append(x) 
                    .append(" y = ").append(y) 
                    .append(" width = ").append(w) 
                    .append(" height = ").append(h)
                    .append(" text length = ").append(length) 
                    .append(" text value = ").append(value); 
                trace(sbuf);
                break;
            }
            case DesktopView.PAINT_INPUT_FIELD:
            {
                pCmdCount++;
                int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int aElemId = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;

                StringBuffer sbuf = new StringBuffer();
                sbuf.append("pCmd #").append(pCmdCount)
                    .append(" paint input field")
                    .append(" x = ").append(x) 
                    .append(" y = ").append(y) 
                    .append(" w = ").append(w) 
                    .append(" h = ").append(h)
                    .append(" aElemId  = ").append(aElemId); 
                trace(sbuf);
                break;
            }
            // focusable rectangles
            case DesktopView.FRECT_OPCODE:
            // focusable polygon
            case DesktopView.FPOLYGON_OPCODE:
            // focusable circle
            case DesktopView.FCIRCLE_OPCODE:
            {
                fAreaCount++;
                StringBuffer sbuf = new StringBuffer();
                int aElemId = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                
                sbuf.append("fArea #").append(fAreaCount)
                    .append(" opcode = ").append(opcode) 
                    .append(" aElemId = ").append(aElemId);
                
                if (opcode == DesktopView.FRECT_OPCODE) {
                    int numOfFRects = paintCmdsEtcByteBuffer.get() & 0xFF;
                    sbuf.append(" numOfFRects = ").append(numOfFRects); 
                    for (int qux = 1; qux <= numOfFRects; qux++) {
                        int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        sbuf.append(" x").append(qux).append(" = ").append(x) 
                            .append(" y").append(qux).append(" = ").append(y) 
                            .append(" w").append(qux).append(" = ").append(w) 
                            .append(" h").append(qux).append(" = ").append(h) ;
                    }                	
                }
                else if (opcode == DesktopView.FPOLYGON_OPCODE) {
                    int numOfVertices = paintCmdsEtcByteBuffer.get() & 0xFF;
                    sbuf.append(" numOfVertices = ").append(numOfVertices); 
                    for (int qux = 1; qux <= numOfVertices; qux++) {
                        int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        sbuf.append(" x").append(qux).append(" = ").append(x) 
                            .append(" y").append(qux).append(" = ").append(y);
                    }                	
                }
                else {
                        sbuf.append(" x = ").append(paintCmdsEtcByteBuffer.getShort() & 0xFFFF)
                            .append(" y = ").append(paintCmdsEtcByteBuffer.getShort() & 0xFFFF)
                            .append(" w = ").append(paintCmdsEtcByteBuffer.getShort() & 0xFFFF)
                            .append(" h = ").append(paintCmdsEtcByteBuffer.getShort() & 0xFFFF);
                }
                trace(sbuf);
                break;
            }
            case DesktopView.A_TAG_OP:
            case DesktopView.IMG_OP:
            case DesktopView.INPUT_TEXT_OP:
            case DesktopView.INPUT_RADIO_OP:
            case DesktopView.INPUT_CHECKBOX_OP:
            case DesktopView.INPUT_BUTTON_OP:
            case DesktopView.INPUT_SELECT_OP:
            case DesktopView.OPTION_OP:
            case DesktopView.SUB_DOCUMENT_TYPE_OP:
            case DesktopView.SNAP_TO_TYPE_OP:
            {
                aElemCount++;
                StringBuffer sbuf = new StringBuffer();
                sbuf.append("aElem #").append(aElemCount)
                    .append(" opcode = ").append(opcode);
                int opcodeLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                int bytesRead = 0;
                while (bytesRead < opcodeLength) {
                    int attrId = paintCmdsEtcByteBuffer.get() & 0xFF;
                    bytesRead++;
                    sbuf.append(" attr id = ").append(aElemAttrIdAsString.get(new Integer(attrId)));
                    switch (attrId) {
                    case DesktopView.DOWNLOADABLE: 
                    case DesktopView.NOV_DIRECT: 
                    case DesktopView.NOV_EXIT: 
                    case DesktopView.ONCHANGE: 
                    case DesktopView.ONCLICK: 
                    case DesktopView.ONSELECT: 
                    case DesktopView.INPUT_IMG: 
                    case DesktopView.READONLY:                                         
                    case DesktopView.INPUT_PASSWORD: 
                    case DesktopView.INPUT_RESET: 
                    case DesktopView.MULTIPLE_SELECTION: 
                    {
                        int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int attrValue = paintCmdsEtcByteBuffer.get() & 0xFF;
                        bytesRead += 3;
                        sbuf.append(" len = ").append(attrLength)
                            .append(" value = ").append(attrValue);
                        break;
                    }
                    case DesktopView.INPUT_TEXT_AREA:
                    {
                    	int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                    	int attrValue = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                    	bytesRead += 4;
                    	sbuf.append(" len = ").append(attrLength)
                            .append(" value = ").append(attrValue);
                    	break;
                    }
                    case DesktopView.BASE_HREF_ATTR: 
                    {
                        int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int attrValue = paintCmdsEtcByteBuffer.getInt();
                        bytesRead += 6;
                        sbuf.append(" len = ").append(attrLength)
                            .append(" value = ").append(attrValue);
                        break;
                    }
                    
                    case DesktopView.HREF: 
                    case DesktopView.SRC: 
                    {
                        int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        byte[] buf = new byte[attrLength];
                        paintCmdsEtcByteBuffer = paintCmdsEtcByteBuffer.get(buf);
                        String attrValue = NovCharset.decode(buf, NovCharset.UTF_8);

                        bytesRead += 2 + attrLength;
                        sbuf.append(" len = ").append(attrLength)
                            .append(" value = ").append(attrValue);
                        break;
                    }
                    case DesktopView.POINT_TO_JUMP: 
                    {
                        int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        bytesRead += 6;
                        sbuf.append(" len = ").append(attrLength)
                            .append(" x = ").append(x)
                            .append(" y = ").append(y);
                        break;
                    }
                    case DesktopView.MAX_LENGTH: 
                    {
                        int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int attrValue = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        bytesRead += 4;
                        sbuf.append(" len = ").append(attrLength)
                            .append(" value = ").append(attrValue);
                        break;
                    }
                    case DesktopView.INITIAL_VALUE: 
                    {
                        int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        byte[] buf = new byte[attrLength];
                        paintCmdsEtcByteBuffer = paintCmdsEtcByteBuffer.get(buf);
                        String attrValue = NovCharset.decode(buf, NovCharset.UTF_8);


                        bytesRead += 2 + attrLength;
                        sbuf.append(" len = ").append(attrLength)
                            .append(" value = ").append(attrValue);
                        break;
                    }
                    case DesktopView.SELECTED: 
                    {
                        int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int attrValue = paintCmdsEtcByteBuffer.get() & 0xFF;
                        bytesRead += 3;
                        sbuf.append(" len = ").append(attrLength)
                            .append(" value = ").append(attrValue);
                        break;
                    }
                    case DesktopView.NAME: 
                    {
                        int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        byte[] buf = new byte[attrLength];
                        paintCmdsEtcByteBuffer = paintCmdsEtcByteBuffer.get(buf);
                        String attrValue = NovCharset.decode(buf, NovCharset.UTF_8);
                        bytesRead += 2 + attrLength;
                        sbuf.append(" len = ").append(attrLength)
                            .append(" value = ").append(attrValue);
                        break;
                    }
                    case DesktopView.NUM_OPTIONS: 
                    {
                        int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int attrValue = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        bytesRead += 4;
                        sbuf.append(" len = ").append(attrLength)
                            .append(" value = ").append(attrValue);
                        break;
                    }
                    case DesktopView.P_POINTER: 
                    {
                        int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int attrValue = paintCmdsEtcByteBuffer.getInt();
                        bytesRead += 6;
                        sbuf.append(" len = ").append(attrLength)
                            .append(" value = ").append(attrValue);
                        break;
                    }
                    case DesktopView.ACCESS_KEY: 
                    {
                        int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int attrValue = paintCmdsEtcByteBuffer.get() & 0xFF;
                        bytesRead += 3;
                        sbuf.append(" len = ").append(attrLength)
                            .append(" value = ").append(attrValue);
                        break;
                    }
                    case DesktopView.DOCUMENT_ID: 
                    {
                        int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int attrValue = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        bytesRead += 4;
                        sbuf.append(" len = ").append(attrLength)
                            .append(" value = ").append(attrValue);
                        break;
                    }
                    case DesktopView.RECTANGLE: 
                    {
                        int attrLength = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int x = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int y = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int w = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        int h = paintCmdsEtcByteBuffer.getShort() & 0xFFFF;
                        bytesRead += 10;
                        sbuf.append(" len = ").append(attrLength)
                            .append(" x = ").append(x)
                            .append(" y = ").append(y)
                            .append(" w = ").append(w)
                            .append(" h = ").append(h);
                        break;
                    }
                    default:
                        break;
                    }
                }
                trace(sbuf);
                break;
            }
            default:
                // do nothing
                break;
            }
        }
        
        // process image info
        if (imageInfoList != null) {
            for (Iterator iter = imageInfoList.iterator(); iter.hasNext();) {
                DvImageInfo imageInfo = (DvImageInfo) iter.next();
                trace(imageInfo.toString());            
            }
        }
        trace("===END Client Payload Trace===");
    }

    static HashMap aElemAttrIdAsString = new HashMap();
    static {
        aElemAttrIdAsString.put(new Integer(DesktopView.DOWNLOADABLE), "downloadable");
        aElemAttrIdAsString.put(new Integer(DesktopView.NOV_DIRECT), "nov_direct");
        aElemAttrIdAsString.put(new Integer(DesktopView.NOV_EXIT), "nov_exit");
        aElemAttrIdAsString.put(new Integer(DesktopView.ONCHANGE), "onchange");
        aElemAttrIdAsString.put(new Integer(DesktopView.ONCLICK), "onclick");
        aElemAttrIdAsString.put(new Integer(DesktopView.ONSELECT), "onselect");
        aElemAttrIdAsString.put(new Integer(DesktopView.INPUT_IMG), "input_img");
        aElemAttrIdAsString.put(new Integer(DesktopView.READONLY), "readonly");
        aElemAttrIdAsString.put(new Integer(DesktopView.INPUT_TEXT_AREA), "input_text_area");
        aElemAttrIdAsString.put(new Integer(DesktopView.INPUT_PASSWORD), "input_password");
        aElemAttrIdAsString.put(new Integer(DesktopView.INPUT_RESET), "input_reset");
        aElemAttrIdAsString.put(new Integer(DesktopView.MULTIPLE_SELECTION), "multiple_selection");
        aElemAttrIdAsString.put(new Integer(DesktopView.BASE_HREF_ATTR), "base_href_attr");
        aElemAttrIdAsString.put(new Integer(DesktopView.HREF), "href");
        aElemAttrIdAsString.put(new Integer(DesktopView.SRC ), "src");
        aElemAttrIdAsString.put(new Integer(DesktopView.POINT_TO_JUMP), "point_to_jump");
        aElemAttrIdAsString.put(new Integer(DesktopView.MAX_LENGTH), "max_length");
        aElemAttrIdAsString.put(new Integer(DesktopView.INITIAL_VALUE), "initial_value");
        aElemAttrIdAsString.put(new Integer(DesktopView.SELECTED), "selected");
        aElemAttrIdAsString.put(new Integer(DesktopView.NAME), "name");
        aElemAttrIdAsString.put(new Integer(DesktopView.NUM_OPTIONS), "num_options");
        aElemAttrIdAsString.put(new Integer(DesktopView.P_POINTER), "p_pointer");
        aElemAttrIdAsString.put(new Integer(DesktopView.ACCESS_KEY), "access_key");
        aElemAttrIdAsString.put(new Integer(DesktopView.DOCUMENT_ID), "document_id");
        aElemAttrIdAsString.put(new Integer(DesktopView.RECTANGLE), "rectangle");
    }
    
    private void trace(String msg) {
        if (Tracer.isEnabled(Tracer.TRACE_DESKTOPVIEW))
            System.out.println(msg);
    }

    private void trace(StringBuffer msg) {
            trace(msg.toString());
    }
}
