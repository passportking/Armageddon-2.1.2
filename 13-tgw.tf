#############################################
# Transit Gateway Setup for Tokyo and New York
#############################################

# Create the Tokyo Transit Gateway
resource "aws_ec2_transit_gateway" "tokyo_tgw" {
  provider = aws.tokyo
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  description = "Transit Gateway in Tokyo (Hub)"
  tags = {
    Name = "tokyo-tgw"
  }
}

# Create a route table for the Tokyo TGW
resource "aws_ec2_transit_gateway_route_table" "tokyo_tgw_rt" {
  provider          = aws.tokyo
  transit_gateway_id = aws_ec2_transit_gateway.tokyo_tgw.id
  tags = {
    Name = "tokyo-tgw-rt"
  }
}

# Attach Tokyo VPC to Tokyo TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "tokyo_tgw_attachment" {
  provider = aws.tokyo
  transit_gateway_id = aws_ec2_transit_gateway.tokyo_tgw.id
  vpc_id            = aws_vpc.tokyo-vpc.id
  subnet_ids        = [aws_subnet.tokyo-private-subnet-1a.id, aws_subnet.tokyo-private-subnet-1d.id]
  
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "tokyo-tgw-attachment"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#############################################
# New York Transit Gateway
#############################################

# Create the New York Transit Gateway
resource "aws_ec2_transit_gateway" "newyork_tgw" {
  provider = aws.new-york
  description = "Transit Gateway in New York (Spoke)"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags = {
    Name = "newyork-tgw"
  }
}

# Create a route table for the New York TGW
resource "aws_ec2_transit_gateway_route_table" "newyork_tgw_rt" {
  provider          = aws.new-york
  transit_gateway_id = aws_ec2_transit_gateway.newyork_tgw.id
  tags = {
    Name = "newyork-tgw-rt"
  }
}

# Attach New York VPC to New York TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "newyork_tgw_attachment" {
  provider            = aws.new-york
  transit_gateway_id  = aws_ec2_transit_gateway.newyork_tgw.id
  vpc_id              = aws_vpc.newyork-vpc.id
  subnet_ids          = [aws_subnet.newyork-private-subnet-1a.id, aws_subnet.newyork-private-subnet-1b.id]

  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "newyork-tgw-attachment"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#############################################
# Add data sources for attachments
#############################################

/*data "aws_ec2_transit_gateway_vpc_attachment" "tokyo_attachment" {
  provider = aws.tokyo
  id = aws_ec2_transit_gateway_vpc_attachment.tokyo_tgw_attachment.id
}

data "aws_ec2_transit_gateway_vpc_attachment" "newyork_attachment" {
  provider = aws.new-york
  id = aws_ec2_transit_gateway_vpc_attachment.newyork_tgw_attachment.id

}
*/


#############################################
# Route Table Associations
#############################################

resource "aws_ec2_transit_gateway_route_table_association" "tokyo_tgw_assoc" {
  provider                        = aws.tokyo
  transit_gateway_attachment_id   = aws_ec2_transit_gateway_vpc_attachment.tokyo_tgw_attachment.id
  transit_gateway_route_table_id  = aws_ec2_transit_gateway_route_table.tokyo_tgw_rt.id

  
  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.tokyo_tgw_attachment
  ]
}

resource "aws_ec2_transit_gateway_route_table_association" "tokyo_tgw_peering_assoc" {
  provider                        = aws.tokyo
  transit_gateway_attachment_id   = data.aws_ec2_transit_gateway_peering_attachment.tokyo_to_newyork_peering.id
  transit_gateway_route_table_id  = aws_ec2_transit_gateway_route_table.tokyo_tgw_rt.id

  
  depends_on = [
   aws_ec2_transit_gateway_peering_attachment.newyork_to_tokyo_peering, 
   aws_ec2_transit_gateway_peering_attachment_accepter.tokyo_accepts_newyork_peering
  ]
}

resource "aws_ec2_transit_gateway_route_table_association" "tokyo_syslog_tgw_assoc" {
  provider                        = aws.tokyo
  transit_gateway_attachment_id   = aws_ec2_transit_gateway_vpc_attachment.tokyo-syslog_tgw_attachment.id
  transit_gateway_route_table_id  = aws_ec2_transit_gateway_route_table.tokyo_tgw_rt.id

  
  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.tokyo-syslog_tgw_attachment
  ]
}

resource "aws_ec2_transit_gateway_route_table_association" "newyork_tgw_assoc" {
  provider                        = aws.new-york
  transit_gateway_attachment_id   = aws_ec2_transit_gateway_vpc_attachment.newyork_tgw_attachment.id
  transit_gateway_route_table_id  = aws_ec2_transit_gateway_route_table.newyork_tgw_rt.id


  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.newyork_tgw_attachment
  ]
}

resource "aws_ec2_transit_gateway_route_table_association" "newyork_tgw_peering_assoc" {
  provider                        = aws.new-york
  transit_gateway_attachment_id   = aws_ec2_transit_gateway_peering_attachment.newyork_to_tokyo_peering.id
  transit_gateway_route_table_id  = aws_ec2_transit_gateway_route_table.newyork_tgw_rt.id


  depends_on = [
    aws_ec2_transit_gateway_peering_attachment.newyork_to_tokyo_peering, 
   aws_ec2_transit_gateway_peering_attachment_accepter.tokyo_accepts_newyork_peering
  ]
}

#############################################
# TGW Peering Between Tokyo and New York
#############################################

# Create a peering attachment from New York TGW to Tokyo TGW
resource "aws_ec2_transit_gateway_peering_attachment" "newyork_to_tokyo_peering" {
  provider                = aws.new-york
  transit_gateway_id      = aws_ec2_transit_gateway.newyork_tgw.id
  peer_transit_gateway_id = aws_ec2_transit_gateway.tokyo_tgw.id
  peer_region            = "ap-northeast-1"

  tags = {
    Name = "newyork-to-tokyo-peering"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Accept the peering in Tokyo
resource "aws_ec2_transit_gateway_peering_attachment_accepter" "tokyo_accepts_newyork_peering" {
  provider                    = aws.tokyo
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.newyork_to_tokyo_peering.id

  tags = {
    Name = "tokyo-accepts-newyork"
  }
}

data "aws_ec2_transit_gateway_peering_attachment" "tokyo_to_newyork_peering" {
  provider   = aws.tokyo
  depends_on = [aws_ec2_transit_gateway_peering_attachment.newyork_to_tokyo_peering,
   aws_ec2_transit_gateway_peering_attachment_accepter.tokyo_accepts_newyork_peering]
  filter {
    name   = "transit-gateway-id"
    values = [aws_ec2_transit_gateway.tokyo_tgw.id]
  }

  filter {
    name   = "state"
    values = ["pendingAcceptance", "available"]
  }
}

#############################################
# TGW Routes for Inter-Region Communication
#############################################

# In Tokyo's TGW route table, add a route to New York's CIDR via the peering attachment
resource "aws_ec2_transit_gateway_route" "tokyo_to_newyork_route" {
  provider                       = aws.tokyo
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tokyo_tgw_rt.id
  destination_cidr_block        = "172.19.0.0/16" # New York VPC CIDR
  transit_gateway_attachment_id = data.aws_ec2_transit_gateway_peering_attachment.tokyo_to_newyork_peering.id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.tokyo_accepts_newyork_peering
  ]
}

resource "aws_ec2_transit_gateway_route" "tgw-to-tokyo-syslog_route" {
  provider                       = aws.tokyo
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tokyo_tgw_rt.id
  destination_cidr_block        = "172.27.0.0/16" # Tokyo Syslog VPC CIDR
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.tokyo-syslog_tgw_attachment.id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.tokyo-syslog_tgw_attachment
  ]
}

resource "aws_ec2_transit_gateway_route" "tgw-to-tokyo_route" {
  provider                       = aws.tokyo
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tokyo_tgw_rt.id
  destination_cidr_block        = "172.18.0.0/16" # Tokyo VPC CIDR
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.tokyo_tgw_attachment.id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.tokyo_accepts_newyork_peering
  ]
}

# In New York's TGW route table, add a route to Tokyo's CIDR via the peering attachment
resource "aws_ec2_transit_gateway_route" "newyork_to_tokyo_route" {
  provider                       = aws.new-york
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.newyork_tgw_rt.id
  destination_cidr_block        = "172.0.0.0/8" # Tokyo VPC CIDR
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.newyork_to_tokyo_peering.id

  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.tokyo_accepts_newyork_peering
  ]
}

resource "aws_ec2_transit_gateway_route" "tgw-to-newyork_route" {
  provider                       = aws.new-york
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.newyork_tgw_rt.id
  destination_cidr_block        = "172.19.0.0/16" # New York VPC CIDR
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.newyork_tgw_attachment.id

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.newyork_tgw_attachment
  ]
}
#############################################
# VPC Route Table Updates
#############################################

# Add route in Tokyo private route table to New York CIDR
/*resource "aws_route" "tokyo_vpc_to_newyork_route" {
  provider              = aws.tokyo
  route_table_id        = aws_route_table.tokyo-private.id
  destination_cidr_block = "172.19.0.0/16"  # New York CIDR
  transit_gateway_id    = aws_ec2_transit_gateway.tokyo_tgw.id
}

*/

////////////////////////////////////////////////////////////////////////
# Add specific route for Syslog traffic in Tokyo TGW route table


////////////////////////////////////////////////////////////////////////

# Create the Tokyo Syslog Transit Gateway
/*resource "aws_ec2_transit_gateway" "tokyo-syslog_tgw" {
  provider = aws.tokyo-syslog
  description = "Transit Gateway in Tokyo (Hub)"
  tags = {
    Name = "tokyo-tgw"
  }
}

# Create a route table for the Tokyo Syslog TGW
resource "aws_ec2_transit_gateway_route_table" "tokyo-syslog_tgw_rt" {
  provider          = aws.tokyo-syslog
  transit_gateway_id = aws_ec2_transit_gateway.tokyo-syslog_tgw.id
  tags = {
    Name = "tokyo-syslog-tgw-rt"
  }
}*/

# Attach Tokyo VPC to Tokyo TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "tokyo-syslog_tgw_attachment" {
  provider = aws.tokyo-syslog
  transit_gateway_id = aws_ec2_transit_gateway.tokyo_tgw.id
  vpc_id            = aws_vpc.tokyo-syslog-vpc.id
  subnet_ids        = [aws_subnet.tokyo-syslog-private-subnet-1c.id]
  
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = {
    Name = "tokyo-syslog-tgw-attachment"
  }

  lifecycle {
    create_before_destroy = true
  }
}