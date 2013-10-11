package com.scissorsoft;
import android.content.*;
import android.database.*;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;

public class ImageNode {
  public long id = -1;
  public String title = "";
  public String url = "";
  public String filename = "";
  /*
   * Ideal IF
   * 
   * FIXME - Reserve 0 as an id for non saved nodes !
   * 
   * ImageNode getNode(String title);
   * ImageNode getNode(long id);
   * boolean nodeExists(long id);
   * boolean nodeExists(String title);
   * ImageNode createNodeWithSave(String title, String url, String filename);
   * ImageNode createNodeWithoutSave(String title, String url, String filename);
   * long linkId linkToNode(ImageNode n);
   * long linkId linkToNode(long id);
   * ArrayList<ImageNode> getLinkedNodes();
   * 
   * 
   */
  
  public ImageNode(long id, String title)
  {
	  this(id,title,"","");
  }
  public ImageNode(long id, String title, String url, String filename)
  {
	  this.id = id;
	  this.title = title;
	  this.url = url;
	  this.filename = filename;
  }
  public boolean isValid()
  {
	  return (id > -1);
  }
  
  public long linkToNode(ImageNode n)
  {
	  return -1;
  }
  public String toString()
  {
	  return "id=" + this.id + " title=" + this.title + " url=" + this.url + " file=" + this.filename;
  }
}

