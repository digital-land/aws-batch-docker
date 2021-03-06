# AWS batch docker image


## AWS batch 30 second intro

There are three components to AWS batch

1. An environment - an AWS managed compute environment. This configures the type of instances used to execute jobs and is assigned to a job queue.
1. A job definition - the configuration for runnable jobs. A runnnable job consists of a docker image in ECR, environment variables and machine configuration, memory etc for the docker image.
1. A job queue - requests to run jobs. Jobs can be created in the web console or using aws cli.

The above have all been setup in the digital land dev AWS enviroment via the web console. They can be found in the
AWS batch dashboard

The queue we are using is:

```
dl-batch-queue
```

and job definition is:

```
dl-batch-def
```

## What's in this repository?

### Dockerfile

The Dockerfile in this repository is the runnable docker image that has been built and pushed to AWS ECR. The job defintion
has been setup to reference the built image in ECR.

The entry point for the image is the [fetch_and_run.sh](fetch_and_run.sh) script.

An execution of a job run involves submitting a job to the configured job queue, providing a job name, and
any environment variables that will be avaiable to the job. In this case the runnable job is effectively the fetch_and_run.sh script
above. When executed, fetch_and_run.sh will fetch another script that will in turn check out a repository and execute specific make targets of the checked out repository.

The submission of jobs in controlled via github actions in the pipeline or builder repositories. For example
see the [brownfield land pipeline](https://github.com/digital-land/brownfield-site-collection/blob/main/makerules/pipeline.mk)

```
aws batch submit-job --job-name $(REPOSITORY)-$(shell date '+%Y-%m-%d-%H-%M-%S') --job-queue dl-batch-queue --job-definition dl-batch-def --container-overrides '{"environment": [{"name":"BATCH_FILE_URL","value":"https://raw.githubusercontent.com/digital-land/docker-builds/main/pipeline_run.sh"}, {"name" : "REPOSITORY","value" : "$(REPOSITORY)"}]}'
```

Note that the --job-queue and --job-definition parameters are set to dl-batch-queue and dl-batch-def respectively.

We provide values for environment variables (available to docker image) using the --container-overrides parameter.

The enviroment variables are:

```
BATCH_FILE_URL
REPOSITORY
```

These tell AWS batch which script fetch_and_run.sh will use and which pipeline or builder repo to use.

In the example above we're creating a batch job to run the pipeline_run.sh (see below) and run it in the context
of the brownfield-site-collection repository. Note the REPOSITORY envrironment variable was already set by an earlier
make target.


### Scripts used by the docker image

Also in this repo are the following

[Pipeline run script](pipeline_run.sh) - this is used for pipeline repositories to make and push datasets to s3

[Builder run script](builder_run.sh) - this is used for builder repositories (entity, tiles-builder datasette)



### Repositories currently being built in AWS batch

These jobs are submitted to AWS batch from github actions

### Pipeline repositories

[historic-england-collection](https://github.com/digital-land/historic-england-collection)

[parish-collection](https://github.com/digital-land/parish-collection)

[local-authority-district-collection](https://github.com/digital-land/local-authority-district-collection)

[green-belt-collection](https://github.com/digital-land/green-belt-collection)

[ancient-land-collection](https://github.com/digital-land/ancient-land-collection)

[site-of-special-scientific-interest-collection](https://github.com/digtial-land/site-of-special-scientific-interest-collection)

[conservation-area-collection](https://github.com/digital-land/conservation-area-collection)

### Builder repositories

[digital-land-builder](https://github.com/digital-land/digital-land-builder)

[entity-builder](https://github.com/digital-land/entity-builder)

