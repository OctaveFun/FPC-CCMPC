program Interactive_Graphs;
{$MODE ObJFPC}

uses winCRT, winMouse, SysUtils, StrUtils, Graph, DOS, GraphSave, DisplayAndChoose;


const
separator : string = ',';

type
stringArray = array of string;
channel     = array of real;
ArrayOfChannel = array of channel;
ScaledIntArray = array of array of Integer;


Var

channels     : ArrayOfChannel;           {all numerical values obtained from engine are here}
LineStringArray : array of ansistring;   {intermediate array of string, re-written while reading new line from log}
ChannName    : array of ansistring;      {3rd line in each CCMPC log is names of channels, like "oil pressure" etc}
Units        : array of ansistring;      {second line is units for each channel, like kPa, RPM, Celcius etc}
LogParticulars : array of ansistring;    {date, time, log length etc, I want this data saved with each graph image}
PlotArray    : ScaledIntArray;           {ready-to-plot 2D array containing all values, scaled to plottable area integers}
SourceFile   : text;
FileName     : string;
GraphImageName: string;
ImageNumber  : string;

Done         : boolean = false;       {allows to drop out of chooseChannel menu back to chooseFile menu }
Quit         : boolean = false;       {exiting from chooseFile and exiting main program}
exitGraph    : boolean = false;       {exiting the graph back to chooseChannel menu}
mouseEvent   : boolean = false;       {to distinguish between mouse position when Lpressed and when released, plotting area between the two}
Options      : array of boolean;      {sets whether we smooth curves or not}
choices      : array of boolean;      {array tells us which channel will be plotted, out of all available}

Line         : string;
LineArray    : array of string;
LastLine     : Integer;
LogLength    : Integer;

numberOfChannels : Integer=1;
CycleCounter : Integer;
mposX1, mposY1, state1 : longInt;
mposX2, mposY2, state2 : longInt;
gd, gm, maxX, maxY  : smallInt;
BottomBorder        : Integer;       {duplicate with local in "scale", for re-use in procedure "plot"}

i,j,k,l,t,n  : Integer;              {misc. counters}


(*************De-Quote Function ******************)
function DeQuote(quotedText : string) : string;
Var
   quote : string = '"';
Begin
  repeat
  Delete(quotedText, pos(quote, quotedText),1);
  until (pos(quote, quotedText) = 0);
  DeQuote := quotedText;
end;
(*************End of De-Quote Function ***********)

(*******String Trim Function *********************)

Function TrimString( s: string; a,b : integer):string;
   Var
    TotLength : integer;
Begin



End;

(************* Moving Average Function ***********)
function MovingAverage(a:scaledIntArray; b:array of boolean; n:integer) : scaledIntArray;    { "n" is "average of"}

Var
 k, i, j : integer;
 sum : integer =0;
Begin
  for J:= Low(b) to High(b) Do
  Begin
     if b[j] then
        Begin
           for i:= (Low(a[j])+n) To (High(a[j])-n) Do
              Begin
                 sum:=0;
                 for  k:=n downto 1 Do sum := sum + a[j,(i-k)] + a[j,(i+k)];
                 a[J,i]:=round((sum+a[J,i])/(2*n+1));
              End;
        End;
  End;

  MovingAverage:=a;

End;
(************* END moving average ****************)

(************* Inverted Matrix Function **********)
Function InvertMatrix( a : ArrayOfChannel) : arrayOfChannel;
Var
i,j : Integer;
b   : arrayOfChannel;
Begin
 SetLength(b, numberOfChannels, LogLength);
 SetLength(InvertMatrix, numberOfChannels, LogLength);
 For i:=Low(a) To High(a) Do
   For j:=Low(a[i]) To High(a[i]) Do
    b[j,i] := a[i,j] ;
 InvertMatrix := b;
End;
(************ END Inverted Matrix Function *******)

(************ SCALE Function *********************)

function Scale( a: ArrayOfChannel; MaxX, MaxY, topBorder, bottomBorder, LeftBorder, RightBorder: Integer): ScaledIntArray;

Function ArrayMin(a: channel) : real;
  Var i:Integer;
      b: real;                                            (* Sub-Function : Finding Array Min *)
  Begin
    b:=a[Low(a)];
    For i:=Low(a) to High(a) Do If b>a[i] Then b:=a[i];
    ArrayMin:=b;
  End;

Function ArrayMax(a: channel) : real;
  Var
    i: Integer;
    b: real;                                              (* Sub-Function : Finding Array Max *)
  Begin
    b:=a[Low(a)];
    For i:= Low(a) To High(a) Do
      if b < a[i] Then b:=a[i];
    ArrayMax:=b;
  End;



  var
     i,j        : Integer;

     ScaleCoeff :  real;
     VertOffset :  real;
     MaxValue   :  real;
     MinValue   :  real;

     b          : ScaledIntArray;

  Begin                                                    { J becomes a row number, an individual engine..}
     setLength(b, length(a), Length(a[0]));                {..parameter, which will be scaled and direct plot ready}
     For j:=(Low(a)+1) To High(a) Do                       {first row is sample#, need not be scaled,   "+1"}
     Begin

       If ((ArrayMax(a[j]) - ArrayMin(a[j])) = 0 )   Then
       For i:=Low(a[j]) To High(a[j]) Do b[j,i] := (300 + J*5)

       Else
          Begin
           ScaleCoeff := (MaxY -(topBorder+BottomBorder))/(ArrayMax(a[j])-ArrayMin(a[j])) ;
           VertOffSet := arrayMin(a[j])*ScaleCoeff;
           For i:=Low(a[j]) to High(a[j]) Do
             b[j,i] := round(MaxY-(a[j,i] * ScaleCoeff - VertOffSet) - BottomBorder);
          End;
     End;

   Scale :=b;

  End;
(************END of Scale Function ***************)

(**********  PLOT PROCEDURE **********************)

Procedure plot(a: scaledIntArray; choices, options : array of boolean ) ;

Var

  i,j,k          : Integer;
  r              : Integer=1;
  start, finish: Integer;
  PlotsCount   : Integer;
  Key            : char;
  ValueAtMousePos : channel;           {channel is dynamic array of real type}
  step : real;
  gauge: string;
  minutes : integer;
  seconds : integer;
  StrMinutes : string;
  StrSeconds : string;
  Marker    : array of array of integer;     {pixels under marker stored here, and re-plotted as marker line moves away}
  MouseMoved : Boolean=true;
  BigWindow   : ViewPortType;
  LilWindow   : ViewPortType;
  Clip        : Boolean = true;
Begin
 GetViewSettings( BigWindow );               {BigWindow will restore viewport to its original size, see running marker}
 clearDevice;
 exitGraph:= false;
 SetLength(ValueAtMousePos,Length(ChannName));
 SetLength(Marker,3,GetMaxY-20-BottomBorder);
 start      := 30 ;                    {reason for 30 : half of log files have jibberish data at the beginning}
 finish     := (LogLength-5);
 a:= MovingAverage(a,Options, 5);      { Options keeps choices which channels needs a cleanup, third arg is "average of"}
 setTextStyle(1,0,1);
   repeat   {graph re-plotted at each graph control input}
    if not ExitGraph Then
    Begin
      cleardevice;
      PlotsCount := 1;                            {Plots Count needed to display data series labels, properly allocate space}
      mouseEvent := false;
      step :=((MaxX-40) / (finish - start));
      setColor(3); OutTextXY(20,2,LogParticulars[0]); OutTextXY((40 +TextWidth(LogParticulars[0])),2,LogParticulars[1]);
      OutTextXY((60 + TextWidth(LogParticulars[0]) + TextWidth(LogParticulars[1])), 2, LogParticulars[2]);
      MoveTo(20,20); LineTo(MaxX-20, 20); MoveTo(20, MaxY-20); LineTo(MaxX-20, MaxY-20);
      SetTextStyle(1,0,1);
      OutTextXY(20,MaxY-15,'KEYBOARD INPUT : ZOOM IN/OUT: W/S | PAN LEFT/RIGHT: A/D | CHANGE COLORS "C" | SAVE IMAGE "R" | EXIT : ENTER');
      SetColor(15); SetLineStyle(DashedLn,1,NormWidth);
      OutTextXY(780, (MaxY-BottomBorder+20), 'TIME:');

          for J := Low(choices) to high(choices) Do
            Begin
              if choices[J] then
                begin
                  SetColor(J+R); SetLineStyle(SolidLn,1,normWidth);
                  outTextXY(50, (MaxY - BottomBorder + (PlotsCount*(TextHeight('I')+3))), ChannName[J]);
                  outTextXY((trunc(MaxX* 0.55) + 120), (MaxY - BottomBorder + (PlotsCount*(TextHeight('I')+3))), Units[j]);
                  MoveTo(20, A[J,start]);
                  k:=1;
                  for i := (start+1) to finish Do
                     Begin
                     LineTo((round(step*k)+20), A[J,i]);
                     inc(k);
                     end;
                  Inc(PlotsCount);

                end;
            end;

        (*************************************)
        {***GRAPH CONTROL INPUT***************}
        (*                                   *)
        (*************************************)

        GetMouseState(mposX2,mposY2,state2);
        If MposX2<20 Then MposX2:=20; If MposX2 > (MaxX-20) Then MposX2 := MaxX-20;
        SetColor(15); SetLineStyle(DashedLn,1,1);
        MoveTo(mposX2, 20); LineTo(mposX2, (MaxY-BottomBorder));      {drawing marker for first time}

         seconds :=round((mposX2-20)/step)+start;                     {calculating time at mouse position}
         minutes := trunc(seconds/120);
         seconds := (seconds- minutes*120) div 2;
         Str(minutes, StrMinutes); str(seconds, StrSeconds);  StrMinutes := StrMinutes + ' : ' + StrSeconds;
         OutTextXY(780, (MaxY-BottomBorder+20+TextHeight('I') +3), StrMinutes);
         PlotsCount:=1;
         For J:=Low(Choices) To High(Choices) Do                      {displaying values at marker}
           Begin
             If Choices[J] Then
               Begin
                 SetColor(J+R);
                 ValueAtMousePos[J] := channels[J,(start + round((mposX2-20)/step))] ;
                 Str(ValueAtMousePos[J]:0:1, Gauge);
                 outTextXY(trunc(MaxX * 0.55), (MaxY - BottomBorder + (PlotsCount*(TextHeight('I')+3))), Gauge);
                 PlotsCount:=PlotsCount+1;
               End;
           End;

        repeat

            GetMouseState(mposX1,mposY1,state1);
(* R *)       If MposX1<20 Then MposX1 :=20; If MposX1>(MaxX-20) Then MposX1:=MaxX-20;
(* U *)       If mposX1<> mposX2  Then                        {determining if mouse rolled from position}
(* N *)       Begin
(* N *)           SetColor(0); OutTextXY(780, (MaxY-BottomBorder+20+TextHeight('I')+3), StrMinutes);  { deleting old time}
(* I *)           SetViewPort(trunc(MaxX*0.55),(MaxY-BottomBorder), (trunc(MaxX*0.55)+55), (MaxY-20), Clip);
(* N *)           ClearViewPort;                                                                               {deleting old values}
(* G *)           SetViewPort(BigWindow.x1,BigWindow.y1, BigWindow.X2, BigWindow.Y2,BigWindow.Clip);           {..from viewport area on display}
(*   *)           PlotsCount:=1;
(* M *)           For J:=Low(Choices) To High(Choices) Do
(* A *)              Begin
(* R *)                ValueAtMousePos[J] := channels[J,(start + round((mposX1-20)/step))] ;  {populating array with new values}
(* K *)                plotsCount:=PlotsCount+1;
(* E *)              End;
(* R *)
                  SetColor(15); SetLineStyle(DashedLn,1,1);        {plotting new marker line at mouse X1}
                  MoveTo(mposX1, 20);  LineTo(mposX1, MaxY-BottomBorder);
                  MoveTo(mposX2, 20);
                  SetLineStyle(SolidLn,1,NormWidth); SetColor(0);        {deleting marker from previous mouse X2}
                  LineTo(mPosX2,MaxY-BottomBorder);
                  putpixel(mposX2,20,3);                                 (*restoring upper border line*)
                  PlotsCount:=1;
           for J:=Low(Choices) to High(Choices) Do
             if Choices[J] then
               Begin
                  SetColor(J+R);                                 (*re-plotting to restore the graph after marker deletion*)
                  MoveTo((trunc(trunc((mposX2-20)/step)*step-step)+20), A[J, ((start-1)+trunc((mposX2-20)/step))]);
                         LineTo((trunc(trunc((mposX2-20)/step)*step)+20), A[J, (start + trunc((mposX2-20)/step))]);
                         LineTo((trunc(trunc((mposX2-20)/step)*step+step)+20), A[J, (start+1+trunc((mposX2-20)/step))]);
                         Str(ValueAtMousePos[J]:0:1, Gauge);
                         OutTextXY(trunc(MaxX * 0.55), (MaxY - BottomBorder + (PlotsCount*(TextHeight('I')+3))), Gauge);
                         PlotsCount:=PlotsCount+1;
                     End;
                  mposX2:=MposX1;     {new position becomes old before next iteration}
                  seconds :=round((mposX1-20)/step)+start;
                  minutes := trunc(seconds/120);
                  seconds := (seconds- minutes*120) div 2;
                  Str(minutes, StrMinutes); str(seconds, StrSeconds);  StrMinutes := StrMinutes + ' : ' + StrSeconds;
                  SetColor(15);
                  OutTextXY(780, (MaxY-BottomBorder+20+TextHeight('I') +3), StrMinutes);
              End;

        until lpressed or rpressed or keypressed;

        if lpressed Then
           Begin
             While lpressed Do
               Begin
                 If MouseEvent = false then
                   Begin
                     GetMouseState(mposX1, mposY1, state1);
                     If MposX1<20 Then MposX1:=20;
                     If MposX1>(MaxX-20) Then MposX1:=(MaxX-20);
                     MouseEvent := true;
                   End;
                   GetMouseState(mposX2,mposY2,state2);
                   If MposX2<20 Then MposX2:=20; If MposX2 > (MaxX-20) Then MposX2 := MaxX-20;
                   SetColor(15); SetLineStyle(DashedLn,1,1);
                   MoveTo(mposX2, 20);  LineTo(mposX2, MaxY-BottomBorder);
               End;
                if MouseEvent and ((Mposx2 - mposX1) > 40) Then
                Begin
                  finish:= finish - round((MaxX-MposX2-20)/step);
                  start := Start + round((mposx1-20)/step);
                End;

        End; {if lpressed}
        if rpressed Then Begin start:=30; finish:=(LogLength-5); end;

        if keypressed then
           Begin
            while keypressed Do Key := readkey;             { this works around keystroke buffer }
            case Key of
            #115  : begin
                      if (start > 70)  then start  := start-40;            {zoom out}
                      if (finish < (LogLength - 45)) then finish := finish + 40;
                    end;
            #119  : if ((finish - start) > 120)  Then                        {zoom in, limited to 40 }
                    begin
                      start := start + 40; finish := finish - 40;
                    end;
            #97   : if (start > 70) then
                    begin start := start -40; finish := finish - 40; end;    {pan left}
            #100  : if (finish < (LogLength - 65)) then
                    begin finish := finish + 40; start := start + 40; end;   {pan right}
            #13   : ExitGraph := true;
            #99   : R:=Random(5);
            #114  : Begin
                       SetTextStyle(1,0,2); SetColor(15);
                       outTextXY((TextWidth(LogParticulars[0]) + TextWidth(LogParticulars[1]) - 30 ), 2, 'SAVING IMAGE, WAIT ...');
                       SetTextStyle(1,0,1);
                       Str(Random(50),ImageNumber);
                       GraphImageName := 'Graph' + ImageNumber + '.bmp';
                       SaveImage(GraphImageName);
                    end;

            end; {case}
           end;
        end;

   until exitGraph;
End;


 {************************Main Program********************************}
 (********************************************************************)

begin
  Gd := detect; gm := getMaxMode; Initgraph(gd,gm,''); initMouse;
  MaxX :=GetMaxX; MaxY := GetMaxY;


  repeat

  if not Quit then

  Begin

    FileName := ChooseFile(quit);
    If Not Quit Then
    Begin
      done:=false;
      assign(SourceFile, FileName);
      reset(SourceFile);
      i:=1;                             {initializing "i" is necessary for independent count of total number of lines in file}

      While not EoF(SourceFile) Do
        Begin
          readln(SourceFile, Line);     {"Line" is re-written with each iteration of "while" loop}
          If Line <> '' Then

            Begin

                LineStringArray:= SplitString(Line, Separator);
                Case i of
                  1     :  Begin
                              setLength(LogParticulars, Length(LineStringArray));             {date/time stamp, component ID etc}
                              for k:= Low(LineStringArray) To High(LineStringArray) Do
                              LogParticulars[k]:=DeQuote(LineStringArray[k]);
                              delete(LogParticulars[2],1,1);
                              Delete(LogParticulars[2],21, (Length(LogParticulars[2])-20));
                           End;

                  2     :
                            Begin
                              SetLength(Units, Length(LineStringArray));                       {reading measuring units }
                              For k:=Low(LineStringArray) To High(LineStringArray) Do
                              Units[k] := Dequote(LineStringArray[k]);
                            End;

                  3     :                                                     {3rd Line in PRQ Logs contain names of engine parameters}
                           Begin
                             SetLength(ChannName, Length(LineStringArray));
                             For k:=Low(LineStringArray) To High(LineStringArray) Do
                             ChannName[k] := Dequote(LineStringArray[k]);
                           End
                  else
                           Begin
                             SetLength(channels, Length(ChannName), (i-3));              //we are transposing Log File
                             For J:=Low(LineStringArray) to High(LineStringArray) Do     //so that we can address individual
                             Val(LineStringArray[j], channels[j,(i-4)]);                 //channel by "i" as in channels[i]
                           End;                                                          //ChannName will be parallel array
                  end;

                i := i+1;
            end;

        end;    (*End of Reading from File*)

        LogLength := i-5;                                     {PRQ LogFiles, first 3 and last line are non-numeric}
        LastLine  := i-1;

       MaxX := GetMaxX; MaxY := GetMaxY;
       SetLength(choices, Length(ChannName));
       SetLength(Options, Length(ChannName));
       BottomBorder := 160;
       PlotArray := Scale(Channels, MaxX, MaxY, 20, BottomBorder, 20, 20);        //PlotArray is ready-to-plot array of integers
                                                                                  //scaled to plot area, args are scr size and borders
       repeat
         done:=false;
         choices := ChooseChannels(ChannName, Options, done);
         if not done then plot(PlotArray, choices, options);
       until done;

    end;
   end;
  until Quit;

  close(SourceFile);
  closeGraph;

end.



