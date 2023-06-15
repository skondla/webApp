#!/bin/bash
#Purpose: Examine Kubernetes API Versions

for kind in `kubectl api-resources | tail +2 | awk '{ print $1 }'`; do kubectl explain $kind; done | grep -e "KIND:" -e "VERSION:"
