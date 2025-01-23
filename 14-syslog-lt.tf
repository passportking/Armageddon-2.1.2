# Syslog Server Launch Template
resource "aws_launch_template" "tokyo_syslog_lt" {
  name_prefix   = "tokyo-syslog-lt"
  image_id      = data.aws_ami.tokyo-syslog-ami.id
  instance_type =  var.instance_type1 # Adjust size as needed
  provider      = aws.tokyo-syslog

  vpc_security_group_ids = [aws_security_group.tokyo_syslog_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y rsyslog
    # Configure rsyslog for high availability
    cat <<'CONF' > /etc/rsyslog.conf
    # Basic configuration
    module(load="imudp")
    input(type="imudp" port="514")
    module(load="imtcp")
    input(type="imtcp" port="514")
    
    # Log storage configuration
    template(name="RemoteLog" type="string" string="/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log")

**.**

?RemoteLog
    CONF
    
    systemctl restart rsyslog
  EOF
  )

  tags = {
    Name    = "tokyo-syslog-server"
    Service = "Armageddon Phase 1"
    Owner   = "MATTRESS AVENGERS"
  }
}

# Syslog Server Security Group
resource "aws_security_group" "tokyo_syslog_sg" {
  name        = "tokyo-syslog-sg"
  description = "Security group for Syslog server"
  vpc_id      = aws_vpc.tokyo-syslog-vpc.id
  provider    = aws.tokyo-syslog

  ingress {
    description = "Syslog UDP"
    from_port   = 514
    to_port     = 514
    protocol    = "udp"
    cidr_blocks = [
      var.vpc_cidr_block_tokyo,
      var.vpc_cidr_block_newyork,
      var.vpc_cidr_block_london,
      var.vpc_cidr_block_saopaulo,
      var.vpc_cidr_block_australia,
      var.vpc_cidr_block_hongkong,
      var.vpc_cidr_block_california
    ]
  }

  ingress {
    description = "Syslog TCP"
    from_port   = 514
    to_port     = 514
    protocol    = "tcp"
    cidr_blocks = [
      var.vpc_cidr_block_tokyo,
      var.vpc_cidr_block_newyork,
      var.vpc_cidr_block_london,
      var.vpc_cidr_block_saopaulo,
      var.vpc_cidr_block_australia,
      var.vpc_cidr_block_hongkong,
      var.vpc_cidr_block_california
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "tokyo-syslog-sg"
    Service = "Armageddon Phase 1"
    Owner   = "MATTRESS AVENGERS"
  }
}

# Syslog Server Auto Scaling Group
resource "aws_autoscaling_group" "tokyo_syslog_asg" {
  name_prefix         = "tokyo-syslog-asg-"
  desired_capacity    = 2
  max_size           = 4
  min_size           = 2
  target_group_arns  = [aws_lb_target_group.tokyo_syslog_tg.arn]
  vpc_zone_identifier = [aws_subnet.tokyo-syslog-private-subnet-1c.id]  # Different AZ from DB
 
  provider           = aws.tokyo-syslog

  launch_template {
    id      = aws_launch_template.tokyo_syslog_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "tokyo-syslog-server"
    propagate_at_launch = true
  }
}

///////////////////////////////////////////////////////////////

//Tokyo Syslog Private Route Table
resource "aws_route_table" "tokyo-syslog-private" {
  vpc_id = aws_vpc.tokyo-syslog-vpc.id
  provider = aws.tokyo-syslog

  
route {
  cidr_block = "172.0.0.0/8"
  transit_gateway_id  = aws_ec2_transit_gateway.tokyo_tgw.id
  }


  

  tags = {
    Name: "${var.env_prefix_tokyo-syslog}-private-rtb"
  }
}

resource "aws_route_table_association" "tokyo-syslog-private-c" {
  provider = aws.tokyo-syslog
  subnet_id      = aws_subnet.tokyo-syslog-private-subnet-1c.id
  route_table_id = aws_route_table.tokyo-syslog-private.id
}