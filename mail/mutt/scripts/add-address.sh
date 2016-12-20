#!/bin/sh
MESSAGE=$(cat)
echo "${MESSAGE}" | lbdb-fetchaddr
echo "${MESSAGE}"
