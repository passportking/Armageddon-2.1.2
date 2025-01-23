# resource "aws_rds_cluster" "database1" {
#   cluster_identifier      = "aurora-cluster-demo"
#   engine                  = "aurora-mysql"
#   engine_version          = "5.7.mysql_aurora.2.03.2"
#   availability_zones      = ["us-west-2a", "us-west-2b", "us-west-2c"]
#   database_name           = "mydb"
#   master_username         = "foo"
#   master_password         = "must_be_eight_characters"
#   backup_retention_period = 5
#   preferred_backup_window = "07:00-09:00"
# }

////////////////////////////////////////////////////////////////////////////////

#RDS Cluster

resource "aws_rds_cluster" "database1" {
  cluster_identifier        = "aurora-cluster"
  availability_zones        = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  engine                    = "mysql"
  db_cluster_instance_class = "db.r6gd.xlarge"
  storage_type              = "io1"
  allocated_storage         = 100
  iops                      = 1000
  master_username           = "test"
  master_password           = "123456789"
  vpc_security_group_ids    = [aws_security_group.tokyo_Aurora_DB01_sg.id]
  db_subnet_group_name      = aws_db_subnet_group.tokyo_aurora_database_sg.name
}