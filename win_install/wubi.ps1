# 安装五笔
$fileExists = Test-Path -Path D:\a\actions_os\actions_os\sougouwubi.exe
if ($fileExists) {
   Start-Process -FilePath "D:\a\actions_os\actions_os\sougouwubi.exe" -ArgumentList "/S" -Wait -NoNewWindow
}
