# SINGLE-PAGE FLASK APPLICATION(PYTHON3)

This is a simple python-flask application with a single endpoint to display the current version and last commit-id of the build repository.
* Commit id will be picked by [Dockerfile](app-build/Dockerfile#L14) and [Wrapper-script](pre-interview.sh#L83)
* Application version will be passed as an environment variable to the container as part of [Deployment](app-deploy/templates/deployment-spec.yaml#L33-L35)

## Repo Structure:

`[app-build]`:
* Contains application source. Single python file exposing a given endpoint.
* Dockefile to build the application.
* Simple test-cases.

`[app-deploy]`:
* Helm templates to deploy the application to Kubernetes cluster.

`pre-interview.sh`:
* Workflow orchestrator to prepare application image and deploy to K8S.

`metadata.json`:
* Contains docker image version.

`app-builder.yaml`:
* GitHub Workflow action to build the image and publish to docker-hub by running [Wrapper-script](pre-interview.sh)

## Build:

:robot: CI Job to run `./pre-interview.sh --action prepare-app` on every single commit to repository master branch. It is required to increament image [version](metadata.json#L2) for any changes or delete the older tag in the docker hub repository.

`variables`:
* docker_repo - Repository name in docker-hub. Defaults to rekhanagyalakurthi.
* image_name  - Application image name. Defaults to pre-interview.
* registry_user/registry_password - Docker-hub login username/password to push image.(Mandatory)

### Image Versioning:

We are maintaining image version inside `metadata.json` file by following Semantic Versioning Standards- `Major.Minor.Patch`. Having version maintained in the source code will aid developers to know when to increase major/minor/patch versions. These changes will be peer-reviewed as part of pull-requests process so that whole team can agree on the version increment.

## Test:

Runs the below simple tests:
* Checks if `flask` module load properly.
* Checks if commit_id file exists in the image with content.

Test failure will halt the execution before pushing to registry.

## Deploy:

As a deployment step run `./pre-interview.sh --action deploy-app --namespace [K8S-Namespace](--namespace is optional)`. It will perform below tasks.
* Checks if a given namespace exist on the K8S cluster and creates if it does not exist. Default namespace is `technical-test`.
* Perform `helm deploy` on the K8S by setting context to provided namespace.
* Specify image version to be deployed [here](app-deploy/values.yaml#L5)

Pre-requisites:
* :point_up: Configure `kubectl` client to access your desired K8S cluster.
* :point_up: check the K8S status `kubectl cluster-info`

## How to build/deploy:

* Perform [source](app-build/source) commits and increment image [version](metadata.json#L2).
* Push the changes to master, which automatically builds/tests/publish app-image to registry via [GitHub-WorkFlow](.github/workflow/app-builder.yaml).
* Once your local/CI tool's `kubectl` gets authenticated to K8S cluster, invoke `./pre-interview --action deploy-app`.
* :boom: :tada: We are flying ....!


## Accessing the application endpoint:

With the [helm-templates](app-deploy/templates) we can either expose the deployment via `NodePort` service or via `Ingress` object, if the K8S cluster has Ingress-Controller installed.

NodePort:
* If you want to access via NodePort, specify port type [here](app-deploy/values.yaml#L12) and disable [ingress](app-deploy/values.yaml#L8)
* Once deployment is successful. Access the endpoint via `http://{node-ip}:31727/version`. If needed nodeport can be changed [here](app-deploy/values.yaml#L15)

Ingress:
* If Ingress-Controller is running on the cluster. Enable [ingress](app-deploy/values.yaml#L8) and set [type](app-deploy/values.yaml#L12) to `ClusterIP` or anything other than `NodePort`
* Post deployment get the ingress endpoint [command](pre-interview.sh#L131) . Access application via `http://{ingress-ip}:80/version` 

## Risks:

* :exclamation: Application is running on non-ssl port.
* :exclamation: Image scanning for vulnerabilities is not enabled.

