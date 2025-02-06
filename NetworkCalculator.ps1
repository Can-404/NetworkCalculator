Add-Type -AssemblyName System.Windows.Forms

# Set-ExecutionPolicy Bypass -Scope Process -Force
# Install-Module ps2exe -Scope CurrentUser
# Invoke-PS2EXE "C:\Users\Admin\Desktop\Data\VS-Code\NetworkCalculator\NetworkCalculator.ps1" "C:\Users\Admin\Desktop\Data\VS-Code\NetworkCalculator\NetworkCalculator.exe" -icon "C:\Users\Admin\Desktop\Data\VS-Code\NetworkCalculator\Icon256x256.ico"

function Get-SubnetInfo {
    param (
        [string]$ipAddress,
        [string]$subnetMask
    )

    # Subnetzmaske in einzelne Oktette aufteilen
    $octets = $subnetMask.Split('.')

    # Jedes Oktett in eine Binärzahl umwandeln und auf 8 Stellen auffüllen
    $binaryOctets = @()
    foreach ($octet in $octets) {
        $binaryOctets += [Convert]::ToString([int]$octet, 2).PadLeft(8, '0')
    }

    # Die binäre Darstellung der gesamten Subnetzmaske zusammenfügen
    $subnetMaskBinary = -join $binaryOctets

    # Anzahl der Einsen in der Subnetzmaske zählen
    $networkBits = ($subnetMaskBinary -split '1').Count - 1

    # Anzahl der Hostbits berechnen
    $hostBits = 32 - $networkBits

    # Berechnung der Netz-ID (Netzwerkadresse) und Broadcastadresse
    $ip = [System.Net.IPAddress]::Parse($ipAddress).GetAddressBytes()
    $mask = [System.Net.IPAddress]::Parse($subnetMask).GetAddressBytes()

    # Netz-ID und Broadcastadresse berechnen
    $network = [byte[]]::new(4)
    $broadcast = [byte[]]::new(4)
    for ($i = 0; $i -lt 4; $i++) {
        $network[$i] = $ip[$i] -band $mask[$i]
        $broadcast[$i] = $network[$i] -bor (-bnot $mask[$i] -band 0xFF)
    }

    $networkAddress = [System.Net.IPAddress]::new($network).ToString()
    $broadcastAddress = [System.Net.IPAddress]::new($broadcast).ToString()

    # Berechnung der maximalen Hosts
    $hostCount = [math]::Pow(2, $hostBits) - 2

    # Ausgabe der Subnetzmaske, Netz-ID und Broadcastadresse in Binärformat
    $subnetMaskBinaryFormatted = ($octets | ForEach-Object { [convert]::ToString($_, 2).PadLeft(8, '0') }) -join '.'
    $networkBinary = ($network | ForEach-Object { [convert]::ToString($_, 2).PadLeft(8, '0') }) -join '.'
    $broadcastBinary = ($broadcast | ForEach-Object { [convert]::ToString($_, 2).PadLeft(8, '0') }) -join '.'

    return @{
        HostCount         = $hostCount
        NetworkAddress    = $networkAddress
        BroadcastAddress  = $broadcastAddress
        SubnetMaskBinary  = $subnetMaskBinaryFormatted
        NetworkBinary     = $networkBinary
        BroadcastBinary   = $broadcastBinary
    }
}

# GUI Creation
$form = New-Object System.Windows.Forms.Form
$form.Text = "Subnet Host Calculator"
$form.Size = New-Object System.Drawing.Size(450, 350)
$form.StartPosition = "CenterScreen"

# IP Address Label
$labelIP = New-Object System.Windows.Forms.Label
$labelIP.Text = "IP Address:"
$labelIP.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($labelIP)

# IP Address TextBox
$textBoxIP = New-Object System.Windows.Forms.TextBox
$textBoxIP.Location = New-Object System.Drawing.Point(120, 18)
$form.Controls.Add($textBoxIP)

# Subnet Mask Label
$labelSubnet = New-Object System.Windows.Forms.Label
$labelSubnet.Text = "Subnet Mask:"
$labelSubnet.Location = New-Object System.Drawing.Point(10, 50)
$form.Controls.Add($labelSubnet)

# Subnet Mask TextBox
$textBoxSubnet = New-Object System.Windows.Forms.TextBox
$textBoxSubnet.Location = New-Object System.Drawing.Point(120, 48)
$form.Controls.Add($textBoxSubnet)

# Calculate Button
$buttonCalculate = New-Object System.Windows.Forms.Button
$buttonCalculate.Text = "Calculate"
$buttonCalculate.Location = New-Object System.Drawing.Point(120, 80)
$form.Controls.Add($buttonCalculate)

# Result Label
$labelResult = New-Object System.Windows.Forms.Label
$labelResult.Location = New-Object System.Drawing.Point(10, 110)
$labelResult.Size = New-Object System.Drawing.Size(360, 180)
$form.Controls.Add($labelResult)

# Button Click Event
$buttonCalculate.Add_Click({
    $result = Get-SubnetInfo -ipAddress $textBoxIP.Text -subnetMask $textBoxSubnet.Text

    # Output the result including the binary representations
    $labelResult.Text = @"
Host Count: $($result.HostCount)

Network Address: $($result.NetworkAddress)
Network Address (Binary): $($result.NetworkBinary)

Broadcast Address: $($result.BroadcastAddress)
Broadcast Address (Binary): $($result.BroadcastBinary)

Subnet Mask (Binary): $($result.SubnetMaskBinary)
"@
})

# Show the form
$form.ShowDialog()
