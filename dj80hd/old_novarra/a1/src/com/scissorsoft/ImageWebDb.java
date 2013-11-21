package com.scissorsoft;
import java.util.ArrayList;

import android.content.*;
import android.database.*;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.util.Log;
public class ImageWebDb 
{ 
	//Link
	public static final String KEY_DIRECTION = "direction";
	public static final String KEY_NODE1= "node1";
	public static final String KEY_NODE2= "node2";
	
	//Node
	 public static final String KEY_URL = "url";
	 public static final String KEY_FILENAME = "filename";
	 
	
	//Both
    public static final String KEY_ROWID = "id";
    public static final String KEY_TITLE = "title";
    public static final String KEY_PUBLISHER = "publisher";    
    private static final String TAG = "DBAdapter";
    
    private static final String DATABASE_NAME = "imageweb";
    private static final String DATABASE_TABLE_NODES = "nodes";
    private static final String DATABASE_TABLE_LINKS = "links";
    
    private static final int DATABASE_VERSION = 1;

    private static final String DATABASE_CREATE_LINKS =
        "create table links (id integer primary key autoincrement, "
        + "direction integer default 0, title text not null, node1 integer, node2 integer);";
    private static final String  DATABASE_CREATE_NODES =
        "create table nodes (id integer primary key autoincrement, "
        + "title text unique, url text, filename text);";
   
    private static final String DATABASE_DROP_LINKS =  "drop table if exists links";
    private static final String  DATABASE_DROP_NODES = "drop table if exists nodes";
    
   
   
    private final Context context;  
    private DatabaseHelper DBHelper;
    private SQLiteDatabase db;
    public static ImageWebDb instance = null;
    public static void init(Context ctx) throws Exception
    {
    	if (instance == null)
    	instance = new ImageWebDb(ctx);
    }
    public static ImageWebDb getInstance()
    {
    	return instance;
    }

   
    private ImageWebDb(Context ctx) throws Exception
    {
        this.context = ctx;
        DBHelper = new DatabaseHelper(context);
        db = DBHelper.getWritableDatabase();
        boolean exists = exists();
        Log.w("X","exists="+exists);
        System.out.println("exists="+exists);
        if (!exists())
        {
        	this.initDB();
        	
        }
        open();
    }
        
    private static class DatabaseHelper extends SQLiteOpenHelper 
    {
        DatabaseHelper(Context context) 
        {
            super(context, DATABASE_NAME, null, DATABASE_VERSION);
        }

        @Override
        //FIXME - How does this actually get called ?
        public void onCreate(SQLiteDatabase db) 
        {
        	//FIXME - how are exceptions caught ?
            db.execSQL(DATABASE_CREATE_LINKS);
            db.execSQL(DATABASE_CREATE_NODES);
        }

        
        @Override
        public void onUpgrade(SQLiteDatabase db, int oldVersion, 
                              int newVersion) 
        {
        	/*
            Log.w(TAG, "Upgrading database from version " + oldVersion 
                  + " to "
                  + newVersion + ", which will destroy all old data");
            db.execSQL("DROP TABLE IF EXISTS titles");
            onCreate(db);
            */
        }
    } //class DatabaseHelper
    
  //FIXME - Real return values
    /*
     * private boolean createDB() throws Exception
    {
    	try
    	{

    		return true;
    	}
    	catch (Exception e)
    	{
    		Log.d("db","CREATE " + e);
    		throw e;
    		//return false;
    	}
        
    }
    */
    //FIXME - Real return values
    public boolean initDB() throws Exception
    {
    	try
    	{
    		db.execSQL(DATABASE_DROP_LINKS);
    		db.execSQL(DATABASE_DROP_NODES);
    		db.execSQL(DATABASE_CREATE_LINKS);
    		db.execSQL(DATABASE_CREATE_NODES);
    	    
    		//Test data
    		ImageNode nBlue = createNodeWithSave("blue", "", "");
    		ImageNode nRed = createNodeWithSave("red", "", "");
    		ImageNode nGreen = createNodeWithSave("green", "", "");
    		
    	    
    	    createLink("", nRed, nBlue);
    	    createLink("", nRed, nGreen);
    	  
    		return true;
    	}
    	catch (Exception e)
    	{
    		Log.d("db","DELETE " + e);
    		throw e;
    		//return false;
    	}
    }//
    
    public boolean exists()
    {
    	try
    	{
    		String q = "select * from " + DATABASE_TABLE_NODES;
    		Cursor c = db.rawQuery(q,null);
    		if ((c == null) || (c.getCount() < 1)) return false;
    		q = "select * from " + DATABASE_TABLE_LINKS;
    		c = db.rawQuery(q,null);
    		if ((c == null) || (c.getCount() < 1)) return false;
    		return true; 	
    	}
    	catch (Exception e)
    	{
    			return false;
    	
    	}
    }
   
    public ImageWebDb open() throws SQLException 
    {
    	return this;
    }

    //---closes the database---    
    public void close() 
    {
        DBHelper.close();
    }
    
    
    /**
     * Get a Node object for a Node with the given title
     */
    public ImageNode getNode(String title)
    {
    	String sql = "select id,url,filename from " + 
    	DATABASE_TABLE_NODES + " where title = '" + title + "'";
    	Cursor c = db.rawQuery(sql,null);
    	ImageNode n = null;
    	if ((c != null) && (c.getCount() >= 1) && c.moveToFirst())
    	{   		
    		
    		 long id = c.getLong(0);
    		 String url = c.getString(1);
    		 String filename = c.getString(2);
    		 n = new ImageNode(id,title,url,filename);
    		 if (!n.isValid()) n = null;
    	 }
    	return n;	
    }//getNode
    
    
    //---insert a title into the database---
    public ImageNode createNodeWithSave(String title, String url, String filename) 
    {
        ContentValues initialValues = new ContentValues();
        initialValues.put(KEY_URL, url);
        initialValues.put(KEY_TITLE, title);
        initialValues.put(KEY_FILENAME, filename);
        long id = db.insert(DATABASE_TABLE_NODES, null, initialValues);
        return new ImageNode(id,title,url,filename);
    }
    
    public long createLink(String title, ImageNode node1, ImageNode node2)
    {
    	if (node1 == null || node2 == null) return -1;
    	return createLink(title,node1.id,node2.id);
    	//return node1.linkToNode(node2);
    }
    
    public long createLink(String title, long node1, long node2)
    {
    	if ((node1 == -1) || (node2 == -1)) return -1;
    	//Set everything up
        ContentValues initialValues = new ContentValues();
        initialValues.put(KEY_TITLE, title);
        initialValues.put(KEY_NODE1, node1);
        initialValues.put(KEY_NODE2, node2);
        
        //Transact it
        //db.open();
        long id = db.insert(DATABASE_TABLE_LINKS, null, initialValues);  
        //db.close();
        
        //Return it.
        return id;
    }
    //---
    /**
     * Get a string representation of the database contents.
     */
    public String getDump()
    {
    	String delim = "|";
    	String ret = "";
        Cursor c = getAllNodes();
        if (c == null) return "Null";
        if (c.getCount() < 1) return "Empty";
        c.moveToFirst();
        do {    
            	for (int i=0;i<4;i++)
            	{
            		ret = ret + c.getString(i) + delim;
            	}
            	ret = ret + "\n";
          
         } while (c.moveToNext());
       return ret;
    }
    
    public String getDump2()
    {
    	try
    	{
    	ImageNode n = getNode("red");
    	long redid = n.id;
    	if (redid >= 0)
    	{
    		ArrayList<ImageNode> a = getNodesLikedTo(n);
    		if (a == null) return "null list";
    		if (a.size() <= 0) return "empty list";
    		String ret = "";
    		for (int i=0; i<a.size(); i++)
    		{
    			ret = ret + a.get(i).toString() + "\n";
    		}
    		return ret;
    		
    	}
    	else
    	{
    		return "redid is bad";
    	}
    	}
    	catch (Exception e)
    	{
    		return e.toString();
    	}
    }
    
    
    public ArrayList<ImageNode> getNodesLikedTo(ImageNode n) throws Exception
    {
    	if (n == null) return null;
    	return getNodesLikedTo(n.id);
    }
    
    //QUESTION - Should links be both ways ?  Should their be an option for both ways ?
    public ArrayList<ImageNode> getNodesLikedTo(long id) throws Exception
    {
    	ArrayList<ImageNode> a = null;
    	String sql = 
    	"select nodes.id,nodes.title,nodes.url,nodes.filename from " + 
    	"nodes join links where links.node1 = " + id + " and links.node2 = nodes.id";
    	Cursor c = db.rawQuery(sql,null);
    	if (c == null) return a;
    	int count = c.getCount();
    	if (count < 1 || !c.moveToFirst()) return a;
    	a = new ArrayList<ImageNode>();
    	for (int i=0; i<count; i++)
    	{
    		c.move(i);
        	long pkey = c.getLong(0);
        	String title = c.getString(1);
        	String url = c.getString(2);
        	String filename = c.getString(3);
        	ImageNode n = new ImageNode(pkey,title,url,filename);
        	if (!n.isValid()) n = null;
        	if (n != null) a.add(n);
        }
    	return a;
    }
    

    //---deletes a particular title---
    public boolean deleteNode(long id) 
    {
    	//Delete the Node and all Links that have that node as an endpoint
    	//Do it as a 
        //return db.delete(DATABASE_TABLE, KEY_ROWID + "=" + rowId, null) > 0;
    	return false;
    }

    /*
      Check if our result was valid. 
               if (c != null) {
                    /* Check if at least one Result was returned. 
                    if (c.first()) { 
     */
    public Cursor getAllNodes() 
    {
    	return getAllNodes(null);
    }
    
    public Cursor getAllNodes(String where) 
    {
        return db.query(DATABASE_TABLE_NODES, new String[] {
        		KEY_ROWID, 
        		KEY_TITLE,
        		KEY_URL,
                KEY_FILENAME}, 
                where, 
                null, 
                null, 
                null, 
                null);
    }


    //---retrieves a particular title---
    public ImageNode getNode(long id) throws SQLException 
    {

        Cursor c =
                db.query(true, DATABASE_TABLE_NODES, new String[] {
                		KEY_ROWID,
                		KEY_TITLE, 
                		KEY_URL,
                		KEY_FILENAME
                		}, 
                		KEY_ROWID + "=" + id, 
                		null,
                		null, 
                		null, 
                		null, 
                		null);
        if (c != null) {
            c.moveToFirst();
        }
        ImageNode n = new ImageNode(id,c.getString(1),c.getString(2),c.getString(3));
        return n;
    }

    public boolean updateNode(ImageNode n) 
    {
        ContentValues args = new ContentValues();
        args.put(KEY_URL, n.url);
        args.put(KEY_TITLE, n.title);
        args.put(KEY_FILENAME, n.filename);
        return db.update(DATABASE_TABLE_NODES, args, 
                         KEY_ROWID + "=" + n.id, null) > 0;
    }

}

