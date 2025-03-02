# 安装拼音
$fileExists = Test-Path -Path D:\a\actions_os\actions_os\sougoupinyin.exe
if ($fileExists) {
   Start-Process -FilePath "D:\a\actions_os\actions_os\sougoupinyin.exe" -ArgumentList "/S" -Wait -NoNewWindow
}
