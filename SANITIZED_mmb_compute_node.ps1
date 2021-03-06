# Scripted configuration of Terravista 6 Compute Node configuration settings
#
# Jeff Bond   -    Sept. 2014

# Define Registry Locations for CN Variables
$regPath = "HKLM:\SOFTWARE\Wow6432Node\Presagis\TerraVista Compute Node\6.1"
$regKeyPass = "MMBUPwd"
$regKeyUser = "MMBUser"
$regKeyDomain = "MMBUDom"
$regPublicKey = "MMBPublicKey"

# Set Compute Node Reg Variables
$mmbUserName = ""
$mmbUserDomain = ""

[byte[]] $publicBlob = New-Object byte[] 128
[byte[]] $encryptedPass = New-Object byte[] 256
[byte[]] $passBuf = 0x00,0x00
[byte[]] $preBlobBuf = 0xb1,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x8c,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x30,0x81,0x89,0x02,0x81,0x81,0x00
[byte[]] $postBlobBuf = 0x02,0x03,0x01,0x00,0x01,0x31,0x2e,0x32,0x2e,0x38,0x34,0x30,0x2e,0x31,0x31,0x33,0x35,0x34,0x39,0x2e,0x31,0x2e,0x31,0x2e,0x31,0x00

# Define CN user password and encode it to bytestream for RSA encoding adding buffer Presagis uses
$enc = [System.Text.Encoding]::UNICODE
$pass = ""
$bytes = $enc.GetBytes($pass)
$bytes += $passBuf

#Define Cryptographic parameters (TV defines keycontainer in MachineStore)
$csp = New-Object System.Security.Cryptography.CspParameters(1)
$csp.KeyContainerName = "presagis_mmb_keyset_0"
$csp.Flags = $csp.Flags -bor [System.Security.Cryptography.CspProviderFlags]::UseMachineKeyStore

# Create RSA Opbject and encrypt the password
$rsa = New-Object System.Security.Cryptography.RSACryptoServiceProvider($csp)

# Export public key blob and change endian
$publicBlobTemp = $rsa.ExportCspBlob($false)
[System.Array]::Reverse($publicBlobTemp)

# Strip key blob of normal header and add Presagis key buffers
[System.Array]::Copy($publicBlobTemp, 0, $publicBlob, 0, 128)
$publicBlob = $preBlobBuf + $publicBlob + $postBlobBuf

# Encrypt Password
$encryptedPass = $rsa.Encrypt($bytes, $false)

# Change endian of encrypted data
[System.Array]::Reverse($encryptedPass)

# Write password byte array to registry location
Set-ItemProperty -Path $regPath -Name $regKeyPass -Value $encryptedPass

# Write public key blob to registry
Set-ItemProperty -Path $regPath -Name $regPublicKey -Value $publicBlob -T Binary

# Write other options to registry
Set-ItemProperty -Path $regPath -Name $regKeyUser -Value $mmbUserName
Set-ItemProperty -Path $regPath -Name $regKeyDomain -Value $mmbUserDomain

Restart-Service -DisplayName "Presagis Network Service Version 3.1"