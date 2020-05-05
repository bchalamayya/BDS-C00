Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
cloud_final_modules:
- [scripts-user, always]

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

# automating some of the tasks in this ACG course:
# https://learn.acloud.guru/course/aws-certified-big-data-specialty
# This part specifically:
# https://acloud.guru/course/aws-certified-big-data-specialty/learn/22f45aa3-407a-62e4-82e0-646e8f262508/1c8cab52-d2d5-8af7-58fc-ff861c9dfc6b/watch

# TODO
# put these in user data or automate some other way
# auto create instance - CF
# don't forget to give instance s3 access
# error handling
# don't delete, better to kill the instance upon successful completion

# output : { all : '| tee -a /var/log/cloud-init-output.log' }

home_dir=/home/ec2-user/
emr_dir=/home/ec2-user/emrdata
tpch_dir=/home/ec2-user/tpch-kit
rdsh_dir=/home/ec2-user/redshiftdata
my_bucket='my-bucket-'$(date --iso-8601)-$(date +%s)

mkdir $home_dir $emr_dir $tpch_dir $rdsh_dir
aws s3api create-bucket --bucket $my_bucket

sudo yum -y update
sudo yum -y install git make gcc
cd $home_dir
git clone https://github.com/gregrahn/tpch-kit
cd $tpch_dir/dbgen
make OS=LINUX
cd $home_dir
export DSS_PATH=$emr_dir
cd $tpch_dir/dbgen
# -v verbose, -T tables, -s data size = 10gb, takes ~5-10m on M5.Large
./dbgen -v -T o -s 10
cd $emr_dir
# confirm lineitem.tbl  orders.tbl exist
# come up with a random name for a bucket
aws s3 cp $emr_dir s3://$my_bucket/emrdata --recursive
# Now make data for redshift
# I think you need to execute below from $tpch_dir/dbgen
export DSS_PATH=$rdsh_dir
cd $tpch_dir/dbgen
./dbgen -v -T o -s 40
cd $rdsh_dir
wc -l orders.tbl
split -d -l 15000000 -a 4 orders.tbl orders.tbl.
wc -l lineitem.tbl
split -d -l 60000000 -a 4 lineitem.tbl lineitem.tbl.
# rm lineitem.tbl orders.tbl
# aws s3 cp $HOME/redshiftdata s3://my-bucket-2020-03-12/redshiftdata --recursive
chown -R ec2-user:ec2-user $home_dir $emr_dir $tpch_dir $rdsh_dir
aws s3 cp $rdsh_dir s3://$my_bucket/redshiftdata --recursive
# once done, verify files are in s3. You can then safely terminate the instance
shutdown -h now

--//

