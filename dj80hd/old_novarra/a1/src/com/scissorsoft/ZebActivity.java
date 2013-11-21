package com.scissorsoft;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.widget.Toast;

public class ZebActivity extends Activity {
    public void alert(String msg)
    {
    	alert("Error!",msg);
    }
    public void error(String msg)
    {
    	error(msg,0);
    }
    public void error(String msg, int code)
    {
    	String title = "ERROR";
    	if (code > 0) title = title + " (" + code + ")";
    	alert(title,msg);
    }
    public void alert(String title,String msg) {
    	AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(title);
        builder.setMessage(msg);
        builder.setPositiveButton("ok", null);
        builder.show(); 
    }
    
    public void toast(String s)
    {
    	Toast.makeText(this,s,Toast.LENGTH_LONG).show(); 
    }
    public void confirm(String msg, DialogInterface.OnClickListener yes, DialogInterface.OnClickListener no) {
    	confirm("Confirm",msg,yes,no);
    }  
    	
    public void confirm(String title, String msg, DialogInterface.OnClickListener yes, DialogInterface.OnClickListener no) {
       	
    	AlertDialog.Builder alert = new AlertDialog.Builder(this);    
    	alert.setTitle(title);  
    	alert.setMessage(msg);  
    	alert.setPositiveButton("Ok", yes);
    	alert.setNegativeButton("Cancel", no);
    	alert.show();
    	//return true;
    }
}
