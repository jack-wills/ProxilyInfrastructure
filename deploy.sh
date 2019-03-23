#!/bin/bash
if [ $# -ne 0 ]; then
    if [ $1 = "lambda" ]; then
        cd lambdas

        cd fileUploadLambda
        printf '\n\nBuilding FileUpload Lambda\n\n'
        mvn clean verify
        if [ $? -ne 0 ]; then
            printf '\n\n FileUpload Lambda build faild!\n\n'
            exit -1
        fi

        cd ..

        cd sqlStartupLambda
        printf '\n\nBuilding SQLStartup Lambda\n\n'
        mvn clean verify
        if [ $? -ne 0 ]; then
            printf '\n\n SQLStartup Lambda build faild!\n\n'
            exit -1
        fi

        cd ..

        cd reaperLambda
        printf '\n\nBuilding Reaper Lambda\n\n'
        mvn clean verify
        if [ $? -ne 0 ]; then
            printf '\n\n Reaper Lambda build faild!\n\n'
            exit -1
        fi

        cd ..
        #Do other lambda builds

        cd ..
    fi
fi
printf '\n\nStarting Terraform!\n\n'
cd Terraform
terraform plan -out=plan.out
terraform apply plan.out