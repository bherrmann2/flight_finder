package dj80hd.typeattack;

import android.app.Activity;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.os.Bundle;
import android.view.View;
import android.widget.FrameLayout;

public class TypeAttack extends Activity {
    /** Called when the activity is first created. */
	


   
    
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        FrameLayout main = (FrameLayout) findViewById(R.id.main_view);
        main.addView(new TypeAttackView(this));
     
    }

}