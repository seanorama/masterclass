#!/usr/bin/env bash

echo "########################################"
echo "## Status of all CloudFormation stacks in this region:"
aws cloudformation describe-stacks --query 'Stacks[*].[StackName, StackStatus]' --output text
echo "########################################"
