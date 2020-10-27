#!/usr/bin/env bash
set -o errexit 
set -o pipefail

function usage() {
	echo "Usage: $0 --action [prepare-app|deploy-app]"
	echo "Build/Deploy Flask application on K8S"
	echo "Parameters:"
	echo " --action pass required task to run (either 'prepare-app' or 'deploy-app')"
	exit 1
}


function parse_args {
	while getopts ":hv-:" opt ; do
		case ${opt} in
		-)
			case ${OPTARG} in 
				action)
					action="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
				;;
				namespace)
					namespace="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
				;;
				*)
					echo "Unknown option: ${OPTARG}" ; exit 1
				;;
			esac
		;;
		h)
			usage
		;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			usage
		;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			exit 1
		;;
		*)
			echo "unknown option ${opt} supplied"
			usage ;;
		esac
	done
}



function main {
	
	[ $# -lt 1 ] && { 
		echo -e ">>> Missing arguments."
		usage
	}

	parse_args "$@"
	
	#Getting image version from metadata.json
	tag=$(cat metadata.json | jq -r ".version")
	docker_repo=${docker_repo:-rekhanagyalakurthi}
	image_name=${image_name:-pre-interview}

	[ -z "${registry_user}" ] && { echo "Kindly set docker login username with [export registry_user=docker-hub username]"; exit 1; }

	[ -z "${registry_password}" ] && { echo "Kindly set docker login password with [export registry_password=docker-hub password]" ; exit 1;}

	[ -z "${tag}" ] && { echo "Application image tag has not been supplied. Kindly specify it in [metadata.json]" ; exit 1;} 

	# Mandy args
	[ -z "${action}" ] && usage


	if [ "${action}" == "prepare-app" ]; then

		commit_id=$(git rev-parse HEAD)
		echo ">>> Repo latest commit hash is:${commit_id}"

		echo ">>> Checking if registry has image with same tag."
		docker pull ${docker_repo}/${image_name}:${tag} && { echo "Aborting build as image already exists.  Delete the image if you wish to re-use ${tag}."; exit 1; }
		
		echo ">>> Building application docker image with tag:${tag}"
		docker build --tag ${docker_repo}/${image_name}:${tag} --build-arg COMMIT_ID=${commit_id} app-build

		echo ">>> Running simple test on the image."
		docker run --rm \
				--volume ${PWD}/app-build/tests:/src \
				--workdir /src \
				${docker_repo}/${image_name}:${tag} python3 check.py
		
		[ $? != 0 ] && exit "Image has failed basic testing. Check the above errors."

		echo ">>> Basic application check is successfull. Pushing image to registry"
		
		docker login --username ${registry_user} --password ${registry_password}
		docker push ${docker_repo}/${image_name}:${tag}

	elif [ "${action}" == "deploy-app" ]; then

		# Optional args
		[ -z "${namespace}" ] && { echo ">>> Namespace not provided. Setting it to [technical-test]"; namespace='technical-test'; }

		echo ">>> Checking if cluster is reachable via kubectl."
		status=$(kubectl cluster-info)
		if [ $? == 0 ]; then
			echo -e ">>> K8S cluster info: \n ${status} "
		else
			echo ">>> kubectl could not able to reach cluster."
			exit 1
		fi
		
		echo ">>> Checking if namespace:[${namespace}] exits on the cluster."
		result=$(kubectl get namespace --field-selector metadata.name=${namespace} -o jsonpath='{.items[*].metadata.name}')
		if [ "${result}" ]; then
			echo ">>> Namespace:[${namespace}] found."
			
		else
			echo ">>> Namespace:[${namespace}] not found. Creating it now"
			kubectl create namespace ${namespace}
		fi
		echo ">>> Setting current context to:${namespace}"
		kubectl config set-context --current --namespace=${namespace}

		echo ">>> Helm deploy .... "
		helm upgrade --install --atomic --timeout=5m --debug flask-app app-deploy

		cat << EOF
----------------------------------------------------------------------------------
Deployment Completed.  Next steps:
1.  Get Ingress IP if you have enabled ingress with below command:
	kubectl get ingress -o jsonpath='{.items[*].status.loadBalancer.ingress[*].ip}'
(Endpoint URL: http://{ingress-ip}/version)
		
2. If you are using NodePort to expose the service get node ip:
	kubectl get nodes -o jsonpath='{.items[*].status.addresses[*].address}'
	(Endpoint URL: http://{node-ip}:31727/version)
EOF

	fi


}

main $@