package dj80hd.typeattack;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.view.View;

public class TypeAttackView extends View{
  private Paint mPaint;
  public TypeAttackView(Context context) {
			super(context);
			this.mPaint = new Paint(Paint.ANTI_ALIAS_FLAG);

			// TODO Auto-generated constructor stub
  }
	    public void onDraw(Canvas canvas) {
	    	canvas.drawText("RED914", 50,50, this.mPaint);
	    }
}
