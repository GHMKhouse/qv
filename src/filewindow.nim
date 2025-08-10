import winim/mean
proc openFileDialog*(hwnd: HWND = 0): string =
  var
    ofn: OPENFILENAMEW
    fileNameBuffer: array[MAX_PATH, TCHAR]
    
  ZeroMemory(addr ofn, sizeof(ofn))
  ofn.lStructSize = sizeof(OPENFILENAME).DWORD
  ofn.hwndOwner = hwnd
  ofn.lpstrFile = cast[LPTSTR](addr fileNameBuffer)
  ofn.nMaxFile = MAX_PATH.DWORD
  ofn.lpstrFilter = "Ogg Files\0*.OGG\0"
  ofn.nFilterIndex = 1
  ofn.lpstrFileTitle = nil
  ofn.nMaxFileTitle = 0
  ofn.lpstrInitialDir = nil
  ofn.Flags = OFN_PATHMUSTEXIST or OFN_FILEMUSTEXIST or OFN_EXPLORER

  if GetOpenFileName(addr ofn) != 0:
    result = $cast[LPTSTR](addr fileNameBuffer)
  else:
    result = ""