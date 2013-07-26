unit uPavkooStringList;

interface
  uses
    Classes,Windows;
   type
     TThreadStringList = class
     private
      FList: TStringList;
      FLock: TRTLCriticalSection;
     public
       constructor Create;
       destructor Destroy; override;
       procedure Add(const Item: String);
       procedure Clear;
       function  LockList: TStringList;
       function GetCount:Integer;
       function GetItem(index:Integer):String;
       procedure Remove(const Item: String);
       procedure UnlockList;
     end;

implementation

{ TThreadStringList }

procedure TThreadStringList.Add(const Item: String);
begin
  LockList;
  try
    if (FList.IndexOf(Item) = -1) then
      FList.Add(Item);
  finally
    UnlockList;
  end;
end;

procedure TThreadStringList.Clear;
begin
  LockList;
  try
    FList.Clear;
  finally
    UnlockList;
  end;
end;

constructor TThreadStringList.Create;
begin
  inherited Create;
  InitializeCriticalSection(FLock);
  FList := TStringList.Create;
end;

destructor TThreadStringList.Destroy;
begin
  LockList;    // Make sure nobody else is inside the list.
  try
    FList.Free;
    inherited Destroy;
  finally
    UnlockList;
    DeleteCriticalSection(FLock);
  end;
end;

function TThreadStringList.GetCount: Integer;
begin
  Result:=FList.Count;
end;

function TThreadStringList.GetItem(index: Integer): String;
begin
  Result:=FList.Strings[index];
end;

function TThreadStringList.LockList: TStringList;
begin
  EnterCriticalSection(FLock);
  Result := FList;
end;

procedure TThreadStringList.Remove(const Item: String);
begin
  LockList;
  try
    FList.Delete(FList.IndexOf(Item));
  finally
    UnlockList;
  end;
end;

procedure TThreadStringList.UnlockList;
begin
  LeaveCriticalSection(FLock);
end;

end.
