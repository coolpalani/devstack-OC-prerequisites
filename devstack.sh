#!/bin/bash
echo "Devstack + OpenContrail prerequisites installation script"

function deploy {
	printf "Do you want to do sudo apt-get update [N/y]: "
	read -r updt
	if [ $updt == y ] || [ $updt == Y ];
		then
		sudo apt-get update
	fi

	sudo apt-get install -y python-pip
	sudo pip install --upgrade pip
	sudo pip install -U os-testr
	sudo apt-get install -y git
	git config --global url."https://".insteadOf git://
	git clone https://github.com/openstack-dev/devstack.git
	cd devstack


	printf "What branch (Devstack release) do you want to use ['stable/mitaka']: "
	read -r branch
	if [ -z $branch ] ;
		then
		branch="stable/mitaka"
	fi
	git checkout $branch


	printf "What branch (OpenContrail release) do you want to use [R3.1.1.x]: "
	read -r OC
	if [ -z $OC ] ;
		then
		OC="R3.1.1.x"
	fi

	cp samples/local.conf .
	echo "enable_plugin contrail https://github.com/zioc/contrail-devstack-plugin.git" >> local.conf
	OC="CONTRAIL_BRANCH=$OC"
	echo $OC >> local.conf

	printf "Ready to run Devstack $branch and OC $OC [n/Y]? "
	read -n 1 -r run
	if [ -z $run ] || [ $run == y ] || [ $run == Y ];
		then
		./stack.sh
	fi
}

function fixes {

	function FixKafka {
		#	Kafka build fails, add build options (Link flags) and make sure if packages are installed
		#	sudo apt-get install libssl-dev libsasl2-dev liblz4-dev
		#	edit: controller/src/analytics/SConscript  add "'-lssl', '-lcrypto', '-lpthread',"
		#	if sys.platform != 'darwin':
		#    AnalyticsEnv.Prepend(LINKFLAGS =
		#                         ['-Wl,--whole-archive',
		#                          '-lbase', '-lcpuinfo',
		#                          '-lprocess_info', '-lnodeinfo',
		#                          '-l:librdkafka.a', '-l:librdkafka++.a','-lssl', '-lcrypto', '-lpthread',
		#                          '-Wl,--no-whole-archive'])
		sudo apt-get install libssl-dev libsasl2-dev liblz4-dev
		sudo sed -ie "/'-l:librdkafka.a', '-l:librdkafka++.a',/s/$/ '-lssl', '-lcrypto', '-lpthread', '-ldl', '-lsasl2', /" /opt/stack/contrail/controller/src/analytics/SConscript
	}

	printf "What fix do you want to apply? [exit]: \n\r 1 - Fix Kafka ssl build \n\r "
	read -n 1 -r fix
	case "$fix" in
	1)
		FixKafka
	;;
	*)
		exit 1
	;;
esac

}

printf "What do you want to do [1]: \n\r 1 - install prerequisites, clone Devstack+OC repo and run devstack \n\r 2 - restack \n\r 3 - unstack and clean \n\r 4 - run fixes \n\r"
read slct
case "$slct" in
	1)
		deploy
	;;
	2)
		cd devstack
		./unstack.sh
		./clean.sh
		./stack.sh
	;;
	3)
		cd devstack
		./unstack.sh
		./clean.sh
	;;
	4)
		fixes
	;;
	*)
		deploy
	;;
esac
