program test008;
uses
  Variants;
var
  ExcelWorkbook: OleVariant;
begin
  ExcelWorkbook.SaveAs(FileName:='test',AccessMode:=3,ConflictResolution:=2);
end.
