package com.novarra;

import android.app.Activity;
import android.media.MediaPlayer;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;



public class KwikkerMainActivity extends Activity {

    private Button go;
    private Button mp3;
    private EditText location;    

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        this.setContentView(R.layout.main);

        this.location = (EditText) findViewById(R.id.location);
        this.go = (Button) findViewById(R.id.get_reviews_button);
        this.go.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                handleGo();
            }
        });
        this.mp3 = (Button) findViewById(R.id.mp3_button);
        this.mp3.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                handleMp3();
            }
        });

    }   

    @Override
    protected void onResume() {
        super.onResume();
        //Log.v(Constants.LOGTAG, " " + ReviewCriteria.CLASSTAG + " onResume");
    }
    
    private void handleMp3() {
        
        try {
          MediaPlayer mp = new MediaPlayer();
          mp.setDataSource("http://www.scissorsoft.com/djadhd/music/goodtimes.mp3");
          mp.prepare();
          mp.start();
        }catch (Exception e){
        	this.alert(e.toString());
        }
    	
    }
    private void handleGo() {
        if (!validate()) {
            return;
        }
  

        String url = this.location.getText().toString();
        if (!url.startsWith("http://")) url = "http://" + url;
        Intent intent = new Intent(Intent.ACTION_VIEW,Uri.parse(url));
        startActivity(intent);
    }

    private void alert(String s) {
        new AlertDialog.Builder(this).setTitle("ALERT!").setMessage(
                s).setPositiveButton("Continue",
                new android.content.DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int arg1) {
                        // in this case, don't need to do anything other than close alert
                    }
                }).show();
    	
    }
    
    // validate form fields
    private boolean validate() {
        boolean valid = true;
        
        StringBuilder validationText = new StringBuilder();
        if ((this.location.getText() == null) || this.location.getText().toString().equals("")) {
            validationText.append(getResources().getString(R.string.location_not_supplied_message));
            valid = false;
        }
        
        if (!valid) {
            new AlertDialog.Builder(this).setTitle(getResources().getString(R.string.alert_label)).setMessage(
                validationText.toString()).setPositiveButton("Continue",
                new android.content.DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int arg1) {
                        // in this case, don't need to do anything other than close alert
                    }
                }).show();
            validationText = null;
        }
        
        return valid;
    }
}