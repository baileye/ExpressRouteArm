# Login to Azure Account
Login-AzureRmAccount

# Select correct subscription
$subId = "<your sub id>"
Get-AzureRmSubscription –SubscriptionId $subId | Select-AzureRmSubscription

# Check the circuit is enabled and provisioned
Get-AzureRmExpressRouteCircuit

# Create ExpressRoute Gateway
# Assumes existing Vnet and GatewaySubnet
$rg = "ExpressRouteResourceGroup"
$rglocation = "North Europe"
$GWPublicIPName = "ErGwPip"
$IPConfigName = "Ipconfig"
$GWName = "ERGW"

$vNetName = "ExpressRouteVNet"
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rg -Name $vNetName
$pip = New-AzureRmPublicIpAddress -Name $GWPublicIPName -ResourceGroupName $rg -Location $rglocation -AllocationMethod Dynamic

# Check this is the GatewaySubnet Id
$subnet = $vnet.Subnets[1].Id
$ipconfig = New-AzureRmVirtualNetworkGatewayIpConfig -Name $IPConfigName -PublicIpAddressId $pip.Id -SubnetId $subnet
New-AzureRmVirtualNetworkGateway -Name $GWName -ResourceGroupName $rg -Location $rglocation -GatewayType ExpressRoute -VpnType RouteBased -IpConfigurations $ipconfig  

# Link the Gateway and the ER Circuit
$ERConnectionName = "ERConnection"
$CircuitName = "ExpressRouteARMCircuit"
$ckt = Get-AzureRmExpressRouteCircuit -Name $CircuitName -ResourceGroupName $rg

$gw = Get-AzureRmVirtualNetworkGateway -Name $GWName -ResourceGroupName $rg
$conn = New-AzureRmVirtualNetworkGatewayConnection -Name $ERConnectionName -ResourceGroupName $rg -Location $rglocation -VirtualNetworkGateway1 $gw -PeerId $ckt.Id -ConnectionType ExpressRoute 

############################################################
############################################################

# Depending on the ExpressRoute provider, you may need to set up Azure Peering on the circuit.
# Check with the ExpressRoute provider to confirm if these steps are neccessry.
# If they are, set up peering before creating the Gateway above.

# Setting up Peering
$CircuitPeeringName = "AzurePrivatePeering"
$ASN = 100
$PrimaryPrefix = "10.6.1.0/30"
$SecondaryPrefix = "10.6.2.0/30"
$vLan = 200

$ckt = Get-AzureRmExpressRouteCircuit -Name $CircuitName -ResourceGroupName $rg
Add-AzureRmExpressRouteCircuitPeeringConfig -Name $CircuitPeeringName -Circuit $ckt -PeeringType AzurePrivatePeering -PeerASN $ASN -PrimaryPeerAddressPrefix $PrimaryPrefix -SecondaryPeerAddressPrefix $SecondaryPrefix -VlanId $vLan
Set-AzureRmExpressRouteCircuit -ExpressRouteCircuit $ckt 

# Checking Peering
$ckt = Get-AzureRmExpressRouteCircuit -Name "ExpressRouteARMCircuit" -ResourceGroupName "ExpressRouteResourceGroup"
Get-AzureRmExpressRouteCircuitPeeringConfig -Name "AzurePrivatePeering" -Circuit $ckt
