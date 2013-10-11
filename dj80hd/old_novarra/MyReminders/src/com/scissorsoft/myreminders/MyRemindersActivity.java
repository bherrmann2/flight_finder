package com.scissorsoft.myreminders;

import com.scissorsoft.myreminders.R;
import android.app.*;
import android.content.*;
import android.inputmethodservice.Keyboard;
import android.inputmethodservice.Keyboard.Key;
import android.media.*;
import android.net.Uri;
import android.os.Bundle;
import android.view.*;
import android.net.*;
import android.net.http.*;
import android.util.*;
import android.view.View.*;
import android.widget.*;

import java.net.*;
import java.util.*;
import java.io.*;

import org.apache.http.*;
import org.apache.http.client.*;
import org.apache.http.client.entity.*;
import org.apache.http.client.methods.*;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.message.*;
import org.apache.http.util.*;

/**
 * TODO:
 * Q: HOw to print to console in eclipse
 * handle fire button
 * Confirms for operations.
 * Bigger buttons.
 * @author jwerwath
 *
 */

public class MyRemindersActivity extends Activity {
	
	private static final String SAVEURL = "http://scissorsoft.com/php/quotes.php";
	private static final int MENU_RELOAD= 0;
	private static final int MENU_QUIT = 1;
	private static final int MENU_WEBLOAD = 2;
	private static final int MENU_WEBSAVE = 3;
	private static final int MENU_EMAIL = 4;
	private static final int MENU_NEW = 5;
	private ArrayList<String> quotes = new ArrayList<String>();
	private Button another_button;
	private Button new_button;
	private Button email_button;
	private TextView quote_textview;
	private String db_filename = "quotes.txt";
	private boolean global_return_boolean = false;
	
	
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
       
        this.quote_textview = (TextView) findViewById(R.id.quote);
        
    
    }   
    
    public boolean onKeyDown(int keyCode, KeyEvent e) {
    	if (KeyEvent.ACTION_DOWN == e.getAction()) {
    		if (keyCode == KeyEvent.KEYCODE_DPAD_CENTER) {
    			handleAnother();
    			return true;
    		}
    	}
    	return false;
    }
    public boolean onTouchEvent(MotionEvent e) {
    	if (e.getAction() == MotionEvent.ACTION_DOWN) {
    	//show_error("Got event "+e.toString());
    		handleAnother();
    	}
    	return true;	
    }
    
    /* Creates the menu items */
    public boolean onCreateOptionsMenu(Menu menu) {
        //menu.add(0, MENU_RELOAD, 0, "Reload");
        menu.add(0, MENU_QUIT, 0, "Delete Database");
        menu.add(0, MENU_WEBLOAD, 0, "Load From Web");
        menu.add(0, MENU_WEBSAVE, 0, "Save To Web");
        menu.add(0, MENU_EMAIL,0,"Email All");
        menu.add(0, MENU_NEW,0,"New");
        return true;
    }

    /* Handles item selections */
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
       
        case MENU_QUIT:
        	this.confirm("Delete Database?",
        	new DialogInterface.OnClickListener() {  
            	public void onClick(DialogInterface dialog, int whichButton) {  
            		boolean ret = deleteFile(db_filename);
            		show_error("DELETED: " + ((ret)?"YES":"NO"));
            	}
        	},null);
            
            return true;
        case MENU_WEBLOAD:
        	this.confirm("Load Database from Web?",
        	new DialogInterface.OnClickListener() {  
            	public void onClick(DialogInterface dialog, int whichButton) {  
            		String text = downloadText(SAVEURL); 
                	try {
                		boolean ok = text2file(db_filename,text);
                		read_database();
                		alertok();
                	}catch(Exception e){show_error(e.toString());}
            	}
        	},null);     	
        	return true;
        	
        case MENU_WEBSAVE:
        	this.confirm("Save Database to Web?",
                	new DialogInterface.OnClickListener() {  
                    	public void onClick(DialogInterface dialog, int whichButton) {  
                    		try {
                        		webSave();
                        		alertok();
                        	}catch(Exception e){show_error(e.toString());}
                    	}
                	},null);     	
                return true;
          
       	case MENU_EMAIL:
       		handleEmail();
       		return true;
       		
       	case MENU_NEW:
       		handleNew();
       		return true;
       		
        }//switch  
        
        return false;
    }
    private void confirm(String msg, DialogInterface.OnClickListener yes, DialogInterface.OnClickListener no) {
    	confirm("Confirm",msg,yes,no);
    }  
    	
    private void confirm(String title, String msg, DialogInterface.OnClickListener yes, DialogInterface.OnClickListener no) {
       	
    	AlertDialog.Builder alert = new AlertDialog.Builder(this);    
    	alert.setTitle(title);  
    	alert.setMessage(msg);  
    	alert.setPositiveButton("Ok", yes);
    	alert.setNegativeButton("Cancel", no);
    	alert.show();
    	//return true;
    }
    
    private String quotes_as_whole_string() {
    	StringBuffer b = new StringBuffer();
    	for (int i=0;i<this.quotes.size();i++) {
    		b.append(this.quotes.get(i));
    		b.append("\n");
    	}
    	return b.toString();
    }
    
    private void handleEmail() {
    	String myBodyText = quotes_as_whole_string();
    	String mySubject = "Your random reminders";
    	final Intent emailIntent = new Intent(android.content.Intent.ACTION_SEND);
    	emailIntent.setType("plain/text");
    	emailIntent.putExtra(android.content.Intent.EXTRA_SUBJECT, mySubject);
    	emailIntent.putExtra(android.content.Intent.EXTRA_TEXT, myBodyText);
    	this.startActivity(Intent.createChooser(emailIntent, "Send mail..."));
    }
    private void show_error(String msg) {
    	alert("Error",msg);
    }
    private void alertok() {
    	alert("Success!");
    }
    private void alert(String msg) {
    	alert("Alert!",msg);
    }
    private void alert(String title,String msg) {
    	AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(title);
        builder.setMessage(msg);
        builder.setPositiveButton("ok", null);
        builder.show(); 
    }

    private void show_quote(String q) {
    	this.quote_textview.setText(q);
    }
    
    private ArrayList<String> filename2array(String filename) throws Exception {
    	
    	ArrayList<String> a = new ArrayList<String>();
    	FileInputStream fis = this.openFileInput(filename);
    	int available = fis.available();
    	if (available < 1) {
    		fis.close();
    		return a;
    	}
    	
    	byte[] reader = new byte[available];
    	while (fis.read(reader) != -1) {}
    	fis.close();
    	String all = new String(reader);
    	StringBuffer b = new StringBuffer();
    	for (int i=0;i<all.length();i++) {
    		char c = all.charAt(i);
    		if (c == '\n') {
    			if (b.length() > 0) a.add(b.toString());
    			b = new StringBuffer();
    		}else if (c == '\r') {
    			//ignore
    		}else {
    			b.append(c);
    		}
    	}
    	if (b.length() > 0) a.add(b.toString());
    
        return a;
    }//filename2array
    
    private boolean text2file(String filename, String text) throws Exception {
    	FileOutputStream fos = this.openFileOutput(filename,MODE_WORLD_READABLE);
    	OutputStreamWriter w = new OutputStreamWriter(fos);
    	w.append(text);
    	w.flush();
    	w.close();
    	return true;
    }
    
    private void array2filename(ArrayList<String>a, String filename) throws Exception {
    	FileOutputStream fos = this.openFileOutput(filename,MODE_WORLD_READABLE);
    	OutputStreamWriter w = new OutputStreamWriter(fos);
    
    	for (int i=0;i<a.size();i++) {
    		String s = a.get(i);
    		w.append(s);
    		w.append("\n");
    	}
    	w.flush();
    	w.close();
    	//alert(bytes + " bytes written");
    }//array2file
    
    private void add_quote(String q) {
    	this.quotes.add(q);
    	try {
    		this.write_database();
    	}catch(Exception e){
    		this.show_error("add_quote:" + e.toString());
    	}
    }
   
    private String random_quote() {
    	try {
    		if ((this.quotes == null) || (this.quotes.size() == 0)) {
    			read_database();
    		}
    		else {
    			//alert("database exists");
    		}
    		Random r = new Random();
    		int size = this.quotes.size();
    		if (size < 1) return "empty";
    		int i = r.nextInt(size);
    		return this.quotes.get(i);
    	}catch(Exception e) {
    		this.show_error("random_quote:" + e.toString());
    		return "";
    	}	
    }//random
    

    
    private void read_database() throws Exception {
    	//this.create_database_if_needed();
    	try {
    		this.quotes = filename2array(this.db_filename);	
    	}catch(FileNotFoundException fnfe) {
    		//FIXME - remove this
    		show_error("database did not exist");
    	}  	
    }//read_database
    
    private void write_database() throws Exception{
    	array2filename(this.quotes,this.db_filename);
    }
    
    private void handleNew() {
    	try {
    		read_database();
    	} catch (Exception e) {
    		show_error(e.toString());
    	}
    	AlertDialog.Builder alert = new AlertDialog.Builder(this);    
    	alert.setTitle("New Reminder");  
    	alert.setMessage("Enter Text:");  
    	final EditText input = new EditText(this);  
    	alert.setView(input);  
    	alert.setPositiveButton("Ok", new DialogInterface.OnClickListener() {  
    	public void onClick(DialogInterface dialog, int whichButton) {  
    	  String value = input.getText().toString();
    	  add_quote(value);}
    	
    	});  
    	  
    	alert.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {  
    	  public void onClick(DialogInterface dialog, int whichButton) {  
    	// Canceled.  
    	   }  
    	 });  
    	 
    	alert.show();
    	
    }
   
    private void handleAnother() {
    	try {
    		show_quote(random_quote());
    	}catch(Exception e) {
    		show_error(e.toString());
    	}

    }

    private InputStream OpenHttpConnection(String urlString) 
    throws IOException
    {
        InputStream in = null;
        int response = -1;
               
        URL url = new URL(urlString); 
        URLConnection conn = url.openConnection();
                 
        if (!(conn instanceof HttpURLConnection))                     
            throw new IOException("Not an HTTP connection");
        
        try{
            HttpURLConnection httpConn = (HttpURLConnection) conn;
            httpConn.setAllowUserInteraction(false);
            httpConn.setInstanceFollowRedirects(true);
            httpConn.setRequestMethod("GET");
            httpConn.connect(); 

            response = httpConn.getResponseCode();                 
            if (response == HttpURLConnection.HTTP_OK) {
                in = httpConn.getInputStream();                                 
            }                     
        }
        catch (Exception ex)
        {
            throw new IOException("Error connecting " + ex.toString());            
        }
        return in;     
    }

    private String downloadText(String URL)
    {
        int BUFFER_SIZE = 2000;
        InputStream in = null;
        try {
            in = OpenHttpConnection(URL);
        } catch (IOException e1) {
            // TODO Auto-generated catch block
            show_error(e1.toString());
            return "";
        }
        
        InputStreamReader isr = new InputStreamReader(in);
        int charRead;
          String str = "";
          char[] inputBuffer = new char[BUFFER_SIZE];          
        try {
            while ((charRead = isr.read(inputBuffer))>0)
            {                    
                //---convert the chars to a String---
                String readString = 
                    String.copyValueOf(inputBuffer, 0, charRead);                    
                str += readString;
                inputBuffer = new char[BUFFER_SIZE];
            }
            in.close();
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
            return "";
        }    
        return str;        
    }
    
    
    private boolean webSave() throws Exception {
    	String data = this.quotes_as_whole_string();
    	String got = doPost(this.SAVEURL,data);
    	return (got.startsWith("OK"));
    }
    private String doPost(String url, String data) throws Exception{
    	
    	HttpClient httpclient = new DefaultHttpClient();
        //Your URL
        HttpPost httppost = new HttpPost(url);
        

       
        	List<NameValuePair> nameValuePairs = new ArrayList<NameValuePair>(2);
       
        	nameValuePairs.add(new BasicNameValuePair("id", "12345"));
        	nameValuePairs.add(new BasicNameValuePair("data",data));
       
        	httppost.setEntity(new UrlEncodedFormEntity(nameValuePairs));

        	HttpResponse response;
        	response=httpclient.execute(httppost);
        	InputStream is = response.getEntity().getContent();
        	BufferedInputStream bis = new BufferedInputStream(is);
        	ByteArrayBuffer baf = new ByteArrayBuffer(2000);
        	int current = 0;  
        	while((current = bis.read()) != -1){  
        		baf.append((byte)current);  
        	}  
         
       /* Convert the Bytes read to a String. */  
       return new String(baf.toByteArray()); 
       
        
        

    } 

    
    
}//MyRemindersActivity