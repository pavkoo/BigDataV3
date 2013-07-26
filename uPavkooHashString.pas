unit uPavkooHashString;

interface
  uses
    SysUtils,Classes;
    
  type
    PHashItem=^THashItem;
    THashItem=record
      Next: PHashItem;
      Key:Int64;
    end;

    TPStringHash = class
    private
      function Compare(Head:PHashItem):Boolean;
    protected
      function HashOf(const Key: string): Cardinal; virtual;
      function ConvertStrToInt64(const Key:String):Int64;
    public
      Buckets: array of PHashItem;
      DuplicateList:TList;
      constructor Create(Size: Cardinal = 256);
      destructor Destroy; override;
      function Find(const Key: string): PHashItem;
      function Add(const Key: string):Boolean;
      procedure Clear;
    end;


implementation

{ TPStringHash }


//----------------------------
//
//  Result := 0;
//  while count > 0 do
//  begin
//    Result := (Result * 131) + PByte(buf)^;
//    Inc(PByte(buf));
//    Dec(count);
//  end;
function BKDRHash(buf: Pointer; count: Integer) : Cardinal; assembler;
asm
        PUSH  EBX;
        XOR   EBX, EBX
        MOV   ECX, EAX
        XOR   EAX, EAX
@LOOP:
        TEST  EDX, EDX
        JZ    @EXIT
        MOV   BL,  [ECX]
        IMUL  EAX, 131
        ADD   EAX, EBX
        INC   ECX
        DEC   EDX
        JMP   @LOOP
@EXIT:
        POP   EBX
end;


function DJBHash(buf: Pointer; count: Integer) : Cardinal; assembler;
asm
        PUSH  EDI
        PUSH  EBX
        XOR   EBX, EBX
        MOV   ECX, EAX
        MOV   EAX, 5381
@LOOP:
        TEST  EDX, EDX
        JZ    @EXIT
        MOV   EDI, EAX
        SHL   EDI, 5
        ADD   EAX, EDI
        MOV   BL, [ECX]
        ADD   EAX, EBX
        INC   ECX
        DEC   EDX
        JMP   @LOOP
@EXIT:
        POP   EBX
        POP   EDI
//----------------------------
// Pascal:
//
//  Result := 5381;
//  while count > 0 do
//  begin
//    Result := ((Result shl 5) + Result) + PByte(buf)^;
//    Inc(PByte(buf));
//    Dec(count);
//  end;
end;


function Adler32Pas(Adler: cardinal; p: pointer; Count: Integer): cardinal;
var s1, s2: cardinal;
    i, n: integer;
begin
  s1 := LongRec(Adler).Lo;
  s2 := LongRec(Adler).Hi;
  while Count>0 do begin
    if Count<5552 then
      n := Count else
      n := 5552;
    for i := 1 to n do begin
      inc(s1,pByte(p)^);
      inc(cardinal(p));
      inc(s2,s1);
    end;
    s1 := s1 mod 65521;
    s2 := s2 mod 65521;
    dec(Count,n);
  end;
  result := word(s1)+cardinal(word(s2)) shl 16;
end;


function GetHashCode(Str: String): Integer;
var
  Off, Len, Skip, I: Integer;
begin
  Result := 0;
  Off := 1;
  Len := Length(Str);
  if Len < 16 then
    for I := (Len - 1) downto 0 do
    begin
      Result := (Result * 37) + Ord(Str[Off]);
      Inc(Off);
    end
  else
  begin
    { Only sample some characters }
    Skip := Len div 8;
    I := Len - 1;
    while I >= 0 do
    begin
      Result := (Result * 39) + Ord(Str[Off]);
      Dec(I, Skip);
      Inc(Off, Skip);
    end;
  end; 
end;


//function TPStringHash.md5(const orl: String): String;
//var
//  MyMD5: TIdHashMessageDigest5;
//  Digest: T4x4LongWordRecord;
//begin
//  MyMD5 := TIdHashMessageDigest5.Create;
//  Digest := MyMD5.HashValue(orl);
//  Result := MyMD5.AsHex(Digest);  //显示32个字符长度的MD5签名结果
//end;


function TPStringHash.Add(const Key: string): Boolean;
var
  Hash: Integer;
  Bucket: PHashItem;
begin
  Result:=True;
  Hash := HashOf(Key) mod Cardinal(Length(Buckets));
  New(Bucket);
  Bucket^.Key := ConvertStrToInt64(Key);
  Bucket^.Next := Buckets[Hash];
  if Buckets[Hash]=nil then
    Buckets[Hash] := Bucket
  else
  begin
    //在这个链接中来超找是否有重复
    //对于相同的key，其Hash值一定相同，所以重复的值，肯定存在于链表中
    Result := not Compare(Bucket);
    if Result then
      Buckets[Hash] := Bucket;
  end;
end;

procedure TPStringHash.Clear;
var
  I: Integer;
  P, N: PHashItem;
begin
  for I := 0 to Length(Buckets) - 1 do
  begin
    P := Buckets[I];
    while P <> nil do
    begin
      N := P^.Next;
      Dispose(P);
      P := N;
    end;
    Buckets[I] := nil;
  end;
end;

//看现在的这个值和其他是否有重复
function TPStringHash.Compare(Head: PHashItem):Boolean;
var
  p:PHashItem;
begin
  Result:=False;
  p:=Head.Next;
  while (p<>nil) do
  begin
    if p.Key=Head.Key then
    begin
      DuplicateList.Add(Pointer(p.Key));
      Result:=True;
      Exit;
    end;
    p:=p.Next;
  end;
end;

const
  values: array [Boolean] of integer=(0,1);

function TPStringHash.ConvertStrToInt64(const Key: String): Int64;
var
  i:integer;
begin
  Result:=0;
  for i := 0 to Length(Key)-1 do
  begin
    Result:= Result shl 1 + (values[Key[i]='A']);
  end;  
end;

constructor TPStringHash.Create(Size: Cardinal);
begin
  inherited Create;
  SetLength(Buckets, Size);
  DuplicateList := TList.Create;
end;

destructor TPStringHash.Destroy;
begin
  Clear;
  DuplicateList.Free;
  inherited;
end;

function TPStringHash.Find(const Key: string): PHashItem;
var
  Hash: Integer;
  KeyInt64:Int64;
begin
  Hash := HashOf(Key) mod Cardinal(Length(Buckets));
  Result := Buckets[Hash];
  KeyInt64:=ConvertStrToInt64(Key);
  while Result <> nil do
  begin
    if Result.Key = KeyInt64 then
      Exit
    else
      Result := Result.Next;
  end;
end;

function TPStringHash.HashOf(const Key: string): Cardinal;
begin
  Result:=BKDRHash(PChar(Key),40);
end;


end.
