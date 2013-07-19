sub AACtaggin
   call gettagsofselectedsongs()
end sub


'************ STANDARD TAGGING FROM AAC's ID3 Tags in MediaMonkey ************
'*****************************************************************************


'¤¤¤¤¤¤¤¤ Setup - not ready yet

'autolist = "AAC;MP3;M4A" 'list of filetypes that are updated automatically at playtrack
'stdtag = 1 or 2 - whether default is id3v1 or id3v2



function gettagsofselectedsongs()
   set selSongs = SDB.selectedsonglist
   for i = 0 to selSongs.count-1
      if i = selSongs.count-1 then
            pos = 1
      else
            pos = 0
      end if
      gettagsofselectedsongs = getID3Tags(selSongs.item(i), pos, i)
   next
end function

function getID3Tags(SongsDBsong, pos, lid)
   set fsys = CreateObject("Scripting.FileSystemObject")
   if fsys.fileExists(SongsDBsong.path) then
      ID3coll = getID3ArrayFromFile(SongsDBsong.path)
      if ID3coll(0) > 0 then 'if tags were found
         getID3Tags = selectForm(ID3coll, SongsDBsong, pos, lid)
      end if
   end if
end function



'** form setup
dheight = 500
dwidth = 500
setinnermargin = 10
ltmarg = dwidth-(dwidth-setinnermargin)
rbmarg = dwidth-setinnermargin

function centertxt(txtwidth)
   centertxt = (dwidth - txtwidth)/2
end function

function headertxt(str)
   headertxt = chr(176) & " " & str & " " & chr(176)
end function



function selectForm(thecol, SongsDBsong, pos, lid) 'restyp, fpath)
   set mmform = SDB.UI.newform
   mmform.caption = "General ID3 Tagger"
   mmform.common.height = Dheight
   mmform.common.width = Dwidth
   mmform.FormPosition = 4

   'msgbox vartype(fpath), 0

   set frmtxt = SDB.UI.newlabel(mmform)
   tmptxt = headertxt("ID3 tag reader") & VBCrLf & VBTab & "ID3 tag information found in this file. Select appropriate action." & VBCrLf & VBCrLf & VBTab & "Filename: " & weedFileName(thecol(4))
   tmptxt = tmptxt & VBCrLf & VBTab & "Filetype: " & getFileType(thecol(4)) & VBCrLf & VBTab & "Available tags: " & resultParser(thecol)
   tmptxt = tmptxt & VBCrLf & VBCrLf & headertxt("Importing from")
   frmtxt.caption = tmptxt
   frmtxt.common.setrect centertxt(450), ltmarg, rbmarg, 130
   frmtxt.common.anchors = 1+2


   set trackID = SDB.UI.newlabel(mmform)
   trackID.caption = seltrackid
   trackID.common.visible = false

   set selIDToUse = SDB.UI.newlabel(mmform)
   selIDToUse.common.visible = false


   if thecol(0) = 3 then
      set impselv1 = SDB.UI.NewRadioButton(mmform)
      impselv1.caption = "ID3v1." & thecol(1)(1,0)
      impselv1.common.setrect ltmarg+55, ltmarg+105, rbmarg, 20
      set impselv2 = SDB.UI.NewRadioButton(mmform)
      impselv2.caption = "ID3v2." & thecol(3)(0) & "." & thecol(3)(1)
      impselv2.checked = true
      impselv2.common.setrect ltmarg+120, ltmarg+105, rbmarg, 20
      selIDToUse.caption = "x"
   else
      set impselgen = SDB.UI.newlabel(mmform)
      impselgen.caption = resultParser(thecol)
      impselgen.common.setrect ltmarg+55, ltmarg+108, rbmarg, 20
      selIDToUse.caption = thecol(0)
   end if
   
   
   set agress = SDB.UI.NewCheckBox(mmform)
   agress.caption = "Aggressive"
   agress.common.setrect ltmarg+280, ltmarg+105, rbmarg, 20
   
   set tgvhead = SDB.UI.newlabel(mmform)
   tgvhead.caption = headertxt("Tag overview")
   tgvhead.common.setrect centertxt(450), letmarg+160, rbmarg, 20

   set action = SDB.UI.newlabel(mmform)
   action.caption = 0
   action.common.visible = false


   ' Create a web browser component
   Set WB = SDB.UI.NewActiveX(mmform, "Shell.Explorer")
   WB.Common.setrect centertxt(450), letmarg+200, 445, 220
   WB.Common.ControlName = "WB"
   Set doc = WB.Interf.Document

   doc.write "<html><head><script type='text/javascript'>v2data = " & chr(34) & tagView(thecol, 2) & chr(34) & "; v1data = " & chr(34) & tagView(thecol, 1) & chr(34) & "; helpdata = " & chr(34) & helplines() & chr(34) & "</script></head><body style='margin: 0px;'>"
   doc.write "<div style='overflow: hidden; width: 425px; font-family: arial; font-size: 9pt; border-style: solid; border-width: 0px; border-color: black;'>"
   doc.write "<div id='v1' onclick='document.getElementById(" & chr(34) & "help" & chr(34) & ").style.borderBottomColor = " & chr(34) & "black" & chr(34) & ";document.getElementById(" & chr(34) & "help" & chr(34) & ").style.backgroundColor = " & chr(34) & "#CBCBCB" & chr(34) & "; document.getElementById(" & chr(34) & "v2" & chr(34) & ").style.borderBottomColor = " & chr(34) & "black" & chr(34) & ";document.getElementById(" & chr(34) & "v2" & chr(34) & ").style.backgroundColor = " & chr(34) & "#CBCBCB" & chr(34) & ";this.style.borderBottomColor = " & chr(34) & "white" & chr(34) & "; this.style.backgroundColor = " & chr(34) & "white" & chr(34) & "; document.getElementById(" & chr(34) & "main" & chr(34) & ").innerHTML = v1data' style='background-color: #CBCBCB; float: left; display: inline; width:183px; height: 22px; text-align: center; border-style: solid; border-width: 0px 1px 1px 0px; border-color: black; cursor: pointer; font-weight: bold;'>ID3v1</div>"
   
   doc.write "<div id='help' onclick='document.getElementById(" & chr(34) & "v1" & chr(34) & ").style.borderBottomColor = " & chr(34) & "black" & chr(34) & ";document.getElementById(" & chr(34) & "v1" & chr(34) & ").style.backgroundColor = " & chr(34) & "#CBCBCB" & chr(34) & "; document.getElementById(" & chr(34) & "v2" & chr(34) & ").style.borderBottomColor = " & chr(34) & "black" & chr(34) & ";document.getElementById(" & chr(34) & "v2" & chr(34) & ").style.backgroundColor = " & chr(34) & "#CBCBCB" & chr(34) & ";this.style.borderBottomColor = " & chr(34) & "white" & chr(34) & "; this.style.backgroundColor = " & chr(34) & "white" & chr(34) & "; document.getElementById(" & chr(34) & "main" & chr(34) & ").innerHTML = helpdata' style='background-color: #CBCBCB; float: right; display: inline; width:60px; height: 22px; text-align: center; border-style: solid; border-width: 0px 0px 1px 1px; border-color: black; cursor: pointer; font-weight: bold;'>help</div>"
   
   doc.write "<div id='v2' onclick='document.getElementById(" & chr(34) & "help" & chr(34) & ").style.borderBottomColor = " & chr(34) & "black" & chr(34) & ";document.getElementById(" & chr(34) & "help" & chr(34) & ").style.backgroundColor = " & chr(34) & "#CBCBCB" & chr(34) & "; document.getElementById(" & chr(34) & "v1" & chr(34) & ").style.borderBottomColor = " & chr(34) & "black" & chr(34) & ";document.getElementById(" & chr(34) & "v1" & chr(34) & ").style.backgroundColor = " & chr(34) & "#CBCBCB" & chr(34) & "; document.getElementById(" & chr(34) & "v1" & chr(34) & ").style.borderBottomColor = " & chr(34) & "black" & chr(34) & ";document.getElementById(" & chr(34) & "v1" & chr(34) & ").style.backgroundColor = " & chr(34) & "#CBCBCB" & chr(34) & ";this.style.borderBottomColor = " & chr(34) & "white" & chr(34) & "; this.style.backgroundColor = " & chr(34) & "white" & chr(34) & "; document.getElementById(" & chr(34) & "main" & chr(34) & ").innerHTML = v2data' style='float: right; display: inline; width:182px; height: 22px; text-align: center; border-style: solid; border-width: 0px 0px 1px 0px; border-color: white; cursor: pointer; font-weight: bold;'>ID3v2</div>"
   
   doc.write "<div id='main' style='font-size: 8pt; padding: 30px 10px 10px 10px ;width:400px; overflow: hidden;'>" & tagView(thecol, 2) & "</div>"
   doc.write "</div>"
   doc.write "</body></html>"



   
   '* import this button
   set btnthis = SDB.UI.Newbutton(mmform)
   btnthis.caption = "Import"
   btnthis.onClickFunc = "clk_this"
   btnthis.UseScript = Script.ScriptPath
   Btnthis.Common.SetRect Dwidth-360, Dheight-60 , 100, 20
   btnthis.common.anchors = 4+8
   btnthis.modalresult = 1
   
   
   '* import rest button
   set btnall = SDB.UI.Newbutton(mmform)
   btnall.caption = "all tracks"
   btnall.onClickFunc = "clk_all"
   btnall.UseScript = Script.ScriptPath
   Btnall.Common.SetRect Dwidth-240, Dheight-60 , 100, 20
   btnall.common.anchors = 4+8
   btnall.common.visible = false
   

   '* cancel button
   set btn = SDB.UI.Newbutton(mmform)
   if pos = 1 then
      btn.caption = "Cancel"
   else
      btn.caption = "Next"
   end if
   'btn.cancel = true
   btn.modalresult = 1
   btn.onClickFunc = "clk_cancel"
   btn.UseScript = Script.ScriptPath
   Btn.Common.SetRect Dwidth-120, Dheight-60 , 100, 20
   btn.common.anchors = 4+8

   '** show result form
   'mmform.Common.Visible = True
   SDB.Objects("actionf") = action
   SDB.Objects("ID3Tagger") = mmform
   SDB.Objects("idtouse") = selIDToUse
   SDB.Objects("ifagg") = agress
   if SDB.Objects("idtouse").caption = "x" then
      SDB.Objects("chv1") = impselv1
      SDB.Objects("chv2") = impselv2
   end if
   
   mmform.showmodal


   '*** UPDATE Functions

   if SDB.Objects("actionf").caption > 0 then
      isag = false
      if SDB.Objects("actionf").caption > 10 then
         isag = true
      end if
      select case right(SDB.Objects("actionf").caption, 1)
         case 1
            SongsDBsong.Title = pasagr(isag, thecol(1)(1,1), SongsDBsong.Title)
            SongsDBsong.ArtistName = pasagr(isag, thecol(1)(1,2), SongsDBsong.ArtistName)
            SongsDBsong.AlbumArtistName = pasagr(isag, thecol(1)(1,2), SongsDBsong.AlbumArtistName)
            SongsDBsong.AlbumName = pasagr(isag, thecol(1)(1,3), SongsDBsong.AlbumName)
            SongsDBsong.Year = pasagr(isag, thecol(1)(1,4), SongsDBsong.Year)
            SongsDBsong.Comment = pasagr(isag, thecol(1)(1,5), SongsDBsong.Comment)
            SongsDBsong.TrackOrder = pasagr(isag, thecol(1)(1,6), SongsDBsong.TrackOrder)
            SongsDBsong.Genre = getGenre(pasagr(isag, thecol(1)(1,7), SongsDBsong.Genre))
            SongsDBsong.UpdateDB
         case 2
            if thecol(3)(0) > 2 then
               id3flags3 = split("TCON;TRCK;COMM;TYER;TALB;TPE1;TIT2;TPE2", ";")
            else
               id3flags3 = split("TCO;TRK;COM;TYE;TAL;TP1;TT2;TP2", ";")
            end if
            if getv2valuefromflag(id3flags3(7), thecol(2)) = "" then
               aaname = 5
            else
               aaname = 7
            end if
            SongsDBsong.AlbumArtistName = pasagr(isag, getv2valuefromflag(id3flags3(aaname), thecol(2)), SongsDBsong.AlbumArtistName)
            SongsDBsong.Title = pasagr(isag, getv2valuefromflag(id3flags3(6), thecol(2)), SongsDBsong.Title)
            SongsDBsong.ArtistName = pasagr(isag, getv2valuefromflag(id3flags3(5), thecol(2)), SongsDBsong.ArtistName)
            SongsDBsong.AlbumName = pasagr(isag, getv2valuefromflag(id3flags3(4), thecol(2)), SongsDBsong.AlbumName)
            SongsDBsong.Year = pasagr(isag, getv2valuefromflag(id3flags3(3), thecol(2)), SongsDBsong.Year)
            SongsDBsong.Comment = pasagr(isag, getv2valuefromflag(id3flags3(2), thecol(2)), SongsDBsong.Comment)
            SongsDBsong.TrackOrder = pasagr(isag, getv2valuefromflag(id3flags3(1), thecol(2)), SongsDBsong.TrackOrder)
            SongsDBsong.Genre = pasagr(isag, getv2valuefromflag(id3flags3(0), thecol(2)), SongsDBsong.Genre)
            SongsDBsong.UpdateDB
         case else
      end select
   end if

   SDB.Objects("actionf") = nothing
   SDB.Objects("chv1") = nothing
   SDB.Objects("chv2") = nothing
   SDB.Objects("ifagg") = nothing
   SDB.Objects("idtouse") = nothing
   SDB.objects("seltrck") = nothing
   SDB.Objects("ID3Tagger") = nothing

end function


sub clk_this(btn)
   SDB.Objects("actionf").caption = howtoupdate(true)
end sub


sub clk_cancel(btnthis)
   SDB.Objects("actionf").caption = howtoupdate(false)
end sub

function helplines()
   helplines = "<div style='font-size: 12pt;'>ID3 tagger </div><div>This script was created to import ID3 tag data from AAC files and other media files which might include  relevant ID3 tags.</div><div style='margin-top: 10px;'><span style='font-weight: bold;'>* Importing From *</span><br>If the reader finds both ID3v1 and ID3v2 tag present in the file, you can choose from which tag you want to import. Default is ID3v2.</div><div style='margin-top: 5px;'>Aggressive mode will overwrite any data already present in the database, but only if data is present in the tag.</div><div>Non-aggressive mode will only insert data if the field is empty in the database.</div><div style='margin-top: 10px;'><b>disclaimer</b><br>This software is provided for full, free and open release. It is understood by the recipient/user that the author assumes no liability for any errors contained in the code.</div><div style='text-align: center; margin-top: 40px;'><span style='font-size: 7pt;'>Coded by Morten R&oslash;mer Hedegaard in 2006.<br><a style='text-decoration: none;' href='http://www.dnsupport.dk/' target='_blank'>Dansk Net Support</a><br>contact: olfert[at]osik.dk</span></div>"
end function

function pasagr(isag, frameval, preval)
   pasagr = preval
   if isag then
      if len(Cstr(frameval)) > 0 then
         pasagr = frameval
      end if
   else
      if len(Cstr(preval)) = 0 then
         pasagr = frameval
      end if
   end if
   pasagr = trim(pasagr)
end function


function howtoupdate(doupdate)
   if doupdate then
      if SDB.Objects("idtouse").caption = "x" then
         if SDB.objects("chv1").checked then
            sa = 1
         elseif SDB.objects("chv2").checked then
            sa = 2
         else
            sa = 3
         end if         
      else
         sa = SDB.Objects("idtouse").caption
      end if
      if SDB.Objects("ifagg").checked then
         sa = sa + 10
      end if
   else
      sa = 0
   end if
   howtoupdate = sa
end function



function frmtTagData(titl, data)
   'possibly better to escape unescape the strings
   titl = replace(titl, chr(34), chr(34) & " + String.fromCharCode(34) + " & chr(34))
   data = replace(data, chr(34), chr(34) & " + String.fromCharCode(34) + " & chr(34))
   frmtTagData = "<div style='font-size: 8pt; width: 425px; overflow: auto;'><div style='float: left; text-align: right; width: 80px; overflow: hidden;'>" & titl & ":</div><div style='border: solid 0px blue; float: right; width: 320px;'>" & data & "</div></div>"
end function


function tagView(thecol, vers)
   tagView = ""
   if vers = 1 then
      if thecol(0) = 1 OR thecol(0) = 3 then
         for i = 1 to 7
            if thecol(1)(1,i) <> "" then
               tagView = tagView & frmtTagData(thecol(1)(0,i), thecol(1)(1,i))
            end if
         next
      else
         tagView = "ID3v1 tag not found"
      end if
   else
      if thecol(0) > 1 then
         for i = 0 to ubound(thecol(2), 2)
            if trim(thecol(2)(1,i)) <> "" then
               flagtit = flagtomm(thecol(2)(0,i), thecol(3)(0))
               if flagtit <> "" then
                  tagView = tagView & frmtTagData(flagtit, thecol(2)(1,i))
               end if
            end if
         next
      else
         tagView = "ID3v2 tag not found"
      end if
   end if
end function


function weedFileName(fpath)
   weedFileName = right(fpath, len(fpath)-instrrev(fpath, "\"))
end function


function getFileType(fnam)
   if instrrev(fnam, ".") > 0 then
      getFileType = ucase(right(fnam, len(fnam) - instrrev(fnam, ".")))      
   else
      getFileType = "unknown"
   end if
end function



function resultParser(thecol)
   select case thecol(0)
      case -1
         resultParser = "Track inaccessible"
      case 0
         resultParser = "No tags found"
      case 1
         resultParser = "ID3v1." & thecol(1)(1,0)
      case 2
         resultParser = "ID3v2." & thecol(3)(0) & "." & thecol(3)(1)
      case 3
         resultParser = "ID3v1." & thecol(1)(1,0) & " and ID3v2." & thecol(3)(0) & "." & thecol(3)(1)
      case else
         resultparser = thecol(0)
   end select
end function



function flagtomm(flagid, v2rev)
   mmdesc = split("Genre;Track;Comment;Year;Album;Artist;Title;Album Artist", ";")
   select case v2rev
      case 2
         id3flags3 = split("TCO;TRK;COM;TYE;TAL;TP1;TT2;TP2", ";")
         for i = 0 to ubound(id3flags2)
            if flagid = id3flags2(i) then
               flagtomm = mmdesc(i)
            end if
         next
      case else
         id3flags3 = split("TCON;TRCK;COMM;TYER;TALB;TPE1;TIT2;TPE2", ";")
         for i = 0 to ubound(id3flags3)
            if flagid = id3flags3(i) then
               flagtomm = mmdesc(i)
            end if
         next
   end select
end function

function getv2valuefromflag(flagid, id2col)
   for i = 0 to ubound(id2col, 2)-1
      if id2col(0, i) = flagid then
         getv2valuefromflag = id2col(1,i)
      end if
   next
   
end function




'#########################################################################################
'######            ID3 READER 




'************* FUNCTIONS ****************************
'****************************************************


'¤¤¤¤¤¤¤¤ GENERAL ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤

function CAscToByte(str)
   for i = 1 to len(str)
      CAscToByte = CAscToByte & right("0" & hex(Asc(mid(str, i, 1))), 2)
   next
   CAscToByte = CLng("&H" & CAscToByte)
end function




Function DecToBin(intDec)

    Dim strResult
    Dim intValue
    Dim intExp
    
    strResult = ""
    intValue = intDec
    intExp = 65536
    While intExp >= 1
        If intValue >= intExp Then
            intValue = intValue - intExp
            strResult = strResult&"1"
        Else
            strResult = strResult&"0"
        End If
        intExp = intExp/2
    Wend
    DecToBin = Right(strResult,8)
    
End Function


'¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
'             ¤¤¤ ID3v2 ¤¤¤
'¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤


function getID3v2HeadInfo(id3header)
   redim outp1(3)
   outp1(0) = -1
   if len(id3header) = 10 then
      if left(id3header, 3) = "ID3" then
         outp1(0) = CAscToByte(mid(id3header, 4, 1)) 'version
         outp1(1) = CAscToByte(mid(id3header, 5, 1)) 'revision
         outp1(2) = CAscToByte(mid(id3header, 7, 4)) 'size with header
         outp1(3) = CAscToByte(mid(id3header, 6, 1)) 'flags
      end if
   end if
   getID3v2HeadInfo = outp1
   'msgbox outp1(2), 0
end function


function getID3v2(bytestring, version)
   i = 1 'the beginpoint of extraction for every frame
   n = 0 'the next arrayelement number
   
   fridsize = 4 'frameid size
   frameheadsize = 10
   if version = 2 then 'in vresion 2 frame size is three char, 3 and 4, four char
      fridsize = 3
      frameheadsize = 6
   end if
   
   redim outp1(1,0)
   
   outp1(1,0) = i < len(bytestring)
   
   do while i < len(bytestring)
      redim preserve outp1(1,n)
      frameid = replace(mid(bytestring, i, fridsize), chr(00), "")
      if len(frameid) <> fridsize then 'simple test for valid Frameid, implement better test later (comparisons)
         exit do
      else
         outp1(0,n) = frameid
         frameLen = CAscToByte(mid(bytestring, i+fridsize, fridsize))
         outp1(1,n) = replace(mid(bytestring, i+frameheadsize, frameLen), chr(00), " ")
         n=n+1
         i=i+frameLen+frameheadsize
      end if
   loop
   getID3v2 = outp1
end function


'¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
'          ¤¤¤ END ID3v2 END ¤¤¤
'¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤














'¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
'         ¤¤¤ ID3v1.0 og ID3v1.1 ¤¤¤
'¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
'   later to be converted into class


function id3v1FrameTitles(pos)
   id3v1FrameTitles = split("Version;Title;Artist;Album;Year;Comment;Track;Genre", ";")(pos)
end function

function getID3v1(bytestring)
   redim tmparr(1,7)
   tmparr(1,0) = -1 'version number
   if len(bytestring) = 128 then
      if left(bytestring, 3) = "TAG" then
         versiondata = evalID3v1version(mid(bytestring, 98, 30)) 'comment and track number in v1.1
         tmparr(1,0) = versiondata(0) 'version number
         tmparr(1,1) = id3v1tagstrings(mid(bytestring, 4, 30)) 'song title
         tmparr(1,2) = id3v1tagstrings(mid(bytestring, 34, 30)) 'artist
         tmparr(1,3) = id3v1tagstrings(mid(bytestring, 64, 30)) 'album
         tmparr(1,4) = id3v1tagstrings(mid(bytestring, 94, 4)) 'year
         tmparr(1,5) = versiondata(1) 'comment
         tmparr(1,6) = versiondata(2) 'track number
         tmparr(1,7) = getGenre(CAscToByte(mid(bytestring, 128,1))) 'genre
      end if
      for i = 0 to 7
         tmparr(0,i) = id3v1FrameTitles(i)
      next
   end if
   getID3v1 = tmparr
end function

function evalID3v1version(cmtstr)
   dim outp1(2)
   trckinfo = right(cmtstr, 2)
   if CAscToByte(left(trckinfo, 1)) = 0 then
      outp1(0) = 1 'version number
      outp1(1) = id3v1tagstrings(left(cmtstr, 28)) 'comment
      outp1(2) = CAscToByte(right(cmtstr, 1)) 'tracknumber
   else
      outp1(0) = 0 'version number
      outp1(1) = id3v1tagstrings(cmtstr) 'comment
   end if
   evalID3v1version = outp1
end function

function getGenre(genreID)
   genreID = replace(genreID, "(", "")
   genreID = replace(genreID, ")", "")
   id3v1genres = split("Blues;Classic Rock;Country;Dance;Disco;Funk;Grunge;Hip-Hop;Jazz;Metal;New Age;Oldies;Other;Pop;R&B;Rap;Reggae;Rock;Techno;Industrial;Alternative;Ska;Death metal;Pranks;Soundtrack;Euro-Techno;Ambient;Trip-hop;Vocal;Jazz+Funk;Fusion;Trance;Classical;Instrumental;Acid;House;Game;Sound Clip;Gospel;Noise;Alt. Rock;Bass;Soul;Punk;Space;Meditative;Instrumental pop;Instrumental rock;Ethnic;Gothic;Darkwave;Techno-Industrial;Electronic;Pop-Folk;Eurodance;Dream;Southern Rock;Comedy;Cult;Gangsta;Top 40;Christian Rap;Pop/Funk;Jungle;Native American;Cabaret;New Wave;Psychedelic;Rave;Showtunes;Trailer;Lo-Fi;Tribal;Acid Punk;Acid Jazz;Polka;Retro;Musical;Rock & Roll;Hard Rock;Folk;Folk-Rock;National Folk;Swing;Fast Fusion;Bebob;Latin;Revival;Celtic;Bluegrass;Avantgarde;Gothic Rock;Progressive Rock;Psychedelic Rock;Symphonic Rock;Slow Rock;Big Band;Chorus;Easy Listening;Acoustic;Humour;Speech;Chanson;Opera;Chamber music;Sonata;Symphony;Booty Bass;Primus;Porn groove;Satire;Slow Jam;Club;Tango;Samba;Folklore;Ballad;Power ballad;Rhythmic soul;Freestyle;Duet;Punk rock;Drum Solo;A cappella;Euro-house;Dance hall;Goa;Drum & Bass;Club-House;Hardcore;Terror;Indie;BritPop;Negerpunk;Polsk Punk;Beat;Christian gangsta rap;Heavy metal;Black metal;Crossover;Contemporary Christian;Christian Rock;Merengue;Salsa;Thrash metal;Anime;JPop", ";")
   if isnumeric(genreID) then
      if genreID >= 0 AND genreID < 148 then
         getGenre = id3v1genres(genreID)
      else
         getGenre = "(" & genreID & ")"
      end if
   end if
end function

function id3v1tagstrings(str)
   id3v1tagstrings = trim(replace(str, chr(00), " "))
end function


'¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
'    ¤¤¤ END ID3v1.0 og ID3v1.1 END ¤¤¤
'¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤






'¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
'    ¤¤¤ Collecting the ID3 Data ¤¤¤
'¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤

function getID3ArrayFromFile(filepath)
   redim id3collection(4)
   dim resultindex
   dim filedata(0)
   
   'filedata(0) = filepath
   id3collection(4) = filepath
   
   set fsys = CreateObject("Scripting.FileSystemObject")
   if fsys.FileExists(filepath) then
      resultindex = 0
      set targ = fsys.GetFile(filepath)
      fsiz = targ.size
      Set targ = fsys.OpenTextFile(filepath, 1, -1)
      addmovepointer = 0

      id3collection(3) = getID3v2HeadInfo(targ.read(10))
      if id3collection(3)(0) > -1 then 'if a tag was found
         resultindex = 2
         addmovepointer = id3collection(3)(2)-10
         ID3v2FrameCollection = getID3v2(targ.read(addmovepointer), id3collection(3)(0))
         id3collection(2) = ID3v2FrameCollection
      end if

      targ.skip(fsiz-(138+addmovepointer))
      last128bytes = targ.read(128)
      ID3v1FrameCollection =  getID3v1(last128bytes)
      if ID3v1FrameCollection(1,0) > -1 then
         if resultindex = 2 then
            resultindex = 3
         else
            resultindex = 1
         end if
         id3collection(1) = ID3v1FrameCollection
      end if
      
   else
      resultindex = -1
   end if
   
   id3collection(0) = resultindex
   getID3ArrayFromFile = id3collection
end function


'¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
' ¤¤¤ END Collecting the ID3 Data END ¤¤¤
'¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤