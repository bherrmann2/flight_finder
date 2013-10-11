package com.scissorsoft;


import android.app.AlertDialog;
import android.content.DialogInterface;

import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.Toast;
import android.os.Bundle;

public class a1 extends ZebActivity {
	private static final int MENU_INIT_DB = 0;
	private static final int MENU_SHOW_DB = 1;
	private static final int MENU_ADD_DB = 2;
	
	private ImageWebDb db = null;
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
    
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        try
        {
        	ImageWebDb.init(this);
        	this.db = ImageWebDb.getInstance();
        	toast(db.getDump2());
        
        }
        catch (Exception e)
        {
        	alert(e.toString());
        	e.printStackTrace();
        }

    }

    /* Creates the menu items */
    public boolean onCreateOptionsMenu(Menu menu) 
    {
        menu.add(0, MENU_INIT_DB, 0, "INIT Database");
        menu.add(0, MENU_SHOW_DB, 0, "Show Database");
        menu.add(0, MENU_ADD_DB, 0, "Add One");
        return true;
    }

    
    public boolean onOptionsItemSelected(MenuItem item) {
    	try
    	{
        switch (item.getItemId()) {
       
        case MENU_INIT_DB:
        	confirm("Delete Database?",
        	new DialogInterface.OnClickListener() {  
            	public void onClick(DialogInterface dialog, int whichButton) {  
            		boolean ret = false;
					try {
						ret = db.initDB();
					} catch (Exception e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
            		alert("DELETED: " + ((ret)?"YES":"NO"));
            	}
        	},null);
            return true;
        case MENU_ADD_DB:
        	ImageNode n = db.createNodeWithSave("purple","","");
        	if (n != null) alert("ADDED " + n.toString());
        	return true;
        
        	
        case MENU_SHOW_DB:
        	toast(this.db.getDump());
        	/*
        	confirm("Show Database?",
        	new DialogInterface.OnClickListener() {  
            	public void onClick(DialogInterface dialog, int whichButton) {  
            		toast(db.getDump());
            		//alert("DELETED: " + ((ret)?"YES":"NO"));
            	}
        	},null);
        	*/
            return true;

        default:
        	break;
        }
    	}
    	catch (Exception ex)
    	{
    		alert(ex.toString());
    	}
    	
        return false;
    }//onOptionsItemSelected
        	


    
 

}