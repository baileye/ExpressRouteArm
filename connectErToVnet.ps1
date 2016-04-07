# Sections below are grouped by what they do -- parameters for each section are defined as needed
#   hopefully making it a little easier should you only need some of these steps

# Login to Azure Account
Login-AzureRmAccount


# Select correct subscription
$subId = "<your sub id>"
Get-AzureRmSubscription –SubscriptionId $subId | Select-AzureRmSubscription


# Check the circuit is enabled and provisioned
Get-AzureRmExpressRouteCircuit


# Resource Group (assumed created already, if not run commented command two lines below)
$rg = "ExpressRouteResourceGroup"
$rglocation = "North Europe"
# New-AzureRmResourceGroup -Name $rg -Location $rglocation


# Create VNet that will be connected to the ExpressRoute Circuit
$vNetName = "ExpressRouteVNet"
# This subnet mist be called 'GatewatSubnet' -- it is identified as such for use by the Gateway connection to ExpressRoute
$subnet1 = New-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix 10.0.0.0/28
$subnet2 = New-AzureRmVirtualNetworkSubnetConfig -Name 'Subnet1' -AddressPrefix '10.0.1.0/20'
New-AzureRmVirtualNetwork -Name $vNetName -ResourceGroupName $rg -Location $rglocation -AddressPrefix 10.0.0.0/16 -Subnet $subnet1, $subnet2

# Create ExpressRoute Gateway
# Assumes existing Vnet and GatewaySubnet
$GWPublicIPName = "ErGwPip"
$IPConfigName = "Ipconfig"
$GWName = "ERGW"

# Get the VNet that the gateweay will be connected to
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $rg -Name $vNetName
# Public IP address needed for the Gateway
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

# To connect an existing ER circuit to a VNet in another subscription, follow the steps above to create the VNet and subnets in 
#   the second Azure subscription (ensure the VNet location is the same as the ER location)

# Login to the subscription that owns the ER circuit to get an authorization key
$CircuitName = "ExpressRouteARMCircuit"
$rg = "ExpressRouteResourceGroup"
$rglocation = "North Europe"
$circuit = Get-AzureRmExpressRouteCircuit -Name $CircuitName -ResourceGroupName $rg
Add-AzureRmExpressRouteCircuitAuthorization -ExpressRouteCircuit $circuit -Name "MyAuthorization1"
Set-AzureRmExpressRouteCircuit -ExpressRouteCircuit $circuit

$auth1 = Get-AzureRmExpressRouteCircuitAuthorization -ExpressRouteCircuit $circuit -Name "MyAuthorization1"
$authkey = $auth1.AuthorizationKey
$peerId = $circuit.Id
# Keep a note of the 'AuthorizationKey' returned as part of the response to the above command

### CREATE the VNet and VNet gateway in the second subscription in the same manner as above, roughly from lines 23 up
###   up until the VNet Gateway is created

# In the second Azure subscription, execute the following commands to connect the VNet to the ER circuit
### TODO: Check the syntax for the ID, and can the $circuit.Id value be used above in its place?
$id = "/subscriptions/********************************/resourceGroups/ERCrossSubTestRG/providers/Microsoft.Network/expressRouteCircuits/MyCircuit"  
$connection = New-AzureRmVirtualNetworkGatewayConnection -Name "ERConnection" -ResourceGroupName $rg -Location $rglocation -VirtualNetworkGateway1 $gw -PeerId $peerId -ConnectionType ExpressRoute -AuthorizationKey $authkey

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




