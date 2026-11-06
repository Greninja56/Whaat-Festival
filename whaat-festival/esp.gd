extends Node

const PORT := "COM4"   # your port from step 1

func send(cmd: String) -> void:
	var ps := "$p = New-Object System.IO.Ports.SerialPort '%s',115200; $p.DtrEnable=$false; $p.RtsEnable=$false; $p.Open(); $p.WriteLine('%s'); Start-Sleep -Milliseconds 200; $p.Close()" % [PORT, cmd]
	OS.create_process("powershell", ["-NoProfile", "-WindowStyle", "Hidden", "-Command", ps])
