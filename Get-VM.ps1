# 查看绑定了“Default Switch”的虚拟机及其状态
Get-VM | ForEach-Object {
    $vm = $_
    Get-VMNetworkAdapter -VM $vm | Where-Object { $_.SwitchName -eq "Default Switch" } | 
    Select-Object @{Name="虚拟机名称"; Expression={$vm.Name}}, 
                  @{Name="虚拟机状态"; Expression={$vm.State}}, 
                  SwitchName
}