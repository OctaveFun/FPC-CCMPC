unit DisplayAndChoose;
                           interface


function ChooseFile(var quit: boolean):string;

type
choiceArray = array of boolean;

function ChooseChannels(channels: array of ansistring; Var cleanUp : array of Boolean; Var Done: Boolean):ChoiceArray;

function WhatsNext():string;


                                implementation

 uses sysutils, graph, winMouse, winCRT;


function ChooseFile(var quit: boolean):string;

Var

  FileArray : array of TSearchRec;
  FileInfo        : TSearchRec;
  count           : LongInt;
  i               : Integer;
  ChosenFile      : ansistring;
  gm,gd           : integer;
  x,y             : Integer;
  mposX, mposY, state : LongInt;
  highLight       : LongInt;
  PageSize        : LongInt;
  Start           : LongInt;

Begin
   repeat until not lpressed;      { NEEDED!! so the menu will not jump from one to another while mouse button is pressed !}
   ChosenFile := '';
  { gd:=detect; gm:=0; Initgraph(gd,gm,''); initMouse; }      {comment-out for new version}
   clearDevice;
   setColor(3);
   setTextStyle(1,0,2);
   PageSize := (GetMaxY-30) div (TextHeight('123TH') + 3);

 ChDir('C:\CCMPC\CCMEXE\DATALOG\');                           {this is where engine logs saved by default}
 Count := 0; i:=0;
 quit := false;

 If FindFirst('*.txt', faAnyFile, FileInfo) = 0 Then
   Begin
   Repeat
     SetLength( FileArray, Count+1);
     FileArray[count] := FileInfo;
     Inc(Count); inc(i);
   Until FindNext(FileInfo) <> 0;
   FindClose(FileInfo);
   end
 Else OutTextXY(50,100, ' No Text Files in this directory');

 Start:=Low(FileArray);

   cleardevice;

    MoveTo(800,40);
 LineTo(800,200);
 LineTo(860,200);
 LineTo(860,40);
 LineTo(800,40);
 setTextStyle(1,1,2);
 OutTextXY(830,80, 'EXIT');
 setTextStyle(1,0,2);

   repeat
     count:=1;
     for i:=Start to high(FileArray) Do              (*OUTPUT FILENAMES TO SCREEN*)
       Begin
         FileInfo := FileArray[i];
         If i=highLight Then setColor(15) Else setColor(3);
         OutTextXY( (GetMaxX div 10), (20 + (TextHeight(FileInfo.Name)+3)*count), FileInfo.Name);
         OutTextXY( (GetMaxX div 3), (20 + (TextHeight(FileInfo.Name)+3)*count), IntToStr(FileInfo.Size));
         inc(count);
       End;

        GetMouseState(mposX, mposY, state);
        highLight := (start-1) + ((mposY-20) div (TextHeight(FileInfo.Name)+3));
        If ((mposX <900) and (mposX>800)) and lpressed Then Begin quit:=true;  end;

        If Keypressed  Then                 {Handling list of files, which is longer than screen}

        Begin

        if readkey = #0 then

            Case readkey of

            #72 :  If Start > 0 Then
                     Begin
                      Start := Start -1;       (*scroll up*)
                      cleardevice;
                     end;
            #80 :  If Start < High(FileArray) Then
                     Begin
                     Start := Start +1;        (*scroll down*)
                     cleardevice;
                     end;
            #73 :  If (Start - pageSize) > 0 Then
                     Begin
                     Start := Start-PageSize;
                     cleardevice;
                     end
                   Else
                     Begin
                     Start := 0;                (*pageUP*)
                     cleardevice;
                     end;

            #81 :  If (Start + PageSize) < High(FileArray) Then
                     Begin
                     Start:=Start + PageSize;     (*pagedown*)
                     cleardevice;
                     end;

            end;
        End;

   until ((highLight <= High(FileArray)) and (lpressed or keypressed)) or quit;

   ChooseFile:= FileArray[highlight].name;

   end;
   (***************************************************************************************)

      Function ChooseChannels(channels: array of ansistring; var cleanUp : array of Boolean; var Done: Boolean):ChoiceArray ;

     Var
      gm,gd           : integer;
      x,y             : Integer;
      mposX, mposY, state : LongInt;
      highLight       : LongInt;
      maxX, MaxY      : integer;
      header, footer, leftBorder, rightBorder : integer;
      count, i        : integer;
      textSize        : integer;
      varFieldY       : integer;
      numberOfChannels: integer;
      Launch          : Boolean = false;

     Begin

     repeat until not lpressed;          {this needed to prevent jumping from one menu to another while enter key held down}
      clearDevice;
      setColor(3); setTextStyle(1,0,2); setLineStyle(0,0,0);
      maxX :=GetMaxX; MaxY:=GetMaxY;
      header:=20;footer:=20;leftBorder:=20;rightBorder:=20;
      textSize:= TextHeight('123TH');

      MoveTo(leftBorder, header); LineTo(leftBorder,MaxY-footer);            (*building table grid*)
      MoveTo(450,header); LineTo(450, MaxY-footer);
      MoveTo(600,header); LineTo(600,MaxY-footer);
      MoveTo(750,header); LineTo(750,MaxY-footer);
      MoveTo(900,header); LineTo(900,MaxY-footer);
      MoveTo(leftBorder,header); LineTo(900, header);
      MoveTo(leftBorder,MaxY-footer); LineTo(900, MaxY-footer);
      OutTextXY(leftBorder+10, header+2,'available channels');                           (*headers*)
      MoveTo(leftBorder,footer+TextSize+6); LineTo(900,footer+TextSize+6);
      OutTextXY(600+3,header+2,'mov.aver.'); OutTextXY(750, header+2,'least sq');
      OutTextXY(450+10,header+2,'as is' );                                               (*launch button*)
      SetTextStyle(1,1,3); OutTextXY(950,60,'ACCEPT AND LAUNCH');
      OutTextXY(1000,60,'EXIT');
      MoveTo(960,40); LineTo(960,500);LineTo(910,500); LineTo(910,40);LineTo(960,40);
      SetTextStyle(1,0,2);
      OutTextXY(30, MaxY-20, 'select/de-select : left/right mouse buttons then press ENTER');

      varFieldY := header+TextSize+10;                                     (*VarFieldY size is all above*)
      SetLength(ChooseChannels, Length(channels));

      for i:=Low(ChooseChannels) to High(ChooseChannels) Do                 (*re-freshing values for a new plot *)
        Begin
          ChooseChannels[i]:=false;
          cleanUp[i]       :=false;
        end;

      Repeat
      count:=0;

      For i:=Low(Channels) To High(channels) Do
        Begin
        delete(channels[i],25,(Length(channels[i])-25));                           (*trimming strings to fit window*)
        If ChooseChannels[count] = true Then SetColor(15);                       (*highlighting choosen channels *)
        OutTextXY(leftBorder+10, VarFieldY + ((TextSize+3)*i), channels[i]);        (*displaying channel name*)
        If cleanUp[i] = false Then  setColor(0);
        OutTextXY(610, VarFieldY+((TextSize+3)*i), 'XXXXXX' );   (*displaying data cleanUp option*)
        SetColor(3); If channels[i] <> '' Then count:=Count+1;
        end;

      repeat until lpressed or keypressed or rpressed;
      if lpressed or rpressed then
        Begin
        GetMouseState(mposx,mposy,state);
        If mposX<750 Then
                    Begin
                      highLight := ((mposY - VarFieldY) div (textSize+3));
                      If highLight <= count  Then
                      Begin
                        If lpressed Then
                          Begin
                            ChooseChannels[highLight] := true;
                            If (mposX>600) and (mposX<750) Then

                              cleanUp[highLight]:= true;                       {cleanUP is parallel to ChooseChannels}


                          end;
                        If rpressed Then
                          Begin
                            If mposX < 450 Then ChooseChannels[highLight] := false;
                            If (mposX > 600) and (mposX<750) Then cleanUp[highLight] := false;
                          End;
                      end;
                    end;

        If (mposx>910) and (mposX<960) and (mposY>40) and (mposY<500) Then Launch:=true;
        If (mposX > 960) and (mposY>40) and (mposY<500) Then Done:=true;


        End;
        If keypressed Then
        Begin
        case readkey of
          #13:  Launch:=true;
        end;
        end;


      until launch or Done;

     { closegraph; }    {comment-out for new version}

     End;

 (*********************************Function What is Next ***************************)

    function WhatsNext():string;


    begin

    end;




  end.
