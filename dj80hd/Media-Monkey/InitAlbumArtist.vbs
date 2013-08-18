' A simple script that initializes the Album Artist with the Artist if it Album Artist is blank

Sub InitAlbumArtist
  ' Define variables
  Dim list, itm, i, tmp

  ' Get list of selected tracks from MediaMonkey
  Set list = SDB.CurrentSongList 

  ' Process all selected tracks
  For i=0 To list.count-1
    Set itm = list.Item(i)

    ' Swap the fields
    tmp = itm.Title
	' Should check if empty
	If itm.AlbumArtistName = "" Then
		itm.AlbumArtistName = itm.ArtistName
	End If
  Next

  ' Write all back to DB and update tags
  list.UpdateAll
End Sub
