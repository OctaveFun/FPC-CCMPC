UNIT GraphSave;
  {$MODE ObjFPC}

                                                         Interface

uses
 Graph, fpimage, fpwritebmp, fpwritepng, fpwritejpeg;

Procedure SaveImage(AFileName : String);


                                                          Implementation

function BGIToFPColor(AColor:word): TFPColor;
  var
    c: word;
  Begin
    c:= 168 shl 8;
    case AColor of
      0: Result :=colBlack;
      1: Result :=FPColor(0,0,c);
      2: Result :=FPColor(0,c,0);
      3: Result := FPColor(0,c,c);
      4: Result := FPColor(c,0,0);
      5: Result := FPColor(c,0,c);
      6: Result := FPColor(c,c,0);
      7: Result := colLtGray;
      8: Result := colDkGray;
      9: Result := colBlue;
      10: Result := colGreen;
      11: Result:= colCyan;
      12: Result:= colRed;
      13: Result:= colMagenta;
      14: Result:= colYellow;
      15: Result:= colWhite
      else Result := colBlack;
  end
End;

Procedure SaveImage(AFileName : String);
  var
    buf : Pointer = nil;
    P   : PByte;
    xwidth,yheight : integer;
    bufSize : Integer;
    img     : TFPMemoryImage;

    imgWriter: TFPCustomImageWriter;
    x, y : Integer;
    bgiCol : word;

  Begin
    xwidth :=GetMaxX;
    yheight :=GetMaxY;
    img := TFPMemoryImage.Create(xwidth+1, yheight+1);
    try
      imgWriter := img.FindWriterFromFileName(AFileName).Create;
      try
        bufSize := ImageSize(0,0,xwidth, yheight);
        try
          GetMem(buf, bufSize);
          GetImage(0,0,(xwidth),(yheight), buf^);
          P:= buf + 12;
          For y:=0 to (yheight) do
            Begin
              For x:=0 to (xwidth) do
              Begin
                bgiCol := PWord(P)^;
                img.Colors[x,y] :=BgiToFPColor(bgiCol);
                inc(P, SizeOf(word));
              end;
            end;
            img.SaveToFile(AFileName, imgWriter);
        finally
          FreeMem(buf);
        end;
      finally
        imgWriter.Free;
      end;
    finally
      img.Free;
    end;
  End;

 (* var
    GraphDriver, GraphMode : SmallInt;
    nx, ny : Integer;
    x1, y1, x2, y2, w, h : Integer;
    i: Integer;

    Begin

    GraphDriver := VGA;
    GraphMode := VGAHi;
    InitGraph(GraphDriver, GraphMode, '');
    nx :=GetMaxX+1;
    ny :=GetMaxY+1;
    for i:=0 to 100 do
    begin
      SetFillStyle(SolidFill, random(16));
      x1 := random(nx);
      y1 := random(ny);
      w := Random(nx div 4);
      h := random(ny div 4);
      if x1 + w < nx then x2 := x1 +w else x2 := x1 -w;
      if y1 + h < ny then y2 := y1 +h else y2 := y1 -h;
      Bar(x1,y1,x2,y2);
    end;
    SaveImage('GraphImage.bmp');
    SaveImage('testYtest.png');
    SaveImage('testXtest.jpg');
    Readln;
    CloseGraph;*)

  end.
